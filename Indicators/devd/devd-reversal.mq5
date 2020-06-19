//+------------------------------------------------------------------+
//|                                                devd-reversal.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"
#property indicator_chart_window
#include <devd/common.mqh>
input string s1 = "-------------------------------------------";  //MACD settings
input ENUM_TIMEFRAMES macd_tf = PERIOD_CURRENT;                   // period
input int fast_ema_period = 12;                                   //period of fast ma
input int slow_ema_period = 26;                                   //period of slow ma
input int signal_period = 9;                                      //period of averaging of difference
input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;             //type of price
int macdHandle = 0;
double macdBuffer[2];

input int sbar = 1;  //Signal bar 0-current, 1-close
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
    macdHandle = iMACD(_Symbol, macd_tf, fast_ema_period, slow_ema_period, signal_period, applied_price);

    //---
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
    double macdValue = macdS();
    printArrayInfo(time, "Time", false);
    printArrayInfo(open, "Open", false);

    for (int i = rates_total - 1; i >= rates_total - 20; i--)
        PrintFormat("%d (%s), Open(%f), Close(%f), Low(%f), High(%f)", i, tsDate(time[i]), open[i], close[i], low[i], high[i]);
    PrintFormat("rates_total:(%f)", rates_total);

    return (rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printArrayInfo(const double &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %f", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printArrayInfo(const datetime &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %f", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
}

//+------------------------------------------------------------------+
double macd(int shift) {
    double res = 0;
    CopyBuffer(macdHandle, 0, shift, 1, macdBuffer);
    res = macdBuffer[0];
    return res;
}
//+------------------------------------------------------------------+
double macdS() {
    int res = 0;
    double ind = macd(sbar);

    if (ind < 0)
        res = 1;
    if (ind > 0)
        res = 2;

    return ind;
}
