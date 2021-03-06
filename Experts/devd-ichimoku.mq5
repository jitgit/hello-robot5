#property strict

#include <devd/ichimoku/kumo.mqh>

SymbolData *s = new SymbolData(_Symbol);

int OnInit() {
    iIchimoku(_Symbol, _Period, 9, 26, 52);  //TO add ichimoku to Strategy Tester
    return INIT_SUCCEEDED;
}
void OnTick() {
    KumoAnalysis *d1 = getKumoAnalysis(s, PERIOD_D1);
    KumoAnalysis *h4 = getKumoAnalysis(s, PERIOD_H4);
    KumoAnalysis *h1 = getKumoAnalysis(s, PERIOD_H1);
    KumoAnalysis *m30 = getKumoAnalysis(s, PERIOD_M30);
    string MTFTrend = StringFormat(" D(%d),H4(%d),H1(%d),M30(%d)", d1.trend, h4.trend, h1.trend, m30.trend);
    
    
    if ((d1.trend >= 0 || h4.trend >= 0 || h1.trend >= 0 || m30.trend >= 0)                                     //Checking atleast one is bullish
        && (d1.trend + h4.trend + h1.trend + m30.trend > 0 && d1.trend * h4.trend * h1.trend * m30.trend >= 0)  // Making sure two TFs trends are not opposite
    ) {
        info("►►►►►► " + MTFTrend);
        PrintFormat("###### %s ", d1.str());
        PrintFormat("###### %s ", h4.str());
        PrintFormat("###### %s ", h1.str());
        PrintFormat("###### %s ", m30.str());

    } else if ((d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)                                     //Checking atleast one is bearish
               && (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0)  // Making sure two TFs trends are not opposite
    ) {
        info("►►►►►► " + MTFTrend);
        PrintFormat("###### %s ", d1.str());
        PrintFormat("###### %s ", h4.str());
        PrintFormat("###### %s ", h1.str());
        PrintFormat("###### %s ", m30.str());
    }
}
