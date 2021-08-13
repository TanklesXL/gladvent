import gleam/list
import gleam/io
import gleam/int
import gleam/iterator.{Iterator}
import gleam/result
import gleam/string
import gleam/function
import gleam/atom
import gleam/otp/task.{Task}
import snag.{Result}
import file
import time
import charlist.{Charlist}

pub fn main(args: List(Charlist)) {
  let timeout = 1000
  case list.map(args, charlist.to_string) {
    ["new", ..days] ->
      days
      |> iterator.from_list()
      |> init_days(timeout)
      |> iterator.to_list()

    ["run", ..days] ->
      days
      |> iterator.from_list()
      |> run_days(timeout)
      |> iterator.to_list()

    args -> [string.concat(["unrecognized command ", ..args])]
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

const gleam_starter = "import gleam/result
import gleam/string

pub fn run(input: String) -> Result(#(Int, Int), String) {
  try pt_1 =
    pt_1(input)
    |> result.map_error(string.append(\"failed part 1: \", _))

  try pt_2 =
    pt_2(input)
    |> result.map_error(string.append(\"failed part 2: \", _))

  Ok(#(pt_1, pt_2))
}

fn pt_1(input: String) -> Result(Int, String) {
  todo
}

fn pt_2(input: String) -> Result(Int, String) {
  todo
}
"

fn init_days(days: Iterator(String), timeout: Int) -> Iterator(String) {
  days
  |> iterator.map(fn(day) { task.async(fn() { init_new_day(day) }) })
  |> try_await_many(timeout)
  |> iterator.map(result.flatten)
  |> iterator.zip(days)
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
    file.open_file(input_path, file.Write)
    |> result.replace_error(failed_to_create_file(input_path))

  try iodevice =
    file.open_file(gleam_src_path, file.Write)
    |> result.replace_error(failed_to_create_file(gleam_src_path))

  assert file.Ok =
    file.write_file(iodevice, charlist.from_string(gleam_starter))
  Ok(day_num)
}

fn run_result_to_string(res: #(Result(#(Int, Int)), String)) {
  case res.0
  |> snag.context(string.append("failed to run day ", res.1))
  |> result.map_error(snag.pretty_print) {
    Ok(solution) ->
      [
        "solved day ",
        res.1,
        "\n\t-> ",
        "part 1: ",
        int.to_string(solution.0),
        "\n\t-> part 2: ",
        int.to_string(solution.1),
      ]
      |> string.concat()
    Error(reason) -> reason
  }
}

fn run_days(days: Iterator(String), timeout: Int) -> Iterator(String) {
  days
  |> iterator.map(fn(day) { task.async(fn() { run_day(day) }) })
  |> try_await_many(timeout)
  |> iterator.map(result.flatten)
  |> iterator.zip(days)
  |> iterator.map(run_result_to_string)
}

fn run_day(day: String) -> Result(#(Int, Int)) {
  try day_num = parse_day_as_int(day)

  let input_path = string.join(["input/day_", day, ".txt"], "")

  try input =
    input_path
    |> file.read_file()
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

pub fn try_await_many(
  tasks: Iterator(Task(a)),
  timeout: Int,
) -> Iterator(Result(a)) {
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
