//+------------------------------------------------------------------+
//|                                  Astra_EURUSD_Industrial.mq5
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"
#property description "EURUSD Industrial-Grade Institutional Trend and Pullback EA"
#property description "Sains Manajemen Project 2 - Broker Exness 7-Year Backtest."
#property description "Anti-Martingale, Anti-Grid, Anti-HFT, NO Leverage."

#include <Trade/Trade.mqh>
#include <AstraInstrumentProfile.mqh>
#include <AstraRiskManager.mqh>
#include <AstraSignalEngine.mqh>

//+------------------------------------------------------------------+
//| Input Parameter Teroptimasi untuk EURUSD (Forex)
//+------------------------------------------------------------------+
input group "=== Risk and Money Management ==="
input double           InpRiskPercent         = 1.0;          // Alokasi Risiko (% Ekuitas)
input double           InpMaxDrawdownLimit    = 25.0;         // Batas Maksimum Drawdown Circuit Breaker (%)
input bool             InpUseTrailingStop     = true;         // Trailing Stop Berbasis ATR
input double           InpTrailingAtrMult     = 1.5;          // Pengali ATR untuk Trailing Stop
input bool             InpAllowReal           = false;        // IZINKAN Akun Real (Default: FALSE)

input group "=== Signal Parameters ==="
input int              InpTrendEmaPeriod      = 200;          // Periode Trend EMA (Filter Makro)
input int              InpFastEmaPeriod       = 21;           // Periode Fast EMA
input int              InpRsiPeriod           = 14;           // Periode RSI
input double           InpRsiLowerThreshold   = 42.0;         // Batas Bawah RSI Pullback (Buy)
input double           InpRsiUpperThreshold   = 58.0;         // Batas Atas RSI Pullback (Sell)
input int              InpAtrPeriod           = 14;           // Periode ATR
input double           InpAtrSlMult           = 2.0;          // Pengali ATR untuk Stop Loss
input double           InpAtrTpMult           = 3.5;          // Pengali ATR untuk Take Profit

input group "=== Execution and Broker ==="
input int              InpMagicNumber         = 2001;         // Magic Number Unik
input int              InpSlippage            = 30;           // Toleransi Slippage (Points)
input int              InpMaxSpread           = 25;           // Batas Maksimum Spread (Points)

CAstraRiskManager      g_riskManager;
CAstraSignalEngine     g_signalEngine;

int OnInit()
  {
   if(!CAstraRiskManager::IsAccountAllowed(InpAllowReal))
      return INIT_FAILED;

   if(!g_riskManager.Init(_Symbol, InpMagicNumber, InpSlippage, InpMaxDrawdownLimit))
      return INIT_FAILED;

   if(!g_signalEngine.Init(_Symbol, _Period, InpTrendEmaPeriod, InpFastEmaPeriod, InpRsiPeriod, InpAtrPeriod))
      return INIT_FAILED;

   PrintFormat("[Astra_%s] Inisialisasi Berhasil. Magic: %d | Risk: %.1f%% | Anti-Leverage Mode",
               "EURUSD", InpMagicNumber, InpRiskPercent);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_signalEngine.ReleaseIndicators();
  }

void OnTick()
  {
   if(InpUseTrailingStop)
     {
      double atr = g_signalEngine.GetCurrentATR();
      if(atr > 0.0)
         g_riskManager.ManageTrailingStop(InpMagicNumber, atr * InpTrailingAtrMult);
     }

   if(!g_signalEngine.IsNewBar())
      return;

   if(!g_riskManager.IsSpreadAcceptable(InpMaxSpread))
      return;

   if(!g_riskManager.CheckDrawdownLimit())
      return;

   ENUM_SIGNAL_TYPE signal = g_signalEngine.EvaluateSignal(InpRsiLowerThreshold, InpRsiUpperThreshold);
   if(signal == SIGNAL_NONE)
      return;

   int activeCount = g_riskManager.CountActivePositions(InpMagicNumber);
   ENUM_POSITION_TYPE activeType = g_riskManager.GetActivePositionType(InpMagicNumber);

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double atr   = g_signalEngine.GetCurrentATR();
   if(atr <= 0.0 || point <= 0.0)
      return;

   double slPoints = (atr * InpAtrSlMult) / point;

   if(signal == SIGNAL_BUY)
     {
      if(activeCount > 0)
        {
         if(activeType == POSITION_TYPE_SELL)
            g_riskManager.CloseAllPositions(InpMagicNumber);
         else
            return;
        }

      double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slPrice  = askPrice - (atr * InpAtrSlMult);
      double tpPrice  = askPrice + (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, askPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_BUY, lotSize, slPrice, tpPrice, "Astra_EURUSD_BUY");
     }
   else if(signal == SIGNAL_SELL)
     {
      if(activeCount > 0)
        {
         if(activeType == POSITION_TYPE_BUY)
            g_riskManager.CloseAllPositions(InpMagicNumber);
         else
            return;
        }

      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slPrice  = bidPrice + (atr * InpAtrSlMult);
      double tpPrice  = bidPrice - (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, bidPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_SELL, lotSize, slPrice, tpPrice, "Astra_EURUSD_SELL");
     }
  }
//+------------------------------------------------------------------+
