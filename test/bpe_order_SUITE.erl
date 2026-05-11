-module(bpe_order_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("bpe/include/bpe.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1, order_test/1]).

all() -> [order_test].

init_per_suite(Config) ->
    application:ensure_all_started(syn),
    application:ensure_all_started(bpe),
    Config.

end_per_suite(_Config) ->
    application:stop(bpe),
    ok.

order_test(_Config) ->
    {ok, Id} = bpe:start(bpe_order:def(), []),
    {complete, "CartActive"} = bpe:next(Id),
    {complete, "Checkout"} = bpe:next(Id),
    bpe:amend(Id, {payment_received, "tx_12345"}),
    {complete, "Fulfilment"} = bpe:next(Id),
    {complete, "PostPurchase"} = bpe:next(Id),
    {complete, "Delivered"} = bpe:next(Id),
    'Final' = bpe:next(Id),
    ok.
