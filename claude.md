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
- Should it use ANSI colors for visibility? NO, not likely.

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
- **File operation strategy:** Rename files
  - Clean migration - no duplicate files left behind
  - Users don't need to manually clean up old files
  - Simpler mental model - "this is the new way"
  - Safe by default with dry-run mode
- **Safety mechanism:** Dry-run by default
  - `gleam run update` - Shows report of what would be renamed (dry-run, safe)
  - `gleam run update --apply` - Actually performs the rename operation
  - Users can and should preview changes before committing
  - Reduces risk of accidental file operations
- **Conflict resolution:** Skip files where both old and new versions exist
  - Don't error (too disruptive)
  - Skip and report to user (safest option, still unclear what could constitute a 'conflict')
  - Allows users to resolve conflicts manually

**Scope:** Upgrades BOTH:
- Input files: `input/<year>/1.txt` -> `input/<year>/01.txt`
- Example Input files: `input/<year>/1.example.txt` -> `input/<year>/01.example.txt`
- Source files: `src/aoc_<year>/day_1.gleam` -> `src/aoc_<year>/day_01.gleam`

**Year Handling Options**
1. **Auto-detect all years**
   - Scan `input/` and `src/` directories for all year folders
   - Upgrade all detected years in a single command
   - Pros: One command fixes everything
   - Cons: May modify more than user expects

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
- **Filtering strategy:** Filter end of path for `.txt`, `.example.txt`, `.gleam` while scanning
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
- ✅ Implement `should_include_file()` helper with tests (7 tests passing)
- ⏳ Implement `scan_input_files()` - Scan input/<year>/ directories
- ⏳ Implement `scan_src_files()` - Scan src/aoc_<year>/ directories
- ⏳ Implement `scan_project_files()` - Main function combining both
- ⏳ Integration test: Full workflow with temp directory structure

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
- `src/gladvent/internal/cmd/update.gleam` - NEW FILE - Migration command logic
- `test/parse_test.gleam` - Added padding tests
- `test/update_test.gleam` - NEW FILE - Update command tests (20 tests, all passing)

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

## Backward Compatibility
Existing users with non-padded filenames will continue to work (for at least 2 more releases). The runner checks for legacy paths and uses them if found.

Fixes #18
```

## Lessons Learned / Session Notes

### Session 1: Initial Planning and TDD Setup

**Decisions Made:**
1. **TDD Approach:** Strict Red-Green-Refactor for all new code
2. **Deprecation Strategy:** All update code isolated in dedicated files (`test/update_test.gleam`, `src/gladvent/internal/cmd/update.gleam`) for easy removal in 2 releases
3. **Test-First Development:** Started with unit tests before implementation

**What Went Well:**
- Clear separation of concerns: update logic is isolated
- TDD discipline: wrote failing test before any implementation
- Good discussion about signature design (String -> String vs String -> Option(String))

**Challenges:**
- Almost slipped into providing unsolicited code (caught and corrected)
- Need to maintain discipline on pair programming approach

**Next Actions:**
1. ✅ Implement `update_path()` to make test green
2. ✅ Add more test cases (days 10+, example files, source files)
3. ✅ Continue TDD cycle for remaining functionality

### Session 2: Building the Update Command

**What We Accomplished:**
1. ✅ Completed `update_path()` - Pure path transformation logic
   - Implemented with pattern matching for input/src paths
   - Comprehensive test coverage (37 test cases including edge cases)
   - Refactored with helper functions and `use` syntax for clean code
2. ✅ Built `find_legacy_files()` - Filter legacy from all paths
   - Used `fold` pattern to collect legacy files
   - Returns `List(#(old_path, new_path))` tuples
   - Tested with mixed legacy/modern paths
3. ✅ Created `format_dry_run_report()` - Formatted output for users
   - Handles empty list (no files to update)
   - Shows file count and instructions for --apply flag
   - Tested both cases
4. ✅ Implemented `should_include_file()` - File filtering helper
   - Checks file extensions (.txt, .example.txt, .gleam)
   - Filters hidden files (starting with .)
   - 7 tests covering all edge cases
5. ✅ Design decisions for directory scanning
   - Error if src/ missing, Ok([]) if input/ missing
   - One level recursion only
   - Filter while scanning
   - Skip hidden files/directories

**Key Design Decisions:**
- **Rename vs Copy:** Chose rename (clean migration, safe with dry-run)
- **Dry-run by default:** `gleam run update` previews, `--apply` executes
- **Separate concerns:** update_path (transform) → find_legacy_files (filter) → format (present)

**Refactoring Wins:**
- Extracted helper functions for cleaner main logic
- Used `use` syntax to flatten nested case statements
- Filter+map patterns for list operations
- Pure functions make testing easy

**Current State:**
- 20 tests, all passing ✅
- Core logic complete for path transformation and reporting
- Ready to implement filesystem scanning

### Session 3: File Scanning and Pattern Matching Refactor

**What We Accomplished:**
1. ✅ Implemented `scan_input_files()` - Recursively scans directories
   - Uses `simplifile.get_files()` for recursive scanning
   - Strips base path by taking last 3 segments (input/<year>/<file>)
   - Filters files using `should_include_path()`
   - Returns `Result(List(String), FileError)`
   - Returns `Ok([])` if input/ directory doesn't exist
2. ✅ Created `should_include_path()` - Path wrapper for file validation
   - Extracts filename from full path using `list.last()`
   - Delegates to `should_include_file()` for validation
   - Handles empty/malformed paths gracefully
3. ✅ **MAJOR REFACTOR:** Rewrote `should_include_file()` with pattern matching
   - **Problem identified:** Extension-based filtering was too fragile
     - `[".txt", "example.txt"]` matched unwanted files like `my_example.txt`
     - Too permissive - couldn't distinguish valid AoC files from arbitrary txt files
   - **Solution:** Pattern matching against known AoC file structures
     - Input files: `<day>.txt` where day is 1-25
     - Example files: `<day>.example.txt` where day is 1-25
     - Source files: `day_<day>.gleam` where day is 1-25
   - **Implementation:**
     - Split on `.` and pattern match against known structures
     - Validate day numbers with `is_valid_day()` helper (1-25 range)
     - Reject hidden files (starting with `.`)
     - Nested case for gleam files: split `day_X` prefix on `_`
   - **No regex needed** - pure string operations and pattern matching
4. ✅ Comprehensive test coverage - 26 tests for file validation
   - 16 tests for `should_include_file()`
   - 10 tests for `should_include_path()`
   - Edge cases: hidden files, invalid days (0, 26), fake examples, wrong extensions

**Key Design Decisions:**
- **Path clipping strategy:** Take last 3 segments instead of stripping base path
  - Robust - doesn't depend on where user's project is located
  - Works with absolute paths from any directory depth
  - Leverages known structure: `input/<year>/<file>`
- **Pattern matching over extension lists:** More explicit validation
  - Eliminates false positives (e.g., `my_example.txt`)
  - Self-documenting - the patterns show exactly what's valid
  - Easy to extend for new file types
- **Boolean chain with block:** `!hidden && { case ... }` is idiomatic and readable
  - Short-circuits on hidden files (efficient)
  - Block makes transformation step clear
  - One level of nesting is acceptable and localized

**Challenges Overcome:**
- **Fragile extension matching:** Discovered `".txt"` was too broad, matching all txt files
- **Test fixture pollution:** Added `my_example.txt` to catch false positives
- **Over-engineering temptation:** Considered const lists and complex helpers, settled on simple pattern matching

**Refactoring Philosophy:**
- Considered extracting more helper functions to reduce nesting
- Decided current implementation is clean and readable as-is
- One nested case (for gleam files) is acceptable - it's localized and clear
- Don't refactor for refactoring's sake - code is already maintainable

**Current State:**
- 46 tests, all passing ✅
- Robust file validation with pattern matching
- `scan_input_files()` functional and tested
- Ready to implement `scan_src_files()` and full integration

**What's Next:**
1. Implement `scan_src_files()` - Scan src/aoc_<year>/ directories
2. Implement `scan_project_files()` - Combine both scans
3. Integration test with temp directory structure
4. File rename operations with conflict detection
5. Warning system in handle_file_path()
6. Glint CLI integration
7. Documentation updates

## Next Steps
1. ⏳ Complete directory scanning (scan_input_files, scan_src_files, scan_project_files)
2. ⏳ Integration test with temp filesystem
3. ⏳ Implement file rename operations
4. ⏳ Add warning system to run.gleam
5. ⏳ Glint CLI integration for update command
6. ⏳ Update README.md documentation (lines 42, 45, 46, new section for update command)
7. Run tests: `gleam test` ✅ (20 passing)
8. Format code: `gleam format`
9. Build: `gleam build`
