#!/bin/bash

NAMESPACE="testapi"
TOTAL_VMS=20
REPORT_FILE="latency_report.csv"

# Cài đặt gói cần thiết nếu chưa có (netcat để check port ssh)
if ! command -v nc &> /dev/null; then
    echo "⚠️  Cảnh báo: Lệnh 'nc' (netcat) chưa cài. Đang dùng ping đơn thuần."
fi

echo "======================================================="
echo "📊 BENCHMARK LATENCY & STABILITY (20 VMs)"
echo "======================================================="
echo "VM_NAME, IP_ADDRESS, PING_AVG(ms), PING_LOSS(%), SSH_PORT_22, STATUS" > $REPORT_FILE
printf "%-15s | %-15s | %-10s | %-8s | %-10s | %s\n" "VM Name" "IP Address" "Latency" "Loss" "SSH Port" "Result"
echo "---------------------------------------------------------------------------------------"

for ((i=1; i<=TOTAL_VMS; i++)); do
    NAME="student-vm-$i"

    # 1. Lấy IP của VM
    IP=$(kubectl get vmi $NAME -n $NAMESPACE -o jsonpath='{.status.interfaces[0].ipAddress}' 2>/dev/null)

    if [ -z "$IP" ]; then
        printf "%-15s | %-15s | %-10s | %-8s | %-10s | %s\n" "$NAME" "N/A" "-" "-" "-" "❌ No IP"
        echo "$NAME,N/A,-,-,-,NO_IP" >> $REPORT_FILE
        continue
    fi

    # 2. Đo Latency (Ping 5 gói)
    # -c 5: Gửi 5 gói
    # -i 0.2: Gửi nhanh (cách nhau 0.2s)
    # -W 1: Timeout 1s
    PING_RES=$(ping -c 5 -i 0.2 -W 1 $IP | tail -n 2)

    # Phân tích kết quả Ping
    LOSS=$(echo "$PING_RES" | grep -oP '\d+(?=% packet loss)')
    AVG_RTT=$(echo "$PING_RES" | grep -oP '(?<=rtt min/avg/max/mdev = )[\d.]+' | cut -d'/' -f2)

    if [ -z "$AVG_RTT" ]; then AVG_RTT="Timeout"; fi
    if [ -z "$LOSS" ]; then LOSS="100"; fi

    # 3. Kiểm tra Port 22 (SSH Stability)
    # nc -z: Scan mode (không gửi dữ liệu)
    # -w 2: Timeout 2s
    SSH_STATUS="CLOSED"
    if nc -z -w 2 $IP 22 2>/dev/null; then
        SSH_STATUS="OPEN"
    fi

    # 4. Đánh giá
    FINAL_STATUS="✅ Stable"
    if [ "$LOSS" -gt 0 ]; then FINAL_STATUS="⚠️ Unstable"; fi
    if [ "$AVG_RTT" == "Timeout" ]; then FINAL_STATUS="❌ Down"; fi

    # In ra màn hình cho đẹp
    printf "%-15s | %-15s | %-10s | %-8s | %-10s | %s\n" "$NAME" "$IP" "${AVG_RTT}ms" "${LOSS}%" "$SSH_STATUS" "$FINAL_STATUS"

    # Ghi vào file CSV để vẽ biểu đồ
    echo "$NAME,$IP,$AVG_RTT,$LOSS,$SSH_STATUS,$FINAL_STATUS" >> $REPORT_FILE

done

echo "---------------------------------------------------------------------------------------"
echo "📝 Kết quả chi tiết đã được lưu vào: $REPORT_FILE"