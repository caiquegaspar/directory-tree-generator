### DEVELOPER_GUIDE.md

# Developer Guide - Directory Tree Generator

This file explains in detail how the `generate_tree.sh` script works. It is a Bash script that generates a directory tree structure of a project, while ignoring files and folders listed in the `.gitignore` file.

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

### 4. **Writing the Structure to the Output File**

The `write_tree_to_file` function creates a file called `my_tree_structure.yml` and writes the generated structure to it.

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
- **Writes the structure**: The generated directory structure is appended to the `my_tree_structure.yml` file.

### 5. **Main Execution**

The `main` function is responsible for loading the `.gitignore` patterns and calling the functions that generate and write the tree structure.

```bash
main() {
  load_ignore_patterns
  write_tree_to_file "my_tree_structure.yml"
}

main
```

#### What the code does:

- **Loads the `.gitignore` patterns**: The `load_ignore_patterns` function is called to load the exclusion patterns.
- **Writes the structure**: The `write_tree_to_file` function is called to generate and save the directory tree structure to the output file.
