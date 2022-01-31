// import days/day_1
// import days/day_2
// import days/day_3
import gleam/map
import gleam/string
import gleam/io
import gleam/erlang.{start_arguments as args}
import cmd/run
import cmd/new
import glint
import glint/flag
import snag

fn runners() {
  map.new()
  // |> map.insert(1, day_1.run)
  // |> map.insert(2, day_2.run)
  // |> map.insert(3, day_3.run)
}

pub fn main() {
  let runners = runners()

  let commands =
    glint.new()
    |> glint.add_command([], fn(_) { io.println(help) }, [])
    |> run.register_command(runners)
    |> glint.add_command(["new"], new.run, [])

  case glint.execute(commands, args()) {
    Ok(Nil) -> Nil
    Error(err) -> {
      let err = snag.pretty_print(err)
      [err, help]
      |> string.join("\n")
      |> io.println()
      exit(1)
    }
  }
}

const help = "\e[1;4mAvailable Commands\e[0m
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
