devops@k8s-master:~/benchmark-1$ ./benchmark.sh heavy
=======================================================
🚀 BENCHMARK: HEAVY
=======================================================
------------------------------------------------
▶️  CASE: 1 VM (heavy)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
datavolume.cdi.kubevirt.io/vm-heavy-1-1 created
virtualmachine.kubevirt.io/vm-heavy-1-1 created
   [Wait] Đã request 1 VM. Đang chờ Running...
   ... Status: 1 / 1 Running
   ✅ DONE! Time: 124s
------------------------------------------------
▶️  CASE: 2 VM (heavy)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
datavolume.cdi.kubevirt.io/vm-heavy-2-1 created
virtualmachine.kubevirt.io/vm-heavy-2-1 created
datavolume.cdi.kubevirt.io/vm-heavy-2-2 created
virtualmachine.kubevirt.io/vm-heavy-2-2 created
   [Wait] Đã request 2 VM. Đang chờ Running...
   ... Status: 2 / 2 Running
   ✅ DONE! Time: 113s
------------------------------------------------
▶️  CASE: 4 VM (heavy)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
datavolume.cdi.kubevirt.io/vm-heavy-4-1 created
virtualmachine.kubevirt.io/vm-heavy-4-1 created
datavolume.cdi.kubevirt.io/vm-heavy-4-2 created
virtualmachine.kubevirt.io/vm-heavy-4-2 created
datavolume.cdi.kubevirt.io/vm-heavy-4-3 created
virtualmachine.kubevirt.io/vm-heavy-4-3 created
datavolume.cdi.kubevirt.io/vm-heavy-4-4 created
virtualmachine.kubevirt.io/vm-heavy-4-4 created
   [Wait] Đã request 4 VM. Đang chờ Running...
   ... Status: 4 / 4 Running
   ✅ DONE! Time: 145s

📊 KẾT QUẢ (HEAVY)
SL VM      | Giây
-----------|----------
1 VM       | 124
2 VM       | 113
4 VM       | 145


----------------------------------------------------------------------------------------------------------------------------------------
devops@k8s-master:~/benchmark-1$ ./benchmark.sh opt
=======================================================
🚀 BENCHMARK: OPT
=======================================================
------------------------------------------------
▶️  CASE: 1 VM (opt)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
   [Wait] Đã request 1 VM. Đang chờ Running...
   ... Status: 1 / 1 Running
   ✅ DONE! Time: 21s
------------------------------------------------
▶️  CASE: 2 VM (opt)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
   [Wait] Đã request 2 VM. Đang chờ Running...
   ... Status: 2 / 2 Running
   ✅ DONE! Time: 21s
------------------------------------------------
▶️  CASE: 4 VM (opt)
   [Cleanup] Xoá tài nguyên cũ...
   [Cleanup] Đợi 10s...
   [Wait] Đã request 4 VM. Đang chờ Running...
   ... Status: 4 / 4 Running
   ✅ DONE! Time: 38s

📊 KẾT QUẢ (OPT)
SL VM      | Giây
-----------|----------
1 VM       | 21
2 VM       | 21
4 VM       | 38