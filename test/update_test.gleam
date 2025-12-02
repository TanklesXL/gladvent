import gladvent/internal/cmd/update.{Failure, Success}
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import simplifile

pub fn update_path_input_file_day_1_test() {
  update.update_path("input/2024/1.txt")
  |> should.equal(Some("input/2024/01.txt"))
}

pub fn update_path_input_file_day_1_example_test() {
  update.update_path("input/2024/1.example.txt")
  |> should.equal(Some("input/2024/01.example.txt"))
}

pub fn update_path_input_file_day_already_padded_test() {
  update.update_path("input/2024/01.txt")
  |> should.equal(None)
}

pub fn update_path_input_file_day_already_padded_example_test() {
  update.update_path("input/2024/01.example.txt")
  |> should.equal(None)
}

pub fn update_path_src_file_day_1_test() {
  update.update_path("src/aoc_2024/day_1.gleam")
  |> should.equal(Some("src/aoc_2024/day_01.gleam"))
}

pub fn update_path_src_file_day_already_padded_test() {
  update.update_path("src/aoc_2024/day_01.gleam")
  |> should.equal(None)
}

pub fn update_path_comprehensive_test_with_edge_cases() {
  let test_cases = [
    // Input files - need update
    #("input/2024/1.txt", Some("input/2024/01.txt")),
    #("input/2024/2.txt", Some("input/2024/02.txt")),
    #("input/2024/9.txt", Some("input/2024/09.txt")),
    #("input/2023/5.example.txt", Some("input/2023/05.example.txt")),
    #("input/2024/1.example.txt", Some("input/2024/01.example.txt")),
    // Input files - already padded (no update)
    #("input/2024/01.txt", None),
    #("input/2024/09.txt", None),
    #("input/2024/10.txt", None),
    #("input/2024/25.txt", None),
    #("input/2024/01.example.txt", None),
    #("input/2024/15.example.txt", None),
    // Src files - need update
    #("src/aoc_2024/day_1.gleam", Some("src/aoc_2024/day_01.gleam")),
    #("src/aoc_2024/day_5.gleam", Some("src/aoc_2024/day_05.gleam")),
    #("src/aoc_2023/day_9.gleam", Some("src/aoc_2023/day_09.gleam")),
    // Src files - already padded (no update)
    #("src/aoc_2024/day_01.gleam", None),
    #("src/aoc_2024/day_09.gleam", None),
    #("src/aoc_2024/day_10.gleam", None),
    #("src/aoc_2024/day_25.gleam", None),
    // Edge cases - invalid/unrecognized paths (no update)
    #("input/2024/", None),
    #("src/aoc_2024/", None),
    #("random/path/file.txt", None),
    #("input/2024", None),
    #("src/aoc_2024/day_.gleam", None),
    #("input/2024/.txt", None),
    #("", None),
  ]

  list.each(test_cases, fn(test_case) {
    let #(input, expected) = test_case
    update.update_path(input)
    |> should.equal(expected)
  })
}

pub fn find_legacy_files_test() {
  let paths = [
    "input/2024/1.txt",
    "input/2024/10.txt",
    "input/2024/5.example.txt",
    "src/aoc_2024/day_3.gleam",
    "src/aoc_2024/day_15.gleam",
    "src/aoc_2023/day_9.gleam",
    "input/2024/01.txt",
    "random/path.txt",
  ]

  let expected = [
    #("input/2024/1.txt", "input/2024/01.txt"),
    #("input/2024/5.example.txt", "input/2024/05.example.txt"),
    #("src/aoc_2024/day_3.gleam", "src/aoc_2024/day_03.gleam"),
    #("src/aoc_2023/day_9.gleam", "src/aoc_2023/day_09.gleam"),
  ]

  update.find_legacy_files(paths)
  |> should.equal(expected)
}

pub fn format_dry_run_report_with_files_test() {
  let legacy_files = [
    #("input/2024/1.txt", "input/2024/01.txt"),
    #("input/2024/5.example.txt", "input/2024/05.example.txt"),
    #("src/aoc_2024/day_3.gleam", "src/aoc_2024/day_03.gleam"),
  ]

  let expected =
    "Files to be renamed:
  input/2024/1.txt -> input/2024/01.txt
  input/2024/5.example.txt -> input/2024/05.example.txt
  src/aoc_2024/day_3.gleam -> src/aoc_2024/day_03.gleam

3 files will be renamed
Run 'gleam run update apply' to perform the rename operation"

  update.format_dry_run_report(legacy_files)
  |> should.equal(expected)
}

pub fn format_dry_run_report_empty_test() {
  let legacy_files = []

  let expected =
    "No files need updating - all files are already using zero-padded names."

  update.format_dry_run_report(legacy_files)
  |> should.equal(expected)
}

// should_include_file tests - rewriting with pattern matching approach
pub fn should_include_file_valid_txt_test() {
  update.should_include_file("1.txt")
  |> should.be_true
}

pub fn should_include_file_valid_padded_txt_test() {
  update.should_include_file("01.txt")
  |> should.be_true
}

pub fn should_include_file_valid_example_txt_test() {
  update.should_include_file("5.example.txt")
  |> should.be_true
}

pub fn should_include_file_valid_day_25_test() {
  update.should_include_file("25.txt")
  |> should.be_true
}

pub fn should_include_file_invalid_day_26_test() {
  update.should_include_file("26.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_day_0_test() {
  update.should_include_file("0.txt")
  |> should.be_false
}

pub fn should_include_file_hidden_file_test() {
  update.should_include_file(".gitignore")
  |> should.be_false
}

pub fn should_include_file_hidden_txt_test() {
  update.should_include_file(".hidden.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_my_example_txt_test() {
  update.should_include_file("my_example.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_readme_md_test() {
  update.should_include_file("readme.md")
  |> should.be_false
}

pub fn should_include_file_invalid_no_extension_test() {
  update.should_include_file("LICENSE")
  |> should.be_false
}

pub fn should_include_file_day_gleam_test() {
  update.should_include_file("day_3.gleam")
  |> should.be_true
}

pub fn should_include_file_day_padded_gleam_test() {
  update.should_include_file("day_03.gleam")
  |> should.be_true
}

pub fn should_include_file_invalid_gleam_test() {
  update.should_include_file("helper.gleam")
  |> should.be_false
}

// should_include_path tests - rewriting with pattern matching approach
pub fn should_include_path_with_input_txt_test() {
  update.should_include_path("input/2024/1.txt")
  |> should.be_true
}

pub fn should_include_path_with_example_txt_test() {
  update.should_include_path("input/2024/5.example.txt")
  |> should.be_true
}

pub fn should_include_path_with_src_gleam_test() {
  update.should_include_path("src/aoc_2024/day_3.gleam")
  |> should.be_true
}

pub fn should_include_path_with_deep_nesting_test() {
  update.should_include_path("test/fixtures/with_input/input/2024/1.txt")
  |> should.be_true
}

pub fn should_include_path_rejects_hidden_file_test() {
  update.should_include_path("input/2024/.gitignore")
  |> should.be_false
}

pub fn should_include_path_rejects_hidden_txt_test() {
  update.should_include_path("input/2024/.hidden.txt")
  |> should.be_false
}

pub fn should_include_path_rejects_fake_example_test() {
  update.should_include_path("input/2024/my_example.txt")
  |> should.be_false
}

pub fn should_include_path_rejects_wrong_extension_test() {
  update.should_include_path("input/2024/readme.md")
  |> should.be_false
}

pub fn should_include_path_rejects_invalid_day_test() {
  update.should_include_path("input/2024/26.txt")
  |> should.be_false
}

pub fn should_include_path_empty_path_test() {
  update.should_include_path("")
  |> should.be_false
}

// scan_files tests - works with both input/ and src/ directories
pub fn scan_files_returns_empty_list_when_dir_missing_test() {
  // When directory doesn't exist, should return Ok([])
  update.scan_files("test/fixtures/no_input")
  |> should.equal(Ok([]))
}

pub fn scan_files_finds_txt_files_test() {
  // Should find .txt files in input/<year>/ directories
  // Test structure: test/fixtures/with_input/input/2024/{1.txt, 10.txt}
  update.scan_files("test/fixtures/with_input")
  |> should.equal(Ok(["input/2024/1.txt", "input/2024/10.txt"]))
}

pub fn scan_files_ignores_non_aoc_files_test() {
  // Should only include valid AoC files, ignore other file types
  // Test structure: test/fixtures/with_other_files/input/2024/{1.txt, readme.md}
  update.scan_files("test/fixtures/with_other_files")
  |> should.equal(Ok(["input/2024/1.txt"]))
}

pub fn scan_files_finds_example_txt_files_test() {
  // Should find .example.txt files (with the dot prefix)
  // Should reject files like "my_example.txt" (without dot prefix)
  // Test structure: test/fixtures/with_examples/input/2024/{1.example.txt, 5.txt, my_example.txt}
  update.scan_files("test/fixtures/with_examples")
  |> should.equal(Ok(["input/2024/1.example.txt", "input/2024/5.txt"]))
}

pub fn scan_files_finds_gleam_files_test() {
  // Should find .gleam files in src/aoc_<year>/ directories
  // Test structure: test/fixtures/with_src/src/aoc_2024/{day_1.gleam, day_10.gleam}
  let result = update.scan_files("test/fixtures/with_src")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(2)
      list.contains(files, "src/aoc_2024/day_1.gleam") |> should.be_true
      list.contains(files, "src/aoc_2024/day_10.gleam") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_ignores_non_day_gleam_files_test() {
  // Should ignore helper.gleam, only find day_X.gleam files
  // Test structure: test/fixtures/with_src_mixed/src/aoc_2024/{day_3.gleam, helper.gleam}
  let result = update.scan_files("test/fixtures/with_src_mixed")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(1)
      list.contains(files, "src/aoc_2024/day_3.gleam") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_handles_multi_year_test() {
  // Should find files across multiple years
  // Test structure: test/fixtures/multi_year/input/{2023/1.txt, 2024/2.txt}
  let result = update.scan_files("test/fixtures/multi_year")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(2)
      list.contains(files, "input/2023/1.txt") |> should.be_true
      list.contains(files, "input/2024/2.txt") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_handles_both_input_and_src_test() {
  // Should find files from both input/ and src/ in same scan
  // Test structure: test/fixtures/full_project/{input/2024/1.txt, src/aoc_2024/day_2.gleam}
  let result = update.scan_files("test/fixtures/full_project")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(2)
      list.contains(files, "input/2024/1.txt") |> should.be_true
      list.contains(files, "src/aoc_2024/day_2.gleam") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_ignores_hidden_directories_test() {
  // Should skip hidden directories like .git
  // Test structure: test/fixtures/with_hidden_dirs/{input/2024/1.txt, .git/something.txt}
  let result = update.scan_files("test/fixtures/with_hidden_dirs")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(1)
      list.contains(files, "input/2024/1.txt") |> should.be_true
      // Should NOT contain anything from .git/
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_handles_deep_nesting_test() {
  // Should work even with extra directory depth (like our test fixtures)
  // The last 3 segments should still be correct
  // Test structure: test/fixtures/deep/nested/path/input/2024/5.txt
  let result = update.scan_files("test/fixtures/deep/nested/path")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(1)
      list.contains(files, "input/2024/5.txt") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_ignores_invalid_day_numbers_test() {
  // Should reject day 0 and day 26+
  // Test structure: test/fixtures/invalid_days/input/2024/{0.txt, 1.txt, 26.txt}
  let result = update.scan_files("test/fixtures/invalid_days")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(1)
      list.contains(files, "input/2024/1.txt") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_files_handles_padded_and_unpadded_mix_test() {
  // Should handle both padded and unpadded filenames
  // Test structure: test/fixtures/mixed_padding/input/2024/{1.txt, 02.txt, 15.txt}
  let result = update.scan_files("test/fixtures/mixed_padding")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(3)
      list.contains(files, "input/2024/1.txt") |> should.be_true
      list.contains(files, "input/2024/02.txt") |> should.be_true
      list.contains(files, "input/2024/15.txt") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

// scan_project_files tests
pub fn scan_project_files_combines_input_and_src_test() {
  // Should scan both input/ and src/ directories and combine results
  // Test structure: test/fixtures/full_project/{input/2024/1.txt, src/aoc_2024/day_2.gleam}
  let result = update.scan_project_files("test/fixtures/full_project")
  case result {
    Ok(files) -> {
      list.length(files) |> should.equal(2)
      list.contains(files, "input/2024/1.txt") |> should.be_true
      list.contains(files, "src/aoc_2024/day_2.gleam") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn scan_project_files_errors_when_src_missing_test() {
  // Should propagate FileError if src/ directory doesn't exist (invalid project)
  // Test structure: test/fixtures/with_input/{input/2024/1.txt} (no src/)
  update.scan_project_files("test/fixtures/with_input")
  |> should.be_error()
}

pub fn scan_files_returns_ok_for_missing_input_test() {
  // Should return Ok([]) when input/ doesn't exist (optional directory)
  update.scan_files("test/fixtures/with_src/input/")
  |> should.equal(Ok([]))
}

pub fn scan_files_errors_for_missing_src_test() {
  // Should error when src/ doesn't exist (required directory)
  update.scan_files("test/fixtures/with_input/src/")
  |> should.be_error()
}

pub fn scan_files_does_not_error_for_src_in_middle_of_path_test() {
  // Should NOT error for paths with "src" in middle (like "my_src_project/input/")
  // This tests that we check ends_with, not contains
  // Test structure: test/fixtures/my_src_project/input/2024/1.txt
  let result = update.scan_files("test/fixtures/my_src_project/input/")
  case result {
    Ok(files) -> {
      // Should succeed and find the file (not error just because "src" is in parent path)
      list.length(files) |> should.equal(1)
      list.contains(files, "input/2024/1.txt") |> should.be_true
    }
    Error(_) -> should.fail()
    // Should NOT error
  }
}

// rename_file tests
pub fn rename_file_renames_successfully_test() {
  // Should rename a file from old path to new path
  let temp_dir = "test/temp/rename_success"
  let old_path = temp_dir <> "/1.txt"
  let new_path = temp_dir <> "/01.txt"

  // Setup: Create temp directory and file
  let assert Ok(_) = simplifile.create_directory_all(temp_dir)
  let assert Ok(_) = simplifile.write(old_path, "test content")

  // Act: Rename the file
  let result = update.rename_file(old_path, new_path)

  // Assert: Rename succeeded
  result |> should.be_ok()

  // Assert: Old file doesn't exist, new file exists
  simplifile.is_file(old_path) |> should.be_ok() |> should.be_false()
  simplifile.is_file(new_path) |> should.be_ok() |> should.be_true()

  // Cleanup
  let assert Ok(_) = simplifile.delete(new_path)
  let assert Ok(_) = simplifile.delete(temp_dir)
}

pub fn rename_file_skips_when_target_exists_test() {
  // Should NOT rename if target file already exists (conflict)
  let temp_dir = "test/temp/rename_conflict"
  let old_path = temp_dir <> "/1.txt"
  let new_path = temp_dir <> "/01.txt"

  // Setup: Create temp directory and BOTH files
  let assert Ok(_) = simplifile.create_directory_all(temp_dir)
  let assert Ok(_) = simplifile.write(old_path, "old content")
  let assert Ok(_) = simplifile.write(new_path, "new content")

  // Act: Try to rename (should skip/error due to conflict)
  let result = update.rename_file(old_path, new_path)

  // Assert: Should return error (or we could return Ok but skip)
  result |> should.be_error()

  // Assert: Both files still exist, old file unchanged
  simplifile.is_file(old_path) |> should.be_ok() |> should.be_true()
  simplifile.is_file(new_path) |> should.be_ok() |> should.be_true()

  // Assert: New file content unchanged (wasn't overwritten)
  simplifile.read(new_path) |> should.equal(Ok("new content"))

  // Cleanup
  let assert Ok(_) = simplifile.delete(old_path)
  let assert Ok(_) = simplifile.delete(new_path)
  let assert Ok(_) = simplifile.delete(temp_dir)
}

// apply_renames tests
pub fn apply_renames_single_file_success_test() {
  // Should rename a single file and return Success result
  let temp_dir = "test/temp/apply_renames_single"
  let old_path = temp_dir <> "/1.txt"
  let new_path = temp_dir <> "/01.txt"

  // Setup: Create temp directory and file
  let assert Ok(_) = simplifile.create_directory_all(temp_dir)
  let assert Ok(_) = simplifile.write(old_path, "test content")

  // Act: Apply renames
  let results = update.apply_renames([#(old_path, new_path)])

  // Assert: Got one Success result
  results |> should.equal([Success(from: old_path, to: new_path)])

  // Assert: File was actually renamed
  simplifile.is_file(old_path) |> should.be_ok() |> should.be_false()
  simplifile.is_file(new_path) |> should.be_ok() |> should.be_true()

  // Cleanup
  let assert Ok(_) = simplifile.delete(new_path)
  let assert Ok(_) = simplifile.delete(temp_dir)
}

pub fn apply_renames_single_file_conflict_test() {
  // Should return Failure when target file already exists (conflict)
  let temp_dir = "test/temp/apply_renames_conflict"
  let old_path = temp_dir <> "/1.txt"
  let new_path = temp_dir <> "/01.txt"

  // Setup: Create temp directory and BOTH files (conflict scenario)
  let assert Ok(_) = simplifile.create_directory_all(temp_dir)
  let assert Ok(_) = simplifile.write(old_path, "old content")
  let assert Ok(_) = simplifile.write(new_path, "new content")

  // Act: Try to apply rename (should fail due to conflict)
  let results = update.apply_renames([#(old_path, new_path)])

  // Assert: Got one Failure result with Eexist error
  results
  |> should.equal([
    Failure(from: old_path, to: new_path, reason: simplifile.Eexist),
  ])

  // Assert: Both files still exist (no overwrite happened)
  simplifile.is_file(old_path) |> should.be_ok() |> should.be_true()
  simplifile.is_file(new_path) |> should.be_ok() |> should.be_true()

  // Assert: New file content unchanged (wasn't overwritten)
  simplifile.read(new_path) |> should.equal(Ok("new content"))

  // Cleanup
  let assert Ok(_) = simplifile.delete(old_path)
  let assert Ok(_) = simplifile.delete(new_path)
  let assert Ok(_) = simplifile.delete(temp_dir)
}

pub fn apply_renames_batch_mixed_results_test() {
  // Should handle multiple files with mix of successes and failures
  let temp_dir = "test/temp/apply_renames_batch"
  let file1_old = temp_dir <> "/1.txt"
  let file1_new = temp_dir <> "/01.txt"
  let file2_old = temp_dir <> "/2.txt"
  let file2_new = temp_dir <> "/02.txt"
  let file3_old = temp_dir <> "/3.txt"
  let file3_new = temp_dir <> "/03.txt"

  // Setup: Create temp directory
  let assert Ok(_) = simplifile.create_directory_all(temp_dir)
  // File 1: Will succeed (only old exists)
  let assert Ok(_) = simplifile.write(file1_old, "content 1")
  // File 2: Will fail (both exist - conflict)
  let assert Ok(_) = simplifile.write(file2_old, "old content 2")
  let assert Ok(_) = simplifile.write(file2_new, "new content 2")
  // File 3: Will succeed (only old exists)
  let assert Ok(_) = simplifile.write(file3_old, "content 3")

  // Act: Apply renames to all three files
  let results =
    update.apply_renames([
      #(file1_old, file1_new),
      #(file2_old, file2_new),
      #(file3_old, file3_new),
    ])

  // Assert: Got correct results in order (success, failure, success)
  results
  |> should.equal([
    Success(from: file1_old, to: file1_new),
    Failure(from: file2_old, to: file2_new, reason: simplifile.Eexist),
    Success(from: file3_old, to: file3_new),
  ])

  // Assert: File 1 renamed successfully
  simplifile.is_file(file1_old) |> should.be_ok() |> should.be_false()
  simplifile.is_file(file1_new) |> should.be_ok() |> should.be_true()

  // Assert: File 2 kept both (conflict - no changes)
  simplifile.is_file(file2_old) |> should.be_ok() |> should.be_true()
  simplifile.is_file(file2_new) |> should.be_ok() |> should.be_true()
  simplifile.read(file2_new) |> should.equal(Ok("new content 2"))

  // Assert: File 3 renamed successfully
  simplifile.is_file(file3_old) |> should.be_ok() |> should.be_false()
  simplifile.is_file(file3_new) |> should.be_ok() |> should.be_true()

  // Cleanup
  let assert Ok(_) = simplifile.delete(file1_new)
  let assert Ok(_) = simplifile.delete(file2_old)
  let assert Ok(_) = simplifile.delete(file2_new)
  let assert Ok(_) = simplifile.delete(file3_new)
  let assert Ok(_) = simplifile.delete(temp_dir)
}

// format_apply_report tests
// pub fn format_apply_report_with_successes_and_failures_test() {
//   // Should format a report showing both successful and failed renames
//   let results = [
//     Success(from: "input/2024/1.txt", to: "input/2024/01.txt"),
//     Failure(
//       from: "input/2024/2.txt",
//       to: "input/2024/02.txt",
//       reason: simplifile.Eexist,
//     ),
//     Success(from: "src/aoc_2024/day_3.gleam", to: "src/aoc_2024/day_03.gleam"),
//   ]

//   let expected =
//     "Successfully renamed:
//   input/2024/1.txt -> input/2024/01.txt
//   src/aoc_2024/day_3.gleam -> src/aoc_2024/day_03.gleam

// Failed to rename:
//   input/2024/2.txt -> input/2024/02.txt (file already exists)

// Changed: 2
// Skipped: 1 (manual intervention required)"

//   update.format_apply_report(results)
//   |> should.equal(expected)
// }

// ===== do_dry_run tests =====

pub fn do_dry_run_with_no_legacy_files_test() {
  let base_path = "test/temp/do_dry_run_no_legacy"

  // Create modern structure only
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/src/aoc_2024/day_01.gleam", "")
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) = simplifile.write(base_path <> "/input/2024/01.txt", "")

  let result = update.do_update(base_path, True)

  let assert Ok(report) = result
  report
  |> should.equal(
    "No files need updating - all files are already using zero-padded names.",
  )

  // Cleanup
  let assert Ok(_) = simplifile.delete(base_path)
}

pub fn do_dry_run_with_legacy_files_test() {
  let base_path = "test/temp/do_dry_run_with_legacy"

  // Create legacy structure
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/src/aoc_2024/day_1.gleam", "")
  let assert Ok(_) =
    simplifile.write(base_path <> "/src/aoc_2024/day_2.gleam", "")
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) = simplifile.write(base_path <> "/input/2024/1.txt", "")
  let assert Ok(_) =
    simplifile.write(base_path <> "/input/2024/2.example.txt", "")

  let result = update.do_update(base_path, True)

  let assert Ok(report) = result
  report
  |> should.equal(
    "Files to be renamed:
  src/aoc_2024/day_1.gleam -> src/aoc_2024/day_01.gleam
  src/aoc_2024/day_2.gleam -> src/aoc_2024/day_02.gleam
  input/2024/1.txt -> input/2024/01.txt
  input/2024/2.example.txt -> input/2024/02.example.txt

4 files will be renamed
Run 'gleam run update apply' to perform the rename operation",
  )

  // Cleanup
  let assert Ok(_) = simplifile.delete(base_path)
}

pub fn do_dry_run_with_missing_src_directory_test() {
  let base_path = "test/temp/do_dry_run_missing_src"

  // Create only input directory, no src/
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) = simplifile.write(base_path <> "/input/2024/1.txt", "")

  let result = update.do_update(base_path, True)

  // Should return error because src/ is required
  result
  |> should.be_error()

  // Cleanup
  let assert Ok(_) = simplifile.delete(base_path)
}

// ===== do_apply tests =====

pub fn do_apply_with_successful_renames_test() {
  let base_path = "test/temp/do_apply_success"

  // Create legacy structure
  let assert Ok(_) =
    simplifile.create_directory_all(base_path <> "/src/aoc_2024")
  let assert Ok(_) =
    simplifile.write(base_path <> "/src/aoc_2024/day_1.gleam", "content")
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) = simplifile.write(base_path <> "/input/2024/1.txt", "input")

  let result = update.do_update(base_path, False)

  let assert Ok(report) = result
  report
  |> should.equal(
    "Successfully renamed:
  src/aoc_2024/day_1.gleam -> src/aoc_2024/day_01.gleam
  input/2024/1.txt -> input/2024/01.txt

Changed: 2
Skipped: 0",
  )

  // Verify files were actually renamed
  simplifile.is_file(base_path <> "/src/aoc_2024/day_01.gleam")
  |> should.equal(Ok(True))
  simplifile.is_file(base_path <> "/input/2024/01.txt")
  |> should.equal(Ok(True))

  // Verify old files are gone
  simplifile.is_file(base_path <> "/src/aoc_2024/day_1.gleam")
  |> should.equal(Ok(False))
  simplifile.is_file(base_path <> "/input/2024/1.txt")
  |> should.equal(Ok(False))

  // Cleanup
  let assert Ok(_) = simplifile.delete(base_path)
}

// pub fn do_apply_with_conflicts_test() {
//   let base_path = "test/temp/do_apply_conflicts"

//   // Create legacy structure with conflicts
//   let assert Ok(_) =
//     simplifile.create_directory_all(base_path <> "/src/aoc_2024")
//   let assert Ok(_) =
//     simplifile.write(base_path <> "/src/aoc_2024/day_1.gleam", "old")
//   let assert Ok(_) =
//     simplifile.write(base_path <> "/src/aoc_2024/day_01.gleam", "new")
//   let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
//   let assert Ok(_) =
//     simplifile.write(base_path <> "/input/2024/2.txt", "input old")
//   let assert Ok(_) =
//     simplifile.write(base_path <> "/input/2024/02.txt", "input new")

//   let result = update.do_update(base_path, False)

//   let assert Ok(report) = result
//   report
//   |> should.equal(
//     "Failed to rename:
//   src/aoc_2024/day_1.gleam -> src/aoc_2024/day_01.gleam (file already exists)
//   input/2024/2.txt -> input/2024/02.txt (file already exists)

// Changed: 0
// Skipped: 2 (manual intervention required)",
//   )

//   // Verify old files still exist (weren't overwritten)
//   simplifile.is_file(base_path <> "/src/aoc_2024/day_1.gleam")
//   |> should.equal(Ok(True))
//   simplifile.is_file(base_path <> "/input/2024/2.txt")
//   |> should.equal(Ok(True))

//   // Verify new files weren't touched
//   simplifile.read(base_path <> "/src/aoc_2024/day_01.gleam")
//   |> should.equal(Ok("new"))
//   simplifile.read(base_path <> "/input/2024/02.txt")
//   |> should.equal(Ok("input new"))

//   // Cleanup
//   let assert Ok(_) = simplifile.delete(base_path)
// }

pub fn do_apply_with_missing_src_directory_test() {
  let base_path = "test/temp/do_apply_missing_src"

  // Create only input directory, no src/
  let assert Ok(_) = simplifile.create_directory_all(base_path <> "/input/2024")
  let assert Ok(_) = simplifile.write(base_path <> "/input/2024/1.txt", "")

  let result = update.do_update(base_path, False)

  // Should return error because src/ is required
  result
  |> should.be_error()

  // Cleanup
  let assert Ok(_) = simplifile.delete(base_path)
}

// ===== Legacy warning message test =====

pub fn legacy_warning_message_test() {
  update.legacy_warning_message(at: "/")
  |> should.equal(
    "*** Legacy files detected at: /.\nRun 'gleam run update' for more information. ***",
  )
}
