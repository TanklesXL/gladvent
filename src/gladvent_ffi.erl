-module(gladvent_ffi).

-export([
    find_files/2,
    get_run/1,
    open_file_exclusive/1,
    write/2,
    ensure_dir/1,
    function_arity_one_exists/2,
    module_exists/1
]).

find_files(Pattern, In) ->
    Results = filelib:wildcard(binary_to_list(Pattern), binary_to_list(In)),
    lists:map(fun list_to_binary/1, Results).

get_run(A) ->
    {fun A:pt_1/1, fun A:pt_2/1}.

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

module_exists(ModuleName) ->
    case code:ensure_loaded(ModuleName) of
        {module, _} ->
            true;
        {error, _} ->
            false
    end.

function_arity_one_exists(ModuleName, Fn) ->
    case erlang:function_exported(ModuleName, Fn, 1) of
        true ->
            {ok, fun ModuleName:Fn/1};
        false ->
            {error, nil}
    end.
