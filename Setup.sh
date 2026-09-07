#!/usr/bin/env sh
# Usage: ./Setup.sh [Qt|FFmpeg|FreeType|Libzip|OpenAL|Xcode|CppGen|Release] [x86_64|arm64]
#   Qt|FFmpeg|FreeType|Libzip|OpenAL:
#       Unzips the external library sources into DEV_DIR (the libraries
#       themselves are precompiled in CppProject/External), then builds Qt
#   Xcode:
#       For Mac OS, generates and opens an Xcode project file
#   CppGen:
#       Generates C++ sources from the GameMaker project and copies modified sprites/shaders
#   Release:
#       Creates a release build and install folder for publishing
#   x86_64|arm64:
#       For Mac OS, sets the target architecture, defaults to system architecture
#   Set SETUP_NON_INTERACTIVE=1 to skip confirmation prompts for CI /
#   non-interactive runs (an existing Qt directory is reused as-is).

set -eu

jobs=8  # Parallel threads when building

if [ -z "${DEV_DIR:-}" ]; then
    echo "DEV_DIR is not set. Example: export DEV_DIR=\"$HOME/Dev\"" >&2
    exit 1
fi

if [ "$#" -gt 2 ]; then
    echo "Usage: $0 [Qt|FFmpeg|Libzip|OpenAL|Xcode|CppGen|Release] [x86_64|arm64]" >&2
    exit 1
fi

action="${1:-Qt}" # Qt is the default action
action_key=$(printf '%s' "$action" | tr '[:upper:]' '[:lower:]')
case "$action_key" in
    qt|ffmpeg|freetype|libzip|openal|xcode|cppgen|release) ;;
    *)
        echo "Unknown action '$action'. Use Qt, FFmpeg, FreeType, Libzip, OpenAL, Xcode, CppGen or Release." >&2
        exit 1
        ;;
esac

requested_architecture="${2:-}"

script_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
cpp_project_directory="$script_root/CppProject"
cppgen_directory="$script_root/CppGen"
generated_directory="$cpp_project_directory/Generated"
external_directory="$cpp_project_directory/External"
source_archive_directory="$external_directory/Sources"
build_xcode_directory="$script_root/build-xcode"
build_release_directory="$script_root/build-release"

case "$(uname -s)" in
    Darwin)
        platform=macos
        external_lib_directory="$external_directory/Mac"
        cppgen_executable="$cppgen_directory/Mac/CppGen"
        macos_arch="${requested_architecture:-$(uname -m)}"
        case "$macos_arch" in
            x86_64) macos_deployment_target=10.15 ;;
            arm64) macos_deployment_target=11.0 ;;
            *)
                echo "Architecture must be x86_64 or arm64 (got: $macos_arch)." >&2
                exit 1
                ;;
        esac
        ;;
    Linux)
        if [ -n "$requested_architecture" ]; then
            echo "The architecture argument is supported only on macOS." >&2
            exit 1
        fi
        platform=linux
        external_lib_directory="$external_directory/Linux"
        cppgen_executable="$cppgen_directory/Linux/CppGen"
        ;;
    *)
        echo "Unsupported operating system: $(uname -s)" >&2
        exit 1
        ;;
    esac

qt_version="5.15.19"
qt_ref="${qt_ref:-v${qt_version}-lts-lgpl}"
# Header-only dependency sources; the compiled libraries are precompiled
# in CppProject/External and referenced by CppProject/CMakeLists.txt
ffmpeg_version="5.0"
libzip_version="1.9.2"
freetype_version="2.9.1"
openal_version="1.22.0"

mkdir -p "$DEV_DIR"
dev_directory=$(cd "$DEV_DIR" && pwd -P)
qt_directory="$dev_directory/Qt/$qt_version"
qt_source_directory="$qt_directory/qt5"
qt_build_directory="$qt_directory/build"
qt_install_directory="$qt_directory/install"
ffmpeg_directory="$dev_directory/FFmpeg/ffmpeg-$ffmpeg_version"
libzip_directory="$dev_directory/Libzip/libzip-$libzip_version"
freetype_directory="$dev_directory/FreeType/freetype-$freetype_version"
openal_directory="$dev_directory/OpenAL/openal-soft-$openal_version"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

require_file() {
    if [ ! -f "$1" ]; then
        echo "$2 was not found at $1." >&2
        exit 1
    fi
}

invoke_cppgen() {
    require_file "$cppgen_executable" "CppGen executable"
    if [ ! -x "$cppgen_executable" ]; then
        echo "CppGen executable is not executable: $cppgen_executable" >&2
        exit 1
    fi

    echo "Running CppGen"
    if ! (
        cd "$cppgen_directory"
        "$cppgen_executable" "$script_root" "$cppgen_directory/gml.json" "$@"
    ); then
        echo "CppGen failed." >&2
        exit 1
    fi

    if [ ! -d "$generated_directory" ]; then
        echo "CppGen did not create the generated source directory: $generated_directory" >&2
        exit 1
    fi
}

ensure_generated_sources() {
    # The directory may exist as a placeholder (Generated/.gitignore) in a
    # fresh checkout; only skip CppGen when its outputs are actually present
    if [ -f "$generated_directory/GmlFunc.hpp" ] && [ -f "$generated_directory/Scripts.hpp" ]; then
        return
    fi

    invoke_cppgen
}

ensure_source_archive() {
    if [ "$#" -eq 0 ]; then
        echo "At least one source library is required." >&2
        exit 1
    fi

    for source_library in "$@"; do
        source_library_key=$(printf '%s' "$source_library" | tr '[:upper:]' '[:lower:]')
        case "$source_library_key" in
            ffmpeg|freetype|libzip|openal) source_names=$source_library_key ;;
            *)
                echo "Unknown source library: $source_library" >&2
                exit 1
                ;;
        esac

        for source_name in $source_names; do
            case "$source_name" in
                ffmpeg)
                    archive_name="ffmpeg-$ffmpeg_version.tar.xz"
                    destination_parent="$dev_directory/FFmpeg"
                    target_directory=$ffmpeg_directory
                    source_marker=configure
                    ;;
                libzip)
                    archive_name="libzip-$libzip_version.tar.gz"
                    destination_parent="$dev_directory/Libzip"
                    target_directory=$libzip_directory
                    source_marker=CMakeLists.txt
                    ;;
                freetype)
                    archive_name="freetype-$freetype_version.tar.gz"
                    destination_parent="$dev_directory/FreeType"
                    target_directory=$freetype_directory
                    source_marker=include/freetype/freetype.h
                    ;;
                openal)
                    archive_name="openal-soft-$openal_version.tar.bz2"
                    destination_parent="$dev_directory/OpenAL"
                    target_directory=$openal_directory
                    source_marker=CMakeLists.txt
                    ;;
            esac

            case "$target_directory" in
                "$ffmpeg_directory"|"$libzip_directory"|"$freetype_directory"|"$openal_directory") ;;
                *)
                    echo "Unexpected source directory request: $target_directory" >&2
                    exit 1
                    ;;
            esac

            if [ -d "$target_directory" ]; then
                echo "Source directory already exists: $target_directory"
            else
                if [ -e "$target_directory" ]; then
                    echo "The expected source directory is occupied by a non-directory path: $target_directory" >&2
                    exit 1
                fi

                require_command tar
                archive_path="$source_archive_directory/$archive_name"
                mkdir -p "$destination_parent"
                echo "Extracting $archive_name into $destination_parent"
                tar -xf "$archive_path" -C "$destination_parent"
                if [ ! -d "$target_directory" ]; then
                    echo "$archive_name did not create the expected directory $target_directory." >&2
                    exit 1
                fi
            fi

            require_file "$target_directory/$source_marker" "$archive_name source marker"
        done
    done
}

remove_build_directory() {
    build_directory=$1
    case "$build_directory" in
        "$dev_directory/Qt/"*|\
        "$dev_directory/FFmpeg/"*|\
        "$dev_directory/FreeType/"*|\
        "$dev_directory/Libzip/"*|\
        "$dev_directory/OpenAL/"*) ;;
        *)
            echo "Refusing to remove unexpected build directory: $build_directory" >&2
            exit 1
            ;;
    esac
    if [ -e "$build_directory" ]; then
        echo "Removing build directory $build_directory"
        rm -rf -- "$build_directory"
    fi
}

# Place generated/absent headers that the precompiled libraries expect
copy_dev_headers() {
    require_file "$external_directory/avconfig.h" "FFmpeg avconfig.h"
    require_file "$external_directory/zipconf.h" "libzip zipconf.h"
    if [ -d "$ffmpeg_directory" ]; then
        cp -f "$external_directory/avconfig.h" "$ffmpeg_directory/libavutil/avconfig.h"
    fi
    if [ -d "$libzip_directory" ]; then
        cp -f "$external_directory/zipconf.h" "$libzip_directory/lib/zipconf.h"
    fi
    echo "Placed avconfig.h and zipconf.h into the dependency sources"
}

build_qt() {
    for required_command in git perl make clang clang++; do
        require_command "$required_command"
    done

    case "$platform" in
        macos) qt_platform=macx-clang ;;
        linux) qt_platform=linux-clang ;;
    esac

    if [ -d "$qt_directory" ]; then
        if [ -n "${SETUP_NON_INTERACTIVE:-}" ]; then
            echo "Qt directory already exists at $qt_directory; reusing it (SETUP_NON_INTERACTIVE is set)."
            exit 0
        fi
        printf 'A Qt directory already exists at %s. Erase it and continue? [Y]es/[N]o ' "$qt_directory"
        if ! read -r answer; then
            exit 0
        fi
        case "$answer" in
            [Yy]|[Yy][Ee][Ss])
                remove_build_directory "$qt_directory"
                ;;
            *)
                exit 0
                ;;
        esac
    fi

    mkdir -p "$qt_directory"

    echo "Cloning Qt $qt_ref for $platform into $qt_source_directory"
    git clone --branch "$qt_ref" --depth 1 https://code.qt.io/qt/qt5.git "$qt_source_directory"

    (cd "$qt_source_directory" && perl init-repository --module-subset=qtbase)
    
    remove_build_directory "$qt_build_directory"
    remove_build_directory "$qt_install_directory"
    mkdir -p "$qt_build_directory"

    set -- \
        -platform "$qt_platform" \
        -prefix "$qt_install_directory" \
        -opensource -confirm-license \
        -release -static \
        -opengl desktop \
        -qt-libpng -qt-libjpeg -qt-zlib -qt-harfbuzz -qt-pcre -qt-doubleconversion \
        -no-feature-textmarkdownreader -no-feature-textmarkdownwriter -no-feature-bearermanagement \
        -no-libinput -no-libmd4c -no-icu -no-dbus -no-glib -no-cups \
        -nomake tests -nomake examples -nomake tools

    if [ "$platform" = "macos" ]; then
        set -- "$@" \
            "QMAKE_APPLE_DEVICE_ARCHS=$macos_arch" \
            "QMAKE_MACOSX_DEPLOYMENT_TARGET=$macos_deployment_target"
    else
        set -- "$@" \
            -openssl-linked -xcb -xcb-xlib -bundled-xcb-xinput
    fi

    (
        cd "$qt_build_directory"
        "$qt_source_directory/configure" "$@"
        make -j"$jobs"
        make install
    )
    echo "Qt $qt_ref for $platform was installed to $qt_install_directory"
}

case "$action_key" in
    qt)
        ensure_generated_sources
        ensure_source_archive FFmpeg FreeType OpenAL Libzip
        copy_dev_headers
        build_qt
        ;;
    ffmpeg|freetype|libzip|openal)
        ensure_source_archive "$(printf '%s' "$action_key" | tr '[:lower:]' '[:upper:]')"
        copy_dev_headers
        ;;
    xcode)
        if [ "$platform" = "linux" ]; then
            echo "The Xcode action is supported only on Mac OS." >&2
            exit 1
        fi
        ensure_generated_sources
        ensure_source_archive FFmpeg FreeType OpenAL Libzip
        copy_dev_headers
        cmake \
            -S "$cpp_project_directory" -B "$build_xcode_directory" -G "Xcode" \
            -DCMAKE_OSX_ARCHITECTURES=$macos_arch
        open "$build_xcode_directory/Mine-imator.xcodeproj"
        ;;
    cppgen)
        invoke_cppgen
        ;;
    release)
        ensure_generated_sources
        ensure_source_archive FFmpeg FreeType OpenAL Libzip
        copy_dev_headers
        if [ "$platform" = "macos" ]; then
            cmake \
                -S "$cpp_project_directory" -B "$build_release_directory" \
                -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_OSX_ARCHITECTURES=$macos_arch
        else
            cmake \
                -S "$cpp_project_directory" -B "$build_release_directory" \
                -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
        fi
        cmake \
            --build "$build_release_directory" \
            --parallel "$jobs"
        cmake \
            --install "$build_release_directory"
        ;;
esac
