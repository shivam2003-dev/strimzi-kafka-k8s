# Getting Started with Strimzi Kafka on Kubernetes

## Overview

This guide will walk you through deploying Apache Kafka on Kubernetes using Strimzi, a Kubernetes operator that simplifies Kafka deployment and management.

## What is Strimzi?

Strimzi provides a way to run Apache Kafka on Kubernetes in various deployment configurations. It uses the Operator pattern to manage Kafka clusters, topics, and users.

## Prerequisites

Before starting, ensure you have:

1. **Kubernetes Cluster**: 
   - Minikube (for local development)
   - Kind (Kubernetes in Docker)
   - Cloud provider (GKE, EKS, AKS)
   
2. **kubectl**: Configured to access your cluster

3. **Resources**: 
   - At least 4 CPU cores
   - 8GB RAM
   - 20GB disk space

## Setting Up Your Environment

### Option 1: Using Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=20g

# Verify cluster is running
kubectl cluster-info
```

### Option 2: Using Kind

```bash
# Create a Kind cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

# Verify cluster is running
kubectl get nodes
```

## Step 1: Install Strimzi Operator

The Strimzi operator manages Kafka clusters and related resources.

```bash
# Apply the Strimzi operator installation
kubectl apply -f 01-strimzi-operator.yaml

# Wait for the operator to be ready
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n kafka --timeout=300s

# Verify operator is running
kubectl get pods -n kafka
```

Expected output:
```
NAME                                        READY   STATUS    RESTARTS   AGE
strimzi-cluster-operator-7d96cbf9c4-xxxxx   1/1     Running   0          1m
```

## Step 2: Deploy Kafka Cluster

```bash
# Create the Kafka cluster
kubectl apply -f 02-kafka-cluster.yaml

# Monitor the deployment (this takes 3-5 minutes)
kubectl get kafka -n kafka -w

# Check all pods are running
kubectl get pods -n kafka
```

You should see:
- 3 Kafka broker pods
- 3 ZooKeeper pods
- Entity operator pod
- Kafka exporter pod

```
NAME                                          READY   STATUS    RESTARTS   AGE
my-cluster-entity-operator-xxxxxxxxxx-xxxxx   3/3     Running   0          2m
my-cluster-kafka-0                            1/1     Running   0          3m
my-cluster-kafka-1                            1/1     Running   0          3m
my-cluster-kafka-2                            1/1     Running   0          3m
my-cluster-zookeeper-0                        1/1     Running   0          4m
my-cluster-zookeeper-1                        1/1     Running   0          4m
my-cluster-zookeeper-2                        1/1     Running   0          4m
```

## Step 3: Verify Kafka Cluster

```bash
# Check cluster status
kubectl get kafka my-cluster -n kafka -o yaml

# Check services
kubectl get svc -n kafka

# Test connectivity
kubectl run kafka-test-client --restart='Never' --image quay.io/strimzi/kafka:0.38.0-kafka-3.6.0 -n kafka -- sleep infinity

kubectl exec -it kafka-test-client -n kafka -- bin/kafka-broker-api-versions.sh --bootstrap-server my-cluster-kafka-bootstrap:9092
```

## Understanding the Components

### Kafka Brokers
- 3 replicas for high availability
- Persistent storage for data durability
- Configured with optimal settings for production

### ZooKeeper
- 3 replicas for consensus
- Manages Kafka cluster metadata
- Handles leader election

### Entity Operator
- **Topic Operator**: Manages KafkaTopic resources
- **User Operator**: Manages KafkaUser resources

## Next Steps

1. [Create Kafka Topics](02-topics.md)
2. [Configure Users and Security](03-users-security.md)
3. [Deploy Test Applications](04-test-applications.md)
4. [Monitor Your Cluster](05-monitoring.md)

## Troubleshooting

### Operator not starting
```bash
kubectl logs deployment/strimzi-cluster-operator -n kafka
```

### Kafka pods not ready
```bash
kubectl describe pod my-cluster-kafka-0 -n kafka
kubectl logs my-cluster-kafka-0 -n kafka
```

### Insufficient resources
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes
```

## Clean Up

To remove everything:
```bash
kubectl delete -f 05-test-applications.yaml
kubectl delete -f 04-kafka-users.yaml
kubectl delete -f 03-kafka-topics.yaml
kubectl delete -f 02-kafka-cluster.yaml
kubectl delete -f 01-strimzi-operator.yaml
kubectl delete namespace kafka
```

