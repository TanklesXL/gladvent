import snag.{Result}
import gleam/int
import gleam/string
import gleam/result

pub fn int(s: String) -> Result(Int) {
  s
  |> int.parse()
  |> result.replace_error(
    ["failed to parse \"", s, "\" as int"]
    |> string.concat()
    |> snag.new(),
  )
}
