
#include <devd/include-base.mqh>
#include <devd/ichimoku/kumo.mqh>


int KUMO_AHEAD_COUNT = 26;

int ANGLE_AVERAGE_COUNT = 3;

void OnStart() {
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
    
    PrintFormat("###### %s - Trend %d ", d1Param.str(), d1Trend);
    PrintFormat("###### %s - Trend %d ", h4Param.str(), h4Trend);    
    PrintFormat("###### %s - Trend %d ", h1Param.str(), h1Trend);
    PrintFormat("###### %s - Trend %d ", m30Param.str(), m30Trend);
}



int getTrend(Kumo *k) {
    int t = 0;
    if (k.cloudDirection > 0 && k.spanA.lineAngle > 5 & k.spanB.lineAngle > 0 && k.kijuan.lineAngle > 5) {      
        t = 1;
    } else if (k.cloudDirection < 0 && k.spanA.lineAngle < 5 & k.spanB.lineAngle < 0 && k.kijuan.lineAngle < 5) {
        t = -1;
    }
    return t;
}
