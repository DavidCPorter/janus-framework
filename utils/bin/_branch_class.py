import pip
import sys
import os
import subprocess
import _ssh_import as ssh_import
from yaml import load, dump


class Vars():
    def __init__(self,name,root_module_path, branch_name,inverted_stage_mapping):
        self.module_name = name
        self.user_variables = {}
        self.root_path = root_module_path
        self.branch_name = branch_name
        self.inverted_modules = {}
        variable_defaults_yaml = self.root_path+'/'+inverted_stage_mapping.get(self.module_name)+'/'+self.module_name+'/defaults/main.yml'

        with open(variable_defaults_yaml) as f:
            default_variables = load(f)
            self.default_variable_keys = default_variables.keys()


        
    def add_variables(self,variable_dict):
        self.user_variables.update(variable_dict)
        with open(self.branch_name+'/user_variables.yml', 'w+') as f:
            try:
                dump(self.user_variables, f)

            except (RuntimeError, TypeError, NameError) as e:
                print("error -> ", e)

        

class Module():
    # _available modules is updated by Exp when exp is launched... not the best design but nbd
    _available_module_names = []
    _root_path = ''
    _inverted_stage_module={}
    def __init__(self,name,branch_name):
        if name in self._available_module_names:
            self.name = name
            self.variables = Vars(name,self._root_path,branch_name,self._inverted_stage_module)
            self.inverted_variable_module={}
            for var in self.variables.default_variable_keys:
                self.inverted_variable_module.update({ var : name })


        else:
            print("module does not exist")
            


class Branch():

    def __init__(self,name):
        self.modules = {}
        self.name=name
        self.inverted_var_to_mod_lookup = {}


    def ls(self, cmd, with_options=False):

        print(f'\n\nbranch_name = {self.name} \n')
        # need to implement an ansible variable run here to get exp variables.
        if with_options:
            pass
        else:
            for module_name,module in self.modules.items():
                stage = module._inverted_stage_module.get(module_name)
                print(f'  stage = {stage} \n   module_name = {module_name} \n' )
                if cmd == 'vars':
                    print(f'user-entered variables: {module.variables.user_variables} \n default variable keys: {module.variables.default_variable_keys}')
                    ansible_command = ['ansible-playbook', '-i', './inventory', '../variable_main.yml', '--extra-vars', 'stage=' + stage + ' module=' + module_name+ ' hosts_ui='+self.name]
                    print(ansible_command)
                    output = subprocess.run( ansible_command, capture_output=True)
                    print(output.stdout)
                    print(output.stderr)





    def create_branch_dir(self):
        output = subprocess.run(['mkdir', self.name], capture_output=True)
        output.check_returncode()
        subprocess.run(['mkdir', self.name + '/env'])
        subprocess.run(['mkdir', self.name + '/load'])
        subprocess.run(['mkdir', self.name + '/pipeline'])
        subprocess.run(['mkdir', self.name + '/service'])
        subprocess.run(['mkdir', self.name + '/viz'])

    def remove_branch_dir(self):
        output = subprocess.run(['rm', '-rf', self.name],capture_output=True)
        output.check_returncode()



    def add_modules(self,module_name_list):
        for module_name in module_name_list:
            if module_name in Module._available_module_names and module_name not in self.modules.keys():
                self.modules.update({module_name: Module(module_name,self.name)})
                mod = self.modules.get(module_name)
                # when we add a module, we automatically add an inverted var-to-module mapping for all the module variables and add it to self.inverted_var_to_mod_lookup table so we can use it when applying variable updates without asking the user to specify the module or stage. THIS IMPLIES ALL VARIABLES ARE UNIQUE! when variable names start overlapping we can add a namespace by default, but I'm going to hold off on that for the time being.
                var_to_mod_dict = mod.inverted_variable_module
                self.inverted_var_to_mod_lookup.update(var_to_mod_dict)

            else:
                print(f'{module_name} does not exist in r_modules or module already in branch')
            

    def rm_module(self,module_name):
        if module_name in Module._available_module_names and module_name in self.modules.keys():
            self.modules.pop(module_name)
        else:
            print(f'{module_name} module not in branch')

    # updating branch vars through module instance
    def update_branch_vars(self, vars):
        var_dict = {vars[x]: vars[x + 1] for x in range(0, len(vars) - 1) if x % 2 == 0}

        for key in var_dict.keys():
            mod = self.inverted_var_to_mod_lookup.get(key)
            mod_instance = self.modules.get(mod)
            mod_instance.variables.add_variables(var_dict)



            

class Experiment():
    _exp_dir = ''
    _parent_dir = ''
    def __init__(self,name, available_stages_modules,modules_root):
        exp_dir = subprocess.run(['pwd'], capture_output=True)
        exp_dir = exp_dir.stdout.decode("utf-8")
        _exp_dir = exp_dir
        _parent_dir = exp_dir[:-len(name)+1]
        self.branches = {}
        self.stages=available_stages_modules.keys()
        Module._available_module_names = [i for sublist in available_stages_modules.values() for i in sublist]
        print(Module._available_module_names)
        Module._root_path = modules_root
        # create this for later reference
        self.inverted_stage_module={}
        for i in self.stages:
            for value in available_stages_modules.get(i):
                self.inverted_stage_module.update({value: i})

        Module._inverted_stage_module = self.inverted_stage_module
        
    
    def getBranchList(self,ansible_notation):
        branch_list = ansible_notation.split('!')
        print(branch_list)

        if len(branch_list) == 2:
            b_list = self.branches.keys()
            for b in branch_list[1].split(','):
                b_list.remove(b)
            return b_list

        elif ansible_notation == 'all':
            return self.branches.keys()
       
        else:
            b_list = self.branches.keys()
            b = ansible_notation.split(',')
            return_list = []
            for branch in b:
                if branch in b_list:
                    return_list.append(branch)
                else:
                    print("branch name does not match")
                    return 
            return return_list
            
    def ls(self, cmd, option_dict, ansible_branches_notation='all'):
        branch_list = self.getBranchList(ansible_branches_notation)
        for b in branch_list:
            branch = self.branches.get(b)
            if len(option_dict) > 0:
                print("ls var options are not available currently, please do not pass in options ")
                branch.ls(cmd, option_dict)
            else:
                branch.ls(cmd)


    def rm_branch(self, name):
        b = self.branches.pop(name)
        b.remove_branch_dir()



    def add_branch(self,name,new_interactive=None):
        b = Branch(name)
        self.branches.update({name:b})
        if not new_interactive:
            b.create_branch_dir()

    def update_modules(self,cmd,module_names,ansible_branches_notation='all'):
        branch_list = self.getBranchList(ansible_branches_notation)
        for b in branch_list:
            branch = self.branches.get(b)
            if cmd == 'add':
                branch.add_modules(module_names)
            elif cmd == 'rm':
                branch.rm_modules(module_names)
            else:
                print("command not found")
                    
    def update_variables(self,user_variables,ansible_branches_notation='all'):
        # need to get variables through branch.(modules.get_inverted
        branch_list = self.getBranchList(ansible_branches_notation)
        
        for b in branch_list:
            branch = self.branches.get(b)
            branch.update_branch_vars(user_variables)

