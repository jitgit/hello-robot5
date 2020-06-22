#property strict

#include <devd/acc/AccountManager.mqh>
#include <devd/acc/AtrStopLoss.mqh>
#include <devd/acc/RiskManager.mqh>
#include <devd/account-utils.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/OrderOptimizer.mqh>
#include <devd/signal/rsi/RsiScanner.mqh>

input int MAX_ORDER_THREADHOLD = 1;
input int MAX_RISK_PERCENTAGE = 2;
input double BB_SD_ENTRY = 2;
input double BB_SD_STOPLOSS = 6;
input double BB_SD_TAKEPROFIT = 1;
input int BB_PERIOD = 50;

input int RSI_PERIOD = 14;
input int RSI_UPPER_BOUND = 70;
input int RSI_LOWER_BOUND = 30;

void main() {
    int SL = 100;
    int TP = 2 * 100;

    SignalScanner *scanner = new RsiScanner(RSI_PERIOD, RSI_UPPER_BOUND, RSI_LOWER_BOUND);

    OrderManager *orderManager = new OrderManager();
    AccountManager *accountManager = new AccountManager();
    RiskManager *riskManager = new RiskManager();
    OrderOptimizer *orderOptimizer = new OrderOptimizer();  //TODO Pass the correct parameter
    AtrStopLoss *stopLoss = new AtrStopLoss(14);
    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(scanner.magicNumber());
    debug(StringFormat("Magic Number(%d), MaxOrder(%d), Exiting(%d)", scanner.magicNumber(), MAX_ORDER_THREADHOLD, anyExistingOrders));

    if (anyExistingOrders >= MAX_ORDER_THREADHOLD) {
        debug("MAX ORDER THREASHOLD REACHED. Optimizing the order ...");
        orderOptimizer.breakEven(scanner.magicNumber());
        orderOptimizer.trailingStop(scanner.magicNumber());
        return;
    } else {
        accountManager.printAccountInfo();
        PrintCurrencyInfo();

        SignalResult signal = scanner.scan();
        debug(" ==> " + signal.str());

        if (signal.go == GO_LONG || signal.go == GO_SHORT) {
            debug("Booking order: " + signal.str());
            stopLoss.calculateStopLoss(signal);
            bool isLong = signal.go == GO_LONG;
            double optimalLotSize = riskManager.optimalLotSizeFrom(signal, MAX_RISK_PERCENTAGE);
            orderManager.bookTrade(isLong, signal.entry, signal.stopLoss, signal.takeProfit, optimalLotSize, scanner.magicNumber());
        } else {
            debug("NO SIGNAL FROM SCAN RESULT");
        }
    }
}