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
    |> glint.name("gladvent")
    |> glint.as_module
    |> glint.group_flag(at: [], for: cmd.year, of: cmd.year_flag())
    |> glint.pretty_help(glint.default_pretty_help())
    |> glint.add(at: ["new"], do: new.new_command())
    |> glint.group_flag(at: ["run"], for: run.timeout, of: run.timeout_flag())
    |> glint.group_flag(
      at: ["run"],
      for: run.allow_crash,
      of: run.allow_crash_flag(),
    )
    |> glint.add(at: ["run"], do: run.run_command())
    |> glint.add(at: ["run", "all"], do: run.run_all_command())

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
