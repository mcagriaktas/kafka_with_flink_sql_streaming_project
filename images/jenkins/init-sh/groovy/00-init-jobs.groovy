// 00-init-jobs.groovy
import jenkins.model.*
import java.util.logging.Logger
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

def logger = Logger.getLogger("main-init")
def jenkins = Jenkins.getInstance()

// Step 1: Configure basic security first
logger.info("Setting up basic security...")
evaluate(new File(jenkins.rootDir, "groovys_base/basic-security.groovy"))

// Step 2: Install required plugins
logger.info("Installing required plugins...")
evaluate(new File(jenkins.rootDir, "groovys_base/install-plugins.groovy"))

// Give plugins a moment to load
sleep(5000)

// Step 3: Create Kafka Topic Manager job
logger.info("Creating Kafka Topic Manager job...")
evaluate(new File(jenkins.rootDir, "groovys/create-kafka-topic-manager.groovy"))

// Step 4: Create Flink SQL Manager job
logger.info("Creating Flink SQL Manager job...")
evaluate(new File(jenkins.rootDir, "groovys/create-flink-sql-manager.groovy"))

// Step 5: Create Jenkins First Deployment
def markerFile = new File(jenkins.rootDir, ".first-init-complete")
markerFile.text = "First initialization completed at ${new Date()}\n"

logger.info("Jobs created successfully. Waiting before restart...")
sleep(15000)

if (!new File(jenkins.rootDir, ".jenkins-restarted").exists()) {
    logger.info("Safely restarting Jenkins to activate plugins...")
    
    def restartMarker = new File(jenkins.rootDir, ".jenkins-restarted")
    restartMarker.text = "Jenkins restarted at ${new Date()}\n"
    
    Thread.start {
        sleep(3000)
        jenkins.safeRestart()
    }
} else {
    logger.info("Jenkins has already been restarted. Skipping restart.")
}

logger.info("Initialization process completed successfully.")