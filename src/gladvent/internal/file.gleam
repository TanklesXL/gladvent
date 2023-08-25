import gleam/erlang/file.{Reason}
import gleam/result

pub type IODevice

@external(erlang, "gladvent_ffi", "open_file_exclusive")
pub fn open_file_exclusive(s s: String) -> Result(IODevice, Reason)

@external(erlang, "gladvent_ffi", "write")
fn do_write(a: IODevice, b: String) -> Result(Nil, Reason)

pub fn write(iod: IODevice, s: String) -> Result(Nil, Reason) {
  do_write(iod, s)
}

@external(erlang, "gladvent_ffi", "close_iodevice")
fn close_iodevice(a: IODevice) -> Result(Nil, Reason)

pub fn do_with_file(filename: String, f: fn(IODevice) -> a) -> Result(a, Reason) {
  use file <- result.map(open_file_exclusive(filename))
  use <- defer(do: fn() {
    let assert Ok(Nil) = close_iodevice(file)
  })
  f(file)
}

fn defer(do later: fn() -> _, after now: fn() -> a) -> a {
  let res = now()
  later()
  res
}
