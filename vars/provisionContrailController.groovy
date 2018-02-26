def call(vmwareConfig, controllerIP) {
    ansiblePlaybook  playbook: 'CentOS-provision.yml',
                     extraVars: controllerIP,
                     extras: '-e @vmware-vm.vars'
}
