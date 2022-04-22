import snag.{Result}
import gleam
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Day =
  Int

pub fn int(s: String) -> Result(Int) {
  s
  |> int.parse
  |> replace_error(
    ["failed to parse \"", s, "\" as int"]
    |> string.concat(),
  )
}

pub fn day(s: String) -> Result(Day) {
  try i = int(s)

  case i > 0 && i < 26 {
    True -> Ok(i)
    False ->
      ["invalid day value ", "'", s, "'"]
      |> string.concat
      |> snag.error
      |> snag.context("day must be an integer from 1 to 25")
  }
}

pub fn days(l: List(String)) -> Result(List(Day)) {
  case l {
    [] -> snag.error("no days selected")
    _ ->
      l
      |> list.try_map(day)
      |> snag.context("could not map day values to integers")
  }
}

pub fn replace_error(r: gleam.Result(a, b), s: String) -> Result(a) {
  result.replace_error(r, snag.new(s))
}
