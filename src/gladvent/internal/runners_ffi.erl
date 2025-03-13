-module(runners_ffi).

-export([
    function_arity_one/2,
    parse_function/1
]).

function_arity_one(ModuleName, Fn) ->
    fun ModuleName:Fn/1.

parse_function(ModuleName) ->
    function_arity_one(ModuleName, parse).
