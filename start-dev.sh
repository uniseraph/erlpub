erl -pa  apps/erlpub/ebin -pa deps/*/ebin -boot start_sasl \
        -config rel/files/sys.config  \
        -s erlpub \
        +K true +P 10240000