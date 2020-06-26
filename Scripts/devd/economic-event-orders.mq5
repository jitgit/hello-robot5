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
#include <devd/price/EconomicEventPricer.mqh>

void OnStart() {
    EconomicEventPricer *newsPricer = new EconomicEventPricer();
    OrderManager *orderManager = new OrderManager();
    RiskManager riskManager = new RiskManager();

    Print("========================= BUY ORDER =========================");

    SignalResult longSignal = {GO_LONG, -1.0, -1.0, -1.0};
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(longSignal, 12);
    //Calculating Lot Size
    double longLotSize = riskManager.optimalLotSizeFrom(longSignal, 2.0);
    //Try to book the order without SL & TP
    orderManager.bookStopOrder(longSignal, longLotSize, 0007);  //We don't want SL or TP

    Print("========================= SELL ORDER =========================");

    SignalResult shortSignal = {GO_SHORT, -1.0, -1.0, -1.0};
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(shortSignal, 12);
    //Calculating Lot Size
    double shortLotSize = riskManager.optimalLotSizeFrom(shortSignal, 2.0);
    //Try to book the order without SL & TP
    orderManager.bookStopOrder(shortSignal, shortLotSize, 0007);  //We don't want SL or TP
}
