import os

instruments = [
    {
        'file': 'Astra_EURUSD_Industrial.mq5',
        'symbol': 'EURUSD',
        'asset': 'Forex',
        'desc': 'EURUSD Industrial-Grade Institutional Trend and Pullback EA',
        'magic': 2001,
        'risk': 1.0,
        'sl_mult': 2.0,
        'tp_mult': 3.5,
        'spread': 25
    },
    {
        'file': 'Astra_USDJPY_Industrial.mq5',
        'symbol': 'USDJPY',
        'asset': 'Forex',
        'desc': 'USDJPY Industrial-Grade Macro Trend and Carry Momentum EA',
        'magic': 2002,
        'risk': 1.0,
        'sl_mult': 2.0,
        'tp_mult': 3.5,
        'spread': 25
    },
    {
        'file': 'Astra_XAUUSD_Industrial.mq5',
        'symbol': 'XAUUSD',
        'asset': 'Logam Mulia (Gold)',
        'desc': 'XAUUSD Gold Safe-Haven Volatility Expansion EA',
        'magic': 2003,
        'risk': 1.2,
        'sl_mult': 2.5,
        'tp_mult': 4.5,
        'spread': 40
    },
    {
        'file': 'Astra_XAGUSD_Industrial.mq5',
        'symbol': 'XAGUSD',
        'asset': 'Logam Mulia (Silver)',
        'desc': 'XAGUSD Silver High-Beta Breakout and Momentum EA',
        'magic': 2004,
        'risk': 1.0,
        'sl_mult': 2.5,
        'tp_mult': 4.0,
        'spread': 45
    },
    {
        'file': 'Astra_US30_Industrial.mq5',
        'symbol': 'US30',
        'asset': 'Indeks Saham AS',
        'desc': 'US30 Dow Jones Industrial Institutional Trend EA',
        'magic': 2005,
        'risk': 1.0,
        'sl_mult': 2.2,
        'tp_mult': 4.0,
        'spread': 150
    },
    {
        'file': 'Astra_JP225_Industrial.mq5',
        'symbol': 'JP225',
        'asset': 'Indeks Saham Asia',
        'desc': 'JP225 Nikkei Tokyo Session Momentum EA',
        'magic': 2006,
        'risk': 1.0,
        'sl_mult': 2.2,
        'tp_mult': 4.0,
        'spread': 180
    },
    {
        'file': 'Astra_BTCUSD_Industrial.mq5',
        'symbol': 'BTCUSD',
        'asset': 'Kripto',
        'desc': 'BTCUSD Bitcoin Macro Volatility Regime EA',
        'magic': 2007,
        'risk': 0.8,
        'sl_mult': 3.0,
        'tp_mult': 5.5,
        'spread': 300
    },
    {
        'file': 'Astra_ETHUSD_Industrial.mq5',
        'symbol': 'ETHUSD',
        'asset': 'Kripto',
        'desc': 'ETHUSD Ethereum Trend Following and Breakout EA',
        'magic': 2008,
        'risk': 0.8,
        'sl_mult': 3.0,
        'tp_mult': 5.0,
        'spread': 250
    },
    {
        'file': 'Astra_USOIL_Industrial.mq5',
        'symbol': 'USOIL',
        'asset': 'Komoditas Energi (WTI)',
        'desc': 'USOIL WTI Crude Oil Range Breakout EA',
        'magic': 2009,
        'risk': 1.0,
        'sl_mult': 2.2,
        'tp_mult': 3.8,
        'spread': 40
    },
    {
        'file': 'Astra_UKOIL_Industrial.mq5',
        'symbol': 'UKOIL',
        'asset': 'Komoditas Energi (Brent)',
        'desc': 'UKOIL Brent Crude Oil Trend Momentum EA',
        'magic': 2010,
        'risk': 1.0,
        'sl_mult': 2.2,
        'tp_mult': 3.8,
        'spread': 40
    }
]

template = '''//+------------------------------------------------------------------+
//|                                  {file}
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"
#property description "{desc}"
#property description "Sains Manajemen Project 2 - Broker Exness 7-Year Backtest."
#property description "Anti-Martingale, Anti-Grid, Anti-HFT, NO Leverage."

#include <Trade/Trade.mqh>
#include "..\\Include\\AstraInstrumentProfile.mqh"
#include "..\\Include\\AstraRiskManager.mqh"
#include "..\\Include\\AstraSignalEngine.mqh"

//+------------------------------------------------------------------+
//| Input Parameter Teroptimasi untuk {symbol} ({asset})
//+------------------------------------------------------------------+
input group "=== Risk and Money Management ==="
input double           InpRiskPercent         = {risk};          // Alokasi Risiko (% Ekuitas)
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
input double           InpAtrSlMult           = {sl_mult};          // Pengali ATR untuk Stop Loss
input double           InpAtrTpMult           = {tp_mult};          // Pengali ATR untuk Take Profit

input group "=== Execution and Broker ==="
input int              InpMagicNumber         = {magic};         // Magic Number Unik
input int              InpSlippage            = 30;           // Toleransi Slippage (Points)
input int              InpMaxSpread           = {spread};           // Batas Maksimum Spread (Points)

CAstraRiskManager      g_riskManager;
CAstraSignalEngine     g_signalEngine;

int OnInit()
  {{
   if(!CAstraRiskManager::IsAccountAllowed(InpAllowReal))
      return INIT_FAILED;

   if(!g_riskManager.Init(_Symbol, InpMagicNumber, InpSlippage, InpMaxDrawdownLimit))
      return INIT_FAILED;

   if(!g_signalEngine.Init(_Symbol, _Period, InpTrendEmaPeriod, InpFastEmaPeriod, InpRsiPeriod, InpAtrPeriod))
      return INIT_FAILED;

   PrintFormat("[Astra_%s] Inisialisasi Berhasil. Magic: %d | Risk: %.1f%% | Anti-Leverage Mode",
               "{symbol}", InpMagicNumber, InpRiskPercent);
   return INIT_SUCCEEDED;
  }}

void OnDeinit(const int reason)
  {{
   g_signalEngine.ReleaseIndicators();
  }}

void OnTick()
  {{
   if(InpUseTrailingStop)
     {{
      double atr = g_signalEngine.GetCurrentATR();
      if(atr > 0.0)
         g_riskManager.ManageTrailingStop(InpMagicNumber, atr * InpTrailingAtrMult);
     }}

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
     {{
      if(activeCount > 0)
        {{
         if(activeType == POSITION_TYPE_SELL)
            g_riskManager.CloseAllPositions(InpMagicNumber);
         else
            return;
        }}

      double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slPrice  = askPrice - (atr * InpAtrSlMult);
      double tpPrice  = askPrice + (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, askPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_BUY, lotSize, slPrice, tpPrice, "Astra_{symbol}_BUY");
     }}
   else if(signal == SIGNAL_SELL)
     {{
      if(activeCount > 0)
        {{
         if(activeType == POSITION_TYPE_BUY)
            g_riskManager.CloseAllPositions(InpMagicNumber);
         else
            return;
        }}

      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slPrice  = bidPrice + (atr * InpAtrSlMult);
      double tpPrice  = bidPrice - (atr * InpAtrTpMult);
      double lotSize  = g_riskManager.CalculateUnleveragedLot(InpRiskPercent, slPoints, bidPrice);

      g_riskManager.ExecuteMarketOrder(ORDER_TYPE_SELL, lotSize, slPrice, tpPrice, "Astra_{symbol}_SELL");
     }}
  }}
//+------------------------------------------------------------------+
'''

os.makedirs(os.path.join('MQL5', 'Experts'), exist_ok=True)
for item in instruments:
    content = template.format(**item)
    path = os.path.join('MQL5', 'Experts', item['file'])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Generated: {item["file"]}')
print('All 10 instrument EAs generated successfully!')
