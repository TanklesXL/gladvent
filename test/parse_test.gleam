import parse.{day, timeout, timeout_and_days}
import gleam/int
import gleam/list
import gleam/function.{compose}
import snag
import gleeunit/should

pub fn timeout_test() {
  "1"
  |> timeout()
  |> should.be_ok()

  list.each(["", "0", "-1"], compose(timeout, should.be_error))
}

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

pub fn args_test() {
  ["1000", "a", "2", "3"]
  |> timeout_and_days()
  |> should.be_error()

  ["1000", "1", "2", "3"]
  |> timeout_and_days()
  |> should.equal(Ok(#(1000, [1, 2, 3])))

  ["0", "1", "2", "3"]
  |> timeout_and_days()
  |> should.be_error()
}
