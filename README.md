### README.md

# Directory Tree Generator

This is a Bash script that generates a directory tree structure of a project, similar to the `tree` command, but with the additional functionality of ignoring files and directories listed in the `.gitignore` file. The generated structure is saved in a file called `my_tree_structure.yml`.

## Features

- **Ignores files and directories**: The script ignores files and folders specified in the `.gitignore`.
- **Generates directory tree**: It creates a hierarchical directory structure.
- **Output to file**: The generated structure is saved to `my_tree_structure.yml`.

## How to Use

### Prerequisites

- The script is written in Bash, so you need to have a Bash environment, such as Linux, macOS, or Git Bash on Windows.
- The `.gitignore` file must be present in the root directory of your project with the files and directories you want to ignore.

### Steps

1. Place the `generate_tree.sh` script in the root directory of your project.
2. Run the script:

   ```bash
   chmod +x generate_tree.sh

   ./generate_tree.sh
   ```

3. The generated structure will be saved in `my_tree_structure.yml`.

### Example Output

After running the script, the `my_tree_structure.yml` file will contain a directory structure similar to the following:

```
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

## How the Code Works

1. **Loading `.gitignore` patterns**: The script loads exclusion patterns from the `.gitignore`.
2. **Exclusion check**: It compares each file and directory against the exclusion patterns to decide whether to ignore it.
3. **Generating the directory structure**: The script generates a hierarchical tree structure of the directories and files.
4. **Saving the structure**: The generated structure is saved to a file called `my_tree_structure.yml`.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
