-module(bpe_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("bpe/include/bpe.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([service_test/1, sample_test/1, compare_test/1, nsinfo_test/1]).
-export([auth/1, action/2, dir_right/1, dir_left/1]).

all() -> [service_test, sample_test, compare_test, nsinfo_test].

init_per_suite(Config) ->
    application:ensure_all_started(bpe),
    Config.

end_per_suite(_Config) ->
    application:stop(bpe),
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.

auth(_) -> true.
action({request, _Source, _Target}, Proc) -> #result{state=Proc}.

dir_right(Proc) -> [{direction, right}] == bpe:doc({direction}, Proc).
dir_left(Proc) -> [{direction, left}] == bpe:doc({direction}, Proc).

service_test(_Config) ->
    PrivDir = code:priv_dir(bpe),
    File = filename:join(PrivDir, "service.bpmn"),
    Def = bpe_xml:load(File, ?MODULE),
    
    % Test 0
    {ok, Pid0} = bpe:start(Def, []),
    {complete, "some"} = bpe:next(Pid0),
    'Final' = bpe:next(Pid0),

    % Test 1
    {ok, Pid1} = bpe:start(Def, []),
    {complete, "some"} = bpe:amend(Pid1, [{direction, right}]),
    {complete, "right"} = bpe:next(Pid1),
    {complete, "any"} = bpe:next(Pid1),
    {complete, "epilog"} = bpe:next(Pid1),
    {complete, "finish"} = bpe:next(Pid1),
    'Final' = bpe:next(Pid1),

    % Test 2
    {ok, Pid2} = bpe:start(Def, []),
    {complete, "some"} = bpe:amend(Pid2, [{direction, left}]),
    {complete, "left"} = bpe:next(Pid2),
    {complete, "any"} = bpe:next(Pid2),
    {complete, "epilog"} = bpe:next(Pid2),
    {complete, "finish"} = bpe:next(Pid2),
    'Final' = bpe:next(Pid2),
    ok.

sample_test(_Config) ->
    PrivDir = code:priv_dir(bpe),
    File = filename:join(PrivDir, "sample.bpmn"),
    Def = bpe_xml:load(File, ?MODULE),
    
    {ok, Pid} = bpe:start(Def, []),
    {complete, "either"} = bpe:next(Pid),
    {complete, "left"} = bpe:next(Pid, "x2"),
    {complete, "right"} = bpe:next(Pid, "x3"),
    {complete, "join"} = bpe:next(Pid, "x5"),
    {error, _, _} = bpe:next(Pid, "x6"),
    {complete, "join"} = bpe:next(Pid, "x4"),
    {complete, "epilog"} = bpe:next(Pid),
    {complete, "finish"} = bpe:next(Pid),
    'Final' = bpe:next(Pid),
    ok.

compare_test(_Config) ->
    PrivDir = code:priv_dir(bpe),
    File = filename:join(PrivDir, "compare.bpmn"),
    Def = bpe_xml:load(File, ?MODULE),
    
    % Test 0
    {ok, Pid0} = bpe:start(Def, []),
    {complete, "some"} = bpe:next(Pid0),
    {complete, "default"} = bpe:next(Pid0),
    {complete, "any"} = bpe:next(Pid0),
    {complete, "epilog"} = bpe:next(Pid0),
    {complete, "finish"} = bpe:next(Pid0),
    'Final' = bpe:next(Pid0),

    % Test 1
    {ok, Pid1} = bpe:start(Def, []),
    {complete, "some"} = bpe:amend(Pid1, [{direction, right}]),
    {complete, "right"} = bpe:next(Pid1),
    {complete, "any"} = bpe:next(Pid1),
    {complete, "epilog"} = bpe:next(Pid1),
    {complete, "finish"} = bpe:next(Pid1),
    'Final' = bpe:next(Pid1),

    % Test 2
    {ok, Pid2} = bpe:start(Def, []),
    {complete, "some"} = bpe:amend(Pid2, [{direction, left}]),
    {complete, "left"} = bpe:next(Pid2),
    {complete, "any"} = bpe:next(Pid2),
    {complete, "epilog"} = bpe:next(Pid2),
    {complete, "finish"} = bpe:next(Pid2),
    'Final' = bpe:next(Pid2),
    ok.

nsinfo_test(_Config) ->
    PrivDir = code:priv_dir(bpe),
    File = filename:join(PrivDir, "exgate1.bpmn"),
    _Def = bpe_xml:load(File, ?MODULE),
    ok.
