#!/usr/bin/env python
import atexit
import argparse
import getpass
from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim, vmodl

import vmware_common as vm


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

    parser.add_argument('--vm-password',
                        required=False,
                        default=None,
                        action='store',
                        help='Password to set for Administrator on Windows')

    args = parser.parse_args()

    if not args.password:
        args.password = getpass.getpass(
            prompt='Enter password')

    return args


def get_vm_network_interfaces(vm=None):
    if vm is None:
            return []

    device_list = []
    for device in vm.config.hardware.device:
        if isinstance(device, vim.vm.device.VirtualPCNet32) or \
           isinstance(device, vim.vm.device.VirtualVmxnet2) or \
           isinstance(device, vim.vm.device.VirtualVmxnet3) or \
           isinstance(device, vim.vm.device.VirtualE1000) or \
           isinstance(device, vim.vm.device.VirtualE1000e) or \
           isinstance(device, vim.vm.device.VirtualSriovEthernetCard):
            device_list.append(device)

    return device_list


def get_nic_with_updated_network(content, nic_device, network_name):
    nic = vim.vm.device.VirtualDeviceSpec()

    nic.operation = vim.vm.device.VirtualDeviceSpec.Operation.edit
    nic.device = nic_device
    nic.device.deviceInfo = vim.Description()

    pg_obj = vm.get_obj(content, [vim.dvs.DistributedVirtualPortgroup], network_name)

    dvs_port_connection = vim.dvs.PortConnection()
    dvs_port_connection.portgroupKey = pg_obj.key
    dvs_port_connection.switchUuid = pg_obj.config.distributedVirtualSwitch.uuid
    nic.device.backing = vim.vm.device.VirtualEthernetCard.DistributedVirtualPortBackingInfo()
    nic.device.backing.port = dvs_port_connection

    return nic


def deploy_vm_from_template(service_instance, datacenter_name, cluster_name, template_name,
                            destination_folder, build_id, mgmt_network_name,
                            data_network_name, data_ip_address, data_netmask,
                            vm_name, vm_password, vm_org='Contrail',
                            vm_administrator='Administrator'):
    connection = vm.get_connection_data(service_instance, datacenter_name, cluster_name)

    template = vm.find_vm(connection, template_name)
    folder = vm.find_vm_folder(connection, destination_folder)
    host = vm.select_destination_host_using_id(connection, build_id)
    datastore = vm.select_destination_host_datastore_by_free_space(host)

    # Create `VirtualMachineConfigSpec` - reconfigure networks
    config_spec = vim.vm.ConfigSpec()
    config_spec.deviceChange = []

    current_network_devices = get_vm_network_interfaces(template)

    eth0 = get_nic_with_updated_network(connection.content, current_network_devices[0], mgmt_network_name)
    config_spec.deviceChange.append(eth0)

    eth1 = get_nic_with_updated_network(connection.content, current_network_devices[1], data_network_name)
    config_spec.deviceChange.append(eth1)

    # Create `CustomizationSpec`
    # TODO: Refactor
    customization_spec = vim.vm.customization.Specification()

    guest_os = template.summary.config.guestId
    if 'win' in guest_os:
        identity = vim.vm.customization.Sysprep()
        identity.userData = vim.vm.customization.UserData()
        identity.userData.computerName = vim.vm.customization.FixedName()
        identity.userData.computerName.name = vm_name
        identity.userData.fullName = vm_administrator
        identity.userData.orgName = vm_org
        identity.guiUnattended = vim.vm.customization.GuiUnattended()
        identity.guiUnattended.password = vim.vm.customization.Password()
        identity.guiUnattended.password.value = vm_password
        identity.guiUnattended.password.plainText = True
        identity.identification = vim.vm.customization.Identification()
    else:
        identity = vim.vm.customization.LinuxPrep()
        identity.hostName = vim.vm.customization.FixedName()
        identity.hostName.name = vm_name
    customization_spec.identity = identity

    customization_spec.globalIPSettings  = vim.vm.customization.GlobalIPSettings()

    mgmt_guest_map = vim.vm.customization.AdapterMapping()
    mgmt_guest_map.adapter = vim.vm.customization.IPSettings()
    mgmt_guest_map.adapter.ip = vim.vm.customization.DhcpIpGenerator()

    data_guest_map = vim.vm.customization.AdapterMapping()
    data_guest_map.adapter = vim.vm.customization.IPSettings()
    data_guest_map.adapter.ip = vim.vm.customization.FixedIp()
    data_guest_map.adapter.ip.ipAddress = data_ip_address
    data_guest_map.adapter.subnetMask = data_netmask

    customization_spec.nicSettingMap = [mgmt_guest_map, data_guest_map]

    # Create `VirtualMachineRelocationSpec`
    # TODO: Refactor
    relocation_spec = vim.vm.RelocateSpec()
    relocation_spec.pool = connection.cluster.resourcePool  # `pool` argument is required when cloning a template
    relocation_spec.host = host
    relocation_spec.datastore = datastore

    # Create `VirtualMachineCloneSpec` consumed by clone template operation
    clone_spec = vim.vm.CloneSpec()
    clone_spec.powerOn = False
    clone_spec.template = False
    clone_spec.config = config_spec
    clone_spec.customization = customization_spec
    clone_spec.location = relocation_spec

    task = template.Clone(name=vm_name, folder=folder, spec=clone_spec)
    vm.wait_for_task(service_instance, task)


def main():
    args = get_args()

    try:
        build_id = int(args.build_id)

        service_instance = SmartConnectNoSSL(host=args.host, user=args.user, pwd=args.password)

        deploy_vm_from_template(service_instance,
                                datacenter_name=args.datacenter,
                                cluster_name=args.cluster,
                                template_name=args.template,
                                destination_folder=args.folder,
                                build_id=build_id,
                                mgmt_network_name=args.mgmt_network,
                                data_network_name=args.data_network,
                                data_ip_address=args.data_ip_address,
                                data_netmask=args.data_netmask,
                                vm_name=args.name,
                                vm_password=args.vm_password)
    except Exception as err:
        # TODO: Handle errors
        raise

    Disconnect(service_instance)

if __name__ == "__main__":
    exit(main())
