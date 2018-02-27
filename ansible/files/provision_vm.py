#!/usr/bin/env python
import argparse
import getpass
from pyVim.connect import SmartConnection
from pyVim.task import WaitForTask
from vmware_api import *


def get_args():
    parser = VmwareArgumentParser()

    parser.add_argument('--cluster',
                        required=False,
                        action='store',
                        help='Cluster to use (if not provided, script will choose the first one available)')

    parser.add_argument('--template',
                        required=True,
                        action='store',
                        help='VM Template used for cloning new VM')

    parser.add_argument('--folder',
                        required=True,
                        action='store',
                        help='Folder in which the cloned VM will be placed')

    parser.add_argument('--name',
                        required=True,
                        action='store',
                        help='Name which will be given to the cloned VM')

    parser.add_argument('--mgmt-network',
                        required=True,
                        action='store',
                        help='Management network for VM')

    parser.add_argument('--data-network',
                        required=True,
                        action='store',
                        help='Data-plane network for VM')

    parser.add_argument('--data-ip-address',
                        required=True,
                        action='store',
                        help='Data-plane IP address')

    parser.add_argument('--data-netmask',
                        required=True,
                        action='store',
                        help='Data-plane netmask')

    parser.add_argument('--vm-username',
                        required=False,
                        default=None,
                        action='store',
                        help='Username to setup on Windows')

    parser.add_argument('--vm-password',
                        required=False,
                        default=None,
                        action='store',
                        help='Password to set for default user on Windows')

    parser.add_argument('--customize',
                        required=False,
                        default=True,
                        action='store_false',
                        help='If set to True customization of operating system will happen')

    args = parser.parse_args()

    if args.vm_username and not args.vm_password:
        raise IncorrectArgument('If vm-username is provided, then you have to provide vm-password as well')

    if args.vm_password and not args.vm_username:
        raise IncorrectArgument('If vm-password is provided, then you have to provide vm-username as well')

    return args


def provision_vm(api, args):
    name = args.name

    template = api.get_vm(args.template)
    if not template:
        raise ResourceNotFound("Couldn't find the template with the provided name "
                               "'{}'".format(args.template))

    folder = api.get_vm_folder(args.folder)
    if not folder:
        raise ResourceNotFound("Couldn't find the folder with the provided path "
                               "'{}'".format(args.folder))

    host, datastore = api.select_destination_host_and_datastore_by_free_space()
    if not host or not datastore:
        raise ResourceNotFound('Choosing appropriate host and datastore failed')

    if args.customize:
        customization_data = {
        'name': args.name,
        'org': 'Contrail',
        'username': args.vm_username,
        'password': args.vm_password,
        'data_ip_address': args.data_ip_address,
        'data_netmask': args.data_netmask
        }
        customization_spec = get_vm_customization_spec(template, **customization_data)
    else:
        customization_spec = None

    config_spec = get_vm_config_spec(api, vm=template, networks=[args.mgmt_network, args.data_network])
    relocate_spec = get_vm_relocate_spec(api.cluster, host, datastore)
    clone_spec = get_vm_clone_spec(config_spec, customization_spec, relocate_spec)

    task = template.Clone(name=name, folder=folder, spec=clone_spec)
    WaitForTask(task)


def main():
    args = get_args()
    conn_params = get_connection_params(args)
    with SmartConnection(**conn_params) as si:
        api = VmwareApi(si, datacenter_name=args.datacenter, cluster_name=args.cluster)
        provision_vm(api, args)


if __name__ == '__main__':
    main()
