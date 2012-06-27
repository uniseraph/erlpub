-module(erlpub_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
	 Dispatch = [
		{'_', [
	

%	http://pubsub.pubnub.com
%	/publish
%	/pub-key
%	/sub-key
%	/signature
%	/channel
%	/callback
%	/message

					  %   curl http://localhost:8080/publish/pub-key/sub-key/signature/channel1/0/helloworld
                      {[<<"publish">>,pub_key,sub_key,signature,channel,callback,message],publish_handler,[]} ,
%	http://pubsub.pubnub.com
%	/subscribe
%	/sub-key
%	/channel
%	/callback
%	/timetoken
	
				% curl http://localhost:8080/subscribe/sub-key/channel/0/12134
                {[<<"subscribe">>,sub_key,channel,callback,timetoken],subscribe_handler,[]},

%	http://pubsub.pubnub.com
%	/history
%	/sub-key
%	/channel
%	/callback
%	/limit

%		{[<<"history">>,sub_key,channel,callback,limit],history_handler,[]},	

			
		{'_', default_handler, []}
		]}
	],
	cowboy:start_listener(my_http_listener, 5,
		cowboy_tcp_transport, [{port, 8080}],
		cowboy_http_protocol, [{dispatch, Dispatch}]
	),
    erlpub_sup:start_link().

stop(_State) ->
    ok.
