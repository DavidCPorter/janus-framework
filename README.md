![fig_1](./utils/img/logos/blackgreen.png) 

## JANUS: cloud-native benchmarking framework 

JANUS is a framework to orchestrate, manage, and execute cloud-native benchmarking experiments.

Open source cloud-native development has become a double edge sword. Cherry picking services for domain-specific architectures makes enterprise development swift and powerful. However, the vast number of services in the open source ecosystem can leave engineers paralyzed by choice. A prudent engineer would conduct a fair evaluation of these architectures before making an investment. One key type of evaluation is performance benchmarking. Benchmarking is often a fickle task, requiring each service to be configured and operated in any number of infinite states. This quickly becomes unrealistic as you expand the scope of systems to evaluate since the complexity of conducting a fair evaluation reduces to (x systems * y configurations * z evaluations). 

JANUS simplifies this approach with a generalized framework to orchestrate, manage, and execute experiments across a variety of system configurations and deployments. 


### Architecture Overview

JANUS provides a management plane and control program for building, deploying, and executing a benchmarking experiment. The MGMT Plane prepares the orchestration of various deployments. Control program generates execution graphs and orchestrates the experiment. 

![fig_1](./utils/img/janus_architecture.png) 


An important design goal of JANUS was maintaining an abstract view of the modules that make up a system's architecture. Users can adapt their systems to JANUS easily with a familiar syntax and simple interface. Modules can be created and plugged into JANUS in one of 5 layers:

1) `ENV` environment running the software
2) `SERVICES` core features of the cloud-native system
3) `LOAD` hammer the servers with requests
4) `PIPE` pipe and filter data tasks
5) `VIZ` interactive visualizations




 module interface | *  
 ---- | ----
![fig_2](./utils/img/module_interface.png) | Each module contains at least one yaml file describing the operations to "activate" and "deactivate" the module using Ansible syntax. JANUS will parse varibles in these files to learn dependencies and provide a default VARS file for users. 


VARS:
JANUS 

JANUS makes extensive use of variable overriding and abstractions to support many parts of the system. Ansible provides the middleware in many places and JANUS development's goal was not to reinvent the wheel when possible. However, Ansible was slightly too opinionated in terms of variables and role management, so JANUS to some extent, uses Ansible in an unconventional way to simplify variable managment. 

Users can dynamically set variables with JANUS cli, load them from a janusfile, or leave them to their default behavior. JANUS will use variable precedence to construct the Optimal Flow DAG, and will load these at runtime for dynamic configuring, building, and deploying plays. Example of a module with three files for downloading, configuring, and running zookeeper: 


### Install




### Usage
Once installed, JANUS can be used with this CLI:
```
$ JANUS new --name <name> --branches <branchlist>
```
```
$ JANUS new --name experiemnt --branches branch1,branch2,branch3
$ JANUS <name> 
 > add [modules] [module_names] [branches]
 > add [vars] [key] [value] [branches]
 > add [hosts] [groupName] [module] and/or [play] [branches]
 > order [modules] [module1] [module2] ... [branches]

* "ls" will display user-entered info 
 > ls [vars] 
 > ls [modules]

* "show" will show execution order and will show runtime values
 > show [vars]
 > show [modules]
```

example:

```
$ janus new --name experiment1 --branches branch1,branch2,branch3
$ janus experiment1
 > 
 > add modules cloud-env all http_closed_loop cdf all
 > 
 > add modules solr solr_index solr_pipe zookeeper all!branch3
 > order modules cloud-env zookeeper solr solr_index http_closed_loop solr_pipe cdf all!branch3
 > 
 > add modules elastic elastic_index http_closed_loop es_pipe cdf branch3
 > order modules cloud-env elastic elastic_index es_pipe cdf branch3
 > 
 > add vars shards 2 replicas 6 all
 > add vars min_conn 1 max_conn 300 increment 10 all
 > add vars heap 5 branch1
 > add vars heap 2 branch2
 > add vars heap 1 branch3 
 > 
 > add hosts fourNode solr all
 > add hosts fourNode elastic
 > 
 > start all
```
Longer term goal is to implement a UI using REACT and reactdnd. 



Once the Management Plane does it's job of preparing the orchestration of each deployment, the control plane's reponsibility is to compute a dependency tree and learn which branches of the experiment share the most modules and plays, then figure out which plays to branch on given the variables, and construct the optimal execution path to minimize redundancy. Broad strokes look like this: 
 ![fig_2](./utils/img/control_program.png)


##### LOCAL ENV:
Create a python3 virtual env:  
`pyenv activate your_env`

install packages:  
`pip install ansible paramiko Jinja2 numpy`

##### CLOUD INFRASTRUCTURE:  
create inventory file with hosts

###### cloudlab setup 
(JANUS provides an optional cloudlab profile creation script JANUS/utils/cloudlab_profiles)
If you are using cloudlab resources, the cloud infrastructure creation is supported by JANUS. 
*first, place the domain names of your nodes in JANUS/utils/cloudlabDNS; then run:*
```
JANUS create inventory [max_component_nodes] [max_load_nodes]

```
this will create JANUS/inventory file

###### other setup
Most notably, you will need globally addressible nodes and a subnet connecting them.
Please emulate the inventory example with your own IPs. 
[add more]

###### emulating cloud infrastructure with local docker env
JANUS provides benchmarking even if you don't have cloud resources but emulating them with Docker locally. Steps to activate this env:
- add 0.0.0.0 as hostname for config file in ~/.ssh/config for all servers used in docker-compose.yml (see config-host.example)
- make sure docker desktop configuration allocates enough CPU cores and RAM (50% of your machine is good)
- run `$ bash container_rsa.yml` to load ssh keys into your containers. 


