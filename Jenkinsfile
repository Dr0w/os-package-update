pipeline {
    agent any

    parameters {
        string(name: 'TARGET_IP', defaultValue: '', description: 'Target IP or hostname')
        choice(name: 'CREDENTIALS', choices: ['ubuntu-dev-creds', 'mac-dev-creds'], description: 'Select SSH credentials')
        choice(name: 'SUDO_CREDENTIALS', choices: ['ubuntu-sudo-creds', 'mac-sudo-creds'], description: 'Select sudo password credentials')
        booleanParam(name: 'DO_CLEAN', defaultValue: false, description: 'Clean after update')
    }

    environment {
        PATH = "/usr/local/bin:/usr/bin:/bin:$PATH"
    }

    stages {
        stage('Init sshpass path') {
            steps {
                script {
                    def sshpassPath = sh(script: 'which sshpass', returnStdout: true).trim()
                    if (!sshpassPath) {
                        error("sshpass not found on Jenkins node")
                    }
                    env.SSHPASS_CMD = sshpassPath
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Dr0w/os-package-update.git',
                        credentialsId: 'github-jenkins-creds'
                    ]]
                ])
            }
        }

        stage('Copy Script') {
            steps {
                script {
                    def credId = params.CREDENTIALS
                    sshagent([credId]) {
                        sh """
                            scp -o StrictHostKeyChecking=no packages_update.sh drow@${params.TARGET_IP}:~/packages_update.sh
                        """
                    }
                }
            }
        }

        stage('Make Executable') {
            steps {
                script {
                    def credId = params.CREDENTIALS
                    sshagent([credId]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no drow@${params.TARGET_IP} 'chmod +x ~/packages_update.sh'
                        """
                    }
                }
            }
        }

        stage('Execute') {
            steps {
                script {
                    def sudoCredId = params.SUDO_CREDENTIALS
                    withCredentials([
                        usernamePassword(credentialsId: sudoCredId, usernameVariable: 'SUDO_USER', passwordVariable: 'SUDO_PASS')
                    ]) {
                        // Detect the remote OS:
                        sh """
                            set -o pipefail
                            ${env.SSHPASS_CMD} -p "${SUDO_PASS}" \\
                                ssh -o StrictHostKeyChecking=no ${SUDO_USER}@${params.TARGET_IP} "uname -s" \\
                                > remote-os.txt
                        """

                        def remoteOS = readFile('remote-os.txt').trim()
                        echo "Remote OS detected: ${remoteOS}"

                        // Run differently based on OS:
                        if (remoteOS == 'Darwin') {
                            echo "macOS detected - running without sudo"
                            sh """
                                set -o pipefail
                                ${env.SSHPASS_CMD} -p "${SUDO_PASS}" \\
                                    ssh -o StrictHostKeyChecking=no ${SUDO_USER}@${params.TARGET_IP} \\
                                    "CLEAN=${params.DO_CLEAN} ~/packages_update.sh" \\
                                | tee exec_output.log
                            """
                        } else {
                            echo "Linux/Unix detected - running with sudo"
                            sh """
                                set -o pipefail
                                ${env.SSHPASS_CMD} -p "${SUDO_PASS}" \\
                                    ssh -o StrictHostKeyChecking=no ${SUDO_USER}@${params.TARGET_IP} \\
                                    "echo '${SUDO_PASS}' | sudo -S CLEAN=${params.DO_CLEAN} ~/packages_update.sh" \\
                                | tee exec_output.log
                            """
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        if (fileExists('exec_output.log')) {
                            def log = readFile('exec_output.log')
                            // Optional check for particular sudo errors
                            if (log.contains("sudo: a terminal is required") || log.contains("sudo: a password is required")) {
                                error("SUDO error")
                            }
                            // If the script has built-in logic to exit nonzero on errors,
                            // Jenkins will fail automatically. Otherwise, you could parse the log
                            // for "Error" or "Warning" and fail as needed.
                        } else {
                            error("exec_output.log not created")
                        }
                    }
                }
            }
        }
    }
}