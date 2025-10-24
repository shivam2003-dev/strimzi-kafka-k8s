# 📚 Complete Index - Strimzi Kafka Tutorial

## 🎯 Start Here

| File | Purpose | Time Required |
|------|---------|---------------|
| [README.md](README.md) | Project overview and introduction | 5 min |
| [QUICKSTART.md](QUICKSTART.md) | Get started in 5 minutes | 5 min |
| [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) | What's included in this project | 10 min |
| [VISUAL-GUIDE.md](VISUAL-GUIDE.md) | Visual diagrams and navigation | 10 min |

## 📖 Complete Tutorial

| File | Description | Level |
|------|-------------|-------|
| [TUTORIAL.md](TUTORIAL.md) | Complete end-to-end tutorial with examples | All Levels |

## ⚙️ Kubernetes YAML Files

Deploy these files in order:

| # | File | Description | What It Creates |
|---|------|-------------|-----------------|
| 1 | [01-strimzi-operator.yaml](01-strimzi-operator.yaml) | Strimzi operator installation | Operator pod, CRDs, RBAC |
| 2 | [02-kafka-cluster.yaml](02-kafka-cluster.yaml) | Kafka cluster configuration | 3 Kafka brokers, 3 ZooKeeper nodes |
| 3 | [03-kafka-topics.yaml](03-kafka-topics.yaml) | Sample topics | 5 topics with different configs |
| 4 | [04-kafka-users.yaml](04-kafka-users.yaml) | Users with authentication | 4 users with different permissions |
| 5 | [05-test-applications.yaml](05-test-applications.yaml) | Test applications | Producers, consumers, client pod |
| 6 | [06-monitoring.yaml](06-monitoring.yaml) | Monitoring stack | Prometheus, Grafana |

## 📚 Detailed Documentation

| File | Topic | Key Concepts |
|------|-------|--------------|
| [docs/01-getting-started.md](docs/01-getting-started.md) | Setup and installation | Prerequisites, installation steps, verification |
| [docs/02-topics.md](docs/02-topics.md) | Topic management | Creating topics, configurations, best practices |
| [docs/03-users-security.md](docs/03-users-security.md) | Security and authentication | SCRAM-SHA-512, ACLs, TLS |
| [docs/04-test-applications.md](docs/04-test-applications.md) | Testing applications | Producers, consumers, testing scenarios |
| [docs/05-monitoring.md](docs/05-monitoring.md) | Monitoring and metrics | Prometheus, Grafana, metrics |
| [docs/06-advanced-features.md](docs/06-advanced-features.md) | Advanced features | Transactions, compaction, Connect |

## 🛠️ Automation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [scripts/setup-cluster.sh](scripts/setup-cluster.sh) | Automated cluster setup | `./scripts/setup-cluster.sh` |
| [scripts/test-kafka.sh](scripts/test-kafka.sh) | Run comprehensive tests | `./scripts/test-kafka.sh` |
| [scripts/monitor.sh](scripts/monitor.sh) | Monitor cluster health | `./scripts/monitor.sh [--watch\|--full]` |
| [scripts/cleanup.sh](scripts/cleanup.sh) | Clean up all resources | `./scripts/cleanup.sh` |

## 📊 What Gets Deployed

### Kafka Cluster Components

```
✓ 3 Kafka Broker Pods
✓ 3 ZooKeeper Pods
✓ 1 Entity Operator Pod (Topic + User operators)
✓ 1 Kafka Exporter Pod
✓ Persistent Volumes (10Gi per broker, 5Gi per ZK)
```

### Topics Created

| Topic Name | Partitions | Replicas | Use Case |
|------------|------------|----------|----------|
| test-topic | 3 | 3 | General testing |
| high-throughput-topic | 10 | 3 | High volume data |
| compacted-topic | 3 | 3 | State management |
| user-events | 5 | 3 | Event streaming |
| application-logs | 6 | 3 | Log aggregation |

### Users Created

| User | Authentication | Permissions | Use Case |
|------|----------------|-------------|----------|
| producer-user | SCRAM-SHA-512 | Write only | Data producers |
| consumer-user | SCRAM-SHA-512 | Read only | Data consumers |
| admin-user | SCRAM-SHA-512 | Full access | Administration |
| app-user | SCRAM-SHA-512 | Limited | Specific app access |

### Test Applications

```
✓ Kafka Console Producer (Bash)
✓ Kafka Console Consumer (Bash)
✓ Python Producer (Job)
✓ Python Consumer (Deployment)
✓ Kafka Client Pod (Interactive)
```

### Monitoring Stack

```
✓ Prometheus (Port 9090)
✓ Grafana (Port 3000, admin/admin)
✓ JMX Exporters
✓ Pre-configured datasources
```

## 🎓 Learning Paths

### Path 1: Quick Start (1 hour)
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Run `./scripts/setup-cluster.sh`
3. Test with console producer/consumer
4. View monitoring in Grafana

### Path 2: Comprehensive (1 day)
1. Read [TUTORIAL.md](TUTORIAL.md)
2. Follow [docs/01-getting-started.md](docs/01-getting-started.md)
3. Work through [docs/02-topics.md](docs/02-topics.md)
4. Explore [docs/03-users-security.md](docs/03-users-security.md)
5. Deploy apps from [docs/04-test-applications.md](docs/04-test-applications.md)

### Path 3: Deep Dive (1 week)
1. Complete Path 2
2. Study [docs/05-monitoring.md](docs/05-monitoring.md)
3. Master [docs/06-advanced-features.md](docs/06-advanced-features.md)
4. Build custom applications
5. Implement production patterns

## 🔍 Quick Reference

### Common Commands

```bash
# Setup
./scripts/setup-cluster.sh

# Test
./scripts/test-kafka.sh

# Monitor
./scripts/monitor.sh --watch

# Access client
kubectl exec -it kafka-client -n kafka -- /bin/bash

# List topics
kubectl get kafkatopics -n kafka

# Check pods
kubectl get pods -n kafka

# View logs
kubectl logs my-cluster-kafka-0 -n kafka

# Port forward Grafana
kubectl port-forward svc/grafana 3000:3000 -n kafka

# Cleanup
./scripts/cleanup.sh
```

### Key Concepts by File

#### Kafka Basics
- **Architecture**: [TUTORIAL.md](TUTORIAL.md#architecture-overview)
- **Topics**: [docs/02-topics.md](docs/02-topics.md)
- **Producers**: [TUTORIAL.md](TUTORIAL.md#producing-messages)
- **Consumers**: [TUTORIAL.md](TUTORIAL.md#consuming-messages)

#### Operations
- **Installation**: [docs/01-getting-started.md](docs/01-getting-started.md)
- **Monitoring**: [docs/05-monitoring.md](docs/05-monitoring.md)
- **Security**: [docs/03-users-security.md](docs/03-users-security.md)
- **Testing**: [docs/04-test-applications.md](docs/04-test-applications.md)

#### Advanced Topics
- **Transactions**: [docs/06-advanced-features.md](docs/06-advanced-features.md#transactions)
- **Compaction**: [docs/06-advanced-features.md](docs/06-advanced-features.md#log-compaction)
- **Connect**: [docs/06-advanced-features.md](docs/06-advanced-features.md#kafka-connect)
- **Streams**: [docs/06-advanced-features.md](docs/06-advanced-features.md#kafka-streams)

## 🎯 Use Case Index

### E-commerce
- Order processing: [TUTORIAL.md](TUTORIAL.md#example-1-e-commerce-order-processing)
- Payment processing: [TUTORIAL.md](TUTORIAL.md#example-1-e-commerce-order-processing)
- Inventory management: [docs/06-advanced-features.md](docs/06-advanced-features.md#log-compaction)

### Analytics
- Real-time analytics: [TUTORIAL.md](TUTORIAL.md#example-2-real-time-analytics)
- Event streaming: [docs/02-topics.md](docs/02-topics.md#events-topic-user-events)
- Metrics aggregation: [docs/05-monitoring.md](docs/05-monitoring.md)

### Logging
- Log aggregation: [TUTORIAL.md](TUTORIAL.md#example-3-log-aggregation)
- Centralized logging: [docs/02-topics.md](docs/02-topics.md#logs-topic-application-logs)

### Microservices
- Event-driven architecture: [docs/02-topics.md](docs/02-topics.md#events-topic-user-events)
- Service communication: [TUTORIAL.md](TUTORIAL.md#real-world-examples)

## 🔧 Troubleshooting Index

| Issue | Solution Location |
|-------|------------------|
| Pods not starting | [TUTORIAL.md](TUTORIAL.md#issue-pods-not-starting) |
| Can't produce/consume | [TUTORIAL.md](TUTORIAL.md#issue-cant-produceconsume-messages) |
| High consumer lag | [TUTORIAL.md](TUTORIAL.md#issue-high-consumer-lag) |
| Under-replicated partitions | [TUTORIAL.md](TUTORIAL.md#issue-under-replicated-partitions) |
| Authentication failures | [docs/03-users-security.md](docs/03-users-security.md#troubleshooting) |
| Topic issues | [docs/02-topics.md](docs/02-topics.md) |

## 📈 Metrics and Monitoring

| Metric Type | Documentation |
|-------------|---------------|
| Broker metrics | [docs/05-monitoring.md](docs/05-monitoring.md#kafka-broker-metrics) |
| Topic metrics | [docs/05-monitoring.md](docs/05-monitoring.md#topic-metrics) |
| Consumer metrics | [docs/05-monitoring.md](docs/05-monitoring.md#consumer-group-metrics) |
| ZooKeeper metrics | [docs/05-monitoring.md](docs/05-monitoring.md#zookeeper-metrics) |

## 🎨 Visual Guides

| Visual | Location |
|--------|----------|
| Architecture diagram | [VISUAL-GUIDE.md](VISUAL-GUIDE.md#complete-system-overview) |
| Data flow | [VISUAL-GUIDE.md](VISUAL-GUIDE.md#producer--kafka--consumer) |
| File organization | [VISUAL-GUIDE.md](VISUAL-GUIDE.md#file-organization-map) |
| Learning path | [VISUAL-GUIDE.md](VISUAL-GUIDE.md#learning-path-visualization) |

## 📝 Code Examples

### Python Examples
- Producer: [TUTORIAL.md](TUTORIAL.md#example-1-e-commerce-order-processing)
- Consumer: [TUTORIAL.md](TUTORIAL.md#example-2-real-time-analytics)
- Transactions: [TUTORIAL.md](TUTORIAL.md#transactions)
- Authentication: [docs/03-users-security.md](docs/03-users-security.md#using-scram-sha-512)

### Bash Examples
- Console producer: [TUTORIAL.md](TUTORIAL.md#simple-text-messages)
- Console consumer: [TUTORIAL.md](TUTORIAL.md#from-beginning)
- Admin operations: [docs/02-topics.md](docs/02-topics.md)

## 🎯 Quick Navigation

| I want to... | Go to... |
|--------------|----------|
| Get started quickly | [QUICKSTART.md](QUICKSTART.md) |
| Learn everything | [TUTORIAL.md](TUTORIAL.md) |
| Set up monitoring | [docs/05-monitoring.md](docs/05-monitoring.md) |
| Secure my cluster | [docs/03-users-security.md](docs/03-users-security.md) |
| Build applications | [docs/04-test-applications.md](docs/04-test-applications.md) |
| Troubleshoot issues | [TUTORIAL.md](TUTORIAL.md#troubleshooting) |
| See architecture | [VISUAL-GUIDE.md](VISUAL-GUIDE.md) |
| Run tests | `./scripts/test-kafka.sh` |

## 📦 File Sizes

| File | Size | Type |
|------|------|------|
| 01-strimzi-operator.yaml | 11KB | YAML |
| 02-kafka-cluster.yaml | 4.5KB | YAML |
| 03-kafka-topics.yaml | 2.5KB | YAML |
| 04-kafka-users.yaml | 3.5KB | YAML |
| 05-test-applications.yaml | 7KB | YAML |
| 06-monitoring.yaml | 6KB | YAML |
| TUTORIAL.md | 30KB | Markdown |
| All docs/ | 52KB | Markdown |
| All scripts/ | 21KB | Shell |

## 🎉 Summary

This project contains:
- ✅ **6 YAML files** for complete Kafka deployment
- ✅ **6 documentation files** covering all aspects
- ✅ **4 automation scripts** for common operations
- ✅ **5 guide files** for learning and reference
- ✅ **100+ code examples** in Python and Bash
- ✅ **Comprehensive testing** with automated test suite
- ✅ **Production-ready** configuration
- ✅ **Complete monitoring** setup

**Total: 22 files, ~130KB of documentation and code**

---

## 🚀 Next Steps

1. **New to Kafka?** → Start with [QUICKSTART.md](QUICKSTART.md)
2. **Want to learn?** → Read [TUTORIAL.md](TUTORIAL.md)
3. **Ready to deploy?** → Run `./scripts/setup-cluster.sh`
4. **Need reference?** → Check this INDEX.md

**Happy Kafka-ing! 🎉**

