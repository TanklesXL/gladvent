import filepath
import gladvent/internal/cmd
import gleam/int

pub type Kind {
  Example
  Puzzle
}

pub fn get_file_path(year: Int, day: Int, input_kind: Kind) -> String {
  filepath.join(dir(year), int.to_string(day))
  <> case input_kind {
    Example -> ".example.txt"
    Puzzle -> ".txt"
  }
}

pub fn root() {
  filepath.join(cmd.root(), "input")
}

pub fn dir(year) {
  filepath.join(root(), int.to_string(year))
}
