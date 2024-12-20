# Developer Guide - Directory Tree Generator

This document provides an in-depth explanation of how the `generate_tree.sh` script works. It is a Bash script that generates a directory tree structure of a project while ignoring files and folders listed in the `.gitignore` file. Additionally, the script can include the contents of each listed file in the output when the `--print-content` parameter is provided.

## How the Script Works

### 1. **Loading Exclusion Patterns from `.gitignore`**

The `load_ignore_patterns` function is responsible for loading all the exclusion patterns defined in the `.gitignore` file. The `.gitignore` file is used to list files and folders that should not be tracked by Git. The script reads this file and stores the exclusion patterns to be used later when checking which files and directories should be ignored in the tree generation.

```bash
load_ignore_patterns() {
  local gitignore_file=".gitignore"
  ignored_patterns=()

  if [[ -f "$gitignore_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}" && line=$(echo "$line" | xargs)
      [[ -n "$line" ]] && ignored_patterns+=("$line")
    done < "$gitignore_file"
  fi
}
```

#### What the code does:

- **Reads the `.gitignore` file**: The script opens and reads each line of the `.gitignore` file, ignoring blank lines and comments.
- **Stores exclusion patterns**: Valid lines (without comments) are added to an array called `ignored_patterns`, which will be used later to check if a file or directory should be ignored.

### 2. **Checking if an Entry Should Be Ignored**

The `is_ignored` function takes a file or directory path and checks if it should be ignored by comparing it with the exclusion patterns loaded earlier.

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

- **Checks if it's a directory**: If the entry is a directory, a slash (`/`) is added at the end to differentiate it from a file.
- **Checks the exclusion patterns**: For each pattern in the `.gitignore` file, it checks if the entry path matches the pattern.
  - If it matches, the function returns `0`, indicating that the entry should be ignored.
  - If it doesn't match, the function returns `1`, indicating that the entry should not be ignored.

### 3. **Generating the Directory Tree Structure**

The `generate_tree_structure` function iterates through directories and files and generates a hierarchical tree structure. The structure is displayed with indentation to indicate the levels of subdirectories.

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

- **Lists files and directories**: The script lists files and directories in the current directory, including hidden files (those starting with a dot).
- **Ignores files and directories**: Before adding a file or directory to the tree, the script checks if it should be ignored based on the `.gitignore` file.
- **Displays the tree structure**: For each directory and file, the script prints the name with an appropriate prefix to indicate its level in the tree (using the symbols `├──` and `└──`).

### 4. **Generating File Contents (Optional)**

The `generate_file_contents` function is responsible for appending the contents of each file in the directory structure to the output file, if the `--print-content` parameter is provided.

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

- **Iterates through files**: The function reads each file in the directory structure.
- **Appends file contents**: For each file, it appends its contents to the output file. If there is an error reading the file (e.g., permission issues), it appends a message stating `[Error reading file]`.

### 5. **Writing the Structure to the Output File**

The `write_tree_to_file` function creates a file called `project_structure.txt` and writes the generated structure to it.

```bash
write_tree_to_file() {
  local output_file="$1"
  > "$output_file"
  echo "/" >> "$output_file"
  generate_tree_structure "." "" >> "$output_file"
}
```

#### What the code does:

- **Creates or clears the output file**: If the file already exists, it is cleared before being rewritten.
- **Writes the structure**: The generated directory structure is appended to the `project_structure.txt` file.

### 6. **Main Execution**

The `main` function is responsible for loading the `.gitignore` patterns and calling the functions that generate and write the tree structure, along with appending the file contents if requested.

```bash
main() {
  local print_content=false

  if [[ "$1" == "--print-content" ]]; then
    print_content=true
    shift # Remove the --print-content argument
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

- **Checks for `--print-content`**: The script checks if the `--print-content` argument is passed. If so, it will generate file contents and append them to the output.
- **Generates and writes the tree structure**: The `write_tree_to_file` function is called to generate and save the directory tree structure to the output file.
- **Generates file contents (optional)**: If the `--print-content` flag was passed, the `generate_file_contents` function is called to append the file contents to the output file.
