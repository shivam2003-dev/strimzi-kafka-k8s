# Strimzi Kafka on Kubernetes Tutorial

This tutorial will guide you through setting up Apache Kafka on Kubernetes using Strimzi, a Kubernetes operator for Kafka.

## What You'll Learn

1. **Strimzi Operator Installation** - Deploy the Strimzi operator to manage Kafka clusters
2. **Kafka Cluster Setup** - Create and configure a Kafka cluster
3. **Topic Management** - Create and manage Kafka topics
4. **User Authentication** - Set up Kafka users with authentication
5. **Testing Applications** - Deploy producer and consumer applications
6. **Monitoring and Management** - Monitor your Kafka cluster

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- Basic understanding of Kubernetes and Kafka concepts

## Quick Start

1. Install Strimzi operator:
```bash
kubectl apply -f 01-strimzi-operator.yaml
```

2. Create Kafka cluster:
```bash
kubectl apply -f 02-kafka-cluster.yaml
```

3. Create topics:
```bash
kubectl apply -f 03-kafka-topics.yaml
```

4. Create users:
```bash
kubectl apply -f 04-kafka-users.yaml
```

5. Deploy test applications:
```bash
kubectl apply -f 05-test-applications.yaml
```

## File Structure

- `01-strimzi-operator.yaml` - Strimzi operator installation
- `02-kafka-cluster.yaml` - Kafka cluster configuration
- `03-kafka-topics.yaml` - Kafka topics definition
- `04-kafka-users.yaml` - Kafka users and authentication
- `05-test-applications.yaml` - Producer and consumer test apps
- `06-monitoring.yaml` - Monitoring and metrics setup
- `scripts/` - Testing and validation scripts
- `docs/` - Detailed documentation

## Next Steps

Follow the step-by-step guide in the `docs/` directory for detailed instructions.
