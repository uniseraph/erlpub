%% Author: uniseraph
%% Created: 2012-6-27
%% Description: TODO: Add description to erlpub
-module(erlpub).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).

%%
%% API Functions
%%
start()->
		application:start(cowboy),
	application:start(erlpub).


%%
%% Local Functions
%%

