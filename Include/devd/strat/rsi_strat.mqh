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

input int RSI_PERIOD = 14;
input int RSI_UPPER_BOUND = 70;
input int RSI_LOWER_BOUND = 30;

void main() {
    int SL = 100;
    int TP = 2 * 100;

    SignalScanner *scanner = new RsiScanner(RSI_PERIOD, RSI_UPPER_BOUND, RSI_LOWER_BOUND, TF);
    OrderManager *orderManager = new OrderManager();
    AccountManager *accountManager = new AccountManager();
    RiskManager *riskManager = new RiskManager();
    OrderOptimizer *orderOptimizer = new OrderOptimizer();  //TODO Pass the correct parameter
    AtrStopLoss *stopLoss = new AtrStopLoss(14);

    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(scanner.magicNumber());
    log(StringFormat("Magic Number(%d), MaxOrder(%d), Exiting(%d)", scanner.magicNumber(), MAX_ORDER_THREADHOLD, anyExistingOrders));

    if (anyExistingOrders >= MAX_ORDER_THREADHOLD) {
        debug("MAX ORDER THREASHOLD REACHED. Optimizing the order ...");
        orderOptimizer.breakEven(scanner.magicNumber());
        orderOptimizer.trailingStop(scanner.magicNumber());
        return;
    } else {
        accountManager.printAccountInfo();
        PrintCurrencyInfo();

        ENUM_TIMEFRAMES TF[] = {PERIOD_H4};  //Scanning multiple time frames
        SignalResult signal = scanner.scan(TF);

        if (signal.go == GO_LONG || signal.go == GO_SHORT) {
            debug("Booking order: " + signal.str());
            stopLoss.addEntryStopLossAndTakeProfit(signal);
            bool isLong = signal.go == GO_LONG;
            double optimalLotSize = riskManager.optimalLotSizeFrom(signal, MAX_RISK_PERCENTAGE);
            orderManager.bookTrade(signal, optimalLotSize, scanner.magicNumber());
        } else {
            debug("NO SIGNAL FROM SCAN RESULT." + signal.str());
        }
    }
}