# import dns.resolver
# import paramiko
# import base64
import os
import sys
import time
import subprocess
import copy


# anticipating the need to track things in this closure
def tree_closure(inv):
    ansible_prefix = ['ansible-playbook', '-i', inv, '../r_modules/main.yml']
    levels = 0
    branch_count = 0

    def tree_walker(dfs_dict):
        nonlocal levels
        nonlocal branch_count

        hosts = dfs_dict['hosts']
        play = dfs_dict['play']
        vars = dfs_dict['vars']
        module = dfs_dict['module']
        vars = 'branch_file_ui=' + vars + ' hosts_ui=' + hosts + ' tasks_file_ui=' + play + ' module=' + module

        if levels > 7:
            print(levels)
            print(vars)
            subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'activate'])
        # output = subprocess.run(['cat', '../inventory'])
        # ansible-playbook - i inventory extra-vars "hosts =$HOSTS vars =$VARS $PLAY"

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
    default_vars = "sapa_vars.yml"
    example_of_branch_vars = "example_vars.yml"

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
                        "module": "zookeeper",
                        "hosts": "zookeeperNodes",
                        "play": "run_tasks.yml",
                        "vars": default_vars,
                        "next": {
                            "module": "solr",
                            "hosts": "twoNode",
                            "play": "install_tasks.yml",
                            "vars": default_vars,
                            "next": {
                                "module": "solr",
                                "hosts": "twoNode",
                                "play": "config_tasks.yml",
                                "vars": default_vars,
                                "next": {
                                    "module": "solr",
                                    "hosts": "twoNode",
                                    "play": "run_tasks.yml",
                                    "vars": default_vars,
                                    "next": {
                                        "module": "index_solr",
                                        "hosts": "singleNode",
                                        "play": "download_json.yml",
                                        "vars": default_vars,
                                        "next": {
                                            "module": "index_solr",
                                            "hosts": "twoNode",
                                            "play": "0_pre_index_config.yml",
                                            "vars": default_vars,
                                            "next": {
                                                "module": "index_solr",
                                                "hosts": "twoNode",
                                                "play": "1_index.yml",
                                                "vars": default_vars,
                                                "next": {
                                                    "module": "index_solr",
                                                    "hosts": "twoNode",
                                                    "play": "3_post_index_config.yml",
                                                    "vars": default_vars,
                                                    "next": {
                                                    },
                                                    "branches": []
                                                },
                                                "branches": []
                                            },
                                            "branches": []
                                        },
                                        "branches": []
                                    },
                                    "branches": []
                                },
                                "branches": []
                            },
                            "branches": []
                        },
                        "branches": []
                    },
                    "branches": []
                },
                "branches": []
            },
            "branches": [{
                "module": "zookeeper",
                "hosts": "zookeeperNodes",
                "play": "download_tasks.yml",
                "vars": example_of_branch_vars,
                "next": {
                    "module": "zookeeper",
                    "hosts": "zookeeperNodes",
                    "play": "download_tasks.yml",
                    "vars": default_vars,
                    "next": {},
                    "branches": []
                },
                "branches": []
            }]
        },
        "branches": []
    }

    print(DFS_dict)

    # DFS_dict = toolUIgenerator()  # this generates a dict like the one at the top
    t_walker = tree_closure(inv)
    t_walker(DFS_dict)
    # execute_visualizations()
    # exit()


def utils(args):
    dfs_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    print(dfs_dict)

    hosts = dfs_dict['--hosts']
    play = dfs_dict['--play']
    var_file = dfs_dict['--vars']
    module = dfs_dict['--module']
    inv = dfs_dict['--inv']
    tags = dfs_dict['--tags']

    extra_vars_param = 'branch_file_ui=' + var_file + ' hosts_ui=' + hosts + ' tasks_file_ui=' + play + ' module=' + module
    ansible_prefix = ['ansible-playbook', '-i', inv, '../r_modules/main.yml']

    subprocess.run(ansible_prefix + ['--extra-vars', extra_vars_param, '--tags', "utils," + tags])


if __name__ == "__main__":

    if sys.argv[1] == 'utils':
        print("running utils function")
        sys.exit(
            utils(sys.argv[2:])
        )
    if len(sys.argv) < 1:
        print('usage: python3 start.py <path_to_inventory>')
    sys.exit(

        main(sys.argv[1])

    )
