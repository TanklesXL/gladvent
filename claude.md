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
- ✅ RED: Tests written in `test/update_test.gleam`
- ✅ GREEN: `update_path()` function implemented and passing
- ✅ REFACTOR: Extracted helper functions, flattened with `use` syntax
- ✅ Comprehensive test coverage with 37 test cases including edge cases

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
- **File operation strategy:** Rename files (move, not copy)
  - Clean migration - no duplicate files left behind
  - Users don't need to manually clean up old files
  - Simpler mental model - "this is the new way"
  - Safe by default with dry-run mode
- **Safety mechanism:** Dry-run by default
  - `gleam run update` - Shows what would be renamed (dry-run, safe)
  - `gleam run update --apply` - Actually performs the rename operation
  - Users can preview changes before committing
  - Reduces risk of accidental file operations
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

**Safety:** Dry-run by default with explicit apply flag
- Default: `gleam run update` shows what would be renamed (no changes)
- Apply: `gleam run update --apply` performs actual rename operations
- Users preview changes before applying
- Clear separation between preview and action

**Conflict Handling:** Skip existing files
- If both `1.txt` and `01.txt` exist, skip that file
- Don't overwrite existing zero-padded files
- Should report skipped files to user
- Prevents accidental data loss

**File Types to Upgrade:**
- Input files: `*.txt` and `*.example.txt`
- Source files: `day_[1-9].gleam` only (days 1-9 need padding)

**Output/Reporting:**
- **Dry-run mode (default):**
  - List files that will be renamed with old → new path
  - Show conflicts (files that would be skipped)
  - Summary: X files to rename, Y conflicts
  - Instruction: "Run with --apply to perform the rename operation"
- **Apply mode (--apply flag):**
  - Show what was renamed (success messages)
  - Show what was skipped (conflict messages)
  - Summary: X files renamed, Y files skipped

**Implementation Location:**
- New file: `src/gladvent/internal/cmd/update.gleam` (following existing pattern)
- Register command in main glint command tree

**Required Helper Functions:**
- ✅ `update_path(path: String) -> Option(String)` - Transform path if legacy
- ✅ `find_legacy_files(paths: List(String)) -> List(#(String, String))` - Filter to legacy only
- ✅ `format_dry_run_report(legacy_files: List(#(String, String))) -> String` - Format dry-run output
- ⏳ `scan_project_files()` - Scan directories to find all relevant files
- ⏳ Detect file conflicts (both old and new exist)
- ⏳ Rename file from old path to new path
- ⏳ Generate apply report/summary

**Directory Scanning Implementation Plan:**

*Design Decisions:*
- **Error handling:** Return Error if `src/` missing (required), return `Ok([])` if `input/` missing (optional)
- **Recursion depth:** One level only - scan `input/<year>/*.txt` and `src/aoc_<year>/*.gleam`
- **Filtering strategy:** Filter for `.txt`, `.example.txt`, `.gleam` while scanning
- **Hidden files:** Skip anything starting with `.` (like `.git`, `.DS_Store`)

*Pseudocode:*
```gleam
// Main entry point
pub fn scan_project_files() -> Result(List(String), simplifile.FileError) {
  // 1. Scan input files (returns Ok([]) if input/ doesn't exist)
  // 2. Scan src files (returns Error if src/ doesn't exist)
  // 3. Combine both lists
  // 4. Return combined list
}

// Scan input directory
fn scan_input_files() -> Result(List(String), Nil) {
  // 1. Check if input/ exists, if not return Ok([])
  // 2. Read directory to get year folders
  // 3. Filter out hidden directories (starting with .)
  // 4. For each year folder:
  //    a. Read files in input/<year>/
  //    b. Filter to only .txt and .example.txt files
  //    c. Filter out hidden files
  //    d. Prepend "input/<year>/" to each filename
  // 5. Flatten all year lists into one list
  // 6. Return Ok(list)
}

// Scan src directory
fn scan_src_files() -> Result(List(String), simplifile.FileError) {
  // 1. Read src/ directory (error if doesn't exist)
  // 2. Filter to only directories starting with "aoc_"
  // 3. Filter out hidden directories
  // 4. For each aoc_<year> folder:
  //    a. Read files in src/aoc_<year>/
  //    b. Filter to only .gleam files
  //    c. Filter out hidden files
  //    d. Prepend "src/aoc_<year>/" to each filename
  // 5. Flatten all lists into one list
  // 6. Return Ok(list)
}

// Helper: Check if file should be included
fn should_include_file(filename: String, extensions: List(String)) -> Bool {
  // 1. Check if starts with "." (hidden) - exclude
  // 2. Check if ends with any of the allowed extensions
  // 3. Return true if matches extension and not hidden
}
```

*TODO Checklist:*
- ✅ Design decisions finalized
- ⏳ Write test for `scan_project_files()` with fixture directory structure
- ⏳ Implement `should_include_file()` helper with tests
- ⏳ Implement `scan_input_files()` with tests
- ⏳ Implement `scan_src_files()` with tests
- ⏳ Implement `scan_project_files()` main function
- ⏳ Integration test: Full workflow (scan → find_legacy_files → format_dry_run_report)

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
