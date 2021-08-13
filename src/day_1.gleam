import gleam/result
import gleam/string

pub fn run(input: String) -> Result(#(Int, Int), String) {
  try pt_1 =
    pt_1(input)
    |> result.map_error(string.append("failed part 1: ", _))

  try pt_2 =
    pt_2(input)
    |> result.map_error(string.append("failed part 2: ", _))

  Ok(#(pt_1, pt_2))
}

fn pt_1(input: String) -> Result(Int, String) {
  todo
}

fn pt_2(input: String) -> Result(Int, String) {
  todo
}
