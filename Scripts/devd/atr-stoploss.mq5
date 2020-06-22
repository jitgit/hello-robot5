//+------------------------------------------------------------------+
//|                                                     devd-rci.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"

#include <devd/include-base.mqh>
#include <devd/acc/AtrStopLoss.mqh>
#include <devd/acc/RiskManager.mqh>


void OnStart() {
    AtrStopLoss *stopLoss = new AtrStopLoss(14);
    SignalResult r = {GO_LONG, -1.0, -1.0, -1.0};
    stopLoss.addEntryStopLossAndTakeProfit(r);
    Print("=========================");
    r.go = GO_SHORT;
    stopLoss.addEntryStopLossAndTakeProfit(r);
    
    RiskManager riskManager = new RiskManager();
    double optimalLotSize = riskManager.optimalLotSizeFrom(r,2.0);
    
    Print("============optimalLotSize: ",optimalLotSize);
}
