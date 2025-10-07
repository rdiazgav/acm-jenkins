pipeline {
  agent any

  environment {
    // --- OpenShift ---
    NS  = "acs-demo"                     // OpenShift project/namespace
    APP = "hello-acs"                    // BuildConfig and ImageStream name
    TAG = "${env.BUILD_NUMBER}"          // unique image tag per build

    // --- Red Hat ACS (StackRox) ---
    STACKROX_TOKEN = credentials('acs-api-token')   // Jenkins secret text credential
    ACS_CENTRAL    = "central-stackrox.apps.cluster-x9nxw.x9nxw.sandbox1133.opentlc.com:443"
  }

  stages {

    stage('Build in OpenShift') {
      steps {
        echo "Starting binary build in OpenShift..."
        sh """
          oc project ${NS}
          # Trigger BuildConfig using the current workspace as source
          oc start-build ${APP} --from-dir=. --wait --follow
          # Tag the new image with the build number
          oc tag ${NS}/${APP}:latest ${NS}/${APP}:${TAG}
        """
      }
    }

    stage('Scan with Red Hat ACS') {
      steps {
        echo "Scanning image with Red Hat Advanced Cluster Security..."
        script {
          def IMAGE = "image-registry.openshift-image-registry.svc:5000/${NS}/${APP}:${TAG}"
          stackrox(
            portalAddress: "${ACS_CENTRAL}",
            apiToken: "${STACKROX_TOKEN}",
            imageNames: IMAGE,
            failOnPolicyEvalFailure: true,
            enableTLSVerification: true
          )
        }
      }
    }

  }

  post {
    success {
      echo "Build and ACS scan completed successfully."
    }
    failure {
      echo "Pipeline failed — check ACS policy evaluation or permissions."
    }
  }
}
