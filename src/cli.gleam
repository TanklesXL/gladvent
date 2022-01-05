import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/list
import gleam/io
import gleam/result
import snag.{Result, Snag}

pub type Runner =
  fn(List(String)) -> Nil

pub fn new() -> Command {
  Command(do: None, subcommands: map.new())
}

pub fn add_command(
  to root: Command,
  at path: List(String),
  do f: Runner,
) -> Command {
  case path {
    [] -> Command(..root, do: Some(f))
    [x, ..xs] ->
      Command(
        ..root,
        subcommands: map.update(
          root.subcommands,
          x,
          fn(node) {
            case node {
              None ->
                add_command(Command(do: None, subcommands: map.new()), xs, f)
              Some(node) -> add_command(node, xs, f)
            }
          },
        ),
      )
  }
}

pub opaque type Command {
  Command(do: Option(Runner), subcommands: CommandTree)
}

type CommandTree =
  Map(String, Command)

fn command_not_found() -> Snag {
  snag.new("command not found")
}

fn execute_root(cmd: Command, args: List(String)) -> Result(Nil) {
  case cmd.do {
    Some(f) -> Ok(f(args))
    None -> Error(command_not_found())
  }
}

pub fn execute(cmd: Command, args: List(String)) -> Result(Nil) {
  case args {
    [] -> execute_root(cmd, [])
    [arg, ..rest] ->
      case map.get(cmd.subcommands, arg) {
        Ok(cmd) -> execute(cmd, rest)
        Error(_) -> execute_root(cmd, args)
      }
  }
}

pub fn run(cmd: Command, args: List(String)) -> Nil {
  cmd
  |> execute(args)
  |> result.map_error(fn(err) {
    err
    |> snag.pretty_print()
    |> io.println()
  })
  Nil
}
