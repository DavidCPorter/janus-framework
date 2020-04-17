import pip
import sys
import os
import subprocess

def main(args):
    print(args)
    arg_dict = {args[x]: args[x + 1] for x in range(0, len(args) - 1) if x % 2 == 0}
    exp_name=arg_dict.get("--name")
    home=arg_dict.get("--home")
    output = subprocess.run(['rm', '-rf', home + '/experiments/' + exp_name ], capture_output=True)

if __name__ == '__main__':
    # print (sys.argv)
    main(sys.argv[2:])
    sys.exit()

