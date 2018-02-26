def call(vmwareConfig, inventoryFilePath) {
    dir('ansible') {
        ansiblePlaybook inventory: 'inventory',
                        playbook: 'vmware-destroy-testenv.yml',
                        extraVars: vmwareConfig,
                        extras: '-e @vmware-vm.vars'
    }
}
