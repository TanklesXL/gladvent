import gleam/erlang/charlist.{Charlist}
import gleam

pub external type Reason

pub external type IODevice

pub external fn read_file(String) -> Result(String, Reason) =
  "file" "read_file"

pub type FileMode {
  Write
}

pub external fn open_file(String, FileMode) -> Result(IODevice, Reason) =
  "file" "open"

pub type WriteResult {
  Ok
  Error(Reason)
}

external fn write(IODevice, Charlist) -> WriteResult =
  "file" "write"

pub fn write_file(iod: IODevice, s: String) -> Result(Nil, Reason) {
  case write(iod, charlist.from_string(s)) {
    Ok -> gleam.Ok(Nil)
    Error(reason) -> gleam.Error(reason)
  }
}
