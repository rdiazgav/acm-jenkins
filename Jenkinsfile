pipeline {
  agent any

  environment {
    // --- Git ---
    GIT_URL    = 'https://github.com/rdiazgav/hello-acs-jenkins.git' 
    GIT_BRANCH = 'main'

    // --- OpenShift ---
    NS  = 'acs-demo'
    APP = 'hello-acs-jenkins'      // BuildConfig (binary docker strategy)
    IS  = 'hello-acs-jenkins-is'   // ImageStream destino
    TAG = "${env.BUILD_NUMBER}"

    // Si el agente NO está ya logueado a OCP, define el API aquí:
    // p.ej.: 'https://api.tu-cluster:6443'
    OC_API = 'https://api.rosa-g55hg.zw03.p3.openshiftapps.com:443'

    // --- AWS / ECR ---
    AWS_REGION   = 'us-east-2'
    ECR_REGISTRY = '635691952381.dkr.ecr.us-east-2.amazonaws.com'
    ECR_REPO     = 'acs-demo'

    // --- ACS ---
    ACS_CENTRAL = 'central-rhacs-operator.apps.rosa.rosa-g55hg.zw03.p3.openshiftapps.com:443'
  }

  stages {

    stage('Checkout') {
      steps {
        // Si tu repo es privado, añade credentialsId: 'github-creds'
        git url: "${GIT_URL}", branch: "${GIT_BRANCH}"
      }
    }

    stage('Login & Prep OpenShift') {
      steps {
        withCredentials([string(credentialsId: 'openshift-token', variable: 'OC_TOKEN')]) {
          sh '''
            set -euo pipefail

            if [ -z "${OC_API}" ]; then
              if oc whoami >/dev/null 2>&1; then
                echo "[oc] Using existing session"
              else
                echo "[oc] ERROR: OC_API is empty and there is no active oc session." >&2
                exit 1
              fi
            else
              oc login --token="${OC_TOKEN}" --server="${OC_API}" --insecure-skip-tls-verify=true
            fi

            oc project ${NS} || oc new-project ${NS}

            # ImageStream destino
            oc -n ${NS} get is/${IS} >/dev/null 2>&1 || oc -n ${NS} create is ${IS}

            # BuildConfig binario (DockerStrategy) si no existe
            if ! oc -n ${NS} get bc/${APP} >/dev/null 2>&1; then
              oc -n ${NS} new-build --name=${APP} --strategy=docker --binary=true
            fi
          '''
        }
      }
    }

    stage('Build in OpenShift (binary DockerStrategy)') {
      steps {
        sh '''
          set -euo pipefail
          oc project ${NS}
          echo ">> starting binary build for ${APP}..."
          oc start-build ${APP} --from-dir=. --wait --follow

          echo ">> tag build output to ${APP}:${TAG}..."
          oc -n ${NS} tag ${NS}/${APP}:latest ${NS}/${APP}:${TAG}

          echo ">> copy tag into ImageStream ${IS}:${TAG}..."
          oc -n ${NS} tag ${NS}/${APP}:${TAG} ${NS}/${IS}:${TAG}
        '''
      }
    }

stage('Mirror to ECR via STS (no Docker on agent)') {
  steps {
    withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-sts' ]]) {
      sh '''
        set -euo pipefail

        SRC="image-registry.openshift-image-registry.svc:5000/${NS}/${IS}:${TAG}"
        DEST="${ECR_REGISTRY}/${ECR_REPO}:${TAG}"
        REGCFG="${WORKSPACE}/mirror-auth.json"

        echo ">> Generate combined auth (OpenShift + ECR)"
        oc registry login --to="$REGCFG"

        echo ">> Get ECR password and build auth string"
        PASS="$(aws ecr get-login-password --region ${AWS_REGION})"
        AUTH=$(echo -n "AWS:${PASS}" | base64 | tr -d '\\n')

        echo ">> Merge ECR auth"
        TMP=$(mktemp)
        jq --arg reg "${ECR_REGISTRY}" --arg auth "$AUTH" \
           '.auths[$reg] = {"auth":$auth}' \
           "$REGCFG" > "$TMP"
        mv "$TMP" "$REGCFG"

        echo ">> Mirror: $SRC  -->  $DEST"
        oc image mirror --registry-config="$REGCFG" --insecure "$SRC" "$DEST"

        echo ">> Mirror completed successfully."
      '''
    }
  }
}


    stage('Scan with Red Hat ACS (informational)') {
      steps {
        script {
          def IMAGE_ECR = "${ECR_REGISTRY}/${ECR_REPO}:${TAG}"
          catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            stackrox(
              portalAddress: ACS_CENTRAL,
              apiToken: credentials('acs-api-token'),
              imageNames: IMAGE_ECR,
              failOnPolicyEvalFailure: false,  // no gate
              enableTLSVerification: true
            )
          }
        }
      }
    }
  }

  post {
    success { echo "OK: Git checkout → Build in OCP → Mirror to ECR → ACS scan (informativo)." }
    unstable { echo "UNSTABLE: ACS reportó violaciones (no bloquea el build)." }
    failure { echo "FAIL: revisa checkout, build OCP o credenciales ECR/OC/ACS." }
  }
}
