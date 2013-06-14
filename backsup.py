#!/usr/bin/python

""" setting up config parser for persistence""" 

import ConfigParser
import os.path
from os.path import expanduser

''' assigning variables '''

home = expanduser('~')
hsplit = home.split('/')
dbhost = 'internal-db.s'+hsplit[2]+'.gridserver.com'
targetdir = '/home/'+hsplit[2]+'/users/.home/data/cloudtech/backup/'
script_path_arr = os.path.realpath(__file__).split(os.sep)
config_path_arr = script_path_arr[:-1] + ['.infos']
config_path = os.sep.join(config_path_arr)

''' importing additional moudules'''

from os import system
from os import stat

def config_found(filename):
    if not os.path.isfile(filename):
        return False

    config["obj"].read(filename)
    return True

def get_boolean(prompt, default=False):
    if default:
        prompt += " ([y]es/no): "
    else:
        prompt += " (yes/[n]o): "

    ans = raw_input(prompt)
    if ans.lower().find("y") == 0:
        return True
    elif ans.lower().find("n") == 0:
        return False

    return default

def get_value(itemKey, prompt, boolean=False, **kwargs):
    (section, option) = itemKey.split(".")
    if config["found"]:
        try:
            if boolean:
                return config["obj"].getboolean(section, option)
            else:
                return config["obj"].get(section, option)
        except Exception, e:
            config["found"] = False

    val = ""
    if boolean:
        val = get_boolean(prompt, kwargs.get("default", False))
    else:
        val = raw_input(prompt)

    if not config["obj"].has_section(section):
        config["obj"].add_section(section)

    config["obj"].set(section, option, str(val))

    return val

def backup_db(section):
	user = get_value(section+'.user', 'Enter database user :' ) 
	password = get_value(section+'.pass', 'Enter database password :')
	name = get_value(section+'.name', 'Enter database name :')
	system('mysqldump --add-drop-table -h'+dbhost+' -u'+user+' -p'+password+' '+ name+' > '+targetdir+name+'_$(date +%y%m%d).sql')

def backup_domain(section):
	domain = get_value(section+'.name', 'Enter domain name :')
	print 'Backing up webroot'
	dpath = home+'/domains/'+domain+'/html/'
	system('tar -zcf '+targetdir+domain+'_$(date +%y%m%d).tar.gz '+dpath)

config = { "file": config_path,
           "found": False,
           "obj": ConfigParser.SafeConfigParser(),
        }


config["found"] = config_found(config["file"])

if config["found"]:
	for s in config['obj'].sections():
		if s.find('db') == 0:
			backup_db(s)

else: 
	i = 0
	msg = "Would you like to backup a database?"
	while get_boolean(msg): 
		key="db"+str(i)
		i += 1
		msg = 'Would you like to backup another database user?' 

		backup_db(key)


if config["found"]:
	for s in config['obj'].sections():
		if s.find('domain') == 0:
			backup_domain(s)

else: 
	i = 0
	msg = "Would you like to backup a domain?"
	while get_boolean(msg): 
		key="domain"+str(i)
		i += 1
		msg = 'Would you like to backup another domain?' 

		backup_domain(key)


print "Backing up complete. You're welcome."

if not config["found"]:
    f = open(config["file"], "wb")
    config["obj"].write(f)
    f.close()
