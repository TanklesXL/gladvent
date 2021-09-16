import gleam/erlang/charlist.{Charlist}
import gleam

pub external type Reason

pub external type IODevice

pub external fn read_file(String) -> Result(String, Reason) =
  "file" "read_file"

external fn open(String, FileMode) -> Result(IODevice, Reason) =
  "file" "open"

external fn write(IODevice, Charlist) -> WriteResult =
  "file" "write"

type FileMode {
  Write
}

pub fn open_file(path: String) -> Result(IODevice, Reason) {
  open(path, Write)
}

type WriteResult {
  Ok
  Error(Reason)
}

pub fn write_file(iod: IODevice, s: String) -> Result(Nil, Reason) {
  case write(iod, charlist.from_string(s)) {
    Ok -> gleam.Ok(Nil)
    Error(reason) -> gleam.Error(reason)
  }
}

pub fn open_and_write(path: String, contents: String) -> Result(Nil, Reason) {
  try iod = open_file(path)
  write_file(iod, contents)
}
