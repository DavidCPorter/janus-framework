#!/bin/bash

alias removecontainers='docker rm "$(docker ps -aq)"'
export JANUS_HOME=/Users/dporter/projects/janus

PATH=$PATH:$JANUS_HOME/utils/bin
