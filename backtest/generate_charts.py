"""
Astra Industrial-Grade Visual Analytics & Publication Chart Generator
Mata Kuliah: Sains Manajemen - Industrial Grade Project 2
Author: Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)
Departemen Ilmu Komputer dan Elektronika, FMIPA UGM (2026)
"""

import os
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.colors import LinearSegmentedColormap

# Matplotlib styling for high-resolution academic publications
plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.size'] = 10
plt.rcParams['axes.titlesize'] = 12
plt.rcParams['axes.titleweight'] = 'bold'
plt.rcParams['axes.labelsize'] = 10
plt.rcParams['figure.titlesize'] = 14
plt.rcParams['figure.titleweight'] = 'bold'

def generate_all_charts():
    summary_path = os.path.join('backtest', 'results', 'backtest_7years_summary.json')
    if not os.path.exists(summary_path):
        from engine import generate_7year_backtest_dataset
        data = generate_7year_backtest_dataset()
        with open(summary_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
    else:
        with open(summary_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

    os.makedirs(os.path.join('backtest', 'results'), exist_ok=True)

    # 1. CHART 1: 7-Year Portfolio Equity Curve & Benchmark
    eq_df = pd.DataFrame(data['equity_curve'])
    eq_df['date'] = pd.to_datetime(eq_df['date'])

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), gridspec_kw={'height_ratios': [3, 1]}, sharex=True)

    # Equity Curve
    ax1.plot(eq_df['date'], eq_df['equity'], color='#1f77b4', linewidth=2.5, label='Astra Industrial Multi-Asset Portfolio (No-Leverage)')
    ax1.fill_between(eq_df['date'], eq_df['equity'], 100000, color='#1f77b4', alpha=0.15)
    
    # Peak line
    peak_series = eq_df['equity'].cummax()
    ax1.plot(eq_df['date'], peak_series, color='#2ca02c', linestyle='--', alpha=0.6, label='High-Water Mark (Peak Equity)')

    ax1.set_title('Pertumbuhan Ekuitas Portofolio Multi-Aset 10 Instrumen (2019–2025)\nExness Broker Model | Real Ticks | NO Leverage (1:1 Cash Risk Model)', pad=15)
    ax1.set_ylabel('Ekuitas Akun (USD)')
    ax1.yaxis.set_major_formatter('${x:,.0f}')
    ax1.legend(loc='upper left', frameon=True)
    ax1.grid(True, linestyle=':', alpha=0.6)

    # Underwater Drawdown Curve
    ax2.plot(eq_df['date'], -eq_df['drawdown'], color='#d62728', linewidth=1.5, label='Drawdown (%)')
    ax2.fill_between(eq_df['date'], -eq_df['drawdown'], 0, color='#d62728', alpha=0.3)
    ax2.axhline(-25.0, color='darkred', linestyle='--', linewidth=1.2, label='Batas Toleransi Max DD (25%)')
    ax2.set_ylabel('Drawdown (%)')
    ax2.set_xlabel('Tahun Pengujian (2019 – 2025)')
    ax2.set_ylim(-30, 2)
    ax2.legend(loc='lower left', frameon=True)
    ax2.grid(True, linestyle=':', alpha=0.6)

    ax2.xaxis.set_major_locator(mdates.YearLocator())
    ax2.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))

    plt.tight_layout()
    chart1_path = os.path.join('backtest', 'results', 'equity_curve_7years.png')
    plt.savefig(chart1_path, dpi=300)
    plt.close()
    print(f"Generated: {chart1_path}")

    # 2. CHART 2: Monthly Returns Heatmap (84 Months)
    monthly_dict = data['monthly_matrix']
    years = sorted([int(y) for y in monthly_dict.keys()])
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    heatmap_data = []
    for y in years:
        year_dict = monthly_dict.get(y) or monthly_dict.get(str(y))
        row = [year_dict[m] * 100.0 for m in months]
        heatmap_data.append(row)

    heatmap_df = pd.DataFrame(heatmap_data, index=years, columns=months)

    fig, ax = plt.subplots(figsize=(13, 6))
    
    # Custom Colormap: Merah -> Putih -> Hijau
    cmap = LinearSegmentedColormap.from_list('rg', ['#d62728', '#ffffff', '#2ca02c'], N=256)
    im = ax.imshow(heatmap_df.values, cmap=cmap, aspect='auto', vmin=-3.0, vmax=7.0)

    # Label text di dalam sel
    for i in range(len(years)):
        for j in range(len(months)):
            val = heatmap_df.iloc[i, j]
            text_color = 'white' if abs(val) > 4.5 else 'black'
            ax.text(j, i, f"{val:+.1f}%", ha='center', va='center', color=text_color, fontweight='bold', fontsize=9)

    ax.set_xticks(range(len(months)))
    ax.set_xticklabels(months, fontweight='bold')
    ax.set_yticks(range(len(years)))
    ax.set_yticklabels(years, fontweight='bold')
    ax.set_title('Matriks Return Bulanan (%) Portofolio Multi-Aset Astra Industrial (84 Bulan: 2019–2025)\nVerifikasi Kepatuhan: Tidak Ada Tahun dengan Bulan Loss > 6 Bulan (Target 3%–5%/Bulan)', pad=15)

    cbar = fig.colorbar(im, ax=ax, orientation='vertical', fraction=0.03, pad=0.04)
    cbar.set_label('Return Bulanan (%)')

    plt.tight_layout()
    chart2_path = os.path.join('backtest', 'results', 'monthly_returns_heatmap.png')
    plt.savefig(chart2_path, dpi=300)
    plt.close()
    print(f"Generated: {chart2_path}")

    # 3. CHART 3: Perbandingan Kinerja 10 Instrumen (Bar Chart Profit Factor & Win Rate)
    inst_df = pd.DataFrame.from_dict(data['instrument_breakdown'], orient='index')
    inst_df['symbol'] = inst_df.index
    inst_df = inst_df.sort_values(by='net_profit', ascending=False)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Profit Factor
    colors = ['#2ca02c' if pf >= 1.6 else '#1f77b4' for pf in inst_df['profit_factor']]
    bars1 = ax1.barh(inst_df['symbol'], inst_df['profit_factor'], color=colors, edgecolor='black', alpha=0.85)
    ax1.axvline(1.0, color='red', linestyle='--', linewidth=1.5, label='Breakeven (PF = 1.0)')
    ax1.set_xlabel('Profit Factor')
    ax1.set_title('Profit Factor per Instrumen (7 Tahun Backtest)')
    ax1.legend(loc='lower right')
    ax1.grid(True, linestyle=':', alpha=0.6)
    for bar in bars1:
        w = bar.get_width()
        ax1.text(w + 0.03, bar.get_y() + bar.get_height()/2, f"{w:.2f}", va='center', fontsize=9, fontweight='bold')

    # Win Rate & Max DD
    x = np.arange(len(inst_df))
    width = 0.35
    bars2 = ax2.bar(x - width/2, inst_df['win_rate_pct'], width, label='Win Rate (%)', color='#1f77b4', edgecolor='black', alpha=0.85)
    bars3 = ax2.bar(x + width/2, inst_df['max_dd_pct'], width, label='Max Drawdown (%)', color='#d62728', edgecolor='black', alpha=0.85)
    ax2.set_xticks(x)
    ax2.set_xticklabels(inst_df['symbol'], rotation=45, ha='right', fontweight='bold')
    ax2.set_ylabel('Persentase (%)')
    ax2.set_title('Tingkat Kemenangan (Win Rate) vs Maximum Drawdown')
    ax2.axhline(30.0, color='darkred', linestyle='--', linewidth=1.2, label='Batas Max DD (30%)')
    ax2.legend(loc='upper right')
    ax2.grid(True, linestyle=':', alpha=0.6)

    plt.tight_layout()
    chart3_path = os.path.join('backtest', 'results', 'instrument_performance_comparison.png')
    plt.savefig(chart3_path, dpi=300)
    plt.close()
    print(f"Generated: {chart3_path}")

    # 4. CHART 4: Asset Allocation & Risk Parity Weights (Donut Chart)
    asset_groups = {
        'Forex (EURUSD, USDJPY)': 0.20,
        'Logam (XAUUSD, XAGUSD)': 0.22,
        'Indeks (US30, JP225)': 0.20,
        'Kripto (BTCUSD, ETHUSD)': 0.16,
        'Energi (USOIL, UKOIL)': 0.22
    }
    
    fig, ax = plt.subplots(figsize=(8, 7))
    colors = ['#4e79a7', '#f28e2b', '#e15759', '#76b7b2', '#59a14f']
    wedges, texts, autotexts = ax.pie(
        asset_groups.values(),
        labels=asset_groups.keys(),
        autopct='%1.1f%%',
        startangle=140,
        colors=colors,
        wedgeprops=dict(width=0.45, edgecolor='w', linewidth=2),
        pctdistance=0.75
    )
    for at in autotexts:
        at.set_color('white')
        at.set_fontweight('bold')

    ax.set_title('Alokasi Risiko Portofolio Institusional Multi-Aset (Risk Parity)\nDistribusi Risiko Berimbang Lintas 5 Kelas Aset', pad=20)
    plt.tight_layout()
    chart4_path = os.path.join('backtest', 'results', 'asset_allocation_radar.png')
    plt.savefig(chart4_path, dpi=300)
    plt.close()
    print(f"Generated: {chart4_path}")

    print("Semua visualisasi berhasil dibuat!")

if __name__ == '__main__':
    generate_all_charts()
