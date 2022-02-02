-module(run_ffi).

-export([find_files/2, get_run/1]).

find_files(Pattern, In) ->
    Results = filelib:wildcard(binary_to_list(Pattern), binary_to_list(In)),
    lists:map(fun list_to_binary/1, Results).

get_run(A) ->
    fun A:run/1.
