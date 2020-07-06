#property strict

#include <devd/ichimoku/kumo.mqh>
#include <devd/signal/Stochastic/StochasticScanner.mqh>

SignalScanner *scanner = new StochasticScanner();
int ichiHandle = 0;
int OnInit() {
    ichiHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);  //TO add ichimoku to tester
    return INIT_SUCCEEDED;
}

void OnTick() {
    SignalResult *signal = scanner.scan(_Symbol, _Period);

    if (signal.go != GO_NOTHING) {
        SymbolData *s = new SymbolData(_Symbol);

        KumoParam *d1Param = new KumoParam(s.symbol, PERIOD_D1);
        Kumo *d1Kumo = buildKumo(d1Param, s);
        int d1Trend = getTrend(d1Kumo);

        KumoParam *h4Param = new KumoParam(s.symbol, PERIOD_H4);
        Kumo *h4Kumo = buildKumo(h4Param, s);
        int h4Trend = getTrend(h4Kumo);

        KumoParam *h1Param = new KumoParam(s.symbol, PERIOD_H1);
        Kumo *h1Kumo = buildKumo(h1Param, s);
        int h1Trend = getTrend(h1Kumo);

        KumoParam *m30Param = new KumoParam(s.symbol, PERIOD_M30);
        Kumo *m30Kumo = buildKumo(m30Param, s);
        int m30Trend = getTrend(m30Kumo);

        datetime candleTime = iTime(s.symbol, _Period, 0);

        if (signal.go == GO_LONG && (d1Trend <= 0 || h4Trend <= 0 || h1Trend <= 0 || m30Trend <= 0)) {
            if (d1Trend + h4Trend + h1Trend + m30Trend > 0 && d1Trend * h4Trend * h1Trend * m30Trend >= 0) {  // Making sure tw are not oppositeopposite
                info(StringFormat("######%s", signal.str()));
                PrintFormat("BUY %s %s - Trend %d ", d1Param.str(), d1Kumo.str(), d1Trend);
                PrintFormat("BUY %s %s - Trend %d ", h4Param.str(), h4Kumo.str(), h4Trend);
                PrintFormat("BUY %s %s - Trend %d ", h1Param.str(), h1Kumo.str(), h1Trend);
                PrintFormat("BUY %s %s - Trend %d ", m30Param.str(), m30Kumo.str(), m30Trend);
            }
        } else if (signal.go == GO_SHORT && (d1Trend <= 0 || h4Trend <= 0 || h1Trend <= 0 || m30Trend <= 0)) {
            if (d1Trend + h4Trend + h1Trend + m30Trend < 0 && d1Trend * h4Trend * h1Trend * m30Trend <= 0) { // Making sure two trends are not opposite
                info(StringFormat("######%s", signal.str()));
            PrintFormat("SELL %s %s - Trend %d ", d1Param.str(), d1Kumo.str(), d1Trend);
            PrintFormat("SELL %s %s - Trend %d ", h4Param.str(), h4Kumo.str(), h4Trend);
            PrintFormat("SELL %s %s - Trend %d ", h1Param.str(), h1Kumo.str(), h1Trend);
            PrintFormat("SELL %s %s - Trend %d ", m30Param.str(), m30Kumo.str(), m30Trend);
        }
    }
}
}
