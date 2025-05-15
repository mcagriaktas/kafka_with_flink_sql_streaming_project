#!/bin/bash
set -e

echo "Starting Jenkins $(java -jar /usr/share/jenkins/jenkins.war --version)"
echo "Using Java: $(java -version 2>&1 | head -n 1)"

export JAVA_OPTS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dhudson.model.ParametersAction.keepUndefinedParameters=true"

chown -R 1000:1000 ${JENKINS_HOME}

exec java ${JAVA_OPTS} -jar /usr/share/jenkins/jenkins.war ${JENKINS_OPTS}