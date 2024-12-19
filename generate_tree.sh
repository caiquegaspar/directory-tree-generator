#!/bin/bash

# Carrega os padrões de exclusão do .gitignore
load_ignore_patterns() {
  local gitignore_file=".gitignore"
  ignored_patterns=()

  if [[ -f "$gitignore_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Remove comentários e espaços extras
      line="${line%%#*}" && line=$(echo "$line" | xargs)
      [[ -n "$line" ]] && ignored_patterns+=("$line")
    done <"$gitignore_file"
  fi
}

# Verifica se uma entrada deve ser ignorada
is_ignored() {
  local entry="$1"

  # Adiciona barra no final para diretórios
  [[ -d "$entry" ]] && entry="${entry%/}/"

  for pattern in "${ignored_patterns[@]}"; do
    # Usando fnmatch para correspondência de padrões, como *.log
    if [[ "$entry" == $pattern || "$entry" == */"$pattern" || "$entry" == "$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

# Gera a estrutura de uma pasta
generate_tree_structure() {
  local dir="$1"
  local indent="$2"
  local entries
  local dirs=()
  local files=()

  # Lista os itens no diretório atual, incluindo ocultos
  entries=("$dir"/* "$dir"/.*)

  for entry in "${entries[@]}"; do
    [[ ! -e "$entry" ]] && continue
    local relative_path="${entry#./}"

    # Ignorar entradas conforme .gitignore
    is_ignored "$relative_path" && continue

    # Classifica em diretórios e arquivos
    [[ -d "$entry" ]] && dirs+=("$entry") || files+=("$entry")
  done

  # Ordena diretórios e arquivos
  IFS=$'\n' dirs=($(sort <<<"${dirs[*]}"))
  IFS=$'\n' files=($(sort <<<"${files[*]}"))
  unset IFS

  # Imprime diretórios primeiro
  local total=${#dirs[@]}+${#files[@]}
  for i in "${!dirs[@]}"; do
    local name=$(basename "${dirs[$i]}")
    local prefix="├── "
    [[ $((i + 1)) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}/"
    generate_tree_structure "${dirs[$i]}" "${indent}│   "
  done

  # Depois imprime arquivos
  for i in "${!files[@]}"; do
    local name=$(basename "${files[$i]}")
    local prefix="├── "
    [[ $((i + 1 + ${#dirs[@]})) -eq $total ]] && prefix="└── "
    echo "${indent}${prefix}${name}"
  done
}

# Escreve a estrutura no arquivo de saída
write_tree_to_file() {
  local output_file="$1"
  >"$output_file"
  echo "/" >>"$output_file"
  generate_tree_structure "." "" >>"$output_file"
}

# Execução principal
main() {
  load_ignore_patterns
  write_tree_to_file "my_tree_structure.yml"
}

main
