#property strict

#include <devd/include-base.mqh>

class ReversalScanner : public SignalScanner {
   protected:
    double itsEntrySD;
    double itsStopLossSD;
    double itsTakeProfitSD;
    int itsBBPeriod;
    int itsRSIPeriod;
    int itsRSIUpperBound;
    int itsRSILowerBound;

    ReversalScanner(int rsiPeriod, int rsiUpperBound, int rsiLowerBound) {
        itsRSIPeriod = rsiPeriod;
        itsRSIUpperBound = rsiUpperBound;
        itsRSILowerBound = rsiLowerBound;
    }

    bool FillArraysFromBuffers(double &base_values[],   // indicator buffer of the middle line of Bollinger Bands
                               double &upper_values[],  // indicator buffer of the upper border
                               double &lower_values[],  // indicator buffer of the lower border
                               int shift,               // shift
                               int ind_handle,          // handle of the iBands indicator
                               int amount               // number of copied values
    ) {
        ArraySetAsSeries(base_values, true);
        ArraySetAsSeries(upper_values, true);
        ArraySetAsSeries(lower_values, true);
        ResetLastError();
        if (CopyBuffer(ind_handle, 0, -shift, amount, base_values) < 0) {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }

        if (CopyBuffer(ind_handle, 1, -shift, amount, upper_values) < 0) {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }

        if (CopyBuffer(ind_handle, 2, -shift, amount, lower_values) < 0) {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }
        return (true);
    }

   public:
    SignalResult *scan(string symbol) {
        SignalResult *signal = new SignalResult(symbol);  //{GO_NOTHING, -1.0, -1.0, -1.0};

        MqlTick current;
        SymbolInfoTick(signal.symbol, current);

        debug(StringFormat("Ask :%f, Bid :%f", current.ask, current.bid));
        debug(StringFormat("itsBBPeriod(%d), itsRSIPeriod(%d), itsEntrySD(%f), itsStopLossSD:(%f), itsTakeProfitSD:(%f)", itsBBPeriod, itsRSIPeriod, itsEntrySD, itsStopLossSD, itsTakeProfitSD));

        double rsiBuffer[];
        int rsi_handle = iRSI(signal.symbol, _Period, itsRSIPeriod, PRICE_CLOSE);
        CopyBuffer(rsi_handle, 0, 0, 3, rsiBuffer);
        double rsiValue = NormalizeDouble(rsiBuffer[0], 2);
        double open = iOpen(signal.symbol, _Period, 0);

        //TODO check more here
        if (rsiValue < itsRSIUpperBound) {
            signal.go = GO_LONG;
        }
        if (rsiValue > itsRSILowerBound) {
            signal.go = GO_SHORT;
        }

        return signal;
    };

    int magic() {
        return 235;
    };
};

//+------------------------------------------------------------------+
