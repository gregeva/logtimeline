---
paths:
  - "process/**"
  - "build/**"
  - "tests/**"
  - "prototype/**"
---
# Scripts and tools of the development process

- Any script whose output a person reads in a terminal, prototypes and tools
  included, follows `docs/terminal-output.md`: the UTF-8 code page set on
  Windows, no `stty` or `tput`, every glyph one cell wide in Windows Terminal,
  a colour that must hold its value (and anything bold) a 256-colour or 24-bit
  code, never a basic one. Windows output is checked in a new window, not the
  agent's shell.
- Interpreters come from `PATH` (`perl`, `bash`, `python3`), never from a path
  to an install (`docs/development-environment.md`).
- A new script is marked executable in the index before it is committed
  (`git update-index --add --chmod=+x <script>`): a Windows checkout has no
  executable bit (`docs/toolchain-guidance.md` § Windows development host).
- A header comment describes what the script does now; no change history.
