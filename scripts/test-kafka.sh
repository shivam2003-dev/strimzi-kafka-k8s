#!/bin/bash

# Kafka Functionality Test Script
# Tests various Kafka operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check cluster is running
test_cluster_running() {
    print_test "Test 1: Checking if Kafka cluster is running..."
    
    if kubectl get kafka my-cluster -n kafka &> /dev/null; then
        STATUS=$(kubectl get kafka my-cluster -n kafka -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$STATUS" == "True" ]; then
            print_pass "Kafka cluster is running"
            ((TESTS_PASSED++))
            return 0
        fi
    fi
    
    print_fail "Kafka cluster is not running"
    ((TESTS_FAILED++))
    return 1
}

# Test 2: Check all pods are ready
test_pods_ready() {
    print_test "Test 2: Checking if all pods are ready..."
    
    NOT_READY=$(kubectl get pods -n kafka --no-headers | grep -v "Running\|Completed" | wc -l)
    
    if [ "$NOT_READY" -eq 0 ]; then
        print_pass "All pods are ready"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "$NOT_READY pods are not ready"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 3: List topics
test_list_topics() {
    print_test "Test 3: Listing Kafka topics..."
    
    if kubectl exec -it kafka-client -n kafka -- bin/kafka-topics.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --list &> /dev/null; then
        print_pass "Successfully listed topics"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Failed to list topics"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 4: Produce and consume messages
test_produce_consume() {
    print_test "Test 4: Testing produce and consume..."
    
    TEST_MESSAGE="Test message $(date +%s)"
    
    # Produce message
    echo "$TEST_MESSAGE" | kubectl exec -i kafka-client -n kafka -- bin/kafka-console-producer.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --topic test-topic &> /dev/null
    
    sleep 2
    
    # Consume message
    CONSUMED=$(kubectl exec -i kafka-client -n kafka -- timeout 5 bin/kafka-console-consumer.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --topic test-topic \
        --from-beginning \
        --max-messages 1 2>/dev/null | tail -1)
    
    if [[ "$CONSUMED" == *"$TEST_MESSAGE"* ]]; then
        print_pass "Successfully produced and consumed message"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Failed to produce/consume message"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 5: Check topic replication
test_topic_replication() {
    print_test "Test 5: Checking topic replication..."
    
    REPLICATION=$(kubectl exec -i kafka-client -n kafka -- bin/kafka-topics.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --describe \
        --topic test-topic 2>/dev/null | grep "ReplicationFactor" | awk '{print $4}')
    
    if [ "$REPLICATION" == "3" ]; then
        print_pass "Topic has correct replication factor (3)"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Topic replication factor is $REPLICATION (expected 3)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 6: Check consumer groups
test_consumer_groups() {
    print_test "Test 6: Checking consumer groups..."
    
    if kubectl exec -i kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --list &> /dev/null; then
        print_pass "Successfully listed consumer groups"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Failed to list consumer groups"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 7: Check broker connectivity
test_broker_connectivity() {
    print_test "Test 7: Testing broker connectivity..."
    
    if kubectl exec -i kafka-client -n kafka -- bin/kafka-broker-api-versions.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 &> /dev/null; then
        print_pass "Successfully connected to brokers"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Failed to connect to brokers"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 8: Check ZooKeeper
test_zookeeper() {
    print_test "Test 8: Checking ZooKeeper..."
    
    ZK_PODS=$(kubectl get pods -n kafka -l strimzi.io/name=my-cluster-zookeeper --no-headers | wc -l)
    
    if [ "$ZK_PODS" -eq 3 ]; then
        print_pass "ZooKeeper ensemble is running (3 nodes)"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "ZooKeeper ensemble has $ZK_PODS nodes (expected 3)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 9: Check under-replicated partitions
test_under_replicated() {
    print_test "Test 9: Checking for under-replicated partitions..."
    
    UNDER_REP=$(kubectl exec -i kafka-client -n kafka -- bin/kafka-topics.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --describe \
        --under-replicated-partitions 2>/dev/null | grep -c "Topic:" || echo "0")
    
    if [ "$UNDER_REP" -eq 0 ]; then
        print_pass "No under-replicated partitions"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Found $UNDER_REP under-replicated partitions"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 10: Performance test
test_performance() {
    print_test "Test 10: Running performance test..."
    
    if kubectl exec -i kafka-client -n kafka -- bin/kafka-producer-perf-test.sh \
        --topic test-topic \
        --num-records 1000 \
        --record-size 100 \
        --throughput -1 \
        --producer-props bootstrap.servers=my-cluster-kafka-bootstrap:9092 &> /dev/null; then
        print_pass "Performance test completed"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "Performance test failed"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "========================================="
    echo "  Test Summary"
    echo "========================================="
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo "========================================="
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "  Kafka Functionality Tests"
    echo "========================================="
    echo ""
    
    test_cluster_running
    test_pods_ready
    test_list_topics
    test_produce_consume
    test_topic_replication
    test_consumer_groups
    test_broker_connectivity
    test_zookeeper
    test_under_replicated
    test_performance
    
    display_summary
}

# Run main function
main

