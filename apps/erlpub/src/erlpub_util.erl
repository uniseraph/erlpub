%% Author: uniseraph
%% Created: 2012-4-10
%% Description: TODO: Add description to erlmc_util
-module(erlpub_util).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([build_exchange_name/1,build_exchange_name/2]).

%%
%% API Functions
%%
build_exchange_name(App)  when is_binary(App) ->
	<< 	<<"erlpub.">>/binary ,   App/binary  >> .


build_exchange_name(SubKey ,Channel) when is_binary(SubKey) , is_binary(Channel) ->
	<< 	<<"erlpub.">>/binary ,   SubKey/binary ,  <<".">>/binary ,  Channel/binary    >> .


%%
%% Local Functions
%%

