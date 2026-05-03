---
name: bypass-profile-path-resolution
description: When read_file/write_file resolve paths through a profile's home directory mapping and fail, use absolute paths via execute_code or terminal to bypass the mapping.
category: software-development
---

# bypass-profile-path-resolution

When `read_file` returns `File not found` for paths under `~`, `$HOME`, or `/home/<user>`, the cause may be the agent profile's home directory mapping — the tool resolves paths through `<profile_dir>/home/` instead of the real filesystem home. This is common in multi-agent setups (e.g., coco-agent with isolated home).

## Trigger
- `read_file` on a path like `~/.hermes/scripts/foo.py` returns "File not found"
- But you know (or suspect) the file exists at the real `/home/<user>/` location

## Resolution steps

1. **Verify existence** with a terminal probe:
   ```bash
   test -f /home/<user>/real-path/to/file && echo EXISTS
   ```
   Or batch-check with `execute_code` using `terminal()` for multiple files.

2. **Read with absolute paths via execute_code**, which bypasses the profile mapping:
   ```python
   from hermes_tools import read_file
   content = read_file("/home/<user>/absolute/path/to/file")
   ```

3. **If unsure of the real home**, find the actual user:
   ```bash
   # The real home is usually one level up from the profile dir
   echo $HOME  # inside terminal() — gives real home
   ```

## Pitfalls

- `search_files` with a broad path like `/` will time out on large filesystems. Use targeted paths or terminal `find` with `-maxdepth`.
- The profile mapping only affects tool-level path resolution (read_file, write_file, etc.). `terminal()` and `execute_code` use real filesystem paths.
- Check the `AGENTS.md` in the discovered subdirectory for project conventions — it may contain unrelated routing rules that don't help the current task.

## When NOT to use

- If the file genuinely doesn't exist (check with `test -f` first).
- If you already have the file contents from a previous successful read (dedup applies).
