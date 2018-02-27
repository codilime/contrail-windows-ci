def call(actionToRun) {
    def vmwareConfig
    def demoEnvName
    def demoEnvFolder
    def mgmtNetwork
    def dataNetwork
    def inventoryFilePath

    pipeline {
        agent { label "ansible" }

        environment {
            // `VC` has to be defined in outer scope to properly
            // strip credentials from logs in all child scopes (all stages).
            // Please do not move to `Prepare environment` stage.
            VC = credentials("vcenter")
        }

        stages {
            stage("Prepare environment") {
                steps {
                    script {
                        vmwareConfig = getVMwareConfig()
                        demoEnvName = env.DEMOENV_NAME
                        demoEnvFolder = "WINCI"
                        mgmtNetwork = env.DEMOENV_MGMT_NETWORK
                        dataNetwork = env.DEMOENV_DATA_NETWORK
                        inventoryFilePath = "${env.WORKSPACE}/ansible/vms.${env.BUILD_ID}"
                    }
                    prepareTestEnv(inventoryFilePath, demoEnvName, demoEnvFolder,
                                   mgmtNetwork, dataNetwork,
                                   env.TESTBED_TEMPLATE, env.CONTROLLER_TEMPLATE)
                }
            }
            stage("Run Ansible") {
                steps {
                    actionToRun(vmwareConfig, inventoryFilePath)
                }
            }
        }
    }
}
