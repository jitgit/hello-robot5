//+------------------------------------------------------------------+
//|                                                      default.mql |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"

#include <Object.mqh>
#include <Trade/SymbolInfo.mqh>


enum GO {
    GO_NOTHING,
    GO_LONG,
    GO_SHORT
};

class SignalResult {
   public:
    string symbol;
    GO go;
    double entry;
    double stopLoss;
    double takeProfit;
    int SL;
    int TP;

    SignalResult(string sym, GO longShort = GO_NOTHING) {
        symbol = sym;
        go = longShort;
        entry = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        SL = 0;
        TP = 0;
    }

    string str() {
        return StringFormat("%s - %s, entry(%f) stopLoss(%d): %f, takeProfit(%d): %f)", symbol, EnumToString(go), entry, SL, stopLoss, TP, takeProfit);
    }

    string str1() {
        return StringFormat("%s - %s", symbol, EnumToString(go));
    }
};



class SymbolData : public CSymbolInfo {
   public:
    //string symbol;
    double tickSize;
    double tickValue;
    int digit;
    double point;
    double ask;
    double bid;
    int spreadPips;
    double spreadValue;
    long stopLossLevel;

    SymbolData(string sym) : CSymbolInfo() {
        this.Name(sym);
        this.refreshRates();
        tickSize = this.TickSize();
        tickValue = this.TickValue();
        digit = this.Digits();
        point = this.Point();
        ask = this.Ask();
        bid = this.Bid();

        spreadPips = this.Spread();
        spreadValue = this.Ask() - this.Bid();
    }

    bool refreshRates(void) {
        if (!this.RefreshRates()) {  //--- refresh rates
            error("RefreshRates error");
            return (false);
        }

        if (this.Ask() == 0 || this.Bid() == 0)  //--- protection against the return value of "zero"
            return (false);
        //---
        return (true);
    }

    double digitAdjust() {
        int digits_adjust = 1;
        if (this.Digits() == 3 || this.Digits() == 5)
            digits_adjust = 10;
        return this.Point() * digits_adjust;
    }
    string str() {
        //StringFormat("%s Tick (Value :%f, Size :%f), stopLossLevel(%d), Point:(%f)", tickValue, tickSize, stopLossLevel, point));
        return StringFormat("%s {Ask(%f) Bid(%f) Point(%f) Digit(%d) Spread [(%d)Pips, %f]}, StopsLevel(%f)", this.Name(), ask, bid, point, digit, spreadPips, spreadValue,this.StopsLevel());
    }
};


string EMPLOYMENT_CHANGE = "EMPLOYMENT_CHANGE";
string IR = "IR";
string CPI = "CPI";
string OIL_INVENTORIES = "OIL_INVENTORIES";
string PMI = "PMI";

class EconomicEvent : public CObject {
   public:
    string name;
    int impact;
    string currency;
    string pairs[];
    datetime eventTime;
    bool isOrderExecuted;

    EconomicEvent(string n, string curr, int impct, string time) {
        name = n;
        currency = curr;
        impact = impct;
        isOrderExecuted = false;
        eventTime = StringToTime(time);
    }

    string str() {
        return StringFormat("EconomicEvent %s - %s(%d), time: %s", currency, name, impact, TimeToString(eventTime));
    }
};