#!/bin/bash

count_0=0
count_1=0
count_2=0
count_3=0

echo "--- Starting Performance Sync: $(date) ---"
echo "    Tags: $CORE_TAG | $HIGH_TAG | $NORMAL_TAG | $LOW_TAG"

echo "=== Applying $CORE_TAG (Weight: $CORE_WEIGHT, Pri: $CORE_IO_PRI) ==="
for uuid in $(xe vm-list tags:contains="$CORE_TAG" --minimal | tr ',' '\n'); do
    [ -z "$uuid" ] && continue
    xe vm-param-set uuid=$uuid VCPUs-params:weight=$CORE_WEIGHT other-config:sched-pri=$CORE_IO_PRI
    echo "  [OK] CORE applied: $uuid"
    ((count_0++))
done

echo "=== Applying $HIGH_TAG (Weight: $HIGH_WEIGHT, Pri: $HIGH_IO_PRI) ==="
for uuid in $(xe vm-list tags:contains="$HIGH_TAG" --minimal | tr ',' '\n'); do
    [ -z "$uuid" ] && continue
    xe vm-param-set uuid=$uuid VCPUs-params:weight=$HIGH_WEIGHT other-config:sched-pri=$HIGH_IO_PRI
    echo "  [OK] HIGH applied: $uuid"
    ((count_1++))
done

echo "=== Applying $NORMAL_TAG (Weight: $NORMAL_WEIGHT, Pri: $NORMAL_IO_PRI) ==="
for uuid in $(xe vm-list tags:contains="$NORMAL_TAG" --minimal | tr ',' '\n'); do
    [ -z "$uuid" ] && continue
    xe vm-param-set uuid=$uuid VCPUs-params:weight=$NORMAL_WEIGHT other-config:sched-pri=$NORMAL_IO_PRI
    echo "  [OK] NORMAL applied: $uuid"
    ((count_2++))
done

echo "=== Applying $LOW_TAG (Weight: $LOW_WEIGHT, Pri: $LOW_IO_PRI) ==="
for uuid in $(xe vm-list tags:contains="$LOW_TAG" --minimal | tr ',' '\n'); do
    [ -z "$uuid" ] && continue
    xe vm-param-set uuid=$uuid VCPUs-params:weight=$LOW_WEIGHT other-config:sched-pri=$LOW_IO_PRI
    echo "  [OK] LOW applied: $uuid"
    ((count_3++))
done

echo "--- Performance Sync Complete: $(date) ---"
echo "$(date '+%Y-%m-%d %H:%M:%S') $(hostname) $CORE_TAG:$count_0 $HIGH_TAG:$count_1 $NORMAL_TAG:$count_2 $LOW_TAG:$count_3" >> "$SUMMARY_LOG"
