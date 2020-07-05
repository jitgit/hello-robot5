#property strict

#include <devd/include-base.mqh>
#include <devd/indicator-buffers.mqh>

class StochasticScanner : public SignalScanner {
   protected:
    int itsKPeriod;
    int itsDPeriod;
    int itsSlowing;
    datetime scanCandle;

   public:
    StochasticScanner(int kPeriod = 30, int dPeriod = 10, int slowing = 10) {
        itsKPeriod = kPeriod;
        itsDPeriod = dPeriod;
        itsSlowing = slowing;
        scanCandle = 0;
    }

    SignalResult* scan(string symbol, ENUM_TIMEFRAMES timeFrame) {
        SignalResult* result = new SignalResult(symbol);
        datetime candleTime = iTime(symbol, timeFrame, 0);

        double mainBuffer[];
        double signalBuffer[];
        ArraySetAsSeries(signalBuffer, true);
        ArraySetAsSeries(mainBuffer, true);
        int handle = iStochastic(symbol, timeFrame, itsKPeriod, itsDPeriod, itsSlowing, MODE_SMA, STO_LOWHIGH);
        GetStochasticBuffers(handle, 0, 2, mainBuffer, signalBuffer);
        double stocValue0 = NormalizeDouble(mainBuffer[0], 2);
        double signalValue0 = NormalizeDouble(signalBuffer[0], 2);
        double stocValue1 = NormalizeDouble(mainBuffer[1], 2);
        double signalValue1 = NormalizeDouble(signalBuffer[1], 2);

        if (scanCandle != candleTime) {  //|| timeFrame>PERIOD_M30) { //If the TF is smaller than M30 we don't want to send more repeatative signals
            if (stocValue0 < 70 && stocValue0 > 30) {
                result.go = GO_NOTHING;
                scanCandle = 0;
            } else if (stocValue0 > 70 && stocValue1 > signalValue1 && stocValue0 < signalValue0) {
                result.go = GO_SHORT;
                scanCandle = candleTime;
            } else if (stocValue0 < 30 && stocValue1 < signalValue1 && stocValue0 > signalValue0) {
                result.go = GO_LONG;
                scanCandle = candleTime;
            }
        } else {
        }

        if (result.go != GO_NOTHING) {
            debug(StringFormat("#%s", result.str()));
            debug(StringFormat("%s %s Stoch(%d,%d,%d), S1(%f , %f), S0(%f , %f)", tsDate(candleTime), EnumToString(timeFrame), itsKPeriod, itsDPeriod, itsSlowing, stocValue1, signalValue1, stocValue0, signalValue0));
        }
        return result;
    }

    int magic() {
        return 234;
    };
};

//+------------------------------------------------------------------+
