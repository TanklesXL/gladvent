import simplifile.{type FileError}
import gleam/result
import gladvent/internal/util.{defer}

pub type IODevice

@external(erlang, "gladvent_ffi", "open_file_exclusive")
pub fn open_file_exclusive(s: String) -> Result(IODevice, FileError)

@external(erlang, "gladvent_ffi", "write")
fn do_write(a: IODevice, b: String) -> Result(Nil, FileError)

pub fn write(iod: IODevice, s: String) -> Result(Nil, FileError) {
  do_write(iod, s)
}

@external(erlang, "gladvent_ffi", "close_iodevice")
fn close_iodevice(a: IODevice) -> Result(Nil, FileError)

pub fn do_with_file(
  filename: String,
  f: fn(IODevice) -> a,
) -> Result(a, FileError) {
  use file <- result.map(open_file_exclusive(filename))
  use <- defer(do: fn() {
    let assert Ok(Nil) = close_iodevice(file)
  })
  f(file)
}
