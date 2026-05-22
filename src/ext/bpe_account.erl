-module(bpe_account).
-include("bpe.hrl").
-include("doc.hrl").
-export([def/0,auth/1,action/2,check_signatory/1,check_payment/1]).
-export([check_process/1, check_process_loop/1, check_process_final/1]).
-export([check_signatory_process/1, check_signatory_final/1]).

auth(_) -> true.

% PROCESS DEFINITION

def() ->
  P =  #process { name = "IBAN Account",
        module = ?MODULE,
        flows = [
            #sequenceFlow { id="->Init", source="Created", target="Init"},
            #sequenceFlow { id="->Upload", source="Init", target="Upload"},
            #sequenceFlow { id="->Payment", source="Upload", target="Payment"},
            #sequenceFlow { id="Payment->Signatory", source="Payment", target="Signatory", condition={service, check_signatory}},
            #sequenceFlow { id="Payment->Process", source="Payment", target="Process", condition={service, check_process}},
            #sequenceFlow { id="Payment-loop", source="Payment", target="Payment", condition={service, check_payment}},
            #sequenceFlow { id="Process-loop", source="Process", target="Process", condition={service, check_process_loop}},
            #sequenceFlow { id="Process->Final", source="Process", target="Final", condition={service, check_process_final}},
            #sequenceFlow { id="Signatory->Process", source="Signatory", target="Process", condition={service, check_signatory_process}},
            #sequenceFlow { id="Signatory->Final", source="Signatory", target="Final", condition={service, check_signatory_final}} ],
        tasks = [
            #beginEvent { id="Created" },
            #userTask { id="Init" },
            #userTask { id="Upload" },
            #userTask { id="Signatory" },
            #serviceTask { id="Payment" },
            #serviceTask { id="Process" },
            #endEvent { id="Final" } ],
        beginEvent = "Created",
        endEvent = "Final",
        events = [ #messageEvent{id="PaymentReceived"},
                   #boundaryEvent{id='*', timeout=#timeout{spec={0, {10, 0, 10}}}} ] },

   P#process{tasks = bpe_xml:fillInOut(P#process.tasks,P#process.flows)}.

% PROCESS LOGIC

action({request,"Created",_}, Proc) ->
    #result{type=reply,state=Proc};

action({request,"Init",_}, Proc) ->
    #result{type=reply,state=Proc};

action({request,"Payment",_X}, Proc) ->
    Payment = bpe:doc({payment_notification},Proc),
    io:format("Payment: ~p",[Payment]),
    case Payment of
         [] -> #result{type=reply,reply="Payment",state=Proc};
          _ -> #result{type=reply,reply="Process",state=Proc} end;

action({request,"Signatory",_}, Proc) ->
    #result{type=reply,reply="Process",state=Proc};

action({request,"Process",X}, Proc) ->
    io:format("Process: ~p",[X]),
    io:format("Process Docs: ~p",[bpe:doc(#close_account{id=[]},Proc)]),
    case check_process_final(Proc) of
         false -> #result{type=reply,reply="Process",state=Proc#process{docs=[#tx{}|Proc#process.docs]}};
         true -> #result{type=reply,reply="Final",state=Proc} end;

action({request,"Upload",_}, Proc) -> #result{type=reply,state=Proc};

action({request,"Final",_}, Proc) -> #result{type=stop,state=Proc}.

% ABAC CONTROL

check_signatory(Proc) -> bpe:doc({payment_notification}, Proc) /= [].
check_payment(Proc) -> bpe:doc({payment_notification}, Proc) == [].
check_process(_Proc) -> false.
check_signatory_process(_Proc) -> true.
check_signatory_final(_Proc) -> false.
check_process_loop(Proc) -> bpe:doc(#close_account{}, Proc) == [].
check_process_final(Proc) ->
    case bpe:doc(#close_account{id=[]},Proc) of
         [] -> false;
        [#close_account{id=_}] -> true end.
