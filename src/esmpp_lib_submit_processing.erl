-module(esmpp_lib_submit_processing).
-author('Alexander Zhuk <aleksandr.zhuk@privatbank.ua>').

-behaviour(gen_server).

-include("esmpp_lib.hrl").

-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/1]).
-export([delete_submit/2]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(State) ->
    gen_server:start_link(?MODULE, State, []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(State) ->
    WorkerPid = self(),
    SubmitTimeout = get_timeout(submit_timeout, State),
    TRef = erlang:send_after(60000, WorkerPid, {exam_submit, SubmitTimeout}),
    {ok, [{submit_check, []}, {worker_pid, WorkerPid}, {submit_tref, TRef}|State]}.

handle_call(Request, _From, State) ->
    ?LOG_ERROR("Unknown call request ~p~n", [Request]),
    {reply, ok, State}.
handle_cast(Msg, State) ->
    ?LOG_ERROR("Unknown cast msg ~p~n", [Msg]),
    {noreply, State}.

handle_info({processing_submit, Handler, List, 
                                SeqNum, OperationHandler, Status}, State) ->
    WorkerPid = proplists:get_value(worker_pid, State),
    ok = submit_handler(Handler, WorkerPid, List, SeqNum, OperationHandler, Status, State), 
    {noreply, State}; 
handle_info({update_state, {add_submit, Value}}, State) ->
    ListSubmit = proplists:get_value(submit_check, State),
    State1 = lists:keyreplace(submit_check, 1, State, {submit_check, [Value|ListSubmit]}),
    {noreply, State1};
handle_info({exam_submit, SubmitTimeout}, State) ->
    OldTRef = proplists:get_value(submit_tref, State),
    _ = erlang:cancel_timer(OldTRef),
    ListSubmit = proplists:get_value(submit_check, State),
    TsNow = os:timestamp(),
    ok = exam_submit(SubmitTimeout, TsNow, State, ListSubmit, []),
    WorkerPid = proplists:get_value(worker_pid, State),
    NewTRef = erlang:send_after(60000, WorkerPid, {exam_submit, SubmitTimeout}),
    State1 = lists:keyreplace(submit_tref, 1, State, {submit_tref, NewTRef}),
    {noreply, State1};
handle_info({update_state, {submit_check, Acc}}, State) ->
    State1 = lists:keyreplace(submit_check, 1, State, {submit_check, Acc}),
    {noreply, State1};
handle_info({update_state, {delete_submit, SeqNum}}, State) ->
    ListSubmit = proplists:delete(SeqNum, proplists:get_value(submit_check, State)),
    State1 = lists:keyreplace(submit_check, 1, State, {submit_check, ListSubmit}),
    {noreply, State1};
handle_info(Info, State) ->
    ?LOG_ERROR("Unknown info msg ~p~n", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

submit_handler(Handler, WorkerPid, List, SeqNum, OperationHandler, Status, State) ->
    ListSubmit = proplists:get_value(submit_check, State),
    case is_tuple(proplists:get_value(SeqNum, ListSubmit)) of
        true ->
            ok = Handler:OperationHandler(WorkerPid, [{sequence_number, SeqNum},
                        {command_status, Status}|List]),
            _ = spawn(?MODULE, delete_submit, [WorkerPid, SeqNum]),
            ok;
        false ->
            ok = Handler:submit_error(WorkerPid, SeqNum)                               
    end.  

exam_submit(_Timeout, _TsNow, State, [], Acc) ->
    WorkerPid = proplists:get_value(worker_pid, State),
    WorkerPid ! {update_state, {submit_check, Acc}},
    ok;
exam_submit(Timeout, TsNow, State, [H|T], Acc) ->
    WorkerPid = proplists:get_value(worker_pid, State),
    Handler = proplists:get_value(handler, State),
    {Key, {Handler, TsOld, _Socket}} = H,
    Acc1 = case timer:now_diff(TsNow, TsOld) > Timeout*1000000 of
        true ->
            ok = Handler:submit_error(WorkerPid, Key),
            Acc;
        false ->
            [H|Acc]
    end,
    exam_submit(Timeout, TsNow, State, T, Acc1).

delete_submit(WorkerPid, SeqNum) ->
    ok = timer:sleep(2000),
    WorkerPid ! {update_state, {delete_submit, SeqNum}}.

get_timeout(Key, Param) ->
    Value = proplists:get_value(Key, Param),
    case is_integer(Value) of 
        true ->
            Value;
        false ->
            39
    end.
