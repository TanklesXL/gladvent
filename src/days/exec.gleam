import snag.{Result}

pub fn exec(
  input: String,
  pt_1: fn(String) -> Result(Int),
  pt_2: fn(String) -> Result(Int),
) -> Result(#(Int, Int)) {
  try pt_1 =
    input
    |> pt_1()
    |> snag.context("failed part 1")

  try pt_2 =
    input
    |> pt_2()
    |> snag.context("failed part 2")

  Ok(#(pt_1, pt_2))
}
