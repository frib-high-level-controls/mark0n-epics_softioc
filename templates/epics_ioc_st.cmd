#!/bin/sh
HOST_ARCH=linux-x86_64
export EPICS_IOC_LOG_INET=127.0.0.1
export EPICS_IOC_LOG_PORT=6500
cd <%= iocbase %>/<%= name %>/<%= bootdir %>
exec ./st.cmd