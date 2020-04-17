import pip
import sys
import os
import subprocess
import oysterutils as OysterUtils
import _ssh_import as ssh_import
from yaml import load, dump


class Vars():
    def __init__(self,name,root_module_path, branch_name,inverted_mapping):
        self.module_name = name
        self.user_variables = {}
        self.root_path = root_module_path
        self.branch_name = branch_name
        self.inverted_modules = {}
        variable_defaults_yaml = self.root_path+'/'+inverted_mapping.get(self.module_name)+'/'+self.module_name+'/defaults/main.yml'
        f = open(variable_defaults_yaml)
        default_variables = load(f)
        self.default_variable_keys = default_variables.keys()


        
    def add_variable(self,key,value):
        self.user_variables.update({key:value})
        
        
        
    #
    # def show_variables(self, ):
    #
    #     output = subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', "utils," + tags])

        
        








class Module():
    _available_modules = []
    _root_path = ''
    _inverted_stage_module={}
    def __init__(self,name,branch_name):
        if name in self._available_modules:
            self.name = name
            self.variables = Vars(name,self._root_path,branch_name)
            self.inverted_stage_module={}
            for var in self.variables.default_variable_keys:
                self.inverted_variable_module.update({ var : name })


        else:
            print("module does not exist")
            





class Branch():

    def __init__(self,name):
        self.modules = {}
        self.create_branch_dir(name)
        self.name=name
        self.inverted_lookup = {}

    def create_branch_dir(self,name):
        output = subprocess.run(['mkdir', name], capture_output=True)
        output.check_returncode()
        subprocess.run(['mkdir', name + '/env'])
        subprocess.run(['mkdir', name + '/load'])
        subprocess.run(['mkdir', name + '/pipeline'])
        subprocess.run(['mkdir', name + '/service'])
        subprocess.run(['mkdir', name + '/viz'])

    def remove_branch_dir(self, name):
        output = subprocess.run(['rm', '-rf', name],capture_output=True)
        output.check_returncode()



    def add_module(self,module_name):
        if module_name in Module._available_modules and module_name not in self.modules.keys():
            self.modules.update({module_name: Module(module_name,self.name)})
            mod = self.modules.get(module_name)
            var_to_mod_dict = mod.self_inverted_variable_module
            self.inverted_lookup.update(var_to_mod_dict)
            

    def rm_module(self,module_name):
        if module_name in Module._available_modules and module_name in self.modules.keys():
            self.modules.pop(module_name)
            
    # updating branch vars through module instance
    def update_branch_vars(self, vars):
        var_dict = {vars[x]: vars[x + 1] for x in range(0, len(vars) - 1) if x % 2 == 0}

        for key in var_dict.keys():
            mod = self.inverted_lookup.get(key)
            mod_instance = self.modules.get(mod)
            mod_instance.variables.user_variables.update({key : var_dict.get(key)})



            

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
        Module._available_modules = [i for sublist in available_stages_modules.values() for i in sublist]
        Module._root_path = modules_root
        # create this for later reference
        self.inverted_stage_module={}
        for i in self.stages:
            for value in available_stages_modules.get(i):
                self.inverted_stage_module.update({value: i})

        Module._inverted_stage_module = self.inverted_stage_module
        
    
    def getBranches(self,ansible_notation):
        branch_list = ansible_notation.split('!')

        if len(branch_list) == 2:
            b_list = self.branches.keys()
            for b in branch_list[1].split(','):
                b_list.remove(b)
            return b_list

        elif ansible_notation == 'all':
            return self.branches.keys()
       
        else:
            b_list = self.branches.keys()
            b = branch_list.split(',')
            return_list = []
            for branch in b:
                if branch in b_list:
                    return_list.append(branch)
                else:
                    print("branch name does not match")
                    return 
            return return_list
            
            
                    
    def rm_branch(self, name):
       self.branches.pop()


    def add_branch(self,name):
        b = Branch(name)
        self.branches.update({name:b})


    def update_modules(self,cmd,module_names,ansible_branches_notation='all'):
        branch_list = self.getBranches(ansible_branches_notation)
        for b in branch_list:
            branch = self.branches.get(b)
            if cmd == 'add':
                branch.add_module(module_names)
            elif cmd == 'rm':
                branch.rm_module(module_names)
            else:
                print("command not found")
                    
    def update_variables(self,user_variables,ansible_branches_notation='all'):
        # need to get variables through branch.(modules.get_inverted
        branch_list = self.getBranches(ansible_branches_notation)
        
        for b in branch_list:
            branch = self.branches.get(b)
            branch.update_branch_vars(user_variables)

