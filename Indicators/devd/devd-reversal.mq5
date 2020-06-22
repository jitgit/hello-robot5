//+------------------------------------------------------------------+
//|                                                devd-reversal.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

//#property indicator_applied_price PRICE_CLOSE

#define ARROW_1 159  // Symbol code to draw in DRAW_ARROW
#define ARROW_2 159  // Symbol code to draw in DRAW_ARROW

//--- input parameters
input int InpShift = 0;  // Indicator's shift

double buffer0[];
double buffer1[];

#include <devd/common.mqh>
#include <devd/indicator-buffers.mqh>

input string s0 = "-------------------------------------------";  //REVERSAL settings
input int LOOK_BACK_CANDLES = 1;
input int STOC_RANGE_AROUND_MACD = 3;  //Number of bar before & after MACD crossing to check for stoc's overbough and over sold

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
input int STOC_OVER_SOLD_LIMIT = 30;
input int STOC_OVER_BOUGHT_LIMIT = 70;
int stochasticHandle = 0;

int bullishReversalIndexes[];
int bearishReversalIndexes[];
const int BEARISH_INDEX = 0;
const int BULLISH_INDEX = 1;

int OnInit() {
    Print("===================================================== ON INIT");
    macdHandle = iMACD(_Symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE);
    stochasticHandle = iStochastic(_Symbol, PERIOD_CURRENT, Kperiod, Dperiod, slowing, stoch_ma_method, price_field);

    //--- name for indicator label
    IndicatorSetString(INDICATOR_SHORTNAME, "SHORTNAME(" + "HELLO" + ")");
    IndicatorSetInteger(INDICATOR_DIGITS, 4);

    SetIndexBuffer(BEARISH_INDEX, buffer0, INDICATOR_DATA);
    SetIndexBuffer(BULLISH_INDEX, buffer1, INDICATOR_DATA);

    //--- sets indicator shift (Displacement from price value)
    PlotIndexSetInteger(BEARISH_INDEX, PLOT_ARROW_SHIFT, -30);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_ARROW_SHIFT, 30);

    //--- Empty value for building for which there is no rendering
    for (int i = 0; i < indicator_buffers; i++)
        PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0);

    //ZeroIndicatorBuffers();
    //--- sets first bar from what index will be drawn
    //PlotIndexSetInteger(0, PLOT_DRAW_BEGIN,STOC_RANGE_AROUND_MACD);
    //PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, STOC_RANGE_AROUND_MACD);

    //--- name for index label
    PlotIndexSetString(BEARISH_INDEX, PLOT_LABEL, "Bearish");
    PlotIndexSetString(BULLISH_INDEX, PLOT_LABEL, "Bullish");

    for (int i = 0; i < indicator_plots; i++)
        PlotIndexSetInteger(i, PLOT_LINE_WIDTH, 2);

    PlotIndexSetInteger(BEARISH_INDEX, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_DRAW_TYPE, DRAW_ARROW);

    //The code to draw - https://www.mql5.com/en/docs/constants/objectconstants/wingdings
    PlotIndexSetInteger(BEARISH_INDEX, 3, 226);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_ARROW, 225);

    PlotIndexSetInteger(BEARISH_INDEX, PLOT_LINE_COLOR, clrRed);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_LINE_COLOR, clrGreenYellow);

    ZeroIndicatorBuffers();
    //--- initialization done
    return (INIT_SUCCEEDED);
}

void ZeroIndicatorBuffers(void) {
    ArrayInitialize(buffer0, 0);
    ArrayInitialize(buffer1, 0);
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
                const int &spread[])  // array, at which the indicator will be calculated;)
{
    ArraySetAsSeries(time, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);

    //ArraySetAsSeries(buffer0, true);
    //ArraySetAsSeries(buffer1, true);

    //PrintFormat("Current time :%s",tsDate(TimeCurrent()));
    findReversal(time);

    for (int i = 0; i < rates_total; i++) {
        if (i % 9 == 0) {
            // buffer0[i] = high[i];
            // buffer1[i] = low[i];
        }
    }

    for (int i = 0; i < ArraySize(bearishReversalIndexes); i++) {
        int stocIndex = bearishReversalIndexes[i];
        buffer0[stocIndex] = high[stocIndex];
        PrintFormat("%d. OVER BOUGHT Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), high[stocIndex]);
    }

    for (int i = 0; i < ArraySize(bullishReversalIndexes); i++) {
        int stocIndex = bullishReversalIndexes[i];
        buffer1[stocIndex] = low[stocIndex];
        PrintFormat("%d. OVER SOLD Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), low[stocIndex]);
    }

    //--- OnCalculate done. Return new prev_calculated.
    return (rates_total);
}

void findReversal(const datetime &time[]) {
    double macdMainBuffer[];
    double macdSignalBuffer[];
    GetMACDBuffers(macdHandle, 0, LOOK_BACK_CANDLES + 1, macdMainBuffer, macdSignalBuffer);

    double stochMainBuffer[];
    double stochSignalBuffer[];
    GetStochasticBuffers(stochasticHandle, 0, LOOK_BACK_CANDLES + STOC_RANGE_AROUND_MACD, stochMainBuffer, stochSignalBuffer);

    //printArrayInfo(macdMainBuffer, "macdMainBuffer");
    //printArrayInfo(stochMainBuffer, "stochMainBuffer");

    int macdCrossAboveIndexes[];
    int macdCrossBelowIndexes[];
    for (int i = LOOK_BACK_CANDLES; i > 0; i--) {
        if (macdMainBuffer[i] < 0 && macdMainBuffer[i - 1] > 0) {
            //ArrayPrint(macdMainBuffer);
            //PrintFormat("ABOVE %d. %s, Macd((%f) | (%f))", i, tsDate(time[i]), macdMainBuffer[i], macdSignalBuffer[i]);
            //PrintFormat("ABOVE NEXT %d. %s, Macd((%f) | (%f))", i-1, tsDate(time[i-1]), macdMainBuffer[i-1], macdSignalBuffer[i-1]);
            addElement(macdCrossAboveIndexes, i);
        }

        if (macdMainBuffer[i] > 0 && macdMainBuffer[i - 1] < 0) {
            //PrintFormat("BELOW %d. %s, Macd((%f) | (%f))", i, tsDate(time[i]), macdMainBuffer[i], macdSignalBuffer[i]);
            //PrintFormat("BELOW NEXT %d. %s, Macd((%f) | (%f))", i-1, tsDate(time[i-1]), macdMainBuffer[i-1], macdSignalBuffer[i-1]);
            addElement(macdCrossBelowIndexes, i);
        }
    }

    if (ArraySize(macdCrossAboveIndexes) > 0 || ArraySize(macdCrossBelowIndexes) > 0)
        PrintFormat("macdCrossAbove(%d) ,macdCrossBelow(%d)", ArraySize(macdCrossAboveIndexes), ArraySize(macdCrossBelowIndexes));

    if (ArraySize(macdCrossAboveIndexes) > 0)
        PrintFormat("########################### MACD Cross ABOVE : %d", ArraySize(macdCrossAboveIndexes));

    for (int i = 0; i < ArraySize(macdCrossAboveIndexes); i++) {
        int macdIndex = macdCrossAboveIndexes[i];
        PrintFormat("    %d. MACD Index(%d)%s = %f", i, macdIndex, tsDate(time[macdIndex]), macdMainBuffer[macdIndex]);
        for (int j = STOC_RANGE_AROUND_MACD - 1; j >= -STOC_RANGE_AROUND_MACD; j--) {
            int stocIndex = MathMax(macdIndex + j, 0);
            //PrintFormat("stochMainBuffer: %d ,time:%d, %d = %f", ArraySize(stochMainBuffer), ArraySize(time), stocIndex, stochMainBuffer[stocIndex]);
            if (stochMainBuffer[stocIndex] >= STOC_OVER_BOUGHT_LIMIT) {
                PrintFormat("---> %d. Stoc Index(%d)%s = %f", j, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
                addElement(bearishReversalIndexes, macdIndex);
                break;
            }
        }
    }
    if (ArraySize(macdCrossBelowIndexes) > 0)
        PrintFormat("########################### MACD Cross BELOW : %d", ArraySize(macdCrossBelowIndexes));
    for (int i = 0; i < ArraySize(macdCrossBelowIndexes); i++) {
        int macdIndex = macdCrossBelowIndexes[i];
        PrintFormat("    %d. MACD Index(%d)%s = %f", i, macdIndex, tsDate(time[macdIndex]), macdMainBuffer[macdIndex]);
        for (int j = STOC_RANGE_AROUND_MACD - 1; j >= -STOC_RANGE_AROUND_MACD; j--) {
            int stocIndex = MathMax(macdIndex + j, 0);
            //PrintFormat("stochMainBuffer: %d , %d = %f", ArraySize(stochMainBuffer), stocIndex, stochMainBuffer[stocIndex]);
            if (stochMainBuffer[stocIndex] <= STOC_OVER_SOLD_LIMIT) {
                PrintFormat("---> %d. Stoc Index(%d)%s = %f", j, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
                addElement(bullishReversalIndexes, macdIndex);
                break;
            }
        }
    }

    if (ArraySize(bullishReversalIndexes) > 0 || ArraySize(bearishReversalIndexes) > 0) {
        PrintFormat("================= bullishReversalIndexes:%d, bearishReversalIndexes:%d", ArraySize(bullishReversalIndexes), ArraySize(bearishReversalIndexes));
        ArrayPrint(bullishReversalIndexes);
        ArrayPrint(bearishReversalIndexes);
    }
    for (int i = 0; i < ArraySize(bearishReversalIndexes); i++) {
        int stocIndex = bearishReversalIndexes[i];
        PrintFormat("%d. OVER SOLD Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
    }

    for (int i = 0; i < ArraySize(bullishReversalIndexes); i++) {
        int stocIndex = bullishReversalIndexes[i];
        PrintFormat("%d. OVERBOUGHT Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
    }
}

void addElement(int &elements[], int newElement) {
    int currentSize = ArraySize(elements);
    ArrayResize(elements, currentSize + 1);
    elements[currentSize] = newElement;
}
