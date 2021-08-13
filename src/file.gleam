import gleam/atom.{Atom}
import charlist.{Charlist}

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

pub external fn write_file(IODevice, Charlist) -> WriteResult =
  "file" "write"
