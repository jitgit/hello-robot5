#property strict

#include <devd/ichimoku/kumo.mqh>
#include <devd/signal/Stochastic/StochasticScanner.mqh>

SignalScanner *scanner = new StochasticScanner();
int OnInit() {
    return INIT_SUCCEEDED;
}

void OnTick() {
    SymbolData *s = new SymbolData(_Symbol);
    SignalResult *signal = scanner.scan(s.symbol, _Period);

    /*;
    debug(StringFormat("#%s", s.str()));

    KumoParam *p = new KumoParam(s.symbol, _Period);
    Kumo *k = buildKumo(p, s);
    int t = getTrend(k);

    PrintFormat("###### %s - Trend %d ", p.str(), t);*/
}
