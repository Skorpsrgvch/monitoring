#!/bin/bash
# Скрипт проверки работоспособности компонентов мониторинга

set -e

echo "=== Проверка состояния системы мониторинга ==="
echo ""

# Проверка контейнеров
echo "[1/6] Проверка статуса контейнеров..."
docker-compose ps

# Проверка Prometheus
echo ""
echo "[2/6] Проверка Prometheus..."
PROMETHEUS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy)
if [ "$PROMETHEUS_STATUS" -eq 200 ]; then
    echo "✓ Prometheus: OK (HTTP $PROMETHEUS_STATUS)"
else
    echo "✗ Prometheus: FAILED (HTTP $PROMETHEUS_STATUS)"
fi

# Проверка Grafana
echo ""
echo "[3/6] Проверка Grafana..."
GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)
if [ "$GRAFANA_STATUS" -eq 200 ]; then
    echo "✓ Grafana: OK (HTTP $GRAFANA_STATUS)"
else
    echo "✗ Grafana: FAILED (HTTP $GRAFANA_STATUS)"
fi

# Проверка Alertmanager
echo ""
echo "[4/6] Проверка Alertmanager..."
ALERTMANAGER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9093/-/healthy)
if [ "$ALERTMANAGER_STATUS" -eq 200 ]; then
    echo "✓ Alertmanager: OK (HTTP $ALERTMANAGER_STATUS)"
else
    echo "✗ Alertmanager: FAILED (HTTP $ALERTMANAGER_STATUS)"
fi

# Проверка экспортеров
echo ""
echo "[5/6] Проверка Node Exporter..."
NODE_EXPORTER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9100/metrics)
if [ "$NODE_EXPORTER_STATUS" -eq 200 ]; then
    echo "✓ Node Exporter: OK (HTTP $NODE_EXPORTER_STATUS)"
else
    echo "✗ Node Exporter: FAILED (HTTP $NODE_EXPORTER_STATUS)"
fi

# Проверка targets в Prometheus
echo ""
echo "[6/6] Проверка targets в Prometheus..."
ACTIVE_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"' | wc -l)
DOWN_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"down"' | wc -l)

echo "Активных targets: $ACTIVE_TARGETS"
echo "Недоступных targets: $DOWN_TARGETS"

if [ "$DOWN_TARGETS" -gt 0 ]; then
    echo "⚠ Внимание: некоторые targets недоступны!"
else
    echo "✓ Все targets активны"
fi

echo ""
echo "=== Проверка завершена ==="