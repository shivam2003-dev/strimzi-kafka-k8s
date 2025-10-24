# Kafka Topics Management

## Understanding Kafka Topics

A Kafka topic is a category or feed name to which records are published. Topics in Kafka are always multi-subscriber; that is, a topic can have zero, one, or many consumers that subscribe to the data written to it.

## Creating Topics with Strimzi

Strimzi uses Kubernetes Custom Resources to manage topics declaratively.

### Apply Topic Configurations

```bash
# Create all topics
kubectl apply -f 03-kafka-topics.yaml

# List all topics
kubectl get kafkatopics -n kafka

# Describe a specific topic
kubectl describe kafkatopic test-topic -n kafka
```

## Topic Types and Use Cases

### 1. Simple Topic (`test-topic`)

**Use Case**: General-purpose testing and development

```yaml
spec:
  partitions: 3
  replicas: 3
  config:
    retention.ms: 604800000  # 7 days
```

**When to use**:
- Development and testing
- Low to medium throughput applications
- General event streaming

### 2. High-Throughput Topic (`high-throughput-topic`)

**Use Case**: High-volume data ingestion

```yaml
spec:
  partitions: 10
  replicas: 3
  config:
    compression.type: lz4
    retention.ms: 86400000  # 1 day
```

**When to use**:
- IoT data streams
- Log aggregation
- Real-time analytics pipelines
- High-frequency trading data

### 3. Compacted Topic (`compacted-topic`)

**Use Case**: Event sourcing and state management

```yaml
spec:
  config:
    cleanup.policy: compact
```

**When to use**:
- Database change data capture (CDC)
- Maintaining latest state per key
- Configuration management
- User profile updates

### 4. Events Topic (`user-events`)

**Use Case**: Event-driven architecture

```yaml
spec:
  partitions: 5
  replicas: 3
  config:
    retention.ms: 2592000000  # 30 days
    compression.type: snappy
```

**When to use**:
- User activity tracking
- Microservices communication
- Event sourcing patterns
- Audit logs

### 5. Logs Topic (`application-logs`)

**Use Case**: Centralized logging

```yaml
spec:
  config:
    retention.bytes: 10737418240  # 10GB
    compression.type: gzip
```

**When to use**:
- Application logs
- System metrics
- Error tracking
- Debugging information

## Testing Topics

### Using Kafka Console Tools

```bash
# Get a shell in the kafka-client pod
kubectl exec -it kafka-client -n kafka -- /bin/bash

# List all topics
bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --list

# Describe a topic
bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --describe --topic test-topic

# Produce messages
bin/kafka-console-producer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic test-topic

# Consume messages
bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic test-topic --from-beginning
```

### Using kubectl

```bash
# Produce a message
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Consume messages
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning
```

## Topic Configuration Parameters

### Retention Settings

- `retention.ms`: How long to keep messages (milliseconds)
- `retention.bytes`: Maximum size of log before deleting old segments

### Performance Settings

- `compression.type`: none, gzip, snappy, lz4, zstd
- `segment.bytes`: Size of log segments
- `min.insync.replicas`: Minimum replicas that must acknowledge a write

### Cleanup Policies

- `delete`: Delete old segments (default)
- `compact`: Keep only the latest value for each key
- `compact,delete`: Both compaction and deletion

## Advanced Topic Operations

### Modify Topic Configuration

```bash
# Edit the KafkaTopic resource
kubectl edit kafkatopic test-topic -n kafka

# Or update the YAML file and reapply
kubectl apply -f 03-kafka-topics.yaml
```

### Increase Partitions

```yaml
# Edit the topic
spec:
  partitions: 6  # Increased from 3
```

**Note**: You can only increase partitions, not decrease them.

### Delete a Topic

```bash
# Delete using kubectl
kubectl delete kafkatopic test-topic -n kafka

# The actual Kafka topic will be deleted automatically
```

## Topic Monitoring

### Check Topic Status

```bash
# Get topic details
kubectl get kafkatopic test-topic -n kafka -o yaml

# Check topic metrics
kubectl exec -it kafka-client -n kafka -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list my-cluster-kafka-bootstrap:9092 \
  --topic test-topic
```

### View Consumer Groups

```bash
# List consumer groups
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list

# Describe a consumer group
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group test-consumer-group
```

## Best Practices

1. **Partitioning Strategy**
   - More partitions = higher throughput
   - But more partitions = more overhead
   - Start with 3-5 partitions, scale as needed

2. **Replication Factor**
   - Always use at least 3 replicas in production
   - Ensures high availability
   - Protects against broker failures

3. **Retention Policy**
   - Balance between storage costs and data availability
   - Use compaction for state topics
   - Use time-based retention for event streams

4. **Compression**
   - Use `lz4` for balanced performance
   - Use `gzip` for maximum compression
   - Use `snappy` for low CPU overhead

## Next Steps

- [Configure Users and Security](03-users-security.md)
- [Deploy Test Applications](04-test-applications.md)

