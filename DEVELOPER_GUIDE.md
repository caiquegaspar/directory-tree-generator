# Developer Guide - Directory Tree Generator

This document provides an in-depth explanation of how the `generate_tree.sh` script works. It is a Bash script that generates a directory tree structure of a project, while ignoring files and folders listed in the `.gitignore` file or an additional `.generatetreeignore` file. Additionally, the script can include the contents of each listed file in the output when the `--print-content` parameter is provided.

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
}
```

#### What the code does:

- **Reads both files**: The function iterates through `.gitignore` and `.generatetreeignore` files.
- **Filters valid patterns**: Lines that are comments or empty are ignored. Valid patterns are added to the `ignored_patterns` array.
- **Combines patterns**: Patterns from both files are combined into a single list.

---

### 2. **Checking if an Entry Should Be Ignored**

The `is_ignored` function determines whether a given file or directory matches any of the exclusion patterns.

```bash
is_ignored() {
  local entry="$1"
  [[ -d "$entry" ]] && entry="${entry%/}/"

  for pattern in "${ignored_patterns[@]}"; do
    if [[ "$entry" == $pattern || "$entry" == */"$pattern" || "$entry" == "$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}
```

#### What the code does:

- **Handles directories**: Ensures directory paths are formatted with a trailing slash for matching.
- **Matches patterns**: Checks if the entry matches any pattern in the `ignored_patterns` list.
  - If a match is found, the function returns `0` (indicating the entry is ignored).
  - If no match is found, it returns `1`.

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
- **Filters ignored entries**: Before processing each entry, it checks if it matches any exclusion pattern.
- **Generates a tree structure**: For each directory and file, the function prints a structured representation with appropriate symbols (`├──`, `└──`).

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

    echo "--- File: $file ---" >>"$output_file"
    echo "" >>"$output_file"
    cat "$file" >>"$output_file" 2>/dev/null || echo "[Error reading file]" >>"$output_file"
    echo "" >>"$output_file"
  done < <(find . -type f ! -path "./.git/*")
}
```

#### What the code does:

- **Iterates through files**: Identifies all files in the project directory.
- **Appends file contents**: For each file, its contents are appended to the output file. Errors (e.g., permission issues) are logged as `[Error reading file]`.

---

### 5. **Writing the Structure to the Output File**

The `write_tree_to_file` function creates and writes the generated directory tree structure to the `project_structure.txt` file.

```bash
write_tree_to_file() {
  local output_file="$1"
  > "$output_file"
  echo "/" >> "$output_file"
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

  if [[ "$1" == "--print-content" ]]; then
    print_content=true
    shift
  fi

  load_ignore_patterns
  write_tree_to_file "project_structure.txt"

  if [[ "$print_content" == true ]]; then
    generate_file_contents "project_structure.txt"
  fi
}

main "$@"
```

#### What the code does:

- **Processes arguments**: Checks if the `--print-content` flag is provided.
- **Loads exclusion patterns**: Reads patterns from `.gitignore` and `.generatetreeignore`.
- **Generates and writes the tree structure**: Calls the functions to generate and save the directory tree.
- **Appends file contents (optional)**: If the `--print-content` flag is enabled, appends the contents of each file to the output.

---

## New Functionality: `.generatetreeignore`

The `.generatetreeignore` file is a new addition that allows users to define exclusion patterns specific to this script, without affecting the `.gitignore` file.

### Key Features:

- **Custom patterns**: Define patterns for files and directories to be excluded from the generated tree, independently of `.gitignore`.
- **Priority**: Patterns from `.generatetreeignore` are combined with `.gitignore` patterns, but they do not override `.gitignore`.

---

### Example `.generatetreeignore` File:

```plaintext
node_modules/
dist/
*.log
*.tmp
```

In this example:

- `node_modules/` and `dist/` directories will be ignored.
- Files with `.log` or `.tmp` extensions will also be excluded.

---

### Summary of Changes

- The script now reads and incorporates patterns from `.generatetreeignore`.
- Users can customize exclusions for tree generation without modifying `.gitignore`.

This new functionality ensures flexibility while maintaining compatibility with existing `.gitignore` configurations.
