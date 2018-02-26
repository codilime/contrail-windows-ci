def call(vmwareConfig, inventoryFilePath) {
    dir('ansible') {
        ansiblePlaybook inventory: 'inventory',
                        playbook: 'vmware-deploy-testenv.yml',
                        extraVars: vmwareConfig,
                        extras: '-e @vmware-vm.vars'
        controllerIP = parseControllerAddress(inventoryFilePath)
        ansiblePlaybook playbook: 'controllerProvision.yml',
                        extraVars: controllerIP,
                        extras: '-e @vmware-vm.vars'
    }
}
