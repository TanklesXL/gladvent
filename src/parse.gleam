import snag.{Result}
import gleam/int
import gleam/string
import gleam/result

pub fn int(s: String) -> Result(Int) {
  s
  |> int.parse()
  |> result.replace_error(
    ["failed to parse \"", s, "\" as int"]
    |> string.concat()
    |> snag.new(),
  )
}

pub fn day(s: String) -> Result(Int) {
  try day = int(s)
  case day {
    _ if day < 1 || day > 25 ->
      Error(
        "day must be between 1 and 25"
        |> snag.new()
        |> snag.layer("failed to parse day"),
      )
    _ -> Ok(day)
  }
}
