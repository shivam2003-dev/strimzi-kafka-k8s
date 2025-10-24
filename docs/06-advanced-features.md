# Advanced Kafka Features

## Overview

This guide covers advanced Kafka features and configurations for production use cases.

## Kafka Connect

Kafka Connect is a framework for connecting Kafka with external systems.

### Deploy Kafka Connect

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnect
metadata:
  name: my-connect-cluster
  namespace: kafka
  annotations:
    strimzi.io/use-connector-resources: "true"
spec:
  version: 3.6.0
  replicas: 3
  bootstrapServers: my-cluster-kafka-bootstrap:9092
  config:
    group.id: connect-cluster
    offset.storage.topic: connect-cluster-offsets
    config.storage.topic: connect-cluster-configs
    status.storage.topic: connect-cluster-status
    config.storage.replication.factor: 3
    offset.storage.replication.factor: 3
    status.storage.replication.factor: 3
  build:
    output:
      type: docker
      image: my-connect-image:latest
    plugins:
      - name: debezium-postgres-connector
        artifacts:
          - type: tgz
            url: https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.0.Final/debezium-connector-postgres-2.4.0.Final-plugin.tar.gz
```

### Example: File Source Connector

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnector
metadata:
  name: file-source-connector
  namespace: kafka
  labels:
    strimzi.io/cluster: my-connect-cluster
spec:
  class: FileStreamSource
  tasksMax: 1
  config:
    file: "/tmp/test.txt"
    topic: connect-test
```

## Kafka Streams

Kafka Streams is a library for building stream processing applications.

### Example: Word Count Application

```python
from kafka import KafkaConsumer, KafkaProducer
from collections import defaultdict
import json

# Simple word count stream processor
consumer = KafkaConsumer(
    'input-topic',
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    group_id='word-count-app',
    value_deserializer=lambda x: x.decode('utf-8')
)

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

word_counts = defaultdict(int)

for message in consumer:
    words = message.value.split()
    for word in words:
        word_counts[word] += 1
        producer.send('word-count-output', {
            'word': word,
            'count': word_counts[word]
        })
```

## Kafka MirrorMaker 2

MirrorMaker 2 replicates data between Kafka clusters.

### Deploy MirrorMaker 2

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaMirrorMaker2
metadata:
  name: my-mirror-maker-2
  namespace: kafka
spec:
  version: 3.6.0
  replicas: 1
  connectCluster: "target"
  clusters:
  - alias: "source"
    bootstrapServers: source-cluster-kafka-bootstrap:9092
  - alias: "target"
    bootstrapServers: my-cluster-kafka-bootstrap:9092
  mirrors:
  - sourceCluster: "source"
    targetCluster: "target"
    sourceConnector:
      config:
        replication.factor: 3
        offset-syncs.topic.replication.factor: 3
        sync.topic.acls.enabled: "false"
    heartbeatConnector:
      config:
        heartbeats.topic.replication.factor: 3
    checkpointConnector:
      config:
        checkpoints.topic.replication.factor: 3
    topicsPattern: ".*"
    groupsPattern: ".*"
```

## Message Compression

### Configure Compression

```yaml
# In topic configuration
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: compressed-topic
  namespace: kafka
spec:
  partitions: 3
  replicas: 3
  config:
    compression.type: lz4  # Options: none, gzip, snappy, lz4, zstd
```

### Compression Comparison

| Type   | Compression Ratio | CPU Usage | Speed  | Use Case                    |
|--------|------------------|-----------|--------|----------------------------|
| none   | 1x               | None      | Fastest| Low latency, high CPU cost |
| lz4    | 2-3x             | Low       | Fast   | Balanced (recommended)     |
| snappy | 2-3x             | Low       | Fast   | Similar to lz4             |
| gzip   | 3-4x             | High      | Slow   | Storage optimization       |
| zstd   | 3-4x             | Medium    | Medium | Best compression ratio     |

## Transactions

Kafka supports exactly-once semantics through transactions.

### Transactional Producer

```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    transactional_id='my-transactional-id',
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    enable_idempotence=True,
    acks='all'
)

producer.init_transactions()

try:
    producer.begin_transaction()
    
    # Send multiple messages atomically
    producer.send('topic1', {'data': 'message1'})
    producer.send('topic2', {'data': 'message2'})
    producer.send('topic3', {'data': 'message3'})
    
    producer.commit_transaction()
    print("Transaction committed")
except Exception as e:
    producer.abort_transaction()
    print(f"Transaction aborted: {e}")
finally:
    producer.close()
```

### Transactional Consumer

```python
from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'topic1',
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    group_id='transactional-consumer',
    isolation_level='read_committed',  # Only read committed messages
    enable_auto_commit=False
)

for message in consumer:
    try:
        # Process message
        process(message.value)
        
        # Manually commit offset
        consumer.commit()
    except Exception as e:
        print(f"Error processing message: {e}")
```

## Quotas

Control resource usage with quotas.

### Configure User Quotas

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: quota-user
  namespace: kafka
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: scram-sha-512
  quotas:
    producerByteRate: 1048576      # 1 MB/s
    consumerByteRate: 2097152      # 2 MB/s
    requestPercentage: 55          # 55% of broker time
    controllerMutationRate: 10     # 10 mutations/s
```

### Set Cluster-Wide Quotas

```bash
# Set default producer quota
kubectl exec -it kafka-client -n kafka -- bin/kafka-configs.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --alter \
  --add-config 'producer_byte_rate=1048576' \
  --entity-type users \
  --entity-default

# Set default consumer quota
kubectl exec -it kafka-client -n kafka -- bin/kafka-configs.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --alter \
  --add-config 'consumer_byte_rate=2097152' \
  --entity-type users \
  --entity-default
```

## Log Compaction

Log compaction retains only the latest value for each key.

### Configure Compacted Topic

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: user-profiles
  namespace: kafka
spec:
  partitions: 3
  replicas: 3
  config:
    cleanup.policy: compact
    segment.ms: 3600000                    # 1 hour
    min.compaction.lag.ms: 0               # Compact immediately
    delete.retention.ms: 86400000          # Keep tombstones for 1 day
    min.cleanable.dirty.ratio: 0.5         # Compact when 50% dirty
```

### Use Compacted Topics

```python
from kafka import KafkaProducer, KafkaConsumer
import json

# Producer: Update user profile
producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    key_serializer=lambda k: k.encode('utf-8'),
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Each user_id is a key
producer.send('user-profiles', 
              key='user123',
              value={'name': 'John', 'email': 'john@example.com'})

# Later update (will replace previous value after compaction)
producer.send('user-profiles',
              key='user123',
              value={'name': 'John Doe', 'email': 'johndoe@example.com'})

# Delete a user (send null value - tombstone)
producer.send('user-profiles', key='user456', value=None)
```

## Schema Registry

While not part of core Kafka, Schema Registry is commonly used.

### Deploy Schema Registry

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: schema-registry
  namespace: kafka
spec:
  replicas: 1
  selector:
    matchLabels:
      app: schema-registry
  template:
    metadata:
      labels:
        app: schema-registry
    spec:
      containers:
      - name: schema-registry
        image: confluentinc/cp-schema-registry:7.5.0
        ports:
        - containerPort: 8081
        env:
        - name: SCHEMA_REGISTRY_HOST_NAME
          value: schema-registry
        - name: SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS
          value: my-cluster-kafka-bootstrap:9092
        - name: SCHEMA_REGISTRY_LISTENERS
          value: http://0.0.0.0:8081
---
apiVersion: v1
kind: Service
metadata:
  name: schema-registry
  namespace: kafka
spec:
  ports:
  - port: 8081
    targetPort: 8081
  selector:
    app: schema-registry
```

## Rack Awareness

Distribute replicas across availability zones.

### Configure Rack Awareness

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 3
    rack:
      topologyKey: topology.kubernetes.io/zone
    # ... rest of configuration
```

## Cruise Control

Automate cluster rebalancing and optimization.

### Deploy Cruise Control

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    # ... kafka config
  cruiseControl:
    brokerCapacity:
      inboundNetwork: "10000KB/s"
      outboundNetwork: "10000KB/s"
    config:
      default.goals: >
        com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal,
        com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal,
        com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal
      cpu.balance.threshold: "1.1"
      disk.balance.threshold: "1.1"
```

## Multi-Tenancy

Isolate workloads in a shared cluster.

### Strategy 1: Topic Prefixes

```yaml
# Tenant A topics: tenant-a-*
# Tenant B topics: tenant-b-*

apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: tenant-a-user
  namespace: kafka
spec:
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: tenant-a-
          patternType: prefix
        operation: All
```

### Strategy 2: Separate Clusters

```yaml
# Deploy multiple Kafka clusters
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: tenant-a-cluster
  namespace: kafka-tenant-a
# ...

apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: tenant-b-cluster
  namespace: kafka-tenant-b
# ...
```

## Best Practices Summary

1. **Use compression** for bandwidth optimization
2. **Enable transactions** for exactly-once semantics
3. **Implement quotas** to prevent resource exhaustion
4. **Use log compaction** for state management
5. **Deploy Schema Registry** for data governance
6. **Enable rack awareness** for high availability
7. **Monitor with Cruise Control** for automated optimization
8. **Plan multi-tenancy** strategy early

## Next Steps

- [Troubleshooting Guide](07-troubleshooting.md)
- [Production Checklist](08-production-checklist.md)

