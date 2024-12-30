# Changelog

All notable changes to this project will be documented in this file.

This format follows the guidelines of [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2024-12-23

### Added

- **Directory Tree Generation**:

  - `generate_tree_structure` function to create a hierarchical view of the project.
  - Support for ignored files and folders specified in `.gitignore`.
  - `--print-content` option to include file contents in the output report.
  - Support for a new `.generatetreeignore` file for custom file/directory exclusion.

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

---

## [0.1.0] - 2024-12-20

### Added

- Initial project structure:
  - `generate_tree.sh` script to generate the basic directory structure.
  - Support for `.gitignore` to exclude specific files and directories.

---

## Upcoming Changes

### Planned

- Add support for multiple output formats, such as JSON and Markdown.
- Improve performance when processing large volumes of files.
- Create automated tests to validate all script functionalities.
