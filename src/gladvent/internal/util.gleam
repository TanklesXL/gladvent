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
