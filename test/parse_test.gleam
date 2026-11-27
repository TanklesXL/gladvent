import gladvent/internal/parse.{day}
import gleam/int
import gleam/list
import gleeunit/should

pub fn day_success_test() {
  use x <- list.each(int.range(from: 25, to: 0, with: [], run: list.prepend))

  x
  |> int.to_string()
  |> day
  |> should.equal(Ok(x))
}

pub fn day_error_test() {
  list.each(["", "0", "-1", "26"], fn(x) {
    x
    |> day
    |> should.be_error
  })
}
