import gleam/atom.{Atom}

pub external type Charlist

pub external fn charlist_to_string(Charlist) -> String =
  "erlang" "list_to_binary"

pub external fn charlist_from_string(String) -> Charlist =
  "erlang" "binary_to_list"

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
