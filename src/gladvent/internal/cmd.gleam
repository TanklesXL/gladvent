import filepath
import gladvent/internal/parse.{type Day}
import gleam/int
import gleam/list
import gleam/otp/task
import gleam/pair
import gleam/result
import glint
import parallel_map
import simplifile
import snag

pub fn root() -> String {
  find_root(".")
}

fn find_root(path: String) -> String {
  let toml = filepath.join(path, "gleam.toml")

  case simplifile.is_file(toml) {
    Ok(False) | Error(_) -> find_root(filepath.join("..", path))
    Ok(True) -> path
  }
}

pub fn input_root() {
  filepath.join(root(), "input")
}

pub fn input_dir(year) {
  filepath.join(input_root(), int.to_string(year))
}

pub fn src_root() {
  filepath.join(root(), "src")
}

pub fn src_dir(year) {
  filepath.join(src_root(), "aoc_" <> int.to_string(year))
}

pub type Timing {
  Endless
  Ending(Timeout)
}

pub type Timeout =
  Int

pub type Year =
  Int

pub fn exec(
  days: List(Day),
  timing: Timing,
  do: fn(Day) -> a,
  collect: fn(#(Day, Result(a, String))) -> c,
) -> List(c) {
  case timing {
    Endless ->
      days
      // spawn all tasks
      |> list.map(fn(day) { #(day, task.async(fn() { do(day) })) })
      // start collecting tasks
      |> fn(tasks) {
        use tup <- list.map(tasks)
        use t <- pair.map_second(tup)
        Ok(task.await_forever(t))
      }
    Ending(timeout) -> {
      parallel_map.list_pmap(
        days,
        do,
        parallel_map.MatchSchedulersOnline,
        timeout,
      )
      |> list.map(result.replace_error(_, "failed to execute task"))
      |> list.zip(days, _)
    }
  }
  |> list.map(collect)
}

@external(erlang, "erlang", "localtime")
fn date() -> #(#(Int, Int, Int), #(Int, Int, Int))

fn current_year() -> Int {
  { date().0 }.0
}

pub fn year_flag() {
  use year <- glint.flag_constraint(
    glint.int_flag("year")
    |> glint.flag_default(current_year()),
  )
  case year < 2015 {
    True ->
      snag.error("advent of code did not exist prior to 2015, did you mistype?")
    False -> Ok(year)
  }
}
