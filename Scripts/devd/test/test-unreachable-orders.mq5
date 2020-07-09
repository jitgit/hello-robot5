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
#include <devd/order/PositionOptimizer.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>

PositionOptimizer *positionOptimizer = new PositionOptimizer(50);

int OnInit() {
    ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
    OrderManager *orderManager = new OrderManager();
    RiskManager riskManager = new RiskManager();

    SignalResult *signal = new SignalResult(_Symbol, GO_LONG);

    Print("=========================");

    //Calculating entry, SL,TP
    stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);

    //Calculating Lot Size
    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);

    //Try to book the order
    bool success = orderManager.bookLimitOrder(signal, optimalLotSize, TEST_MAGIC_NUMBER);

    EventSetTimer(5);
    Print("============optimalLotSize: ", optimalLotSize);
    return 0;
}

void OnTimer() {
    Print("OnTimer : ");
    SymbolData *s = new SymbolData(_Symbol);
    positionOptimizer.closeUnreachablePendingOrders(ORDER_TYPE_BUY_LIMIT, s, TEST_MAGIC_NUMBER, 5);
    EventKillTimer();
}
