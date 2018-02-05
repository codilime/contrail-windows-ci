import os
import time
from collections import namedtuple
from pyVmomi import vim


ConnectionData = namedtuple('ConnectionData', ['content', 'datacenter', 'cluster'])


def get_obj(content, vim_type, name, folder=None):
    if not isinstance(vim_type, list):
        vim_type = [vim_type]
    if not folder:
        folder = content.rootFolder
    container = content.viewManager.CreateContainerView(folder, vim_type, True)
    return next((obj for obj in container.view if obj.name == name), None)


def get_connection_data(service_instance, datacenter_name, cluster_name):
    content = service_instance.RetrieveContent()

    datacenter = get_obj(content, [vim.Datacenter], datacenter_name)
    if not datacenter:
        raise Exception("Couldn't find the Datacenter with the provided name "
                        "'{}'".format(datacenter_name))

    cluster = get_obj(content, [vim.ClusterComputeResource], cluster_name,
                      datacenter.hostFolder)
    if not cluster:
        raise Exception("Couldn't find the Cluster with the provided name "
                        "'{}'".format(cluster_name))

    return ConnectionData(content=content, datacenter=datacenter, cluster=cluster)


def find_vm(conn, vm_name):
    vm = get_obj(conn.content, [vim.VirtualMachine], vm_name, conn.datacenter.vmFolder)
    if not vm:
        raise Exception("Couldn't find the VirtualMachine with the provided name "
                        "'{}'".format(vm_name))
    return vm


def find_vm_folder(conn, folder_path):
    inventory_path = os.path.join(conn.datacenter.name, 'vm', folder_path)
    folder = conn.content.searchIndex.FindByInventoryPath(inventory_path)
    if not folder:
        raise Exception("Couldn't find the Folder with the provided name "
                        "'{}'".format(folder_path))
    return folder


def select_destination_host_using_id(conn, build_id):
    hosts = conn.cluster.host

    hosts = sorted(hosts, key=lambda h: h.name)
    dest_host_index = build_id % len(hosts)
    dest_host = hosts[dest_host_index]

    return dest_host


def select_destination_host_datastore_by_free_space(host):
    datastores = [d for d in host.datastore if 'ssd' in d.name]
    datastores = sorted(datastores, key=lambda d: d.summary.freeSpace)
    dest_datastore = datastores[-1]
    return dest_datastore


def wait_for_task(conn, task):
    while task.info.state in ['queued', 'running']:
        time.sleep(1)

    # TODO: More logging?
    if task.info.state != 'success':
        raise Exception("Task has failed")
