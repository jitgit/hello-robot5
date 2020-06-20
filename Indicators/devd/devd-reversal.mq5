//+------------------------------------------------------------------+
//|                                                devd-reversal.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"
#property indicator_chart_window

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 3

#property indicator_color1 clrSteelBlue
#property indicator_color2 clrMediumSeaGreen
#property indicator_color3 clrRed

//#property indicator_applied_price PRICE_CLOSE

#define ARROW_1 159
#define ARROW_2 159

//--- input parameters
input int InpPeriodEMA = 14;  // EMA period
input int InpShift = 0;       // Indicator's shift

double buffer0[];
double buffer1[];
double buffer2[];

#include <devd/common.mqh>
#include <devd/indicator-buffers.mqh>

input string s0 = "-------------------------------------------";  //REVERSAL settings
input int LOOK_BACK_CANDLES = 300;
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

input int sbar = 1;  //Signal bar 0-current, 1-close
int bullishReversalIndexes[];
int bearishReversalIndexes[];
int macdCrossOverIndexes[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {
    macdHandle = iMACD(_Symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE);
    stochasticHandle = iStochastic(_Symbol, PERIOD_CURRENT, Kperiod, Dperiod, slowing, stoch_ma_method, price_field);

    //--- name for indicator label
    IndicatorSetString(INDICATOR_SHORTNAME, "SHORTNAME(" + string(InpPeriodEMA) + ")");

    SetIndexBuffer(0, buffer0, INDICATOR_DATA);
    SetIndexBuffer(1, buffer1, INDICATOR_DATA);
    SetIndexBuffer(2, buffer2, INDICATOR_DATA);
    //--- sets first bar from what index will be drawn
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 3 * InpPeriodEMA);
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 3 * InpPeriodEMA);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, 3 * InpPeriodEMA);

    //--- sets indicator shift
    PlotIndexSetInteger(0, PLOT_SHIFT, InpShift);
    PlotIndexSetInteger(1, PLOT_SHIFT, InpShift);
    PlotIndexSetInteger(2, PLOT_SHIFT, InpShift);

    //--- name for index label
    PlotIndexSetString(0, PLOT_LABEL, "PLOT_LABEL0");
    PlotIndexSetString(1, PLOT_LABEL, "PLOT_LABEL1");
    PlotIndexSetString(2, PLOT_LABEL, "PLOT_LABEL2");

    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_LINE_WIDTH, 1);

    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_ARROW);

    PlotIndexSetInteger(1, PLOT_ARROW, ARROW_1);
    PlotIndexSetInteger(2, PLOT_ARROW, ARROW_2);

    IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, STYLE_DOT);
    IndicatorSetInteger(INDICATOR_LEVELSTYLE, 1, STYLE_DOT);
    IndicatorSetInteger(INDICATOR_LEVELSTYLE, 2, STYLE_DOT);

    //--- Empty value for building for which there is no rendering
    for (int i = 0; i < indicator_buffers; i++)
        PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0);

    PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, _Point);
    PlotIndexSetInteger(2, PLOT_ARROW_SHIFT, -_Point);

    ZeroIndicatorBuffers();
    //--- initialization done
    return (INIT_SUCCEEDED);
}

void ZeroIndicatorBuffers(void) {
    ::ArrayInitialize(buffer0, 0);
    ::ArrayInitialize(buffer1, 0);
    ::ArrayInitialize(buffer2, 0);
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

    ArraySetAsSeries(buffer0, true);
    ArraySetAsSeries(buffer1, true);
    ArraySetAsSeries(buffer2, true);

    findReversal(time);

    int bars = Bars(Symbol(), 0);
    Print("Bars = ", bars, ", rates_total = ", rates_total, ",  prev_calculated = ", prev_calculated);
    //Print("time[0] = ", time[0], " time[rates_total-1] = ", time[rates_total - 1]);

    //--- check for data
    //if (rates_total < 3 *InpPeriodEMA - 3)
    //return (0);

    int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;

    for (int i = 0; i < ArraySize(bearishReversalIndexes); i++) {
        int stocIndex = bearishReversalIndexes[i];
        buffer1[stocIndex] = high[stocIndex] + 0.2;
        PrintFormat("%d. OVER SOLD Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), high[stocIndex] + 0.2);
    }

    for (int i = 0; i < ArraySize(bullishReversalIndexes); i++) {
        int stocIndex = bullishReversalIndexes[i];
        buffer2[stocIndex] = low[stocIndex] - 0.2;
        PrintFormat("%d. OVERBOUGHT Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), low[stocIndex] - 0.2);
    }

    for (int i = 0; i < ArraySize(macdCrossOverIndexes); i++) {
        int stocIndex = macdCrossOverIndexes[i];
        // buffer2[stocIndex] = low[stocIndex] - 0.2 ;
        //PrintFormat("%d. MACD Crossing Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), low[stocIndex] - 0.2);
    }

    //--- OnCalculate done. Return new prev_calculated.
    return (rates_total);
}

void findReversal(const datetime &time[]) {
    double macdMainBuffer[];
    double macdSignalBuffer[];
    GetMACDBuffers(macdHandle, 0, LOOK_BACK_CANDLES, macdMainBuffer, macdSignalBuffer);

    double stochMainBuffer[];
    double stochSignalBuffer[];
    GetStochasticBuffers(stochasticHandle, 0, LOOK_BACK_CANDLES + STOC_RANGE_AROUND_MACD, stochMainBuffer, stochSignalBuffer);

    printArrayInfo(macdMainBuffer, "macdMainBuffer");
    printArrayInfo(stochMainBuffer, "stochMainBuffer");

    int macdCrossAboveIndexes[];
    int macdCrossBelowIndexes[];
    for (int i = LOOK_BACK_CANDLES - 2; i >= 1; i--) {
        if (macdMainBuffer[i] < 0 && macdMainBuffer[i - 1] > 0) {
            //PrintFormat("ABOVE %d. %s, Open(%f), High(%f), Low(%f), Close(%f), Macd((%f) | (%f)), Stochastic((%f) | (%f)) ", i, tsDate(time[i]), open[i], high[i], low[i], close[i], macdMainBuffer[i], macdSignalBuffer[i], stochMainBuffer[i], stochSignalBuffer[i]);
            addElement(macdCrossAboveIndexes, i);
            addElement(macdCrossOverIndexes, i);
        }

        if (macdMainBuffer[i] > 0 && macdMainBuffer[i - 1] < 0) {
            addElement(macdCrossOverIndexes, i);
            //PrintFormat("BELOW %d. %s, Open(%f), High(%f), Low(%f), Close(%f), Macd((%f) | (%f)), Stochastic((%f) | (%f)) ", i, tsDate(time[i]), open[i], high[i], low[i], close[i], macdMainBuffer[i], macdSignalBuffer[i], stochMainBuffer[i], stochSignalBuffer[i]);
            addElement(macdCrossBelowIndexes, i);
        }
    }

    PrintFormat("macdCrossAbove(%d) ,macdCrossBelow(%d)", ArraySize(macdCrossAboveIndexes), ArraySize(macdCrossBelowIndexes));

    Print("MACD Cross ABOVE ###########################");

    for (int i = 0; i < ArraySize(macdCrossAboveIndexes); i++) {
        int macdIndex = macdCrossAboveIndexes[i];
        PrintFormat("%d. MACD Index(%d)%s = %f", i, macdIndex, tsDate(time[macdIndex]), macdMainBuffer[macdIndex]);
        for (int j = STOC_RANGE_AROUND_MACD; j >= -STOC_RANGE_AROUND_MACD; j--) {
            int stocIndex = macdIndex + j;
            if (stochMainBuffer[stocIndex] >= STOC_OVER_BOUGHT_LIMIT) {
                PrintFormat("---> %d. Stoc Index(%d)%s = %f", j, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
                addElement(bearishReversalIndexes, macdIndex);
                ArrayPrint(bearishReversalIndexes);
                break;
            }
        }
    }

    Print("MACD Cross BELOW ###########################");
    for (int i = 0; i < ArraySize(macdCrossBelowIndexes); i++) {
        int macdIndex = macdCrossBelowIndexes[i];
        PrintFormat("%d. MACD Index(%d)%s = %f", i, macdIndex, tsDate(time[macdIndex]), macdMainBuffer[macdIndex]);
        for (int j = STOC_RANGE_AROUND_MACD; j >= -STOC_RANGE_AROUND_MACD; j--) {
            int stocIndex = macdIndex + j;
            if (stochMainBuffer[stocIndex] <= STOC_OVER_SOLD_LIMIT) {
                PrintFormat("---> %d. Stoc Index(%d)%s = %f", j, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
                addElement(bullishReversalIndexes, macdIndex);
                ArrayPrint(bullishReversalIndexes);
                break;
            }
        }
    }

    PrintFormat("====================================================================");
    ArrayPrint(bullishReversalIndexes);
    ArrayPrint(bearishReversalIndexes);
    /*for (int i = 0; i < ArraySize(bearishReversalIndexes); i++) {
        int stocIndex = bearishReversalIndexes[i];
        PrintFormat("%d. OVER SOLD Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
    }

    for (int i = 0; i < ArraySize(bullishReversalIndexes); i++) {
        int stocIndex = bullishReversalIndexes[i];
        PrintFormat("%d. OVERBOUGHT Stoc Index(%d)%s = %f", i, stocIndex, tsDate(time[stocIndex]), stochMainBuffer[stocIndex]);
    }*/
}

void addElement(int &elements[], int newElement) {
    int currentSize = ArraySize(elements);
    ArrayResize(elements, currentSize + 1);

    elements[currentSize] = newElement;
}
