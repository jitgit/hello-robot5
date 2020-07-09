#property strict

#include <devd\include-base.mqh>

void OnStart() {
    SymbolData* s = new SymbolData(_Symbol);
    Alert("=============== %f", s.str());
}
//+------------------------------------------------------------------+
