import gladvent/internal/util
import gleam/list
import gleeunit/should

pub fn format_float_test() {
  use #(float, precision, expected) <- list.each([
    #(123.123, 4, "123.1230"),
    #(123.123, 2, "123.12"),
    #(123.123, 0, "123"),
    #(123.123, -3, "123"),
    #(-123.123, 2, "-123.12"),
    #(0.0, 0, "0"),
  ])

  util.format_float(float, precision)
  |> should.equal(expected)
}
