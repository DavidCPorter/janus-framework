import pip
import sys
import os
import subprocess

def main(args):
    arg_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    branch_list=arg_dict.get("--branches")
    exp_name=arg_dict.get("--name")
    home=arg_dict.get("--home")
    branch_list = branch_list.split(',')
    output = subprocess.run(['mkdir', home + '/experiments/' + exp_name ], capture_output=True)


    for i in branch_list:
        output = subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i], capture_output=True)
        subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i+'/env'])
        subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i+'/load'])
        subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i+'/pipeline'])
        subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i+'/service'])
        subprocess.run(['mkdir', home+'/experiments/'+exp_name+'/'+i+'/viz'])

if __name__ == '__main__':
    main(sys.argv[2:])
    sys.exit()

