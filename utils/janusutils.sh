#!/bin/bash

pyenv activate ansible
export JANUS_HOME=/Users/dporter/projects/janus
export ANSIBLE_CONFIG=$JANUS_HOME/experiments/ansible.cfg
PATH=$PATH:$JANUS_HOME/utils/bin
cd $JANUS_HOME
