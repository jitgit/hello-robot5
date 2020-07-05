
#include <devd/include-base.mqh>
#include <devd/ichimoku/lines.mqh>
#include <devd/ichimoku/kumo.mqh>

int KUMO_AHEAD_COUNT = 26;

int ANGLE_AVERAGE_COUNT = 3;



void OnStart() {
    SymbolData *s = new SymbolData(_Symbol);
    KumoParam *d1Param = new KumoParam(s.symbol, _Period);

    Kumo *d1Kumo = buildKumo(d1Param, s);
    
    

    int d1Trend = getTrend(d1Kumo);    
    PrintFormat("%s - Trend %d ", d1Param.str(),d1Trend);
}

int getTrend(Kumo *k) {
    int t = 0;
    if (k.cloudDirection > 0 && k.spanA.lineAngle > 5 & k.spanB.lineAngle > 0 && k.kijuan.lineAngle >5) {
        t = 1;
    } else if (k.cloudDirection < 0 && k.spanA.lineAngle < 5 & k.spanB.lineAngle < 0 && k.kijuan.lineAngle <5) {
        t = -1;
    }

    return t;
}
