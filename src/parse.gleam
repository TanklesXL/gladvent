import snag.{Result}
import gleam/int
import gleam/list
import gleam/string
import gleam/result

fn int(s: String) -> Result(Int) {
  s
  |> int.parse()
  |> result.replace_error(
    ["failed to parse \"", s, "\" as int"]
    |> string.concat()
    |> snag.new(),
  )
}

fn valid_int(
  s: String,
  is_valid: fn(Int) -> Bool,
  invalid_msg: String,
) -> Result(Int) {
  try i = int(s)
  case is_valid(i) {
    False -> Error(snag.new(invalid_msg))
    True -> Ok(i)
  }
}

pub type Day =
  Int

pub fn day(s: String) -> Result(Day) {
  let is_valid = fn(i) { i >= 1 && i <= 25 }
  s
  |> valid_int(is_valid, "day must be an integer from 1 to 25")
  |> snag.context(string.concat(["invalid day value", " '", s, "' "]))
}

pub fn days(l: List(String)) -> Result(List(Day)) {
  l
  |> list.try_map(day)
  |> snag.context("could not map day values to integers")
}

pub type Timeout =
  Int

pub fn timeout(s: String) -> Result(Timeout) {
  let is_valid = fn(i) { i >= 1 }
  s
  |> valid_int(is_valid, "timeout must be greater than or equal to 1 ms")
  |> snag.context(string.concat(["invalid timeout value", " '", s, "' "]))
}
