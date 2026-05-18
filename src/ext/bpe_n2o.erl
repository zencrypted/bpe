-module(bpe_n2o).
-include_lib("bpe/include/bpe.hrl").
-include_lib("bpe/include/doc.hrl").
-record('Token', {data= [] :: binary()}).
-record(io, {code= [] :: term(),data = [] :: [] | #'Token'{} | #process{} | #io{} | term() }).
-export([info/3, to_atom/1]).

info(#'Amen'{id=Proc,docs=Docs},R,S) -> {reply,{bert,#io{data=bpe:amend(binary_to_list(Proc),Docs)}},R,S};
info(#'Hist'{id=Proc},R,S) -> {reply,{bert,#io{data=bpe:hist(binary_to_list(Proc))}},  R,S};
info(#'Proc'{id=Proc},R,S) -> {reply,{bert,#io{data=bpe:proc(binary_to_list(Proc))}},  R,S};
info(#'Load'{id=Proc},R,S) -> {reply,{bert,#io{data=bpe:load(binary_to_list(Proc))}},  R,S};
info(#'Next'{id=Proc},R,S) -> {reply,{bert,#io{data=bpe:next(binary_to_list(Proc))}},  R,S};
info(#'Make'{proc=M,docs=Docs},R,S) ->
  Proc = case M of
    #process{} -> M;
    _ -> (to_atom(M)):def()
  end,
  {reply,{bert,#io{data=bpe:start(Proc,Docs)}},R,S};
info(M,R,S) -> {unknown,M,R,S}.

-spec to_atom(atom() | binary() | list()) -> atom().
to_atom(A) when is_atom(A) -> A;
to_atom(B) when is_binary(B) -> binary_to_atom(B, utf8);
to_atom(L) when is_list(L) -> list_to_atom(L).
