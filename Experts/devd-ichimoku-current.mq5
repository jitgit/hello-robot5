#property strict

#include <devd\acc\RiskManager.mqh>
#include <devd\ichimoku\kumo.mqh>
#include <devd\order\OrderManager.mqh>
#include <devd\order\PositionOptimizer.mqh>
#include <devd\price\ATRBasedSLTPMarketPricer.mqh>
#include <devd\signal\Stochastic\StochasticKDCrossOverScanner.mqh>
#include <devd\signal\Stochastic\StochasticLimitsScanner.mqh>

input int MAX_ORDER_THREADHOLD = 1;
input bool closeOpposite = true;

ATRBasedSLTPMarketPricer *stopLossPricer = new ATRBasedSLTPMarketPricer(14, 2, 3);
OrderManager *orderManager = new OrderManager();
RiskManager riskManager = new RiskManager(3 / MAX_ORDER_THREADHOLD);
SignalScanner *crossOverScanner = new StochasticKDCrossOverScanner();
SignalScanner *confirmationInHTF = new StochasticLimitsScanner();
PositionOptimizer *positionOptimizer = new PositionOptimizer(50);

void OnTick() {
    SymbolData *s = new SymbolData(_Symbol);
    int pendingOrderCounts = positionOptimizer.getPendingOrderCount(s.Name(), ICHIMOKU_STOCH_MAGIC);
    int positionsCount = positionOptimizer.getPositionCount(s.Name(), ICHIMOKU_STOCH_MAGIC);

    positionOptimizer.trailingStop(s, ICHIMOKU_STOCH_MAGIC);
    //info(StringFormat("anyExistingOrders:%d , anyExistingPosition: %d",anyExistingOrders, anyExistingPosition));
    if (positionsCount >= MAX_ORDER_THREADHOLD || pendingOrderCounts >= MAX_ORDER_THREADHOLD) {
        //info("MAX ORDER THREASHOLD REACHED. TODO (Optimizing the order) ..." + (anyExistingOrders + anyExistingPosition));
        return;
    }

    SignalResult *signal = crossOverScanner.scan(s.Name(), _Period);
    if (signal.go != GO_NOTHING) {
        KumoAnalysis *d1 = getKumoAnalysis(s, PERIOD_D1);
        KumoAnalysis *h4 = getKumoAnalysis(s, PERIOD_H4);
        KumoAnalysis *h1 = getKumoAnalysis(s, PERIOD_H1);
        KumoAnalysis *m30 = getKumoAnalysis(s, PERIOD_M30);

        KumoAnalysis array[4];
        CArrayObj* arr = new CArrayObj;
        arr.Add(m30);
        arr.Add(h1);
        arr.Add(h4);
        arr.Add(d1);
        printAnalysis(arr, signal);
        datetime candleTime = iTime(s.Name(), _Period, 0);

        string MTFTrend = StringFormat(" D(%d),H4(%d),H1(%d),M30(%d)", d1.trend, h4.trend, h1.trend, m30.trend);
        if (signal.go == GO_LONG) {
            if (d1.trend >= 0 || h4.trend >= 0 || h1.trend >= 0 || m30.trend >= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend > 0 && d1.trend * h4.trend * h1.trend * m30.trend >= 0) {  // Making sure two TFs trends are not opposite

                    if (closeOpposite)
                        closeUnfilledOppositePendingOrder(POSITION_TYPE_SELL, s);

                    stopLossPricer.addEntryStopLossAndTakeProfit(signal, _Period);
                    double optimalLotSize = riskManager.lotSize(s, signal, _Period);
                    info(StringFormat("►►►►►►►►►►►►►►►► BUY BUY BUY %s size %f", signal.str(), optimalLotSize));
                    bool success = orderManager.bookMarketOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                }
        } else if (signal.go == GO_SHORT) {
            if (d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0) {  // Making sure two TFs trends are not opposite

                    if (closeOpposite)
                        closeUnfilledOppositePendingOrder(POSITION_TYPE_BUY, s);

                    stopLossPricer.addEntryStopLossAndTakeProfit(signal, _Period);
                    double optimalLotSize = riskManager.lotSize(s, signal, _Period);
                    info(StringFormat("►►►►►►►►►►►►►►►► SELL SELL SELL %s, size %f", signal.str(), optimalLotSize));
                    bool success = orderManager.bookMarketOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                }
        }
    }
}

// Here we close an unfilled order as we might have a better opposite order, also as we place limited order
void closeUnfilledOppositePendingOrder(ENUM_POSITION_TYPE pos_type, SymbolData *s) {
    positionOptimizer.CloseOppositePosition(pos_type, s, ICHIMOKU_STOCH_MAGIC);
}

void printAnalysis(CArrayObj* arr, SignalResult *signal) {

   //info(StringFormat("►►►►►►►►►►►►►►►►►►►►►►►►►►►►►►signal %s ArraySize(a) %d", signal.str(), arr.Total()));
    if (signal.go == GO_LONG) {
        for (int i = 0; i < arr.Total(); i++) {
            KumoAnalysis* ka = arr.At(i);                        
            if (ka.trend == 1) {
               info(StringFormat("%s" , ka.str()));
            }
        }

    } else {
        for (int i = 0; i < arr.Total(); i++) {
            KumoAnalysis* ka = arr.At(i);            
            if (ka.trend == -1) {
               info(StringFormat("%s" , ka.str()));
            }
        }
    }

}
