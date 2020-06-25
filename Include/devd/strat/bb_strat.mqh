#property strict

#include <devd/acc/AccountManager.mqh>
#include <devd/acc/RiskManager.mqh>
#include <devd/account-utils.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/TradeOptimizer.mqh>
#include <devd/signal/bb/BBSignalScanner.mqh>

input int MAX_ORDER_THREADHOLD = 1;
input int MAX_RISK_PERCENTAGE = 2;
input double BB_SD_ENTRY = 2;
input double BB_SD_STOPLOSS = 6;
input double BB_SD_TAKEPROFIT = 1;
input int BB_PERIOD = 50;

input int RSI_PERIOD = 14;
input int RSI_UPPER_BOUND = 60;
input int RSI_LOWER_BOUND = 40;

void main() {
    int SL = 100;
    int TP = 2 * 100;

    /*SignalScanner *scanner = new BBSignalScanner(BB_SD_ENTRY, BB_SD_STOPLOSS, BB_SD_TAKEPROFIT, BB_PERIOD, RSI_PERIOD, RSI_UPPER_BOUND, RSI_LOWER_BOUND);
    OrderManager *orderManager = new OrderManager();
    AccountManager *accountManager = new AccountManager();
    RiskManager *riskManager = new RiskManager();
    OrderOptimizer *ordeOptimizer = new OrderOptimizer();
    long orderIds[];
    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(scanner.magicNumber(), orderIds);
    debug(StringFormat("Magic Number(%d), MaxOrder(%d), Exiting(%d)", scanner.magicNumber(), MAX_ORDER_THREADHOLD, anyExistingOrders));

    if (anyExistingOrders >= MAX_ORDER_THREADHOLD) {
        debug("MAX ORDER THREASHOLD REACHED. Optimizing the order ...");
        return;
    } else {
        accountManager.printAccountInfo();
        PrintCurrencyInfo();

        SignalResult signal = scanner.scan();
        debug(signal.str());

        if (signal.go == GO_LONG || signal.go == GO_SHORT) {
            debug("Booking order: " + signal.str());
            bool isLong = signal.go == GO_LONG;
            double optimalLotSize = riskManager.optimalLotSize(isLong,SL,TP, MAX_RISK_PERCENTAGE);
            orderManager.bookTrade(isLong, signal.entry, signal.stopLoss, signal.takeProfit, optimalLotSize, scanner.magicNumber());
        } else {
            debug("NO SIGNAL FROM SCAN RESULT");
        }
    }
    //Optimize TP on existing trades if any by this EA
    ordeOptimizer.optimizeTakeProfit(scanner.magicNumber(), orderIds, scanner.optimizedLongTP(), scanner.optimizedShortTP());   */
}