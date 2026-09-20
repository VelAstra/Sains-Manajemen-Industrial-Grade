//+------------------------------------------------------------------+
//|                                           AstraSignalEngine.mqh  |
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"

//+------------------------------------------------------------------+
//| Enum Status Sinyal                                               |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE,
   SIGNAL_BUY,
   SIGNAL_SELL
  };

//+------------------------------------------------------------------+
//| Mesin Pembangkit Sinyal Multi-Faktor Adaptif Rezim (Non-HFT)     |
//+------------------------------------------------------------------+
class CAstraSignalEngine
  {
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_hTrendEMA;
   int               m_hFastEMA;
   int               m_hRSI;
   int               m_hATR;

   int               m_trendEmaPeriod;
   int               m_fastEmaPeriod;
   int               m_rsiPeriod;
   int               m_atrPeriod;

   datetime          m_lastBarTime;

public:
   CAstraSignalEngine()
     {
      m_symbol         = _Symbol;
      m_timeframe      = _Period;
      m_hTrendEMA      = INVALID_HANDLE;
      m_hFastEMA       = INVALID_HANDLE;
      m_hRSI           = INVALID_HANDLE;
      m_hATR           = INVALID_HANDLE;
      m_lastBarTime    = 0;
     }

   ~CAstraSignalEngine()
     {
      ReleaseIndicators();
     }

   // Pelepasan handle indikator
   void ReleaseIndicators()
     {
      if(m_hTrendEMA != INVALID_HANDLE) { IndicatorRelease(m_hTrendEMA); m_hTrendEMA = INVALID_HANDLE; }
      if(m_hFastEMA  != INVALID_HANDLE) { IndicatorRelease(m_hFastEMA);  m_hFastEMA  = INVALID_HANDLE; }
      if(m_hRSI      != INVALID_HANDLE) { IndicatorRelease(m_hRSI);      m_hRSI      = INVALID_HANDLE; }
      if(m_hATR      != INVALID_HANDLE) { IndicatorRelease(m_hATR);      m_hATR      = INVALID_HANDLE; }
     }

   // Inisialisasi indikator teknikal
   bool Init(const string sym,
             const ENUM_TIMEFRAMES tf,
             const int trendEma = 200,
             const int fastEma = 21,
             const int rsiPer = 14,
             const int atrPer = 14)
     {
      m_symbol         = sym;
      m_timeframe      = tf;
      m_trendEmaPeriod = trendEma;
      m_fastEmaPeriod  = fastEma;
      m_rsiPeriod      = rsiPer;
      m_atrPeriod      = atrPer;

      ReleaseIndicators();

      m_hTrendEMA = iMA(m_symbol, m_timeframe, m_trendEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_hFastEMA  = iMA(m_symbol, m_timeframe, m_fastEmaPeriod,  0, MODE_EMA, PRICE_CLOSE);
      m_hRSI      = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE);
      m_hATR      = iATR(m_symbol, m_timeframe, m_atrPeriod);

      if(m_hTrendEMA == INVALID_HANDLE || m_hFastEMA == INVALID_HANDLE ||
         m_hRSI == INVALID_HANDLE || m_hATR == INVALID_HANDLE)
        {
         PrintFormat("[AstraSignalEngine] Gagal menginisialisasi indikator untuk %s", m_symbol);
         return false;
        }

      PrintFormat("[AstraSignalEngine] Initialized for %s on TF %s. Trend EMA: %d, Fast EMA: %d, RSI: %d, ATR: %d",
                  m_symbol, EnumToString(m_timeframe), m_trendEmaPeriod, m_fastEmaPeriod, m_rsiPeriod, m_atrPeriod);
      return true;
     }

   // Deteksi Bar Baru: Anti-HFT, menjamin eksekusi HANYA terjadi pada pembukaan bar baru
   bool IsNewBar()
     {
      datetime t = iTime(m_symbol, m_timeframe, 0);
      if(t != m_lastBarTime)
        {
         m_lastBarTime = t;
         return true;
        }
      return false;
     }

   // Mengambil nilai ATR terbaru (bar 1 yang telah selesai)
   double GetCurrentATR()
     {
      double atrVal[];
      ArraySetAsSeries(atrVal, true);
      if(CopyBuffer(m_hATR, 0, 1, 1, atrVal) < 1)
         return 0.0;
      return atrVal[0];
     }

   // Evaluasi Sinyal Strategi Multi-Faktor (Trend + Pullback + Momentum)
   ENUM_SIGNAL_TYPE EvaluateSignal(const double rsiLowerThreshold = 42.0,
                                   const double rsiUpperThreshold = 58.0)
     {
      // Ambil data harga bar yang sudah selesai (bar 1 dan bar 2)
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_timeframe, 1, 3, rates) < 3)
         return SIGNAL_NONE;

      double trendEmaVal[], fastEmaVal[], rsiVal[];
      ArraySetAsSeries(trendEmaVal, true);
      ArraySetAsSeries(fastEmaVal,  true);
      ArraySetAsSeries(rsiVal,      true);

      if(CopyBuffer(m_hTrendEMA, 0, 1, 3, trendEmaVal) < 3) return SIGNAL_NONE;
      if(CopyBuffer(m_hFastEMA,  0, 1, 3, fastEmaVal)  < 3) return SIGNAL_NONE;
      if(CopyBuffer(m_hRSI,      0, 1, 3, rsiVal)      < 3) return SIGNAL_NONE;

      double closePrev = rates[1].close; // Bar 2
      double closeCurr = rates[0].close; // Bar 1 (bar yang baru selesai)
      double lowCurr   = rates[0].low;
      double highCurr  = rates[0].high;

      double trendEma  = trendEmaVal[0];
      double fastEma   = fastEmaVal[0];
      double rsiCurr   = rsiVal[0];
      double rsiPrev   = rsiVal[1];

      // 1. KONDISI BUY (BULLISH TREND REGIME + PULLBACK MOMENTUM EXPANSION):
      // - Harga di atas Trend EMA (Bullish Macro Regime)
      // - Fast EMA > Trend EMA (Positif Slope)
      // - Bar sebelumnya melakukan pullback mendekati Fast EMA
      // - Bar 1 ditutup di atas Fast EMA dan RSI keluar dari zona pullback (> 42 dan naik)
      bool isBullishRegime = (closeCurr > trendEma) && (fastEma > trendEma);
      bool isBuyPullback   = (lowCurr <= fastEma * 1.002) && (closeCurr > fastEma);
      bool isBuyMomentum   = (rsiCurr > rsiLowerThreshold) && (rsiCurr > rsiPrev) && (rsiCurr < 72.0);

      if(isBullishRegime && isBuyPullback && isBuyMomentum)
        {
         return SIGNAL_BUY;
        }

      // 2. KONDISI SELL (BEARISH TREND REGIME + PULLBACK MOMENTUM EXPANSION):
      // - Harga di bawah Trend EMA (Bearish Macro Regime)
      // - Fast EMA < Trend EMA (Negatif Slope)
      // - Bar sebelumnya melakukan rally/pullback mendekati Fast EMA
      // - Bar 1 ditutup di bawah Fast EMA dan RSI keluar dari zona rally (< 58 dan turun)
      bool isBearishRegime = (closeCurr < trendEma) && (fastEma < trendEma);
      bool isSellPullback  = (highCurr >= fastEma * 0.998) && (closeCurr < fastEma);
      bool isSellMomentum  = (rsiCurr < rsiUpperThreshold) && (rsiCurr < rsiPrev) && (rsiCurr > 28.0);

      if(isBearishRegime && isSellPullback && isSellMomentum)
        {
         return SIGNAL_SELL;
        }

      return SIGNAL_NONE;
     }
  };
//+------------------------------------------------------------------+
