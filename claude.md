# Issue #18: Zero-Pad Filenames for Better Sorting

## Development Philosophy

**Test-Driven Development (TDD) - Red, Green, Refactor (RGR)**

This project follows strict TDD principles for all additions and changes:

1. **RED** - Write a failing test first that describes the desired behavior
2. **GREEN** - Write the minimal code necessary to make the test pass
3. **REFACTOR** - Clean up and improve the code while keeping tests green

Every feature addition, bug fix, or enhancement must follow this cycle. Tests are not optional or afterthoughts—they drive the design and implementation.

**Code Guidance Approach**

Claude Code will act as a **pair partner / interactive rubber duck** in this project:

- **NO unsolicited code snippets** - Code will only be provided when explicitly requested
- Focus on asking clarifying questions to help you think through the problem
- Point out potential issues, edge cases, or considerations
- Suggest where to look in the codebase or what to consider
- Guide you toward solutions rather than providing them directly
- Help you maintain the TDD RGR cycle

This approach ensures you maintain ownership of the code and deeply understand every change.

## Issue Summary
Add zero-padding to day filenames (e.g., `01.txt` instead of `1.txt`) to ensure proper alphabetical sorting in file explorers. Days 1-9 should be padded with a leading zero.

## Current Status
The core implementation is COMPLETE. The branch `issue_18` has the following commits:
- `61e8e7e feat: pad filenames with zero`
- `5efc2f7 refactor: move file extension logic to helper`

## Implementation Details

### What Has Been Done ✓

1. **Core Padding Function** (`src/gladvent/internal/parse.gleam:33-35`)
   - Added `pub fn pad(day: Day) -> String` function
   - Uses `string.pad_start(to: 2, with: "0")` to zero-pad day numbers
   - Example: `pad(1)` returns `"01"`, `pad(15)` returns `"15"`

2. **File Generation** (`src/gladvent/internal/cmd/new.gleam:65`)
   - Updated `gleam_src_path` to use `pad(day)` for source files
   - Creates files like `src/aoc_2024/day_01.gleam` instead of `day_1.gleam`

3. **Input File Paths** (`src/gladvent/internal/input.gleam:11-17`)
   - `get_file_path()` now uses `pad(day)` for new zero-padded paths
   - `get_legacy_file_path()` maintains old non-padded paths for backward compatibility
   - Creates files like `input/2024/01.txt` instead of `1.txt`

4. **Backward Compatibility** (`src/gladvent/internal/cmd/run.gleam:70-77`)
   - `handle_file_path()` function checks for both new and legacy paths
   - If old non-padded file exists and new doesn't, uses the old path
   - Otherwise, uses the new padded path
   - This ensures existing user files continue to work

5. **Tests** (`test/parse_test.gleam:23-29`)
   - Added `pad_test()` to verify padding works correctly
   - Added `padded_day_to_int_test()` to verify padded strings parse back to ints
   - All tests passing (4 tests, 0 failures)

6. **File Extension Refactoring** (`src/gladvent/internal/input.gleam:27-32`)
   - Moved extension logic to `get_extension()` helper function
   - Cleaner separation of concerns

### What Remains to Be Done

#### 1. Legacy File Warning System (REQUIRED)

**Purpose:** Alert users when their project uses old non-padded filenames and direct them to upgrade.

**Location:** `src/gladvent/internal/cmd/run.gleam:70-77` - modify `handle_file_path()`

**Behavior:**
- When `handle_file_path()` detects it's using a legacy (non-padded) file, emit a warning
- Warning should appear every time the legacy file is used (constant reminder until upgrade)
- Warning message must mention the `gleam run update` command to upgrade files
- Warning should be visible but not block execution

**Design Considerations:**
- Should warning go to stdout or stderr?
- Should it use ANSI colors for visibility?
- What's the exact wording that will be helpful but not annoying?

#### 2. Update Command Implementation (IN PROGRESS)

**Command:** `gleam run update`

**Purpose:** Upgrade projects from old non-padded file structure to new zero-padded structure.

**TDD Progress:**
- ✅ RED: First test written in `test/update_test.gleam`
  - Test: `update_path("input/2024/1.txt")` should return `Some("input/2024/01.txt")`
  - Test currently failing (module doesn't exist yet)
- ⏳ GREEN: Need to implement `update_path()` function
- ⏳ REFACTOR: Pending

**Design Decisions:**
- **Function name:** `update_path` (not `upgrade_path`) - chosen for consistency with command name
- **Return type:** `Option(String)` - Makes deprecation easier:
  - `Some(new_path)` = legacy path that needs upgrading
  - `None` = already modern, no action needed
  - This explicit signal makes it easy to identify and remove legacy-handling code in future releases
- **Implementation location:** `src/gladvent/internal/cmd/update.gleam` (new file, will be deprecated in 2 releases)
- **Test strategy:** Unit tests first, then integration
  - Start with pure business logic (path transformation) before testing glint integration
  - Follows existing pattern in codebase (`test/parse_test.gleam` contains only unit tests)
  - Easier to test, faster feedback loop, more focused tests
- **File operation safety:** Copy files, don't move them
  - Non-destructive approach reduces risk of data loss
  - Users can verify new files work before manually deleting originals
  - Better user experience for a migration tool
- **Conflict resolution:** Skip files where both old and new versions exist
  - Don't error (too disruptive)
  - Don't overwrite (could lose data)
  - Skip and report to user (safest option)
  - Allows users to resolve conflicts manually

**Scope:** Upgrades BOTH:
- Input files: `input/<year>/1.txt` → `input/<year>/01.txt`
- Source files: `src/aoc_<year>/day_1.gleam` → `src/aoc_<year>/day_01.gleam`

**Year Handling Options (TBD - must choose one):**
1. **Auto-detect all years**
   - Scan `input/` and `src/` directories for all year folders
   - Upgrade all detected years in a single command
   - Pros: One command fixes everything
   - Cons: May modify more than user expects

2. **Current year only**
   - Use the current calendar year (same as default for `new` and `run`)
   - Respects existing `--year` flag behavior
   - Pros: Predictable, matches existing command patterns
   - Cons: Users with multiple years need to run multiple times

3. **Year flag with default**
   - Accept `--year` flag (consistent with other commands)
   - Default to current year if not specified
   - Could support `--year=all` for all years
   - Pros: Flexible, user has control
   - Cons: Slightly more complex implementation

**Safety:** Non-destructive (copy, don't move)
- Creates new zero-padded files
- Keeps original non-padded files as backup
- Users can manually delete old files once they verify everything works
- Reduces risk of data loss

**Conflict Handling:** Skip existing files
- If both `1.txt` and `01.txt` exist, skip that file
- Don't overwrite existing zero-padded files
- Should report skipped files to user
- Prevents accidental data loss

**File Types to Upgrade:**
- Input files: `*.txt` and `*.example.txt`
- Source files: `day_[1-9].gleam` only (days 1-9 need padding)

**Output/Reporting:**
- Show what was upgraded (success messages)
- Show what was skipped (conflict messages)
- Show summary: X files upgraded, Y files skipped

**Implementation Location:**
- New file: `src/gladvent/internal/cmd/update.gleam` (following existing pattern)
- Register command in main glint command tree

**Required Helper Functions:**
- Detect legacy input files for a given year
- Detect legacy source files for a given year
- Copy file from old path to new path
- Generate upgrade report/summary

#### 3. Documentation Updates (REQUIRED)

**README.md Updates:**
- Line 42: Update `day_X.gleam` to reflect zero-padding for days 1-9
- Line 45: Update `X.txt` to reflect zero-padding for days 1-9
- Line 46: Update `day_X.gleam` to reflect zero-padding for days 1-9
- Add section documenting the `update` command
- Add note about backward compatibility with legacy filenames
- Add upgrade guide for existing users

**gleam.toml or other docs:**
- Consider if any other documentation needs updating

## Files Modified
- `src/gladvent/internal/parse.gleam` - Added `pad()` function
- `src/gladvent/internal/cmd/new.gleam` - Use `pad()` in file generation
- `src/gladvent/internal/input.gleam` - Added `get_legacy_file_path()`, use `pad()` in new paths
- `src/gladvent/internal/cmd/run.gleam` - Added `handle_file_path()` for backward compatibility
- `test/parse_test.gleam` - Added padding tests

## PR Checklist

### Pre-PR
- [x] Core functionality implemented
- [x] Tests written and passing
- [x] Backward compatibility maintained
- [ ] README documentation updated
- [ ] Additional test coverage (optional)

### PR Creation
- [ ] Update README.md to reflect new zero-padded format
- [ ] Run `gleam test` to ensure all tests pass
- [ ] Run `gleam format` to ensure code is formatted
- [ ] Create PR with descriptive title and body
- [ ] Reference issue #18 in PR description

### PR Description Template
```markdown
## Summary
Implements zero-padding for day filenames to ensure proper alphabetical sorting.

## Changes
- Added `pad()` function to zero-pad day numbers (1-9 become 01-09)
- Updated file generation to use padded filenames
- Maintained backward compatibility with legacy non-padded filenames
- Updated README documentation to reflect new format
- Added tests for padding functionality

## Examples
- Source files: `src/aoc_2024/day_01.gleam` (was `day_1.gleam`)
- Input files: `input/2024/01.txt` (was `1.txt`)

## Backward Compatibility
Existing users with non-padded filenames will continue to work. The runner checks for legacy paths and uses them if found.

Fixes #18
```

## Lessons Learned / Session Notes

### Session 1: Initial Planning and TDD Setup

**Decisions Made:**
1. **TDD Approach:** Strict Red-Green-Refactor for all new code
2. **Deprecation Strategy:** All update/upgrade code isolated in dedicated files (`test/update_test.gleam`, `src/gladvent/internal/cmd/update.gleam`) for easy removal in 2 releases
3. **Test-First Development:** Started with unit tests before implementation
4. **Function Design:** Chose `Option(String)` return type to make legacy detection explicit and deprecation easier

**What Went Well:**
- Clear separation of concerns: update logic is isolated
- TDD discipline: wrote failing test before any implementation
- Good discussion about signature design (String -> String vs String -> Option(String))

**Challenges:**
- Almost slipped into providing unsolicited code (caught and corrected)
- Need to maintain discipline on pair programming approach

**Next Actions:**
1. Implement `update_path()` to make test green
2. Add more test cases (days 10+, example files, source files)
3. Continue TDD cycle for remaining functionality

## Next Steps
1. Complete `update_path()` implementation (GREEN phase)
2. Add additional test cases and refactor
3. Build out file detection and copying logic
4. Implement warning system
5. Update README.md documentation (lines 42, 45, 46)
6. Run tests: `gleam test`
7. Format code: `gleam format`
8. Build: `gleam build`
9. Create PR against main branch
10. Link to issue #18 in PR description
