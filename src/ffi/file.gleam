import gleam/erlang/file.{Reason}

pub external type IODevice

pub external fn open_file_exclusive(s: String) -> Result(IODevice, Reason) =
  "gladvent_ffi" "open_file_exclusive"

external fn do_write(IODevice, String) -> Result(Nil, Reason) =
  "gladvent_ffi" "write"

pub fn write(iod: IODevice, s: String) -> Result(Nil, Reason) {
  do_write(iod, s)
}
