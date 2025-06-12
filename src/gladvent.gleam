import argv
import gladvent/internal/cmd
import gladvent/internal/cmd/new
import gladvent/internal/cmd/run
import gleam/string
import glint
import glintio

/// Add this function to your project's `main` function in order to run the gladvent CLI.
///
/// This function gets its input from the command line arguments by using the `argv` library.
///
pub fn run() {
  glint.new()
  |> glint.with_name("gladvent")
  |> glint.with_version("2.3.0")
  |> glint.path_help(
    [],
    "gladvent is an advent of code runner and generator for gleam.


      Please use either the 'run' or 'new' commands.
      ",
  )
  |> glint.with_default_header_style
  |> glint.group_flag(at: [], of: cmd.year_flag())
  |> glint.add(at: ["new"], do: new.new_command())
  |> glint.group_flag(at: ["run"], of: run.timeout_flag())
  |> glint.group_flag(at: ["run"], of: run.allow_crash_flag())
  |> glint.group_flag(at: ["run"], of: run.timed_flag())
  |> glint.add(at: ["run"], do: run.run_command())
  |> glint.add(at: ["run", "all"], do: run.run_all_command())
  |> glint.run(argv.load().arguments)
  |> glintio.print(string.join(_, "\n\n"))
  |> glintio.exit
}
