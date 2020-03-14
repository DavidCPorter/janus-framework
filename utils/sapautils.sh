#!/bin/bash

alias removecontainers='docker rm "$(docker ps -aq)"'
export OYSTER_HOME=/Users/dporter/projects/sapa

PATH=$PATH:$OYSTER_HOME/utils/bin
