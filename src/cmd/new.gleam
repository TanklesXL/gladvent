import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import snag.{Result, Snag}
import files
import time
import async
import parse
import gleam/erlang/charlist

const gleam_starter = "import snag.{Result}

pub fn run(input: String) -> Result(#(Int, Int)) {
  try pt_1 =
    input
    |> pt_1()
    |> snag.context(\"failed part 1\")

  try pt_2 =
    input
    |> pt_2()
    |> snag.context(\"failed part 2\")

  Ok(#(pt_1, pt_2))
}

fn pt_1(input: String) -> Result(Int) {
  todo
}

fn pt_2(input: String) -> Result(Int) {
  todo
}
"

pub fn exec(days: List(String), timeout: Int) -> List(String) {
  days
  |> async.list_map(init_new_day)
  |> iterator.from_list()
  |> async.iterator_try_await_many(timeout)
  |> iterator.map(result.flatten)
  |> iterator.zip(iterator.from_list(days))
  |> iterator.map(fn(res: #(Result(Int), String)) {
    case res.0
    |> snag.context(string.append("failed to initialize day ", res.1))
    |> result.map_error(snag.pretty_print) {
      Ok(_) -> string.append("initialized day: ", res.1)
      Error(reason) -> reason
    }
  })
  |> iterator.to_list()
}

fn failed_to_create_file_err(s: String) -> Snag {
  s
  |> string.append("failed to create file: ", _)
  |> snag.new()
}

fn init_new_day(day: String) -> Result(Int) {
  try day_num = parse.int(day)

  let input_path = string.concat(["input/day_", day, ".txt"])
  let gleam_src_path = string.concat(["src/days/day_", day, ".gleam"])

  try _ =
    files.open_file(input_path, files.Write)
    |> result.replace_error(failed_to_create_file_err(input_path))

  try iodevice =
    files.open_file(gleam_src_path, files.Write)
    |> result.replace_error(failed_to_create_file_err(gleam_src_path))

  assert files.Ok =
    files.write_file(iodevice, charlist.from_string(gleam_starter))
  Ok(day_num)
}
