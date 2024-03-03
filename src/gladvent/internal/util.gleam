pub fn defer(do later: fn() -> _, after now: fn() -> a) -> a {
  let res = now()
  later()
  res
}
