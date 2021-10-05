import parse.{Day}
import snag.{Result}

pub type Exec(a) {
  Exec(do: fn(Day) -> Result(a), collect: fn(#(Result(a), Day)) -> String)
}
