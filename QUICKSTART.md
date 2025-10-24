# Strimzi Kafka Quick Start Guide

Get your Kafka cluster running on Kubernetes in minutes!

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl installed and configured
- At least 4 CPU cores and 8GB RAM available

## Quick Setup (5 minutes)

### Option 1: Automated Setup

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the automated setup
./scripts/setup-cluster.sh
```

This script will:
1. Install Strimzi operator
2. Deploy Kafka cluster (3 brokers + 3 ZooKeeper nodes)
3. Create sample topics
4. Create users with authentication
5. Deploy test applications
6. Set up monitoring (Prometheus + Grafana)

### Option 2: Manual Setup

```bash
# 1. Install Strimzi operator
kubectl apply -f 01-strimzi-operator.yaml

# Wait for operator
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n kafka --timeout=300s

# 2. Deploy Kafka cluster
kubectl apply -f 02-kafka-cluster.yaml

# Wait for Kafka (takes 5-10 minutes)
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=600s -n kafka

# 3. Create topics
kubectl apply -f 03-kafka-topics.yaml

# 4. Create users
kubectl apply -f 04-kafka-users.yaml

# 5. Deploy test applications
kubectl apply -f 05-test-applications.yaml

# 6. Deploy monitoring
kubectl apply -f 06-monitoring.yaml
```

## Verify Installation

```bash
# Check all pods are running
kubectl get pods -n kafka

# You should see:
# - 3 Kafka broker pods
# - 3 ZooKeeper pods
# - 1 entity operator pod
# - Test application pods
# - Monitoring pods
```

## Test Your Cluster

### Quick Test

```bash
# Run automated tests
./scripts/test-kafka.sh
```

### Manual Test

```bash
# Access Kafka client pod
kubectl exec -it kafka-client -n kafka -- /bin/bash

# Inside the pod:

# List topics
bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --list

# Produce messages
bin/kafka-console-producer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic test-topic

# (Type some messages and press Ctrl+D)

# Consume messages (in another terminal)
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning
```

## Access Monitoring

### Prometheus

```bash
kubectl port-forward svc/prometheus 9090:9090 -n kafka
# Open http://localhost:9090
```

### Grafana

```bash
kubectl port-forward svc/grafana 3000:3000 -n kafka
# Open http://localhost:3000
# Login: admin / admin
```

## Monitor Your Cluster

```bash
# Full monitoring report
./scripts/monitor.sh

# Continuous monitoring
./scripts/monitor.sh --watch

# Check specific components
./scripts/monitor.sh --pods
./scripts/monitor.sh --topics
./scripts/monitor.sh --consumers
```

## Common Operations

### Produce Messages

```bash
# Simple text messages
echo "Hello Kafka" | kubectl exec -i kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Messages with keys
echo "key1:value1" | kubectl exec -i kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --property "parse.key=true" \
  --property "key.separator=:"
```

### Consume Messages

```bash
# From beginning
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning

# Latest messages only
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# With consumer group
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --group my-group
```

### Check Consumer Lag

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group test-consumer-group
```

### Create New Topic

```bash
# Via kubectl
cat <<EOF | kubectl apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: my-new-topic
  namespace: kafka
  labels:
    strimzi.io/cluster: my-cluster
spec:
  partitions: 3
  replicas: 3
  config:
    retention.ms: 604800000
EOF

# Via Kafka tools
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --create \
  --topic my-new-topic \
  --partitions 3 \
  --replication-factor 3
```

## Performance Testing

```bash
# Producer performance
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-producer-perf-test.sh \
  --topic test-topic \
  --num-records 100000 \
  --record-size 1024 \
  --throughput -1 \
  --producer-props bootstrap.servers=my-cluster-kafka-bootstrap:9092

# Consumer performance
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-perf-test.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --messages 100000
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n kafka

# Check pod logs
kubectl logs <pod-name> -n kafka

# Describe pod for events
kubectl describe pod <pod-name> -n kafka
```

### Can't connect to Kafka

```bash
# Check services
kubectl get svc -n kafka

# Test connectivity
kubectl exec -it kafka-client -n kafka -- \
  nc -zv my-cluster-kafka-bootstrap 9092
```

### Topics not creating

```bash
# Check topic operator logs
kubectl logs deployment/my-cluster-entity-operator -n kafka -c topic-operator

# Check topic status
kubectl describe kafkatopic <topic-name> -n kafka
```

## Clean Up

```bash
# Automated cleanup (deletes everything)
./scripts/cleanup.sh

# Manual cleanup
kubectl delete -f 05-test-applications.yaml
kubectl delete -f 04-kafka-users.yaml
kubectl delete -f 03-kafka-topics.yaml
kubectl delete -f 02-kafka-cluster.yaml
kubectl delete -f 01-strimzi-operator.yaml
kubectl delete namespace kafka
```

## What's Included

### YAML Files

- `01-strimzi-operator.yaml` - Strimzi operator installation
- `02-kafka-cluster.yaml` - 3-node Kafka cluster with ZooKeeper
- `03-kafka-topics.yaml` - Sample topics with different configurations
- `04-kafka-users.yaml` - Users with SCRAM-SHA-512 authentication
- `05-test-applications.yaml` - Producer/consumer test apps
- `06-monitoring.yaml` - Prometheus and Grafana

### Scripts

- `setup-cluster.sh` - Automated cluster setup
- `test-kafka.sh` - Comprehensive functionality tests
- `monitor.sh` - Monitoring and health checks
- `cleanup.sh` - Complete cleanup

### Documentation

- `docs/01-getting-started.md` - Detailed setup guide
- `docs/02-topics.md` - Topic management
- `docs/03-users-security.md` - Authentication and authorization
- `docs/04-test-applications.md` - Testing guide
- `docs/05-monitoring.md` - Monitoring with Prometheus/Grafana
- `docs/06-advanced-features.md` - Advanced Kafka features

## Next Steps

1. **Learn the Basics**: Read `docs/01-getting-started.md`
2. **Explore Topics**: Check out `docs/02-topics.md`
3. **Secure Your Cluster**: Read `docs/03-users-security.md`
4. **Test Applications**: Follow `docs/04-test-applications.md`
5. **Set Up Monitoring**: See `docs/05-monitoring.md`
6. **Advanced Features**: Explore `docs/06-advanced-features.md`

## Key Features

✅ Production-ready 3-node Kafka cluster  
✅ High availability with replication  
✅ Persistent storage  
✅ Authentication (SCRAM-SHA-512)  
✅ Authorization (ACLs)  
✅ Multiple listeners (plain, TLS, external)  
✅ Monitoring with Prometheus & Grafana  
✅ Sample topics and test applications  
✅ Automated setup and testing scripts  

## Resources

- [Strimzi Documentation](https://strimzi.io/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `kubectl logs <pod-name> -n kafka`
3. Check Strimzi documentation
4. Review Kafka documentation

Happy Kafka-ing! 🚀

