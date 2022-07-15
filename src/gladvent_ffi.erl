-module(gladvent_ffi).

-export([find_files/2, get_run/1, open_file_exclusive/1, write/2, ensure_dir/1, do_run/2]).

find_files(Pattern, In) ->
    Results = filelib:wildcard(binary_to_list(Pattern), binary_to_list(In)),
    lists:map(fun list_to_binary/1, Results).

get_run(A) ->
        {fun A:pt_1/1,fun A:pt_2/1}.

do_run(Run, Input) ->
    try
        {ok, Run(Input)}
    catch
        _:undef -> {error, undef};
        _ -> {error, run_failed}
    end.

open_file_exclusive(File) ->
    file:open(File, [exclusive]).

to_gleam_result(Res) ->
    case Res of
        ok -> {ok, nil};
        Err -> Err
    end.

write(IODevice, Charlist) ->
    to_gleam_result(file:write(IODevice, Charlist)).

ensure_dir(Dir) ->
    to_gleam_result(filelib:ensure_dir(Dir)).
