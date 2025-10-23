import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import simplifile.{type FileError}

pub fn update_path(path: String) -> Option(String) {
  let split = string.split(path, "/")
  case split {
    ["input", year, input_name] -> update_input_path(year, input_name)
    ["src", aoc_year, gleam_file_name] ->
      update_src_path(aoc_year, gleam_file_name)
    _ -> None
  }
}

fn update_input_path(year: String, input_name: String) -> Option(String) {
  {
    use day <- result.try(list.first(string.split(input_name, ".")))

    case string.length(day) == 1 {
      True -> Ok(string.join(["input", year, "0" <> input_name], "/"))
      False -> Error(Nil)
    }
  }
  |> option.from_result
}

fn update_src_path(aoc_year: String, gleam_file_name: String) -> Option(String) {
  {
    let day_with_ext = string.drop_start(gleam_file_name, up_to: 4)
    use day <- result.try(list.first(string.split(day_with_ext, ".")))

    case string.length(day) == 1 {
      True ->
        Ok(string.join(["src", aoc_year, "day_0" <> day <> ".gleam"], "/"))
      False -> Error(Nil)
    }
  }
  |> option.from_result
}

pub fn find_legacy_files(paths: List(String)) -> List(#(String, String)) {
  list.fold(paths, [], fn(acc, path) {
    case update_path(path) {
      Some(new_path) -> [#(path, new_path), ..acc]
      None -> acc
    }
  })
  |> list.reverse
}

pub fn format_dry_run_report(paths: List(#(String, String))) -> String {
  case list.is_empty(paths) {
    True ->
      "No files need updating - all files are already using zero-padded names."
    False -> {
      let report = "Files to be renamed:\n"
      list.fold(paths, report, fn(acc, path) {
        acc <> "  " <> path.0 <> " -> " <> path.1 <> "\n"
      })
      |> string.append(
        "\n"
        <> int.to_string(list.length(paths))
        <> " files will be renamed\n"
        <> "Run 'gleam run update --apply' to perform the rename operation",
      )
    }
  }
}

pub fn should_include_file(file: String) -> Bool {
  !string.starts_with(file, ".")
  && {
    case string.split(file, ".") {
      [day, "txt"] -> is_valid_day(day)
      [day, "example", "txt"] -> is_valid_day(day)
      [prefix, "gleam"] ->
        case string.split(prefix, "_") {
          ["day", day] -> is_valid_day(day)
          _ -> False
        }
      _ -> False
    }
  }
}

fn is_valid_day(day: String) -> Bool {
  case int.parse(day) {
    Ok(d) -> d >= 1 && d < 26
    _ -> False
  }
}

pub fn should_include_path(path: String) -> Bool {
  let graphemes = string.split(path, "/")
  case list.last(graphemes) {
    Ok(filename) -> should_include_file(filename)
    _ -> False
  }
}

pub fn scan_files(path: String) -> Result(List(String), FileError) {
  case simplifile.get_files(path) {
    Ok(files) -> {
      list.filter(files, fn(file) { should_include_path(file) })
      |> list.map(fn(file) {
        string.split(file, "/")
        |> list.reverse
        |> list.take(up_to: 3)
        |> list.reverse
        |> string.join("/")
      })
      |> list.sort(string.compare)
      |> Ok
    }
    Error(e) ->
      case string.ends_with(path, "src/") || string.ends_with(path, "src") {
        True -> Error(e)
        False -> Ok([])
      }
  }
}

pub fn scan_project_files(path: String) -> Result(List(String), FileError) {
  let src = scan_files(path <> "/src/")
  let input = scan_files(path <> "/input/")
  case src, input {
    Ok(s), Ok(i) -> Ok(list.append(s, i))
    Error(e), _ -> Error(e)
    _, Error(_) -> Ok([])
  }
}

pub fn rename_file(old_path: String, new_path: String) -> Result(Nil, FileError) {
  case simplifile.is_file(new_path) {
    Ok(True) -> Error(simplifile.Eexist)
    Ok(False) -> simplifile.rename(old_path, new_path)
    Error(e) -> Error(e)
  }
}
