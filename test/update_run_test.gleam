import gleeunit/should

import gladvent/internal/cmd/update

pub fn legacy_warning_message_test() {
  update.legacy_warning_message()
  |> should.equal(
    "*** Legacy files detected. Run 'gleam run update' for more information. ***",
  )
}
