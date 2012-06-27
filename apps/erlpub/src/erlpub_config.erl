-module(erlpub_config).


-export([rabbitmq_cluster/0,rabbitmq_connection_size/0]).



rabbitmq_cluster()->
	case  application:get_env(erlpub, rabbitmq_cluster) of
		{ok , Cluster } ->
			Cluster;
		undefined ->
			{ "127.0.0.1" ,5672}
	end.


rabbitmq_connection_size() ->
	case application:get_env(erlpub,rabbitmq_connection_size) of
		{ok , Size} ->
			Size;
		 _ ->
			4  * erlang:system_info(schedulers)
	end.