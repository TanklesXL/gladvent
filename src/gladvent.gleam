import gleam/string
import gleam/io
import gleam/erlang.{start_arguments as args}
import runners.{RunnerMap}
import cmd/run
import cmd/new
import glint
import snag

/// Find all runners in the project src/days/ directory and
/// run either the 'run' or 'new' command as specified
///
pub fn main() {
  case runners.build_from_days_dir() {
    Ok(runners) -> execute(given: runners)
    Error(err) -> print_snag_and_halt(err)
  }
}

/// Given the daily runners, create the command tree and run the specified command
///
pub fn execute(given runners: RunnerMap) {
  let commands =
    glint.new()
    |> run.register_command(runners)
    |> new.register_command()

  let args = args()
  case commands
  |> glint.execute(args) {
    Ok(glint.Out(Ok(output))) ->
      output
      |> string.join("\n\n")
      |> io.println
    Ok(glint.Help(help)) -> io.println(help)
    Ok(glint.Out(Error(err))) | Error(err) -> print_snag_and_halt(err)
  }
}

external fn exit(Int) -> Nil =
  "erlang" "halt"

fn print_snag_and_halt(err: snag.Snag) -> Nil {
  err
  |> snag.pretty_print()
  |> io.println()
  exit(1)
}
