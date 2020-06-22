//+------------------------------------------------------------------+
//|                                                      default.mql |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"

enum GO {
    GO_NOTHING,
    GO_LONG,
    GO_SHORT
};

struct SignalResult {
    GO go;
    double entry;
    double stopLoss;
    double takeProfit;
    int SL;
    int TP;

    string str() {
        return StringFormat("Signal - (GO: %d, entryPrice: %f, stopLoss(%d): %f, takeProfit(%d): %f)", go, entry, SL, stopLoss, TP, takeProfit);
    }
};
