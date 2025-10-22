import gladvent/internal/cmd/update.{
  find_legacy_files, format_dry_run_report, scan_input_files, should_include_file,
  should_include_path, update_path,
}

import gleam/list
import gleam/option.{None, Some}
import gleeunit/should

pub fn update_path_input_file_day_1_test() {
  update_path("input/2024/1.txt")
  |> should.equal(Some("input/2024/01.txt"))
}

pub fn update_path_input_file_day_1_example_test() {
  update_path("input/2024/1.example.txt")
  |> should.equal(Some("input/2024/01.example.txt"))
}

pub fn update_path_input_file_day_already_padded_test() {
  update_path("input/2024/01.txt")
  |> should.equal(None)
}

pub fn update_path_input_file_day_already_padded_example_test() {
  update_path("input/2024/01.example.txt")
  |> should.equal(None)
}

pub fn update_path_src_file_day_1_test() {
  update_path("src/aoc_2024/day_1.gleam")
  |> should.equal(Some("src/aoc_2024/day_01.gleam"))
}

pub fn update_path_src_file_day_already_padded_test() {
  update_path("src/aoc_2024/day_01.gleam")
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
    update_path(input)
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

  find_legacy_files(paths)
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
Run 'gleam run update --apply' to perform the rename operation"

  format_dry_run_report(legacy_files)
  |> should.equal(expected)
}

pub fn format_dry_run_report_empty_test() {
  let legacy_files = []

  let expected =
    "No files need updating - all files are already using zero-padded names."

  format_dry_run_report(legacy_files)
  |> should.equal(expected)
}

// should_include_file tests - rewriting with pattern matching approach
pub fn should_include_file_valid_txt_test() {
  should_include_file("1.txt")
  |> should.be_true
}

pub fn should_include_file_valid_padded_txt_test() {
  should_include_file("01.txt")
  |> should.be_true
}

pub fn should_include_file_valid_example_txt_test() {
  should_include_file("5.example.txt")
  |> should.be_true
}

pub fn should_include_file_valid_day_25_test() {
  should_include_file("25.txt")
  |> should.be_true
}

pub fn should_include_file_invalid_day_26_test() {
  should_include_file("26.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_day_0_test() {
  should_include_file("0.txt")
  |> should.be_false
}

pub fn should_include_file_hidden_file_test() {
  should_include_file(".gitignore")
  |> should.be_false
}

pub fn should_include_file_hidden_txt_test() {
  should_include_file(".hidden.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_my_example_txt_test() {
  should_include_file("my_example.txt")
  |> should.be_false
}

pub fn should_include_file_invalid_readme_md_test() {
  should_include_file("readme.md")
  |> should.be_false
}

pub fn should_include_file_invalid_no_extension_test() {
  should_include_file("LICENSE")
  |> should.be_false
}

pub fn should_include_file_day_gleam_test() {
  should_include_file("day_3.gleam")
  |> should.be_true
}

pub fn should_include_file_day_padded_gleam_test() {
  should_include_file("day_03.gleam")
  |> should.be_true
}

pub fn should_include_file_invalid_gleam_test() {
  should_include_file("helper.gleam")
  |> should.be_false
}

// should_include_path tests - rewriting with pattern matching approach
pub fn should_include_path_with_input_txt_test() {
  should_include_path("input/2024/1.txt")
  |> should.be_true
}

pub fn should_include_path_with_example_txt_test() {
  should_include_path("input/2024/5.example.txt")
  |> should.be_true
}

pub fn should_include_path_with_src_gleam_test() {
  should_include_path("src/aoc_2024/day_3.gleam")
  |> should.be_true
}

pub fn should_include_path_with_deep_nesting_test() {
  should_include_path("test/fixtures/with_input/input/2024/1.txt")
  |> should.be_true
}

pub fn should_include_path_rejects_hidden_file_test() {
  should_include_path("input/2024/.gitignore")
  |> should.be_false
}

pub fn should_include_path_rejects_hidden_txt_test() {
  should_include_path("input/2024/.hidden.txt")
  |> should.be_false
}

pub fn should_include_path_rejects_fake_example_test() {
  should_include_path("input/2024/my_example.txt")
  |> should.be_false
}

pub fn should_include_path_rejects_wrong_extension_test() {
  should_include_path("input/2024/readme.md")
  |> should.be_false
}

pub fn should_include_path_rejects_invalid_day_test() {
  should_include_path("input/2024/26.txt")
  |> should.be_false
}

pub fn should_include_path_empty_path_test() {
  should_include_path("")
  |> should.be_false
}

// scan_input_files tests
pub fn scan_input_files_returns_empty_list_when_input_dir_missing_test() {
  // When input/ directory doesn't exist, should return Ok([])
  scan_input_files("test/fixtures/no_input")
  |> should.equal(Ok([]))
}

pub fn scan_input_files_finds_txt_files_test() {
  // Should find .txt files in input/<year>/ directories
  // Test structure: test/fixtures/with_input/input/2024/{1.txt, 10.txt}
  scan_input_files("test/fixtures/with_input")
  |> should.equal(Ok(["input/2024/1.txt", "input/2024/10.txt"]))
}

pub fn scan_input_files_ignores_non_txt_files_test() {
  // Should only include .txt files, ignore other file types
  // Test structure: test/fixtures/with_other_files/input/2024/{1.txt, readme.md}
  scan_input_files("test/fixtures/with_other_files")
  |> should.equal(Ok(["input/2024/1.txt"]))
}

pub fn scan_input_files_finds_example_txt_files_test() {
  // Should find .example.txt files (with the dot prefix)
  // Should reject files like "my_example.txt" (without dot prefix)
  // Test structure: test/fixtures/with_examples/input/2024/{1.example.txt, 5.txt, my_example.txt}
  scan_input_files("test/fixtures/with_examples")
  |> should.equal(Ok(["input/2024/1.example.txt", "input/2024/5.txt"]))
}
