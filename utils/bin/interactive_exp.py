import pip
import sys
import os
import subprocess
import oysterutils as OysterUtils
import _ssh_import as ssh_import
from _branch_class import Experiment


def commandDispatcher(exp_dict):
    name = exp_dict.get('--name')
    home_dir = exp_dict.get('--home')
    r_modules = home_dir + '/r_modules'
    stages = ['env', 'load', 'pipeline', 'service', 'viz']
    available_modules = {stages[x]: list() for x in range(0, len(stages))}
    for stage in os.scandir(r_modules):
        if stage.name in stages:
            available_modules.update({stage.name: [x.name for x in os.scandir(stage.path)]})

    branch_names = []

    for branch in os.scandir('.'):
        if branch.is_dir():
            branch_names.append(branch.name)

    # create a hostfile that ~/.ssh/config includes temporarily that treats branches as a host so you can apply var updates to them all... just my preferred way to keep tabs on all var updates for the exp.
    for branch in branch_names:
        ssh_import.new_branch(branch, exp_dict.get('--home_user'), home_dir)

    # make inventory file for vars
    ssh_import.new_inventory(branch_names, exp_dict.get('--home_user'))

    # experiment_modules

    experiment = Experiment(name, available_modules, r_modules)
    for branch in branch_names:
        print(branch)
        experiment.add_branch(branch, new_interactive=True)

    def cmdFetcher(command, group):
        # we can do better than this, but for now this sort of ensures there is a group name as last argument or it returns. right now it assumes names are correct.
        if len(group.split('!')) != 2 or len(group.split(',')) != 2:
            if group not in set(experiment.branches.keys()) and group != 'all':
                print(f'group name \'{group}\' not valid')
                return

        def ls(vars):
            nonlocal experiment

            if len(vars) < 2:
                print('ls command requires at least two arguments: vars|modules and groups')
            if vars[0] == 'modules':
                print(available_modules.values())

            if vars[0] == 'vars':
                ansible_groups = vars.pop()
                cli_options = vars[1:]
                cli_options_dict = {cli_options[x]: cli_options[x + 1] for x in range(0, len(cli_options) - 1) if
                                    x % 2 == 0}
                experiment.ls('vars', cli_options_dict, ansible_groups)

            #
            if vars[0] == 'branches':
                print(experiment.branches)

        def add(vars):
            if len(vars) < 3:
                print(f'vars {vars} incorrect')
                return

            nonlocal experiment
            if vars[0] == 'branch':
                experiment.add_branch(vars[1])
                print('success')

            if vars[0] == 'modules' or vars[0] == 'module':
                experiment.update_modules('add', vars[1].split(','), vars[2])

            if vars[0] == 'vars':
                ansible_groups = vars.pop()
                user_variables = vars[1:]
                experiment.update_variables(user_variables, ansible_groups)

        def rm(vars):
            nonlocal experiment
            if vars[0] == 'branch':
                experiment.rm_branch(vars[1])
                print('success')

            if vars[0] == 'modules' or vars[0] == 'module':
                experiment.update_modules('rm', vars[1].split(','), vars[2])

        # oyster cmd does project operations when in interactive mode
        def oyster(vars):
            nonlocal experiment
            if vars[0] == 'add' and vars[1] == 'branch':
                add(vars[1:])
            elif vars[0] == 'ls' and vars[1] == 'branches':
                ls(vars[1:])

            else:
                print('oyster command did not match operation')


        decorated_command = dict(add=add, rm=rm, ls=ls, oyster=oyster)

        return_function = decorated_command.get(command)

        return return_function

    return cmdFetcher


def main(interactive_dict):
    print(interactive_dict)
    os.chdir(str(interactive_dict.get('--home')) + '/experiments/' + str(interactive_dict.get('--name')))

    experiment_context = commandDispatcher(interactive_dict)
    user_command = ''

    while user_command != 'exit':
        user_command = input('> ')

        if user_command == '' or user_command == 'exit':
            # print('continue')
            continue

        user_command_list = user_command.split(' ')
        try:
            cmd = experiment_context(user_command_list[0], user_command_list[-1])
            if cmd:
                cmd(user_command_list[1:])

        except (RuntimeError, TypeError, NameError) as e:
            print("error -> ", e)



if __name__ == '__main__':
    print(sys.argv)
    args = sys.argv[1:]
    i_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    main(i_dict)
    sys.exit()
