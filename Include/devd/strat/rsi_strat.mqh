#property strict

#include <devd/acc/AccountManager.mqh>
#include <devd/acc/RiskManager.mqh>
#include <devd/account-utils.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/PositionOptimizer.mqh>
#include <devd/order/TradeManager.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>
#include <devd/signal/rsi/RsiScanner.mqh>

input int SELL_ORDER_MAX = 1;
input int BUY_ORDER_MAX = 1;
input int MAX_RISK_PERCENTAGE = 2;

input int RSI_PERIOD = 14;
input int RSI_UPPER_BOUND = 70;
input int RSI_LOWER_BOUND = 30;

input bool CLOSE_COUNTER_TRADES = false;

void main() {
    SignalScanner *scanner = new RsiScanner(RSI_PERIOD, RSI_UPPER_BOUND, RSI_LOWER_BOUND);
    OrderManager *orderManager = new OrderManager();
    TradeManager *tradeManager = new TradeManager(CLOSE_COUNTER_TRADES);
    AccountManager *accountManager = new AccountManager();
    RiskManager *riskManager = new RiskManager();
    PositionOptimizer *positionOptimizer = new PositionOptimizer();  //TODO Pass the correct parameter
    ATRBasedSLTPMarketPricer *atrPricer = new ATRBasedSLTPMarketPricer(14);

    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(_Symbol, scanner.magic());
    info(StringFormat("Magic Number(%d), MaxOrder(%d), Exiting(%d)", scanner.magic(), (SELL_ORDER_MAX + BUY_ORDER_MAX), anyExistingOrders));

    if (anyExistingOrders >= SELL_ORDER_MAX + BUY_ORDER_MAX) {
        debug("MAX ORDER THREASHOLD REACHED. Optimizing existing trades ...");
        positionOptimizer.breakEven(scanner.magic());
        positionOptimizer.trailingStop(scanner.magic());
        return;
    } else {
        string symbol = _Symbol;
        accountManager.printAccountInfo();
        PrintCurrencyInfo(symbol);

        SignalResult *signal = scanner.scan(symbol, PERIOD_H4);

        if (signal.go == GO_LONG || signal.go == GO_SHORT) {
            debug("Booking order: " + signal.str());

            //Calculating entry, SL,TP
            atrPricer.addEntryStopLossAndTakeProfit(signal, PERIOD_H4);

            bool isLong = signal.go == GO_LONG;
            //Calculating Lot Size
            double optimalLotSize = riskManager.optimalLotSizeFrom(signal, MAX_RISK_PERCENTAGE);

            //Try to book the order
            bool success = orderManager.bookLimitOrder(signal, optimalLotSize, scanner.magic());

            //Closing counter trades
            //if (success) {  //TODO need to test this
            //tradeManager.closeCounterTrades(signal, scanner.magic());
            //}
        } else {
            debug("NO SIGNAL FROM SCAN RESULT." + signal.str());
        }
    }
}