%% Author: uniseraph
%% Created: 2012-4-9
%% Description: TODO: Add description to register_app
-module(publish_handler).


%-behaviour(cowboy_http_handler).


%%
%% Exported Functions
%%
-export([init/3,  terminate/2]).
-export([info/3]).
%-export([handle/2]).
%%
%% Include files
%%
-include_lib("amqp_client/include/amqp_client.hrl").
-include_lib("cowboy/include/http.hrl").

-record(state,{channel=undefined,noreply=true,ref}).
%%
%% API Functions
%%

%	http://pubsub.pubnub.com
%	/publish
%	/pub-key
%	/sub-key
%	/signature
%	/channel
%	/callback
%	/message

init({_Any, http}, Req, []) ->

	{PubKey   , Req1} = cowboy_http_req:binding(pub_key  , Req),
	{SubKey , Req2} = cowboy_http_req:binding(sub_key, Req1),
	{Signature  , Req3} = cowboy_http_req:binding(signature , Req2),
	{ChannelName   , Req4} = cowboy_http_req:binding(channel  , Req3),
	{_Callback , Req5} = cowboy_http_req:binding(callback, Req4),
	{Message  , Req6} = cowboy_http_req:binding(message , Req5),
	

	case  amqp_connection_pool:get()    of
		{error ,Reason} ->
			{ok,Req7} =cowboy_http_req:reply(200, [] ,  ["publish error ,no connection to rabbitmq.\r\n" ] , Req6   ),
			{shutdown , Req7, #state{noreply=false} };
		Connection ->

   				{ok , Channel} = amqp_connection:open_channel(Connection),
				Ref = erlang:monitor(process,Channel),
%				Declare = #'exchange.declare'{
%					exchange =  erlpub_util:build_exchange_name( SubKey, ChannelName) ,
%					durable  =  true,
%					type     =  <<"topic">>				
%				},
%		  		#'exchange.declare_ok'{} =  amqp_channel:call(Channel,Declare),

    			ok =  amqp_channel:register_return_handler(Channel, self()),
	    		ok =  amqp_channel:register_confirm_handler(Channel, self()),
      	    	#'confirm.select_ok'{}=amqp_channel:call(Channel,#'confirm.select'{}),	
			    
                Publish = #'basic.publish'{
					exchange    =  erlpub_util:build_exchange_name( SubKey, ChannelName) ,
					mandatory   =  true,
					routing_key =  <<"*">>	
				},
     			
				Msg = #amqp_msg{props =  #'P_basic'{delivery_mode = 2}  ,  
			   		payload = Message},
       			
				amqp_channel:call(Channel,Publish,Msg),

				{ loop , Req6 , #state{channel=Channel,ref=Ref} ,500 } 
	end.

info({'DOWN', Ref, Channel , Channel, Info} , Req , State=#state{ref=Ref , channel=Channel} ) ->
	error_logger:info_msg("~p recving a channel:~p die message because of ~p~n", [self(), Channel , Info]) ,
	
	{ok , Req , State#state{channel=undefined} };

info( { #'basic.return'{reply_code=_ReplyCode,reply_text=ReplyText} , _ } = Message  ,  Req , State ) ->
	error_logger:info_msg("~p recving a message ~p~n", [self(), Message]) ,
	{ok,Req2} =cowboy_http_req:reply(200, [] ,  ["publish error ," , ReplyText , "\r\n" ] , Req   ),
	{ok , Req2 , State#state{noreply=false} };

info( #'basic.ack'{delivery_tag=1,multiple=false}=Message, Req,State)->
	error_logger:info_msg("~p recving a message ~p~n", [self(), Message]) ,
	{ok,Req2} =cowboy_http_req:reply(200, [] ,  ["publish success \r\n" ] , Req   ),
	{ok , Req2 , State#state{noreply=false} };
info( #'basic.nack'{}=Message, Req,State)->
	error_logger:info_msg("~p recving a message ~p~n", [self(), Message]) ,
	{ok,Req2} =cowboy_http_req:reply(200, [] ,  ["publish error, no confirm \r\n" ] , Req   ),
	{ok , Req2 , State#state{noreply=false} };

info(Message , Req, State) ->
	error_logger:info_msg("~p recving a message ~p~n", [self(), Message]) ,
	{loop , Req , State} .

	



terminate(Req=#http_req{resp_state=_RespState}, 
		#state{channel=Channel  , noreply =NoReply }) ->
    case   NoReply of 
		true ->
			 %greate hack
	 	 cowboy_http_req:reply(200, [],	<< "publish success\r\n" >>, Req#http_req{resp_state=waiting}) ;
		false ->
			ok
	end,
	case Channel of
		undefined ->
			ok;
		_ ->
			amqp_channel:close(Channel)
	end.





%%
%% Local Functions
%%





















