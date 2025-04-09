pipeline{

    agent {
        label 'jenkins-slave'
    }
    environment {
        DOCKER_REGISTRY = "https://index.docker.io"
        DOCKER_IMAGE = "adekhemie/django-app"
    }
  
    stages{
        
        stage('Testing'){
            steps {
                script{
                sh 'echo "Hello from Slave Node"'
                }
            }
        }
        stage('Gitleaks scan'){
            steps {
                script{
                    // Pull and run the Gitleaks Docker Image with a custom config file
                    sh '''
                        rm gitleaks-report.json  || true
                        docker run --rm -v $(pwd):/path -v $(pwd)/.gitleaks.toml:/.gitleaks.toml zricethezav/gitleaks:latest detect --source /path --config /.gitleaks.toml --report-format json --report-path /path/gitleaks-report.json || true
                    '''
                    // Display the content of the report in a separte step
                    echo "Displaying Gitleaks report: "
                    sh 'cat gitleaks-report.json || echo "Report not found"'
                }
            }
            // Archive the report as an artifact
            post {
                always {
                    archiveArtifacts artifacts: 'gitleaks-report.json',
                    fingerprint: true,
                    allowEmptyArchive: true
                }
            }
        }
        stage('SCA with OWASP Dependency Check'){
            steps {
                script {
                    sh 'rm dependency-check-report*  || true'
                    sh 'wget "https://raw.githubusercontent.com/aatikah/devsecops/refs/heads/master/owasp-dependency-check.sh"'
                    sh 'chmod +x run-depcheck.sh'
                    sh 'bash run-depcheck.sh || true'
                    
                }
                // Parse JSON report to check for issues
                // This step is added to ensure that the JSON report is parsed and the results are displayed
                // after the Dependency Check scan is completed
                // This is important to ensure that the JSON report is available for parsing
                script {
                    if (fileExists('dependency-check-report.json')) {
                        def jsonReport = readJSON file: 'dependency-check-report.json'
                        def vulnerabilities = jsonReport.dependencies.collect { it.vulnerabilities ?: [] }.flatten()
                        def highVulnerabilities = vulnerabilities.findAll { it.cvssv3?.baseScore >= 7 }
                        echo "OWASP Dependency-Check found ${vulnerabilities.size()} vulnerabilities, ${highVulnerabilities.size()} of which are high severity (CVSS >= 7.0)"
                    } else {
                        echo "Dependency-Check JSON report not found. The scan may have failed."
                    }
                }
            }
            // Archive the report as an artifact
            post {
                always {
                    archiveArtifacts artifacts: 'dependency-check-report.json, dependency-check-report.html, dependency-check-report.xml', 
                    fingerprint: true,
                    allowEmptyArchive: true

                    // Publish HTML Report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Checker Report'
                    ])
                }
            }
        }
        stage('SAST with Bandit'){
            steps {
                script {
                    // Run scan with Bandit and generate report
                    sh '''
                        python3 -m venv bandit_venv
                        . bandit_venv/bin/activate
                        pip install --upgrade pip
                        pip install bandit

                        bandit -r . -f json -o bandit-report.json --exit-zero
                        bandit -r . -f html -o bandit-report.html --exit-zero
                        deactivate
                    '''
                }
                // Parse JSON report to check for issues
                script {
                    def jsonReport = readJSON file: 'bandit-report.json'
                    def issueCount = jsonReport.results.size()
                    if (issueCount > 0) {
                        echo "Bandit found ${issueCount} potential security issue(s). Please review the report"
                    } else {
                        echo 'Bandit scan completely with no found issue.'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'bandit-report.json, bandit-report.html',
                    fingerprint: true,
                    allowEmptyArchive: true

                    // Publish HTML Report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit Static Analysis Report'
                    ])
                }
            }
        }
        stage('SAST with Flake8'){
            steps {
                script {
                    // Run scan with Flake8 and generate report
                    sh '''
                        python3 -m venv flake8_venv
                        . flake8_venv/bin/activate
                        pip install --upgrade pip
                        pip install flake8

                        flake8 --output-file=flake8-report.json --count --show-source --statistics . --exit-zero
                        flake8 --output-file=flake8-report.html --format=html --max-line-length=120 . --exit-zero
                        deactivate
                    '''
                }
                // Parse report to check for issues
                script {
                    def jsonReport = readJSON file: 'flake8-report.json'
                    def issueCount = jsonReport('flake8-report.json').results.size()
                    if (issueCount > 0) {
                        echo "Flake8 found ${issueCount} potential security issue(s). Please review the report"
                    } else {
                        echo 'Flake8 scan completely with no found issue.'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'flake8-report.json, flake8-report.html',
                    fingerprint: true,
                    allowEmptyArchive: true

                    // Publish HTML Report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'flake8-report.html',
                        reportName: 'Flake8 Static Dependency Analysis Report'
                    ])
                }
            }
        }
        stage('Buid and Push Docker Image To DockerHub'){
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIAL',
                                        usernameVariable: 'DOCKER_USERNAME',
                                        passwordVariable: 'DOCKER_PASSWORD',
                                    )]) {
                        // Build the docker image
                        sh 'docker build -t ${DOCKER_IMAGE} .'

                        // Login to Docker Hub
                        sh '''
                            set +x
                            echo "$DOCKER_PASSWORD" | docker login $DOCKER_REGISTRY -u "DOCKER_USERNAME" --password-stdin
                            set -x
                        '''

                        // Push Image to Docker Hub
                        sh 'docker push ${DOCKER_IMAGE}'

                        // Clean up by removing leftover credentials
                        sh 'rm -f /home/jenkins/.docker/config.json'
                    }
                }
            }
        }
    }
}