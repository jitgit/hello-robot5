#property strict

#include <devd/include-base.mqh>

class RsiScanner : public SignalScanner {
   protected:
    int itsRSIPeriod;
    int itsRSIUpperBound;
    int itsRSILowerBound;
    ENUM_TIMEFRAMES itsTimeFrames[];

   public:
    SignalResult scan() {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};

        double rsiBuffer[];
        int rsi_handle = iRSI(_Symbol, _Period, itsRSIPeriod, PRICE_CLOSE);
        CopyBuffer(rsi_handle, 0, 0, 1, rsiBuffer);
        double rsiValue = NormalizeDouble(rsiBuffer[0], 2);

        debug(StringFormat("RSI(%d)[%d , %d], Current RSI:(%f)", itsRSIPeriod, itsRSILowerBound, itsRSIUpperBound, rsiValue));
        //TODO check more here
        if (rsiValue > itsRSIUpperBound) {
            result.go = GO_SHORT;
        }
        if (rsiValue < itsRSILowerBound) {
            result.go = GO_LONG;
        }

        return result;
    };

    SignalResult scan(ENUM_TIMEFRAMES &timeFrames[]) {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};
        for (int i = 0; i < ArraySize(timeFrames); i++) {
            ENUM_TIMEFRAMES tf = timeFrames[i];
            double rsiBuffer[];
            int rsi_handle = iRSI(_Symbol, tf, itsRSIPeriod, PRICE_CLOSE);
            CopyBuffer(rsi_handle, 0, 0, 1, rsiBuffer);
            double rsiValue = NormalizeDouble(rsiBuffer[0], 2);
            debug(StringFormat("%s, RSI(%d)[%d , %d], Current RSI:(%f)", timFrameToString(tf), itsRSIPeriod, itsRSILowerBound, itsRSIUpperBound, rsiValue));

            if (rsiValue > itsRSIUpperBound) {
                result.go = GO_SHORT;
            } else if (rsiValue < itsRSILowerBound) {
                result.go = GO_LONG;
            }
            if (rsiValue < itsRSIUpperBound && rsiValue > itsRSILowerBound) {
                result.go = GO_NOTHING;
            }
        }

        return result;
    }

    int magicNumber() {
        return 234;
    };

    RsiScanner(int rsiPeriod, int rsiUpperBound, int rsiLowerBound, ENUM_TIMEFRAMES &timeFrames[]) {
        itsRSIPeriod = rsiPeriod;
        itsRSIUpperBound = rsiUpperBound;
        itsRSILowerBound = rsiLowerBound;
        //itsTimeFrames = timeFrames;
    }
};

//+------------------------------------------------------------------+
