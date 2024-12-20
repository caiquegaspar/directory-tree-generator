#!/bin/bash

# Loads the exclusion patterns from .gitignore
load_ignore_patterns() {
  local gitignore_file=".gitignore"
  ignored_patterns=()

  # Always ignore the .git/ folder
  ignored_patterns+=(".git/")

  if [[ -f "$gitignore_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Remove comments and extra spaces
      line="${line%%#*}" && line=$(echo "$line" | xargs)
      [[ -n "$line" ]] && ignored_patterns+=("$line")
    done <"$gitignore_file"
  fi
}

# Checks if an entry should be ignored
is_ignored() {
  local entry="$1"

  # Adds a trailing slash for directories
  [[ -d "$entry" ]] && entry="${entry%/}/"

  for pattern in "${ignored_patterns[@]}"; do
    # Uses fnmatch for pattern matching, such as *.log
    if [[ "$entry" == $pattern || "$entry" == */"$pattern" || "$entry" == "$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

# Generates the structure of a folder
generate_tree_structure() {
  local dir="$1"
  local indent="$2"
  local entries
  local dirs=()
  local files=()

  # Lists the items in the current directory, including hidden ones
  entries=("$dir"/* "$dir"/.*)

  for entry in "${entries[@]}"; do
    [[ ! -e "$entry" ]] && continue
    local relative_path="${entry#./}"

    # Ignore entries as per .gitignore
    is_ignored "$relative_path" && continue

    # Classifies into directories and files
    [[ -d "$entry" ]] && dirs+=("$entry") || files+=("$entry")
  done

  # Sort directories and files
  IFS=$'\n' dirs=($(sort <<<"${dirs[*]}"))
  IFS=$'\n' files=($(sort <<<"${files[*]}"))
  unset IFS

  # Print directories first
  local total=${#dirs[@]}+${#files[@]}
  for i in "${!dirs[@]}"; do
    local name=$(basename "${dirs[$i]}")
    local prefix="├── "
    [[ $((i + 1)) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}/"
    generate_tree_structure "${dirs[$i]}" "${indent}│   "
  done

  # Then print files
  for i in "${!files[@]}"; do
    local name=$(basename "${files[$i]}")
    local prefix="├── "
    [[ $((i + 1 + ${#dirs[@]})) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}"
  done
}

# Writes the structure to the output file
write_tree_to_file() {
  local output_file="$1"
  >"$output_file"
  echo "--- 📁 Project Structure ---" >>"$output_file"
  echo '' >>"$output_file" # Add blank line for better readability
  echo "/" >>"$output_file"
  generate_tree_structure "." "" >>"$output_file"
}

# Generates the file contents section
generate_file_contents() {
  local output_file="$1"
  echo "" >>"$output_file"
  echo "--- 📄 File Contents ---" >>"$output_file"
  echo "" >>"$output_file"

  # Iterate over the files, excluding ignored ones
  while IFS= read -r file; do
    # Skip directories
    [[ -d "$file" ]] && continue

    # Check if the file should be ignored
    is_ignored "$file" && continue

    echo "--- File: $file ---" >>"$output_file"
    echo "" >>"$output_file"
    cat "$file" >>"$output_file" 2>/dev/null || echo "[Error reading file]" >>"$output_file"
    echo "" >>"$output_file"
  done < <(find . -type f ! -path "./.git/*") # Finds files, excluding the .git directory
}

# Main execution
main() {
  local print_content=false

  # Check for "--print-content" parameter
  if [[ "$1" == "--print-content" ]]; then
    print_content=true
    shift # Remove the --print-content argument
  fi

  # Generate the tree structure
  load_ignore_patterns
  write_tree_to_file "project_structure.txt"

  # If "--print-content" was passed, generate file contents
  if [[ "$print_content" == true ]]; then
    generate_file_contents "project_structure.txt"
  fi
}

main "$@"
