import gladvent/internal/parse.{day}
import gleam/int
import gleam/list
import gleeunit/should

pub fn day_success_test() {
  use x <- list.each(list.range(1, 25))

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
