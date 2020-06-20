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
#include <devd/indicator-buffers.mqh>
input string s1 = "-------------------------------------------";  //MACD settings
//input ENUM_TIMEFRAMES macd_tf = PERIOD_CURRENT;                   // period
input int fast_ema_period = 12;  //period of fast ma
input int slow_ema_period = 26;  //period of slow ma
input int signal_period = 9;     //period of averaging of difference
//input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;             //type of price
int macdHandle = 0;

input string s2 = "-------------------------------------------";  //Stochastic settings
//input ENUM_TIMEFRAMES macd_tf = PERIOD_CURRENT;                   // period
input int Kperiod = 70;  //K Period
input int Dperiod = 10;  //D Period
input int slowing = 10;  //Slowing
//input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;             //type of price
input ENUM_MA_METHOD stoch_ma_method = MODE_SMA;  //MA Method
input ENUM_STO_PRICE price_field = STO_LOWHIGH;
int stochasticHandle = 0;

input int sbar = 1;  //Signal bar 0-current, 1-close
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {
    macdHandle = iMACD(_Symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE);
    stochasticHandle = iStochastic(_Symbol, PERIOD_CURRENT, Kperiod, Dperiod, slowing, stoch_ma_method, price_field);

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
    int read_count = 10;
    double macdMainBuffer[];
    double macdSignalBuffer[];
    GetMACDBuffers(macdHandle, 0, read_count, macdMainBuffer, macdSignalBuffer);

    double stochMainBuffer[];
    double stochSignalBuffer[];
    GetStochasticBuffers(stochasticHandle, 0, read_count, stochMainBuffer, stochSignalBuffer);

    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(time, true);

    for (int i = 0; i < read_count; i++)
        PrintFormat("%s, Open(%f), High(%f), Low(%f), Close(%f), Macd((%f) | (%f)), Stochastic((%f) | (%f)) ", tsDate(time[i]), open[i], high[i], low[i], close[i], macdMainBuffer[i], macdSignalBuffer[i], stochMainBuffer[i], stochSignalBuffer[i]);
    PrintFormat("====================================================================");

    return (rates_total);
}
