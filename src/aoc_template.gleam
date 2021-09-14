import gleam/list
import gleam/io
import gleam/int
import gleam/iterator.{Iterator}
import gleam/result
import gleam/string
import gleam/function
import gleam/otp/task.{Task}
import snag.{Result}
import files
import time
import gleam/erlang/charlist.{Charlist}

pub fn main(args: List(Charlist)) {
  let run_timeout = 1000
  let new_timeout = 1000
  case list.map(args, charlist.to_string) {
    ["new", ..days] ->
      days
      |> init_days(new_timeout)
      |> iterator.to_list

    ["run", ..days] ->
      days
      |> run_days(run_timeout)
      |> iterator.to_list

    args -> [string.concat(["unrecognized command: ", ..args])]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}

fn parse_day_as_int(day: String) -> Result(Int) {
  day
  |> int.parse()
  |> result.replace_error(
    ["failed to parse \"", day, "\" as int"]
    |> string.concat()
    |> snag.new(),
  )
}

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

fn init_days(days: List(String), timeout: Int) -> Iterator(String) {
  days
  |> async_map(init_new_day)
  |> iterator.from_list()
  |> try_await_many(timeout)
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
}

fn init_new_day(day: String) -> Result(Int) {
  try day_num = parse_day_as_int(day)

  let input_path = string.concat(["input/day_", day, ".txt"])
  let gleam_src_path = string.concat(["src/day_", day, ".gleam"])

  let failed_to_create_file =
    function.compose(string.append("failed to create file: ", _), snag.new)

  try _ =
    files.open_file(input_path, files.Write)
    |> result.replace_error(failed_to_create_file(input_path))

  try iodevice =
    files.open_file(gleam_src_path, files.Write)
    |> result.replace_error(failed_to_create_file(gleam_src_path))

  assert files.Ok =
    files.write_file(iodevice, charlist.from_string(gleam_starter))
  Ok(day_num)
}

fn run_result_to_string(day_res: #(String, Result(#(Int, Int)))) {
  let #(day, res) = day_res
  case res {
    Ok(#(pt_1, pt_2)) ->
      [
        "solved day ",
        day,
        "\n\t-> ",
        "part 1: ",
        int.to_string(pt_1),
        "\n\t-> part 2: ",
        int.to_string(pt_2),
      ]
      |> string.concat()
    Error(reason) ->
      reason
      |> snag.layer(string.append("failed to run day ", day))
      |> snag.pretty_print()
  }
}

fn run_days(days: List(String), timeout: Int) -> Iterator(String) {
  days
  |> async_map(run_day)
  |> iterator.from_list()
  |> try_await_many(timeout)
  |> iterator.map(result.flatten)
  |> iterator.zip(iterator.from_list(days), _)
  |> iterator.map(run_result_to_string)
}

fn run_day(day: String) -> Result(#(Int, Int)) {
  try day_num = parse_day_as_int(day)

  let input_path = string.join(["input/day_", day, ".txt"], "")

  try input =
    input_path
    |> files.read_file()
    |> result.replace_error(
      "failed to read input file: "
      |> string.append(input_path)
      |> snag.new(),
    )
  case day_num {
    // 1 -> day_1.run(input)
    // 2 -> day_2.run(input)
    // 3 -> day_3.run(input)
    _ -> Error(snag.new(string.append("unrecognized day: ", day)))
  }
}

fn async_map(over l: List(a), with f: fn(a) -> b) -> List(Task(b)) {
  list.map(l, fn(x) { task.async(fn() { f(x) }) })
}

fn try_await_many(tasks: Iterator(Task(a)), timeout: Int) -> Iterator(Result(a)) {
  let end = time.now_ms() + timeout
  let delayed_try_await = fn(t) {
    task.try_await(t, int.clamp(end - time.now_ms(), 0, timeout))
  }

  tasks
  |> iterator.map(delayed_try_await)
  |> iterator.map(result.map_error(
    over: _,
    with: fn(res) {
      case res {
        task.Timeout -> "task timed out"
        task.Exit(_) -> "task exited for some reason"
      }
      |> snag.new()
    },
  ))
}
