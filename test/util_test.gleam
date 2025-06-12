import gladvent/internal/util
import gleam/list

pub fn format_float_test() {
  use #(float, precision, expected) <- list.each([
    #(123.123, 4, "123.1230"),
    #(123.123, 2, "123.12"),
    #(123.123, 0, "123"),
    #(123.123, -3, "123"),
    #(-123.123, 2, "-123.12"),
    #(0.0, 0, "0"),
  ])

  assert util.format_float(float, precision) == expected
}
