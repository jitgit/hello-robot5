#property strict

#include <devd/include-base.mqh>
#include <devd/indicator-buffers.mqh>
int STOCH_LIMIT_UPPER_BOUND = 75;
int STOCH_LIMIT_LOWER_BOUND = 25;
class StochasticLimitsScanner : public SignalScanner {
   protected:
    int itsKPeriod;
    int itsDPeriod;
    int itsSlowing;

   public:
    StochasticLimitsScanner(int kPeriod = 30, int dPeriod = 10, int slowing = 10) {
        itsKPeriod = kPeriod;
        itsDPeriod = dPeriod;
        itsSlowing = slowing;
    }

    SignalResult* scan(string symbol, ENUM_TIMEFRAMES timeFrame) {
        SignalResult* result = new SignalResult(symbol);

        double mainBuffer[];
        double signalBuffer[];
        datetime ts[];

        ArraySetAsSeries(ts, true);
        int handle = iStochastic(symbol, timeFrame, itsKPeriod, itsDPeriod, itsSlowing, MODE_EMA, STO_CLOSECLOSE);
        CopyTime(symbol, timeFrame, 0, 1, ts);
        GetStochasticBuffers(handle, 0, 1, mainBuffer, signalBuffer);

        double stocValue0 = mainBuffer[0];
        double signalValue0 = signalBuffer[0];
        if (stocValue0 >= STOCH_LIMIT_UPPER_BOUND || signalValue0 >= STOCH_LIMIT_UPPER_BOUND) {
            result.go = GO_SHORT;
        } else if (stocValue0 <= STOCH_LIMIT_LOWER_BOUND || signalValue0 <= STOCH_LIMIT_LOWER_BOUND) {
            result.go = GO_LONG;
        } else if (stocValue0 < STOCH_LIMIT_UPPER_BOUND && stocValue0 > STOCH_LIMIT_LOWER_BOUND) {
            result.go = GO_NOTHING;
        }

        //info(StringFormat("%s %s ──────────► S0(%f , %f) ───► %s", tsDate(ts[0]), EnumToString(timeFrame), stocValue0, signalValue0, EnumToString(result.go)));

        return result;
    }

    int magic() {
        return 0;
    };
};

//+------------------------------------------------------------------+
