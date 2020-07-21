#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>

void OnStart() {
    ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
    OrderManager *orderManager = new OrderManager();
RiskManager* riskManager = new RiskManager();
    SignalResult *signal = new SignalResult(_Symbol, GO_LONG);

    Print("=========================");

    //Calculating entry, SL,TP
    stopLoss.addEntryStopLossAndTakeProfit(signal,_Period);

    //Calculating Lot Size
    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);

    //Try to book the order
    bool success = orderManager.bookMarketOrder(signal, optimalLotSize, 0007);

    Print("============optimalLotSize: ", optimalLotSize);
}