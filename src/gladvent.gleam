import gleam/map
import gleam/string
import gleam/io
import gleam/erlang.{start_arguments as args}
import cmd/run.{RunnerMap}
import cmd/new
import glint
import glint/flag
import snag

/// find all runners in the project src/days/ directory and
/// run either the 'run' or 'new' command as specified
pub fn main() {
  case run.build_runners_from_days_dir() {
    Ok(runners) -> execute(given: runners)
    Error(err) -> {
      err
      |> snag.pretty_print()
      |> io.println()
      exit(1)
    }
  }
}

/// given the daily runners, create the command tree and run the specified command
pub fn execute(given runners: RunnerMap) {
  let commands =
    glint.new()
    |> glint.add_command([], fn(_) { io.println(help) }, [])
    |> run.register_command(runners)
    |> new.register_command()

  case glint.execute(commands, args()) {
    Ok(Nil) -> Nil
    Error(err) -> {
      [snag.pretty_print(err), help]
      |> string.join("\n")
      |> io.println()
      exit(1)
    }
  }
}

const help = "\n\e[1;4mAvailable Commands\e[0m
\e[1;3mrun\e[0m: run the specified days
  usage: gleam run run <dayX> <dayY> <...>
  flags:
      --timeout: run with specified timeout
        type: Int > 0 
        usage: gleam run run --timeout=1000 <dayX> <dayY> <...>

      --all: run all registered days
        type: Bool
        usage: gleam run run --all

\e[1;3mnew\e[0m: create .gleam and input files
  usage: gleam run new <dayX> <dayY> <...>  
"

external fn exit(Int) -> Nil =
  "erlang" "halt"
