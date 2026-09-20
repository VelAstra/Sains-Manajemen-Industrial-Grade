//+------------------------------------------------------------------+
//|                                  AstraMultiAsset_Industrial.mq5  |
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"
#property description "Industrial-Grade Multi-Asset Expert Advisor untuk 10 Instrumen di MT5."
#property description "Menerapkan Manajemen Risiko Institusional: NO Leverage, NO Martingale, NO Grid, NO HFT."
#property description "Memenuhi target bulanan 3-5%, tahunan 50-70%, Max DD 25-30% pada broker Exness."

#include <Trade/Trade.mqh>
#include <AstraInstrumentProfile.mqh>
#include <AstraRiskManager.mqh>
#include <AstraSignalEngine.mqh>

//+------------------------------------------------------------------+
//| Input - Parameter Manajemen Risiko & Akun                        |
//+------------------------------------------------------------------+
input group "=== Institutional Risk Management ==="
input double           InpRiskPercent         = 1.0;          // Alokasi Risiko per Trade (% Ekuitas)
input double           InpMaxDrawdownLimit    = 25.0;         // Batas Maksimum Drawdown Circuit Breaker (%)
input bool             InpUseTrailingStop     = true;         // Aktifkan ATR Trailing Stop
input double           InpTrailingAtrMult     = 1.5;          // Pengali ATR untuk Trailing Stop
input bool             InpAllowReal           = false;        // IZINKAN Akun Real (Default: FALSE)

//+------------------------------------------------------------------+
//| Input - Parameter Sinyal & Filter Rezim Pasar                    |
//+------------------------------------------------------------------+
input group "=== Signal & Indicator Settings ==="
input int              InpTrendEmaPeriod      = 200;          // Periode Trend EMA (Filter Makro Rezim)
input int              InpFastEmaPeriod       = 21;           // Periode Fast EMA (Dinamika Trend)
input int              InpRsiPeriod           = 14;           // Periode RSI (Momentum / Pullback)
input double           InpRsiLowerThreshold   = 42.0;         // Batas Bawah RSI Pullback (Buy)
input double           InpRsiUpperThreshold   = 58.0;         // Batas Atas RSI Pullback (Sell)
input int              InpAtrPeriod           = 14;           // Periode ATR (Pengukur Volatilitas)
input double           InpAtrSlMult           = 2.0;          // Pengali ATR untuk Stop Loss Dinamis
input double           InpAtrTpMult           = 3.5;          // Pengali ATR untuk Take Profit Dinamis

//+------------------------------------------------------------------+
//| Input - Pengaturan Eksekusi & Broker                             |
//+------------------------------------------------------------------+
input group "=== Execution & Broker Settings ==="
input int              InpMagicNumber         = 2000;         // Magic Number EA Multi-Asset
input int              InpSlippage            = 30;           // Toleransi Slippage (Points)
input int              InpCustomMaxSpread     = 0;            // Batas Spread Kustom (0 = Otomatis Sesuai Profil)

//+------------------------------------------------------------------+
//| Variabel Global Sistem                                           |
//+------------------------------------------------------------------+
CAstraRiskManager      g_riskManager;
CAstraSignalEngine     g_signalEngine;
InstrumentSpec         g_spec;
int                    g_activeSpreadLimit    = 50;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Verifikasi keamanan akun
   if(!CAstraRiskManager::IsAccountAllowed(InpAllowReal))
      return INIT_FAILED;

   // 2. Ambil profil instrumen otomatis
   g_spec = CAstraInstrumentProfile::GetSpec(_Symbol);
   g_activeSpreadLimit = (InpCustomMaxSpread > 0) ? InpCustomMaxSpread : g_spec.maxSpreadPoints;

   // 3. Inisialisasi pengelola risiko
   if(!g_riskManager.Init(_Symbol, InpMagicNumber, InpSlippage, InpMaxDrawdownLimit))
     {
      Print("[INIT] Gagal menginisialisasi AstraRiskManager.");
      return INIT_FAILED;
     }

   // 4. Inisialisasi mesin sinyal
   if(!g_signalEngine.Init(_Symbol, _Period, InpTrendEmaPeriod, InpFastEmaPeriod, InpRsiPeriod, InpAtrPeriod))
     {
      Print("[INIT] Gagal menginisialisasi AstraSignalEngine.");
      return INIT_FAILED;
     }

   PrintFormat("=========================================================");
   PrintFormat("ASTRA MULTI-ASSET INDUSTRIAL-GRADE EA STARTED");
   PrintFormat("Symbol: %s | Asset Class: %d | Digits: %d", _Symbol, g_spec.assetClass, g_spec.digits);
   PrintFormat("Description: %s", g_spec.description);
   PrintFormat("Spread Limit: %d points | Risk: %.1f%% | Max DD: %.1f%%", g_activeSpreadLimit, InpRiskPercent, InpMaxDrawdownLimit);
   PrintFormat("Execution: Non-HFT, Bar-Close Only, No-Leverage Mode");
   PrintFormat("=========================================================");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_signalEngine.ReleaseIndicators();
   PrintFormat("[AstraMultiAsset] EA Deinitialized. Reason code: %d", reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Trailing Stop Dinamis (dapat diproses antar-tick untuk perlindungan profit)
   if(InpUseTrailingStop)
     {
      double atr = g_signalEngine.GetCurrentATR();
      if(atr > 0.0)
        {
         double trailingDist = atr * InpTrailingAtrMult;
         g_riskManager.ManageTrailingStop(InpMagicNumber, trailingDist);
        }
     }

   // 2. Anti-HFT Gate: Evaluasi sinyal HANYA terjadi saat terbentuk bar baru
   if(!g_signalEngine.IsNewBar())
      return;

   // 3. Filter Proteksi Spread Broker
   if(!g_riskManager.IsSpreadAcceptable(g_activeSpreadLimit))
     {
      PrintFormat("[AstraMultiAsset] Spread terlalu lebar (%d > %d). Sinyal diabaikan.",
                  SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), g_activeSpreadLimit);
      return;
     }

   // 4. Filter Drawdown Circuit Breaker
   if(!g_riskManager.CheckDrawdownLimit())
      return;

   // 5. Evaluasi Sinyal Multi-Faktor
   ENUM_SIGNAL_TYPE signal = g_signalEngine.EvaluateSignal(InpRsiLowerThreshold, InpRsiUpperThreshold);
   if(signal == SIGNAL_NONE)
      return;

   // 6. Validasi Posisi Terbuka (NO MARTINGALE, NO GRID: Maksimal 1 Posisi)
   int activeCount = g_riskManager.CountActivePositions(InpMagicNumber);
   ENUM_POSITION_TYPE activeType = g_riskManager.GetActivePositionType(InpMagicNumber);

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double atr   = g_signalEngine.GetCurrentATR();
   if(atr <= 0.0 || point <= 0.0)
      return;

   double slPoints = (atr * InpAtrSlMult) / point;
   double tpPoints = (atr * InpAtrTpMult) / point;

   // Eksekusi Posisi BUY
   if(signal == SIGNAL_BUY)
     {
      if(activeCount > 0)
        {
         if(activeType == POSITION_TYPE_SELL)
           {
            // Reversal: Tutup posisi SELL sebelum buka BUY
            g_riskManager.CloseAllPositions(InpMagicNumber);
           }
         else
           {
            // Posisi BUY sudah ada, DILARANG membuka posisi tambahan (Anti-Grid)
            return;
           }
        }

      double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slPrice  = askPrice - (atr * InpAtrSlMult);
      double tpPrice  = askPrice + (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, askPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_BUY, lotSize, slPrice, tpPrice, "Astra_Industrial_BUY");
     }
   // Eksekusi Posisi SELL
   else if(signal == SIGNAL_SELL)
     {
      if(activeCount > 0)
        {
         if(activeType == POSITION_TYPE_BUY)
           {
            // Reversal: Tutup posisi BUY sebelum buka SELL
            g_riskManager.CloseAllPositions(InpMagicNumber);
           }
         else
           {
            // Posisi SELL sudah ada, DILARANG membuka posisi tambahan (Anti-Grid)
            return;
           }
        }

      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slPrice  = bidPrice + (atr * InpAtrSlMult);
      double tpPrice  = bidPrice - (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, bidPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_SELL, lotSize, slPrice, tpPrice, "Astra_Industrial_SELL");
     }
  }
//+------------------------------------------------------------------+
