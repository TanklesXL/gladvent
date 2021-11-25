import snag.{Result}
import gleam/int
import gleam/list
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

pub fn valid_int(
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

fn greater_than_0(i: Int) -> Bool {
  i > 0
}

fn less_than_26(i: Int) -> Bool {
  i < 26
}

pub type Day =
  Int

fn valid_day(i: Int) -> Bool {
  greater_than_0(i) && less_than_26(i)
}

pub fn day(s: String) -> Result(Day) {
  valid_int(s, valid_day, "day must be an integer from 1 to 25")
  |> snag.context(string.concat(["invalid day value ", "'", s, "'"]))
}

pub fn days(l: List(String)) -> Result(List(Day)) {
  l
  |> list.try_map(day)
  |> snag.context("could not map day values to integers")
}

pub type Timeout =
  Int

pub fn timeout(s: String) -> Result(Timeout) {
  valid_int(s, greater_than_0, "timeout must be greater than or equal to 1 ms")
  |> snag.context(string.concat(["invalid timeout value ", "'", s, "'"]))
}
