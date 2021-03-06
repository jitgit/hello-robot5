#property strict

#include <devd/ichimoku/kumo.mqh>


void keybd_event(int bVk, int bScan, int dwFlags, int dwExtraInfo);

SymbolData *s = new SymbolData(_Symbol);

int OnInit() {
    iIchimoku(_Symbol, _Period, 9, 26, 52);  //TO add ichimoku to Strategy Tester
    return INIT_SUCCEEDED;
}
void OnTick() {
    KumoAnalysis *m30 = getKumoAnalysis(s, _Period);
    PrintFormat("►►►►►►►► %s ", s.str());        
    if (m30.trend != 0) {
        PrintFormat("►►►►►►►► %s ", m30.str());        
    }
}

/*Breakpoint neither receive nor send back any parameters
int BreakPoint() {
    //It is expecting, that this function should work
    //only in tester
    if (!MQLInfoInteger(MQL_VISUAL_MODE)) return 0;

    //Press/release Pause button
    //19 is a Virtual Key code of "Pause" button
    //Sleep() is needed, because of the probability
    //to misprocess too quick pressing/releasing
    //of the button
    keybd_event(19, 0, 0, 0);
    Sleep(10);
    keybd_event(19, 0, 2, 0);
    return 0;
}*/