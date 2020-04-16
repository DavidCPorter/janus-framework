## OYSTACLOUD { * } 
deploy and compare performance of cloud-native systems with ease
```
                                              the cloud is your oysta 
```
*WHAT:* 
Oysta is a simple framework for designing cloud-native systems, deploying them on remote or local environment, and benchmarking request/response times and load so all deployments can be evaluated on a level playing field. 

*WHY:*
Building and deploying a single version of a cloud-native system is typically challenging. Moreover, deploying alternative architectures or configurations for comparative analysis can become a very challenging and time-consuming process. 

*HOW:*
Oysta's tooling suggests cloud architects conform to general principles when deploying and evaluating cloud-native applications. Oysta's framework enables this guided experience through a historically painstaking process. 



Oysta was desinged for general-purpose architecting (GPA), in other words, Oysta can be used to design and benchmark any cloud-native system. The entire framework is developed from three "views" or perspectives: 


1) how does Oysta define the cloud architectures? `DEFINITION` 
2) how does Oysta build the cloud systems? `MIDDLEWARE`
3) how does Oysta benchmark deployments? `CONTROL PLANE`

 

#### Definition 

OYSTA thinks about building, deploying and benchmarking cloud architectures in four layers. 
1) Infrastructure (env running the software)
2) Services (core featurs of the cloud native application goes here)
3) Data Pipeline (data collection delineating performance)
4) Vizualization ( visualize results )

Each layer has constituents, which are Ansible modules you create following Oysta's CLI tooling and design principles. 
The design priciples for builiding or Defining the cloud systems are concerned primarily with assigning variables to module tasks in an intuitive way, dependencies, and following the Control Plane interface.  

Once installed, Oysta can be used with this CLI:
*create module skeleton*

```
$ oysta new [name]
```
oysta [name] deployment add [deploy1, deploy2] 

*define a deployment*

```
$ oysta new solr1 solr2 solr1-vs-solr2
$ oysta list modules|experiments|branches,experiment
$ oysta configure solr1-vs-solr2
> add module 
$ oysta add module_name 
$ oysta configconfig queryCache:9999 documentCache:9999 all,!elastic1,!elastic2 ;
$ oysta workload loop:open all ;
$ oysta workload load_start:1 load_finish:100 solr1,solr2;
$ oysta workload load_balancer:clients all,!elastic2;
$ oysta plug ratelimiter /path/to/ratelimiter/binary all,!elastic1 ;
$ oysta viz cdf_91 total_throughput all
$ oysta show states all ;

```


Longer term goal is to implement a UI using react with reactdnd (react drag and drop) library to organize 



#### MIDDLEWARE

achieves this using a deconstructed version of Ansible roles as the middleware for deploying the systems and running workload tasks




#### CONTROL PLANE

Once an oysta experiment has been defined as explained in `DEFINITION`, the control plane's reponsibility is to compute a dependency tree for the experiment with each branch in the tree representing a different deployment to benchmark. Deployment branches from the tree when parameters to that module are different than the other branches. This is easier to understand with the below figures. 

```


```



  

### REQUIREMENTS / INSTALLATION

##### LOCAL ENV:
Create a python3 virtual env:  
`pyenv activate your_env`

install packages:  
`pip install ansible paramiko Jinja2 numpy`

##### CLOUD INFRASTRUCTURE:  

###### cloudlab setup 
(OYSTA provides an optional cloudlab profile creation script oysta/utils/cloudlab_profiles)
If you are using cloudlab reasources, the cloud infrastructure creation is supported by OYSTA. 
*first, place the domain names of your nodes in oysta/utils/cloudlabDNS; then run:*
```
oysta create inventory [max_component_nodes] [max_load_nodes]

```
this will create oysta/inventory file

###### other setup
Most notably, you will need globally addressible nodes and a subnet connecting them.
Please emulate the inventory example with your own IPs. 
[add more]

###### emulating cloud infrastructure with local docker env
OYSTA provides benchmarking even if you don't have cloud resources but emulating them with Docker locally. So, if you choose this route, please_:
- add 0.0.0.0 as hostname for config file in ~/.ssh/config for all servers used in docker-compose.yml (see config-host.example)
- make sure docker desktop configuration allocates enough CPU cores and RAM (50% of your machine is good)
- run `$ bash container_rsa.yml` to load ssh keyss into your containers. 


### RUNNING WITH LOCAL


### required variables 
when a deploy is run, oysta will load the UI variables, which override any defaults for that module (module/defaults/main.yml). Defaults will use jinja syntax to set var value to {{ui_var | 'default_string'}}. Since oysta has a predetermined variables, branch variables are also set for next branch in branch_vars/



next:

- load should save the results to default location on remote load machines. These results might include data from multiple iterations. 
- pipeline should retrieve remote results, filter results, and save locally
- viz should run once for entire oysta experiment at the end. 
 
 
 EXTRA:
 
 - `features` (e.g. data store, file system, transaction service, etc) are the core services a cloudsystem provides. 
 - `deployment` is a fully functional cloud-native system. (i.e. set of components)
 - `components` are systems that enable features for cloud-native systems (e.g. MongoDB, ElasticSearch, SolrCloud, Memcached, Hadoop, Spanner, S3 )
 - `workloads` are the applications which apply pressure to the system and track performance. 
 - `pipeline` this component drives the results from the many workloads into a format that can be projected in the next step.
 - `viz` projects the data into html charts for analysis of SLOs and performance characteristics.   
