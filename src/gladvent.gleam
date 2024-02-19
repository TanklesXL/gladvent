import gleam/string
import gleam/io
import gladvent/internal/cmd/run
import gladvent/internal/cmd/new
import gladvent/internal/cmd
import glint
import snag
import argv

/// Find all runners in the project src/days/ directory and
/// run either the 'run' or 'new' command as specified
///
pub fn main() {
  let commands =
    glint.new()
    |> glint.with_name("gladvent")
    |> glint.as_gleam_module
    |> glint.global_flag(cmd.year, cmd.year_flag())
    |> glint.with_pretty_help(glint.default_pretty_help())
    |> glint.add(["new"], new.new_command())
    |> glint.add(["run"], run.run_command())
    |> glint.add(["run", "all"], run.run_all_command())

  use out <- glint.run_and_handle(commands, argv.load().arguments)
  case out {
    Ok(out) ->
      out
      |> string.join("\n\n")
      |> io.println
    Error(err) -> print_snag_and_halt(err)
  }
}

@external(erlang, "erlang", "halt")
fn exit(a: Int) -> Nil

fn print_snag_and_halt(err: snag.Snag) -> Nil {
  err
  |> snag.pretty_print()
  |> io.println()
  exit(1)
}
