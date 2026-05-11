-module(bpe_ticket_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("bpe/include/bpe.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1, ticket_test/1]).

all() -> [ticket_test].

init_per_suite(Config) ->
    application:ensure_all_started(syn),
    application:ensure_all_started(bpe),
    Config.

end_per_suite(_Config) ->
    application:stop(bpe),
    ok.

ticket_test(_Config) ->
    {ok, Id} = bpe:start(bpe_ticket:def(), []),
    {complete, "Assign"} = bpe:next(Id),
    {complete, "Work"} = bpe:next(Id),
    bpe:amend(Id, {sla_violation, true}),
    {complete, "Closed"} = bpe:next(Id),
    'Final' = bpe:next(Id),
    ok.
