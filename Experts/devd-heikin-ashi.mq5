#property strict

#include <devd\acc\RiskManager.mqh>
#include <devd\ichimoku\kumo.mqh>
#include <devd\order\OrderManager.mqh>
#include <devd\order\PositionOptimizer.mqh>
#include <devd\price\ATRBasedSLTPMarketPricer.mqh>
#include <devd\signal\Stochastic\StochasticKDCrossOverScanner.mqh>
#include <devd\signal\Stochastic\StochasticLimitsScanner.mqh>

class HACandle : public CObject {
   public:
    double o, h, l, c;
    double upperShadow;
    double lowerShadow;
    double body;
    int shadowToBodyRatio;
    double height;
    string candleColor;
    datetime time;
    double bodyRatioToPrevious;

    int isDoji;

    HACandle(double open, double high, double low, double close, int colour, datetime t, HACandle *previous) {  //candleColor=0(Blue), 1(Red)
        o = open;
        h = high;
        l = low;
        c = close;
        height = MathAbs(high - low);
        upperShadow = MathAbs(high - close);
        lowerShadow = MathAbs(open - low);
        body = MathAbs(close - open);
        shadowToBodyRatio = (upperShadow + lowerShadow) * 100 / body;
        candleColor = colour == 1 ? "R" : "B";
        time = t;

        isDoji = (upperShadow > 0 && lowerShadow > 0 && shadowToBodyRatio > 1200) ? 1 : 0;
        bodyRatioToPrevious = 0;
        if (previous != NULL) {
            bodyRatioToPrevious = (body - previous.body) * 100 / previous.body;
        }
    }
    string str() {
        string ohlc = StringFormat("%s - (%f|%f|%f|%f)", tsDate(time), o, h, l, c);
        return StringFormat("%s Ht.(%f) [%f] [%f] [%f] ║%d║%s║ Doji: %d, BodyToPrevious(%2.1f)", ohlc, height, upperShadow, body, lowerShadow, shadowToBodyRatio, candleColor, isDoji, bodyRatioToPrevious);
    }
};

class HAAnalysis : public CObject {
   public:
    Kumo *k;
    KumoParam *p;  //Number of TS when non change
    int trend;

    string str() {
        return StringFormat("%s(%s), %s, ║%d║", p.symbol, EnumToString(p.timeFrame), k.str(), trend);
    }
    HAAnalysis() {
        trend = 0;
    }
};

const int BAR_COUNT = 8;
const int HA_OPEN = 0;
const int HA_HIGH = 1;
const int HA_LOW = 2;
const int HA_CLOSE = 3;
datetime currentCandleTime = 0;
int haHandle;
int OnInit() {
    Print("===================================================== ON INIT");
    haHandle = iCustom(NULL, PERIOD_CURRENT, "Examples\\Heiken_Ashi");
    return (0);
}

void OnTick() {
    datetime nextCandle = iTime(_Symbol, _Period, 0);
    if (currentCandleTime != nextCandle) {
        if (BarsCalculated(haHandle) > 100) {
            CheckHACandles();
        }
        currentCandleTime = nextCandle;
    }
}

void CheckHACandles() {
    double haOpen[];
    double haHigh[];
    double haLow[];
    double haClose[];
    double haColor[];
    datetime time[];

    GetHeikinAshiBuffers(haHandle, 0, BAR_COUNT, haOpen, haHigh, haLow, haClose, haColor, false);
    CopyTime(_Symbol, _Period, 0, BAR_COUNT, time);
    Print("=====================================================");
    /*for (int i = 0; i < BAR_COUNT; i++) {
        PrintFormat("%d. O(%f), H(%f), L(%f), C(%f), Color(%f)", i, haOpen[i], haHigh[i], haLow[i], haClose[i], haColor[i]);
    }*/

    HAAnalysis a = doHeikinAshi(haOpen, haHigh, haLow, haClose, haColor, time, BAR_COUNT);
}

HAAnalysis *doHeikinAshi(double &haOpen[], double &haHigh[], double &haLow[], double &haClose[], double &haColor[], datetime &time[], int totalCandles) {
    HAAnalysis *result = new HAAnalysis();
    CArrayObj *candles = new CArrayObj;
    HACandle *previousCandle = NULL;
    for (int i = 0; i < totalCandles; i++) {
        HACandle *c = new HACandle(haOpen[i], haHigh[i], haLow[i], haClose[i], haColor[i], time[i], previousCandle);
        candles.Add(c);
        previousCandle = c;
        PrintFormat("%s", c.str());
    }
    return result;
}

/*
input int MAX_ORDER_THREADHOLD = 1;
input bool closeOpposite = true;

ATRBasedSLTPMarketPricer *stopLossPricer = new ATRBasedSLTPMarketPricer(14, 2, 3);
OrderManager *orderManager = new OrderManager();
RiskManager riskManager = new RiskManager(3 / MAX_ORDER_THREADHOLD);
SignalScanner *crossOverScanner = new StochasticKDCrossOverScanner();
SignalScanner *confirmationInHTF = new StochasticLimitsScanner();
PositionOptimizer *positionOptimizer = new PositionOptimizer(50);

void OnTick1() {
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

        CArrayObj *arr = new CArrayObj;
        arr.Add(m30);
        arr.Add(h1);
        arr.Add(h4);
        arr.Add(d1);
        int indexMatch = printAnalysis(arr, signal);

        string MTFTrend = StringFormat("D(%d),H4(%d),H1(%d),M30(%d)", d1.trend, h4.trend, h1.trend, m30.trend);
        if (signal.go == GO_LONG) {
            if (d1.trend >= 0 || h4.trend >= 0 || h1.trend >= 0 || m30.trend >= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend > 0 && d1.trend * h4.trend * h1.trend * m30.trend >= 0) {  // Making sure two TFs trends are not opposite

                    KumoAnalysis *matchedKumo = arr.At(indexMatch);
                    SignalResult *confirmationSignal = checkStochLimit(matchedKumo, s);
                    if (confirmationSignal.go == signal.go || true) {
                        if (closeOpposite)
                            closeUnfilledOppositePendingOrder(POSITION_TYPE_SELL, s);

                        stopLossPricer.addEntryStopLossAndTakeProfit(signal, _Period);
                        double optimalLotSize = riskManager.lotSize(s, signal, _Period);
                        info(StringFormat("I(%d) ►►►►►►►►►►►►►►►► BUY BUY BUY %s size %f", indexMatch, signal.str(), optimalLotSize));
                        info(StringFormat("►►►►►►►►►►►►►►►► CONFIMATION %s", confirmationSignal.str()));
                        bool success = orderManager.bookMarketOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                    } else {
                        warn(StringFormat("BUY SIGNAL(%s), CONFIRMATION(%s)", signal.str1(), confirmationSignal.str1()));
                    }
                }
        } else if (signal.go == GO_SHORT) {
            if (d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0) {  // Making sure two TFs trends are not opposite

                    KumoAnalysis *matchedKumo = arr.At(indexMatch);
                    SignalResult *confirmationSignal = checkStochLimit(matchedKumo, s);
                    if (confirmationSignal.go == signal.go || true) {
                        if (closeOpposite)
                            closeUnfilledOppositePendingOrder(POSITION_TYPE_BUY, s);

                        stopLossPricer.addEntryStopLossAndTakeProfit(signal, _Period);
                        double optimalLotSize = riskManager.lotSize(s, signal, _Period);
                        info(StringFormat("I(%d) ►►►►►►►►►►►►►►►► SELL SELL SELL %s, size %f", indexMatch, signal.str(), optimalLotSize));
                        info(StringFormat("►►►►►►►►►►►►►►►► CONFIMATION %s", confirmationSignal.str()));
                        bool success = orderManager.bookMarketOrder(signal, optimalLotSize, ICHIMOKU_STOCH_MAGIC, MTFTrend);
                    } else {
                        warn(StringFormat("SELL SIGNAL(%s), CONFIRMATION(%s)", signal.str1(), confirmationSignal.str1()));
                    }
                }
        }
    }
}

SignalResult *checkStochLimit(KumoAnalysis *KumoAnalysis, SymbolData *s) {
    return confirmationInHTF.scan(s.Name(), KumoAnalysis.p.timeFrame);
}

// Here we close an unfilled order as we might have a better opposite order, also as we place limited order
void closeUnfilledOppositePendingOrder(ENUM_POSITION_TYPE pos_type, SymbolData *s) {
    positionOptimizer.CloseOppositePosition(pos_type, s, ICHIMOKU_STOCH_MAGIC);
}

int printAnalysis(CArrayObj *arr, SignalResult *signal) {
    //info(StringFormat("►►►►►►►►►►►►►►►►►►►►►►►►►►►►►►signal %s ArraySize(a) %d", signal.str(), arr.Total()));
    int trend = signal.go == GO_LONG ? 1 : -1;
    int result = -1;
    for (int i = 0; i < arr.Total(); i++) {
        KumoAnalysis *ka = arr.At(i);
        if (ka.trend == trend) {
            info(StringFormat("%s", ka.str()));
            if (result == -1)
                result = i;
        }
    }
    return result;
}*/
