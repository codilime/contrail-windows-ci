#!/usr/bin/env python

import atexit
import argparse
import getpass
import time
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

    parser.add_argument('--network-name',
                        required=True,
                        action='store',
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

    folder_name = '{}/{}'.format(args.folder, args.network_name)
    folder = find_folder(content, args.datacenter, folder_name)
    if not folder:
        raise Exception("Couldn't find the Folder with the provided name "
                        "'{}'".format(folder_name))

    if folder.childEntity:
        raise Exception("The folder '{}' is not empty".format(folder_name))

    task = folder.Destroy_Task()
    while task.info.state in [vim.TaskInfo.State.running, vim.TaskInfo.State.queued]:
        time.sleep(10)

    if task.info.state == vim.TaskInfo.State.error:
        try:
            raise Exception(task.info.error)
        except AttributeError:
            raise Exception("An unknown error has occurred")

    return 0


if __name__ == "__main__":
    exit(main())
