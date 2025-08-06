-module(runners_ffi).

-export([function_arity_one/2, parse_function/1, rescue/1, identity/1]).

identity(X) ->
    X.

function_arity_one(ModuleName, Fn) ->
    fun ModuleName:Fn/1.

parse_function(ModuleName) ->
    function_arity_one(ModuleName, parse).

rescue(F) ->
    try
        {ok, F()}
    catch
        X ->
            {error, {thrown, X}};
        error:X ->
            {error, {errored, X}};
        exit:X ->
            {error, {exited, X}}
    end.
