import pdb
import traceback

import pip
import sys
import os
import subprocess
import oysterutils as OysterUtils
import _ssh_import as ssh_import
from _branch_class import Experiment
from typing import Set
from itertools import permutations
import _start_basic as Start

import yaml
from collections import OrderedDict
from jinja2 import Template
import re
from _graph_node import Noder


# pass in all active branch names
def update_groupnames(branch_names: Set):
    groupnames_list = []
    valid_groupnames_dict = {}
    for r in range(1, len(branch_names)+1):
        itertools = permutations(branch_names, r)
        for i in itertools:
            groupnames_list.append(','.join(i))
            valid_groupnames_dict.update({','.join(i) : set(i)})


    for i in groupnames_list:
        set_to_remove = set(i.split(','))
        value_set = branch_names - set_to_remove
        valid_groupnames_dict.update({'all!'+i : value_set})

    valid_groupnames_dict.update({'all' : branch_names})

    return valid_groupnames_dict



def commandDispatcher(exp_dict):
    name = exp_dict.get('--name')
    home_dir = exp_dict.get('--home')
    r_modules = home_dir + '/r_modules'
    stages = {'env', 'load', 'pipeline', 'service', 'viz'}
    available_modules = {x : list() for x in stages}


    for stage in os.scandir(r_modules):
        if stage.name in stages:
            available_modules.update({stage.name: [x.name for x in os.scandir(stage.path)]})
    allmods = available_modules.values()
    module_play_order = {mod : OrderedDict() for m_list in allmods for mod in m_list}
    module_var_order= {mod : OrderedDict() for m_list in allmods for mod in m_list}
    for stage in os.scandir(r_modules):
        if stage.name in stages:
            for m in os.scandir(r_modules+'/'+stage.name):
                play_list = []
                for j in os.scandir(r_modules+'/'+stage.name+'/'+m.name+'/'+'plays'):
                   play_list.append(j.name)
                play_list.sort()
                variable_pos = 1
                for pname in play_list:
                    pname_path = r_modules+'/'+stage.name+'/'+m.name+'/'+'plays/'+pname
                    # update dict in order
                    # implies the play directiory is listed in order
                    play_dict = module_play_order.get(m.name)
                    play_dict.update({pname: 'all'})
                    module_play_order.update({m.name: play_dict})
                    ordered_var_dict = module_var_order.get(m.name)

                    rgx = re.compile('{{(?P<name>[^{}]+)}}')
                    #                 open play file and read the variabels in order to pass as a control dict to Experiment cls
                    with open(r_modules+'/'+stage.name+'/'+m.name+'/'+'plays/'+pname, 'r') as playfile:
                        for line in playfile.readlines():
                            if '{{' not in line:
                                continue
                            tmpl = Template(line)
                            var_keys = {match.group('name') for match in rgx.finditer(line)}

                            for v in var_keys:
                                if v not in ordered_var_dict:
                                    ordered_var_dict.update({v:(variable_pos,pname)})
                                    variable_pos+=1

                    print(m.name)

    tmp = set()
    try:

        for branch in os.scandir('.'):
            if branch.is_dir():
                tmp.add(branch.name)

        # create a hostfile that ~/.ssh/config includes temporarily that treats branches as a host so you can apply var updates to them all... just my preferred way to keep tabs on all var updates for the exp.
        for branch in tmp:
            ssh_import.new_branch(branch, exp_dict.get('--home_user'), home_dir)

        # make local_var_inventory file for vars
        ssh_import.new_inventory(tmp, exp_dict.get('--home_user'))



    except (RuntimeError, TypeError, NameError) as e:
        print(e)
        return 1



    # experiment_modules
    experiment = Experiment(name, available_modules, r_modules, module_play_order, module_var_order, [b_name for b_name in tmp])


    # this dict maps ansible groupname notation to a set of branch_names
    valid_groupnames_dict = update_groupnames(tmp)

    for i in valid_groupnames_dict.keys():
        print(f'{i} --> {valid_groupnames_dict.get(i)}')




    def cmdFetcher(args):
        nonlocal valid_groupnames_dict

        if args[-1] not in valid_groupnames_dict.keys():
            groups = 'all'

        else:
            groups = args.pop()

        target_branch_set = valid_groupnames_dict.get(groups)

        def ls(vars,target_branches):
            nonlocal experiment


            if vars[0] == 'modules':
                print('yes')
                experiment.show_ordered_mods(target_branches)

            if vars[0] == 'vars':
                cli_options = vars[1:]
                cli_options_dict = {cli_options[x]: cli_options[x + 1] for x in range(0, len(cli_options) - 1) if
                                    x % 2 == 0}
                experiment.ls('vars', cli_options_dict, target_branches)

            #
            if vars[0] == 'branches':
                print(experiment.branches)

        def add(vars,target_branches):
            if len(vars) < 2:
                print(f'vars {vars} incorrect')
                return

            nonlocal experiment,valid_groupnames_dict

            if vars[0] == 'branch':
                experiment.add_branch(vars[1])
                branch_names = set(experiment.branches.keys())
                valid_groupnames_dict = update_groupnames(branch_names.union(target_branches))
                print('success')

            if vars[0] == 'modules' or vars[0] == 'module':
                experiment.update_modules('add', vars[1:], target_branches)

            if vars[0] == 'vars':
                user_variables = vars[1:]
                experiment.update_variables(user_variables, target_branches)


            if vars[0] == 'hosts':
                if len(vars) < 4:
                    print('BASIC assumes you left out playname(s) argument, so default behavior applied changes to all plays')
                    vars.append('all')
                hostgroup = vars[1]
                modulename = vars[2]
                playname = vars[3]
                experiment.update_hostgroups(hostgroup, modulename, playname, target_branches)

        def rm(vars,target_branches):
            nonlocal experiment, valid_groupnames_dict
            if vars[0] == 'branch' or vars[0] == 'branches':
                experiment.rm_branches(target_branches)
                valid_groupnames_dict = update_groupnames(set(experiment.branches.keys()))
                print('success')

            if vars[0] == 'modules' or vars[0] == 'module':
                experiment.update_modules('rm', vars[1].split(','), target_branches)

        def show(vars, target_branches):
            if vars[0] == 'tree':
                branch_order = experiment.get_branch_flow_order([b for b in experiment.branches.values()], list_flag='filtered')
                print(branch_order)
                return






        # oyster cmd does project operations when in interactive mode
        def oyster(vars,target_branches):
            nonlocal experiment
            if vars[0] == 'add' and vars[1] == 'branch':
                add(vars[1:], target_branches)
            elif vars[0] == 'ls' and vars[1] == 'branches':
                ls(vars[1:], target_branches)

            else:
                print('oyster command did not match operation')


        def order(vars,target_branches):
            nonlocal experiment
            ordered_list = vars[1:]
            experiment.update_modules('order', ordered_list, target_branches)

        def start(vars, target_branches):
            nonlocal experiment
            # returns a list of lists of sets each set in a list represents a single branch, and each list in a list is a different point in the module order.
            branch_order = experiment.get_branch_flow_order([b for b in experiment.branches.values()], list_flag='filtered')
            full_branch_flow = experiment.get_branch_flow_order([b for b in experiment.branches.values()], list_flag='unfiltered')
            # make a graph out of the branch order
            final_list = list()

            def explore_next(node):
                nonlocal final_list
                if node.neighbors == None:
                    final_list.append(node.value)
                    return
                union_set = set()
                for i in node.neighbors:
                    if i.value.issubset(node.value):
                        union_set = union_set.union(i.value)
                        explore_next(i)
                if len(node.value - union_set) > 0:
                    final_list.append(node.value-union_set)

            # Creates Nodes representation of branchorder
            graph = [[Noder(i,None) for i in j] for j in branch_order ]
            rootNode = Noder({t for t in target_branches}, graph[0])
            next_level=0
            for i in graph:
                next_level+=1
                if next_level == len(graph):
                    break
                for j in i:
                    # set reference to neighbors
                    j.neighbors = graph[next_level]


            explore_next(rootNode)
            # want to order modules within the set correctly
            # list list(_branches_sharing_mod) set(variables) tuple(key,value)
            llst_branches_variables = experiment.get_vars_to_branch_on(final_list, full_branch_flow)
            print(llst_branches_variables)
            # returns list of list tuples(branch_name, module, play_to_start_from)
            ordered_set = experiment.get_ordered_set(llst_branches_variables, final_list)
            print(ordered_set)
            final = experiment.get_final_mod_play_levels(ordered_set, full_branch_flow)
            # walk the branches connected

            shotgun,first_branch,mod_start,play_start = experiment.execute_experiment(final)
            print(first_branch,mod_start,play_start)
            shotgun(first_branch,mod_start,play_start)



            #  {branchname,
            # start at module,play - passed in from previous branch recurse
            #  starts playing from module,play_order
            # continues through modules
            # recurses to point 'module,play'
            #
            # "stage": "env",
            # "module": "cloud-env",
            # "hosts": "all:!mylocal",
            # "play": "install_tasks.yml",
            # "vars": default_vars,
            # "next": {module}
            # "branch": {next branch in ordered_set}

            # for b_name,branch_play in branch_play_tuple_list:
            #     branch = experiment.branches.get(b_name)
            #     for m in branch.ordered_mods:
            #         m_instance = branch.modules.get(m)
            #         print(m)
            #         mod_execution_tuple = []
            #         for k,v in m_instance.play_order.items():
            #             mod_execution_tuple.append((k,v))
            #         print(mod_execution_tuple)







            return
            #
            # branch_order = experiment.get_dfs_branch_order(target_branches)
            # ordered_branch_playbranch_tuple_list = experiment.get_branch_at_play(branch_order)
            # for branch_name,play_to_branch_on in ordered_branch_playbranch_tuple_list:
            #     b_instance = experiment.branches.get(branch_name)
            #






        decorated_command = dict(add=add, rm=rm, ls=ls, oyster=oyster, order=order, show=show, start=start)

        return_function = decorated_command.get(args[0])

        # add vars as a default if command is only "ls"

        # if command was 'ls [group]' or 'ls' then default to vars
        if len(args) == 1 and args[0] == 'ls':
            args.append('vars')

        # remove command from args to return function
        args = args[1:]

        return return_function, args, target_branch_set

    return cmdFetcher


def main(interactive_dict):
    print(interactive_dict)
    os.chdir(str(interactive_dict.get('--home')) + '/experiments/' + str(interactive_dict.get('--name')))

    experiment_context = commandDispatcher(interactive_dict)
    user_command = ''

    while user_command != 'exit':
        user_command = input('> ')
        user_command.split()
        user_command.replace('  ', ' ')

        if user_command == '' or user_command == 'exit':
            # print('continue')
            continue

        user_command_list = user_command.split(' ')
        if user_command_list[-1] == '':
            user_command_list.pop()
        try:
            cmd,args,target_branches = experiment_context(user_command_list)
            if cmd:
                cmd(args,target_branches)
            else:
                print('command not found')

        except (RuntimeError, TypeError, NameError) as e:
            print("error -> ", e)
            traceback.print_exc()



if __name__ == '__main__':
    print(sys.argv)
    args = sys.argv[1:]
    i_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    main(i_dict)
    sys.exit()
