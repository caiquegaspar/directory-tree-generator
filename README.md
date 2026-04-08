# Directory Tree Generator

A Bash script that generates a clean directory tree of your project — similar to the `tree` command, but with first-class `.gitignore` support and additional quality-of-life features. Output can be plain text or Markdown (great for dropping into a `docs/` folder or a wiki).

## Download

```bash
curl -LO https://github.com/caiquegaspar/directory-tree-generator/releases/download/v2.0.0/generate_tree.sh
chmod +x generate_tree.sh
```

## Features

| Feature                  | Details                                                                             |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `.gitignore` aware       | Respects all patterns from `.gitignore` automatically                               |
| Custom tree-ignore rules | Add extra exclusions in `.generatetreeignore`                                       |
| Content-skip rules       | Files in `.contentignore` appear in the tree but are never printed                  |
| Plain-text output        | Classic tree written to `project_structure.txt`                                     |
| Markdown output          | Fenced code block tree + syntax-highlighted file contents in `project_structure.md` |
| Binary file detection    | Skips images, archives, compiled files, fonts, etc. when printing content           |
| Depth limit              | `--max-depth N` to avoid exploding on monorepos                                     |
| Custom output path       | `-o path/to/file` sends output anywhere                                             |
| Auto-exclusion           | The script itself and the output file never appear in the tree                      |
| Debug mode               | `-d` streams pattern-matching detail to stderr                                      |

## Requirements

- Bash 4.0 or later (macOS ships Bash 3 — install a modern version via Homebrew: `brew install bash`)
- Linux, macOS, or Git Bash on Windows

## Usage

```
Usage: generate_tree.sh [OPTIONS]

Options:
  -o, --output FILE       Write output to FILE instead of the default name.
                            Default for --txt : project_structure.txt
                            Default for --md  : project_structure.md
      --txt               Output as plain text (default).
      --md                Output as Markdown with syntax-highlighted file content.
      --print-content     Append file contents to the output.
                          Binary files are detected and skipped automatically.
      --skip-content PAT  Show files matching PAT in the tree but omit their
                          content from --print-content. Can be repeated.
                          Same glob syntax as .gitignore.
                          E.g.: --skip-content "*.lock" --skip-content "*.json"
      --max-depth N       Limit directory recursion to N levels (0 = unlimited).
  -d, --debug             Print debug messages to stderr during execution.
  -h, --help              Show this message and exit.
```

### Quick start

```bash
./generate_tree.sh                             # plain text → project_structure.txt
./generate_tree.sh --md                        # Markdown   → project_structure.md
./generate_tree.sh --md --print-content        # Markdown with file contents
./generate_tree.sh --max-depth 3               # limit to 3 levels deep
./generate_tree.sh --md -o docs/structure.md   # custom output path
./generate_tree.sh --md --print-content --skip-content "*.lock"
```

---

## Ignore files

The script reads three optional files from the project root, each with a distinct role:

| File                  | Effect                                                               |
| --------------------- | -------------------------------------------------------------------- |
| `.gitignore`          | Files and directories **excluded from the tree entirely**            |
| `.generatetreeignore` | Same as above — extra patterns beyond `.gitignore`                   |
| `.contentignore`      | Files **shown in the tree** but whose contents are **never printed** |

### `.generatetreeignore`

```gitignore
# Skip build artifacts completely
dist/
build/
*.min.js
```

### `.contentignore`

This is the key distinction: files listed here are still visible in the tree (so you know they exist), but their contents are suppressed when using `--print-content`. This is ideal for lock files, large generated files, and anything too noisy to include in documentation.

```gitignore
# Lock files — visible in tree, content suppressed
pnpm-lock.yaml
package-lock.json
yarn.lock
Cargo.lock

# Other large generated files
*.snap
```

You can also skip content for specific patterns on the fly without creating a file:

```bash
./generate_tree.sh --md --print-content \
  --skip-content "pnpm-lock.yaml" \
  --skip-content "*.snap"
```

---

## Output examples

### Plain text (`--txt`)

```
--- Project Structure ---

/
├── .github/
│   └── workflows/
│       └── ci.yml
├── docker/
│   └── Dockerfile
├── src/
│   ├── components/
│   │   └── Button.jsx
│   └── index.js
├── .gitignore
├── package.json
└── pnpm-lock.yaml
```

### Markdown (`--md --print-content`)

`pnpm-lock.yaml` is listed in the tree. In the File Contents section it shows as skipped:

````markdown
# Project Structure

```
/
├── src/
│   └── index.js
├── package.json
└── pnpm-lock.yaml
```

---

# File Contents

## `src/index.js`

```javascript
const x = 1;
export default x;
```

## `package.json`

```json
{ "name": "myapp", "version": "1.0.0" }
```

## `pnpm-lock.yaml`

_Skipped by --skip-content._
````

---

## Supported syntax highlighting

When using `--md --print-content`, the script automatically selects the correct language tag for: Bash, Python, JavaScript, TypeScript, JSX, JSON, YAML, TOML, HTML, CSS/SCSS, SQL, Go, Rust, Java, C/C++, Ruby, PHP, Swift, Kotlin, Dockerfile, XML, and HCL/Terraform. Unknown extensions get a plain fenced block.

## Contributing

Contributions are welcome. Open an issue or submit a pull request.

## License

MIT — see [LICENSE](LICENSE) for details.
