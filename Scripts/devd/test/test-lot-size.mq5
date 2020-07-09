#property strict

#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>

void OnStart() {
    ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
    RiskManager riskManager = new RiskManager();
    SignalResult *signal = new SignalResult(_Symbol, GO_LONG);
    SymbolData *s = new SymbolData(_Symbol);
    Print("=========================");

    //Calculating entry, SL,TP
    stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);

    //Calculating Lot Size
    double optimalLotSize = riskManager.lotSize(s, signal, _Period);

    Print("============optimalLotSize: ", optimalLotSize);
}