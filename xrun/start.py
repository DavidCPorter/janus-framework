# import dns.resolver
# import paramiko
# import base64
import os
import sys
import time
import subprocess

def recurse_helper(dfs_dict):

    # subprocess.run(args, *, stdin=None, input=None, stdout=None, stderr=None, capture_output=False, shell=False, cwd=None, timeout=None, check=False, encoding=None, errors=None, text=None, env=None, universal_newlines=None)¶

    hosts = dfs_dict['hosts']
    play = dfs_dict['play']
    vars = dfs_dict['vars']
    module = dfs_dict['module']
    vars='branch_file_ui='+vars+' hosts_ui='+hosts+' tasks_file_ui='+play+' module='+module
    print(vars)

    output = subprocess.run(['ansible-playbook', '-i', '../inventory', '../r_modules/main.yml', '--extra-vars', vars, '--tags', 'activate'])
    # output = subprocess.run(['cat', '../inventory'])
    # ansible-playbook - i inventory extra-vars "hosts =$HOSTS vars =$VARS $PLAY"

    if len(dfs_dict['next']) > 0:
        recurse_helper(dfs_dict['next'])

    for branch in dfs_dict['branches']:
        recurse_helper(branch)

    revert_output = subprocess.run(['ansible-playbook', '-i', '../inventory', '../r_modules/main.yml', '--extra-vars', vars, '--tags', 'deactivate' ])

    return


def main(inv):
    default_vars="sapa_vars.yml"
    example_of_branch_vars="sapa_vars.yml"

    DFS_dict = {
        "module": "cloud-env",
        "hosts": "all:!mylocal",
        "play": "install_tasks.yml",
        "vars": default_vars,
        "next": {
            "module": "cloud-env",
            "hosts": "all:!mylocal",
            "play": "aws_tasks.yml",
            "vars": default_vars,
            "next": {
                "module": "zookeeper",
                "hosts": "zookeeperNodes",
                "play": "download_tasks.yml",
                "vars": default_vars,
                "next": {
                    "module": "zookeeper",
                    "hosts": "zookeeperNodes",
                    "play": "configure_tasks.yml",
                    "vars": default_vars,
                    "next": {
                    },
                    "branches": []
                },
                "branches": []
            },
            "branches": [{
                "hosts": "zookeeper",
                "play": "zookeeperNodes",
                "vars": example_of_branch_vars,
                "next": {
                    "module": "zookeeper",
                    "hosts": "zookeeperNodes",
                    "play": "download_tasks.yml",
                    "vars": default_vars,
                    "next": {},
                    "branches":[]
                },
                "branches":[]
            }]
        },
        "branches": []
    }

    print(DFS_dict)

        # DFS_dict = toolUIgenerator()  # this generates a dict like the one at the top
    recurse_helper(DFS_dict)
    # execute_visualizations()
    # exit()




if __name__ == "__main__":
    if len(sys.argv) < 1:
        print('usage: python3 start.py <path_to_inventory>')
    sys.exit(

        main(sys.argv[1])

    )

