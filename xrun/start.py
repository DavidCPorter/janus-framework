# import dns.resolver
# import paramiko
# import base64
import os
import sys
import time
import subprocess
import copy

from mydicts import *

# anticipating the need to track things in this closure


def tree_closure(inv):
    ansible_prefix = ['ansible-playbook', '-i', inv, '../r_modules/main.yml']
    levels = 0
    branch_count = 0

    def tree_walker(dfs_dict):
        nonlocal levels
        nonlocal branch_count

        hosts = dfs_dict['hosts']
        stage = dfs_dict['stage']
        play = dfs_dict['play']
        vars = dfs_dict['vars']
        module = dfs_dict['module']
        vars = 'branch_file_ui=' + vars + ' hosts_ui=' + hosts + ' tasks_file_ui=' + play + ' module=' + module + ' stage=' + stage

        # if levels > 7:
        print(levels)
        print(vars)
        subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'activate'])

        if len(dfs_dict['next']) > 0:
            levels += 1
            tree_walker(dfs_dict['next'])

        # for branch in dfs_dict['branches']:
        #     branch_count+=1
        #     tree_walker(branch)

        # when there is no next and no branch to take, we've reached the leaf, and we recurse back and continue to 'deactivate' each node until we find a branch
        # subprocess.run(ansible_prefix+['--extra-vars', vars, '--tags', 'deactivate'])

        return

    return tree_walker


def main(inv):

    DFS_dict = getDfsDict()
    # DFS_dict = toolUIgenerator()  # this generates a dict like the one at the top
    t_walker = tree_closure(inv)
    t_walker(DFS_dict)
    # execute_visualizations()
    # exit()



def utils(args):
    dfs_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}

    tags = dfs_dict.get('--tags', 'activate')

    if tags != "activate" and tags != "deactivate":
        d = getAdHocDict()
        if tags in d:
            # do predefined tasks via custom tags if exist, otherwise run utils with default params
            utils(d[tags].split(' '))
            return
    # if tags != activate or deactivate, then default params are loaded here which point to default module in utils stage.
    hosts = dfs_dict.get("--hosts", 'all')
    play = dfs_dict.get("--play", 'main.yml')
    var_file = dfs_dict.get("--vars", 'ui_sapa_vars.yml')
    module = dfs_dict.get('--module', 'default')
    inv = dfs_dict.get('--inv', '/Users/dporter/projects/sapa/inventory_local')
    stage = dfs_dict.get('--stage', 'utils')

    extra_vars_param = 'branch_file_ui=' + var_file + ' hosts_ui=' + hosts + ' tasks_file_ui=' + play + ' module=' + module + ' stage=' + stage
    ansible_prefix = ['ansible-playbook', '-i', inv, '../r_modules/main.yml']

    subprocess.run(ansible_prefix + ['--extra-vars', extra_vars_param, '--tags', "utils," + tags])


if __name__ == "__main__":

    if sys.argv[1] == 'utils' and len(sys.argv) < 4:
        print("utils option requires additional parameters e.g.: \n python3 start.py utils --hosts all --play "
              "main.yml --vars ui_sapa_vars.yml --module example_mod --inv "
              "/Users/dporter/projects/sapa/inventory_local --tags "
              "rsa_config --stage service")

    elif sys.argv[1] == 'utils' and len(sys.argv) >= 4:
        print("running utils function")
        sys.exit(
            utils(sys.argv[2:])
        )
    elif len(sys.argv) < 2:
        print('usage: python3 start.py <path_to_inventory>')

    elif len(sys.argv) == 2:
        print('running exp')
        sys.exit(
            main(sys.argv[1])
        )
    print(len(sys.argv))
    sys.exit()
