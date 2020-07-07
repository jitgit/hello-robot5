#property strict

#include <devd/acc/RiskManager.mqh>
#include <devd/ichimoku/kumo.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/PositionOptimizer.mqh>
#include <devd/price/ATRBasedSLTPMarketPricer.mqh>
#include <devd/signal/Stochastic/StochasticKDCrossOverScanner.mqh>
#include <devd/signal/Stochastic/StochasticLimitsScanner.mqh>

input int MAX_ORDER_THREADHOLD = 1;

ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 3);
OrderManager *orderManager = new OrderManager();
RiskManager riskManager = new RiskManager();
SignalScanner *crossOverScanner = new StochasticKDCrossOverScanner();
SignalScanner *confirmationInHTF = new StochasticLimitsScanner();
PositionOptimizer *positionOptimizer = new PositionOptimizer();
int ichiHandle = 0;
int OnInit() {
    ichiHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);  //TO add ichimoku to Strategy Tester
    return INIT_SUCCEEDED;
}

void OnTick() {
    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(_Symbol, ICHIMOKU_STOCH_MAGIC);
    int anyExistingPosition = positionOptimizer.getPositionCount(_Symbol, ICHIMOKU_STOCH_MAGIC);

    if (anyExistingOrders + anyExistingPosition >= MAX_ORDER_THREADHOLD) {
        debug("MAX ORDER THREASHOLD REACHED. TODO (Optimizing the order) ...");
        return;
    }

    SignalResult *signal = crossOverScanner.scan(_Symbol, _Period);
    if (signal.go != GO_NOTHING) {
        SymbolData *s = new SymbolData(_Symbol);

        KumoAnalysis *d1 = getKumoAnalysis(s, PERIOD_D1);
        KumoAnalysis *h4 = getKumoAnalysis(s, PERIOD_H4);
        KumoAnalysis *h1 = getKumoAnalysis(s, PERIOD_H1);
        KumoAnalysis *m30 = getKumoAnalysis(s, PERIOD_M30);

        datetime candleTime = iTime(s.symbol, _Period, 0);

        string MTFTrend = StringFormat(" D(%d),H4(%d),H1(%d),M30(%d)", d1.trend, h4.trend, h1.trend, m30.trend);
        if (signal.go == GO_LONG) {
            if (d1.trend >= 0 || h4.trend >= 0 || h1.trend >= 0 || m30.trend >= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend > 0 && d1.trend * h4.trend * h1.trend * m30.trend >= 0) {  // Making sure two TFs trends are not opposite
                    ENUM_TIMEFRAMES confirmationTimeFrame0 = PERIOD_H4;
                    ENUM_TIMEFRAMES confirmationTimeFrame1 = PERIOD_D1;

                    if (m30.trend == 1) {
                        confirmationTimeFrame0 = PERIOD_H1;
                        confirmationTimeFrame1 = PERIOD_H4;
                    } else if (h1.trend == 1) {
                        confirmationTimeFrame0 = PERIOD_H4;
                        confirmationTimeFrame1 = PERIOD_D1;
                    } else if (h4.trend == 1) {
                        confirmationTimeFrame0 = PERIOD_D1;
                        confirmationTimeFrame1 = PERIOD_H4;
                    } else if (d1.trend == 1) {
                        confirmationTimeFrame0 = PERIOD_H4;
                        confirmationTimeFrame1 = PERIOD_D1;
                    }

                    SignalResult *confirmationSignal0 = new SignalResult(s.symbol);
                    confirmationSignal0 = confirmationInHTF.scan(s.symbol, confirmationTimeFrame0);
                    SignalResult *confirmationSignal1 = new SignalResult(s.symbol);
                    confirmationSignal1 = confirmationInHTF.scan(s.symbol, confirmationTimeFrame0);

                    info(StringFormat("►►►► %s, Signal0 %s, CONFIRM0(%s , %s) CONFIRM1(%s , %s) ", MTFTrend, EnumToString(signal.go), EnumToString(confirmationTimeFrame0), EnumToString(confirmationSignal0.go), EnumToString(confirmationTimeFrame1), EnumToString(confirmationSignal1.go)));
                    if (confirmationSignal0.go != GO_SHORT || confirmationSignal1.go != GO_SHORT ||true) {
                        stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);
                        double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);
                        info(StringFormat("►►►►►►►►►►►►►►►► BUY BUY BUY %s size %f", signal.str(), optimalLotSize));
                        bool success = orderManager.bookMarketOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC);
                        /*PrintFormat("%s ", d1.str());
                        PrintFormat("%s ", h4.str());
                        PrintFormat("%s ", h1.str());
                        PrintFormat("%s ", m30.str());*/
                    }
                }
        } else if (signal.go == GO_SHORT) {
            if (d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)

                if (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0) {  // Making sure two TFs trends are not opposite

                    ENUM_TIMEFRAMES confirmationTimeFrame0 = PERIOD_H4;
                    ENUM_TIMEFRAMES confirmationTimeFrame1 = PERIOD_D1;

                    if (m30.trend == -1) {
                        confirmationTimeFrame0 = PERIOD_H1;
                        confirmationTimeFrame1 = PERIOD_H4;
                    } else if (h1.trend == -1) {
                        confirmationTimeFrame0 = PERIOD_H4;
                        confirmationTimeFrame1 = PERIOD_D1;
                    } else if (h4.trend == -1) {
                        confirmationTimeFrame0 = PERIOD_D1;
                        confirmationTimeFrame1 = PERIOD_H4;
                    } else if (d1.trend == -1) {
                        confirmationTimeFrame0 = PERIOD_H4;
                        confirmationTimeFrame1 = PERIOD_D1;
                    }

                    SignalResult *confirmationSignal0 = new SignalResult(s.symbol);
                    confirmationSignal0 = confirmationInHTF.scan(s.symbol, confirmationTimeFrame0);
                    SignalResult *confirmationSignal1 = new SignalResult(s.symbol);
                    confirmationSignal1 = confirmationInHTF.scan(s.symbol, confirmationTimeFrame0);

                    info(StringFormat("►►►► %s, Signal0 %s, CONFIRM0(%s , %s) CONFIRM1(%s , %s) ", MTFTrend, EnumToString(signal.go), EnumToString(confirmationTimeFrame0), EnumToString(confirmationSignal0.go), EnumToString(confirmationTimeFrame1), EnumToString(confirmationSignal1.go)));

                    if (confirmationSignal0.go != GO_LONG || confirmationSignal1.go != GO_LONG||true) {
                        stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);
                        double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);
                        info(StringFormat("►►►►►►►►►►►►►►►► SELL SELL SELL %s, size %f", signal.str(), optimalLotSize));
                        bool success = orderManager.bookLimitOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC);

                        /*PrintFormat("%s ", d1.str());
                        PrintFormat("%s ", h4.str());
                        PrintFormat("%s ", h1.str());
                        PrintFormat("%s ", m30.str());*/
                    }
                }
        }
    }
}
