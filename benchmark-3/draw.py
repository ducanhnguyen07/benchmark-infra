import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import io


df = pd.read_csv('ux_report.csv')

df['vm_id'] = df['VM_Name'].str.extract('(\d+)').astype(int)
df = df.sort_values('vm_id')

sns.set_theme(style="whitegrid")
fig, ax1 = plt.subplots(figsize=(14, 7))

color_tp = 'skyblue'
bars = sns.barplot(data=df, x='VM_Name', y='Throughput(Mbps)', ax=ax1, color=color_tp, alpha=0.8, edgecolor='black')
ax1.set_ylabel('TCP Throughput (Mbps)', color='tab:blue', fontsize=12, fontweight='bold')
ax1.tick_params(axis='y', labelcolor='tab:blue')
ax1.set_xlabel('Virtual Machine', fontsize=12, fontweight='bold')
ax1.set_ylim(0, 900)

for container in bars.containers:
    ax1.bar_label(container, fmt='%.0f', padding=3, fontsize=9, color='tab:blue')

ax2 = ax1.twinx()
color_jit = 'tab:red'
sns.lineplot(data=df, x='VM_Name', y='Jitter(ms)', ax=ax2, color=color_jit, marker='o', markersize=8, linewidth=2, sort=False)
ax2.set_ylabel('UDP Jitter (ms)', color=color_jit, fontsize=12, fontweight='bold')
ax2.tick_params(axis='y', labelcolor=color_jit)
ax2.set_ylim(0, 0.5)

ax1.set_xticklabels(ax1.get_xticklabels(), rotation=45, ha='right')
ax1.grid(True, axis='y', linestyle='--', alpha=0.7)
ax2.grid(False) # Tắt grid trục phụ cho đỡ rối

ax1.axhline(1000, color='gray', linestyle='--', linewidth=1, alpha=0.5)
ax1.text(0, 1000, ' 1Gbps Theory', color='gray', va='bottom', fontsize=8)

plt.tight_layout()

plt.savefig('benchmark_qos_chart.png', dpi=300)
plt.show()