def call(vmwareConfig, controllerIP) {
    dir('ansible') {
        ansiblePlaybook  playbook: 'controllerProvision.yml',
                         extraVars: controllerIP,
                         extras: '-e @vmware-vm.vars'
    }
}
