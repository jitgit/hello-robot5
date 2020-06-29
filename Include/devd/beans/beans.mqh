//+------------------------------------------------------------------+
//|                                                      default.mql |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"

#include <Object.mqh>

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
        return StringFormat("Signal %s - (GO: %d, entryPrice: %f, stopLoss(%d): %f, takeProfit(%d): %f)", symbol, go, entry, SL, stopLoss, TP, takeProfit);
    }
};

string EMPLOYMENT_CHANGE = "EMPLOYMENT_CHANGE";
string IR = "IR";
string CPI = "CPI";

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
