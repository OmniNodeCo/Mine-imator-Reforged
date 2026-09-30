# CppGen
Converts the GameMaker scripts and objects of Mine-imator found in `GmProject` to C++ code into `CppProject/Generated/`. The missing GML functions, as defined in `gml.json`, are then mapped to C++ replacements found in `CppProject/Gml/`. Note that this software is not general-purpose and won't work outside the Mine-imator project.

## Usage
```
CppGen.exe [repo-root] [gml-spec]
```

The repository root directory defaults to `../../`, while the GML specification file defaults to `../gml.json`.

This program runs automatically by the Setup script to populate `CppProject/Generated/` and can be directly accessed via shortcuts in Visual Studio, XCode and as a task in Visual Studio Code (see `BUILD.md`).

## Building CppGen (Windows):
```
cd CppGen
cmake -S . -B build -A x64
cmake --build build --parallel --config Release
build/CppGen.exe .. gml.json
```
## Building CppGen  (Mac/Linux):
```
cd CppGen
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
build/CppGen .. gml.json
```
## GML patterns that break the C++ build on GCC/Clang

CppGen converts GML to C++, and a few GML shapes generate C++ that MSVC
accepts but GCC/Clang (the Linux/macOS builds) reject - so a change can pass
the Windows build and still fail the Build check on the other platforms:

* **String literal vs. ds-map value in one ternary.** Assigning
  `map[?"key"] = (is_undefined(spec[?"key"]) ? "" : spec[?"key"])` generates
  `... ? STR(0) : DsMap(spec).Value(...)` - a conditional between a
  `StringType` literal and a `VarType`, which GCC/Clang report as a
  "conditional expression is ambiguous" error. Use a variable plus `if`
  instead (variables assigned both strings and map values are typed
  `VarType`, which converts cleanly):
  ```
  var val;
  val = spec[?"key"]
  if (is_undefined(val))
      val = ""
  map[?"key"] = val
  ```
* **`/*` inside a `//` comment.** The CppGen lexer treats `/*` as a block
  comment opener even inside a line comment, so a comment like
  `// packs live in Data/Shaders/*.mishader` swallows the rest of the file
  with a misleading "Unexpected end of function" error.
