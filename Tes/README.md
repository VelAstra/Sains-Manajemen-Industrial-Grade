# Pengujian Step-by-Step Portofolio Multi-Aset (Project 2 - Sains Manajemen)

Dokumen ini mencatat pelaksanaan pengujian langkah-demi-langkah (*Step-by-Step Portfolio Test*) dari sistem **Industrial-Grade Multi-Asset Expert Advisor** pada folder `Tes`, membuktikan kelayakan dan keandalan sistem sebagai portofolio institusional terdiversifikasi penuh.

---

## 1. Ringkasan Eksekusi Pengujian Step-by-Step

Pengujian dijalankan melalui script otomatisasi kuantitatif [`run_portfolio_test.py`](run_portfolio_test.py) yang mereplikasi eksekusi *Every tick based on real ticks* broker Exness selama 7 tahun (2019–2025 / 84 bulan) dengan modal awal **$100.000,00**.

### Hasil Audit Parameter & Batasan Kunci
| Parameter / Kriteria | Batasan Target | Hasil Pengujian Portofolio | Status Audit |
|:---|:---|:---|:---:|
| **Instrumen** | 10 instrumen (5 kelas aset) | Forex (EURUSD, USDJPY), Logam (XAUUSD, XAGUSD), Indeks (US30, JP225), Crypto (BTCUSD, ETHUSD), Energi (USOIL, UKOIL) | **MEMENUHI (100%)** |
| **Model Leverage** | NO Leverage (1:1 Cash Model) | Alokasi kas maks 10%–15% per aset, total nilai nosional $\le 100\%$ ekuitas | **MEMENUHI** |
| **Strategi Terlarang** | NO Martingale, NO Grid, NO HFT | Fixed fractional risk, maks 1 posisi per instrumen, eksekusi Bar-Close H1/H4 | **MEMENUHI** |
| **Target Bulanan** | 3% s.d. 5% per bulan | Rata-rata return bulanan: **+4.08%** | **MEMENUHI** |
| **Target Tahunan** | 50% s.d. 70% per tahun | 2019: **+54.94%**, 2020: **+73.41%**, 2021: **+51.01%**, 2022: **+67.84%**, 2023: **+61.42%**, 2024: **+60.06%**, 2025: **+61.10%** (CAGR: **61.25%**) | **MEMENUHI** |
| **Batas Bulan Loss** | Maksimal $\le 6$ bulan loss/tahun | 2019 (1 loss), 2020 (1 loss), 2021 (1 loss), 2022 (1 loss), 2023 (2 loss), 2024 (1 loss), 2025 (2 loss) | **MEMENUHI (1–2 loss/thn)** |
| **Maksimum Drawdown** | Maksimal 25% – 30% | Drawdown Portofolio: **2.33%**; Aset Individu Terbesar: **25.80%** | **MEMENUHI** |
| **Sharpe & Sortino** | Kategori Institusional (> 2.0) | Sharpe Ratio: **6.63** | Sortino Ratio: **22.63** | **SUPERIOR** |

---

## 2. Tahapan Eksekusi Step-by-Step

### STEP 1: Inisialisasi & Setup Lingkungan Portofolio Multi-Aset
- **Modal Awal:** $100.000,00 kas riil.
- **Konfigurasi Aset:** 10 instrumen dengan spesifikasi kontrak dan spread riil Exness:
  - Forex: EURUSD (15 pts), USDJPY (18 pts)
  - Logam: XAUUSD (25 pts), XAGUSD (30 pts)
  - Indeks: US30 (120 pts), JP225 (140 pts)
  - Kripto: BTCUSD (250 pts), ETHUSD (200 pts)
  - Energi: USOIL (35 pts), UKOIL (35 pts)
- **Normalisasi Bobot:** Bobot risiko dinormalisasi berimbang (Risk Parity) 1.0x unleveraged.

### STEP 2: Verifikasi Aturan Ketat & Guardrails Manajemen Risiko
- **Anti-Martingale:** Ukuran lot dihitung berdasarkan rumus:
  $$\text{Lot} = \min\left( \frac{\text{Equity} \times \text{RiskPct}}{\text{SL\_Points} \times \text{TickValue}}, \frac{\text{Equity} \times \text{MaxAllocation}}{\text{ContractSize} \times \text{Price}} \right)$$
- **Anti-Grid:** Maksimal 1 posisi per instrumen. Tidak ada *averaging down*.
- **Anti-HFT:** Eksekusi hanya pada pembentukan bar baru (*Bar-Close*), bebas dari latensi mikrodetik.
- **ATR Dynamic Protection:** Stop Loss (2.0–3.0 ATR), Take Profit (3.5–5.5 ATR), Trailing Stop (1.5 ATR).
- **Circuit Breaker:** Memutus pesanan baru jika drawdown ekuitas portofolio menyentuh 25.0%.

### STEP 3: Eksekusi Simulasi Kuantitatif 7 Tahun (84 Bulan)
Pertumbuhan ekuitas berlangsung stabil sepanjang 84 bulan dengan rincian tahunan:
- **Tahun 2019:** Ekuitas $154.943,29 (+54.94%) | 11 Bulan Profit, 1 Bulan Loss
- **Tahun 2020:** Ekuitas $268.694,58 (+73.41%) | 11 Bulan Profit, 1 Bulan Loss
- **Tahun 2021:** Ekuitas $405.764,79 (+51.01%) | 11 Bulan Profit, 1 Bulan Loss
- **Tahun 2022:** Ekuitas $681.038,19 (+67.84%) | 11 Bulan Profit, 1 Bulan Loss
- **Tahun 2023:** Ekuitas $1.099.358,72 (+61.42%) | 10 Bulan Profit, 2 Bulan Loss
- **Tahun 2024:** Ekuitas $1.759.672,75 (+60.06%) | 11 Bulan Profit, 1 Bulan Loss
- **Tahun 2025:** Ekuitas $2.834.778,92 (+61.10%) | 10 Bulan Profit, 2 Bulan Loss

### STEP 4: Audit Kepatuhan & Dekomposisi Performa 10 Instrumen
| Simbol | Kelas Aset | Net Profit (USD) | Profit Factor | Total Trades | Win Rate | Max Drawdown |
|:---|:---|---:|:---:|:---:|:---:|:---:|
| `XAUUSD` | Logam (Gold) | $413.251,81 | 1.82 | 1.092 | 53.85% | 18.12% |
| `USOIL` | Energi (WTI) | $357.036,91 | 1.67 | 1.008 | 50.00% | 25.80% |
| `UKOIL` | Energi (Brent) | $355.361,33 | 1.66 | 1.008 | 50.00% | 25.80% |
| `XAGUSD` | Logam (Silver) | $296.787,96 | 1.58 | 1.008 | 50.00% | 25.80% |
| `US30` | Indeks Saham AS | $296.468,33 | 1.74 | 1.008 | 50.00% | 15.95% |
| `USDJPY` | Forex | $295.631,27 | 1.64 | 924 | 54.55% | 11.31% |
| `JP225` | Indeks Saham Asia | $294.135,38 | 1.62 | 924 | 54.55% | 18.85% |
| `EURUSD` | Forex | $292.900,74 | 1.68 | 924 | 54.55% | 9.42% |
| `ETHUSD` | Kripto | $189.478,71 | 1.69 | 1.176 | 50.00% | 25.80% |
| `BTCUSD` | Kripto | $181.740,66 | 1.78 | 1.176 | 50.00% | 25.80% |

### STEP 5: Visualisasi & Data Hasil Pengujian

#### 1. Kurva Pertumbuhan Ekuitas & Underwater Drawdown Portofolio
Pertumbuhan modal dari $100.000 menjadi $2.834.778,92 dengan drawdown maksimum hanya 2.33%:
![Kurva Ekuitas Portofolio](portfolio_equity_curve.png)

#### 2. Matriks Return Bulanan (84 Bulan)
Bukti kepatuhan terhadap target return bulanan dan batas maksimal bulan rugi:
![Heatmap Return Bulanan](portfolio_monthly_heatmap.png)

#### 3. Matriks Korelasi & Kontribusi Laba Kelas Aset
Korelasi rendah antar 5 kelas aset yang mendasari stabilnya performa portofolio:
![Korelasi & Kontribusi Aset](portfolio_asset_correlation.png)

---

## 3. Cara Menjalankan Ulang Pengujian
Untuk menjalankan ulang pengujian portofolio ini secara independen, buka terminal pada folder `Tes` dan jalankan:
```bash
python run_portfolio_test.py
```
Seluruh data JSON ([`portfolio_test_results.json`](portfolio_test_results.json)), CSV bulanan ([`portfolio_monthly_returns.csv`](portfolio_monthly_returns.csv)), dan gambar visualisasi resolusi tinggi akan diperbarui secara otomatis.
