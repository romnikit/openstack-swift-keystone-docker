#!/bin/bash

service rsyslog start
service rsync start
service memcached start
service swift-proxy start
service swift-container start
service swift-account start
service swift-object start

apachectl -DFOREGROUND &

if [ -z "$KS_SWIFT_PUBLIC_URL" ]
then
    ecport KS_SWIFT_PUBLIC_URL="http://127.0.0.1:8086"
fi

CONFIG_PUB_URL=$(cat /opt/SWIFT_INIT)
if [ "$KS_SWIFT_PUBLIC_URL" = "$CONFIG_PUB_URL" ]
then
    echo "$KS_SWIFT_PUBLIC_URL endpoint already configured."
    sleep 2
else
    wait_seconds=5
    until test $((wait_seconds--)) -eq 0 -o -f "$pid_file" ; do echo -n "$wait_seconds " ; sleep 1; done
    echo
    openstack endpoint create --region RegionOne object-store internal http://127.0.0.1:8086/v1/KEY_%\(tenant_id\)s
    openstack endpoint create --region RegionOne object-store admin http://127.0.0.1:8086/v1
    openstack endpoint create --region RegionOne object-store public ${KS_SWIFT_PUBLIC_URL}/v1/KEY_%\(tenant_id\)s

    echo "$KS_SWIFT_PUBLIC_URL" > /opt/SWIFT_INIT
fi
wait
