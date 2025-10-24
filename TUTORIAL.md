# Complete Strimzi Kafka Tutorial

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Basic Operations](#basic-operations)
5. [Advanced Topics](#advanced-topics)
6. [Real-World Examples](#real-world-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Introduction

### What is Apache Kafka?

Apache Kafka is a distributed streaming platform that:
- Publishes and subscribes to streams of records (like a message queue)
- Stores streams of records in a fault-tolerant, durable way
- Processes streams of records as they occur

### What is Strimzi?

Strimzi is a Kubernetes operator that simplifies:
- Deploying Kafka clusters on Kubernetes
- Managing Kafka configuration
- Handling upgrades and scaling
- Providing monitoring and security

### Why Use Strimzi?

✅ **Declarative Configuration**: Define Kafka resources as YAML  
✅ **Kubernetes Native**: Leverages Kubernetes features  
✅ **Automated Operations**: Handles complex operational tasks  
✅ **Production Ready**: Battle-tested in production environments  

## Architecture Overview

### Cluster Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Kafka Namespace                        │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────┐     │    │
│  │  │     Strimzi Cluster Operator             │     │    │
│  │  │  (Manages Kafka & ZooKeeper resources)   │     │    │
│  │  └──────────────────────────────────────────┘     │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │         Kafka Cluster                       │  │    │
│  │  │                                             │  │    │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │    │
│  │  │  │  Kafka   │  │  Kafka   │  │  Kafka   │ │  │    │
│  │  │  │ Broker 0 │  │ Broker 1 │  │ Broker 2 │ │  │    │
│  │  │  └──────────┘  └──────────┘  └──────────┘ │  │    │
│  │  │                                             │  │    │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │    │
│  │  │  │ZooKeeper │  │ZooKeeper │  │ZooKeeper │ │  │    │
│  │  │  │  Node 0  │  │  Node 1  │  │  Node 2  │ │  │    │
│  │  │  └──────────┘  └──────────┘  └──────────┘ │  │    │
│  │  │                                             │  │    │
│  │  │  ┌──────────────────────────────────────┐  │  │    │
│  │  │  │      Entity Operator                 │  │  │    │
│  │  │  │  - Topic Operator                    │  │  │    │
│  │  │  │  - User Operator                     │  │  │    │
│  │  │  └──────────────────────────────────────┘  │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │         Monitoring Stack                    │  │    │
│  │  │  ┌────────────┐      ┌─────────────┐       │  │    │
│  │  │  │ Prometheus │      │   Grafana   │       │  │    │
│  │  │  └────────────┘      └─────────────┘       │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Producer → Kafka Broker → Topic → Partition → Consumer
              ↓
         ZooKeeper (metadata)
```

## Installation

### Step-by-Step Installation

#### 1. Prerequisites Check

```bash
# Check Kubernetes is running
kubectl cluster-info

# Check available resources
kubectl top nodes

# Verify you have sufficient resources:
# - 4+ CPU cores
# - 8+ GB RAM
# - 20+ GB disk
```

#### 2. Install Strimzi Operator

```bash
# Apply operator configuration
kubectl apply -f 01-strimzi-operator.yaml

# Verify operator is running
kubectl get pods -n kafka -w

# Wait for operator to be ready
kubectl wait --for=condition=ready pod \
  -l name=strimzi-cluster-operator \
  -n kafka \
  --timeout=300s
```

**What happens:**
- Creates `kafka` namespace
- Installs Custom Resource Definitions (CRDs)
- Deploys Strimzi operator pod
- Sets up RBAC permissions

#### 3. Deploy Kafka Cluster

```bash
# Deploy Kafka cluster
kubectl apply -f 02-kafka-cluster.yaml

# Monitor deployment
kubectl get kafka my-cluster -n kafka -w

# Wait for cluster to be ready (5-10 minutes)
kubectl wait kafka/my-cluster \
  --for=condition=Ready \
  --timeout=600s \
  -n kafka
```

**What happens:**
- Creates 3 Kafka broker pods
- Creates 3 ZooKeeper pods
- Creates entity operator pod
- Sets up services and networking
- Configures persistent storage

#### 4. Create Topics

```bash
# Create topics
kubectl apply -f 03-kafka-topics.yaml

# Verify topics
kubectl get kafkatopics -n kafka

# Check topic details
kubectl describe kafkatopic test-topic -n kafka
```

#### 5. Create Users

```bash
# Create users with authentication
kubectl apply -f 04-kafka-users.yaml

# Verify users
kubectl get kafkausers -n kafka

# Get user password
kubectl get secret producer-user -n kafka \
  -o jsonpath='{.data.password}' | base64 -d
```

## Basic Operations

### Working with Topics

#### Create a Topic

```bash
# Method 1: Using kubectl
cat <<EOF | kubectl apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: orders
  namespace: kafka
  labels:
    strimzi.io/cluster: my-cluster
spec:
  partitions: 5
  replicas: 3
  config:
    retention.ms: 604800000
    compression.type: lz4
EOF

# Method 2: Using Kafka tools
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --create \
  --topic orders \
  --partitions 5 \
  --replication-factor 3
```

#### List Topics

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list
```

#### Describe Topic

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --topic orders
```

#### Modify Topic

```bash
# Increase partitions
kubectl patch kafkatopic orders -n kafka \
  --type merge \
  -p '{"spec":{"partitions":10}}'

# Update configuration
kubectl patch kafkatopic orders -n kafka \
  --type merge \
  -p '{"spec":{"config":{"retention.ms":"1209600000"}}}'
```

#### Delete Topic

```bash
kubectl delete kafkatopic orders -n kafka
```

### Producing Messages

#### Simple Text Messages

```bash
# Interactive producer
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Type messages and press Enter
# Press Ctrl+D to exit
```

#### Messages with Keys

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --property "parse.key=true" \
  --property "key.separator=:"

# Type: key1:value1
# Messages with same key go to same partition
```

#### Batch Messages

```bash
# From file
cat messages.txt | kubectl exec -i kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Multiple messages
echo -e "message1\nmessage2\nmessage3" | \
  kubectl exec -i kafka-client -n kafka -- \
  bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic
```

### Consuming Messages

#### From Beginning

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning
```

#### Latest Messages

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic
```

#### With Consumer Group

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --group my-consumer-group \
  --from-beginning
```

#### Specific Partition

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --partition 0 \
  --from-beginning
```

### Consumer Groups

#### List Consumer Groups

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list
```

#### Describe Consumer Group

```bash
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group my-consumer-group
```

#### Reset Consumer Offset

```bash
# Reset to earliest
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --group my-consumer-group \
  --reset-offsets \
  --to-earliest \
  --topic test-topic \
  --execute

# Reset to specific offset
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --group my-consumer-group \
  --reset-offsets \
  --to-offset 100 \
  --topic test-topic \
  --execute
```

## Advanced Topics

### Authentication and Authorization

#### Using SCRAM-SHA-512

```python
from kafka import KafkaProducer, KafkaConsumer

# Get password from Kubernetes secret
# kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    security_protocol='SASL_PLAINTEXT',
    sasl_mechanism='SCRAM-SHA-512',
    sasl_plain_username='producer-user',
    sasl_plain_password='<password-from-secret>'
)

producer.send('test-topic', b'Authenticated message')
producer.close()
```

### Transactions

```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    transactional_id='my-transaction-id',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

producer.init_transactions()

try:
    producer.begin_transaction()
    
    # All these messages are committed atomically
    producer.send('orders', {'order_id': 1, 'amount': 100})
    producer.send('payments', {'order_id': 1, 'status': 'paid'})
    producer.send('inventory', {'product_id': 1, 'quantity': -1})
    
    producer.commit_transaction()
except Exception as e:
    producer.abort_transaction()
    print(f"Transaction failed: {e}")
finally:
    producer.close()
```

### Exactly-Once Semantics

```python
from kafka import KafkaProducer, KafkaConsumer

# Producer with idempotence
producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    enable_idempotence=True,
    acks='all',
    retries=3,
    max_in_flight_requests_per_connection=5
)

# Consumer reading committed messages only
consumer = KafkaConsumer(
    'orders',
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    group_id='order-processor',
    isolation_level='read_committed',
    enable_auto_commit=False
)

for message in consumer:
    try:
        process_order(message.value)
        consumer.commit()
    except Exception as e:
        print(f"Error: {e}")
        # Don't commit, will retry
```

## Real-World Examples

### Example 1: E-commerce Order Processing

```python
from kafka import KafkaProducer, KafkaConsumer
import json
from datetime import datetime

# Order Service - Produces orders
class OrderService:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    
    def create_order(self, user_id, items, total):
        order = {
            'order_id': generate_order_id(),
            'user_id': user_id,
            'items': items,
            'total': total,
            'timestamp': datetime.now().isoformat(),
            'status': 'pending'
        }
        
        self.producer.send('orders', value=order, key=str(user_id).encode())
        print(f"Order created: {order['order_id']}")
        
        return order

# Payment Service - Processes payments
class PaymentService:
    def __init__(self):
        self.consumer = KafkaConsumer(
            'orders',
            bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
            group_id='payment-service',
            value_deserializer=lambda x: json.loads(x.decode('utf-8'))
        )
        
        self.producer = KafkaProducer(
            bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    
    def process_payments(self):
        for message in self.consumer:
            order = message.value
            
            # Process payment
            payment_result = self.charge_payment(order)
            
            # Publish payment event
            self.producer.send('payments', value={
                'order_id': order['order_id'],
                'status': payment_result['status'],
                'timestamp': datetime.now().isoformat()
            })
```

### Example 2: Real-time Analytics

```python
from kafka import KafkaConsumer
from collections import defaultdict
import json

class AnalyticsEngine:
    def __init__(self):
        self.consumer = KafkaConsumer(
            'user-events',
            bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
            group_id='analytics-engine',
            value_deserializer=lambda x: json.loads(x.decode('utf-8'))
        )
        
        self.metrics = defaultdict(int)
    
    def process_events(self):
        for message in self.consumer:
            event = message.value
            
            # Update metrics
            self.metrics[event['event_type']] += 1
            self.metrics['total_events'] += 1
            
            # Real-time aggregation
            if self.metrics['total_events'] % 1000 == 0:
                self.publish_metrics()
    
    def publish_metrics(self):
        print(f"Metrics: {dict(self.metrics)}")
```

### Example 3: Log Aggregation

```python
import logging
from kafka import KafkaProducer
import json

class KafkaLogHandler(logging.Handler):
    def __init__(self, bootstrap_servers, topic):
        super().__init__()
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.topic = topic
    
    def emit(self, record):
        log_entry = {
            'timestamp': record.created,
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName
        }
        
        self.producer.send(self.topic, value=log_entry)

# Usage
logger = logging.getLogger('myapp')
kafka_handler = KafkaLogHandler(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    topic='application-logs'
)
logger.addHandler(kafka_handler)

logger.info("Application started")
logger.error("An error occurred")
```

## Best Practices

### 1. Topic Design

✅ **Use meaningful topic names**: `orders`, `payments`, `user-events`  
✅ **Plan partition count**: More partitions = higher throughput  
✅ **Set appropriate replication**: Use 3 replicas for production  
✅ **Configure retention**: Balance storage cost vs data availability  

### 2. Producer Best Practices

✅ **Use compression**: `lz4` for balanced performance  
✅ **Batch messages**: Improves throughput  
✅ **Handle errors**: Implement retry logic  
✅ **Use keys wisely**: Ensures ordering per key  

### 3. Consumer Best Practices

✅ **Use consumer groups**: Enables parallel processing  
✅ **Commit offsets carefully**: Avoid data loss or duplication  
✅ **Handle rebalancing**: Implement proper cleanup  
✅ **Monitor lag**: Keep lag under control  

### 4. Security Best Practices

✅ **Enable authentication**: Use SCRAM or TLS  
✅ **Implement authorization**: Use ACLs  
✅ **Encrypt in transit**: Use TLS listeners  
✅ **Rotate credentials**: Regular password updates  

### 5. Operations Best Practices

✅ **Monitor everything**: Use Prometheus + Grafana  
✅ **Set up alerts**: Under-replicated partitions, lag, etc.  
✅ **Regular backups**: Export important topics  
✅ **Test disaster recovery**: Practice cluster recovery  

## Troubleshooting

### Common Issues

#### Issue: Pods Not Starting

```bash
# Check pod status
kubectl get pods -n kafka

# Check events
kubectl describe pod <pod-name> -n kafka

# Check logs
kubectl logs <pod-name> -n kafka

# Common causes:
# - Insufficient resources
# - Storage issues
# - Configuration errors
```

#### Issue: Can't Produce/Consume Messages

```bash
# Test connectivity
kubectl exec -it kafka-client -n kafka -- \
  nc -zv my-cluster-kafka-bootstrap 9092

# Check broker status
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-broker-api-versions.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092

# Check topic exists
kubectl get kafkatopics -n kafka
```

#### Issue: High Consumer Lag

```bash
# Check lag
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group <group-name>

# Solutions:
# 1. Scale consumers
# 2. Increase partitions
# 3. Optimize consumer code
# 4. Increase consumer resources
```

#### Issue: Under-Replicated Partitions

```bash
# Check under-replicated partitions
kubectl exec -it kafka-client -n kafka -- \
  bin/kafka-topics.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --under-replicated-partitions

# Check broker health
kubectl get pods -n kafka | grep kafka

# Check broker logs
kubectl logs my-cluster-kafka-0 -n kafka
```

## Conclusion

You now have a comprehensive understanding of:
- Kafka architecture and concepts
- Strimzi operator and deployment
- Basic and advanced operations
- Real-world usage patterns
- Best practices and troubleshooting

### Next Steps

1. Deploy your own applications
2. Implement monitoring and alerting
3. Test disaster recovery procedures
4. Explore Kafka Streams and Connect
5. Optimize for your specific use case

Happy streaming! 🚀

