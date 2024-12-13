import gleam/erlang/charlist.{type Charlist}
import gleam/float
import gleam/int
import gleam/list
import gleam/set

pub fn defer(do later: fn() -> _, after now: fn() -> a) -> a {
  let res = now()
  later()
  res
}

pub fn deduplicate_sort(l: List(Int)) -> List(Int) {
  l |> set.from_list |> set.to_list |> list.sort(int.compare)
}

@external(erlang, "timer", "tc")
pub fn timed(fun: fn() -> a) -> #(Int, a)

pub fn format_float(input: Float, precision: Int) -> String {
  case precision {
    p if p >= 1 ->
      do_format("~." <> int.to_string(precision) <> "f", input)
      |> charlist.to_string
    _ -> float.truncate(input) |> int.to_string
  }
}

@external(erlang, "io_lib", "format")
fn do_format(format: String, data: a) -> Charlist
