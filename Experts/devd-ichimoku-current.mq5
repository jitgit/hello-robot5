#property strict

#include <devd\acc\RiskManager.mqh>
#include <devd\ichimoku\kumo.mqh>
#include <devd\order\OrderManager.mqh>
#include <devd\order\PositionOptimizer.mqh>
#include <devd\price\ATRBasedSLTPMarketPricer.mqh>
#include <devd\signal\Stochastic\StochasticKDCrossOverScanner.mqh>
#include <devd\signal\Stochastic\StochasticLimitsScanner.mqh>
#include <devd\trailingsl\ATRTrailingStop.mqh>

input int MAX_ORDER_THREADHOLD = 1;

ATRBasedSLTPMarketPricer *stopLoss = new ATRBasedSLTPMarketPricer(14, 2, 4);
OrderManager *orderManager = new OrderManager();
RiskManager riskManager = new RiskManager();
SignalScanner *crossOverScanner = new StochasticKDCrossOverScanner();
SignalScanner *confirmationInHTF = new StochasticLimitsScanner();
PositionOptimizer *positionOptimizer = new PositionOptimizer();
TrailingStop *tralingStop = new ATRTrailingStop();

void OnTick() {
    int anyExistingOrders = orderManager.getTotalOrderByMagicNum(_Symbol, ICHIMOKU_STOCH_MAGIC);
    int anyExistingPosition = positionOptimizer.getPositionCount(_Symbol, ICHIMOKU_STOCH_MAGIC);

    if (anyExistingOrders + anyExistingPosition >= MAX_ORDER_THREADHOLD) {
        debug("MAX ORDER THREASHOLD REACHED. TODO (Optimizing the order) ...");
        //tralingStop.updateTrailingStop(ICHIMOKU_STOCH_MAGIC);
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
                    stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);
                    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);
                    info(StringFormat("►►►►►►►►►►►►►►►► BUY BUY BUY %s size %f", signal.str(), optimalLotSize));
                    bool success = orderManager.bookMarketOrder(signal, 0.1, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                                        
                }
        } else if (signal.go == GO_SHORT) {
            if (d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0) {  // Making sure two TFs trends are not opposite

                    stopLoss.addEntryStopLossAndTakeProfit(signal, _Period);
                    double optimalLotSize = riskManager.optimalLotSizeFrom(signal, 2.0);
                    info(StringFormat("►►►►►►►►►►►►►►►► SELL SELL SELL %s, size %f", signal.str(), optimalLotSize));
                    bool success = orderManager.bookLimitOrder(signal, 0.1, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                }
        }
    }
}
