import gladvent/internal/parse.{day, pad}
import gleam/int
import gleam/list

pub fn day_success_test() {
  use x <- list.each(list.range(1, 25))

  assert x
    |> int.to_string()
    |> day
    == Ok(x)
}

pub fn day_error_test() {
  list.each(["", "0", "-1", "26"], fn(x) {
    let assert Error(_) = day(x)
  })
}

pub fn pad_test() {
  assert pad(1) == "01"
}

pub fn padded_day_to_int_test() {
  assert "01" |> int.parse() == Ok(1)
}
