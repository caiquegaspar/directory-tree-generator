# Directory Tree Generator

This is a Bash script that generates a directory tree structure of a project, similar to the `tree` command, but with the additional functionality of ignoring files and directories listed in the `.gitignore` file. The generated structure is saved in a file called `project_structure.txt`. Additionally, you can optionally include the contents of the listed files in the output.

## Features

- **Ignores files and directories**: The script ignores files and folders specified in the `.gitignore`.
- **Generates directory tree**: It creates a hierarchical directory structure.
- **Output to file**: The generated structure is saved to `project_structure.txt`.
- **File contents (optional)**: With the `--print-content` parameter, the contents of each file in the directory structure are appended to the output file.

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

3. The generated structure will be saved in `project_structure.txt`. If you want to include file contents, use the `--print-content` argument:

   ```bash
   ./generate_tree.sh --print-content
   ```

   This will append the contents of each file listed in the directory structure to the `project_structure.txt`.

### Example Output

#### Without `--print-content`

After running the script, the `project_structure.txt` file will contain a directory structure similar to the following:

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

If you run the script with the `--print-content` parameter, the contents of the files will be appended to the file:

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

--- File: docker/Dockerfile ---

FROM node:18-alpine AS builder

RUN apk add --no-cache \
    bash \
    libstdc++ \
    openssl \
    libc6-compat

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run prisma:generate
RUN npm run build

FROM node:18-alpine

RUN apk add --no-cache \
    bash \
    libstdc++ \
    openssl \
    libc6-compat

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
COPY docker/start.sh ./start.sh

RUN chmod +x ./start.sh

EXPOSE 3000

CMD ["./start.sh"]
```

## How the Code Works

1. **Loading `.gitignore` patterns**: The script loads exclusion patterns from the `.gitignore`.
2. **Exclusion check**: It compares each file and directory against the exclusion patterns to decide whether to ignore it.
3. **Generating the directory structure**: The script generates a hierarchical tree structure of the directories and files.
4. **Saving the structure**: The generated structure is saved to a file called `project_structure.txt`.
5. **Generating file contents (optional)**: If the `--print-content` parameter is passed, the script appends the content of each file to the output file.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
