pub external type Charlist

pub external fn to_string(Charlist) -> String =
  "erlang" "list_to_binary"

pub external fn from_string(String) -> Charlist =
  "erlang" "binary_to_list"
