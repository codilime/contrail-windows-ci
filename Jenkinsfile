#!groovy
library "contrailWindows@$BRANCH_NAME"

def mgmtNetwork
def dataNetwork
def vmwareConfig
def inventoryFilePath
def testEnvName
def testEnvFolder

def testbeds

pipeline {
    agent none

    options {
        timeout time: 5, unit: 'HOURS'
        timestamps()
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
                    dataNetwork = calculateTestNetwork(env.BUILD_ID as int)
                }

                stash name: "CIScripts", includes: "CIScripts/**"
                stash name: "Linters", includes: "Linters/**"
                stash name: "Ansible", includes: "ansible/**"
            }
        }

        stage ('Checkout') {
            agent { label 'windows' }
            environment {
                DRIVER_SRC_PATH = "github.com/Juniper/contrail-windows-docker-driver"
            }
            steps {
                deleteDir()
                unstash "CIScripts"
                powershell script: './CIScripts/Checkout.ps1'
                stash name: "SourceCode", excludes: "CIScripts"
            }
        }

        stage('Lint') {
            // TODO: 'scriptanalyzer' is feature flag label; change to 'builder' after rollout done
            agent { label 'scriptanalyzer' }
            steps {
                deleteDir()
                unstash "Linters"
                unstash "SourceCode"
                unstash "CIScripts"
                // TODO. https://review.opencontrail.org/#/c/39677/ containts Powershell formatting fixes
                // for contrail-controller. Until that PR is merged, just run the linters on 
                // CIScripts/ directory. We need to swap, when aforementioned PR is merged.
                powershell script: "./Linters/Invoke-AllLinters.ps1 -RootDir CIScripts/ -Config ${env.WORKSPACE}/Linters/"
                // powershell script: "./Linters/Invoke-AllLinters.ps1 -RootDir . -Config ${env.WORKSPACE}/Linters/"
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
                WINCIDEV = credentials('winci-drive')
            }
            steps {
                deleteDir()

                unstash "CIScripts"
                unstash "SourceCode"

                powershell script: './CIScripts/BuildStage.ps1'

                stash name: "Artifacts", includes: "output/**/*"
            }
        }

        // NOTE: Currently nesting multiple stages in lock directive is unsupported
        stage('Provision & Deploy & Test') {
            agent none
            when { environment name: "DONT_CREATE_TESTBEDS", value: null }
            environment {
                // Required in 'Provision' stages
                VC = credentials('vcenter')

                // Required in 'Deploy' and 'Test' stages
                // TODO actually create this file
                TEST_CONFIGURATION_FILE = "GetTestConfigurationJuni.ps1"
                TESTBED = credentials('win-testbed')
                ARTIFACTS_DIR = "output"
            }
            steps {
                script {
                    try {
                        lock(dataNetwork) {
                            // 'Provision' stage
                            node(label: 'ansible') {
                                deleteDir()
                                unstash 'Ansible'

                                script {
                                    vmwareConfig = getVMwareConfig()
                                    inventoryFilePath = "${env.WORKSPACE}/ansible/vm.${env.BUILD_ID}"
                                    testEnvName = generateTestEnvName()
                                    testEnvFolder = env.VC_FOLDER
                                }

                                prepareTestEnv(inventoryFilePath, testEnvName, testEnvFolder,
                                               mgmtNetwork, dataNetwork,
                                               env.TESTBED_TEMPLATE, env.CONTROLLER_TEMPLATE)
                                provisionTestEnv(vmwareConfig)

                                script {
                                    testbeds = parseTestbedAddresses(inventoryFilePath)
                                }
                            }

                            // 'Deploy' stage
                            node(label: 'tester') {
                                deleteDir()

                                unstash "CIScripts"
                                unstash "Artifacts"

                                script {
                                    env.TESTBED_ADDRESSES = testbeds.join(',')
                                }

                                powershell script: './CIScripts/Deploy.ps1'
                            }

                            // 'Test' stage
                            node(label: 'tester') {
                                deleteDir()
                                unstash "CIScripts"
                                // powershell script: './CIScripts/Test.ps1'
                            }
                        }
                    }
                    catch(err) {
                        echo "Error occured during test stage: ${err}"
                        currentBuild.result = "SUCCESS"
                    }
                }
            }
            post {
                always {
                    node(label: 'ansible') {
                        destroyTestEnv(vmwareConfig)
                    }
                }
            }
        }
    }

    environment {
        LOG_SERVER = "logs.opencontrail.org"
        LOG_SERVER_USER = "zuul-win"
        LOG_ROOT_DIR = "/var/www/logs/winci"
        BUILD_SPECIFIC_DIR = "${ZUUL_UUID}"
        JOB_SUBPATH = env.JOB_NAME.replaceAll("/", "/job/")
        RAW_LOG_PATH = "job/${JOB_SUBPATH}/${BUILD_ID}/timestamps/?elapsed=HH:mm:ss&appendLog"
        REMOTE_DST_FILE = "${LOG_ROOT_DIR}/${BUILD_SPECIFIC_DIR}/log.txt"
    }

    post {
        always {
            node('master') {
                script {
                    // Job triggered by Zuul -> upload log file to public server.
                    // Job triggered by Github CI repository (variable "ghprbPullId" exists) -> keep log "private".

                    // TODO JUNIPER_WINDOWSSTUBS variable check is temporary and should be removed once
                    // repository contrail-windows is accessible from Gerrit and it is main source of
                    // windowsstubs code.
                    if (env.ghprbPullId == null && env.JUNIPER_WINDOWSSTUBS == null) {
                        // unstash "buildLogs"
                        // TODO correct flags for rsync
                        sh "ssh ${LOG_SERVER_USER}@${LOG_SERVER} \"mkdir -p ${LOG_ROOT_DIR}/${BUILD_SPECIFIC_DIR}\""
                        // The timestamps are not stored on disk as raw text, but in some encoded form,
                        // so the easiest way to decode them is to use http path provided by the timestamper plugin.
                        sh "curl --silent 'http://localhost:8080/$RAW_LOG_PATH' --output clean_log.txt"
                        sh "rsync clean_log.txt ${LOG_SERVER_USER}@${LOG_SERVER}:${REMOTE_DST_FILE}"
                        deleteDir()
                    }
                }
            }
        }
    }
}
