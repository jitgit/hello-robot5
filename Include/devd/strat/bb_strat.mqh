#property strict

#include <devd/acc/AccountManager.mqh>
#include <devd/acc/RiskManager.mqh>
#include <devd/account-utils.mqh>
#include <devd/common.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/OrderOptimizer.mqh>
#include <devd/signal/bb/BBSignalScanner.mqh>

input int MAX_ORDER_THREADHOLD = 1;
input double BB_SD_ENTRY = 2;
input double BB_SD_STOPLOSS = 6;
input double BB_SD_TAKEPROFIT = 1;
input int BB_PERIOD = 50;

input int RSI_PERIOD = 14;
input int RSI_UPPER_BOUND = 60;
input int RSI_LOWER_BOUND = 40;

void main() {
    SignalScanner *scanner = new BBSignalScanner(BB_SD_ENTRY, BB_SD_STOPLOSS, BB_SD_TAKEPROFIT, BB_PERIOD, RSI_PERIOD, RSI_UPPER_BOUND, RSI_LOWER_BOUND);
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

        SignalResult scan = scanner.scan();
        debug("Scan Result: " + scan.str());

        if (scan.go == GO_LONG || scan.go == GO_SHORT) {
            debug("Booking order: " + scan.str());
            bool isLong = scan.go == GO_LONG;
            double optimalLotSize = riskManager.optimalLotSize(scan.stopLoss, scan.takeProfit);
            orderManager.bookTrade(isLong, scan.entry, scan.stopLoss, scan.takeProfit, optimalLotSize, scanner.magicNumber());
        } else {
            debug("NO SIGNAL FROM SCAN RESULT");
        }
    }
    //Optimize TP on existing trades if any by this EA
    ordeOptimizer.optimizeTakeProfit(scanner.magicNumber(), orderIds, scanner.optimizedLongTP(), scanner.optimizedShortTP());

    delete scanner;
    scanner = NULL;
    delete orderManager;
    orderManager = NULL;
    delete accountManager;
    accountManager = NULL;
    delete riskManager;
    riskManager = NULL;
}