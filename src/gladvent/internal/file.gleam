import gleam/erlang/file.{Reason}
import gleam/result

pub external type IODevice

pub external fn open_file_exclusive(s: String) -> Result(IODevice, Reason) =
  "gladvent_ffi" "open_file_exclusive"

external fn do_write(IODevice, String) -> Result(Nil, Reason) =
  "gladvent_ffi" "write"

pub fn write(iod: IODevice, s: String) -> Result(Nil, Reason) {
  do_write(iod, s)
}

external fn close_iodevice(IODevice) -> Result(Nil, Reason) =
  "gladvent_ffi" "close_iodevice"

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
