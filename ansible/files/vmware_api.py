import os
import ssl
import getpass
import argparse
from pyVmomi import vim


class ResourceNotFound(Exception):
    pass


class IncorrectArgument(Exception):
    pass


class VmwareArgumentParser(object):
    def __init__(self, description='Arguments for talking to vCenter'):
        self.parser = argparse.ArgumentParser(description=description)

        self.parser.add_argument('--host',
                                 required=True,
                                 action='store',
                                 help='vSphere service to connect to')

        self.parser.add_argument('--user',
                                 required=True,
                                 action='store',
                                 help='Username used to connect to vSphere')

        self.parser.add_argument('--password',
                                 required=False,
                                 action='store',
                                 help='Password used to connect to vSphere')

        self.parser.add_argument('--datacenter',
                                 required=True,
                                 action='store')


    def add_argument(self, *args, **kwargs):
        self.parser.add_argument(*args, **kwargs)


    def parse_args(self):
        args = self.parser.parse_args()

        if not args.password:
            args.password = getpass.getpass(prompt='Enter password: ')

        return args


class VmwareApi(object):
    def __init__(self, si, datacenter_name, cluster_name):
        self.si = si
        self.content = None
        self.datacenter = None
        self.cluster = None
        self._setup_common_objects(datacenter_name, cluster_name)


    def get_vm(self, name):
        return self.get_vc_object(vim.VirtualMachine, name, self.datacenter.vmFolder)


    def get_vm_folder(self, folder_path):
        inventory_path = os.path.join(self.datacenter.name, 'vm', folder_path)
        return self.content.searchIndex.FindByInventoryPath(inventory_path)


    def select_destination_host_and_datastore_by_free_space(self):
        datastores = [d for d in self.datacenter.datastore if 'ssd' in d.name]
        if len(datastores) == 0:
            return None, None
        datastores = sorted(datastores, key=lambda d: d.info.freeSpace)
        chosen_datastore = datastores[-1]
        chosen_host = chosen_datastore.host[0].key
        return chosen_host, chosen_datastore


    def _setup_common_objects(self, datacenter_name, cluster_name):
        self.content = self.si.RetrieveContent()

        self.datacenter = self.get_vc_object(vim.Datacenter, datacenter_name)
        if not self.datacenter:
            raise ResourceNotFound("Couldn't find the Datacenter with the provided name "
                                   "'{}'".format(datacenter_name))

        self.cluster = None
        if cluster_name:
            self.cluster = self.get_vc_object(vim.ClusterComputeResource, cluster_name,
                                               self.content.rootFolder)
            if not self.cluster:
                raise ResourceNotFound("Couldn't find the Cluster with the provided name "
                                       "'{}'".format(cluster_name))
        else:
            clusters = self._get_vc_objects_of_type(vim.ClusterComputeResource,
                                                    self.content.rootFolder)
            self.cluster = next(iter(clusters), None)
            if not self.cluster:
                raise ResourceNotFound("Couldn't find any compute clusters")


    def get_vc_object(self, vimtype, name, folder=None):
        objects = self._get_vc_objects_of_type(vimtype, folder)
        return next((obj for obj in objects if obj.name == name), None)


    def _get_vc_objects_of_type(self, vimtype, folder=None):
        assert self.content is not None

        if not folder:
            folder = self.content.rootFolder
        container = self.content.viewManager.CreateContainerView(folder, [vimtype], True)
        return list(container.view)


def _get_vm_network_interfaces(vm):
    return [d
            for d in vm.config.hardware.device
            if isinstance(d, vim.vm.device.VirtualEthernetCard)]


def _get_network_device_change_spec(api, old_device, network_name):
    pg_obj = api.get_vc_object(vim.dvs.DistributedVirtualPortgroup, network_name)
    if not pg_obj:
        raise ResourceNotFound("Couldn't find the port group with provided name "
                               "'{}'".format(network_name))
    dvs_port_connection = vim.dvs.PortConnection()
    dvs_port_connection.portgroupKey = pg_obj.key
    dvs_port_connection.switchUuid = pg_obj.config.distributedVirtualSwitch.uuid

    spec = vim.vm.device.VirtualDeviceSpec()
    spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.edit
    spec.device = old_device
    spec.device.backing = vim.vm.device.VirtualEthernetCard.DistributedVirtualPortBackingInfo()
    spec.device.backing.port = dvs_port_connection

    return spec


def get_vm_config_spec(api, vm, networks):
    vm_network_devices = _get_vm_network_interfaces(vm)
    if len(vm_network_devices) != len(networks):
        raise IncorrectArgument("Number of VM's network interfaces does not match "
                                "a number of provided networks")

    config_spec = vim.vm.ConfigSpec()
    config_spec.deviceChange = [_get_network_device_change_spec(api, dev, network)
                                for dev, network in zip(vm_network_devices, networks)]

    return config_spec


def _get_vm_customization_identity_spec(vm, name, org, username, password):
    identity = None
    guest_os = vm.summary.config.guestId
    if 'win' in guest_os:
        identity = vim.vm.customization.Sysprep()
        identity.userData = vim.vm.customization.UserData()
        identity.userData.computerName = vim.vm.customization.FixedName()
        identity.userData.computerName.name = name
        identity.userData.fullName = username
        identity.userData.orgName = org
        identity.guiUnattended = vim.vm.customization.GuiUnattended()
        identity.guiUnattended.password = vim.vm.customization.Password()
        identity.guiUnattended.password.value = password
        identity.guiUnattended.password.plainText = True
        identity.identification = vim.vm.customization.Identification()
    else:
        identity = vim.vm.customization.LinuxPrep()
        identity.hostName = vim.vm.customization.FixedName()
        identity.hostName.name = name
    return identity


def _get_vm_customization_adapter_map(data_ip_address, data_netmask):
    mgmt_guest_map = vim.vm.customization.AdapterMapping()
    mgmt_guest_map.adapter = vim.vm.customization.IPSettings()
    mgmt_guest_map.adapter.ip = vim.vm.customization.DhcpIpGenerator()

    data_guest_map = vim.vm.customization.AdapterMapping()
    data_guest_map.adapter = vim.vm.customization.IPSettings()
    data_guest_map.adapter.ip = vim.vm.customization.FixedIp()
    data_guest_map.adapter.ip.ipAddress = data_ip_address
    data_guest_map.adapter.subnetMask = data_netmask

    return [mgmt_guest_map, data_guest_map]


def get_vm_customization_spec(template, name, org, username, password, data_ip_address, data_netmask):
    customization_spec = vim.vm.customization.Specification()
    customization_spec.globalIPSettings  = vim.vm.customization.GlobalIPSettings()

    customization_spec.identity = _get_vm_customization_identity_spec(template, name, org, username, password)
    customization_spec.nicSettingMap = _get_vm_customization_adapter_map(data_ip_address, data_netmask)

    return customization_spec


def get_vm_relocate_spec(cluster, host, datastore):
    relocate_spec = vim.vm.RelocateSpec()
    relocate_spec.pool = cluster.resourcePool
    relocate_spec.host = host
    relocate_spec.datastore = datastore
    return relocate_spec


def get_vm_clone_spec(config_spec, customization_spec, relocate_spec):
    clone_spec = vim.vm.CloneSpec()
    clone_spec.powerOn = True
    clone_spec.template = False
    clone_spec.config = config_spec
    clone_spec.customization = customization_spec
    clone_spec.location = relocate_spec
    return clone_spec


def get_connection_params(args):
    context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    context.verify_mode = ssl.CERT_NONE
    params = {
        'host': args.host,
        'user': args.user,
        'pwd': args.password,
        'sslContext': context
    }
    return params
