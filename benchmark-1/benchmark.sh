#!/bin/bash

# --- CẤU HÌNH ---
NAMESPACE="testapi"
COUNTS=(1 2 4)
TIMEOUT=1200

# Kiểm tra tham số
MODE=$1
if [[ "$MODE" != "heavy" && "$MODE" != "opt" ]]; then
    echo "❌ Lỗi: Chọn chế độ ./benchmark.sh heavy HOẶC ./benchmark.sh opt"
    exit 1
fi

echo "======================================================="
echo "🚀 BENCHMARK: ${MODE^^}"
echo "======================================================="

declare -A RESULTS

cleanup() {
    echo "   [Cleanup] Xoá tài nguyên cũ..."
    kubectl delete vm --all -n $NAMESPACE --wait=false > /dev/null 2>&1
    kubectl delete dv --all -n $NAMESPACE --wait=false > /dev/null 2>&1
    kubectl delete pvc --all -n $NAMESPACE --wait=false > /dev/null 2>&1
    echo "   [Cleanup] Đợi 10s..."
    sleep 10
}

run_test() {
    COUNT=$1
    echo "------------------------------------------------"
    echo "▶️  CASE: $COUNT VM ($MODE)"

    cleanup
    START_TIME=$(date +%s)

    for ((i=1; i<=COUNT; i++)); do
        NAME="vm-${MODE}-${COUNT}-${i}"
        PVC_NAME="pvc-${MODE}-${COUNT}-${i}" # Chỉ dùng cho Opt

        if [ "$MODE" == "heavy" ]; then
            # === HEAVY: Dùng 2 file rời vừa tạo ===
            # 1. Tạo DataVolume (Download Image)
            cat heavy-dv.yaml | sed "s/\${NAME}/$NAME/g" | kubectl apply -f -

            # 2. Tạo VM
            cat heavy-vm.yaml | sed "s/\${NAME}/$NAME/g" | kubectl apply -f -
        else
            # === OPT: Dùng file cũ (pvc-opt.yaml và vm-template.yaml) ===
            cat pvc-opt.yaml | sed "s/\${PVC_NAME}/$PVC_NAME/g" | kubectl apply -f - > /dev/null 2>&1
            cat vm-template.yaml | sed "s/\${VM_NAME}/$NAME/g" | sed "s/\${PVC_NAME}/$PVC_NAME/g" | kubectl apply -f - > /dev/null 2>&1
        fi
    done

    echo "   [Wait] Đã request $COUNT VM. Đang chờ Running..."

    while true; do
        # Đếm số VM Running
        RUNNING=$(kubectl get vms -n $NAMESPACE --no-headers 2>/dev/null | grep "Running" | wc -l)

        # In tiến độ trên cùng 1 dòng
        echo -ne "   ... Status: $RUNNING / $COUNT Running\r"

        if [ "$RUNNING" -ge "$COUNT" ]; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            echo ""
            echo "   ✅ DONE! Time: ${DURATION}s"
            RESULTS[$COUNT]=$DURATION
            break
        fi

        if [ $(( $(date +%s) - START_TIME )) -gt $TIMEOUT ]; then
            echo ""
            echo "   ❌ TIMEOUT!"
            RESULTS[$COUNT]="Timeout"
            break
        fi
        sleep 5
    done
}

for N in "${COUNTS[@]}"; do
    run_test $N
done

echo ""
echo "📊 KẾT QUẢ (${MODE^^})"
printf "%-10s | %-10s\n" "SL VM" "Giây"
echo "-----------|----------"
for N in "${COUNTS[@]}"; do
    printf "%-10s | %-10s\n" "$N VM" "${RESULTS[$N]}"
done