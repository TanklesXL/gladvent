import gleam/erlang/charlist.{Charlist}
import gleam/erlang/file.{Reason}

pub external type IODevice

pub external fn open_file_exclusive(s: String) -> Result(IODevice, Reason) =
  "gladvent_ffi" "open_file_exclusive"

external fn do_write(IODevice, Charlist) -> Result(Nil, Reason) =
  "gladvent_ffi" "write"

external fn do_ensure_dir(Charlist) -> Result(Nil, Reason) =
  "gladvent_ffi" "ensure_dir"

pub fn write(iod: IODevice, s: String) -> Result(Nil, Reason) {
  do_write(iod, charlist.from_string(s))
}

pub fn ensure_dir(dir: String) -> Result(Nil, Reason) {
  do_ensure_dir(charlist.from_string(dir))
}
