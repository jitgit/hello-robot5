#property strict

#include <devd/ichimoku/kumo.mqh>

void OnStart() {
    SymbolData *s = new SymbolData(_Symbol);
    debug(StringFormat("#%s", s.str()));

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
    if (d1Trend + h4Trend + h1Trend + m30Trend >= 2) {
        PrintFormat("###### %s - Trend %d ", d1Param.str(), d1Trend);
        PrintFormat("###### %s - Trend %d ", h4Param.str(), h4Trend);
        PrintFormat("###### %s - Trend %d ", h1Param.str(), h1Trend);
        PrintFormat("###### %s - Trend %d ", m30Param.str(), m30Trend);
    }
}
