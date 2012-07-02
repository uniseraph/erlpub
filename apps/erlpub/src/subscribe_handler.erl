-module(subscribe_handler).



%%
%% Exported Functions
%%
-export([init/3, terminate/2 , info/3]).

%%
%% Include files
%%
-include_lib("amqp_client/include/amqp_client.hrl").
-include_lib("cowboy/include/http.hrl").

%%
%% API Functions
%%

-record(state ,  { sub_key ,   channel ,  ctag , queue ,ref }) .

init({_Any, http}, Req=#http_req{socket=Socket}, []) ->

%	http://pubsub.pubnub.com
%	/subscribe
%	/sub-key
%	/channel
%	/callback
%	/timetoken	

	{SubKey    , Req1} = cowboy_http_req:binding(sub_key   , Req),
	{ChannelName   , Req2} = cowboy_http_req:binding(channel   , Req1),
	{_Callback  , Req3} = cowboy_http_req:binding(callback  , Req2),
	{Timetoken , Req4} = cowboy_http_req:binding(timetoken , Req3),


	case  amqp_connection_pool:get()    of
		{error ,Reason} ->
			{ok,Req5} =cowboy_http_req:reply(200, [] ,  ["publish error ,no connection to rabbitmq.\r\n" ] , Req4   ),
			{shutdown , Req5, #state{} };
		Connection ->
			case Timetoken of
					0 ->
						% query from db
						{shutdown , Req4 , #state{}};
					_ ->
						{ok , Channel} = amqp_connection:open_channel(Connection),
						Ref = erlang:monitor(process,Channel),

						#'exchange.declare_ok'{} =  amqp_channel:call(Channel,#'exchange.declare'{
							exchange =  erlpub_util:build_exchange_name( SubKey, ChannelName) ,
							durable  =  true,
							type     =  <<"topic">>				
						}),

						#'queue.declare_ok'{queue = X } = amqp_channel:call(Channel,
							 #'queue.declare'{durable= true} ),

       					#'queue.bind_ok'{} = amqp_channel:call(Channel, 
							#'queue.bind'{	queue       = X,
                         		exchange    = erlpub_util:build_exchange_name(SubKey,ChannelName) ,
			 			 		routing_key =   <<"*">>   }) ,


       					#'basic.consume_ok'{consumer_tag = Ctag} 
							= amqp_channel:subscribe(Channel, 
						        #'basic.consume'{queue = X ,no_ack= false},self()),

	        			Headers = [{'Content-Type', <<"text/event-stream">>}],
	        			{ok, Req5} = cowboy_http_req:chunked_reply(200, Headers, Req4),
%	          			cowboy_tcp_transport:setopts(Socket, [{active, once}]), 

	   					{loop , Req5,  #state{sub_key=SubKey,channel=Channel, 
					  		 ctag=Ctag , queue= X , ref=Ref}  , hibernate}
				end

	end.





info({'DOWN', Ref, Channel , Channel, Info} , Req , State=#state{ref=Ref , channel=Channel} ) ->
	error_logger:info_msg("~p recving a channel:~p die message because of ~p~n", [self(), Channel , Info]) ,
	{ok,Req1} =cowboy_http_req:reply(200, [] ,  ["publish error, no confirm \r\n" ] , Req   ),

	{ok , Req1 , State#state{channel=undefined} };
info({tcp_closed , _ } , 
	 	Req = #http_req{socket=_Socket} ,	
	 	State=#state {channel=Channel ,ctag=Ctag,queue=Queue}) ->
	amqp_channel:call(Channel, #'basic.cancel'{consumer_tag = Ctag}) ,
	amqp_channel:call(Channel, #'queue.delete'{queue=Queue}) ,
	amqp_channel:close(Channel),
	{ok , Req, State} ;

info(  {#'basic.deliver'{delivery_tag = Dtag}, #amqp_msg{payload=Payload}}   , 
	   Req= #http_req{socket=Socket}  ,  State =#state{channel=Channel} )  ->
%	cowboy_tcp_transport:setopts(Socket, [{active, once}]), 

	ok = cowboy_http_req:chunk( [Payload, "\r\n"] , Req ),
    amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Dtag}),
	{loop,Req, State ,hibernate};

info(_Message, Req= #http_req{socket=Socket} ,State) ->
%	cowboy_tcp_transport:setopts(Socket, [{active, once}]), 
	{loop , Req , State , hibernate} .






terminate(_Req, _State=#state{channel=_Channel,ref=Ref}) ->
%	error_logger:info_msg("~p terminate~n",[self()]),
	erlang:demonitor(Ref),

	ok.



%%
%% Local Functions
%%