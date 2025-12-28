#!/bin/bash

# --- CẤU HÌNH ---
NAMESPACE="testapi"
TOTAL_VMS=20
PACKET_COUNT=100  # Gửi 100 gói tin cực nhanh

# Kiểm tra quyền Root (Bắt buộc cho flood ping)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lỗi: Lệnh 'ping -f' yêu cầu quyền root."
  echo "👉 Hãy chạy lại bằng lệnh: sudo ./flood_test.sh"
  exit 1
fi

echo "======================================================================="
echo "🌊 NETWORK STRESS TEST: FLOOD PING (100 Packets/VM)"
echo "⚙️  Mục tiêu: Kiểm tra độ ổn định của vCPU khi chịu tải mạng cao"
echo "======================================================================="

# In tiêu đề bảng
printf "%-15s | %-15s | %-10s | %-10s | %s\n" "VM Name" "IP Address" "Loss (%)" "Avg RTT" "Stability"
echo "-----------------------------------------------------------------------"

for ((i=1; i<=TOTAL_VMS; i++)); do
    NAME="student-vm-$i"

    # Lấy IP
    IP=$(kubectl get vmi $NAME -n $NAMESPACE -o jsonpath='{.status.interfaces[0].ipAddress}' 2>/dev/null)

    # Nếu chưa có IP (do VM chưa boot xong)
    if [ -z "$IP" ]; then
        printf "%-15s | %-15s | %-10s | %-10s | %s\n" "$NAME" "N/A" "-" "-" "❌ No IP"
        continue
    fi

    # Thực hiện Flood Ping
    # -f: Flood (gửi tấp nập)
    # -c: Số lượng gói
    # -q: Quiet (chỉ hiện kết quả tổng hợp, không in từng dòng)
    PING_RESULT=$(ping -f -c $PACKET_COUNT -q $IP 2>&1)

    # Phân tích kết quả (Parsing)
    LOSS=$(echo "$PING_RESULT" | grep -oP '\d+(?=% packet loss)')
    RTT=$(echo "$PING_RESULT" | grep -oP 'rtt min/avg/max/mdev = \K[0-9.]+' | awk -F/ '{print $2}')

    # Xử lý hiển thị nếu timeout
    if [ -z "$LOSS" ]; then LOSS="100"; fi
    if [ -z "$RTT" ]; then RTT="Timeout"; else RTT="${RTT}ms"; fi

    # Đánh giá trạng thái
    STATUS="✅ Excellent"
    if [ "$LOSS" -gt 0 ]; then STATUS="⚠️  Drop Packet"; fi
    if [ "$LOSS" -eq 100 ]; then STATUS="❌ Disconnected"; fi

    # In ra bảng
    printf "%-15s | %-15s | %-10s | %-10s | %s\n" "$NAME" "$IP" "${LOSS}%" "$RTT" "$STATUS"
done

echo "-----------------------------------------------------------------------"
echo "📝 Ghi chú: Nếu Loss = 0% nhưng Avg RTT cao (>50ms) -> CPU Node đang bận."
echo "            Nếu Loss > 0% -> vCPU của VM bị nghẽn (CPU Starvation)."