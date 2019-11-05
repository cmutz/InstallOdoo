#!/usr/bin/python3.6

import os
import sys                                                                                                                                                                                                         
path = "branch_oca.ini"
version_odoo = "10.0"
path_sources = "/opt/odoo/odoo_v10/sources/oca_addons"

with open(path, "r") as f:
    contenu = f.read().splitlines()
    print(contenu)
    for liste in contenu:
        git_command = "https://github.com/OCA/" + liste
        os.system("git clone " + git_command + " -b " + version_odoo + " " + path_sources + "/" + liste)
    
