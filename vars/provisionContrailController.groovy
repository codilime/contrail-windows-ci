def call(vmwareConfig, controllerIP) {
    dir('ansible') {
        ansiblePlaybook  playbook: 'CentOS-provision.yml',
                         extraVars: controllerIP,
                         extras: '-e @vmware-vm.vars'
    }
}
