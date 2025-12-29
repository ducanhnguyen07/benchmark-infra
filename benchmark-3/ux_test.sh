#!/bin/bash

# --- CẤU HÌNH ---
NAMESPACE="testapi"
TOTAL_VMS=20
SSH_USER="debian"
SSH_PASS="1234"
REPORT_FILE="ux_report.csv"

echo "VM_Name,IP,Throughput(Mbps),Jitter(ms),Result" > $REPORT_FILE

echo "======================================================="
echo "🚀 USER EXPERIENCE BENCHMARK (iPerf3) - V3 Stable"
echo "⚙️  Đo băng thông (Download) và Jitter (SSH Lag)"
echo "======================================================="
printf "%-15s | %-15s | %-15s | %-10s | %s\n" "VM Name" "IP Address" "Speed (Mbps)" "Jitter" "Ranking"
echo "-----------------------------------------------------------------------------"

for ((i=1; i<=TOTAL_VMS; i++)); do
    NAME="student-vm-$i"

    # 1. Lấy IP
    IP=$(kubectl get vmi $NAME -n $NAMESPACE -o jsonpath='{.status.interfaces[0].ipAddress}' 2>/dev/null)

    if [ -z "$IP" ]; then
        printf "%-15s | %-15s | %-15s | %-10s | %s\n" "$NAME" "N/A" "-" "-" "❌ No IP"
        continue
    fi

    # 2. Cài đặt & Khởi chạy iPerf3
    # Lần này ta dùng --one-off cho server để nó xử lý 1 client rồi tự tắt (tránh treo process)
    COMMAND="
      export DEBIAN_FRONTEND=noninteractive
      # Chỉ cài nếu chưa có (Check nhanh)
      if ! command -v iperf3 &> /dev/null; then
          echo $SSH_PASS | sudo -S apt-get update -qq > /dev/null 2>&1
          echo $SSH_PASS | sudo -S apt-get install -y -qq iperf3 > /dev/null 2>&1
      fi
      pkill iperf3
      # Chạy server dạng daemon (-D)
      iperf3 -s -D > /dev/null 2>&1
    "

    # Timeout 90s cho cài đặt (phòng khi mạng chậm)
    timeout 90s sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SSH_USER@$IP "$COMMAND" > /dev/null 2>&1

    # QUAN TRỌNG: Chờ 5s để Server chắc chắn đã lên
    sleep 5

    # 3. TEST 1: Đo băng thông TCP (Chỉ 2s để tránh sập VM yếu)
    TCP_RESULT=$(iperf3 -c $IP -t 2 -f m --json 2>/dev/null)
    THROUGHPUT=$(echo "$TCP_RESULT" | grep -oP '"bits_per_second":\s*\K[0-9.]+' | head -n 1 | awk '{printf "%.2f", $1/1000000}')

    # 4. TEST 2: Đo Jitter UDP (Chỉ 2s)
    UDP_RESULT=$(iperf3 -c $IP -u -t 2 -b 1M --json 2>/dev/null)
    JITTER=$(echo "$UDP_RESULT" | grep -oP '"jitter_ms":\s*\K[0-9.]+' | head -n 1)

    # Xử lý kết quả rỗng
    if [ -z "$THROUGHPUT" ]; then THROUGHPUT="0"; fi
    if [ -z "$JITTER" ]; then JITTER="Err"; fi

    # 5. Đánh giá
    RANK="✅ Smooth"
    if (( $(echo "$THROUGHPUT < 100" | bc -l 2>/dev/null) )); then RANK="⚠️ Slow DL"; fi
    if [ "$JITTER" == "Err" ]; then
        RANK="❌ Failed"
    elif (( $(echo "$JITTER > 10" | bc -l 2>/dev/null) )); then
        RANK="❌ Laggy"
    fi

    printf "%-15s | %-15s | %-15s | %-10s | %s\n" "$NAME" "$IP" "${THROUGHPUT} Mbps" "${JITTER} ms" "$RANK"

    echo "$NAME,$IP,$THROUGHPUT,$JITTER,$RANK" >> $REPORT_FILE
done

echo "-----------------------------------------------------------------------------"
echo "📝 Kết quả lưu tại: $REPORT_FILE"