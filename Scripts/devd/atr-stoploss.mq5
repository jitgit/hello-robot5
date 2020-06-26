//+------------------------------------------------------------------+
//|                                                     devd-rci.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"

#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>

void OnStart() {
    ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
    OrderManager *orderManager = new OrderManager();
    RiskManager riskManager = new RiskManager();
    SignalResult signal = {GO_LONG, -1.0, -1.0, -1.0};

    Print("=========================");

    //Calculating entry, SL,TP
    stopLoss.addEntryStopLossAndTakeProfit(signal);

    //Calculating Lot Size
    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);

    //Try to book the order
    bool success = orderManager.bookLimitOrder(signal, optimalLotSize, 0007);

    Print("============optimalLotSize: ", optimalLotSize);
}
