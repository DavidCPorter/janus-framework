import pip
import sys
import os
import subprocess
import _ssh_import as ssh_import
from typing import List, Set, Any
from llist import dllist, dllistnode

import pdb
import yaml
from collections import OrderedDict
from more_itertools import powerset



class Vars:
    def __init__(self, name, root_module_path, branch_name, inverted_stage_mapping):
        self.module_name = name
        self.user_variables = {}
        self.root_path = root_module_path
        self.branch_name = branch_name
        self.inverted_modules = {}
        self.host_play_map = {}
        variable_defaults_yaml = self.root_path + '/' + inverted_stage_mapping.get(
            self.module_name) + '/' + self.module_name + '/defaults/main.yml'

        with open(variable_defaults_yaml) as f:
            default_variables = yaml.safe_load(f)
            self.default_variable_keys = default_variables.keys()



    def add_variables(self, variable_dict):
        self.user_variables.update(variable_dict)

    # when you add a module to branch(es) vars object is created and attached to module with orderd default keys to assist in dfs flow at runtime.
    # def order_keys(self):




class Module:
    # _available modules is updated by Exp when exp is launched... not the best design but nbd
    _available_module_names = []
    _root_path = ''
    _inverted_stage_module = {}

    def __init__(self, name, branch_name):
        if name in self._available_module_names:
            self.name = name
            self.play_order = OrderedDict()
            self.variables = Vars(name, self._root_path, branch_name, self._inverted_stage_module)
            self.inverted_variable_module = {}
            for var in self.variables.default_variable_keys:
                self.inverted_variable_module.update({var: name})

            self.play_order.update(Experiment._module_play_order.get(name))


        else:
            print("module does not exist")


class Branch:

    def __init__(self, name):
        # probably should have implemented modules as a linkedlist... i'm going to keep dict functionality and just build out the ordering in a separate linkedlist
        self.ordered_mods = dllist()
        self.modules = {}
        self.name = name
        self.inverted_var_to_mod_lookup = {}
    def ls(self, cmd, with_options=False):

        print(f'\n\nbranch_name = {self.name} \n')
        # need to implement an ansible variable run here to get exp variables.
        if with_options:
            pass
        else:
            for module_name, module in self.modules.items():
                stage = module._inverted_stage_module.get(module_name)
                print(f'  stage = {stage} \n   module_name = {module_name} \n')
                if cmd == 'vars':
                    print(
                        f'user-entered variables: {module.variables.user_variables} \n\n\n default variable keys: {module.variables.default_variable_keys} \n\n\n')
                    ansible_command = ['ansible-playbook', '-i', './local_var_inventory', '../variable_main.yml', '--extra-vars',
                                       'stage=' + stage + ' module=' + module_name + ' hosts_ui=' + self.name]
                    # print(ansible_command)
                    # output = subprocess.run( ansible_command, capture_output=True)
                    # print(output.stdout)
                    # print(output.stderr)

    def create_branch_dir(self):
        output = subprocess.run(['mkdir', self.name], capture_output=True)
        output.check_returncode()
        subprocess.run(['mkdir', self.name + '/env'])
        subprocess.run(['mkdir', self.name + '/load'])
        subprocess.run(['mkdir', self.name + '/pipeline'])
        subprocess.run(['mkdir', self.name + '/service'])
        subprocess.run(['mkdir', self.name + '/viz'])
        with open(self.name + '/mod_order.yml', 'w+') as f:
            yaml.safe_dump({'module_order': None}, f)

    def remove_branch_dir(self):
        output = subprocess.run(['rm', '-rf', self.name], capture_output=True)
        output.check_returncode()

    def add_modules(self, module_name_list: OrderedDict):
        for module_name, plays_dict in module_name_list.items():
            if module_name in Module._available_module_names and module_name not in self.modules.keys():
                self.modules.update({module_name: Module(module_name, self.name)})
                mod = self.modules.get(module_name)
                # update the module playorder for flow (play_dict is a mapping of plays to local_var_inventory hostname [all] is default)
                mod.play_order.update(plays_dict)
                # when we add a module, we automatically add an inverted var-to-module mapping for all the module variables and add it to self.inverted_var_to_mod_lookup table so we can use it when applying variable updates without asking the user to specify the module or stage. THIS IMPLIES ALL VARIABLES ARE UNIQUE! when variable names start overlapping we can add a namespace by default, but I'm going to hold off on that for the time being.
                var_to_mod_dict = mod.inverted_variable_module
                self.inverted_var_to_mod_lookup.update(var_to_mod_dict)
                self.order_modules('include', [module_name])

            else:
                print(f'{module_name} does not exist in r_modules or module already in branch')

    def rm_module(self, module_name_list: List):
        for module_name in module_name_list:
            if module_name in Module._available_module_names and module_name in self.modules.keys():
                self.modules.pop(module_name)
                self.order_modules('remove', list(module_name))
            else:
                print(f'{module_name} module not in branch')

    # updating branch vars through module instance
    def update_branch_vars(self, vars):
        var_dict = {vars[x]: vars[x + 1] for x in range(0, len(vars) - 1) if x % 2 == 0}

        try:
            # for each variable user wishes to update on this branch, grab the module associated with it, update the
            # corresponding variable dictionary for that module with the singe variable update. Repeat
            for key in var_dict.keys():
                # to remove 'ui_' for lookup
                # pdb.set_trace()
                mod = self.inverted_var_to_mod_lookup.get(key[3:])
                mod_instance = self.modules.get(mod)
                mod_instance.variables.add_variables({key: var_dict.get(key)})
                # for task ordering key needs to be _mod_name: {play: host}

                # there are other ways to update through modules, but this is the first that came to mind. just read
                # from current yaml file every time first in lieu of reading from mod_sintance.varianble.user_variables
                with open(self.name + '/user_variables.yml', 'r') as f:
                    cur_file = yaml.safe_load(f)

                    if cur_file is None:
                        cur_file = dict()

                    cur_file.update({key: var_dict.get(key)})

                if cur_file:
                    with open(self.name + '/user_variables.yml', 'w') as f:
                        yaml.safe_dump(cur_file, f)


        except (RuntimeError, TypeError, NameError) as e:
            print("error -> ", e)

    def order_modules(self, action, mod_name_list_arg: List):
        mod_name_list = [dllistnode(x) for x in mod_name_list_arg]
        # this is dumb... i was trying to save time using a llist library, and it was a travesty. there is no point
        # to that library.  you have to implement the logic of getting the node before you can do anyting with it
        # which isnt' hard but is really annoying to have to discover from the terrible docs.
        # should have used ordered dict
        if action == 'remove':
            for mod_name in mod_name_list:
                self.ordered_mods.remove(mod_name)
        elif action == 'include':
            last_node = mod_name_list.pop()
            if last_node.value not in self.ordered_mods:
                self.ordered_mods.appendright(last_node)
                before_node = self.ordered_mods.last
            else:
                index = 0
                for sob in self.ordered_mods:
                    if last_node.value == sob:
                        before_node = self.ordered_mods.nodeat(index)
                        break
                    index += 1
            for mod_name in mod_name_list:
                index = 0
                # remove modules from their previous order and place in front of last node
                for sob in self.ordered_mods:
                    if mod_name.value == sob:
                        node = self.ordered_mods.nodeat(index)
                        self.ordered_mods.remove(node)
                        index = 0
                        continue
                    index += 1

            for mod_name in mod_name_list:
                self.ordered_mods.insert(mod_name, before_node)

        write_list = [x for x in self.ordered_mods]
        modorder_dict = dict()

        # to keep mod order consistent in and out of interactive sessions
        for m in write_list:
            mod = self.modules.get(m)
            modorder_dict.update({m: dict(mod.play_order)})

        with open(self.name + '/mod_order.yml', 'w+') as f:
           yaml.safe_dump({'module_order': modorder_dict}, default_flow_style=False, sort_keys=False, stream=f)


class Experiment():
    # if there's no reason a branch or module should encapsulate the state of something that is needed for the control of the experiment, then that state is stored as an Experiemnt cls variable as a sort of control level data point.
    _exp_dir = ''
    _parent_dir = ''
    _module_play_order = None
    _max_mods = None
    _var_play_order = None
    _mod_to_ordered_vars = None



    #         open plays sequentially and store the variables

    @classmethod
    def get_pos_of_var(cls, module_name, variable_key):
        var_order_index = cls._mod_to_ordered_vars.get(module_name)
        position = var_order_index.get(variable_key)
        return position


    def __init__(self, name, available_stages_modules, modules_root, play_order_dict, var_order_dict, branch_names):
        exp_dir = subprocess.run(['pwd'], capture_output=True)
        exp_dir = exp_dir.stdout.decode("utf-8")
        exp_dir = exp_dir.strip('\n')
        Experiment._exp_dir = exp_dir
        Experiment._parent_dir = exp_dir[:-len(name) - 1]
        self.name = name
        self.branches = {}
        for b in branch_names:
            self.add_branch(b, new_interactive=True)

        self.stages = available_stages_modules.keys()
        Module._available_module_names = [i for sublist in available_stages_modules.values() for i in sublist]
        Module._root_path = modules_root
        # create this for later reference
        self.inverted_stage_module = {}
        for i in self.stages:
            for value in available_stages_modules.get(i):
                self.inverted_stage_module.update({value: i})

        Module._inverted_stage_module = self.inverted_stage_module
        Experiment._module_play_order = play_order_dict.copy()

        for b in self.branches.values():
            with open(b.name + '/mod_order.yml', 'r') as f:
                mod_order_dict = yaml.safe_load(f)
                _mods = mod_order_dict.get('module_order')
                if _mods is not None:
                    b.add_modules(_mods)

            with open(b.name + '/user_variables.yml', 'r') as f:
                user_var_dict = yaml.safe_load(f)
                if user_var_dict is not None:
                    for k, v in user_var_dict.items():
                        b.update_branch_vars([k, v])
        Experiment._max_mods = self.get_max_mod_size_of_branches([b for b in self.branches.values()])
        self.update_var_order(var_order_dict)



    ## INSTANCE METHODS START HERE ##

    def get_max_mod_size_of_branches(self, branch_instances_list):
        max_mods = 0
        for b in branch_instances_list:
            max_mods = max(max_mods, b.ordered_mods.size)
        return max_mods


    def update_var_order(self, mod_var):
        # var order doesnt care about the order of the modules or whether the modules have been added to the experiemnt.Howver, it does care about the play order.
        self._mod_to_ordered_vars = mod_var.copy()


    def ls(self, cmd, option_dict, target_branch_names):
        for b in target_branch_names:
            branch = self.branches.get(b)
            if len(option_dict) > 0:
                print("ls var options are not available currently, please do not pass in options ")
                branch.ls(cmd, option_dict)
            else:
                # print('branch ls call')
                branch.ls(cmd)

    def rm_branch(self, name):
        b = self.branches.pop(name)
        b.remove_branch_dir()

    def add_branch(self, name, new_interactive=None):
        b = Branch(name)
        self.branches.update({name: b})
        if not new_interactive:
            b.create_branch_dir()
        return b

    def update_modules(self, cmd, module_names, target_branch_names):
        for b in target_branch_names:
            branch = self.branches.get(b)
            # when adding new modules to experiemnt, creating the ordered module dict is required to add to the
            # branch ordered_mod file
            if cmd == 'add':
                ordered_mod_name_dict = OrderedDict()
                for m in module_names:
                    play_dict = Experiment._module_play_order.get(m)
                    ordered_mod_name_dict.update({m: OrderedDict(play_dict)})
                branch.add_modules(ordered_mod_name_dict)

            elif cmd == 'rm':
                branch.rm_modules(module_names)
            elif cmd == 'order':
                print(module_names)
                branch.order_modules('include', module_names)
            else:
                print("command not found")

        self.get_max_mod_size_of_branches([b for b in self.branches.values()])



    def update_hostgroups(self, hostgroup, modulename, playname, target_branch_names):
        playnames = playname.split(',')
        for b in target_branch_names:
            branch = self.branches.get(b)
            mod = branch.modules.get(modulename)
            if playnames[0] == 'all':
                k = mod.play_order.keys()
            else:
                k = playnames
            update_dict = {x:hostgroup for x in k}
            mod.play_order.update(update_dict)
    #         write these new hosts to mod_order file... for sake of time just run this:
            branch.order_modules('include', list(branch.ordered_mods))


    def show_ordered_mods(self, target_branch_names):
        branch_instances = [self.branches.get(b) for b in target_branch_names]
        for branch in branch_instances:
            print(branch.ordered_mods)


    def update_variables(self, user_variables, target_branch_names):
        # need to get variables through branch.(modules.get_inverted
        for b in target_branch_names:
            branch = self.branches.get(b)
            branch.update_branch_vars(user_variables)

    # returns list of tuples(branch_name, module, play_to_start_from, sort_number)
    # varset_list maps to respective branches, so varset_list is reorderd and used to return a reordered respective branhces list
    def order_branches_by_var_precedence(self, varset_list, respective_branches, mod_name):
        def find_earliest_diff(self, varset, mod_name):
            earliest_diff = (9999, None)
            for var in varset:
                # remove 'ui_'
                earliest_diff = min((earliest_diff, self._mod_to_ordered_vars[mod_name][var[0][3:]]), key=lambda t: t[0])
            return earliest_diff

        # greatest var value gets precedence because that means it shares the most
        module_branch_variable_tuple = [vars_branch for vars_branch in zip(varset_list,respective_branches)]
        module_branch_variable_tuple.sort(key=lambda tup: tup[1])  # sorts in place
        return_list = []



        for b in module_branch_variable_tuple:
            varset = b[0]
            play,earliest_var_delta = find_earliest_diff(self, varset, mod_name)
            return_list.append((b[1],mod_name, play,earliest_var_delta))

        return_list.sort(key= lambda t: t[2], reverse=True)

        return return_list


        # list of tuples... each tuple represe
        #     for i in varset_list:



    def get_ordered_set(self, play_diffs, final_list):
        # each list in play_diffs contains a set of variables representing a branch that branches at same module as others in list... we need to order them by variable precedence
        return_list = []
        count= 0
        for module_varset in play_diffs:
            if len(module_varset):
                arb_bname_list = list(final_list[count])
                mod = ''
                # this is just to get the mod_name for this set
                for b in module_varset:
                    b = list(b)
                    bname = arb_bname_list[0]
                    branch = self.branches.get(bname)
                    var_tup = b[0]
                    key = var_tup[0]
                    # remove 'ui'
                    mod = branch.inverted_var_to_mod_lookup.get(key[3:])
                    # print(mod)

                # return
                return_val = self.order_branches_by_var_precedence(module_varset, arb_bname_list, mod)
                return_list.append(return_val)
            count+=1

        return return_list





    def get_play_diffs(self, module_name_index, branch_names):
        branch_instances_list = [self.branches.get(b) for b in list(branch_names)]
        tmp_dict= {}
        for b in branch_instances_list:
            if module_name_index >= len(b.ordered_mods):

                print('some branches have the exact same variables. Please address this issue by removing the superfluous branch or changing the vars')
                return 0
            mod = b.ordered_mods[module_name_index]
            mod = b.modules.get(mod)
            tmp_dict.update({b.name: mod.variables.user_variables})
        tmp = {}
        dict_list = list(tmp_dict.items())
        # seems inefficient to compare this way to find the order of plays that each branch diffs on,
        # but its easier to reason about at my current point.
        diffs_per_branch = []
        for i in range(0, len(tmp_dict)):
            k1s_diff_vars = []
            for j in range(0, len(tmp_dict)):

                if i == j:
                    continue
                k1,v1 = dict_list[i]
                k2,v2 = dict_list[j]

                k1s_diff_vars.append(set(v1.items()) - set(v2.items()))

            branch_diffs_variables_list = [var for varset in k1s_diff_vars for var in varset]
            diffs_per_branch.append(set(branch_diffs_variables_list))


        return diffs_per_branch




    # this algo will append the module level to the respective index in the branch_order list so we know which module
    # the set of branches diff on.
    def get_mod_diff_level(self, branch_order, full_branch_flow, flag=False):
        max_mods = self._max_mods
        bs_module_diff_level = []
        flag_return_list = []
        for bs in branch_order:
            flag_return_module_name = None
            max_mi = 0
            bl = [self.branches.get(b) for b in bs]
            # -1 in case calling from flag=True need correct module references
            tmp_branch = bl[-1]

            if len(bs) == 1:
                max_mi = -9999
            else:
                for mi in range(0, len(tmp_branch.ordered_mods)):
                    check = False
                    for bnames in full_branch_flow[mi]:
                        if bs.issubset(bnames):
                            max_mi = mi
                            flag_return_module_name = tmp_branch.ordered_mods[mi+1]
                            check = True
                            break
                    if check != True:

                        break

            bs_module_diff_level.append(max_mi+1)
            flag_return_list.append(flag_return_module_name)
        if flag:
            return flag_return_list

        return bs_module_diff_level




    def get_vars_to_branch_on(self, list_of_sets, full_branch_flow):
        branch_order = list_of_sets
        # the list is in correct order, however, these sets of branches are in arbitrary order
        bs_module_diff_level = self.get_mod_diff_level(branch_order, full_branch_flow)
        index = 0
        pdiffs = []
        # diff level is the module the furthest shared var module in the DAG, so we wan tot find the play diffs at that moduleindex+1
        for diff_level in bs_module_diff_level:
            # implies index is a set (more than 1 branch shares a diff at this mod level)
            if diff_level >= 0:
                # need to evaluate variables at the next level where there are variable diffs
                return_value = self.get_play_diffs(module_name_index=diff_level, branch_names=branch_order[index])
                if return_value:
                    pdiffs.append(return_value)
            else:
                # append empty list if only one branch in that set
                pdiffs.append(list())
            index+=1

        return pdiffs
    #     need to do this again for betwen sets




    #
    def get_branch_flow_order(self, branch_instances_list, list_flag):

        max_mods = self._max_mods
        basic_flow = [{b.name for b in branch_instances_list}]
        all_branches_flow = []
        for ordered_module_index in range(0, max_mods):
            tmp_dict = dict()
            # compare each module in each branch and return the branches that all match
            for b in branch_instances_list:
                mod = b.ordered_mods[ordered_module_index]
                mod = b.modules.get(mod)
                tmp_dict.update({b.name: mod.variables.user_variables})
            tmp = {}
            for k, v in tmp_dict.items():
                hv = hash(frozenset(v.items()))
                if hv not in tmp:
                    tmp[hv] = [k]
                else:
                    tmp[hv].append(k)
            maxlen = 0
            max_matching_branch_names = set()
            all_branches_flow.append([set(bs) for bs in tmp.values()])

            for i in tmp.values():
                i = set(i)
                if len(i) > maxlen:
                    max_matching_branch_names = i
                    maxlen = len(i)

            remaining_branches = basic_flow[-1]
            intersect_the_two = remaining_branches & max_matching_branch_names
            basic_flow.append(intersect_the_two)


        basic_flow_return_list = []
        previous = set()
        basic_flow.reverse()

        # this filters out the prior aggregate set of branches
        for i in basic_flow:
            branches_remaining = set(i - previous)

            if len(branches_remaining) != 0:
                basic_flow_return_list.append(branches_remaining)
            previous = branches_remaining.union(previous)

        if list_flag == 'filtered':
            return self.best_subset({b.name for b in branch_instances_list},all_branches_flow)

        return all_branches_flow




    def best_subset(self, matchingset, all_flows):
        return_list = [[] for i in all_flows]
        all_length = len(all_flows)

        # print(all_length)
        # print(return_list)

        def _best_subset(matchingset, index):
            nonlocal return_list, all_length
            if len(matchingset) == 1 or index == all_length:
                return len(matchingset)

            maxer = -999
            max_subset = None
            all_subsets = powerset(matchingset)
            all_subsets = list(all_subsets)
            all_subsets.pop(0)
            for s in all_subsets:
                contains_set = False
                for f in all_flows[index]:
                    if set(s).issubset(f):
                        contains_set = True
                        break

                if not contains_set:
                    continue

                best_sub_length = len(s) + _best_subset(s, index + 1)
                if best_sub_length > maxer:
                    maxer = best_sub_length
                    max_subset = set(s)

            return_list[index].append(max_subset)
            return len(max_subset)

        sub = _best_subset(matchingset, 0)

        count = 0
        for i in list(return_list):
            tmp = list(set(frozenset(item) for item in i))
            return_list[count] = [set(item) for item in set(frozenset(item) for item in tmp)]
            count += 1
        # print(return_list)

        count = 0
        tmp_return_list = [[] for i in all_flows]

        for i in return_list:
            # print(i)
            if len(i) == 0:
                break

            max_remaining = max(i, key=len)
            tmp_return_list[count].append(max_remaining)
            max_remaining_prevs_total = set(max_remaining)
            while max_remaining:
                max_remaining = max([set(x - max_remaining_prevs_total) for x in i])
                if len(max_remaining) == 0:
                    break
                tmp_return_list[count].append(max_remaining)
                max_remaining_prevs_total = max_remaining.union(max_remaining_prevs_total)
            count += 1

        return_list = list(tmp_return_list)
        first_rm_sequence = []
        rm_sequence = []
        for i in range(0, len(list(tmp_return_list))):
            if len(tmp_return_list[i]) ==0:
                rm_sequence.append(tmp_return_list[i])
            else:
                rm_count = 0
                for j in range(0, len(list(tmp_return_list[i]))):
                    if len(tmp_return_list[i][j]) <= 1:
                        if len(tmp_return_list[i])-rm_count == 1:
                            rm_sequence.append(tmp_return_list[i])
                        else:
                            first_rm_sequence.append((i,tmp_return_list[i][j]))
                            # need this to account for previous remove
                            rm_count+=1

        for i,j in first_rm_sequence:
            return_list[i].remove(j)

        for i in rm_sequence:
            return_list.remove(i)


        return return_list



    def get_final_mod_play_levels(self, ordered_set, full_branch_flow):
        tmp = []
        # get reference to the positions need modification
        replacements = [ordered_set[0][0]]
        count = 0
        for bs in list(ordered_set):
            if len(bs) > 1:
                tmp.append(bs[0])
                if count != 0:
                    replacements.append(ordered_set[count][0])
                tmp.append(bs[-1])
            else:

                tmp.append(bs[0])
                tmp.append(bs[0])
                if count != 0:
                    replacements.append(ordered_set[count][0])

            count+=1
        #
        ammendment_list = []
        #  dont need these
        tmp.pop(0)
        tmp.pop(-1)
        param_list = []
        branch_sets= []
        # returnrecurse resume play and module for each leader in the modset
        for i in range(0, len(tmp)-1, 2):
            param_list.append([tmp[i], tmp[i+1]])
        for i in param_list:
            branch_sets.append({i[0][0], i[1][0]})

        mod_diff = self.get_mod_diff_level(branch_sets, full_branch_flow, flag=True)
        variable_mods = self.get_vars_to_branch_on(branch_sets, full_branch_flow)
        variable_to_recurse_to = []
        for i in variable_mods:
            variable_to_recurse_to.append(i.pop())


        count=-1
        replacements_adustments = []
        for i in replacements:
            if count == -1:
                count+=1
                continue
            mod_name = mod_diff[count]
            var = variable_to_recurse_to[0].pop()
            play_name = self._mod_to_ordered_vars[mod_name][var[0][3:]][1]
            irrelevant = 999
            replacements_adustments.append((i[0], mod_name, irrelevant, play_name))
            count+=1


        return_final = []
        count = -1
        for i in ordered_set:
            if count == -1:
                count+=1
                return_final.append(i)
                continue
            i_prefix = [replacements_adustments[count]]
            return_final.append(i_prefix + i[1:])

        return [y for x in return_final for y in x]


    def prepare_experiment(self, branch_order, experiment_flag=None):
        ansible_prefix = ['ansible-playbook', '-i', self._exp_dir+'/inventory', self._parent_dir+'/main.yml']
        stage_lookup = Module._inverted_stage_module
        b_order = branch_order
        branch_index = 0
        branches_remaining = True
        experiment_name = self.name

        def tree_walker(branch, mod_llist, play_tuple_list):

            nonlocal branch_index, branches_remaining
            branches_remaining = False if branch_index == len(b_order)-1 else True
        #     pass first branch, then recurse until branch_order.next.play == current.play (after recursed)
            mod_name = mod_llist.value

            mod_instance = branch.modules.get(mod_name)
            if play_tuple_list == 'start':
                play_tuple_list = list(mod_instance.play_order.items())
            play_name = play_tuple_list[0][0]
            play_hosts = play_tuple_list[0][1]
            stage = stage_lookup.get(mod_name)
            show_vars_file =  self._exp_dir+'/'+branch.name+'/'+stage+'/'+mod_name+'.yml'
            # will need to do some more work here to help with variable dependencies on previous plays
            variable_filename = self._exp_dir+'/'+branch.name+'/'+'user_variables.yml'
            vars = 'branch_file_ui=' + variable_filename + ' hosts_ui=' + play_hosts + ' tasks_file_ui=' + play_name + ' module=' + mod_name + ' stage=' + stage + ' experiment_name=' + experiment_name + ' show_vars_file='+ show_vars_file

            if experiment_flag == 'show_vars':
                ansible_output_rc = subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'debug'])
                # if ansible_output_rc:
                #     print(ansible_output_rc)

                print(f'getting output \n\n')

                with open(show_vars_file, 'r') as f:
                    var_dict = yaml.safe_load(f)
                    print(f'branch = {branch.name} \n    stage = {stage} \n      module = {mod_name} \n\n VARS:')
                    for k,v in var_dict.items():
                        if k[0] != '_':
                            print(f'{k} = {v}')
                    print(f'***************\n\n')

                if mod_llist.next is not None:
                    tree_walker(branch, mod_llist.next, 'start')


            else:
                subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'activate'])
            # get next mod order if mod has no plays left
                if len(play_tuple_list) > 1:
                    tree_walker(branch, mod_llist, play_tuple_list[1:])
                else:
                #     get next module
                    if mod_llist.next is not None:
                        tree_walker(branch, mod_llist.next, 'start')


            # if there are no more plays or modules, then branch only if we've recursed to the correct mod_name and
            # play_name, else deactivate
            if branches_remaining:
                next_branch_tuple = b_order[branch_index+1]
                if mod_name == next_branch_tuple[1] and play_name == next_branch_tuple[3]:
                    next_branch_instance = self.branches.get(next_branch_tuple[0])
                    module_order_root = next_branch_instance.ordered_mods.first
                    # this loop is just trying to find the correct module and play, so it increments branch_index once it does and hops to the branch to begin activating states for that branch.
                    while module_order_root is not None:
                        if module_order_root.value == mod_name:
                            next_branch_module = next_branch_instance.modules.get(module_order_root.value)
                            play_order = list(next_branch_module.play_order.items())
                            count = 0
                            for play,_hosts in play_order:
                                if play == play_name:
                                    break
                                count += 1
                            play_order = play_order[count:]

                            # decativate current play once more before passing to new branch
                            if experiment_flag != 'show_vars':
                                subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'deactivate'])

                            branch_index+=1
                            print(f'------- BRANCH INITIATED -------\n\n')
                            print(next_branch_instance, module_order_root, play_order)
                            print(f'--------------------------------\n\n')
                            return tree_walker(next_branch_instance, module_order_root, play_order)
                        else:
                            module_order_root = module_order_root.next

            # if we are just showing variables, we do not need to do run anything when we recurse.
            if experiment_flag == 'show_vars':
                return
            # recurse if no more plays or modules or branches matching play and module
            return subprocess.run(ansible_prefix + ['--extra-vars', vars, '--tags', 'deactivate'])


        first_branch = self.branches.get(branch_order[0][0])
        mod_start = first_branch.ordered_mods.first
        return tree_walker, first_branch, mod_start, 'start'


