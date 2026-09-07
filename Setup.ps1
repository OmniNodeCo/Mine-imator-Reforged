# Usage: ./Setup.ps1 [Qt|OpenSSL|FFmpeg|FreeType|Libzip|OpenAL|VisualStudio|CppGen|Release] [x64|x86]
#   Qt|OpenSSL|FFmpeg|FreeType|Libzip|OpenAL:
#       Unzips external library sources into DEV_DIR (the libraries themselves
#       are precompiled in CppProject/External); Qt and OpenSSL are built
#   VisualStudio:
#       Generates and opens a Visual Studio 2022/2026 solution
#   CppGen:
#       Generates C++ sources from the GameMaker project and copies modified sprites/shaders
#   Release:
#       Creates a release build and install folder for publishing
#   x64|x86:
#       Sets the target architecture, defaults to system architecture
#   Set SETUP_NON_INTERACTIVE=1 to skip confirmation prompts for CI /
#   non-interactive runs (an existing Qt directory is reused as-is).

param(
    [Parameter(Position = 0)][string] $Action = "Qt",
    [Parameter(Position = 1)][string] $Architecture
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $Architecture) {
    $Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
}

$jobs = 8 # Parallel threads when building

if (-not $env:DEV_DIR) {
    throw "DEV_DIR is not set. Example: setx DEV_DIR C:\Dev"
}

$actionKey = $Action.ToLowerInvariant()
$validActions = @("qt", "openssl", "ffmpeg", "freetype", "libzip", "openal", "visualstudio", "cppgen", "release")
if ($actionKey -notin $validActions) {
    throw "Unknown action '$Action'. Use Qt, OpenSSL, FFmpeg, FreeType, Libzip, OpenAL, VisualStudio, CppGen or Release."
}

$architectureKey = $Architecture.ToLowerInvariant()
if ($architectureKey -notin @("x64", "x86")) {
    throw "Unknown architecture '$Architecture'. Use x64 or x86."
}

$cppProjectDirectory = Join-Path $PSScriptRoot "CppProject"
$cppGenDirectory = Join-Path $PSScriptRoot "CppGen"
$generatedDirectory = Join-Path $cppProjectDirectory "Generated"
$externalDirectory = Join-Path $cppProjectDirectory "External"
$sourceArchiveDirectory = Join-Path $externalDirectory "Sources"

if ($architectureKey -eq "x64") {
    $cmakeArchitecture = "x64"
    $architectureSuffix = ""
    $externalLibDirectory = Join-Path $externalDirectory "Win64"
    $cppGenExecutable = Join-Path $cppGenDirectory "Win64\CppGen.exe"
} else {
    $cmakeArchitecture = "Win32"
    $architectureSuffix = "-Win32"
    $externalLibDirectory = Join-Path $externalDirectory "Win32"
    $cppGenExecutable = Join-Path $cppGenDirectory "Win32\CppGen.exe"
}

$buildVsDirectory = Join-Path $PSScriptRoot "build-vs${architectureSuffix}"
$buildReleaseDirectory = Join-Path $PSScriptRoot "build-release${architectureSuffix}"

$qtVersion = "5.15.19"
$qtRef = "v${qtVersion}-lts-lgpl"
$qtFolderName = "${qtVersion}${architectureSuffix}"
# Header-only dependency sources; the compiled libraries are precompiled
# in CppProject/External and referenced by CppProject/CMakeLists.txt
$ffmpegVersion = "5.0"
$libzipVersion = "1.9.2"
$freetypeVersion = "2.9.1"
$openAlVersion = "1.22.0"
$openSslVersion = "3.0.21"
$jomVersion = "1.1.7"

$devDirectory = [System.IO.Path]::GetFullPath($env:DEV_DIR)
if (-not (Test-Path -LiteralPath $devDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $devDirectory -Force | Out-Null
}
$qtDirectory = Join-Path $devDirectory "Qt\$qtFolderName"
$qtSourceDirectory = Join-Path $qtDirectory "qt5"
$qtBuildDirectory = Join-Path $qtDirectory "build"
$qtInstallDirectory = Join-Path $qtDirectory "install"
$jomExecutable = Join-Path $devDirectory "Jom\jom.exe"
$jomArchiveName = "jom_$($jomVersion.Replace('.', '_')).zip"
$jomArchive = Join-Path $externalDirectory $jomArchiveName

. (Join-Path $PSScriptRoot "WinUtils.ps1")

$cmake = Get-VisualStudioCMake
$cmakeGenerator = Get-VisualStudioGenerator

function Get-SafeSourceTarget {
    param([Parameter(Mandatory = $true)][string] $RelativePath)

    $allowedRelativePaths = @(
        "FFmpeg\ffmpeg-$ffmpegVersion",
        "Libzip\libzip-$libzipVersion",
        "FreeType\freetype-$freetypeVersion",
        "OpenAL\openal-soft-$openAlVersion",
        "OpenSSL\openssl-$openSslVersion"
    )
    if ($allowedRelativePaths -notcontains $RelativePath) {
        throw "Unexpected source directory request: $RelativePath"
    }

    $target = [System.IO.Path]::GetFullPath((Join-Path $devDirectory $RelativePath))
    $devPrefix = $devDirectory.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $target.StartsWith($devPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to replace unexpected source directory: $target"
    }

    return $target
}

function Ensure-SourceArchive {
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
        [string[]] $Libraries
    )

    foreach ($library in $Libraries) {
        $sources = switch ($library.ToLowerInvariant()) {
            "openssl" {
                @{
                    Archive = "openssl-$openSslVersion.tar.gz"
                    Destination = Join-Path $devDirectory "OpenSSL"
                    RelativePath = "OpenSSL\openssl-$openSslVersion"
                    Marker = "Configure"
                }
            }
            "ffmpeg" {
                @{
                    Archive = "ffmpeg-$ffmpegVersion.tar.xz"
                    Destination = Join-Path $devDirectory "FFmpeg"
                    RelativePath = "FFmpeg\ffmpeg-$ffmpegVersion"
                    Marker = "configure"
                }
            }
            "libzip" {
                @{
                    Archive = "libzip-$libzipVersion.tar.gz"
                    Destination = Join-Path $devDirectory "Libzip"
                    RelativePath = "Libzip\libzip-$libzipVersion"
                    Marker = "CMakeLists.txt"
                }
            }
            "freetype" {
                @{
                    Archive = "freetype-$freetypeVersion.tar.gz"
                    Destination = Join-Path $devDirectory "FreeType"
                    RelativePath = "FreeType\freetype-$freetypeVersion"
                    Marker = "include\freetype\freetype.h"
                }
            }
            "openal" {
                @{
                    Archive = "openal-soft-$openAlVersion.tar.bz2"
                    Destination = Join-Path $devDirectory "OpenAL"
                    RelativePath = "OpenAL\openal-soft-$openAlVersion"
                    Marker = "CMakeLists.txt"
                }
            }
            default { throw "Unknown source library: $library" }
        }

        foreach ($source in $sources) {
            $targetDirectory = Get-SafeSourceTarget -RelativePath $source.RelativePath
            $resolvedParent = [System.IO.Path]::GetFullPath($source.Destination)
            $expectedParent = [System.IO.Path]::GetFullPath((Split-Path -Parent $targetDirectory))
            if (-not $resolvedParent.Equals($expectedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Archive destination does not match the expected source parent: $resolvedParent"
            }

            if (Test-Path -LiteralPath $targetDirectory -PathType Container) {
                Write-Host "Source directory already exists: $targetDirectory"
            } else {
                if (Test-Path -LiteralPath $targetDirectory) {
                    throw "The expected source directory is occupied by a non-directory path: $targetDirectory"
                }

                $archivePath = Join-Path $sourceArchiveDirectory $source.Archive
                New-Item -ItemType Directory -Path $resolvedParent -Force | Out-Null

                Write-Host "Extracting $($source.Archive) into $resolvedParent"
                Push-Location -LiteralPath $resolvedParent
                try {
                    & $cmake -E tar xf $archivePath
                    $extractionExitCode = $LASTEXITCODE
                }
                finally {
                    Pop-Location
                }
                if ($extractionExitCode -ne 0) {
                    throw "Extraction of $($source.Archive) failed with exit code $extractionExitCode."
                }
                if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
                    throw "$($source.Archive) did not create the expected directory $targetDirectory."
                }
            }

            Require-File `
                -Path (Join-Path $targetDirectory $source.Marker) `
                -Description "$($source.Archive) source marker"
        }
    }
}

function Remove-BuildDirectory {
    param([Parameter(Mandatory = $true)][string] $Path)

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $isUnderKnownLibrary = @("Qt", "OpenSSL", "FFmpeg", "FreeType", "Libzip", "OpenAL") |
        ForEach-Object { [System.IO.Path]::GetFullPath((Join-Path $devDirectory $_)) } |
        Where-Object {
            $resolvedPath.StartsWith(
                $_ + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        }
    if (-not $isUnderKnownLibrary) {
        throw "Refusing to remove unexpected build directory: $resolvedPath"
    }
    if (Test-Path -LiteralPath $resolvedPath) {
        Write-Host "Removing build directory $resolvedPath"
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

# Place generated/absent headers that the precompiled libraries expect
function Copy-DevHeaders {
    $ffmpegDirectory = Get-SafeSourceTarget -RelativePath "FFmpeg\ffmpeg-$ffmpegVersion"
    if (Test-Path -LiteralPath $ffmpegDirectory -PathType Container) {
        Copy-Item `
            -LiteralPath (Join-Path $externalDirectory "avconfig.h") `
            -Destination (Join-Path $ffmpegDirectory "libavutil\avconfig.h") -Force
    }
    $libzipDirectory = Get-SafeSourceTarget -RelativePath "Libzip\libzip-$libzipVersion"
    if (Test-Path -LiteralPath $libzipDirectory -PathType Container) {
        Copy-Item `
            -LiteralPath (Join-Path $externalDirectory "zipconf.h") `
            -Destination (Join-Path $libzipDirectory "lib\zipconf.h") -Force
    }
    Write-Host "Placed avconfig.h and zipconf.h into the dependency sources"
}

function Copy-BuiltFile {
    param(
        [Parameter(Mandatory = $true)][string] $Source
    )

    Require-File -Path $Source -Description "Built library"
    New-Item -ItemType Directory -Path $externalLibDirectory -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $externalLibDirectory -Force
    Write-Host "Copied $(Split-Path -Leaf $Source) to $externalLibDirectory"
}

function Invoke-CppGen {

    Require-File -Path $cppGenExecutable -Description "CppGen executable"
    Write-Host "Running CppGen"
    $cppGenArguments = @($PSScriptRoot, (Join-Path $cppGenDirectory "gml.json"))
    Push-Location $cppGenDirectory
    try {
        & $cppGenExecutable @cppGenArguments
        if ($LASTEXITCODE -ne 0) {
            throw "CppGen failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path -LiteralPath $generatedDirectory -PathType Container)) {
        throw "CppGen did not create the generated source directory: $generatedDirectory"
    }
}

function Ensure-GeneratedSources {
    if (Test-Path -LiteralPath $generatedDirectory -PathType Container) {
        return
    }

    Invoke-CppGen
}

function Ensure-Jom {
    $jomDirectory = [System.IO.Path]::GetFullPath((Split-Path -Parent $jomExecutable))
    $expectedJomDirectory = [System.IO.Path]::GetFullPath((Join-Path $devDirectory "Jom"))
    if (-not $jomDirectory.Equals($expectedJomDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to extract Jom into unexpected directory: $jomDirectory"
    }

    if (Test-Path -LiteralPath $jomDirectory -PathType Container) {
        Require-File -Path $jomExecutable -Description "Jom executable"
        Write-Host "Reusing existing Jom directory $jomDirectory"
        return
    }
    if (Test-Path -LiteralPath $jomDirectory) {
        throw "The Jom destination is occupied by a non-directory path: $jomDirectory"
    }

    Write-Host "Extracting jom into $jomDirectory"
    try {
        Expand-Archive -LiteralPath $jomArchive -DestinationPath $jomDirectory
        Require-File -Path $jomExecutable -Description "Extracted Jom executable"
    }
    catch {
        if (Test-Path -LiteralPath $jomDirectory -PathType Container) {
            Remove-Item -LiteralPath $jomDirectory -Recurse -Force
        }
        throw
    }
}

function Invoke-OpenSSLTarget {
    param(
        [Parameter(Mandatory = $true)][string] $BuildTarget
    )

    $openSslDirectory = Get-SafeSourceTarget -RelativePath "OpenSSL\openssl-$openSslVersion"
    $buildDirectory = Join-Path $openSslDirectory "build${architectureSuffix}"
    $installDirectory = Join-Path $openSslDirectory "install${architectureSuffix}"
    
    if ($architectureKey -eq "x64") {
        $configureTarget = "VC-WIN64A"
    } else {
        $configureTarget = "VC-WIN32"
    }

    Remove-BuildDirectory -Path $buildDirectory
    New-Item -ItemType Directory -Path $buildDirectory | Out-Null

    $previousTerm = $env:TERM
    $env:TERM = "ansi"
    Push-Location $buildDirectory
    try {
        $configureArguments = @(
            $configureTarget,
            "no-asm",
            "no-shared",
            "no-module",
            "no-tests",
            "no-makedepend",
            "--prefix=$installDirectory",
            "--openssldir=$(Join-Path $installDirectory 'ssl')",
            "--libdir=lib"
        )
        & perl.exe (Join-Path $openSslDirectory "Configure") @configureArguments
        if ($LASTEXITCODE -ne 0) {
            throw "OpenSSL configuration failed for $Architecture with exit code $LASTEXITCODE."
        }

        & nmake.exe $BuildTarget
        if ($LASTEXITCODE -ne 0) {
            throw "OpenSSL target '$BuildTarget' failed for $Architecture with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
        if ($null -eq $previousTerm) {
            Remove-Item Env:TERM -ErrorAction SilentlyContinue
        } else {
            $env:TERM = $previousTerm
        }
    }
}

function Build-OpenSSL {
    $openSslDirectory = Get-SafeSourceTarget -RelativePath "OpenSSL\openssl-$openSslVersion"
    $installDirectory = Join-Path $openSslDirectory "install${architectureSuffix}"
    
    Remove-BuildDirectory -Path $installDirectory

    Import-VisualStudioEnvironment -TargetArchitecture $architectureKey

    foreach ($commandName in @("cl.exe", "lib.exe", "nmake.exe", "perl.exe", "rc.exe")) {
        Require-Command -Name $commandName
    }
    
    # install_dev builds and installs only the static libraries and headers.
    Invoke-OpenSSLTarget -BuildTarget "install_dev" `

    foreach ($name in @("libssl.lib", "libcrypto.lib")) {
        Copy-BuiltFile -Source (Join-Path $installDirectory "lib\$name")
    }

    $includeDirectory = Join-Path $installDirectory "include\openssl"
    Require-File `
        -Path (Join-Path $includeDirectory "ssl.h") `
        -Description "Installed OpenSSL headers"
}

function Build-Qt {
    Ensure-Jom
    Import-VisualStudioEnvironment -TargetArchitecture $architectureKey

    foreach ($commandName in @("cl.exe", "git.exe", "perl.exe", "nmake.exe")) {
        if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
            throw "$commandName was not found. Ensure Git and Strawberry Perl are installed and on PATH, then restart the terminal and run again."
        }
    }

    if ($env:VSCMD_ARG_TGT_ARCH -ne $architectureKey) {
        throw "The active MSVC compiler does not target $architectureKey."
    }

    if (Test-Path -LiteralPath $qtDirectory -PathType Container) {
        if ($env:SETUP_NON_INTERACTIVE) {
            Write-Host "Qt directory already exists at $qtDirectory; reusing it (SETUP_NON_INTERACTIVE is set)."
            return
        }
        $answer = Read-Host "A Qt directory already exists at $qtDirectory. Erase it and continue? [Y]es/[N]o"
        if ($answer -notmatch '^(?i:y|yes)$') {
            return
        }
        Remove-BuildDirectory -Path $qtDirectory
    }

    # Generate OpenSSL's platform-specific public headers without rebuilding its libraries.
    Invoke-OpenSSLTarget -BuildTarget "build_generated"

    $openSslDirectory = Get-SafeSourceTarget -RelativePath "OpenSSL\openssl-$openSslVersion"
    $openSslGeneratedIncludeDirectory = Join-Path $openSslDirectory  "build${architectureSuffix}\include"
    $openSslSourceIncludeDirectory = Join-Path $openSslDirectory "include"
    $openSslInstallDirectory = Join-Path $openSslDirectory "install${architectureSuffix}"

    Require-File `
        -Path (Join-Path $openSslGeneratedIncludeDirectory "openssl\ssl.h") `
        -Description "Generated OpenSSL headers"
    Require-File `
        -Path (Join-Path $openSslSourceIncludeDirectory "openssl\e_os2.h") `
        -Description "OpenSSL source headers"
    Require-File `
        -Path (Join-Path $externalLibDirectory "libssl.lib") `
        -Description "OpenSSL static library"
    Require-File `
        -Path (Join-Path $externalLibDirectory "libcrypto.lib") `
        -Description "OpenSSL crypto static library"

    # Clone Qt sources
    New-Item -ItemType Directory -Path $qtDirectory -Force | Out-Null
    Write-Host "Cloning Qt $qtRef for $Architecture into $qtSourceDirectory"
    & git.exe clone --branch $qtRef --depth 1 https://code.qt.io/qt/qt5.git $qtSourceDirectory
    if ($LASTEXITCODE -ne 0) { throw "Qt clone failed with exit code $LASTEXITCODE." }

    Push-Location $qtSourceDirectory
    try {
        # Project uses Qt Widgets, Gui, Network, and OpenGL classes, all supplied by QtBase
        & perl.exe init-repository --module-subset=qtbase
        if ($LASTEXITCODE -ne 0) { throw "QtBase initialization failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }

    Remove-BuildDirectory -Path $qtBuildDirectory
    Remove-BuildDirectory -Path $qtInstallDirectory
    New-Item -ItemType Directory -Path $qtBuildDirectory | Out-Null

    Push-Location $qtBuildDirectory
    try {
        $openSslLibraries =
            "$externalLibDirectory\libssl.lib " +
            "$externalLibDirectory\libcrypto.lib"
        $configureArguments = @(
            "-platform", "win32-msvc",
            "-prefix", $qtInstallDirectory,
            "-opensource", "-confirm-license",
            "-release", "-static", "-static-runtime",
            "-opengl", "desktop",
            "-openssl-linked",
            "-I$openSslGeneratedIncludeDirectory",
            "-I$openSslSourceIncludeDirectory",
            "OPENSSL_LIBS=-lWs2_32 -lGdi32 -lAdvapi32 -lCrypt32 -lUser32",
            "OPENSSL_LIBS_DEBUG=$openSslLibraries",
            "OPENSSL_LIBS_RELEASE=$openSslLibraries",
            "-qt-libpng", "-qt-libjpeg", "-qt-zlib", "-qt-harfbuzz", "-qt-pcre", "-qt-doubleconversion",
            "-no-feature-textmarkdownreader", "-no-feature-textmarkdownwriter", "-no-feature-bearermanagement",
            "-no-libinput", "-no-libmd4c", "-no-icu",
            "-nomake", "tests", "-nomake", "examples", "-nomake", "tools"
        )

        & (Join-Path $qtSourceDirectory "configure.bat") @configureArguments
        if ($LASTEXITCODE -ne 0) { throw "Qt configuration failed with exit code $LASTEXITCODE." }

        # Only QtBase was initialized, so the normal build target is already limited
        # to QtBase. `jom module-qtbase` would build it too, but not install it.
        & $jomExecutable
        if ($LASTEXITCODE -ne 0) { throw "Qt build failed with exit code $LASTEXITCODE." }
        & $jomExecutable install
        if ($LASTEXITCODE -ne 0) { throw "Qt installation failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }

    Write-Host "Qt $qtRef for $Architecture was installed to $qtInstallDirectory"
}

switch ($actionKey) {
    "qt" {
        Ensure-GeneratedSources
        Ensure-SourceArchive "OpenSSL" "FFmpeg" "FreeType" "OpenAL" "Libzip"
        Copy-DevHeaders
        Build-Qt
    }
    "openssl" {
        Ensure-SourceArchive "OpenSSL"
        Build-OpenSSL
    }
    "ffmpeg" {
        Ensure-SourceArchive "FFmpeg"
        Copy-DevHeaders
    }
    "freetype" {
        Ensure-SourceArchive "FreeType"
    }
    "libzip" {
        Ensure-SourceArchive "Libzip"
        Copy-DevHeaders
    }
    "openal" {
        Ensure-SourceArchive "OpenAL"
    }
    "visualstudio" {
        Ensure-GeneratedSources
        Ensure-SourceArchive "FFmpeg" "FreeType" "OpenAL" "Libzip"
        Copy-DevHeaders
        & $cmake `
            -S $cppProjectDirectory -B $buildVsDirectory `
            -G $cmakeGenerator -A $cmakeArchitecture
        if ($LASTEXITCODE -ne 0) {
            throw "Visual Studio generation failed for $($cmakeArchitecture)."
        }

        $solution = Get-ChildItem -LiteralPath $buildVsDirectory -File |
            Where-Object { $_.Extension -in @(".sln", ".slnx") } |
            Select-Object -First 1

        if ($null -eq $solution) {
            throw "No Visual Studio solution was generated in $buildVsDirectory."
        }
        $devenv = Join-Path (Get-VisualStudioDirectory) "Common7\IDE\devenv.exe"
        Start-Process -FilePath $devenv -ArgumentList "`"$($solution.FullName)`""
    }
    "cppgen" {
        Invoke-CppGen
    }
    "release" {
        Ensure-GeneratedSources
        Ensure-SourceArchive "FFmpeg" "FreeType" "OpenAL" "Libzip"
        Copy-DevHeaders
        & $cmake `
            -S $cppProjectDirectory -B $buildReleaseDirectory `
            -G $cmakeGenerator -A $cmakeArchitecture
        if ($LASTEXITCODE -ne 0) {
            throw "Release build generation failed for $($cmakeArchitecture)."
        }
        & $cmake `
            --build $buildReleaseDirectory `
            --parallel $jobs `
            --config Release
        if ($LASTEXITCODE -ne 0) {
            throw "Release build failed for $($cmakeArchitecture)."
        }
        & $cmake `
            --install $buildReleaseDirectory `
            --config Release
        if ($LASTEXITCODE -ne 0) {
            throw "Install failed for $($cmakeArchitecture)."
        }
    }
}
