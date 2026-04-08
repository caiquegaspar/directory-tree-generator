# Changelog

All notable changes to this project will be documented in this file.

This format follows the guidelines of [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2025-04-08

### Added

- **Markdown output** (`--md` / `--txt`): generates a `.md` file with the tree in a fenced code block and file contents in syntax-highlighted blocks (20+ languages supported).
- **Depth limit** (`--max-depth N`): limits directory recursion to N levels; 0 means unlimited.
- **Custom output path** (`-o` / `--output FILE`): writes the result to any specified path instead of the default filename.
- **Content-skip via flag** (`--skip-content PAT`): files matching the pattern appear in the tree but their contents are omitted from `--print-content`. Can be repeated for multiple patterns.
- **`.contentignore` file**: persistent content-skip rules using the same syntax as `.gitignore`. Files listed here are always visible in the tree but never printed.
- **Binary file detection**: automatically skips images, fonts, archives, compiled files, and other binary types when printing content. Falls back to the `file` command for unknown extensions.
- **Auto-exclusion**: the script itself and the output file are always excluded from the tree without requiring manual ignore rules.
- **`--help` / `-h`**: prints full usage information and exits.
- **Organized test suite**: manual tests moved to `tests/` with fixture files (`.contentignore`, `.generatetreeignore`, nested folders) and a `test_results.json` recording all test cases and their outcomes.

### Changed

- Rewrote `README.md` with updated usage, ignore-file reference table, and output examples for both `--txt` and `--md`.
- Rewrote `DEVELOPER_GUIDE.md` with architecture diagram, explanation of the three ignore layers, and dedicated sections for every non-trivial implementation decision.
- Whitespace trimming in pattern loading replaced `echo "$line" | xargs` (two subprocesses per line) with pure bash parameter expansion.
- Array sorting replaced `IFS=$'\n' arr=($(sort ...))` with `mapfile -t` (bash 4+), which handles filenames with newlines correctly.
- Debug messages now go to `stderr` instead of `stdout` so they never pollute the output file.

### Fixed

- `printf '--- ... ---'` crashed with `printf: --: invalid option` on some systems due to leading `--` in the format string.
- `dotglob` + `.*` glob caused every dotfile to appear **twice** in the tree.
- Glob patterns like `*.log` never matched because `$pattern` was quoted inside `[[`, disabling glob expansion.
- `(( idx++ ))` with `set -e` active silently exited the script when `idx` was `0` (arithmetic result zero = exit code 1).
- `local total=${#dirs[@]}+${#files[@]}` produced the string `"3+2"` instead of the integer `5`.

---

## [1.0.0] - 2024-12-23

### Added

- **Directory Tree Generation**:
  - `generate_tree_structure` function to create a hierarchical view of the project.
  - Support for ignored files and folders specified in `.gitignore`.
  - `--print-content` option to include file contents in the output report.
  - Support for a new `.generatetreeignore` file for custom file/directory exclusion.
  - **Debug Mode**: Added a `--debug` flag to enable detailed script execution messages.

- **Ignored File Loading**:
  - `load_ignore_patterns` function to process exclusion patterns from `.gitignore` and `.generatetreeignore`.

- **File Export**:
  - Automatic generation of the `project_structure.txt` file containing the directory structure.
  - Optional inclusion of file contents in the output file.

- **Documentation**:
  - Added a developer guide detailing the workings of the `generate_tree.sh` script.

### Changed

- Updated exclusion logic to handle combined ignore patterns from `.gitignore` and `.generatetreeignore`.

### Fixed

- Error handling when attempting to read files without permission.
- Fixed issues with files and directories that include special characters in their names.
- Resolved an issue where files specified in `.generatetreeignore` were not always being ignored due to incorrect path separator handling. Forward slashes (`/`) are now correctly interpreted as path separators.

---

## [0.1.0] - 2024-12-20

### Added

- Initial project structure:
  - `generate_tree.sh` script to generate the basic directory structure.
  - Support for `.gitignore` to exclude specific files and directories.

---

## Upcoming Changes

### Planned

- Improve performance when processing large volumes of files.
- Add support for JSON output format.
- Add `--no-content-notice` flag to silence the "skipped" messages in content sections.
