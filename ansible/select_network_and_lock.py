#!/usr/bin/env python

import atexit
import argparse
import getpass
import time
import re
import random
from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim, vmodl


def get_args():
    parser = argparse.ArgumentParser(description='Arguments for talking to vCenter')

    parser.add_argument('--host',
                        required=True,
                        action='store',
                        help='vSphere service to connect to')

    parser.add_argument('--user',
                        required=True,
                        action='store',
                        help='User name to use')

    parser.add_argument('--password',
                        required=False,
                        action='store',
                        help='Password to use')

    parser.add_argument('--datacenter',
                        required=False,
                        action='store',
                        help='Datacenter to use')

    parser.add_argument('--folder',
                        required=True,
                        action='store',
                        help='') # TODO: fill

    parser.add_argument('--network-name-out-file',
                        required=True,
                        action='store',
                        help='') # TODO: fill

    parser.add_argument('--first-network-id',
                        required=True,
                        action='store',
                        type=int,
                        help='') # TODO: fill

    parser.add_argument('--networks-count',
                        required=True,
                        action='store',
                        type=int,
                        help='') # TODO: fill

    args = parser.parse_args()

    if not args.password:
        args.password = getpass.getpass(
            prompt='Enter password')

    return args

def find_folder(content, datacenter_name, folder):
    inventory_path = '{}/vm/{}'.format(datacenter_name, folder)
    return content.searchIndex.FindByInventoryPath(inventory_path)

# Found in https://github.com/vmware/pyvmomi-community-samples/blob/master/samples/linked_clone.py
def get_obj(content, vimtype, name, folder=None):
    obj = None
    if not folder:
        folder = content.rootFolder
    container = content.viewManager.CreateContainerView(folder, vimtype, True)
    for item in container.view:
        if item.name == name:
            obj = item
            break
    return obj

NETWORK_NAME_PATTERN = re.compile('^VLAN_([0-9]+)_TestEnv$')

def is_network_testnet(name, testnets_range):
    match = NETWORK_NAME_PATTERN.match(name)
    if not match:
        return False

    return testnets_range[0] <= int(match.group(1)) <= testnets_range[1]

def main():
    args = get_args()

    service_instance = SmartConnectNoSSL(
        host=args.host,
        user=args.user,
        pwd=args.password)
    atexit.register(Disconnect, service_instance)

    content = service_instance.RetrieveContent()

    datacenter = get_obj(content, [vim.Datacenter], args.datacenter)
    if not datacenter:
        raise Exception("Couldn't find the Datacenter with the provided name "
                        "'{}'".format(args.datacenter))

    folder = find_folder(content, args.datacenter, args.folder)
    if not folder:
        raise Exception("Couldn't find the Folder with the provided name "
                        "'{}'".format(args.folder))

    testnets_range = (args.first_network_id, args.first_network_id + args.networks_count - 1)
    available_testnets = [net.name for net in datacenter.network if is_network_testnet(net.name, testnets_range)]

    if not available_testnets:
        raise Exception("No networks available")

    random.shuffle(available_testnets)

    while True:
        for name in available_testnets:
            if not find_folder(content, args.datacenter, '{}/{}'.format(args.folder, name)):
                with open(args.network_name_out_file, 'w') as f:
                    f.write(name)

                subfolder = folder.CreateFolder(name)
                if not subfolder:
                    raise Exception("Couldn't create the Folder with the selected name "
                                    "'{}'".format(name))
                return 0

        time.sleep(10)

    return 0


if __name__ == "__main__":
    exit(main())
