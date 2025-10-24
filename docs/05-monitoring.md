# Monitoring Kafka with Prometheus and Grafana

## Overview

Monitoring is crucial for maintaining a healthy Kafka cluster. This guide covers setting up Prometheus and Grafana for comprehensive Kafka monitoring.

## Deploy Monitoring Stack

```bash
# Deploy Prometheus and Grafana
kubectl apply -f 06-monitoring.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n kafka --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n kafka --timeout=300s

# Check deployment status
kubectl get pods -n kafka | grep -E 'prometheus|grafana'
```

## Accessing Monitoring Tools

### Access Prometheus

```bash
# Get Prometheus URL (if using Minikube)
minikube service prometheus -n kafka --url

# Or use port-forward
kubectl port-forward svc/prometheus 9090:9090 -n kafka

# Access at: http://localhost:9090
```

### Access Grafana

```bash
# Get Grafana URL (if using Minikube)
minikube service grafana -n kafka --url

# Or use port-forward
kubectl port-forward svc/grafana 3000:3000 -n kafka

# Access at: http://localhost:3000
# Default credentials: admin / admin
```

## Key Metrics to Monitor

### Kafka Broker Metrics

#### 1. Broker Health
- **UnderReplicatedPartitions**: Should be 0
- **OfflinePartitionsCount**: Should be 0
- **ActiveControllerCount**: Should be 1 (on one broker)

```promql
# Prometheus queries
kafka_controller_kafkacontroller_activecontrollercount
kafka_server_replicamanager_underreplicatedpartitions
kafka_server_replicamanager_offlinereplicacount
```

#### 2. Request Metrics
- **RequestsPerSecond**: Throughput indicator
- **RequestLatency**: Performance indicator

```promql
# Request rate
rate(kafka_server_brokertopicmetrics_messagesin_total[5m])

# Request latency
kafka_network_requestmetrics_totaltimems{quantile="0.99"}
```

#### 3. Network Metrics
- **BytesInPerSecond**: Incoming data rate
- **BytesOutPerSecond**: Outgoing data rate

```promql
# Bytes in
rate(kafka_server_brokertopicmetrics_bytesin_total[5m])

# Bytes out
rate(kafka_server_brokertopicmetrics_bytesout_total[5m])
```

### Topic Metrics

```promql
# Messages per topic
kafka_server_brokertopicmetrics_messagesin_total

# Bytes per topic
kafka_server_brokertopicmetrics_bytesin_total

# Failed produce requests
kafka_server_brokertopicmetrics_failedproducerequests_total
```

### Consumer Group Metrics

```promql
# Consumer lag
kafka_consumergroup_lag

# Consumer group members
kafka_consumergroup_members
```

### ZooKeeper Metrics

```promql
# Outstanding requests
zookeeper_outstandingrequests

# Average latency
zookeeper_avgrequestlatency

# Alive connections
zookeeper_numaliveconnections
```

## Using Prometheus

### Explore Metrics

1. Open Prometheus UI: http://localhost:9090
2. Go to "Graph" tab
3. Try these queries:

```promql
# All Kafka metrics
{job="kafka"}

# Broker metrics
kafka_server_brokertopicmetrics_messagesin_total

# Request rate by topic
sum(rate(kafka_server_brokertopicmetrics_messagesin_total[5m])) by (topic)

# 99th percentile request latency
histogram_quantile(0.99, rate(kafka_network_requestmetrics_totaltimems_bucket[5m]))
```

### Set Up Alerts

Create alert rules in Prometheus:

```yaml
# Example alert rules (add to prometheus-config)
groups:
- name: kafka_alerts
  rules:
  - alert: KafkaUnderReplicatedPartitions
    expr: kafka_server_replicamanager_underreplicatedpartitions > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Kafka has under-replicated partitions"
      description: "Broker {{ $labels.instance }} has {{ $value }} under-replicated partitions"
  
  - alert: KafkaOfflinePartitions
    expr: kafka_controller_kafkacontroller_offlinepartitionscount > 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Kafka has offline partitions"
      description: "Cluster has {{ $value }} offline partitions"
  
  - alert: KafkaHighProducerLatency
    expr: kafka_network_requestmetrics_totaltimems{quantile="0.99",request="Produce"} > 1000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High producer latency detected"
      description: "99th percentile produce latency is {{ $value }}ms"
```

## Using Grafana

### Initial Setup

1. Access Grafana: http://localhost:3000
2. Login with admin/admin
3. Change password when prompted
4. Prometheus datasource is pre-configured

### Import Kafka Dashboard

1. Click "+" → "Import"
2. Use these popular Kafka dashboard IDs:
   - **7589**: Kafka Overview
   - **721**: Kafka Exporter Overview
   - **11962**: Strimzi Kafka Dashboard

Or create custom dashboards with these panels:

### Essential Dashboard Panels

#### Panel 1: Broker Health

```promql
# Query
kafka_server_replicamanager_underreplicatedpartitions

# Visualization: Stat
# Thresholds: 0 (green), 1 (yellow), 5 (red)
```

#### Panel 2: Message Rate

```promql
# Query
sum(rate(kafka_server_brokertopicmetrics_messagesin_total[5m]))

# Visualization: Graph
# Unit: messages/sec
```

#### Panel 3: Throughput

```promql
# Query for incoming
sum(rate(kafka_server_brokertopicmetrics_bytesin_total[5m]))

# Query for outgoing
sum(rate(kafka_server_brokertopicmetrics_bytesout_total[5m]))

# Visualization: Graph
# Unit: bytes/sec
```

#### Panel 4: Consumer Lag

```promql
# Query
kafka_consumergroup_lag

# Visualization: Graph
# Group by: group, topic
```

#### Panel 5: Request Latency

```promql
# Query
kafka_network_requestmetrics_totaltimems{quantile="0.99"}

# Visualization: Graph
# Unit: milliseconds
```

## Command-Line Monitoring

### Check Broker Status

```bash
# Get broker IDs
kubectl exec -it kafka-client -n kafka -- bin/kafka-broker-api-versions.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092

# Check broker configs
kubectl exec -it kafka-client -n kafka -- bin/kafka-configs.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --entity-type brokers \
  --entity-default \
  --describe
```

### Monitor Topics

```bash
# List all topics with details
kubectl exec -it kafka-client -n kafka -- bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe

# Get topic metrics
kubectl exec -it kafka-client -n kafka -- bin/kafka-run-class.sh \
  kafka.tools.GetOffsetShell \
  --broker-list my-cluster-kafka-bootstrap:9092 \
  --topic test-topic
```

### Monitor Consumer Groups

```bash
# List all consumer groups
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list

# Describe consumer group (shows lag)
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group test-consumer-group

# Monitor in real-time
watch -n 2 'kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group test-consumer-group'
```

### Check Cluster Metadata

```bash
# Get cluster ID
kubectl exec -it kafka-client -n kafka -- bin/kafka-metadata.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe --cluster

# Check log directories
kubectl exec -it my-cluster-kafka-0 -n kafka -- du -sh /var/lib/kafka/data-0/kafka-log*
```

## Kubernetes-Native Monitoring

### Check Pod Resources

```bash
# CPU and memory usage
kubectl top pods -n kafka

# Detailed resource info
kubectl describe pod my-cluster-kafka-0 -n kafka | grep -A 10 "Limits\|Requests"
```

### Check Persistent Volumes

```bash
# List PVCs
kubectl get pvc -n kafka

# Check PVC usage
kubectl exec -it my-cluster-kafka-0 -n kafka -- df -h /var/lib/kafka
```

### View Logs

```bash
# Kafka broker logs
kubectl logs my-cluster-kafka-0 -n kafka --tail=100 -f

# ZooKeeper logs
kubectl logs my-cluster-zookeeper-0 -n kafka --tail=100 -f

# Strimzi operator logs
kubectl logs deployment/strimzi-cluster-operator -n kafka --tail=100 -f
```

## Performance Tuning Based on Metrics

### High Latency Issues

If you see high latency (>100ms):

```bash
# Check disk I/O
kubectl exec -it my-cluster-kafka-0 -n kafka -- iostat -x 1 5

# Increase broker resources
kubectl edit kafka my-cluster -n kafka
# Increase memory and CPU limits
```

### Under-Replicated Partitions

If under-replicated partitions > 0:

```bash
# Check broker health
kubectl get pods -n kafka | grep kafka

# Check broker logs
kubectl logs my-cluster-kafka-0 -n kafka --tail=100

# Verify network connectivity
kubectl exec -it kafka-client -n kafka -- nc -zv my-cluster-kafka-0.my-cluster-kafka-brokers 9092
```

### High Consumer Lag

If consumer lag is growing:

```bash
# Scale consumers
kubectl scale deployment kafka-consumer --replicas=3 -n kafka

# Or increase partitions
kubectl edit kafkatopic test-topic -n kafka
# Increase partitions count
```

## Health Checks

### Automated Health Check Script

```bash
# Create health check script
cat > /tmp/kafka-health-check.sh <<'EOF'
#!/bin/bash

echo "=== Kafka Cluster Health Check ==="
echo

# Check broker pods
echo "1. Broker Pods:"
kubectl get pods -n kafka -l strimzi.io/name=my-cluster-kafka
echo

# Check ZooKeeper pods
echo "2. ZooKeeper Pods:"
kubectl get pods -n kafka -l strimzi.io/name=my-cluster-zookeeper
echo

# Check topics
echo "3. Topics:"
kubectl exec -it kafka-client -n kafka -- bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list
echo

# Check consumer groups
echo "4. Consumer Groups:"
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list
echo

# Check under-replicated partitions
echo "5. Under-Replicated Partitions:"
kubectl exec -it kafka-client -n kafka -- bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --under-replicated-partitions
echo

echo "=== Health Check Complete ==="
EOF

chmod +x /tmp/kafka-health-check.sh
/tmp/kafka-health-check.sh
```

## Monitoring Best Practices

1. **Set Up Alerts**
   - Under-replicated partitions
   - Offline partitions
   - High latency
   - Disk space usage

2. **Regular Health Checks**
   - Run automated health checks daily
   - Monitor consumer lag
   - Check broker balance

3. **Capacity Planning**
   - Monitor disk usage trends
   - Track message rates
   - Plan for growth

4. **Performance Baselines**
   - Establish normal operating ranges
   - Set appropriate alert thresholds
   - Document expected metrics

## Next Steps

- [Advanced Kafka Features](06-advanced-features.md)
- [Troubleshooting Guide](07-troubleshooting.md)

