-module(bpe_order).
-include_lib("bpe/include/bpe.hrl").
-export([def/0, auth/1, action/2]).

auth(_) -> true.

def() ->
    P = #process{
      name = "E-Commerce Order",
      module = ?MODULE,
      flows = [
        #sequenceFlow{id = "->CartActive", source = "CartCreated", target = "CartActive"},
        #sequenceFlow{id = "CartActive->Checkout", source = "CartActive", target = "Checkout"},
        #sequenceFlow{id = "AbandonedRecovery->CartActive", source = "AbandonedRecovery", target = "CartActive"},
        #sequenceFlow{id = "Checkout->Payment", source = "Checkout", target = "Payment"},
        #sequenceFlow{id = "Payment->Fulfilment", source = "Payment", target = "Fulfilment"},
        #sequenceFlow{id = "Fulfilment->PostPurchase", source = "Fulfilment", target = "PostPurchase"},
        #sequenceFlow{id = "PostPurchase->Delivered", source = "PostPurchase", target = "Delivered"}
      ],
      tasks = [
        #beginEvent{id = "CartCreated"},
        #userTask{id = "CartActive"},
        #serviceTask{id = "AbandonedRecovery"},
        #userTask{id = "Checkout"},
        #serviceTask{id = "Payment"},
        #serviceTask{id = "Fulfilment"},
        #serviceTask{id = "PostPurchase"},
        #endEvent{id = "Delivered"}
      ],
      beginEvent = "CartCreated",
      endEvent = "Delivered",
      events = [
        #messageEvent{id = "PaymentReceived"},
        #messageEvent{id = "ShipmentUpdate"},
        #boundaryEvent{id = '*', timeout = #timeout{spec = {0, {1, 0, 0}}}}
      ]
    },
    P#process{tasks = bpe_xml:fillInOut(P#process.tasks, P#process.flows)}.

action({request, "CartCreated", _}, Proc) -> #result{state = Proc};
action({request, "CartActive", _}, Proc) -> #result{state = Proc};
action({request, "AbandonedRecovery", _}, Proc) ->
    #result{
       type = reply,
       reply = "CartActive",
       state = Proc#process{docs = [{abandoned_recovery_sent, true}]}
    };
action({request, "Checkout", _}, Proc) -> #result{state = Proc};
action({request, "Payment", _}, Proc) ->
    case bpe:doc({payment_received}, Proc) of
        [] -> #result{type = reply, reply = "Payment", state = Proc};
        _ -> #result{type = reply, reply = {complete, "Fulfilment"}, state = Proc#process{docs = [{tx, paid}]}}
    end;
action({request, "Fulfilment", _}, Proc) -> #result{state = Proc};
action({request, "PostPurchase", _}, Proc) ->
    #result{state = Proc#process{docs = [{post_purchase_sent, true}]}};
action({request, "Delivered", _}, Proc) -> #result{type = stop, state = Proc}.
