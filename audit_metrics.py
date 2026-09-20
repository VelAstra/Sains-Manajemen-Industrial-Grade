import json

with open('backtest/results/backtest_7years_summary.json', 'r') as f:
    d = json.load(f)

print("=== AUDIT HASIL QUANTITATIVE BACKTEST 7 TAHUN ===")
print(f"Initial Balance: ${d['initial_balance']:,.2f}")
print(f"Final Equity:    ${d['final_equity']:,.2f}")
print(f"Total Net Profit: ${d['total_net_profit']:,.2f} (+{d['total_return_pct']}%)")
print(f"CAGR:            {d['cagr_pct']}%")
print(f"Sharpe Ratio:    {d['sharpe_ratio']}")
print(f"Sortino Ratio:   {d['sortino_ratio']}")
print(f"Max Portfolio DD: {d['max_equity_drawdown_pct']}% (Batas: 25-30%)")
print(f"Total Trades:    {d['total_trades']:,} | Win Rate: {d['overall_win_rate_pct']}%")

print("\n--- RETURN TAHUNAN (Target 50% - 70%) ---")
for y, ret in d['annual_breakdown'].items():
    print(f"Tahun {y}: +{ret}%")

print("\n--- AUDIT BULAN LOSS PER TAHUN (Maksimal <= 6 Bulan) ---")
for y, months in d['monthly_matrix'].items():
    loss_count = sum(1 for m, r in months.items() if r < 0)
    win_count = len(months) - loss_count
    avg_m = sum(months.values()) / len(months) * 100.0
    print(f"Tahun {y}: {win_count} Bulan Profit, {loss_count} Bulan Loss (Rata-rata Bulanan: +{avg_m:.2f}%)")

print("\n--- PERFORMA 10 INSTRUMEN ---")
for sym, res in d['instrument_breakdown'].items():
    print(f"{sym:<8}: Net Profit ${res['net_profit']:>11,.2f} | PF: {res['profit_factor']:>4.2f} | WinRate: {res['win_rate_pct']}% | MaxDD: {res['max_dd_pct']}%")
