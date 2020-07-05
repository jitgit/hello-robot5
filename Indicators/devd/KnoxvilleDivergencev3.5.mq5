//+------------------------------------------------------------------+
//|                                         Knoxville Divergence.mq5 |
//|                                             copyright Rob Booker |
//|                                       developed by Daniel Sinnig |
//+------------------------------------------------------------------+

#property copyright "Copyright 2019, Rob Booker"
#property link "http://www.metaquotes.net"
#property strict

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots 8
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Red
#property indicator_color5 Green
#property indicator_color6 Red
#property indicator_color7 Green
#property indicator_color8 Red
#property indicator_width1 5
#property indicator_width2 5
#property indicator_width3 3
#property indicator_width4 3
#property indicator_width5 5
#property indicator_width6 5
#property indicator_width7 5
#property indicator_width8 5

input int CandlesBack = 30;
input int RSIPeriod = 21;
input int MomentumPeriod = 20;
input int FastMAPeriod = 12;
input int SlowMAPeriod = 26;
input int SignalMAPeriod = 9;
input int KPeriod = 70;
input int DPeriod = 10;
input int Slowing = 10;
input int Stochastic_Upper = 70;
input int Stochastic_Lower = 30;
input bool Reversal_Tabs_Alerts = false;
input bool Mail_Alert = false;
input bool PopUp_Alert = false;
input bool Sound_Alert = false;
input bool SmartPhone_Notifications = false;

double UsePoint;

bool Alerts = true;
bool KAlerts = true;
double Buy[];
double Sell[];
double BuyArrow[];
double SellArrow[];
double BuyAlt[];
double SellAlt[];
double BuyAlt1[];
double SellAlt1[];
datetime LastKDB;
datetime LastKDS;
datetime LastKDBA;
datetime LastKDSA;
datetime LastKDBA2;
datetime LastKDSA2;

int RSIHandle;
int MomentumHandle;
int MACDHandle;
int StochHandle;

double iRSIBuffer[];
double iMomentumBuffer[];
double iMACDBuffer[];
double iStochBuffer[];

int bars_calculated = 0;

int OnInit() {
    ArraySetAsSeries(iRSIBuffer, true);
    ArraySetAsSeries(iMomentumBuffer, true);
    ArraySetAsSeries(iMACDBuffer, true);
    ArraySetAsSeries(iStochBuffer, true);

    RSIHandle = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE);

    if (RSIHandle == INVALID_HANDLE) {
        PrintFormat("Failed to access handle of the iRSI indicator for the symbol. Error code: " + IntegerToString(GetLastError()));
        return (INIT_FAILED);
    }

    MomentumHandle = iMomentum(Symbol(), 0, MomentumPeriod, PRICE_CLOSE);

    if (MomentumHandle == INVALID_HANDLE) {
        PrintFormat("Failed to access handle of the iMomentum indicator for the symbol. Error code: " + IntegerToString(GetLastError()));
        return (INIT_FAILED);
    }

    MACDHandle = iMACD(Symbol(), 0, FastMAPeriod, SlowMAPeriod, SignalMAPeriod, PRICE_CLOSE);

    if (MACDHandle == INVALID_HANDLE) {
        PrintFormat("Failed to access handle of the iMACD indicator for the symbol. Error code: " + IntegerToString(GetLastError()));
        return (INIT_FAILED);
    }

    StochHandle = iStochastic(Symbol(), 0, KPeriod, DPeriod, Slowing, MODE_SMA, STO_CLOSECLOSE);

    if (StochHandle == INVALID_HANDLE) {
        PrintFormat("Failed to access handle of the iStochastics indicator for the symbol. Error code: " + IntegerToString(GetLastError()));
        return (INIT_FAILED);
    }

    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(0, Buy);
    ArraySetAsSeries(Buy, true);
    PlotIndexSetString(0, PLOT_LABEL, "Buy Knox");

    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(1, Sell);
    ArraySetAsSeries(Sell, true);
    PlotIndexSetString(1, PLOT_LABEL, "Sell Knox");

    PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(2, PLOT_ARROW, 233);
    SetIndexBuffer(2, BuyArrow);
    ArraySetAsSeries(BuyArrow, true);
    PlotIndexSetString(2, PLOT_LABEL, "Buy Reversal");

    PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(3, PLOT_ARROW, 234);
    SetIndexBuffer(3, SellArrow);
    ArraySetAsSeries(SellArrow, true);
    PlotIndexSetString(3, PLOT_LABEL, "Sell Reversal");

    PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(4, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(4, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(4, BuyAlt);
    ArraySetAsSeries(BuyAlt, true);
    PlotIndexSetString(4, PLOT_LABEL, "Buy Knox Alt");

    PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(5, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(5, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(5, SellAlt);
    ArraySetAsSeries(SellAlt, true);
    PlotIndexSetString(5, PLOT_LABEL, "Sell Knox Alt");

    PlotIndexSetInteger(6, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(6, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(6, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(6, BuyAlt1);
    ArraySetAsSeries(BuyAlt1, true);
    PlotIndexSetString(6, PLOT_LABEL, "Buy Knox Alt");

    PlotIndexSetInteger(7, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(7, PLOT_LINE_STYLE, STYLE_SOLID);
    //PlotIndexSetInteger(7, PLOT_LINE_WIDTH, 1);
    SetIndexBuffer(7, SellAlt1);
    ArraySetAsSeries(SellAlt1, true);
    PlotIndexSetString(7, PLOT_LABEL, "Sell Knox Alt");

    UsePoint = PipPoint(Symbol());

    return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {
    ArrayFree(Buy);
    ArrayFree(Sell);
    ArrayFree(BuyArrow);
    ArrayFree(SellArrow);
    ArrayFree(BuyAlt);
    ArrayFree(SellAlt);
    ArrayFree(BuyAlt1);
    ArrayFree(SellAlt1);
}

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
    ArraySetAsSeries(time, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(low, true);

    if (prev_calculated == 0) {
        //first run
        ArrayInitialize(Buy, EMPTY_VALUE);
        ArrayInitialize(Sell, EMPTY_VALUE);
        ArrayInitialize(BuyArrow, EMPTY_VALUE);
        ArrayInitialize(SellArrow, EMPTY_VALUE);
        ArrayInitialize(BuyAlt, EMPTY_VALUE);
        ArrayInitialize(SellAlt, EMPTY_VALUE);
        ArrayInitialize(BuyAlt1, EMPTY_VALUE);
        ArrayInitialize(SellAlt1, EMPTY_VALUE);
    }

    //calculate RSI

    int values_to_copy;
    int calculated = BarsCalculated(RSIHandle);
    if (calculated <= 0) {
        Print("Could not calculate RSI");
        return (0);
    }

    if (prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated + 1) {
        if (calculated > rates_total)
            values_to_copy = rates_total;
        else
            values_to_copy = calculated;
    } else {
        values_to_copy = (rates_total - prev_calculated) + 1;
    }

    if (!FillArrayFromBuffer(iRSIBuffer, RSIHandle, values_to_copy)) return (0);

    //calculate Momentum
    calculated = BarsCalculated(RSIHandle);
    if (calculated <= 0) return (0);

    if (prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated + 1) {
        if (calculated > rates_total)
            values_to_copy = rates_total;
        else
            values_to_copy = calculated;
    } else {
        values_to_copy = (rates_total - prev_calculated) + 1;
    }

    if (!FillArrayFromBuffer(iMomentumBuffer, MomentumHandle, values_to_copy)) return (0);

    //calculate MACD MAIN LINE
    calculated = BarsCalculated(MACDHandle);
    if (calculated <= 0) return (0);

    if (prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated + 1) {
        if (calculated > rates_total)
            values_to_copy = rates_total;
        else
            values_to_copy = calculated;
    } else {
        values_to_copy = (rates_total - prev_calculated) + 1;
    }

    if (!FillArrayFromBuffer(iMACDBuffer, MACDHandle, values_to_copy)) return (0);

    //calculate Stochastics
    calculated = BarsCalculated(StochHandle);
    if (calculated <= 0) return (0);

    if (prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated + 1) {
        if (calculated > rates_total)
            values_to_copy = rates_total;
        else
            values_to_copy = calculated;
    } else {
        values_to_copy = (rates_total - prev_calculated) + 1;
    }

    if (!FillArrayFromBuffer(iStochBuffer, StochHandle, values_to_copy)) return (0);

    if (prev_calculated == rates_total) return rates_total;

    int start = (prev_calculated < 1) ? 0 : prev_calculated - 1;
    for (int i = (rates_total - start) - 1; i >= 0; --i) {
        if (i > rates_total - 100) continue;

        double MACD = iMACDBuffer[i];
        double MACD1 = iMACDBuffer[i + 1];
        double Stoch = iStochBuffer[i];

        //Print(time[i], " ", MACD, " ", MACD1);

        if (MACD1 > 0 && MACD < 0 && Stoch > Stochastic_Upper) {
            SellArrow[i] = high[i] + (7 * UsePoint);
            if (i == 1 && Reversal_Tabs_Alerts) SendAlert("Sell Reversal Tab for the " + Symbol());
        }

        if (MACD1 < 0 && MACD > 0 && Stoch < Stochastic_Lower) {
            BuyArrow[i] = low[i] - (7 * UsePoint);
            if (i == 1 && Reversal_Tabs_Alerts) SendAlert("Buy Reversal Tab for the " + Symbol());
        }

        RSISellCheck(i);
        RSIBuyCheck(i);
    }
    return rates_total;
}

/*
int start()
{
   int counted_bars = (IndicatorCounted()+1);
   int uncounted_bars = Bars - counted_bars;
   
   for(int i=uncounted_bars; i>=1; i--)
   {
      double MACD = iMACD(Symbol(),0,FastMAPeriod,SlowMAPeriod,SignalMAPeriod,PRICE_CLOSE,MODE_MAIN,i);
      double MACD1 = iMACD(Symbol(),0,FastMAPeriod,SlowMAPeriod,SignalMAPeriod,PRICE_CLOSE,MODE_MAIN,i+1);
      double Stoch = iStochastic(Symbol(),0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,i);

      if(MACD1>0 && MACD<0 && Stoch>Stochastic_Upper)
      {
         SellArrow[i]=High[i]+(7*UsePoint);
         if(i==1 && Reversal_Tabs_Alerts) SendAlert("Sell Reversal Tab for the "+Symbol());
      }   

      if(MACD1<0 && MACD>0 && Stoch<Stochastic_Lower)
      {
         BuyArrow[i]=Low[i]-(7*UsePoint);
         if(i==1 && Reversal_Tabs_Alerts) SendAlert("Buy Reversal Tab for the "+Symbol());
      }

      RSISellCheck(i);
      RSIBuyCheck(i);
   }


return(0);
}
*/

void RSISellCheck(int Loc) {
    bool UseKDSAlt = false;
    bool UseKDSAlt1 = false;

    double RSIMain = iRSIBuffer[Loc];
    if (RSIMain < 50) {
        Sell[Loc] = EMPTY_VALUE;
        return;
    }
    for (int x = Loc; x <= Loc + 2; x++) {
        if (iHigh(NULL, 0, x) > iHigh(NULL, 0, Loc)) {
            Sell[Loc] = EMPTY_VALUE;
            return;
        }
    }
    for (int y = Loc + 4; y <= (Loc + CandlesBack); y++) {
        if (iTime(NULL, 0, y) < LastKDS) UseKDSAlt = true;
        if (iTime(NULL, 0, y) < LastKDSA) {
            UseKDSAlt = false;
            UseKDSAlt1 = true;
        }
        if (iTime(NULL, 0, y) < LastKDSA2) {
            UseKDSAlt1 = false;
        }

        if (y == (Loc + CandlesBack)) {
            Sell[Loc] = EMPTY_VALUE;
            return;
        }
        if (iHigh(NULL, 0, y) > iHigh(NULL, 0, Loc)) {
            Sell[Loc] = EMPTY_VALUE;
            return;
        }
        int s = y;
        for (int z = y - 2; z <= y + 2; z++) {
            if (iHigh(NULL, 0, z) > iHigh(NULL, 0, y)) {
                y++;
                break;
            }
        }
        if (s != y) {
            y--;
            continue;
        }
        bool OB = false;
        for (int k = Loc; k <= y; k++) {
            double RSIOB = iRSIBuffer[k];
            if (RSIOB > 70) {
                OB = true;
                break;
            }
        }
        if (OB == false) continue;
        double Mom1 = iMomentumBuffer[Loc];
        double Mom2 = iMomentumBuffer[y];
        if (Mom1 > Mom2) continue;

        LastKDS = iTime(NULL, 0, Loc);
        if (UseKDSAlt) LastKDSA = iTime(NULL, 0, Loc);
        if (UseKDSAlt1) LastKDSA2 = iTime(NULL, 0, Loc);

        LineDraw(Loc, y, "Sell", UseKDSAlt, UseKDSAlt1);
        if (Loc == 1) {
            SendAlert("New Knoxville Divergence Sell Setup on the " + Symbol());
        }
        return;
    }
}
void RSIBuyCheck(int Loc) {
    bool UseKDBAlt = false;
    bool UseKDBAlt1 = false;
    double RSIMain = iRSIBuffer[Loc];
    if (RSIMain > 50) {
        Buy[Loc] = EMPTY_VALUE;
        return;
    }
    for (int x = Loc; x <= Loc + 2; x++) {
        if (iLow(NULL, 0, x) < iLow(NULL, 0, Loc)) {
            Buy[Loc] = EMPTY_VALUE;
            return;
        }
    }
    for (int y = Loc + 4; y <= (Loc + CandlesBack); y++) {
        if (iTime(NULL, 0, y) < LastKDB) UseKDBAlt = true;
        if (iTime(NULL, 0, y) < LastKDBA) {
            UseKDBAlt = false;
            UseKDBAlt1 = true;
        }
        if (iTime(NULL, 0, y) < LastKDBA2) {
            UseKDBAlt1 = false;
        }

        if (y == (Loc + CandlesBack)) {
            Buy[Loc] = EMPTY_VALUE;
            return;
        }
        if (iLow(NULL, 0, y) < iLow(NULL, 0, Loc)) {
            Buy[Loc] = EMPTY_VALUE;
            return;
        }
        int s = y;
        for (int z = y - 2; z <= y + 2; z++) {
            if (iLow(NULL, 0, z) < iLow(NULL, 0, y)) {
                y++;
                break;
            }
        }
        if (s != y) {
            y--;
            continue;
        }
        bool OB = false;
        for (int k = Loc; k <= y; k++) {
            double RSIOB = iRSIBuffer[k];
            if (RSIOB < 30) {
                OB = true;
                break;
            }
        }
        if (OB == false) continue;
        double Mom1 = iMomentumBuffer[Loc];
        double Mom2 = iMomentumBuffer[y];
        if (Mom1 < Mom2) continue;

        LastKDB = iTime(NULL, 0, Loc);
        if (UseKDBAlt) LastKDBA = iTime(NULL, 0, Loc);
        if (UseKDBAlt1) LastKDBA2 = iTime(NULL, 0, Loc);

        LineDraw(Loc, y, "Buy", UseKDBAlt, UseKDBAlt1);
        if (Loc == 1) {
            SendAlert("New Knoxville Divergence Buy Setup on the " + Symbol());
        }
        return;
    }
}

void LineDraw(int Start, int Finish, string BuySell, bool UseAlt, bool UseAlt2) {
    double Slope;
    if (BuySell == "Buy") {
        Slope = (iLow(NULL, 0, Start) - iLow(NULL, 0, Finish)) / (Start - Finish);
        double StartBuy = iLow(NULL, 0, Start);
        for (int x = 0; x <= (Finish - Start); x++) {
            StartBuy += Slope;
            if (!UseAlt && !UseAlt2) Buy[Start + x] = StartBuy;
            if (UseAlt) BuyAlt[Start + x] = StartBuy;
            if (UseAlt2) BuyAlt1[Start + x] = StartBuy;
        }
        for (int i = Finish + 1; i < Bars(_Symbol, _Period); i++) {
            if (Buy[i] == EMPTY_VALUE && !UseAlt && !UseAlt2) return;
            if (BuyAlt[i] == EMPTY_VALUE && UseAlt) return;
            if (BuyAlt1[i] == EMPTY_VALUE && UseAlt2) return;
            if (!UseAlt && !UseAlt2) Buy[i] = EMPTY_VALUE;
            if (UseAlt) BuyAlt[i] = EMPTY_VALUE;
            if (UseAlt2) BuyAlt1[i] = EMPTY_VALUE;
        }
    }
    if (BuySell == "Sell") {
        Slope = (iHigh(NULL, 0, Start) - iHigh(NULL, 0, Finish)) / (Start - Finish);
        double StartSell = iHigh(NULL, 0, Start);
        for (int y = 0; y <= (Finish - Start); y++) {
            StartSell += Slope;
            if (!UseAlt && !UseAlt2) Sell[Start + y] = StartSell;
            if (UseAlt) SellAlt[Start + y] = StartSell;
            if (UseAlt2) SellAlt1[Start + y] = StartSell;
        }
        for (int n = Finish + 1; n < Bars(_Symbol, _Period); n++) {
            if (!UseAlt && !UseAlt2 && Sell[n] == EMPTY_VALUE) return;
            if (UseAlt && SellAlt[n] == EMPTY_VALUE) return;
            if (UseAlt2 && SellAlt1[n] == EMPTY_VALUE) return;
            if (!UseAlt && !UseAlt2) Sell[n] = EMPTY_VALUE;
            if (UseAlt) SellAlt[n] = EMPTY_VALUE;
            if (UseAlt2) SellAlt1[n] = EMPTY_VALUE;
        }
    }
    return;
}
double PipPoint(string Currency) {
    double CalcPoint = 0.01;
    int CalcDigits = Digits();
    if (CalcDigits == 2 || CalcDigits == 3)
        CalcPoint = 0.01;
    else if (CalcDigits == 4 || CalcDigits == 5)
        CalcPoint = 0.0001;
    return (CalcPoint);
}
void SendAlert(string Message) {
    if (Mail_Alert) SendMail("New Knoxville Alert", Message);
    if (PopUp_Alert) Alert(Message);
    if (Sound_Alert) PlaySound("alert.wav");
    if (SmartPhone_Notifications) SendNotification(Message);
    return;
}

bool FillArrayFromBuffer(double &rsi_buffer[],  // indicator buffer of Relative Strength Index values
                         int ind_handle,        // handle of the iRSI indicator
                         int amount             // number of copied values
) {
    //--- reset error code
    ResetLastError();
    //--- fill a part of the iRSIBuffer array with values from the indicator buffer that has 0 index
    if (CopyBuffer(ind_handle, 0, 0, amount, rsi_buffer) < 0) {
        //--- if the copying fails, tell the error code
        PrintFormat("Failed to copy data from the iRSI indicator, error code %d", GetLastError());
        //--- quit with zero result - it means that the indicator is considered as not calculated
        return (false);
    }
    //--- everything is fine
    return (true);
}