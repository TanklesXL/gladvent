// import days/day_1
// import days/day_2
// import days/day_3
import gleam/map
import gleam/erlang.{start_arguments as args}
import cmd/run
import cmd/new
import cli
import cli/flag

fn runners() {
  map.new()
  // |> map.insert(1, day_1.run)
  // |> map.insert(2, day_2.run)
  // |> map.insert(3, day_3.run)
}

pub fn main() {
  let runners = runners()

  let commands =
    cli.new()
    |> run.register_command(runners)
    |> cli.add_command(["new"], new.run, [])

  cli.run(commands, args())
}
