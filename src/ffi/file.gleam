import gleam/erlang/charlist.{Charlist}
import gleam

pub type Reason {
  Enoent
  Eaccess
  Eisdir
  Enotdir
  Enospc
  Eexist
}

pub external type IODevice

pub type FileMode {
  Read
  Write
  Append
  Exclusive
}

pub external fn read_file(String) -> Result(String, Reason) =
  "file" "read_file"

pub external fn open_file(String, List(FileMode)) -> Result(IODevice, Reason) =
  "file" "open"

pub fn open_file_exclusive(s: String) -> Result(IODevice, Reason) {
  open_file(s, [Exclusive])
}

external fn write(IODevice, Charlist) -> WriteResult =
  "file" "write"

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

pub fn open_and_write_exclusive(
  path: String,
  contents: String,
) -> Result(Nil, Reason) {
  try iod = open_file_exclusive(path)
  write_file(iod, contents)
}
