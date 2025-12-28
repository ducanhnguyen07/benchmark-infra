#!/bin/bash

# --- CẤU HÌNH CHIẾN THẮNG (ONE-BY-ONE) ---
NAMESPACE="testapi"
TOTAL_VMS=20
BATCH_SIZE=1       # QUAN TRỌNG: Tạo từng con một
BATCH_SLEEP=10     # Nghỉ 10s sau mỗi con để ổ cứng kịp ghi

echo "======================================================="
echo "🏫 BENCHMARK BÀI 2: CAPACITY (20 VMs - ONE BY ONE)"
echo "⚙️  Mục tiêu: Đảm bảo 100% VM Running trên Disk yếu"
echo "======================================================="

# 1. Dọn dẹp chiến trường cũ
echo "🧹 [Cleanup] Đang xoá sạch..."
kubectl delete vm --all -n $NAMESPACE --wait=false > /dev/null 2>&1
kubectl delete pvc --all -n $NAMESPACE --wait=false > /dev/null 2>&1

# Đợi lâu hơn một chút để Longhorn xả sạch các kết nối cũ
echo "⏳ [Cleanup] Đợi 45s cho hệ thống hồi phục..."
sleep 45

START_TIME=$(date +%s)
echo "🚀 Bắt đầu chiến dịch..."

for ((i=1; i<=TOTAL_VMS; i++)); do
    NAME="student-vm-$i"
    PVC_NAME="student-disk-$i"

    # Tạo PVC và VM (Dùng đúng file của bạn)
    cat pvc-opt.yaml | sed "s/\${PVC_NAME}/$PVC_NAME/g" | kubectl apply -f - > /dev/null 2>&1
    cat vm-template.yaml | sed "s/\${VM_NAME}/$NAME/g" | sed "s/\${PVC_NAME}/$PVC_NAME/g" | kubectl apply -f - > /dev/null 2>&1

    # In ra ngay lập tức để thấy tiến độ
    echo "   + Đã tạo $NAME ($i/$TOTAL_VMS)..."

    # Nghỉ để tránh nghẽn I/O
    sleep ${BATCH_SLEEP}
done

echo "⏳ Đã tạo xong 20 con. Đang chờ tất cả chuyển sang Running..."

# Vòng lặp theo dõi (Kiên nhẫn chờ)
while true; do
    RUNNING=$(kubectl get vms -n $NAMESPACE --no-headers 2>/dev/null | grep "Running" | wc -l)

    echo -ne "   ... Status: $RUNNING / $TOTAL_VMS VM Running \r"

    if [ "$RUNNING" -ge "$TOTAL_VMS" ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "✅ THÀNH CÔNG TUYỆT ĐỐI! 20/20 VM ĐÃ SẴN SÀNG."
        echo "⏱️  Tổng thời gian: ${DURATION}s"
        break
    fi

    # Timeout an toàn (40 phút)
    if [ $(( $(date +%s) - START_TIME )) -gt 2400 ]; then
        echo ""
        echo "❌ TIMEOUT! (Nhưng hãy kiểm tra xem lên được bao nhiêu)"
        break
    fi
    sleep 3
done