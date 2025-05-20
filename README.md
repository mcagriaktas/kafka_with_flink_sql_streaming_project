# Kafka and Flink SQL with Iceberg Using Hive Catalog – Streaming Project

A complete streaming analytics pipeline using Apache Kafka, Apache Flink SQL, Hive, HDFS, Prometheus, Grafana, and Jenkins for automated Apache Kafka and Apache Flink jobs. Includes observability, monitoring, and dashboarding features for data streaming.

- [All details are in the Medium article — click the link and check all the explanations.](https://medium.com/@mucagriaktas/ed2f483d05e0)

## ⚙️ Services & Versions

This project implements a complete streaming data pipeline with the following components:

| Service | Version | Description | Ports | User & Password
|---------|---------|-------------|--------| -------------|
| Apache Kafka | 4.0.0 | Distributed event streaming platform (3-node cluster) | Inside: 9092, Outside: 19092,29092,39093 | - |
| Kafka Exporter | 1.9.0 | Kafka Consumer Metrics Exporter | 9308 | - |
| Apache Flink | 1.20.0 | Stateful stream processing framework with SQL support (Jobmanager, Taskmanager and SQL-Gateway) | UI: 8081, SQL-Gateway: 8082 | - |
| Apache Iceberg | 1.8.1 | Table format for huge analytic datasets | - | - |
| Hadoop (HDFS) | 3.4.1 | Distributed file system for data storage | Namenode: 9870, HDFS: 9000 | User: root |
| Apache Hive | 3.1.3 | Data warehouse and metadata management | 10000 | User: root |
| Hive Metastore | 3.0.0 | Metadata service | 9083 | User: root |
| Jenkins | 2.506 | CI/CD and job management (2 jobs) | 8085 | User: cagri, Password: 35413541 |
| Prometheus | 2.45.0 | Monitoring system | 9090 | - |
| Provectus | 0.7.2 | Web interface for Kafka management | 8080 | - |
| Grafana | 10.4.14 | Monitoring and visualization (3 dashboard) | 3000 | User: admin, Password: 3541 |

## 📂 Project Structure
```bash
├── docker-compose.yml
├── config/
│   ├── flink/              # Job/TaskManager configs
│   ├── kafka/              # Broker configs & metrics & Kafka-exporter
│   ├── grafana/            # Dashboards & datasource setup
│   ├── jenkins/            # Groovy jobs for automation
│   ├── hdfs/, hive/, hms/  # Hadoop ecosystem configs
│   ├── prometheus/         # prometheus.yaml config
│   └── provectus/          # Kafka UI config
├── images/                 # All Dockerfiles + init-sh scripts
├── jobs/
│   ├── flink/              # SQL scripts for streaming
│   └── raw_data.py         # Python generator for Kafka input
├── repo_images/            # Dashboard screenshots
└── README.md
```

### 📁 Service Startup Automation
Each image in the `images/` folder includes its own `service_name-starter.sh` script.
These `starter.sh` scripts are designed to automate deployment and setup for each service — such as:

- ⚙️ Initializing Jenkins jobs
- 📊 Preloading Grafana dashboards
- 🚀 Auto-starting services with correct configs

They simplify the deployment process and ensure everything is ready out-of-the-box.

### 🐳 Deployment Tip
You can also deploy each service individually on any Linux server by following the corresponding Dockerfile. Each Dockerfile includes step-by-step instructions to build and configure the service easily.

## Prerequisites

- Linux environment
- Docker
- Docker Compose

## Deployment

### 1. Create Docker Network

```bash
docker network create --subnet=172.80.0.0/16 dahbest
```

### 2. Build and Deploy

```bash
docker-compose up -d --build
```

> ⚠️ The build process will take approximately 2-3 minutes since all services are built from scratch rather than using base images.

## Getting Started

### 1. Create Kafka Topics

Access Jenkins UI at `http://localhost:8085` and run the `Kafka-Topic-Manager` job to:
- Create `raw-data` topic
- Create `clean-data` topic
- Create `raw-data-dlq` topic

### 2. Configure Flink SQL Processing

Run the `Flink-SQL-Manager` job in Jenkins UI and paste the SQL queries from:
- `jobs/flink/extract_transform.sql` - For data transformation
- `jobs/flink/load.sql` - For loading data into Iceberg

### 3. Start Data Producer

Run the sample data producer:
```bash
python jobs/raw_data.py
```

### 4. Monitoring

Access Grafana dashboards at `http://localhost:3000` to monitor:
- Flink Cluster
- Jenkins Operations
- Kafka Cluster

## Data Storage

The project uses Apache Iceberg tables stored in HDFS for persistent data storage:

```bash
docker exec namenode hdfs dfs -ls /warehouse/
```

Storage locations:
1. `/warehouse/iceberg`           - Iceberg data and metadata
2. `/warehouse/flink/flink-state` - Flink checkpoints and savepoints

HDFS UI:

```bash
http://localhost:9870/
```

### Configuration Files

- Flink configuration: `config/flink/jobmanager/config.yaml` and `config/flink/taskmanager/config.yaml`
- Kafka configuration: `config/kafka/kafka{1,2,3}/server.properties`
- HDFS configuration: `config/hdfs/core-site.xml` and `config/hdfs/hdfs-site.xml`
- Hive configuration: `config/hive/hive-site.xml`
- Monitoring: `config/prometheus/prometheus.yaml` and `config/grafana/*`
- CI/CD Automation: `config/jenkins/*`

## Deployment Notes

### Flink Configuration

⚠️ **Flink 1.20.0 specifics:**
- Flink 1.20.0 and 2.0.0 use `config.yaml` instead of `flink-conf.yaml`
- Only RocksDB state backend is supported
- Iceberg runtime JAR is only available for Flink <=1.20.0 (not 2.0.0 yet)

⚠️ **Docker Network:**
- If you want to change docker network name and sub ipv4, you make unsure to change correctly all configuration setting.

## Documentation Links

- [Apache Flink SQL Client Documentation](https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sqlclient/)
- [Apache Flink Class Loader Documantation](https://nightlies.apache.org/flink/flink-docs-master/docs/ops/debugging/debugging_classloading/)
- [Apache Flink Configuration Options](https://nightlies.apache.org/flink/flink-docs-master/docs/deployment/config/)
- [Apache Flink Offical Streaming Proje Example](https://flink.apache.org/2020/07/28/flink-sql-demo-building-an-end-to-end-streaming-application/#preparation)
- [Apache Flink Kafka Documantation](https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/table/kafka/)
- [Apache Iceberg CoW and MoR](https://estuary.dev/blog/apache-iceberg-cow-vs-mor/)
- [Apache Kafka Client and Configuration Documantation](https://kafka.apache.org/documentation/#configuration)
- [Apache Kafka DQL Dead Letter Queue](https://www.kai-waehner.de/blog/2022/05/30/error-handling-via-dead-letter-queue-in-apache-kafka/)
- [Apache Flink Connector's Data Format](https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/table/formats/overview/)
