# Project Structure

```
/
├── test_folder/
│   ├── depth2folder/
│   │   ├── depth3folder/
│   │   │   └── depth4file.txt
│   │   └── depth3file.txt
│   ├── dont_ignore.txt
│   └── generated_with_-o_param.md
├── .contentignore
├── .generatetreeignore
├── .gitignore
└── project_structure.txt
```

---

# File Contents

## `.contentignore`

```
# project_structure.txt
```

## `.generatetreeignore`

```
ignore_test.txt
test_folder/ignore.txt
*.log
```

## `.gitignore`

```
# .gitignore to test the ignore logic
# project_structure.md
```

## `project_structure.txt`

_Skipped by --skip-content._

## `test_folder/dont_ignore.txt`

```
Just a file to test the logic of the .generatetreeignore file.
```

## `test_folder/generated_with_-o_param.md`

```markdown
# Project Structure

```
/
├── test_folder/
│   ├── depth2folder/
│   │   ├── depth3folder/
│   │   │   └── depth4file.txt
│   │   └── depth3file.txt
│   └── dont_ignore.txt
├── .contentignore
├── .generatetreeignore
├── .gitignore
├── project_structure.md
└── project_structure.txt
```

```

## `test_folder/depth2folder/depth3file.txt`

```
Just a file to test the logic of the --max-depth param.
```

## `test_folder/depth2folder/depth3folder/depth4file.txt`

```
Just a file to test the logic of the --max-depth param.
```
