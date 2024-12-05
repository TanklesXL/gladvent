import gleam/int
import gleam/list
import gleam/result
import gleam/string
import snag.{type Result}

pub type Day =
  Int

pub fn int(s: String) -> Result(Int) {
  s
  |> int.parse
  |> result.replace_error(snag.new("failed to parse \"" <> s <> "\" as int"))
}

pub fn day(s: String) -> Result(Day) {
  use i <- result.then(int(s))

  case i > 0 && i < 26 {
    True -> Ok(i)
    False ->
      { "invalid day value " <> "'" <> s <> "'" }
      |> snag.error
      |> snag.context("day must be an integer from 1 to 25")
  }
}

pub fn days(l: List(String)) -> Result(List(Day)) {
  list.try_map(l, day)
  |> snag.context("could not map day values to integers")
}

pub fn pad(day: Day) -> String {
  int.to_string(day) |> string.pad_start(to: 2, with: "0")
}
