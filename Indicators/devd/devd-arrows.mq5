
#include <devd/include-base.mqh>
#include <devd/indicator-buffers.mqh>

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

//#property indicator_applied_price PRICE_CLOSE

#define ARROW_1 159  // Symbol code to draw in DRAW_ARROW
#define ARROW_2 159  // Symbol code to draw in DRAW_ARROW


double bearish_buffer[];
double bullish_buffer[];


int bullishReversalIndexes[];
int bearishReversalIndexes[];

const int BEARISH_INDEX = 0;
const int BULLISH_INDEX = 1;

int LAST_CANDLE = 100;
const int ARRAOW_DISTANCE_FROM_CANDLE=20;

int OnInit() {
    Print("===================================================== ON INIT");    
    //--- name for indicator label
    IndicatorSetString(INDICATOR_SHORTNAME, "SHORTNAME(" + "HELLO" + ")");
    IndicatorSetInteger(INDICATOR_DIGITS, 4);

    SetIndexBuffer(BEARISH_INDEX, bearish_buffer, INDICATOR_DATA);
    SetIndexBuffer(BULLISH_INDEX, bullish_buffer, INDICATOR_DATA);

    //--- sets indicator shift (Displacement from price value)
    PlotIndexSetInteger(BEARISH_INDEX, PLOT_ARROW_SHIFT, -ARRAOW_DISTANCE_FROM_CANDLE);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_ARROW_SHIFT, ARRAOW_DISTANCE_FROM_CANDLE);

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
        PlotIndexSetInteger(i, PLOT_LINE_WIDTH, 1);

    PlotIndexSetInteger(BEARISH_INDEX, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_DRAW_TYPE, DRAW_ARROW);

    //The code to draw - https://www.mql5.com/en/docs/constants/objectconstants/wingdings
    PlotIndexSetInteger(BEARISH_INDEX, PLOT_ARROW, 234);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_ARROW, 233);

    PlotIndexSetInteger(BEARISH_INDEX, PLOT_LINE_COLOR, clrRed);
    PlotIndexSetInteger(BULLISH_INDEX, PLOT_LINE_COLOR, clrGreenYellow);

    ZeroIndicatorBuffers();
    //--- initialization done
    return (INIT_SUCCEEDED);
}

void ZeroIndicatorBuffers() {
    ArrayInitialize(bearish_buffer, 0);
    ArrayInitialize(bullish_buffer, 0);
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

    ArraySetAsSeries(bearish_buffer, true);
    ArraySetAsSeries(bullish_buffer, true);
    //ZeroIndicatorBuffers();
    if(rates_total < LAST_CANDLE) return 0;
    int toCount = (int)MathMin(rates_total, rates_total - prev_calculated + LAST_CANDLE);
    //PrintFormat("bearish_buffer: %d , bullish_buffer: %d, toCount:%d ", ArraySize(bearish_buffer) , ArraySize(bullish_buffer),toCount);
    for (int i = 0; i < toCount; i++) {
        if (rates_total % 6 == 0) {
            bearish_buffer[i] = high[i];            
        }else{
            bullish_buffer[i] = low[i];
        }
    }

    return (rates_total);
}
