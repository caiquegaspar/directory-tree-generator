# Developer Guide — Directory Tree Generator

This document covers the internal design of `generate_tree.sh`, every non-trivial decision, the bugs fixed from v1, and guidance for extending the script.

---

## Architecture overview

```
Constants & state
       │
       ▼
load_ignore_patterns ──────────────────────────────────────┐
  reads .gitignore, .generatetreeignore → ignored_patterns  │
  reads .contentignore               → content_skip_patterns│
       │                                                     │
       ▼                                                     │
generate_tree_structure (recursive)                          │
  calls is_ignored()        ◄── uses ignored_patterns        │
  populates collected_files                                  │
       │                                                     │
       ├──────────────┐                                      │
       ▼              ▼                                      │
  write_txt      write_md                                    │
  calls is_content_skipped() ◄── uses content_skip_patterns ─┘
  calls is_binary_file()
       │
       ▼
     main (CLI entry, argument parsing)
```

`generate_tree_structure` has one side effect beyond printing: it populates the global `collected_files` array as it walks the tree. Both output writers consume that array for the `--print-content` section, avoiding a second `find` pass over the filesystem and guaranteeing that tree and content sections stay in sync.

---

## Shell settings

```bash
set -euo pipefail
shopt -s nullglob dotglob
```

`set -euo pipefail` enforces strict error handling. `-e` exits on any unhandled non-zero exit; `-u` treats unset variables as errors; `-o pipefail` makes pipelines fail if any stage fails.

`shopt -s nullglob` causes a glob that matches nothing to expand to an empty list instead of the literal string. Without it, `for entry in "$dir"/*` on an empty directory iterates once with the literal value `"$dir/*"`, which would then fail the `-e` existence check silently.

`shopt -s dotglob` makes `*` include hidden files (those starting with `.`). This is critical for capturing `.github/`, `.env`, `.gitignore`, etc. in a single glob. Earlier versions used both `"$dir"/*` and `"$dir"/.*`, which caused every dotfile to appear **twice** in the output.

---

## Three ignore layers

The script uses three distinct arrays to implement its three-tier ignore system:

| Array                   | Source                                   | Effect                                                                           |
| ----------------------- | ---------------------------------------- | -------------------------------------------------------------------------------- |
| `ignored_patterns`      | `.gitignore`, `.generatetreeignore`      | File/directory completely excluded from tree                                     |
| `content_skip_patterns` | `.contentignore`, `--skip-content` flags | File shown in tree, content suppressed                                           |
| `BINARY_EXTENSIONS`     | hardcoded constant                       | File shown in tree, content suppressed (detected by extension or `file` command) |

Content-skip is checked in the output writers (`write_txt`, `write_md`), not during tree traversal. This is by design: the tree walk must remain unaware of the content layer so that the two concerns don't bleed into each other.

---

## Pattern loading

```bash
load_ignore_patterns() {
  ignored_patterns+=(".git/")

  local f line
  for f in ".gitignore" ".generatetreeignore"; do
    ...
    done < "$f"
  done

  if [[ -f ".contentignore" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      ...
      [[ -n "$line" ]] && content_skip_patterns+=("$line")
    done < ".contentignore"
  fi
}
```

Whitespace trimming uses pure bash parameter expansion — no subshells:

```bash
line="${line%%#*}"                             # strip inline comment
line="${line#"${line%%[^[:space:]]*}"}"        # ltrim
line="${line%"${line##*[^[:space:]]}"}"        # rtrim
```

The original code used `echo "$line" | xargs` for this, spawning two processes per line and breaking on inputs like `-n` or lines containing only whitespace.

The `|| [[ -n "$line" ]]` guard on `read` handles files that lack a trailing newline — without it, the last line is silently dropped.

---

## Pattern matching

```bash
is_ignored() {
  local entry="$1"
  [[ -d "$entry" ]] && entry="${entry%/}/"

  local pattern
  for pattern in "${ignored_patterns[@]}"; do
    # shellcheck disable=SC2254
    if [[ "$entry" == $pattern      || \
          "$entry" == */"$pattern"  || \
          "$entry" == "$pattern"/*  ]]; then
      return 0
    fi
  done
  return 1
}
```

The three conditions handle the main classes of gitignore-style matching:

| Condition                  | Example pattern | Matches                        |
| -------------------------- | --------------- | ------------------------------ |
| `"$entry" == $pattern`     | `*.log`         | `debug.log`, `logs/app.log`    |
| `"$entry" == */"$pattern"` | `Dockerfile`    | `docker/Dockerfile`            |
| `"$entry" == "$pattern"/*` | `node_modules/` | `node_modules/lodash/index.js` |

`$pattern` is intentionally **unquoted** in the first condition. In bash `[[`, the right-hand side of `==` is treated as a glob pattern when unquoted. This is what allows `*.log` to match `debug.log`. Quoting it (`"$pattern"`) would make it a literal string comparison, silently breaking every wildcard rule. The `# shellcheck disable=SC2254` comment is intentional.

`is_content_skipped` uses the same two-condition approach, omitting the directory-traversal condition since it only ever receives file paths.

**Known limitation:** This is not a full gitignore parser. Negation (`!important.log`), anchored patterns (`/build`), and `**` double-star matching are not supported. For full compliance, replace `is_ignored` with a call to `git check-ignore -q "$entry"`.

---

## Tree generation and arithmetic safety

```bash
generate_tree_structure() {
  ...
  local total=$(( ${#dirs[@]} + ${#files[@]} ))
  local idx=0

  for entry in "${dirs[@]}"; do
    idx=$(( idx + 1 ))
    ...
  done
}
```

A subtle but important rule: `(( expression ))` returns exit code 1 when the arithmetic result is zero. With `set -e` active, this silently exits the script.

```bash
# DANGEROUS with set -e — exits when idx is 0:
(( idx++ ))

# SAFE — assignment always exits 0:
idx=$(( idx + 1 ))
```

The v1 script also had a bug where `local total=${#dirs[@]}+${#files[@]}` created the **string** `"3+2"` rather than the integer `5`. It happened to work in `-lt` comparisons because bash evaluates arithmetic in that context, but it was unintentional and a ticking time bomb.

---

## `printf` and the `--` trap

Any format string starting with `--` triggers `printf: --: invalid option` on bash builtins. The original code used:

```bash
printf '--- Project Structure ---\n'  # ❌ breaks on some systems
```

The fix separates the format string from the data:

```bash
printf '%s\n' "--- Project Structure ---"  # ✅ always safe
```

---

## `dotglob` and the double-entry bug

The original script used:

```bash
entries=("$dir"/* "$dir"/.*)
```

With `shopt -s dotglob`, `"$dir"/*` already includes hidden entries. Adding `"$dir"/.*` then produces every dotfile twice in the array. The fix is to enable `dotglob` once at the top and use only `"$dir"/*`.

---

## Content-skip in output writers

Both `write_txt` and `write_md` check `is_content_skipped` alongside `is_binary_file`:

````bash
for f in "${collected_files[@]}"; do
  if is_binary_file "$f"; then
    printf '_Binary file - skipped._\n'
  elif is_content_skipped "$f"; then
    printf '_Skipped by --skip-content._\n'
  else
    lang="$(md_lang_for_file "$f")"
    printf '```%s\n' "$lang"
    cat "$f"
    printf '\n```\n'
  fi
done
````

The file still appears as a heading in the content section (e.g. `## 'pnpm-lock.yaml'`). This is intentional: the reader can see the file exists and know it was deliberately skipped, rather than wondering why it vanished from the content section without explanation.

---

## Sorting with `mapfile`

```bash
(( ${#dirs[@]} > 0 )) && mapfile -t dirs < <(printf '%s\n' "${dirs[@]}" | sort)
```

The original code used `IFS=$'\n' dirs=($(sort ...))` which breaks on filenames containing newlines and is harder to read. `mapfile -t` (bash 4+) reads lines into an array cleanly. The guard `(( ${#dirs[@]} > 0 ))` prevents running `mapfile` on an empty array, which would produce a spurious empty element — and also prevents `(( 0 ))` from exiting under `set -e`.

---

## CLI argument parsing

The parser handles both `--flag value` and `--flag=value` forms for all options that take arguments:

```bash
--skip-content)
  content_skip_patterns+=("$2"); shift ;;
--skip-content=*)
  content_skip_patterns+=("${1#*=}") ;;
```

`--skip-content` can be passed multiple times and each value is appended to `content_skip_patterns`. Patterns supplied via CLI are merged with those loaded from `.contentignore` — they are additive.

---

## Known limitations

- **Gitignore spec compliance:** Negation (`!important.log`), directory-anchored patterns (`/build`), and `**` globbing are not supported.
- **Bash 4+ required:** `${var,,}` (lowercase) and `mapfile` both require bash 4. macOS ships bash 3.2 by default — install via `brew install bash`.
- **Symlinks:** Followed for the `-e` existence check, not specially annotated in the tree.
- **Non-UTF-8 filenames:** Tree renders correctly but terminal output may be garbled.

---

## Extending the script

### Adding a new output format (e.g. JSON)

1. Add a `write_json` function mirroring `write_txt` / `write_md`.
2. Add `--json` to the `case` block in `main`.
3. Add `DEFAULT_JSON_OUTPUT` to constants and extend the filename resolution block.

`generate_tree_structure` outputs to stdout and populates `collected_files` regardless of format, so both are immediately available to any new writer.

### Full gitignore compliance

Replace `is_ignored` with:

```bash
is_ignored() {
  git check-ignore -q "$1" 2>/dev/null
}
```

This delegates matching to Git itself and handles every edge case. Trade-offs: requires a Git repository and is significantly slower on large trees because it spawns a process per file.
