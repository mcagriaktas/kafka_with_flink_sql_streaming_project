// Add necessary imports
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.getInstance()

def logInfo(message) {
    println "[INFO] ${message}"
}

def logSevere(message) {
    println "[SEVERE] ${message}"
}

def requiredPlugins = ["workflow-job", "workflow-cps"]
def missingPlugins = requiredPlugins.findAll { pluginId -> jenkins.getPluginManager().getPlugin(pluginId) == null }

if (!missingPlugins.isEmpty()) {
    println "[SEVERE] Required plugins not installed: ${missingPlugins.join(', ')}"
    return
}

println "[INFO] Creating Flink SQL Manager pipeline job..."

def jobName = "Flink-SQL-Manager"
def pipelineScript = '''
pipeline {
    agent any
    parameters {
        text(name: 'SQL_QUERY', defaultValue: '', description: 'SQL query to execute')
        choice(name: 'OPERATION', choices: ['execute', 'list', 'view'], description: 'Operation to perform')
        string(name: 'FILE_NAME', defaultValue: '', description: 'SQL file name (required for execute and view)')
    }
    
    stages {
        stage('Validate Input') {
            steps {
                script {
                    if (params.OPERATION == 'execute') {
                        if (params.SQL_QUERY.trim() == '' || params.FILE_NAME.trim() == '') {
                            error "Both SQL query and file name are required for execute operation"
                        }
                    } else if (params.OPERATION == 'view') {
                        if (params.FILE_NAME.trim() == '') {
                            error "File name is required for view operation"
                        }
                    }
                }
            }
        }
        
        stage('Prepare Directories') {
            steps {
                sh 'mkdir -p /opt/jenkins/flink-sql'
                sh 'mkdir -p /opt/flink/sql_query_list'
            }
        }
        
        stage('Manage Flink SQL') {
            steps {
                script {
                    // Define script path
                    def cmd = "/opt/jenkins/execute-flink-sql.sh"
                    
                    switch(params.OPERATION) {
                        case 'execute':
                            // Save SQL query to a temporary file
                            def tmpFile = "/tmp/query_${BUILD_NUMBER}.txt"
                            writeFile file: tmpFile, text: params.SQL_QUERY
                            
                            // Execute with the query from the file
                            sh "chmod +x ${cmd}"
                            sh "${cmd} -o execute -f '${params.FILE_NAME}' -q '@${tmpFile}'"
                            sh "rm ${tmpFile}"
                            break
                            
                        case 'list':
                            // For list, we don't need any additional parameters
                            sh "chmod +x ${cmd}"
                            sh "${cmd} -o list"
                            break
                            
                        case 'view':
                            // For view, we need the file name
                            sh "chmod +x ${cmd}"
                            sh "${cmd} -o view -f '${params.FILE_NAME}'"
                            break
                            
                        default:
                            error "Unknown operation: ${params.OPERATION}"
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
        println "[INFO] Created Flink SQL Manager pipeline job."
    } else {
        job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
        println "[INFO] Updated Flink SQL Manager pipeline job."
    }
    jenkins.save()
    
    def params = [
        new StringParameterValue('OPERATION', 'list'),
        new StringParameterValue('SQL_QUERY', ''),      
        new StringParameterValue('FILE_NAME', '')
    ]
    job.scheduleBuild2(0, new ParametersAction(params))
    println "[INFO] Scheduled build for ${jobName} with 'list' operation"
} catch (Exception e) {
    println "[SEVERE] Error creating Flink SQL Manager job: ${e.message}"
    e.printStackTrace()
}