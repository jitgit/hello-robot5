#property strict

#include <devd/include-base.mqh>
#include <devd/indicator-buffers.mqh>
int STOCH_UPPER_BOUND = 65;
int STOCH_LOWER_BOUND = 35;
class StochasticKDCrossOverScanner : public SignalScanner {
   protected:
    int itsKPeriod;
    int itsDPeriod;
    int itsSlowing;
    datetime scanCandle;

   public:
    StochasticKDCrossOverScanner(int kPeriod = 30, int dPeriod = 10, int slowing = 10) {
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
        datetime ts[];

        ArraySetAsSeries(ts, true);
        int handle = iStochastic(symbol, timeFrame, itsKPeriod, itsDPeriod, itsSlowing, MODE_EMA, STO_CLOSECLOSE);

        CopyTime(symbol, timeFrame, 0, 3, ts);
        GetStochasticBuffers(handle, 0, 3, mainBuffer, signalBuffer);

        double stocValue0 = mainBuffer[0];
        double signalValue0 = signalBuffer[0];
        double stocValue1 = mainBuffer[1];
        double signalValue1 = signalBuffer[1];
        if (scanCandle != candleTime || true) {  //|| timeFrame>PERIOD_M30) { //TODO If the TF is smaller than M30 we don't want to send more repeatative signals
            if (stocValue0 < STOCH_UPPER_BOUND && stocValue0 > STOCH_LOWER_BOUND) {
                result.go = GO_NOTHING;
                scanCandle = 0;
            } else if (stocValue1 > signalValue1 && stocValue0 <= signalValue0 && stocValue0 < stocValue1) {
                result.go = GO_SHORT;
                scanCandle = candleTime;
            } else if (stocValue1 < signalValue1 && stocValue0 >= signalValue0 && stocValue0 > stocValue1) {
                result.go = GO_LONG;
                scanCandle = candleTime;
            }
        }

        /*if (result.go != GO_NOTHING) {
            info(StringFormat("#### %s - %s",tsDate(candleTime), EnumToString(result.go)));
            info(StringFormat("%s S0(%f , %f)", tsDate(ts[0]), stocValue0, signalValue0));
            info(StringFormat("%s S1(%f , %f)", tsDate(ts[1]), stocValue1, signalValue1));
        }*/
        return result;
    }

    int magic() {
        return 0;
    };
};

//+------------------------------------------------------------------+
