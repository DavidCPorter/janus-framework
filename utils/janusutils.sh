#!/bin/bash

alias removecontainers='docker rm "$(docker ps -aq)"'
export JANUS_HOME=/Users/dporter/projects/janus
export ANSIBLE_CONFIG=$JANUS_HOME/experiments/ansible.cfg
PATH=$PATH:$JANUS_HOME/utils/bin
