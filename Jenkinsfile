#!groovy
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
        timestamps()
    }

    stages {
        stage('Preparation') {
            agent { label 'ansible' }
            steps {
                deleteDir()

                // Use the same repo and branch as was used to checkout Jenkinsfile:
                checkout scm

                script {
                    mgmtNetwork = env.TESTENV_MGMT_NETWORK
                }

                stash name: "CIScripts", includes: "CIScripts/**"
                stash name: "StaticAnalysis", includes: "StaticAnalysis/**"
                stash name: "Ansible", includes: "ansible/**"
            }
        }

        stage ('Checkout projects') {
            agent { label 'builder' }
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

        stage('Static analysis') {
            // TODO: 'scriptanalyzer' is feature flag label; change to 'builder' after rollout done
            agent { label 'scriptanalyzer' }
            steps {
                deleteDir()
                unstash "StaticAnalysis"
                unstash "SourceCode"
                unstash "CIScripts"
                powershell script: "./StaticAnalysis/Invoke-StaticAnalysisTools.ps1 -RootDir . -Config ${pwd()}/StaticAnalysis"
            }
        }
    }

    environment {
        LOG_SERVER = "logs.opencontrail.org"
        LOG_SERVER_USER = "zuul-win"
        LOG_ROOT_DIR = "/var/www/logs/winci"
        BUILD_SPECIFIC_DIR = "${ZUUL_UUID}"
        JOB_SUBPATH = env.JOB_NAME.replaceAll("/", "/job/")
        REMOTE_DST_FILE = "${LOG_ROOT_DIR}/${BUILD_SPECIFIC_DIR}/log.txt.gz"
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
                        def tmpLogFilename = "clean_log.txt.gz"
                        obtainLogFile(env.JOB_NAME, env.BUILD_ID, tmpLogFilename)
                        sh "rsync $tmpLogFilename ${LOG_SERVER_USER}@${LOG_SERVER}:${REMOTE_DST_FILE}"
                        deleteDir()
                    }
                }

                build job: 'WinContrail/gather-build-stats', wait: false,
                      parameters: [string(name: 'BRANCH_NAME', value: env.BRANCH_NAME),
                                   string(name: 'MONITORED_JOB_NAME', value: env.JOB_NAME),
                                   string(name: 'MONITORED_BUILD_URL', value: env.BUILD_URL),]
            }
        }
    }
}
