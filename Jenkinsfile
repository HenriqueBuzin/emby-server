pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Verify') {
            steps {
                sh '''
                    set -eu
                    sh -n scripts/deploy.sh
                    docker compose --env-file .env.example config --quiet
                    test -s site/about/index.html
                    test -s site/privacy/index.html
                '''
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                }
            }
            steps {
                sh 'sh scripts/deploy.sh "$BRANCH_NAME"'
            }
        }
    }
}
