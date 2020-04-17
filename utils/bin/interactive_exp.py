import pip
import sys
import os
import subprocess
import oysterutils as OysterUtils
import _ssh_import as ssh_import
from _branch_class.py import Experiment

def commandDispatcher(exp_dict):
    name = exp_dict.get('--name')
    home_dir= exp_dict.get('--home')
    r_modules = home_dir+'/r_modules'
    stages = ['env','load','pipeline','service','viz']
    available_modules={stages[x]:list() for x in range(0, len(stages))}
    for stage in os.scandir(r_modules):
        if stage.name in stages:
            available_modules.update({stage.name: [x.name for x in os.scandir(stage.path)]})
    branches=[]

    for branch in os.scandir('.'):
        if branch.is_dir():
            branches.append(branch.name)

    # create a hostfile that ~/.ssh/config includes temporarily that treats branches as a host so you can apply var updates to them all... just my preferred way to keep tabs on all var updates for the exp.
    for branch in branches:
        ssh_import.new_branch(branch,exp_dict.get('--home_user'),home_dir)

    # make inventory file for vars
    ssh_import.new_inventory(branches,exp_dict.get('--home_user'))

    # experiment_modules

    experiment = Experiment(name,available_modules,r_modules)




    def cmdFetcher(command):
        def ls(vars):
            nonlocal experiment
            if vars[0] == 'modules':
                print(available_modules.values())

            if vars[0] == 'vars':
                vars.pop()

        def add(vars):
            if len(vars) != 3:
                print("vars incorrect", vars)
                return

            nonlocal experiment
            if vars[0] == 'branch':
                experiment.add_branch(vars[1])
                branches.append(vars[1])
                print('success')

            if vars[0] == 'modules' or vars[0] == 'module':
                experiment.update_modules('add',vars[1].split(','),vars[2])

            if vars[0] == 'vars':
                user_variables = vars[1:-1]
                ansible_groups = vars[-1]
                experiment.update_variables(user_variables, ansible_groups,)


        def rm(vars):
            nonlocal experiment
            if vars[0] == 'branch':
                experiment.rm_branch(vars[1])
                branches.remove(vars[1])
                print('success')



        decorated_command = dict(add=add, rm=rm, ls=ls)

        return_function = decorated_command.get(command)

        return return_function
    return cmdFetcher


def main(interactive_dict):
    print(interactive_dict)
    os.chdir(str(interactive_dict.get('--home'))+'/experiments/'+str(interactive_dict.get('--name')))

    experiment_context = commandDispatcher(interactive_dict)
    user_command = input('> ')
    while user_command != 'exit':
        user_command_list = user_command.split(' ')
        cmd = experiment_context(user_command_list[0])
        cmd(user_command_list[1:])
        user_command = input('> ')


if __name__ == '__main__':
    print(sys.argv)
    args = sys.argv[1:]
    i_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    main(i_dict)
    sys.exit()
