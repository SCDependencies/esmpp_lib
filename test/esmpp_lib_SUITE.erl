%% common_test suite for esmpp_lib

-module(esmpp_lib_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, suite/0, groups/0]).
-export([init_per_suite/1, end_per_suite/1, init_per_group/2, 
            end_per_group/2, init_per_testcase/2, end_per_testcase/2]).
-export([submit_cyrillic_short/1, submit_cyrillic_long/1, 
        submit_latin_long/1, submit_latin_short/1,
        submit_symbols/1, unbind/1]).


-define(current_function_name(), element(2, element(2, process_info(self(), current_function)))).

suite() -> [{timetrap, {seconds, 20}}].

groups() -> [].

all() -> [submit_cyrillic_short, submit_cyrillic_long,
          submit_latin_long, submit_latin_short,
          submit_symbols, unbind].

%% ct:run_test([{spec, "test/test.spec"}]).

init_per_suite(Config) ->

  ok = ct:pal("~p", [?current_function_name()]),

%%    ok = application:start(asn1),
%%    ok = application:start(crypto),
%%    ok = application:start(public_key),
%%    ok = application:start(ssl),
    ok = application:start(compiler),
    ok = application:start(syntax_tools),
    ok = application:start(goldrush),
    ok = application:start(lager),
    ConnectOptions = [{host, {127,0,0,1}}, {port, 2775}, {password, <<"password">>}, 
                    {system_id, <<"smppclient1">>}, {mode, transceiver}, 
                    {interface_version, "3.4"}, {enquire_timeout, 30}, 
                    {submit_timeout, 60}, {system_type, ""}, {service_type, ""}, 
                    {addr_ton, 5}, {addr_npi, 0}, {source_addr, <<"380920003100">>}, 
                    {source_addr_ton, 5}, {source_addr_npi, 0}, {dest_addr_ton, 1}, 
                    {dest_addr_npi, 1}, {handler, my_sms}],
    SubmitOptions = [{source_addr, <<"test">>}, {dest_addr, <<"380667833873">>}], 
    {ok, Pid} = esmpp_lib_worker:start_link(ConnectOptions),
    ok = ct:pal("Connect OK ~n", []),
    [{connect_options, ConnectOptions}, {submit_options, SubmitOptions}, {pid, Pid}|Config].

%%--------------------------------------------------------------------
%% Function: end_per_suite(Config0) -> void() | {save_config,Config1}
%%
%% Config0 = Config1 = [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%%
%% Description: Cleanup after the suite.
%%--------------------------------------------------------------------
end_per_suite(Config) ->
    ok = ct:pal("~p", [?current_function_name()]),
    ConnectOptions = ?config(connect_options, Config),
    ok = esmpp_lib_worker:terminate(end_tests, ConnectOptions),
%%    ok = application:stop(ssl),
    ok = application:stop(lager),
    ok = application:stop(goldrush),
    ok = application:stop(syntax_tools),
    ok = application:stop(compiler),
    ok = ct:pal("stop success", []).

%%--------------------------------------------------------------------
%% Function: init_per_group(GroupName, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%%
%% GroupName = atom()
%%   Name of the test case group that is about to run.
%% Config0 = Config1 = [tuple()]
%%   A list of key/value pairs, holding configuration data for the group.
%% Reason = term()
%%   The reason for skipping all test cases and subgroups in the group.
%%
%% Description: Initialization before each test case group.
%%--------------------------------------------------------------------
init_per_group(_group, Config) ->
    Config.

%%--------------------------------------------------------------------
%% Function: end_per_group(GroupName, Config0) ->
%%               void() | {save_config,Config1}
%%
%% GroupName = atom()
%%   Name of the test case group that is finished.
%% Config0 = Config1 = [tuple()]
%%   A list of key/value pairs, holding configuration data for the group.
%%
%% Description: Cleanup after each test case group.
%%--------------------------------------------------------------------
end_per_group(_group, Config) ->
    Config.

%%--------------------------------------------------------------------
%% Function: init_per_testcase(TestCase, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%%
%% TestCase = atom()
%%   Name of the test case that is about to run.
%% Config0 = Config1 = [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%% Reason = term()
%%   The reason for skipping the test case.
%%
%% Description: Initialization before each test case.
%%
%% Note: This function is free to add any key/value pairs to the Config
%% variable, but should NOT alter/remove any existing entries.
%%--------------------------------------------------------------------
init_per_testcase(_TestCase, Config) ->
    Config.

%%--------------------------------------------------------------------
%% Function: end_per_testcase(TestCase, Config0) ->
%%               void() | {save_config,Config1} | {fail,Reason}
%%
%% TestCase = atom()
%%   Name of the test case that is finished.
%% Config0 = Config1 = [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%% Reason = term()
%%   The reason for failing the test case.
%%
%% Description: Cleanup after each test case.
%%--------------------------------------------------------------------

end_per_testcase(_TestCase, Config) ->
    Config.

submit_cyrillic_short(Config) ->
    Pid = ?config(pid, Config),
    SubmitOptions = ?config(submit_options, Config), 
    Text = {text, <<"відносно маленький, майже прямий, розташовано поперек голови."/utf8>>},
    ok = esmpp_lib_worker:submit(Pid, [Text|SubmitOptions]).
    
submit_cyrillic_long(Config) ->
    Pid = ?config(pid, Config),
    SubmitOptions = ?config(submit_options, Config), 
    Text = {text, <<"Загальна довжина досягає 70 см. Голова низька та пласка.
                    Морда лопатоподібна, помірно довга та загострена. Очі 
                    відносно великі, овальні, горизонтальної форми. 
                    За ними на відстані ширини ока присутні великі бризкальца. 
                    Ніздрі широкі, розташовані близько до кінчика морди. Рот 
                    відносно маленький, майже прямий, розташовано поперек голови"/utf8>>},
    ok = esmpp_lib_worker:submit(Pid, [Text|SubmitOptions]).

submit_latin_short(Config) ->
    Pid = ?config(pid, Config),
    SubmitOptions = ?config(submit_options, Config), 
    Text = {text, <<"Lorem ipsum dolor sit amet.">>},
    ok = esmpp_lib_worker:submit(Pid, [Text|SubmitOptions]).

submit_latin_long(Config) ->
    Pid = ?config(pid, Config),
    SubmitOptions = ?config(submit_options, Config), 
    Text = {text, <<"Lorem ipsum dolor sit amet, consectetur adipiscing elit, 
                    sed do eiusmod tempor incididunt ut labore et dolore magna 
                    aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
                    ullamco laboris nisi ut aliquip ex ea commodo consequat. 
                    Duis aute irure dolor in reprehenderit in voluptate velit 
                    esse cillum dolore eu fugiat nulla pariatur. Excepteur 
                    sint occaecat cupidatat non proident, sunt in culpa qui 
                    officia deserunt mollit anim id est laborum.">>},
    ok = ct:pal("esmpp_lib_worker:submit", []),
    ok = esmpp_lib_worker:submit(Pid, [Text|SubmitOptions]),
    ok = ct:pal("esmpp_lib_worker:submit end", []).

submit_symbols(Config) ->
    Pid = ?config(pid, Config),
    SubmitOptions = ?config(submit_options, Config), 
    Text = {text, <<"There are some symbols from extended table of gsm 
                    data coding {test} [test1] € ~ mail@mail $ £ ¥ 
                    also _ § Å è | etc">>},
    ok = esmpp_lib_worker:submit(Pid, [Text|SubmitOptions]).

unbind(Config) ->
    Pid = ?config(pid, Config),
    ok = esmpp_lib_worker:unbind(Pid).
