import gladvent/internal/cmd/update
import gladvent/internal/input
import gleam/string
import gleeunit/should
import simplifile

// This test file focuses on end-to-end verification of the legacy file warning system

//pre my contribution code, but just wanted some tests on it anyway
pub fn legacy_file_detection_e2e_test() {
  // E2E test: Verify that when legacy files exist (and new ones don't),
  // the system detects them and uses the legacy path
  let base_path = "test/temp/legacy_detection_e2e"
  let year = 2024
  let day = 1

  // Setup: Create ONLY legacy files (not zero-padded)
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/1.txt", "legacy input")
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_1.gleam",
      "pub fn pt_1(input: String) { 0 }\npub fn pt_2(input: String) { 0 }",
    )

  // Simulate what handle_file_path() does: check for new file, then old file
  let new_path =
    base_path <> "/" <> input.get_file_path(year, day, input.Puzzle)
  let old_path =
    base_path <> "/" <> input.get_legacy_file_path(year, day, input.Puzzle)

  // Verify new (zero-padded) file doesn't exist
  simplifile.is_file(new_path)
  |> should.equal(Ok(False))

  // Verify old (legacy) file DOES exist
  simplifile.is_file(old_path)
  |> should.equal(Ok(True))

  // In this situation, handle_file_path() would:
  // 1. Print the warning (side effect we can't easily test)
  // 2. Return the old path
  // We verify the legacy file is readable and has the right content
  simplifile.read(old_path)
  |> should.equal(Ok("legacy input"))

  // Cleanup
  let assert Ok(_) = simplifile.delete_all([base_path])
}

//pre my contribution code, but just wanted some tests on it anyway
pub fn modern_file_no_warning_e2e_test() {
  // E2E test: Verify that when only modern (zero-padded) files exist,
  // no legacy path is used
  let base_path = "test/temp/modern_detection_e2e"
  let year = 2024
  let day = 1

  // Setup: Create ONLY modern files (zero-padded)
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/01.txt", "modern input")
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_01.gleam",
      "pub fn pt_1(input: String) { 0 }\npub fn pt_2(input: String) { 0 }",
    )

  // Check paths
  let new_path =
    base_path <> "/" <> input.get_file_path(year, day, input.Puzzle)
  let old_path =
    base_path <> "/" <> input.get_legacy_file_path(year, day, input.Puzzle)

  // Verify new (zero-padded) file exists
  simplifile.is_file(new_path)
  |> should.equal(Ok(True))

  // Verify old (legacy) file doesn't exist
  simplifile.is_file(old_path)
  |> should.equal(Ok(False))

  // In this situation, handle_file_path() would use the new path (no warning)
  simplifile.read(new_path)
  |> should.equal(Ok("modern input"))

  // Cleanup
  let assert Ok(_) = simplifile.delete_all([base_path])
}

//pre my contribution code, but just wanted some tests on it anyway
pub fn both_files_exist_prefers_new_e2e_test() {
  // E2E test: When both legacy and modern files exist, prefer the modern one
  let base_path = "test/temp/both_files_e2e"
  let year = 2024
  let day = 1

  // Setup: Create BOTH legacy and modern files
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/1.txt", "legacy input")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/01.txt", "modern input")

  // Check paths
  let new_path =
    base_path <> "/" <> input.get_file_path(year, day, input.Puzzle)
  let old_path =
    base_path <> "/" <> input.get_legacy_file_path(year, day, input.Puzzle)

  // Both exist
  simplifile.is_file(new_path)
  |> should.equal(Ok(True))
  simplifile.is_file(old_path)
  |> should.equal(Ok(True))

  simplifile.read(new_path)
  |> should.equal(Ok("modern input"))

  // Cleanup
  let assert Ok(_) = simplifile.delete_all([base_path])
}

// E2E test: Full legacy project with multiple days gets completely updated
pub fn full_legacy_project_update_e2e_test() {
  let base_path = "test/temp/full_legacy_update_e2e"

  // Setup: Create a full legacy project structure
  // Days 1-9 (need padding), day 10 (already has two digits), day 25 (edge case)
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")

  // Day 1: input + example + source (all need padding)
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/1.txt", "day 1 input")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/1.example.txt", "day 1 example")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_1.gleam",
      "pub fn pt_1(input: String) { 1 }\npub fn pt_2(input: String) { 1 }",
    )

  // Day 5: input + source (need padding)
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/5.txt", "day 5 input")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_5.gleam",
      "pub fn pt_1(input: String) { 5 }\npub fn pt_2(input: String) { 5 }",
    )

  // Day 9: input + source (need padding, edge of single digit)
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/9.txt", "day 9 input")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_9.gleam",
      "pub fn pt_1(input: String) { 9 }\npub fn pt_2(input: String) { 9 }",
    )

  // Day 10: input + source (already two digits, should NOT be updated)
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/10.txt", "day 10 input")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_10.gleam",
      "pub fn pt_1(input: String) { 10 }\npub fn pt_2(input: String) { 10 }",
    )

  // Day 25: input + source (already two digits, should NOT be updated)
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/25.txt", "day 25 input")
  let assert Ok(_) =
    simplifile.write(
      base_path <> "/src/aoc_2024/day_25.gleam",
      "pub fn pt_1(input: String) { 25 }\npub fn pt_2(input: String) { 25 }",
    )

  // Step 1: Run dry-run to see what would be updated
  let dry_run_result = update.do_update(base_path, True)
  let assert Ok(dry_run_report) = dry_run_result

  // Verify dry-run found all legacy files (7 files: 3 for day 1, 2 for day 5, 2 for day 9)
  dry_run_report
  |> string.contains("7 files will be renamed")
  |> should.be_true()
  // Verify specific files are listed
  dry_run_report
  |> string.contains("src/aoc_2024/day_1.gleam -> src/aoc_2024/day_01.gleam")
  |> should.be_true()
  dry_run_report
  |> string.contains("input/2024/1.txt -> input/2024/01.txt")
  |> should.be_true()
  dry_run_report
  |> string.contains("input/2024/1.example.txt -> input/2024/01.example.txt")
  |> should.be_true()

  // Verify day 10 and 25 are NOT listed (already two digits)
  // Note: Check for full paths to avoid false matches
  dry_run_report
  |> string.contains("input/2024/10")
  |> should.be_false()
  dry_run_report
  |> string.contains("day_10")
  |> should.be_false()
  dry_run_report
  |> string.contains("input/2024/25")
  |> should.be_false()

  // Step 2: Apply the updates
  let apply_result = update.do_update(base_path, False)
  let assert Ok(apply_report) = apply_result

  // Verify all 7 files were renamed successfully
  apply_report
  |> string.contains("Changed: 7")
  |> should.be_true()
  apply_report
  |> string.contains("Skipped: 0")
  |> should.be_true()

  // Step 3: Verify files were actually renamed
  // Day 1 - new files exist
  simplifile.is_file(base_path <> "/input/2024/01.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/input/2024/01.example.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_01.gleam")
  |> should.equal(Ok(True))

  // Day 1 - old files gone
  simplifile.is_file(base_path <> "/input/2024/1.txt")
  |> should.equal(Ok(False))
  simplifile.is_file(base_path <> "/input/2024/1.example.txt")
  |> should.equal(Ok(False))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_1.gleam")
  |> should.equal(Ok(False))

  // Day 5 - new files exist
  simplifile.is_file(base_path <> "/input/2024/05.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_05.gleam")
  |> should.equal(Ok(True))

  // Day 9 - new files exist
  simplifile.is_file(base_path <> "/input/2024/09.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_09.gleam")
  |> should.equal(Ok(True))

  // Day 10 and 25 - unchanged (still at original paths)
  simplifile.is_file(base_path <> "/input/2024/10.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_10.gleam")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/input/2024/25.txt")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/src/aoc_2024/day_25.gleam")
  |> should.equal(Ok(True))

  // Step 4: Verify content is preserved
  simplifile.read(base_path <> "/input/2024/01.txt")
  |> should.equal(Ok("day 1 input"))
  simplifile.read(base_path <> "/input/2024/01.example.txt")
  |> should.equal(Ok("day 1 example"))
  simplifile.read(base_path <> "/src/aoc_2024/day_01.gleam")
  |> should.equal(Ok(
    "pub fn pt_1(input: String) { 1 }\npub fn pt_2(input: String) { 1 }",
  ))
  simplifile.read(base_path <> "/input/2024/05.txt")
  |> should.equal(Ok("day 5 input"))
  simplifile.read(base_path <> "/input/2024/09.txt")
  |> should.equal(Ok("day 9 input"))

  // Cleanup
  let assert Ok(_) = simplifile.delete_all([base_path])
}
