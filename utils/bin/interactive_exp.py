import pip
import sys
import os
import subprocess
import oysterutils as OysterUtils
import _ssh_import as ssh_import

def commandDispatcher(exp_dict):
    home_dir= exp_dict.get('--home')
    stages = ['env','load','pipeline','service','viz']
    available_modules={stages[x]:list() for x in range(0, len(stages))}
    for stage in os.scandir(home_dir+'/r_modules'):
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

    all_modules=available_modules.values()
    # experiment_modules

    def cmdFetcher(command):
        def show(vars):
            print(vars)
            if vars[0] == 'modules':
                print(available_modules.values())
            if vars[0] in stages and vars[1] == "vars":
                pass

            # {vars[x]: list() for x in range(0, len(vars))}
            # print(var)

        def add(vars):
            if vars[0] == 'branch':
                OysterUtils.add_branch(vars[1])
                branches.append(vars[1])
                print('success')

        def rm(vars):
            if vars[0] == 'branch':
                OysterUtils.rm_branch(vars[1])
                branches.remove(vars[1])
                print('success')

        def ls(vars):
            if vars[0] == 'vars':
                vars.pop()


                pass





        decorated_command = dict(show=show, add=add, rm=rm, ls=ls)

        return_function = decorated_command.get(command)

        return return_function
    return cmdFetcher


def main(interactive_dict):
    print(interactive_dict)
    os.chdir(str(interactive_dict.get('--home'))+'/experiments/'+str(interactive_dict.get('--name')))
    # subprocess.run(['ls'])
    # files = os.popen('ls ' + str(interactive_dict.get('--home'))+'/experiments/'+str(interactive_dict.get('--name')+ '| grep solr1').read()
    # default_variables =
    # branch_list=arg_dict.get("--branches")
    # exp_name=arg_dict.get("--name")
    # home=arg_dict.get("--home")
    # branch_list = branch_list.split(',')
    # output = subprocess.run(['mkdir', home + '/experiments/' + exp_name ], capture_output=True)

    fetch_the_command = commandDispatcher(interactive_dict)
    user_input = input('> ')
    while user_input != 'exit':
        user_input_list = user_input.split(' ')
        cmd = fetch_the_command(user_input_list[0])
        cmd(user_input_list[1:])
        user_input = input('> ')


if __name__ == '__main__':
    print(sys.argv)
    args = sys.argv[1:]
    i_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    main(i_dict)
    sys.exit()
