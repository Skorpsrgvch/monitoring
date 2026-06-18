#!/bin/bash
# Скрипт резервного копирования конфигураций и TSDB Prometheus

set -e

BACKUP_DIR="/backup/monitoring"
DATE=$(date +%Y%m%d_%H%M%S)
PROMETHEUS_CONTAINER="prometheus"
GRAFANA_CONTAINER="grafana"
ALERTMANAGER_CONTAINER="alertmanager"

echo "=== Начало резервного копирования: $DATE ==="

# Создание директории для бэкапа
mkdir -p "$BACKUP_DIR/$DATE"

# Бэкап конфигураций Prometheus
echo "[1/5] Копирование конфигурации Prometheus..."
docker cp prometheus:/etc/prometheus/prometheus.yml "$BACKUP_DIR/$DATE/prometheus.yml"
docker cp prometheus:/etc/prometheus/rules "$BACKUP_DIR/$DATE/prometheus_rules" 2>/dev/null || true

# Бэкап конфигурации Alertmanager
echo "[2/5] Копирование конфигурации Alertmanager..."
docker cp alertmanager:/etc/alertmanager/alertmanager.yml "$BACKUP_DIR/$DATE/alertmanager.yml"

# Бэкап дашбордов Grafana
echo "[3/5] Копирование дашбордов Grafana..."
docker exec grafana grafana-cli admin backup "$BACKUP_DIR/$DATE/grafana_backup" 2>/dev/null || \
  docker cp grafana:/var/lib/grafana "$BACKUP_DIR/$DATE/grafana_data"

# Бэкап TSDB Prometheus (сжатие)
echo "[4/5] Создание снимка TSDB Prometheus..."
docker exec prometheus wget --post-query='' -q -O - http://localhost:9090/api/v1/admin/tsdb/snapshot
sleep 2
docker cp prometheus:/prometheus/snapshots "$BACKUP_DIR/$DATE/prometheus_snapshots" 2>/dev/null || true

# Архивация
echo "[5/5] Архивация бэкапа..."
cd "$BACKUP_DIR"
tar -czf "monitoring_backup_$DATE.tar.gz" "$DATE"
rm -rf "$DATE"

# Удаление старых бэкапов (хранить последние 7 дней)
find "$BACKUP_DIR" -name "monitoring_backup_*.tar.gz" -mtime +7 -delete

echo "=== Резервное копирование завершено: $BACKUP_DIR/monitoring_backup_$DATE.tar.gz ==="