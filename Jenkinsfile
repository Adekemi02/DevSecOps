pipeline{

    agent {
        label 'jenkins-slave'
    }
    // environment {

    // }
  
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
                    sh 'bash owasp-dependency-check.sh || true'
                    
                    // Display the content of the report in a separte step
                    echo "Displaying OWASP Dependency Check report: "
                    sh 'cat report/dependency-check-report.html || echo "Report not found"'
                }
                // Parse JSON report to check for issues
                // This step is added to ensure that the JSON report is parsed and the results are displayed
                // after the Dependency Check scan is completed
                // This is important to ensure that the JSON report is available for parsing
                script {
                    if (fileExists('report/dependency-check-report.json')) {
                        def jsonReport = readJSON file: 'report/dependency-check-report.json'
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
                    archiveArtifacts artifacts: 'report/dependency-check-report.json, report/dependency-check-report.html, report/dependency-check-report.xml', 
                    fingerprint: true,
                    allowEmptyArchive: true

                    // Publish HTML Report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'report/dependency-check-report.html',
                        reportName: 'OWASP Dependency Checker Report'
                    ])
                }
            }
        }
    }
}