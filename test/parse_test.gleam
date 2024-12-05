import gladvent/internal/parse.{day, pad}
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

pub fn pad_test() {
  pad(1) |> should.equal("01")
}

pub fn padded_day_to_int_test() {
  "01" |> int.parse() |> should.be_ok() |> should.equal(1)
}
