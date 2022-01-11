import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/list
import gleam/io
import gleam/int
import gleam/result
import gleam/string
import snag.{Result}
import cli/flag.{Flag, FlagMap}

pub type CommandInput {
  CommandInput(args: List(String), flags: FlagMap)
}

pub type Runner =
  fn(CommandInput) -> Nil

pub opaque type Command {
  Command(do: Option(Runner), subcommands: CommandTree, flags: FlagMap)
}

type CommandTree =
  Map(String, Command)

pub fn new() -> Command {
  Command(do: None, subcommands: map.new(), flags: map.new())
}

pub fn add_command(
  to root: Command,
  at path: List(String),
  do f: Runner,
  with flags: List(Flag),
) -> Command {
  case path {
    [] ->
      Command(
        ..root,
        do: Some(f),
        flags: list.fold(
          flags,
          map.new(),
          fn(m, flag: Flag) { map.insert(m, flag.name, flag.value) },
        ),
      )
    [x, ..xs] ->
      Command(
        ..root,
        subcommands: map.update(
          root.subcommands,
          x,
          fn(node) {
            case node {
              None ->
                add_command(
                  Command(do: None, subcommands: map.new(), flags: map.new()),
                  xs,
                  f,
                  flags,
                )
              Some(node) -> add_command(node, xs, f, flags)
            }
          },
        ),
      )
  }
}

fn execute_root(cmd: Command, args: List(String)) -> Result(Nil) {
  case cmd.do {
    Some(f) -> Ok(f(CommandInput(args, cmd.flags)))
    None -> Error(snag.new("command not found"))
  }
}

pub fn execute(cmd: Command, args: List(String)) -> Result(Nil) {
  case args {
    [] -> execute_root(cmd, [])
    [arg, ..rest] ->
      case string.starts_with(arg, "-") {
        True -> {
          try new_flags =
            flag.update_flags(cmd.flags, string.drop_left(arg, 1))
            |> snag.context("failed to run command")
          execute(Command(..cmd, flags: new_flags), rest)
        }
        False ->
          case map.get(cmd.subcommands, arg) {
            Ok(cmd) -> execute(cmd, rest)
            Error(_) -> execute_root(cmd, args)
          }
      }
  }
}

pub fn run(cmd: Command, args: List(String)) -> Nil {
  case execute(cmd, args) {
    Ok(Nil) -> Nil
    Error(err) ->
      err
      |> snag.pretty_print()
      |> io.println()
  }
}
