import yaml
import sys
import os

ymlfile=open("saga_example.yml", "r")
yobj=yaml.safe_load(ymlfile)
print(yobj)



