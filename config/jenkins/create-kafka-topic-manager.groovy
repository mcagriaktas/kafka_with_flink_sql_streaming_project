// create-kafka-topic-manager.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import java.util.logging.Logger
import hudson.model.ParametersAction
import hudson.model.StringParameterValue

def logger = Logger.getLogger("kafka-job-creator")
def jenkins = Jenkins.getInstance()

def requiredPlugins = ["workflow-job", "workflow-cps"]
def missingPlugins = requiredPlugins.findAll { pluginId -> jenkins.getPluginManager().getPlugin(pluginId) == null }

if (!missingPlugins.isEmpty()) {
    logger.severe("Required plugins not installed: ${missingPlugins.join(', ')}")
    return
}

logger.info("Creating Kafka Topic Manager pipeline job...")

def jobName = "Kafka-Topic-Manager"
def pipelineScript = '''
pipeline {
    agent any
    parameters {
        string(name: 'TOPIC_NAME', defaultValue: '', description: 'The name of the Kafka topic')
        choice(name: 'OPERATION', choices: ['create', 'delete', 'describe', 'list', 'alter'], description: 'Operation to perform')
        string(name: 'PARTITIONS', defaultValue: '12', description: 'Number of partitions (for create or alter)')
        string(name: 'REPLICATION_FACTOR', defaultValue: '3', description: 'Replication factor (for create)')
    }
    
    stages {
        stage('Manage Kafka Topic') {
            steps {
                script {
                    // Basic validation
                    if (params.OPERATION != 'list' && params.TOPIC_NAME.trim() == '') {
                        error "Topic name is required for ${params.OPERATION} operation"
                    }
                    
                    // Check if topic exists for delete and alter operations
                    if (params.OPERATION in ['delete', 'alter']) {
                        echo "Checking if topic ${params.TOPIC_NAME} exists..."
                        def topicExists = sh(
                            script: "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --list | grep -q '^${params.TOPIC_NAME}\\$'",
                            returnStatus: true
                        ) == 0
                        
                        if (!topicExists && params.OPERATION == 'delete') {
                            echo "Topic ${params.TOPIC_NAME} does not exist. Skipping delete operation."
                            return
                        }
                        
                        if (!topicExists && params.OPERATION == 'alter') {
                            error "Cannot alter topic ${params.TOPIC_NAME} because it does not exist."
                        }
                    }
                    
                    // Prepare the command based on the operation
                    def command = ""
                    
                    switch(params.OPERATION) {
                        case 'create':
                            command = "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic ${params.TOPIC_NAME} --create --partitions ${params.PARTITIONS} --replication-factor ${params.REPLICATION_FACTOR}"
                            break
                        case 'delete':
                            command = "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic ${params.TOPIC_NAME} --delete"
                            break
                        case 'describe':
                            command = "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic ${params.TOPIC_NAME} --describe"
                            break
                        case 'list':
                            command = "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --list"
                            break
                        case 'alter':
                            command = "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic ${params.TOPIC_NAME} --alter --partitions ${params.PARTITIONS}"
                            break
                    }
                    
                    // Execute the command
                    echo "Executing: ${command}"
                    try {
                        sh command
                        echo "Command executed successfully."
                    } catch (Exception e) {
                        if (params.OPERATION == 'describe' && e.toString().contains('does not exist')) {
                            echo "Topic ${params.TOPIC_NAME} does not exist."
                        } else {
                            throw e
                        }
                    }
                    
                    // Verify the operation
                    if (params.OPERATION in ['create', 'alter']) {
                        echo "Verifying topic ${params.TOPIC_NAME}..."
                        sh "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic ${params.TOPIC_NAME} --describe"
                    }
                }
            }
        }
    }
}
'''

try {
    def job = jenkins.getItemByFullName(jobName)
    if (job == null) {
        job = jenkins.createProject(WorkflowJob.class, jobName)
        job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
        logger.info("Created Kafka Topic Manager pipeline job.")
    } else {
        job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
        logger.info("Updated Kafka Topic Manager pipeline job.")
    }
    jenkins.save()

    def params = [
        new StringParameterValue('OPERATION', 'list'),
        new StringParameterValue('TOPIC_NAME', ''),
        new StringParameterValue('PARTITIONS', '12'),
        new StringParameterValue('REPLICATION_FACTOR', '3')
    ]
    job.scheduleBuild2(0, new ParametersAction(params))
    logger.info("Scheduled build for ${jobName} with 'list' operation")
} catch (Exception e) {
    logger.severe("Error creating Kafka Topic Manager job: ${e.message}")
    e.printStackTrace()
}