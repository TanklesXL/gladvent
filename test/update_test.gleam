import gladvent/internal/cmd/update.{update_path}

import gleam/option.{None, Some}
import gleeunit/should

pub fn upgrade_path_input_file_day_1_test() {
  update_path("input/2024/1.txt")
  |> should.equal(Some("input/2024/01.txt"))
}
