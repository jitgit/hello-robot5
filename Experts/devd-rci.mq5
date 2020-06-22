//+------------------------------------------------------------------+
//|                                                     devd-rci.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"
#include <devd/common.mqh>
#include <devd/strat/rsi_strat.mqh>


int OnInit() {
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {

   main();
}
