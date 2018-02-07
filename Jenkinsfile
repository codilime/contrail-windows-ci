library "contrailWindows@$BRANCH_NAME"

def mgmtNetwork
def testNetwork
def vmwareConfig
def inventoryFilePath
def testEnvName
def testEnvFolder

def testbeds

pipeline {
    agent none

    options {
        timeout time: 5, unit: 'HOURS'
    }

    environment {
        VC = credentials('vcenter')
        // TODO actually create this file
        TEST_CONFIGURATION_FILE = "GetTestConfigurationJuni.ps1"
        TESTBED = credentials('win-testbed')
        ARTIFACTS_DIR = "output"

        LOG_SERVER = "logs.opencontrail.org"
        LOG_SERVER_USER = "zuul-win"
        LOG_ROOT_DIR = "/var/www/logs/winci"
        BUILD_SPECIFIC_DIR = "${ZUUL_UUID}"
        JOB_SUBDIR = env.JOB_NAME.replaceAll("/", "/jobs/")
        LOCAL_SRC_FILE = "${JENKINS_HOME}/jobs/${JOB_SUBDIR}/builds/${BUILD_ID}/log"
        REMOTE_DST_FILE = "${LOG_ROOT_DIR}/${BUILD_SPECIFIC_DIR}/log.txt"
    }

    stages {
        stage('Preparation') {
            agent { label 'builder' }
            steps {
                deleteDir()

                // Use the same repo and branch as was used to checkout Jenkinsfile:
                checkout scm

                script {
                    mgmtNetwork = env.TESTENV_MGMT_NETWORK
                }

                // If not using `Pipeline script from SCM`, specify the branch manually:
                // git branch: 'development', url: 'https://github.com/codilime/contrail-windows-ci/'

                stash name: "CIScripts", includes: "CIScripts/**"
                stash name: "ansible", includes: "ansible/**"
            }
        }

        stage('Build') {
            agent { label 'builder' }
            environment {
                THIRD_PARTY_CACHE_PATH = "C:/BUILD_DEPENDENCIES/third_party_cache/"
                DRIVER_SRC_PATH = "github.com/Juniper/contrail-windows-docker-driver"
                BUILD_ONLY = "1"
                BUILD_IN_RELEASE_MODE = "false"
                SIGNTOOL_PATH = "C:/Program Files (x86)/Windows Kits/10/bin/x64/signtool.exe"
                CERT_PATH = "C:/BUILD_DEPENDENCIES/third_party_cache/common/certs/codilime.com-selfsigned-cert.pfx"
                CERT_PASSWORD_FILE_PATH = "C:/BUILD_DEPENDENCIES/third_party_cache/common/certs/certp.txt"

                MSBUILD = "C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe"
            }
            steps {
                deleteDir()

                unstash "CIScripts"

                powershell script: './CIScripts/Build.ps1'

                stash name: "WinArt", includes: "output/**/*"
                //stash name: "buildLogs", includes: "logs/**"
            }
        }

        stage('Lock') {
            agent { label 'ansible' }
            steps {
                script {
                    try {
                        lock('vmware-lock') {
                            deleteDir()
                            unstash 'ansible'

                            script {
                                testNetwork = selectNetworkAndLock(env.VC_FIRST_TEST_NETWORK_ID, env.VC_TEST_NETWORKS_COUNT)
                            }
                        }
                    }
                    catch(err) {
                        echo "Error occured during Lock stage: ${err}"
                        currentBuild.result = "SUCCESS"
                    }
                }
            }
        }

        stage('Provision') {
            agent { label 'ansible' }
            when { expression { return !currentBuild.result } }

            steps {
                script {
                    try {
                        deleteDir()
                        unstash 'ansible'

                        script {
                            vmwareConfig = getVMwareConfig()
                            inventoryFilePath = "${env.WORKSPACE}/ansible/vm.${env.BUILD_ID}"
                            testEnvName = generateTestEnvName()
                            testEnvFolder = "${env.VC_FOLDER}/${testNetwork}"
                        }

                        prepareTestEnv(inventoryFilePath, testEnvName, testEnvFolder,
                                       mgmtNetwork, testNetwork,
                                       env.TESTBED_TEMPLATE, env.CONTROLLER_TEMPLATE)
                        provisionTestEnv(vmwareConfig)

                        script {
                            testbeds = parseTestbedAddresses(inventoryFilePath)
                        }

                        stash name: "ansible", includes: "ansible/**"
                    }
                    catch(err) {
                        echo "Error occured during Provision stage: ${err}"
                        currentBuild.result = "SUCCESS"
                    }
                }
            }
        }

        stage('Deploy') {
            agent { label 'tester' }
            when { expression { return !currentBuild.result } }

            steps {
                script {
                    try {
                        deleteDir()
                        unstash "CIScripts"
                        unstash "WinArt"

                        script {
                            env.TESTBED_ADDRESSES = testbeds.join(',')
                        }

                        powershell script: './CIScripts/Deploy.ps1'
                    }
                    catch(err) {
                        echo "Error occured during Deploy stage: ${err}"
                        currentBuild.result = "SUCCESS"
                    }
                }
            }
        }

        stage('Test') {
            agent { label 'tester' }
            when { expression { return !currentBuild.result } }

            steps {
                script {
                    try {
                        deleteDir()
                        unstash "CIScripts"
                        // powershell script: './CIScripts/Test.ps1'
                    }
                    catch(err) {
                        echo "Error occured during Test stage: ${err}"
                        currentBuild.result = "SUCCESS"
                    }
                }
            }
        }
    }

    post {
        always {
            node(label: 'ansible') {
                deleteDir()
                unstash 'ansible'

                script {
                    try {
                        destroyTestEnv(vmwareConfig)
                    }
                    catch(err) {
                        echo "Error occured during Post stage (destroying TestEnv): ${err}"
                    }

                    try {
                        unlockNetwork(testNetwork)
                    }
                    catch(err) {
                        echo "Error occured during Post stage (unlocking TestNetwork): ${err}"
                    }
                }
            }

            node('master') {
                script {
                    // Job triggered by Zuul -> upload log file to public server.
                    // Job triggered by Github CI repository (variable "ghprbPullId" exists) -> keep log "private".

                    // TODO JUNIPER_WINDOWSSTUBS variable check is temporary and should be removed once
                    // repository contrail-windows is accessible from Gerrit and it is main source of
                    // windowsstubs code.
                    if (env.ghprbPullId == null && env.JUNIPER_WINDOWSSTUBS == null) {
                        // cleanWs()
                        echo "TODO environment cleanup"
                        // unstash "buildLogs"
                        // TODO correct flags for rsync
                        sh "ssh ${LOG_SERVER_USER}@${LOG_SERVER} \"mkdir -p ${LOG_ROOT_DIR}/${BUILD_SPECIFIC_DIR}\""
                        sh "rsync ${LOCAL_SRC_FILE} ${LOG_SERVER_USER}@${LOG_SERVER}:${REMOTE_DST_FILE}"
                        // cleanWS{}
                    }
                }
            }
        }
    }
}
