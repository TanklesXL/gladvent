import filepath
import gladvent/internal/cmd
import gleam/int

pub type Kind {
  Example
  Puzzle
}

pub fn get_file_path(year: Int, day: Int, input_kind: Kind) -> String {
  filepath.join(dir(year), int.to_string(day)) <> get_extension(input_kind)
}

pub fn root() {
  filepath.join(cmd.root(), "input")
}

pub fn dir(year) {
  filepath.join(root(), int.to_string(year))
}

fn get_extension(input_kind: Kind) -> String {
  case input_kind {
    Example -> ".example.txt"
    Puzzle -> ".txt"
  }
}
