# Strimzi Kafka Visual Guide

## 🎯 Quick Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                    START HERE                                │
│                                                              │
│  New to Kafka?          → Read QUICKSTART.md                │
│  Want detailed guide?   → Read TUTORIAL.md                  │
│  Ready to deploy?       → Run ./scripts/setup-cluster.sh    │
│  Need reference?        → Check docs/ directory             │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Architecture Visualization

### Complete System Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER                              │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │                      KAFKA NAMESPACE                           │   │
│  │                                                                │   │
│  │  ┌──────────────────────────────────────────────────────┐    │   │
│  │  │           STRIMZI CLUSTER OPERATOR                    │    │   │
│  │  │  • Watches Kafka custom resources                     │    │   │
│  │  │  • Manages Kafka & ZooKeeper deployments             │    │   │
│  │  │  • Handles rolling updates                           │    │   │
│  │  └──────────────────────────────────────────────────────┘    │   │
│  │                            ↓                                  │   │
│  │  ┌────────────────────────────────────────────────────────┐  │   │
│  │  │              KAFKA CLUSTER                             │  │   │
│  │  │                                                        │  │   │
│  │  │  ┌──────────┐      ┌──────────┐      ┌──────────┐   │  │   │
│  │  │  │  Kafka   │      │  Kafka   │      │  Kafka   │   │  │   │
│  │  │  │ Broker 0 │◄────►│ Broker 1 │◄────►│ Broker 2 │   │  │   │
│  │  │  │          │      │          │      │          │   │  │   │
│  │  │  │ Port:9092│      │ Port:9092│      │ Port:9092│   │  │   │
│  │  │  │ PVC:10Gi │      │ PVC:10Gi │      │ PVC:10Gi │   │  │   │
│  │  │  └────┬─────┘      └────┬─────┘      └────┬─────┘   │  │   │
│  │  │       │                 │                 │          │  │   │
│  │  │       └─────────────────┼─────────────────┘          │  │   │
│  │  │                         ↓                            │  │   │
│  │  │  ┌──────────┐      ┌──────────┐      ┌──────────┐   │  │   │
│  │  │  │ZooKeeper │      │ZooKeeper │      │ZooKeeper │   │  │   │
│  │  │  │  Node 0  │◄────►│  Node 1  │◄────►│  Node 2  │   │  │   │
│  │  │  │          │      │          │      │          │   │  │   │
│  │  │  │ Port:2181│      │ Port:2181│      │ Port:2181│   │  │   │
│  │  │  │ PVC: 5Gi │      │ PVC: 5Gi │      │ PVC: 5Gi │   │  │   │
│  │  │  └──────────┘      └──────────┘      └──────────┘   │  │   │
│  │  │                                                        │  │   │
│  │  │  ┌──────────────────────────────────────────────┐    │  │   │
│  │  │  │         ENTITY OPERATOR                      │    │  │   │
│  │  │  │  ┌────────────────┐  ┌──────────────────┐   │    │  │   │
│  │  │  │  │ Topic Operator │  │  User Operator   │   │    │  │   │
│  │  │  │  │ (Manages       │  │  (Manages        │   │    │  │   │
│  │  │  │  │  KafkaTopics)  │  │   KafkaUsers)    │   │    │  │   │
│  │  │  │  └────────────────┘  └──────────────────┘   │    │  │   │
│  │  │  └──────────────────────────────────────────────┘    │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │           TEST APPLICATIONS                        │  │   │
│  │  │                                                    │  │   │
│  │  │  ┌──────────────┐    ┌──────────────┐           │  │   │
│  │  │  │   Producer   │───►│   Consumer   │           │  │   │
│  │  │  │  (Bash/Py)   │    │  (Bash/Py)   │           │  │   │
│  │  │  └──────────────┘    └──────────────┘           │  │   │
│  │  │                                                    │  │   │
│  │  │  ┌──────────────────────────────────┐            │  │   │
│  │  │  │      Kafka Client Pod            │            │  │   │
│  │  │  │  (Interactive testing)           │            │  │   │
│  │  │  └──────────────────────────────────┘            │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │           MONITORING STACK                         │  │   │
│  │  │                                                    │  │   │
│  │  │  ┌──────────────┐         ┌──────────────┐       │  │   │
│  │  │  │  Prometheus  │────────►│   Grafana    │       │  │   │
│  │  │  │              │         │              │       │  │   │
│  │  │  │ Port: 9090   │         │ Port: 3000   │       │  │   │
│  │  │  │ (Metrics)    │         │ (Dashboard)  │       │  │   │
│  │  │  └──────┬───────┘         └──────────────┘       │  │   │
│  │  │         │                                         │  │   │
│  │  │         └─────► Scrapes metrics from Kafka       │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

### Producer → Kafka → Consumer

```
┌──────────────┐
│  Producer    │
│ Application  │
└──────┬───────┘
       │ 1. Send message
       ↓
┌──────────────────────────────────────────┐
│         Kafka Broker                     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Topic: orders                     │ │
│  │                                    │ │
│  │  ┌──────────┐  ┌──────────┐      │ │
│  │  │Partition0│  │Partition1│  ... │ │
│  │  │          │  │          │      │ │
│  │  │ Msg 1    │  │ Msg 2    │      │ │
│  │  │ Msg 3    │  │ Msg 4    │      │ │
│  │  │ Msg 5    │  │ Msg 6    │      │ │
│  │  └──────────┘  └──────────┘      │ │
│  └────────────────────────────────────┘ │
└──────────────┬───────────────────────────┘
               │ 2. Fetch messages
               ↓
┌──────────────────────────────┐
│  Consumer Group              │
│                              │
│  ┌──────────┐  ┌──────────┐ │
│  │Consumer 1│  │Consumer 2│ │
│  │(Part 0)  │  │(Part 1)  │ │
│  └──────────┘  └──────────┘ │
└──────────────────────────────┘
```

## 📁 File Organization Map

```
Strimzi/
│
├── 🚀 QUICK START FILES
│   ├── README.md              ← Start here for overview
│   ├── QUICKSTART.md          ← 5-minute setup guide
│   └── PROJECT-SUMMARY.md     ← What's included
│
├── 📖 LEARNING RESOURCES
│   ├── TUTORIAL.md            ← Complete tutorial
│   └── VISUAL-GUIDE.md        ← This file
│
├── ⚙️  KUBERNETES YAML FILES (Deploy in order)
│   ├── 01-strimzi-operator.yaml    ← Step 1: Operator
│   ├── 02-kafka-cluster.yaml       ← Step 2: Kafka cluster
│   ├── 03-kafka-topics.yaml        ← Step 3: Topics
│   ├── 04-kafka-users.yaml         ← Step 4: Users
│   ├── 05-test-applications.yaml   ← Step 5: Test apps
│   └── 06-monitoring.yaml          ← Step 6: Monitoring
│
├── 📚 DETAILED DOCUMENTATION
│   └── docs/
│       ├── 01-getting-started.md    ← Setup guide
│       ├── 02-topics.md             ← Topic management
│       ├── 03-users-security.md     ← Security
│       ├── 04-test-applications.md  ← Testing
│       ├── 05-monitoring.md         ← Monitoring
│       └── 06-advanced-features.md  ← Advanced topics
│
└── 🛠️  AUTOMATION SCRIPTS
    └── scripts/
        ├── setup-cluster.sh    ← Automated setup
        ├── test-kafka.sh       ← Run tests
        ├── monitor.sh          ← Monitor cluster
        └── cleanup.sh          ← Clean up
```

## 🎯 Learning Path Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                    LEARNING JOURNEY                          │
└─────────────────────────────────────────────────────────────┘

Level 1: BEGINNER (Day 1)
┌──────────────────────────────────────────────────┐
│ 1. Read QUICKSTART.md                            │
│ 2. Run: ./scripts/setup-cluster.sh               │
│ 3. Test basic produce/consume                    │
│ 4. Explore with kafka-client pod                 │
└──────────────────────────────────────────────────┘
                      ↓
Level 2: INTERMEDIATE (Days 2-3)
┌──────────────────────────────────────────────────┐
│ 1. Read docs/02-topics.md                        │
│ 2. Create custom topics                          │
│ 3. Read docs/03-users-security.md                │
│ 4. Test authentication                           │
│ 5. Deploy test applications                      │
└──────────────────────────────────────────────────┘
                      ↓
Level 3: ADVANCED (Week 1+)
┌──────────────────────────────────────────────────┐
│ 1. Read docs/05-monitoring.md                    │
│ 2. Set up Grafana dashboards                     │
│ 3. Read docs/06-advanced-features.md             │
│ 4. Implement transactions                        │
│ 5. Build your own applications                   │
└──────────────────────────────────────────────────┘
                      ↓
Level 4: EXPERT
┌──────────────────────────────────────────────────┐
│ 1. Performance tuning                            │
│ 2. Disaster recovery                             │
│ 3. Multi-cluster setup                           │
│ 4. Production deployment                         │
└──────────────────────────────────────────────────┘
```

## 🔧 Operations Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   DAILY OPERATIONS                           │
└─────────────────────────────────────────────────────────────┘

MONITORING
┌──────────────────────────────────────┐
│ ./scripts/monitor.sh --watch         │ ← Continuous monitoring
│                                      │
│ Check:                               │
│ • Pod health                         │
│ • Consumer lag                       │
│ • Under-replicated partitions        │
│ • Resource usage                     │
└──────────────────────────────────────┘

TESTING
┌──────────────────────────────────────┐
│ ./scripts/test-kafka.sh              │ ← Run tests
│                                      │
│ Tests:                               │
│ • Cluster connectivity               │
│ • Produce/consume                    │
│ • Replication                        │
│ • Performance                        │
└──────────────────────────────────────┘

TROUBLESHOOTING
┌──────────────────────────────────────┐
│ kubectl logs <pod> -n kafka          │ ← Check logs
│ kubectl describe pod <pod> -n kafka  │ ← Check events
│ ./scripts/monitor.sh --full          │ ← Full report
└──────────────────────────────────────┘
```

## 📊 Topic Configuration Matrix

```
┌────────────────────────────────────────────────────────────────┐
│                    TOPIC TYPES                                  │
├─────────────────┬──────────┬──────────┬────────────┬──────────┤
│ Topic Type      │Partitions│Retention │Compression │Use Case  │
├─────────────────┼──────────┼──────────┼────────────┼──────────┤
│ test-topic      │    3     │  7 days  │  producer  │ Testing  │
├─────────────────┼──────────┼──────────┼────────────┼──────────┤
│ high-throughput │   10     │  1 day   │    lz4     │ IoT data │
├─────────────────┼──────────┼──────────┼────────────┼──────────┤
│ compacted       │    3     │ compact  │  producer  │ State    │
├─────────────────┼──────────┼──────────┼────────────┼──────────┤
│ user-events     │    5     │ 30 days  │   snappy   │ Events   │
├─────────────────┼──────────┼──────────┼────────────┼──────────┤
│ app-logs        │    6     │  7 days  │    gzip    │ Logs     │
└─────────────────┴──────────┴──────────┴────────────┴──────────┘
```

## 🔐 User Permissions Matrix

```
┌────────────────────────────────────────────────────────────────┐
│                    USER PERMISSIONS                             │
├──────────────┬────────┬────────┬────────┬────────┬────────────┤
│ User         │ Read   │ Write  │ Create │ Delete │ Admin      │
├──────────────┼────────┼────────┼────────┼────────┼────────────┤
│ producer     │   ✗    │   ✓    │   ✓    │   ✗    │     ✗      │
├──────────────┼────────┼────────┼────────┼────────┼────────────┤
│ consumer     │   ✓    │   ✗    │   ✗    │   ✗    │     ✗      │
├──────────────┼────────┼────────┼────────┼────────┼────────────┤
│ admin        │   ✓    │   ✓    │   ✓    │   ✓    │     ✓      │
├──────────────┼────────┼────────┼────────┼────────┼────────────┤
│ app-user     │   ✓*   │   ✓*   │   ✗    │   ✗    │     ✗      │
│              │(limited)│(limited)│        │        │            │
└──────────────┴────────┴────────┴────────┴────────┴────────────┘
* Limited to specific topics
```

## 🎬 Command Cheat Sheet

### Quick Commands

```bash
# SETUP
./scripts/setup-cluster.sh              # Full setup

# TESTING
./scripts/test-kafka.sh                 # Run all tests

# MONITORING
./scripts/monitor.sh                    # Full report
./scripts/monitor.sh --watch            # Continuous
./scripts/monitor.sh --pods             # Pods only

# CLEANUP
./scripts/cleanup.sh                    # Remove all

# MANUAL OPERATIONS
kubectl get pods -n kafka               # List pods
kubectl get kafkatopics -n kafka        # List topics
kubectl get kafkausers -n kafka         # List users

# INTERACTIVE
kubectl exec -it kafka-client -n kafka -- /bin/bash

# LOGS
kubectl logs my-cluster-kafka-0 -n kafka
kubectl logs deployment/strimzi-cluster-operator -n kafka
```

## 📈 Monitoring Dashboard Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    GRAFANA DASHBOARD                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Broker Health│  │Message Rate  │  │  Throughput  │     │
│  │              │  │              │  │              │     │
│  │   ✓ Ready    │  │  1000 msg/s  │  │  10 MB/s     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Message Rate Over Time                    │    │
│  │                                                     │    │
│  │    ┌─────────────────────────────────────────┐    │    │
│  │    │         📈 Line Graph                    │    │    │
│  │    └─────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐       │
│  │   Consumer Lag       │  │  Under-Replicated    │       │
│  │                      │  │    Partitions        │       │
│  │   📊 Bar Chart       │  │   ✓ None             │       │
│  └──────────────────────┘  └──────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Deployment Timeline

```
Time    Action                          Status
─────────────────────────────────────────────────────────────
0:00    Start deployment                🟡 Starting
0:30    Operator deployed               🟢 Ready
1:00    ZooKeeper starting              🟡 Starting
3:00    ZooKeeper ready                 🟢 Ready
3:30    Kafka brokers starting          🟡 Starting
6:00    Kafka cluster ready             🟢 Ready
6:30    Topics created                  🟢 Ready
7:00    Users created                   🟢 Ready
7:30    Test apps deployed              🟢 Ready
8:00    Monitoring deployed             🟢 Ready
─────────────────────────────────────────────────────────────
Total: ~8 minutes
```

## 💡 Tips and Tricks

```
┌─────────────────────────────────────────────────────────────┐
│                    PRO TIPS                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Always check pod status before operations               │
│  ✅ Use consumer groups for parallel processing             │
│  ✅ Monitor consumer lag regularly                          │
│  ✅ Set appropriate retention based on use case             │
│  ✅ Use compression for bandwidth optimization              │
│  ✅ Test disaster recovery procedures                       │
│  ✅ Keep Strimzi operator updated                           │
│  ✅ Use meaningful topic and consumer group names           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Success Indicators

```
Your cluster is healthy when:

✅ All pods are Running
✅ Kafka cluster status is Ready
✅ No under-replicated partitions
✅ Consumer lag is low
✅ Prometheus is collecting metrics
✅ Grafana dashboards show data
✅ Test applications are working
✅ All tests pass
```

## 📞 Getting Help

```
┌─────────────────────────────────────────────────────────────┐
│                    HELP RESOURCES                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Issue?                  → Check troubleshooting section     │
│  Need logs?              → kubectl logs <pod> -n kafka       │
│  Want health check?      → ./scripts/monitor.sh             │
│  Documentation?          → See docs/ directory               │
│  Strimzi docs?           → https://strimzi.io/docs/         │
│  Kafka docs?             → https://kafka.apache.org/docs/    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

**🎉 You're all set! Start with QUICKSTART.md and enjoy learning Kafka!**

