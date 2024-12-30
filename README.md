# Directory Tree Generator

This is a Bash script that generates a directory tree structure of a project, similar to the `tree` command, but with enhanced functionality. It respects files and directories listed in `.gitignore` and `.generatetreeignore`. The generated structure is saved in a file called `project_structure.txt`. Additionally, you can optionally include the contents of the listed files in the output.

## Download

You can download directly using the link below:

- [Download File](https://github.com/caiquegaspar/directory-tree-generator/releases/download/v1.0.0/generate_tree.sh)

## Features

- **Ignores files and directories**: Respects patterns specified in `.gitignore` and `.generatetreeignore`.
- **Custom ignore rules**: Allows additional exclusion rules via `.generatetreeignore`.
- **Generates directory tree**: Creates a hierarchical directory structure.
- **Output to file**: Saves the generated structure to `project_structure.txt`.
- **File contents (optional)**: Includes the contents of each file in the directory structure with the `--print-content` parameter.

## How to Use

### Prerequisites

- Bash environment (Linux, macOS, or Git Bash on Windows).
- A `.gitignore` or `.generatetreeignore` file to define ignored files and directories (optional).

### Steps

1. Place the `generate_tree.sh` script in the root directory of your project.
2. Run the script:

   ```bash
   chmod +x generate_tree.sh

   ./generate_tree.sh
   ```

3. The generated structure will be saved in `project_structure.txt`. To include file contents, use the `--print-content` argument:

   ```bash
   ./generate_tree.sh --print-content
   ```

### Using `.generatetreeignore`

To add custom exclusions beyond `.gitignore`, create a `.generatetreeignore` file in the root of your project. The syntax is the same as `.gitignore`.

#### Example `.generatetreeignore` File:

```bash
# Ignore all `.log` files
*.log

# Ignore specific folders
/temp/
```

Patterns in `.generatetreeignore` will be processed in addition to `.gitignore`.

### Example Output

#### Without `--print-content`

The `project_structure.txt` file will contain a directory structure similar to:

```
--- 📁 Project Structure ---

/
├── .github/
│   └── workflows/
│       └── docker-image.yml
├── docker/
│   ├── Dockerfile
│   └── start.sh
├── prisma/
│   ├── migrations/
│   │   └── 0001_initial/
│   │   │   └── migration.sql
│   └── schema.prisma
...
```

#### With `--print-content`

Running the script with `--print-content` will append the contents of each file listed in the structure:

```
--- 📁 Project Structure ---

/
├── .github/
│   └── workflows/
│       └── docker-image.yml
├── docker/
│   ├── Dockerfile
│   └── start.sh
├── prisma/
│   ├── migrations/
│   │   └── 0001_initial/
│   │   │   └── migration.sql
│   └── schema.prisma
...

--- 📄 File Contents ---

--- File: .github/workflows/docker-image.yml ---

name: Docker Image CI

on:
  push:
    branches:
      - "**"
  pull_request:
    branches:
      - "**"

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker Image
        run: docker buildx build --file docker/Dockerfile --tag my-project-image:${{ github.sha }} --tag my-project-image:latest --load .
```

## How It Works

1. **Loading Ignore Patterns**:

   - Loads exclusion patterns from `.gitignore` and `.generatetreeignore`.
   - Combines patterns from both files for a unified exclusion list.

2. **Exclusion Check**:

   - Each file and directory is checked against the combined list of patterns to determine if it should be ignored.

3. **Generating the Directory Tree**:

   - Recursively scans the directory structure to create a hierarchical tree.

4. **Saving the Output**:

   - The directory tree is saved in `project_structure.txt`.

5. **Including File Contents (Optional)**:
   - If `--print-content` is specified, the contents of non-ignored files are appended to the output.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
