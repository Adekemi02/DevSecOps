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
    }
}