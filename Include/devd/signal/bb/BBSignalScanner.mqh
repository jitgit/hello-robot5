//+------------------------------------------------------------------+
//|                                                 Jatin Patel DevD |
//|                                                 https://devd.com |
//+------------------------------------------------------------------+
#property strict

#include <devd/signal/SignalScanner.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class BBSignalScanner : public SignalScanner
{

protected:
    double itsEntrySD;
    double itsStopLossSD;
    double itsTakeProfitSD;
    int itsBBPeriod;
    int itsRSIPeriod;
    int itsRSIUpperBound;
    int itsRSILowerBound;

    bool FillArraysFromBuffers(double &base_values[],  // indicator buffer of the middle line of Bollinger Bands
                               double &upper_values[], // indicator buffer of the upper border
                               double &lower_values[], // indicator buffer of the lower border
                               int shift,              // shift
                               int ind_handle,         // handle of the iBands indicator
                               int amount              // number of copied values
    )
    {
         ArraySetAsSeries(base_values,true);
         ArraySetAsSeries(upper_values,true);
         ArraySetAsSeries(lower_values,true);
        ResetLastError();
        if (CopyBuffer(ind_handle, 0, -shift, amount, base_values) < 0)
        {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }

        if (CopyBuffer(ind_handle, 1, -shift, amount, upper_values) < 0)
        {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }

        if (CopyBuffer(ind_handle, 2, -shift, amount, lower_values) < 0)
        {
            PrintFormat("Failed to copy data from the iBands indicator, error code %d", GetLastError());
            return (false);
        }
        return (true);
    }

public:
    SignalResult scan()
    {

        MqlTick current;
        SymbolInfoTick(_Symbol, current);

        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};

        debug(StringFormat("Ask :%f, Bid :%f", current.ask, current.bid));
        debug(StringFormat("itsBBPeriod(%d), itsRSIPeriod(%d), itsEntrySD(%f), itsStopLossSD:(%f), itsTakeProfitSD:(%f)", itsBBPeriod, itsRSIPeriod, itsEntrySD, itsStopLossSD, itsTakeProfitSD));

        double entryMidBuffer[], entryLowerBuffer[], entryUpperBuffer[];
        int entryBB_Handle = iBands(_Symbol, _Period, itsBBPeriod, 0, itsEntrySD, PRICE_CLOSE);
        FillArraysFromBuffers(entryMidBuffer, entryUpperBuffer, entryLowerBuffer, 0, entryBB_Handle, 3);

        double stopLossMidBuffer[], stopLossLowerBuffer[], stopLossUpperBuffer[];
        int stopLossBB_Handle = iBands(_Symbol, _Period, itsBBPeriod, 0, itsStopLossSD, PRICE_CLOSE);
        FillArraysFromBuffers(stopLossMidBuffer, stopLossUpperBuffer, stopLossLowerBuffer, 0, stopLossBB_Handle, 3);

        double commonMid = entryMidBuffer[0];

        double entryLower = entryLowerBuffer[0];
        double entryUpper = entryUpperBuffer[0];
        debug(StringFormat("BB Entry (%f, %f, %f)", entryLower, commonMid, entryUpper));

        double stopLossLower = stopLossLowerBuffer[0];
        double stopLossUpper = stopLossUpperBuffer[0];
        debug(StringFormat("BB StopLoss (%f, %f, %f)", stopLossLower, commonMid, stopLossUpper));

        double takeProfitUpper = optimizedLongTP();
        double takeProfitLower = optimizedShortTP();
        debug(StringFormat("BB TakeProfit (%f, %f, %f)", takeProfitLower, commonMid, takeProfitUpper));

        
        double rsiBuffer[];
        int rsi_handle = iRSI(_Symbol, _Period, itsRSIPeriod, PRICE_CLOSE);
        CopyBuffer(rsi_handle, 0, 0, 3, rsiBuffer);
        double rsiValue = NormalizeDouble(rsiBuffer[0], 2);
        double open = iOpen(_Symbol, _Period, 0);
        if (current.ask < entryLower && open > entryLower && current.ask > stopLossLower && rsiValue < itsRSIUpperBound)
        {
            result.go = GO_LONG;
            result.entry = current.ask;
            result.stopLoss = stopLossLower;
            result.takeProfit = takeProfitUpper;
        }
        if (current.bid > entryUpper && open < entryUpper && current.bid<stopLossUpper & rsiValue> itsRSILowerBound)
        {
            result.go = GO_SHORT;
            result.entry = current.bid;
            result.stopLoss = stopLossUpper;
            result.takeProfit = takeProfitLower;
        }

        return result;
    };

    double optimizedLongTP()
    {
        double takeProfitMidBuffer[], takeProfitLowerBuffer[], takeProfitUpperBuffer[];
        int takeProfitBB_Handle = iBands(_Symbol, _Period, itsBBPeriod, 0, itsTakeProfitSD, PRICE_CLOSE);
        FillArraysFromBuffers(takeProfitMidBuffer, takeProfitUpperBuffer, takeProfitLowerBuffer, 0, takeProfitBB_Handle, 3);
        return takeProfitLowerBuffer[0];
    };

    double optimizedShortTP()
    {
        double takeProfitMidBuffer[], takeProfitLowerBuffer[], takeProfitUpperBuffer[];
        int takeProfitBB_Handle = iBands(_Symbol, _Period, itsBBPeriod, 0, itsTakeProfitSD, PRICE_CLOSE);
        FillArraysFromBuffers(takeProfitMidBuffer, takeProfitUpperBuffer, takeProfitLowerBuffer, 0, takeProfitBB_Handle, 3);
        return takeProfitUpperBuffer[0];
    };

    int magicNumber()
    {
        return 9;
    };

    BBSignalScanner(double entrySD, double stopLossSD, double takeProfitSD, int bbPeriod, int rsiPeriod, int rsiUpperBound, int rsiLowerBound)
    {
        itsEntrySD = entrySD;
        itsStopLossSD = stopLossSD;
        itsTakeProfitSD = takeProfitSD;
        itsBBPeriod = bbPeriod;
        itsRSIPeriod = rsiPeriod;
        itsRSIUpperBound = rsiUpperBound;
        itsRSILowerBound = rsiLowerBound;
    }
};

//+------------------------------------------------------------------+
