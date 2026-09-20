//+------------------------------------------------------------------+
//|                                          AstraRiskManager.mqh    |
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"

#include <Trade/Trade.mqh>
#include "AstraInstrumentProfile.mqh"

//+------------------------------------------------------------------+
//| Kelas Manajemen Risiko Institusional (Anti-Martingale/Grid/HFT)  |
//+------------------------------------------------------------------+
class CAstraRiskManager
  {
private:
   string            m_symbol;
   CTrade            m_trade;
   InstrumentSpec    m_spec;
   double            m_initialBalance;
   double            m_peakEquity;
   double            m_maxDrawdownPct;
   bool              m_circuitBreakerTriggered;

public:
   // Konstruktor
   CAstraRiskManager()
     {
      m_symbol                 = _Symbol;
      m_initialBalance         = 0.0;
      m_peakEquity             = 0.0;
      m_maxDrawdownPct         = 25.0; // Batas maksimal drawdown 25-30%
      m_circuitBreakerTriggered= false;
     }

   // Inisialisasi pengelola risiko
   bool Init(const string sym, const int magicNumber, const int slippage, const double maxDDPct = 25.0)
     {
      m_symbol         = sym;
      m_spec           = CAstraInstrumentProfile::GetSpec(sym);
      m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_peakEquity     = AccountInfoDouble(ACCOUNT_EQUITY);
      m_maxDrawdownPct = maxDDPct;
      m_circuitBreakerTriggered = false;

      m_trade.SetExpertMagicNumber(magicNumber);
      m_trade.SetDeviationInPoints(slippage);

      PrintFormat("[AstraRiskManager] Initialized for %s (%s). Max DD Allowed: %.1f%%. NO LEVERAGE MODEL ACTIVE.",
                  m_symbol, m_spec.description, m_maxDrawdownPct);
      return true;
     }

   // Verifikasi Keamanan Akun Real (Proteksi dari Project 1 dipertahankan)
   static bool IsAccountAllowed(const bool allowReal)
     {
      ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
      if(mode == ACCOUNT_TRADE_MODE_REAL && !allowReal)
        {
         Print("PERINGATAN KRITIS: EA dicegah berjalan di akun REAL karena InpAllowReal = false.");
         Print("Ubah InpAllowReal = true jika Anda benar-benar memahami seluruh risiko eksekusi.");
         return false;
        }
      return true;
     }

   // Memeriksa Drawdown Circuit Breaker
   bool CheckDrawdownLimit()
     {
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(currentEquity > m_peakEquity)
         m_peakEquity = currentEquity;

      if(m_peakEquity > 0.0)
        {
         double currentDD = (m_peakEquity - currentEquity) / m_peakEquity * 100.0;
         if(currentDD >= m_maxDrawdownPct)
           {
            if(!m_circuitBreakerTriggered)
              {
               PrintFormat("[CIRCUIT BREAKER] Ekuitas turun %.2f%% melampaui batas toleransi %.2f%%. Seluruh order baru dihentikan!",
                           currentDD, m_maxDrawdownPct);
               m_circuitBreakerTriggered = true;
              }
            return false;
           }
        }
      return true;
     }

   // Menghitung Ukuran Lot Tanpa Leverage (NO LEVERAGE / 1:1 Cash Equivalent)
   // Menjamin nilai nosional total tidak melebihi alokasi kas ekuitas
   double CalculateUnleveragedLot(const double riskPercent, const double stopLossPoints, const double entryPrice)
     {
      if(stopLossPoints <= 0.0 || entryPrice <= 0.0)
         return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);

      double equity       = AccountInfoDouble(ACCOUNT_EQUITY);
      double tickValue    = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize     = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double point        = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);

      if(tickValue <= 0.0 || tickSize <= 0.0 || point <= 0.0 || contractSize <= 0.0)
         return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);

      // 1. Alokasi risiko kas (Cash Risk Parity):
      // CashAtRisk = Equity * (RiskPercent / 100.0)
      double cashAtRisk = equity * (riskPercent / 100.0);
      double pointValuePerLot = (tickValue / tickSize) * point;
      double riskLot = cashAtRisk / (stopLossPoints * pointValuePerLot);

      // 2. Pembatasan Nosional Tanpa Leverage (NO LEVERAGE CONSTRAINT):
      // Notional Value = Lot * ContractSize * EntryPrice <= Equity * MaxAllocationRatio
      // Di sini alokasi maksimal untuk 1 instrumen dalam portofolio 10 aset adalah 10% (1/10 kas) s.d 15%
      double maxInstrumentNotional = equity * 0.15; // Maks 15% dari ekuitas untuk 1 aset (Total 10 aset <= 100% unleveraged)
      double unleveragedMaxLot     = maxInstrumentNotional / (contractSize * entryPrice);

      // Ambil nilai terendah antara risk-based lot dan unleveraged-based lot
      double calculatedLot = MathMin(riskLot, unleveragedMaxLot);

      // Normalisasi sesuai batasan volume broker
      double minLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double stepLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

      if(stepLot > 0.0)
         calculatedLot = MathFloor(calculatedLot / stepLot) * stepLot;

      if(calculatedLot < minLot)
         calculatedLot = minLot;
      if(calculatedLot > maxLot)
         calculatedLot = maxLot;

      return NormalizeDouble(calculatedLot, 2);
     }

   // Memeriksa Kondisi Spread
   bool IsSpreadAcceptable(const int maxSpreadLimit)
     {
      long spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      return (spread <= maxSpreadLimit);
     }

   // Menghitung Jumlah Posisi Aktif untuk Simbol & Magic Ini
   // MEMASTIKAN NO GRID / NO MARTINGALE: Maksimal HANYA 1 posisi terbuka
   int CountActivePositions(const int magicNumber)
     {
      int count = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
           {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == magicNumber)
              {
               count++;
              }
           }
        }
      return count;
     }

   // Mendapatkan Tipe Posisi Terbuka
   ENUM_POSITION_TYPE GetActivePositionType(const int magicNumber)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
           {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == magicNumber)
              {
               return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
              }
           }
        }
      return (ENUM_POSITION_TYPE)-1;
     }

   // Menutup Seluruh Posisi Simbol Ini
   bool CloseAllPositions(const int magicNumber)
     {
      bool allClosed = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
           {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == magicNumber)
              {
               if(!m_trade.PositionClose(ticket))
                  allClosed = false;
              }
           }
        }
      return allClosed;
     }

   // Eksekusi Buka Posisi Terencana dengan SL dan TP terpasang sejak awal
   bool ExecuteMarketOrder(const ENUM_ORDER_TYPE orderType,
                           const double lotSize,
                           const double slPrice,
                           const double tpPrice,
                           const string comment = "AstraIndustrial")
     {
      if(!CheckDrawdownLimit())
         return false;

      double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK)
                                                   : SymbolInfoDouble(m_symbol, SYMBOL_BID);

      bool result = false;
      if(orderType == ORDER_TYPE_BUY)
         result = m_trade.Buy(lotSize, m_symbol, price, slPrice, tpPrice, comment);
      else if(orderType == ORDER_TYPE_SELL)
         result = m_trade.Sell(lotSize, m_symbol, price, slPrice, tpPrice, comment);

      if(!result)
        {
         PrintFormat("[AstraRiskManager] Order Execution Failed: %s Error Code: %d",
                     m_symbol, GetLastError());
        }
      return result;
     }

   // Trailing Stop Dinamis Berbasis ATR untuk Mengunci Keuntungan
   void ManageTrailingStop(const int magicNumber, const double trailingAtrDistance)
     {
      if(trailingAtrDistance <= 0.0)
         return;

      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      int digits   = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
           {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == magicNumber)
              {
               ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               double currentOpen = PositionGetDouble(POSITION_PRICE_OPEN);
               double currentSL   = PositionGetDouble(POSITION_SL);
               double currentTP   = PositionGetDouble(POSITION_TP);

               if(posType == POSITION_TYPE_BUY)
                 {
                  double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
                  double proposedSL = currentBid - trailingAtrDistance;

                  // Hanya geser SL ke atas jika harga bergerak cukup jauh melampaui entry
                  if(proposedSL > currentOpen && (currentSL == 0.0 || proposedSL > currentSL + 10 * point))
                    {
                     m_trade.PositionModify(ticket, NormalizeDouble(proposedSL, digits), currentTP);
                    }
                 }
               else if(posType == POSITION_TYPE_SELL)
                 {
                  double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
                  double proposedSL = currentAsk + trailingAtrDistance;

                  // Hanya geser SL ke bawah jika harga bergerak cukup jauh melampaui entry
                  if(proposedSL < currentOpen && (currentSL == 0.0 || proposedSL < currentSL - 10 * point))
                    {
                     m_trade.PositionModify(ticket, NormalizeDouble(proposedSL, digits), currentTP);
                    }
                 }
              }
           }
        }
     }
  };
//+------------------------------------------------------------------+
