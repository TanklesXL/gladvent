import parse.{day, timeout}
import gleam/int
import gleam/list
import gleam/function.{compose}
import snag

pub fn timeout_test() {
  assert Ok(1) = timeout("1")

  ["", "0", "-1"]
  |> list.each(fn(s) { assert Error(_) = timeout(s) })
}

pub fn day_test() {
  assert Ok(1) = day("1")

  // TODO: make better when readding gleam_should_assertions
  ["", "0", "-1", "26"]
  |> list.each(fn(s) { assert Error(_) = day(s) })
}
