# Windows Character Rendering (#13)

## Problem Statement

Windows command line (cmd.exe, PowerShell, and even Windows Terminal) renders block characters differently than macOS/Linux terminals. The full block character (`█`, U+2588) fills the entire character cell with no spacing, which:

1. Eliminates visual separation between bar graph segments
2. Breaks the highlight functionality that uses background color to show behind the character
3. Makes the heatmap difficult to read

## Current Implementation

Block characters defined in `ltl` (lines ~205-215):
```perl
my %blocks = (
    # Full and partial blocks
    'A' => '█',    # Full block (U+2588)
    'B' => '▓',    # Dark shade (U+2593) - ~75% fill
    'C' => '▒',    # Medium shade (U+2592) - ~50% fill
    'D' => '░',    # Light shade (U+2591) - ~25% fill
    # Half blocks - show 50% background color
    'E' => '▀',    # Upper half block (U+2580)
    'F' => '▄',    # Lower half block (U+2584)
    # Squares - large to small
    'G' => '■',    # Black square (U+25A0)
    'H' => '▪',    # Black small square (U+25AA)
    'I' => '•',    # Bullet (U+2022)
);
```

Current usage:
- **Occurrences bar graph** (line ~2779): Uses `$blocks{'A'}` (full block) for HTTP status codes, `$blocks{$default_chart_block}` for others
- **Heatmap** (line ~2528, ~2531): Uses hardcoded `█` (full block)
- Default chart block is `'A'` (full block) set at line ~216

Platform detection already exists (`$^O eq 'MSWin32'`) and is used for:
- UTF-8 code page setting (line 68)
- Memory tracking method (lines 537-548)
- Background color auto-detection skip (line 461)

## Research: Windows Console Architecture

Both cmd.exe and PowerShell (legacy 5.x) use **conhost.exe** as their underlying console host. This means:
- Rendering is handled by conhost, not by the shell itself
- cmd.exe and PowerShell should render characters identically when using conhost
- The real distinction is between console hosts, not shells

### Console Hosts
1. **conhost.exe (legacy)**: The traditional Windows console host
   - Used by: cmd.exe, PowerShell 5.x, any console app not in Windows Terminal
   - Rendering depends on font selection (raster fonts vs TrueType)
   - Full block (`█`) may fill entire character cell with no gaps

2. **Windows Terminal**: Modern terminal application (Windows 10 2004+)
   - Completely different rendering engine
   - Better font support and anti-aliasing
   - Can be detected via `$ENV{WT_SESSION}` environment variable
   - Hosts any shell (cmd, PowerShell, WSL, etc.)

### Detection Methods

| What to Detect | How | Perl Code |
|----------------|-----|-----------|
| Windows OS | `$^O` | `$^O eq 'MSWin32'` |
| Windows Terminal | `WT_SESSION` env var | `defined $ENV{WT_SESSION}` |

**Note:** Detecting PowerShell vs cmd.exe is not useful for rendering decisions since both use conhost. The meaningful detection is whether we're running in Windows Terminal or legacy conhost.

## Testing Approach

Testing will be done directly with the application by modifying the `$default_chart_block` variable to test different characters.

### Characters to Test

| Key | Char | Name | Expected Behavior |
|-----|------|------|-------------------|
| A | `█` | Full block | Current default - no BG visible |
| B | `▓` | Dark shade | ~75% fill, some BG visible |
| C | `▒` | Medium shade | ~50% fill, BG visible |
| D | `░` | Light shade | ~25% fill, most BG visible |
| E | `▀` | Upper half block | BG visible in lower half |
| F | `▄` | Lower half block | BG visible in upper half |
| G | `■` | Black square | Medium size square |
| H | `▪` | Black small square | Small, most BG visible |

### Testing Procedure

1. Modify line ~216 to change `$default_chart_block` to test each character (e.g., `'E'` for upper half block)
2. Run the application with highlighting enabled: `ltl -h "pattern" -n 5 <logfile>`
3. Run the application with heatmap: `ltl -hm -n 5 <logfile>`
4. Observe and document:
   - Is the background highlight color visible?
   - Is there visual separation between bar segments?
   - Is the heatmap readable?

### Testing Environments

Test in these environments and document results:
1. **macOS Terminal** - baseline reference
2. **Windows conhost via cmd.exe** - legacy Windows console
3. **Windows conhost via PowerShell 5.x** - verify same as cmd.exe (expected)
4. **Windows Terminal** - modern console

### Hypotheses to Verify

1. cmd.exe and PowerShell render identically in conhost (expected: yes)
2. Windows Terminal renders differently than conhost (expected: yes, likely better)
3. Half blocks or shade characters will show background color better than full block

## Test Results

*To be filled in after Windows testing*

### macOS Terminal (Baseline)
- Character A (█):
- Character B (▓):
- Character C (▒):
- Character D (░):
- Character E (▀):
- Character F (▄):
- Character G (■):
- Character H (▪):

### Windows conhost (cmd.exe)
- Character A (█):
- Character B (▓):
- Character C (▒):
- Character D (░):
- Character E (▀):
- Character F (▄):
- Character G (■):
- Character H (▪):

### Windows conhost (PowerShell)
- Same as cmd.exe? Yes/No
- Any differences:

### Windows Terminal
- Character A (█):
- Character B (▓):
- Character C (▒):
- Character D (░):
- Character E (▀):
- Character F (▄):
- Character G (■):
- Character H (▪):

## Implementation Plan

### Phase 1: Windows Testing
- [ ] Test all characters on Windows conhost (cmd.exe)
- [ ] Test all characters on Windows conhost (PowerShell) - confirm same as cmd.exe
- [ ] Test all characters on Windows Terminal
- [ ] Document results with screenshots
- [ ] Identify best character(s) for each environment

### Phase 2: Implementation (after testing)
- [ ] Add Windows-specific block character selection based on test results
- [ ] Detect Windows Terminal vs legacy conhost if needed
- [ ] Update heatmap code to use configurable character (currently hardcoded)
- [ ] Consider adding command-line option to override character selection

### Phase 3: Documentation
- [ ] Update CLAUDE.md with Windows character handling
- [ ] Add troubleshooting notes for Windows users

## Questions to Answer During Testing

1. Which character shows the best balance of visibility and background color on Windows?
2. Does Windows Terminal render differently than legacy conhost?
3. Is there a single character that works well on both platforms, or do we need platform-specific defaults?
4. Do the shade characters (`░▒▓`) work better than half blocks on Windows?

## Next Steps

1. Pull this branch on a Windows machine
2. Test each character in the environments listed above
3. Document results in the "Test Results" section
4. Determine implementation approach based on findings
