def call(vmwareConfig, controllerIP) {
    dir('ansible/project-config') {
        //clone repos
        //copy yml
        git branch: 'master',
        url: 'https://github.com/Juniper/contrail-project-config.git'
        ansiblePlaybook  playbook: '../CentOS-provision.yml',
                         extraVars: controllerIP,
                         extras: '-e @../vmware-vm.vars'
    }


}