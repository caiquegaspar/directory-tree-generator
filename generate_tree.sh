#!/bin/bash

# Global variable for debug mode
DEBUG_MODE=false

# Function to echo debug messages only when DEBUG_MODE is true
debug_echo() {
  if [[ "$DEBUG_MODE" == true ]]; then
    echo "$@"
  fi
}

# Loads the exclusion patterns from .gitignore and .generatetreeignore (if exists)
load_ignore_patterns() {
  local gitignore_file=".gitignore"
  local generatetreeignore_file=".generatetreeignore"
  ignored_patterns=()

  # Always ignore the .git/ folder
  ignored_patterns+=(".git/")

  # Load patterns from .gitignore
  if [[ -f "$gitignore_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Remove comments and extra spaces
      line="${line%%#*}" && line=$(echo "$line" | xargs)
      [[ -n "$line" ]] && ignored_patterns+=("$line")
    done <"$gitignore_file"
  fi

  # Load patterns from .generatetreeignore (if exists)
  if [[ -f "$generatetreeignore_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Remove comments and extra spaces
      line="${line%%#*}" && line=$(echo "$line" | xargs)
      [[ -n "$line" ]] && ignored_patterns+=("$line")
    done <"$generatetreeignore_file"
  fi

  debug_echo "DEBUG: Loaded ignore patterns: ${ignored_patterns[@]}"
}

# Checks if an entry should be ignored
is_ignored() {
  local entry="$1"

  # Adds a trailing slash for directories
  [[ -d "$entry" ]] && entry="${entry%/}/"

  debug_echo "DEBUG: Checking if '$entry' is ignored..."
  for pattern in "${ignored_patterns[@]}"; do
    debug_echo "DEBUG:   Comparing with pattern: '$pattern'"
    # Use pattern matching with wildcards. Also check against patterns that are relative from root with leading '/' to allow for .generatetreeignore path specification
    if [[ "$entry" == $pattern ]] || [[ "$entry" == */"$pattern" ]] || [[ "$entry" == "$pattern"* ]] || [[ "$entry" == /*"$pattern" ]]; then
      debug_echo "DEBUG:     '$entry' matches pattern '$pattern'. Ignoring."
      return 0
    fi
  done
  debug_echo "DEBUG:     '$entry' is not ignored."
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

    debug_echo "DEBUG: Checking entry: '$relative_path'"
    # Ignore entries as per .gitignore and .generatetreeignore
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
  find . -type f ! -path "./.git/*" | while IFS= read -r file; do
    # Remove leading './' for consistency
    local relative_file="${file#./}"

    # Check if the file or its directory should be ignored
    if ! is_ignored "$relative_file"; then
      echo "--- File: $relative_file ---" >>"$output_file"
      echo "" >>"$output_file"
      cat "$file" >>"$output_file" 2>/dev/null || echo "[Error reading file]" >>"$output_file"
      echo "" >>"$output_file"
      echo "" >>"$output_file"
    fi
  done
}

# Main execution
main() {
  local print_content=false
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

  # Generate the tree structure
  load_ignore_patterns
  write_tree_to_file "project_structure.txt"

  # If "--print-content" was passed, generate file contents
  if [[ "$print_content" == true ]]; then
    generate_file_contents "project_structure.txt"
  fi
}

main "$@"
