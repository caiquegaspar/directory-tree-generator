# Developer Guide - Directory Tree Generator

This document provides an in-depth explanation of how the `generate_tree.sh` script works. It is a Bash script that generates a directory tree structure of a project, while ignoring files and folders listed in the `.gitignore` file or an additional `.generatetreeignore` file. Additionally, the script can include the contents of each listed file in the output when the `--print-content` parameter is provided, and now includes a debug mode activated by the `--debug` parameter.

---

## How the Script Works

### 1. **Loading Exclusion Patterns**

The script supports two sources of exclusion patterns:

- `.gitignore`: The file used by Git to ignore files and directories.
- `.generatetreeignore`: A custom file that allows additional patterns specific to this script.

The `load_ignore_patterns` function is responsible for reading both files and consolidating the exclusion patterns.

```bash
load_ignore_patterns() {
  local ignore_files=(".gitignore" ".generatetreeignore")
  ignored_patterns=()

  for ignore_file in "${ignore_files[@]}"; do
    if [[ -f "$ignore_file" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}" && line=$(echo "$line" | xargs)
        [[ -n "$line" ]] && ignored_patterns+=("$line")
      done < "$ignore_file"
    fi
  done

  debug_echo "DEBUG: Loaded ignore patterns: ${ignored_patterns[@]}"
}
```

#### What the code does:

- **Reads both files**: The function iterates through `.gitignore` and `.generatetreeignore` files.
- **Filters valid patterns**: Lines that are comments or empty are ignored. Valid patterns are added to the `ignored_patterns` array.
- **Combines patterns**: Patterns from both files are combined into a single list.
- **Debug Output**: When debug mode is enabled, the loaded ignore patterns are printed to the console.

---

### 2. **Checking if an Entry Should Be Ignored**

The `is_ignored` function determines whether a given file or directory matches any of the exclusion patterns.

```bash
is_ignored() {
  local entry="$1"
  [[ -d "$entry" ]] && entry="${entry%/}/"

  debug_echo "DEBUG: Checking if '$entry' is ignored..."
  for pattern in "${ignored_patterns[@]}"; do
    debug_echo "DEBUG:   Comparing with pattern: '$pattern'"
    if [[ "$entry" == "$pattern" || "$entry" == */"$pattern" || "$entry" == "$pattern"* || "$entry" == /*"$pattern" ]]; then
      debug_echo "DEBUG:     '$entry' matches pattern '$pattern'. Ignoring."
      return 0
    fi
  done
  debug_echo "DEBUG:     '$entry' is not ignored."
  return 1
}
```

#### What the code does:

- **Handles directories**: Ensures directory paths are formatted with a trailing slash for matching.
- **Matches patterns**: Checks if the entry matches any pattern in the `ignored_patterns` list.
  - If a match is found, the function returns `0` (indicating the entry is ignored).
  - If no match is found, it returns `1`.
- **Debug Output**: When debug mode is enabled, the function prints messages indicating which entry is being checked and the patterns it's being compared against.

---

### 3. **Generating the Directory Tree Structure**

The `generate_tree_structure` function creates a hierarchical representation of the directory structure, excluding ignored files and directories.

```bash
generate_tree_structure() {
  local dir="$1"
  local indent="$2"
  local entries
  local dirs=()
  local files=()

  entries=("$dir"/* "$dir"/.*)

  for entry in "${entries[@]}"; do
    [[ ! -e "$entry" ]] && continue
    local relative_path="${entry#./}"

    debug_echo "DEBUG: Checking entry: '$relative_path'"
    is_ignored "$relative_path" && continue

    [[ -d "$entry" ]] && dirs+=("$entry") || files+=("$entry")
  done

  IFS=$'\n' dirs=($(sort <<<"${dirs[*]}"))
  IFS=$'\n' files=($(sort <<<"${files[*]}"))
  unset IFS

  local total=${#dirs[@]}+${#files[@]}
  for i in "${!dirs[@]}"; do
    local name=$(basename "${dirs[$i]}")
    local prefix="├── "
    [[ $((i + 1)) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}/"
    generate_tree_structure "${dirs[$i]}" "${indent}│   "
  done

  for i in "${!files[@]}"; do
    local name=$(basename "${files[$i]}")
    local prefix="├── "
    [[ $((i + 1 + ${#dirs[@]})) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}"
  done
}
```

#### What the code does:

- **Lists files and directories**: The script gathers all visible and hidden entries in the current directory.
- **Filters ignored entries**: Before processing each entry, it checks if it matches any exclusion pattern using the `is_ignored` function.
- **Generates a tree structure**: For each directory and file that is not ignored, the function prints a structured representation with appropriate symbols (`├──`, `└──`).
- **Debug Output**: When debug mode is enabled, the function prints messages indicating which entry is being checked for exclusion.

---

### 4. **Generating File Contents (Optional)**

The `generate_file_contents` function appends the contents of each file in the directory structure to the output file, if the `--print-content` option is enabled.

```bash
generate_file_contents() {
  local output_file="$1"
  echo "" >>"$output_file"
  echo "--- 📄 File Contents ---" >>"$output_file"
  echo "" >>"$output_file"

  while IFS= read -r file; do
    [[ -d "$file" ]] && continue
    local relative_file="${file#./}"

    if ! is_ignored "$relative_file"; then
      echo "--- File: $relative_file ---" >>"$output_file"
      echo "" >>"$output_file"
      cat "$file" >>"$output_file" 2>/dev/null || echo "[Error reading file]" >>"$output_file"
      echo "" >>"$output_file"
      echo "" >>"$output_file"
    fi
  done < <(find . -type f ! -path "./.git/*")
}
```

#### What the code does:

- **Iterates through files**: Identifies all files in the project directory.
- **Filters ignored entries**: Before processing each file, it checks if it matches any exclusion pattern using the `is_ignored` function.
- **Appends file contents**: For each non-ignored file, its contents are appended to the output file. Errors (e.g., permission issues) are logged as `[Error reading file]`.

---

### 5. **Writing the Structure to the Output File**

The `write_tree_to_file` function creates and writes the generated directory tree structure to the `project_structure.txt` file.

```bash
write_tree_to_file() {
  local output_file="$1"
  > "$output_file"
  echo "--- 📁 Project Structure ---" >>"$output_file"
  echo '' >>"$output_file"
  echo "/" >>"$output_file"
  generate_tree_structure "." "" >> "$output_file"
}
```

#### What the code does:

- **Creates or clears the output file**: Ensures the output file starts empty.
- **Writes the directory structure**: Appends the generated tree structure to the output file.

---

### 6. **Main Execution**

The `main` function orchestrates the script's execution by calling the necessary functions based on the provided arguments.

```bash
main() {
  local print_content=false
  local DEBUG_MODE=false
  local args=("$@")

  # Process arguments
  for arg in "${args[@]}"; do
    case "$arg" in
      "--print-content")
        print_content=true
        ;;
      "--debug")
        DEBUG_MODE=true
        ;;
      *)
        echo "Unknown argument: $arg"
        exit 1
        ;;
    esac
  done

  # Set the global DEBUG_MODE variable
  export DEBUG_MODE

  load_ignore_patterns
  write_tree_to_file "project_structure.txt"

  if [[ "$print_content" == true ]]; then
    generate_file_contents "project_structure.txt"
  fi
}

main "$@"
```

#### What the code does:

- **Processes arguments**: Checks if the `--print-content` and `--debug` flags are provided.
- **Sets Debug Mode**: The `DEBUG_MODE` variable is set based on the presence of the `--debug` flag and exported to be accessible by other functions.
- **Loads exclusion patterns**: Reads patterns from `.gitignore` and `.generatetreeignore`.
- **Generates and writes the tree structure**: Calls the functions to generate and save the directory tree.
- **Appends file contents (optional)**: If the `--print-content` flag is enabled, appends the contents of each file to the output.

---

## New Functionality: Debug Mode

The script now includes a debug mode that can be enabled using the `--debug` parameter. This mode provides detailed output about the script's execution, which can be helpful for understanding how the script is processing files and ignore patterns.

### Enabling Debug Mode

To enable debug mode, simply include the `--debug` parameter when running the script:

```bash
./generate_tree.sh --debug
```

You can also combine it with other parameters:

```bash
./generate_tree.sh --print-content --debug
```

### Debug Output

When debug mode is enabled, the script will print the following information to the console:

- **Loaded ignore patterns**: Displays the list of patterns loaded from `.gitignore` and `.generatetreeignore`.
- **File exclusion checks**: Shows each file and directory being checked against the ignore patterns, and whether it is being ignored or not.
- **Pattern matching**: Indicates which specific ignore pattern matched a given file or directory, if a match occurs.

### `DEBUG_MODE` Variable and `debug_echo` Function

- **`DEBUG_MODE`**: This global variable (set in the `main` function based on the `--debug` argument) controls whether debug messages are displayed.
- **`debug_echo()`**: This helper function is used throughout the script to print debug messages. It only outputs its arguments if the `DEBUG_MODE` variable is set to `true`.

```bash
# Global variable for debug mode
DEBUG_MODE=false

# Function to echo debug messages only when DEBUG_MODE is true
debug_echo() {
  if [[ "$DEBUG_MODE" == true ]]; then
    echo "$@"
  fi
}
```

By using this structure, debug messages can be easily added or removed from the script by simply calling `debug_echo` instead of `echo` directly.

This new functionality provides developers with a valuable tool for understanding and troubleshooting the script's behavior.
