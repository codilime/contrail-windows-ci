@{
    ControllerIP = "10.7.0.54";
    ControllerRestPort = 8082;
    ControllerHostUsername = "ubuntu";
    ControllerHostPassword = "ubuntu";
    AdapterName = "Ethernet1";
    VMSwitchName = "Layered Ethernet1";
    VHostName = "vEthernet (HNSTransparent)"
    ForwardingExtensionName = "vRouter forwarding extension";
    AgentConfigFilePath = "C:\ProgramData\Contrail\etc\contrail\contrail-vrouter-agent.conf";
    LinuxVirtualMachineIp = "10.0.0.3";
    DockerDriverConfiguration = @{
        Username = "admin";
        Password = "secret123";
        AuthUrl = "http://10.7.0.54:5000/v2.0";
        TenantConfiguration = @{
            Name = "ci_tests";
            DefaultNetworkName = "testnet1";
            SingleSubnetNetwork = @{
                Name = "testnet1";
                Subnets = @("10.0.0.0/24");
            }
            MultipleSubnetsNetwork = @{
                Name = "testnet2";
                Subnets = @("192.168.1.0/24", "192.168.2.0/24");
            }
            NetworkWithPolicy1 = @{
                Name = "testnet3";
                Subnets = @("10.0.1.0/24");
            }
            NetworkWithPolicy2 = @{
                Name = "testnet4";
                Subnets = @("10.0.2.0/24");
            }
        }
    }
}