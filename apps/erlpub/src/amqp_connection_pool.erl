%%% -------------------------------------------------------------------
%%% Author  : uniseraph
%%% Description :
%%%
%%% Created : 2012-6-23
%%% -------------------------------------------------------------------
-module(amqp_connection_pool).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("amqp_client/include/amqp_client.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2,start_link/0,get/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {pool,size,port,host}).

%% ====================================================================
%% External functions
%% ====================================================================
get()->
	gen_server:call(?MODULE,get).

%% ====================================================================
%% Server functions
%% ====================================================================
start_link({Host,Port},Size)->
	gen_server:start_link({local, ?MODULE},?MODULE,[{Host,Port},Size],[]).


start_link()->
	start_link(erlpub_config:rabbitmq_cluster(),
			erlpub_config:rabbitmq_connection_size()).
	 

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([{Host,Port} , Size]) ->
	 pg2:create(connection_pool),
	
%%		[ { Host , Port} | _L ] = erlmc_config:rabbitmq_cluster(),
    	
	lists:foreach(   fun (_)->
				{ok , Connection} = 
					amqp_connection:start(#amqp_params_network{
											host = Host , 
											port = Port
										}),
				pg2:join(connection_pool,Connection)
	end ,  lists:seq( 1,  Size) ), 
	
    {ok, #state{pool=connection_pool,size=Size,host=Host,port=Port}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call(get , _From , State=#state{pool=Pool,port=Port,host=Host,size=Size}) ->
	case pg2:get_closest_pid(Pool)  of
		{no_process,_} ->
			{reply , {error,no_process} ,State};
		Pid when is_pid(Pid)->
			{reply ,Pid , State}
	end;
	
handle_call(Request, From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	pg2:delete(connection_pool),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(OldVsn, State, Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

