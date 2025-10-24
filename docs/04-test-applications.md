# Testing Kafka with Applications

## Overview

This guide covers deploying and testing producer and consumer applications to verify your Kafka cluster functionality.

## Deploying Test Applications

### Apply All Test Applications

```bash
# Deploy all test applications
kubectl apply -f 05-test-applications.yaml

# Check deployment status
kubectl get pods -n kafka | grep -E 'producer|consumer|client'

# Watch logs
kubectl logs -f deployment/kafka-producer -n kafka
kubectl logs -f deployment/kafka-consumer -n kafka
```

## Test Application Types

### 1. Kafka Console Producer

**Purpose**: Simple message producer using Kafka console tools

```bash
# View producer logs
kubectl logs -f deployment/kafka-producer -n kafka

# You should see messages being produced every 5 seconds
```

### 2. Kafka Console Consumer

**Purpose**: Simple message consumer using Kafka console tools

```bash
# View consumer logs
kubectl logs -f deployment/kafka-consumer -n kafka

# You should see messages being consumed
```

### 3. Python Producer

**Purpose**: Demonstrates producing JSON messages using kafka-python

```bash
# Check job status
kubectl get jobs -n kafka

# View job logs
kubectl logs job/python-producer -n kafka

# You should see 100 JSON messages being sent
```

### 4. Python Consumer

**Purpose**: Demonstrates consuming JSON messages using kafka-python

```bash
# View consumer logs
kubectl logs -f deployment/python-consumer -n kafka

# You should see JSON messages being consumed
```

### 5. Kafka Client Pod

**Purpose**: Interactive pod for manual testing

```bash
# Access the client pod
kubectl exec -it kafka-client -n kafka -- /bin/bash

# Now you can run any Kafka commands
```

## Manual Testing Scenarios

### Scenario 1: Basic Producer-Consumer Test

```bash
# Terminal 1: Start a consumer
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning

# Terminal 2: Produce messages
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Type messages and press Enter
# You should see them appear in Terminal 1
```

### Scenario 2: Testing with Keys

```bash
# Producer with keys
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --property "parse.key=true" \
  --property "key.separator=:"

# Type messages like: key1:value1

# Consumer showing keys
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning \
  --property print.key=true \
  --property key.separator=":"
```

### Scenario 3: Testing Partitioning

```bash
# Produce to specific partition
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --property "partitioner.class=org.apache.kafka.clients.producer.RoundRobinPartitioner"

# Consume from specific partition
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --partition 0 \
  --from-beginning
```

### Scenario 4: Consumer Groups

```bash
# Terminal 1: Consumer in group 1
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --group my-consumer-group

# Terminal 2: Another consumer in the same group
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --group my-consumer-group

# Terminal 3: Produce messages
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic

# Messages will be distributed between the two consumers
```

## Performance Testing

### Test 1: Throughput Test

```bash
# Producer performance test
kubectl exec -it kafka-client -n kafka -- bin/kafka-producer-perf-test.sh \
  --topic test-topic \
  --num-records 100000 \
  --record-size 1024 \
  --throughput -1 \
  --producer-props bootstrap.servers=my-cluster-kafka-bootstrap:9092

# Consumer performance test
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-perf-test.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --messages 100000 \
  --threads 1
```

### Test 2: Latency Test

```bash
# End-to-end latency test
kubectl exec -it kafka-client -n kafka -- bin/kafka-run-class.sh \
  kafka.tools.EndToEndLatency \
  my-cluster-kafka-bootstrap:9092 \
  test-topic \
  10000 \
  1 \
  1024
```

## Python Application Examples

### Create a Custom Producer

```bash
# Create a Python producer script
kubectl exec -it kafka-client -n kafka -- bash -c "
cat > /tmp/my_producer.py <<'EOF'
from kafka import KafkaProducer
import json
import time
from datetime import datetime

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    acks='all',
    retries=3
)

for i in range(10):
    message = {
        'id': i,
        'timestamp': datetime.now().isoformat(),
        'message': f'Custom message {i}',
        'metadata': {
            'source': 'custom-producer',
            'priority': 'high' if i % 2 == 0 else 'low'
        }
    }
    
    future = producer.send('test-topic', value=message)
    record_metadata = future.get(timeout=10)
    
    print(f'Sent message {i} to partition {record_metadata.partition} at offset {record_metadata.offset}')
    time.sleep(1)

producer.flush()
producer.close()
print('Producer finished!')
EOF

python3 /tmp/my_producer.py
"
```

### Create a Custom Consumer

```bash
# Create a Python consumer script
kubectl exec -it kafka-client -n kafka -- bash -c "
cat > /tmp/my_consumer.py <<'EOF'
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'test-topic',
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='my-custom-group',
    value_deserializer=lambda x: json.loads(x.decode('utf-8')) if x else None
)

print('Starting consumer...')
message_count = 0

for message in consumer:
    message_count += 1
    print(f'\\nMessage {message_count}:')
    print(f'  Topic: {message.topic}')
    print(f'  Partition: {message.partition}')
    print(f'  Offset: {message.offset}')
    print(f'  Key: {message.key}')
    print(f'  Value: {message.value}')
    
    if message_count >= 10:
        break

consumer.close()
print(f'\\nConsumed {message_count} messages')
EOF

python3 /tmp/my_consumer.py
"
```

## Monitoring Applications

### Check Application Health

```bash
# Check pod status
kubectl get pods -n kafka -l app=kafka-producer
kubectl get pods -n kafka -l app=kafka-consumer

# Check resource usage
kubectl top pod -n kafka | grep -E 'producer|consumer'

# View recent logs
kubectl logs --tail=50 deployment/kafka-producer -n kafka
kubectl logs --tail=50 deployment/kafka-consumer -n kafka
```

### Monitor Consumer Lag

```bash
# Check consumer group lag
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --describe \
  --group test-consumer-group

# Output shows:
# - Current offset
# - Log end offset
# - Lag (difference between the two)
```

## Advanced Testing

### Test Message Ordering

```bash
# Produce messages with the same key (goes to same partition)
kubectl exec -it kafka-client -n kafka -- bash -c '
for i in {1..10}; do
  echo "key1:Message $i"
done | bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --property "parse.key=true" \
  --property "key.separator=:"
'

# Consume and verify order
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --from-beginning \
  --property print.key=true \
  --max-messages 10
```

### Test Exactly-Once Semantics

```bash
# Producer with idempotence
kubectl exec -it kafka-client -n kafka -- bash -c '
cat > /tmp/idempotent-producer.properties <<EOF
enable.idempotence=true
acks=all
retries=3
max.in.flight.requests.per.connection=5
EOF

echo "Test message with idempotence" | bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --producer.config /tmp/idempotent-producer.properties
'
```

### Test Transactional Writes

```bash
# Create a transactional producer script
kubectl exec -it kafka-client -n kafka -- bash -c "
cat > /tmp/transactional.py <<'EOF'
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['my-cluster-kafka-bootstrap:9092'],
    transactional_id='my-transactional-id',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

producer.init_transactions()

try:
    producer.begin_transaction()
    
    for i in range(5):
        producer.send('test-topic', value={'id': i, 'message': f'Transactional message {i}'})
    
    producer.commit_transaction()
    print('Transaction committed successfully')
except Exception as e:
    producer.abort_transaction()
    print(f'Transaction aborted: {e}')
finally:
    producer.close()
EOF

python3 /tmp/transactional.py
"
```

## Troubleshooting Applications

### Producer Issues

```bash
# Check producer logs
kubectl logs deployment/kafka-producer -n kafka --tail=100

# Common issues:
# - Connection refused: Kafka not ready
# - Authentication failed: Check user credentials
# - Topic not found: Create topic first
```

### Consumer Issues

```bash
# Check consumer logs
kubectl logs deployment/kafka-consumer -n kafka --tail=100

# Common issues:
# - No messages: Check producer is running
# - Offset out of range: Reset consumer offset
# - Rebalancing: Normal during consumer group changes
```

### Reset Consumer Offset

```bash
# Reset to earliest
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --group test-consumer-group \
  --reset-offsets \
  --to-earliest \
  --topic test-topic \
  --execute

# Reset to latest
kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --group test-consumer-group \
  --reset-offsets \
  --to-latest \
  --topic test-topic \
  --execute
```

## Clean Up Test Applications

```bash
# Remove all test applications
kubectl delete -f 05-test-applications.yaml

# Or remove specific applications
kubectl delete deployment kafka-producer -n kafka
kubectl delete deployment kafka-consumer -n kafka
kubectl delete pod kafka-client -n kafka
```

## Next Steps

- [Monitor Your Cluster](05-monitoring.md)
- [Advanced Kafka Features](06-advanced-features.md)

