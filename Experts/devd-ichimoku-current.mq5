

#include <devd/ichimoku/kumo.mqh>

int KUMO_AHEAD_COUNT = 26;

int ANGLE_AVERAGE_COUNT = 3;

void OnStart() {
    SymbolData *s = new SymbolData(_Symbol);
    debug(StringFormat("#%s", s.str()));

    KumoParam *p = new KumoParam(s.symbol, _Period);
    Kumo *k = buildKumo(p, s);
    int t = getTrend(k);

    PrintFormat("###### %s - Trend %d ", p.str(), t);
}
