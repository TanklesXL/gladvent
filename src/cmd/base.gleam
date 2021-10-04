import snag.{Result}

pub type Exec(a) {
  Exec(do: fn(Int) -> Result(a), collect: fn(#(Result(a), Int)) -> String)
}
