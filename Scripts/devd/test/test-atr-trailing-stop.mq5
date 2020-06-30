#property strict

#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>
#include <devd/trailingsl/ATRTrailingStop.mqh>

int MAGIC_NUMBER = 008;

TrailingStop *tralingStop = new ATRTrailingStop();

int OnInit() {
    ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
    OrderManager *orderManager = new OrderManager();
    RiskManager riskManager = new RiskManager();
    SignalResult *signal = new SignalResult("EURUSD", GO_LONG);

    Print("=========================");

    //Calculating entry, SL,TP
    stopLoss.addEntryStopLossAndTakeProfit(signal);

    //Calculating Lot Size
    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);

    //Try to book the order
    bool success = orderManager.bookMarketOrder(signal, optimalLotSize, MAGIC_NUMBER);

    Print("============optimalLotSize: ", optimalLotSize);
    EventSetTimer(5);
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    EventKillTimer();
}

void OnTimer() {
    tralingStop.updateTrailingStop(MAGIC_NUMBER, PERIOD_CURRENT);
}
