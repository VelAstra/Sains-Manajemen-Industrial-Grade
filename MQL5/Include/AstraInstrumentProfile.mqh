//+------------------------------------------------------------------+
//|                                     AstraInstrumentProfile.mqh   |
//|                 Sains Manajemen - Industrial Grade Multi-Asset   |
//|               Rayhan Haldi Hermawan (NIM: 24/545406/PA/23176)    |
//|                 Departemen Ilmu Komputer dan Elektronika, FMIPA  |
//|                            Universitas Gadjah Mada (UGM) 2026    |
//+------------------------------------------------------------------+
#property copyright "Rayhan Haldi Hermawan - UGM 2026"
#property link      "https://github.com/VelAstra/Sains-Manajemen-Industrial-Grade"
#property version   "2.00"

//+------------------------------------------------------------------+
//| Enum Klasifikasi Kelas Aset                                      |
//+------------------------------------------------------------------+
enum ENUM_ASSET_CLASS
  {
   ASSET_FOREX,    // Mata Uang (Forex)
   ASSET_METAL,    // Logam Mulia (Precious Metals)
   ASSET_INDEX,    // Indeks Saham Global (Equity Indices)
   ASSET_CRYPTO,   // Aset Kripto (Cryptocurrency)
   ASSET_ENERGY    // Komoditas Energi (Energy)
  };

//+------------------------------------------------------------------+
//| Struktur Profil Spesifikasi Instrumen pada Broker Exness         |
//+------------------------------------------------------------------+
struct InstrumentSpec
  {
   string            symbolName;       // Nama simbol standar
   ENUM_ASSET_CLASS  assetClass;       // Kelas aset
   string            description;      // Deskripsi instrumen
   double            contractSize;     // Ukuran kontrak standar Exness
   int               digits;           // Jumlah desimal
   int               maxSpreadPoints;  // Batas toleransi spread (points)
   double            defaultRiskPct;   // Alokasi risiko per trade (% ekuitas)
   double            atrSlMultiplier;  // Pengali ATR untuk Stop Loss
   double            atrTpMultiplier;  // Pengali ATR untuk Take Profit
   int               emaFilterPeriod;  // Periode EMA Trend Filter
   int               rsiPeriod;        // Periode RSI Momentum
   int               atrPeriod;        // Periode ATR Volatilitas
  };

//+------------------------------------------------------------------+
//| Class Pengelola Profil 10 Instrumen                              |
//+------------------------------------------------------------------+
class CAstraInstrumentProfile
  {
public:
   // Mendapatkan spesifikasi instrumen berdasarkan nama simbol
   static InstrumentSpec GetSpec(const string sym)
     {
      InstrumentSpec spec;
      string s = sym;
      StringToUpper(s);

      // 1. Forex: EURUSD
      if(StringFind(s, "EURUSD") >= 0)
        {
         spec.symbolName       = "EURUSD";
         spec.assetClass       = ASSET_FOREX;
         spec.description      = "Euro vs US Dollar (Major Forex)";
         spec.contractSize     = 100000.0;
         spec.digits           = 5;
         spec.maxSpreadPoints  = 25;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.0;
         spec.atrTpMultiplier  = 3.5;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 2. Forex: USDJPY
      if(StringFind(s, "USDJPY") >= 0)
        {
         spec.symbolName       = "USDJPY";
         spec.assetClass       = ASSET_FOREX;
         spec.description      = "US Dollar vs Japanese Yen (Macro Carry)";
         spec.contractSize     = 100000.0;
         spec.digits           = 3;
         spec.maxSpreadPoints  = 25;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.0;
         spec.atrTpMultiplier  = 3.5;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 3. Logam: XAUUSD (Gold)
      if(StringFind(s, "XAUUSD") >= 0 || StringFind(s, "GOLD") >= 0)
        {
         spec.symbolName       = "XAUUSD";
         spec.assetClass       = ASSET_METAL;
         spec.description      = "Gold vs US Dollar (Precious Metal Safe-Haven)";
         spec.contractSize     = 100.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 40;
         spec.defaultRiskPct   = 1.2;
         spec.atrSlMultiplier  = 2.5;
         spec.atrTpMultiplier  = 4.5;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 4. Logam: XAGUSD (Silver)
      if(StringFind(s, "XAGUSD") >= 0 || StringFind(s, "SILVER") >= 0)
        {
         spec.symbolName       = "XAGUSD";
         spec.assetClass       = ASSET_METAL;
         spec.description      = "Silver vs US Dollar (High Beta Metal)";
         spec.contractSize     = 5000.0;
         spec.digits           = 3;
         spec.maxSpreadPoints  = 45;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.5;
         spec.atrTpMultiplier  = 4.0;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 5. Index: US30 / DJ30
      if(StringFind(s, "US30") >= 0 || StringFind(s, "DJ30") >= 0 || StringFind(s, "WALLSTREET") >= 0)
        {
         spec.symbolName       = "US30";
         spec.assetClass       = ASSET_INDEX;
         spec.description      = "Dow Jones Industrial Average (US Equity)";
         spec.contractSize     = 1.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 150;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.2;
         spec.atrTpMultiplier  = 4.0;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 6. Index: JP225 / NIKKEI
      if(StringFind(s, "JP225") >= 0 || StringFind(s, "NIKKEI") >= 0)
        {
         spec.symbolName       = "JP225";
         spec.assetClass       = ASSET_INDEX;
         spec.description      = "Nikkei 225 Index (Asian Session Equity)";
         spec.contractSize     = 100.0;
         spec.digits           = 0;
         spec.maxSpreadPoints  = 180;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.2;
         spec.atrTpMultiplier  = 4.0;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 7. Crypto: BTCUSD
      if(StringFind(s, "BTCUSD") >= 0 || StringFind(s, "BTC") >= 0)
        {
         spec.symbolName       = "BTCUSD";
         spec.assetClass       = ASSET_CRYPTO;
         spec.description      = "Bitcoin vs US Dollar (Macro Digital Asset)";
         spec.contractSize     = 1.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 300;
         spec.defaultRiskPct   = 0.8; // Ukuran risiko lebih konservatif karena volatilitas tinggi
         spec.atrSlMultiplier  = 3.0;
         spec.atrTpMultiplier  = 5.5;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 8. Crypto: ETHUSD
      if(StringFind(s, "ETHUSD") >= 0 || StringFind(s, "ETH") >= 0)
        {
         spec.symbolName       = "ETHUSD";
         spec.assetClass       = ASSET_CRYPTO;
         spec.description      = "Ethereum vs US Dollar (Smart Contract Asset)";
         spec.contractSize     = 1.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 250;
         spec.defaultRiskPct   = 0.8;
         spec.atrSlMultiplier  = 3.0;
         spec.atrTpMultiplier  = 5.0;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 9. Energy: USOIL (WTI Crude Oil)
      if(StringFind(s, "USOIL") >= 0 || StringFind(s, "WTI") >= 0 || StringFind(s, "CRUDE") >= 0)
        {
         spec.symbolName       = "USOIL";
         spec.assetClass       = ASSET_ENERGY;
         spec.description      = "WTI Light Sweet Crude Oil";
         spec.contractSize     = 1000.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 40;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.2;
         spec.atrTpMultiplier  = 3.8;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // 10. Energy: UKOIL (Brent Crude Oil)
      if(StringFind(s, "UKOIL") >= 0 || StringFind(s, "BRENT") >= 0)
        {
         spec.symbolName       = "UKOIL";
         spec.assetClass       = ASSET_ENERGY;
         spec.description      = "Brent Crude Oil (Global Energy Benchmark)";
         spec.contractSize     = 1000.0;
         spec.digits           = 2;
         spec.maxSpreadPoints  = 40;
         spec.defaultRiskPct   = 1.0;
         spec.atrSlMultiplier  = 2.2;
         spec.atrTpMultiplier  = 3.8;
         spec.emaFilterPeriod  = 200;
         spec.rsiPeriod        = 14;
         spec.atrPeriod        = 14;
         return spec;
        }

      // Default fallback (Generic Spec)
      spec.symbolName       = sym;
      spec.assetClass       = ASSET_FOREX;
      spec.description      = "Generic Financial Instrument";
      spec.contractSize     = 100000.0;
      spec.digits           = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      spec.maxSpreadPoints  = 50;
      spec.defaultRiskPct   = 1.0;
      spec.atrSlMultiplier  = 2.0;
      spec.atrTpMultiplier  = 3.5;
      spec.emaFilterPeriod  = 200;
      spec.rsiPeriod        = 14;
      spec.atrPeriod        = 14;
      return spec;
     }
  };
//+------------------------------------------------------------------+
