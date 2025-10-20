import gleam/list
import gleam/option.{type Option, None}
import gleam/string

pub fn update_path(path: String) -> Option(String) {
  // split on /
  let digit = string.split(path, "/") |> list.last
  case digit {
    Ok(str_digit) -> {
      case string.drop_end(str_digit, up_to: 4) |> string.length() != 2 {
        True -> todo as "pad value and rebuild path"
        False -> None
      }
    }
    _ -> None
  }
  // grab last list item
  // split on .
  // check len of digit prior, if 1 pad and return Some(updated_str) else None
  None
}
