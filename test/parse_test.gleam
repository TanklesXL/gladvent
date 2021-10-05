import parse.{day, timeout}
import gleam/should
import gleam/int
import gleam/list
import snag

pub fn timeout_test() {
  "1"
  |> timeout()
  |> should.equal(Ok(1))

  ["", "0", "-1"]
  |> list.each(fn(s) {
    s
    |> timeout()
    |> should.be_error()
  })
}

pub fn day_test() {
  list.range(1, 26)
  |> list.map(int.to_string)
  |> list.each(fn(s) {
    s
    |> day()
    |> should.equal(parse.int(s))
  })

  ["", "0", "-1", "26"]
  |> list.each(fn(s) {
    s
    |> day()
    |> should.be_error()
  })
}
