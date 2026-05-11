-module(bpe_ticket).
-include_lib("bpe/include/bpe.hrl").
-export([def/0, auth/1, action/2]).

auth(_) -> true.

def() ->
    P = #process{
      name = "Support Ticket",
      module = ?MODULE,
      flows = [
        #sequenceFlow{id = "->Assign", source = "Create", target = "Assign"},
        #sequenceFlow{id = "Assign->Work", source = "Assign", target = "Work"},
        #sequenceFlow{id = "Work->Resolve", source = "Work", target = "Resolve"},
        #sequenceFlow{id = "Resolve->Closed", source = "Resolve", target = "Closed"},
        #sequenceFlow{id = "Escalate->Work", source = "Escalate", target = "Work"}
      ],
      tasks = [
        #beginEvent{id = "Create"},
        #userTask{id = "Assign"},
        #userTask{id = "Work"},
        #serviceTask{id = "Escalate"},
        #userTask{id = "Resolve"},
        #endEvent{id = "Closed"}
      ],
      beginEvent = "Create",
      endEvent = "Closed",
      events = [
        #messageEvent{id = "TicketUpdate"},
        #boundaryEvent{id = '*', timeout = #timeout{spec = {0, {24, 0, 0}}}}
      ]
    },
    P#process{tasks = bpe_xml:fillInOut(P#process.tasks, P#process.flows)}.

action({request, "Create", _}, Proc) -> #result{state = Proc};
action({request, "Assign", _}, Proc) -> #result{state = Proc};
action({request, "Work", _}, Proc) -> #result{state = Proc};
action({request, "Escalate", _}, Proc) ->
    #result{type = reply, reply = "Work", state = Proc#process{docs = [{escalated, true}]}};
action({request, "Resolve", _}, Proc) -> #result{state = Proc};
action({request, "Closed", _}, Proc) -> #result{type = stop, state = Proc}.
