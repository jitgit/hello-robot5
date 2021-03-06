//+------------------------------------------------------------------+
//|                                                   RSI plus 1.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                     https://www.mql5.com/en/articles/4828#para11 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link "http://www.mql5.com"
#property version "1.0"
//--- Properties
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 5
#property indicator_plots 3
#property indicator_color1 clrSteelBlue
#property indicator_color2 clrMediumSeaGreen
#property indicator_color3 clrRed
//--- Arrows for signals: 159 - points; 233/234 - arrows;
#define ARROW_BUY 159
#define ARROW_SELL 159
//--- Enumeration of channel boundary breakdown modes
enum ENUM_BREAK_INOUT {
    BREAK_IN = 0,          // Break in
    BREAK_IN_REVERSE = 1,  // Break in reverse
    BREAK_OUT = 2,         // Break out
    BREAK_OUT_REVERSE = 3  // Break out reverse
};
//--- Input parameters
input int PeriodRSI = 8;                       // RSI Period
input double SignalLevel = 30;                 // Signal Level
input ENUM_BREAK_INOUT BreakMode = BREAK_OUT;  // Break Mode
//--- Indicator arrays
double rsi_buffer[];
double buy_buffer[];
double sell_buffer[];
double pos_buffer[];
double neg_buffer[];
//---Indent for arrows
int arrow_shift = 0;
//---Indicator period
int period_rsi = 0;
//--- Values ​​of horizontal indicator levels
double up_level = 0;
double down_level = 0;
//--- Starting position for indicator calculations
int start_pos = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit(void) {
    //--- Checking the value of an external parameter
    if (PeriodRSI < 1) {
        period_rsi = 2;
        Print("Incorrect value for input variable PeriodRSI =", PeriodRSI,
              "Indicator will use value =", period_rsi, "for calculations.");
    } else
        period_rsi = PeriodRSI;
    //--- Set indicator properties
    SetPropertiesIndicator();
}
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
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
    //--- Exit if data is insufficient
    if (rates_total <= period_rsi)
        return (0);
    //--- Preliminary calculations
    PreliminaryCalculations(prev_calculated, close);
    //--- The main cycle for calculations
    for (int i = start_pos; i < rates_total && !::IsStopped(); i++) {
        //--- Calculates RSI indicator
        CalculateRSI(i, close);
        //--- Calculates signals
        CalculateSignals(i);
    }
    //---Return the last calculated number of items
    return (rates_total);
}
//+------------------------------------------------------------------+
//| Sets indicator properties                               |
//+------------------------------------------------------------------+
void SetPropertiesIndicator(void) {
    //--- Short name
    ::IndicatorSetString(INDICATOR_SHORTNAME, "RSI_PLUS1");
    //---Decimal places
    ::IndicatorSetInteger(INDICATOR_DIGITS, 4);
    //---Indicator Arrays
    ::SetIndexBuffer(0, rsi_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(1, buy_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(2, sell_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(3, pos_buffer, INDICATOR_CALCULATIONS);
    ::SetIndexBuffer(4, neg_buffer, INDICATOR_CALCULATIONS);
    //--- Array initialization
    ZeroIndicatorBuffers();
    //--- Set text labels
    string plot_label[] = {"RSI", "buy", "sell"};
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetString(i, PLOT_LABEL, plot_label[i]);
    //--- Set the thickness for indicator arrays
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_LINE_WIDTH, 1);
    //--- Set the type for indicator arrays
    ENUM_DRAW_TYPE draw_type[] = {DRAW_LINE, DRAW_ARROW, DRAW_ARROW};
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_DRAW_TYPE, draw_type[i]);
    //--- Tag codes
    ::PlotIndexSetInteger(1, PLOT_ARROW, ARROW_BUY);
    ::PlotIndexSetInteger(2, PLOT_ARROW, ARROW_SELL);
    //--- The index of the element from which the calculation begins
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, period_rsi);
    //--- The number of horizontal indicator levels
    ::IndicatorSetInteger(INDICATOR_LEVELS, 2);
    //--- Values ​​of horizontal indicator levels
    up_level = 100 - SignalLevel;
    down_level = SignalLevel;
    ::IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, down_level);
    ::IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, up_level);
    //---Line style
    ::IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, STYLE_DOT);
    ::IndicatorSetInteger(INDICATOR_LEVELSTYLE, 1, STYLE_DOT);
    //--- Empty value for building for which there is no rendering
    for (int i = 0; i < indicator_buffers; i++)
        ::PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0);
    //--- Y axis shift
    if (BreakMode == BREAK_IN_REVERSE || BreakMode == BREAK_OUT_REVERSE) {
        ::PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, arrow_shift);
        ::PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -arrow_shift);
    } else {
        ::PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -arrow_shift);
        ::PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, arrow_shift);
    }
}
//+------------------------------------------------------------------+
//| Zeroing indicator buffers                                   |
//+------------------------------------------------------------------+
void ZeroIndicatorBuffers(void) {
    ::ArrayInitialize(rsi_buffer, 0);
    ::ArrayInitialize(buy_buffer, 0);
    ::ArrayInitialize(sell_buffer, 0);
}
//+------------------------------------------------------------------+
//| Preliminary calculations                                       |
//+------------------------------------------------------------------+
void PreliminaryCalculations(const int prev_calculated, const double &price[]) {
    double diff = 0;
    //---
    start_pos = prev_calculated - 1;
    if (start_pos <= period_rsi) {
        //--- The first indicator value is not calculated
        rsi_buffer[0] = 0.0;
        pos_buffer[0] = 0.0;
        neg_buffer[0] = 0.0;
        //---
        double sum_p = 0.0;
        double sum_n = 0.0;
        //---
        for (int i = 1; i <= period_rsi; i++) {
            rsi_buffer[i] = 0.0;
            pos_buffer[i] = 0.0;
            neg_buffer[i] = 0.0;
            //---
            diff = price[i] - price[i - 1];
            sum_p += (diff > 0 ? diff : 0);
            sum_n += (diff < 0 ? -diff : 0);
        }
        //--- Calculation of the first value
        pos_buffer[period_rsi] = sum_p / period_rsi;
        neg_buffer[period_rsi] = sum_n / period_rsi;
        //---
        if (neg_buffer[period_rsi] != 0.0)
            rsi_buffer[period_rsi] = 100.0 - (100.0 / (1.0 + pos_buffer[period_rsi] / neg_buffer[period_rsi]));
        else {
            if (pos_buffer[period_rsi] != 0.0)
                rsi_buffer[period_rsi] = 100.0;
            else
                rsi_buffer[period_rsi] = 50.0;
        }
        //--- Starting position for calculations
        start_pos = period_rsi + 1;
    }
}
//+------------------------------------------------------------------+
//| Calculates RSI indicator                                       |
//+------------------------------------------------------------------+
void CalculateRSI(const int i, const double &price[]) {
    double diff = price[i] - price[i - 1];
    //---
    pos_buffer[i] = (pos_buffer[i - 1] * (period_rsi - 1) + (diff > 0.0 ? diff : 0.0)) / period_rsi;
    neg_buffer[i] = (neg_buffer[i - 1] * (period_rsi - 1) + (diff < 0.0 ? -diff : 0.0)) / period_rsi;
    //---
    if (neg_buffer[i] != 0.0)
        rsi_buffer[i] = 100.0 - 100.0 / (1 + pos_buffer[i] / neg_buffer[i]);
    else {
        rsi_buffer[i] = (pos_buffer[i] != 0.0) ? 100.0 : 50.0;
    }
}
//+------------------------------------------------------------------+
//| Calculates indicator signals                                  |
//+------------------------------------------------------------------+
void CalculateSignals(const int i) {
    bool condition1 = false;
    bool condition2 = false;
    //--- Breakdown in the channel
    if (BreakMode == BREAK_IN || BreakMode == BREAK_IN_REVERSE) {
        condition1 = rsi_buffer[i - 1] < down_level && rsi_buffer[i] > down_level;
        condition2 = rsi_buffer[i - 1] > up_level && rsi_buffer[i] < up_level;
    } else {
        condition1 = rsi_buffer[i - 1] < up_level && rsi_buffer[i] > up_level;
        condition2 = rsi_buffer[i - 1] > down_level && rsi_buffer[i] < down_level;
    }
    //--- We display signals if the conditions are met
    if (BreakMode == BREAK_IN || BreakMode == BREAK_OUT) {
        buy_buffer[i] = (condition1) ? rsi_buffer[i] : 0;
        sell_buffer[i] = (condition2) ? rsi_buffer[i] : 0;
    } else {
        buy_buffer[i] = (condition2) ? rsi_buffer[i] : 0;
        sell_buffer[i] = (condition1) ? rsi_buffer[i] : 0;
    }
}
//+------------------------------------------------------------------+
