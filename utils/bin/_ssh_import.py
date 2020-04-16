import sys
import os
import subprocess

def new_branch(name,homeuser,homedir):
    with open(homedir+'/utils/etc/tmp_oyster_host_file', 'a+') as f:
        f.write("\nHost "+name+"\n  hostname 0.0.0.0\n  User "+homeuser+'\n')
    return

def new_inventory(branch_names,homeuser):
    current_dir = subprocess.run(['pwd'], capture_output=True)
    current_dir = current_dir.stdout.decode("utf-8")
    with open('./inventory', 'a+') as f:
        for name in branch_names:
            f.write('\n'+'['+ name +']'+'\n'+ name +' ansible_connection=local path='+ current_dir[:-1] +'/'+ name + ' ansible_user='+homeuser+'\n')
    return
