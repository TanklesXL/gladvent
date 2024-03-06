-module(gladvent_ffi).

-export([
    find_files/2,
    open_file_exclusive/1,
    write/2,
    ensure_dir/1,
    function_arity_one/2,
    parse_function/1,
    close_iodevice/1
]).

close_iodevice(IoDevice) ->
    to_gleam_result(file:close(IoDevice)).

find_files(Pattern, In) ->
    Results = filelib:wildcard(binary_to_list(Pattern), binary_to_list(In)),
    lists:map(fun list_to_binary/1, Results).

open_file_exclusive(File) ->
    file:open(File, [exclusive]).

to_gleam_result(Res) ->
    case Res of
        ok -> {ok, nil};
        Other -> Other
    end.

write(IODevice, Contents) ->
    to_gleam_result(file:write(IODevice, Contents)).

ensure_dir(Dir) ->
    to_gleam_result(filelib:ensure_dir(Dir)).

function_arity_one(ModuleName, Fn)-> fun ModuleName:Fn/1.

parse_function(ModuleName)-> function_arity_one(ModuleName, parse).
