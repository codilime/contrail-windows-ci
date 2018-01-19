function Get-TestConfiguration {
    [TestConfiguration] @{
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
        DockerDriverConfiguration = [DockerDriverConfiguration] @{
            Username = "admin";
            Password = "secret123";
            AuthUrl = "http://10.7.0.54:5000/v2.0";
            TenantConfiguration = [TenantConfiguration] @{
                Name = "ci_tests";
                DefaultNetworkName = "testnet1";
                SingleSubnetNetwork = [NetworkConfiguration] @{
                    Name = "testnet1";
                    Subnets = @("10.0.0.0/24");
                }
                MultipleSubnetsNetwork = [NetworkConfiguration] @{
                    Name = "testnet2";
                    Subnets = @("192.168.1.0/24", "192.168.2.0/24");
                }
                NetworkWithPolicy1 = [NetworkConfiguration] @{
                    Name = "testnet3";
                    Subnets = @("10.0.1.0/24");
                }
                NetworkWithPolicy2 = [NetworkConfiguration] @{
                    Name = "testnet4";
                    Subnets = @("10.0.2.0/24");
                }
            }
        }
    }
}

function Get-SnatConfiguration {
    # TODO un-env this
    [SNATConfiguration] @{
        EndhostIP = $Env:SNAT_ENDHOST_IP;
        VethIP = $Env:SNAT_VETH_IP;
        GatewayIP = $Env:SNAT_GATEWAY_IP;
        ContainerGatewayIP = $Env:SNAT_CONTAINER_GATEWAY_IP;
        EndhostUsername = $Env:SNAT_ENDHOST_USERNAME;
        EndhostPassword = $Env:SNAT_ENDHOST_PASSWORD;
        DiskDir = $Env:SNAT_DISK_DIR;
        DiskFileName = $Env:SNAT_DISK_FILE_NAME;
        VMDir = $Env:SNAT_VM_DIR;
    }
}