#!/usr/bin/env python
import atexit
import argparse
import getpass
from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim, vmodl


def get_args():
    parser = argparse.ArgumentParser(description='Arguments for talking to vCenter')

    parser.add_argument('--build-id',
                        required=True,
                        type=int,
                        action='store',
                        help='vSphere service to connect to')

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

    parser.add_argument('--cluster',
                        required=False,
                        action='store',
                        help='Cluster to use')

    parser.add_argument('--template',
                        required=True,
                        action='store',
                        help='Name of the template')

    parser.add_argument('--folder',
                        required=True,
                        action='store',
                        help='Folder in which the cloned VM will be placed')

    parser.add_argument('--name',
                        required=True,
                        action='store',
                        help='Name which will be given to the cloned VM')

    args = parser.parse_args()

    if not args.password:
        args.password = getpass.getpass(
            prompt='Enter password')

    return args


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


def find_folder(content, datacenter_name, folder):
    inventory_path = '{}/vm/{}'.format(datacenter_name, folder)
    return content.searchIndex.FindByInventoryPath(inventory_path)


def select_destinations(build_id, hosts):
    hosts = sorted(hosts, key=lambda h: h.name)
    dest_host_index = build_id % len(hosts)
    dest_host = hosts[dest_host_index]

    datastores = [d for d in dest_host.datastore if 'ssd' in d.name]
    datastores = sorted(datastores, key=lambda d: d.summary.freeSpace)
    dest_datastore = datastores[-1]

    return (dest_host, dest_datastore)


def get_relocation_spec(pool, host, datastore):
    relocation_spec = vim.vm.RelocateSpec()
    relocation_spec.pool = pool
    relocation_spec.host = host
    relocation_spec.datastore = datastore
    return relocation_spec


def get_clone_spec(location):
    clone_spec = vim.vm.CloneSpec()
    clone_spec.powerOn = False
    clone_spec.template = False
    clone_spec.location = location
    return clone_spec


# Adapted from https://github.com/vmware/pyvmomi-community-samples/blob/master/samples/tools/tasks.py
def wait_for_task(service_instance, original_task):
    obj_spec = vmodl.query.PropertyCollector.ObjectSpec(obj=original_task)
    prop_spec = vmodl.query.PropertyCollector.PropertySpec(type=vim.Task, pathSet=[], all=True)

    filter_spec = vmodl.query.PropertyCollector.FilterSpec()
    filter_spec.objectSet = [obj_spec]
    filter_spec.propSet = [prop_spec]

    pc = service_instance.content.propertyCollector
    pc_filter = pc.CreateFilter(filter_spec, True)
    try:
        version, state = None, None
        while True:
            update = pc.WaitForUpdates(version)
            for filter_set in update.filterSet:
                assert len(filter_set.objectSet) == 1  # We should receive update only for one task
                obj_update = filter_set.objectSet[0]
                task = obj_update.obj

                for change in obj_update.changeSet:
                    if change.name == 'info':
                        state = change.val.state
                    elif change.name == 'info.state':
                        state = change.val
                    else:
                        continue

                if state == vim.TaskInfo.State.success:
                    break
                elif state == vim.TaskInfo.State.error:
                    raise task.info.error

            version = update.version
    finally:
        if pc_filter:
            pc_filter.Destroy()


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

    cluster = get_obj(content, [vim.ClusterComputeResource], args.cluster,
                      datacenter.hostFolder)
    if not cluster:
        raise Exception("Couldn't find the Cluster with the provided name "
                        "'{}'".format(args.cluster))

    template = get_obj(content, [vim.VirtualMachine], args.template, datacenter.vmFolder)
    if not template:
        raise Exception("Couldn't find the Template with the provided name "
                        "'{}'".format(args.template))

    folder = find_folder(content, args.datacenter, args.folder)
    if not folder:
        raise Exception("Couldn't find the Folder with the provided name "
                        "'{}'".format(args.folder))

    hosts = cluster.host
    host, datastore = select_destinations(args.build_id, hosts)

    relocation_spec = get_relocation_spec(cluster.resourcePool, host, datastore)
    clone_spec = get_clone_spec(relocation_spec)

    task = template.Clone(name=args.name, folder=folder, spec=clone_spec)
    wait_for_task(service_instance, task)

    return 0


if __name__ == "__main__":
    exit(main())
