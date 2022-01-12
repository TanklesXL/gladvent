import parse.{day}
import gleam/int
import gleam/list
import gleam/function.{compose}
import snag
import gleeunit/should

pub fn day_test() {
  list.range(1, 26)
  |> list.each(fn(x) {
    x
    |> int.to_string()
    |> day()
    |> should.equal(Ok(x))
  })

  list.each(["", "0", "-1", "26"], compose(day, should.be_error))
}
