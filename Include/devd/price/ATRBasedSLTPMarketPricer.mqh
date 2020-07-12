//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property strict

#include <devd/include-base.mqh>

class ATRBasedSLTPMarketPricer {
   protected:
    double itsScale;
    double itsTakeProfitRatio;
    int itAtrMAPeriod;

   public:
    ATRBasedSLTPMarketPricer(int atrMAPeriod, double scale = 1.5, double takeProfitRatio = 3.0) {
        itsScale = scale;
        itAtrMAPeriod = atrMAPeriod;
        itsTakeProfitRatio = takeProfitRatio;
    }

    void addEntryStopLossAndTakeProfit(SignalResult& signal, ENUM_TIMEFRAMES tf) {
        double stopLoss = 0;
        double takeProfit = 0;
        double ATRValue[];                                       // Variable to store the value of ATR
        int ATRHandle = iATR(signal.symbol, tf, itAtrMAPeriod);  // returns a handle for ATR
        SymbolData* s = new SymbolData(signal.symbol);
        debug(StringFormat("Signal %s , Symbol:%s", signal.str(), s.str()));

        ArraySetAsSeries(ATRValue, true);
        int atrCopyCount = CopyBuffer(ATRHandle, 0, 0, 1, ATRValue);
        if (atrCopyCount > 0 && signal.go != GO_NOTHING) {
            double atrValue = ATRValue[0];
            debug(StringFormat("ATR (%f), SL = %2.2f x ATR, TP = %2.2f x SL ", atrValue, itsScale, itsTakeProfitRatio));

            //SL = 2* atr & TP = 3 * SL; (1:3)
            if (signal.go == GO_LONG) {
                signal.entry = s.ask - (50 * s.point);  //Closes to ASK for a Pending order
                signal.stopLoss = s.ask - (itsScale * atrValue);
                signal.takeProfit = s.bid + (itsTakeProfitRatio * itsScale * atrValue);
            }

            if (signal.go == GO_SHORT) {
                signal.entry = s.bid + (60 * s.point);  //Closes to BID for a Pending order
                signal.stopLoss = s.bid + (itsScale * atrValue);
                signal.takeProfit = s.ask - (itsTakeProfitRatio * itsScale * atrValue);
            }
            signal.SL = MathAbs(signal.entry - signal.stopLoss) / s.point;
            signal.TP = MathAbs(signal.entry - signal.takeProfit) / s.point;
        } else {
            warn(StringFormat("There was no signal (long/short) specified or atr copy failed copied(%d)", atrCopyCount));
        }
        debug(StringFormat("%s - UPDATED Signal %s", tsDate(TimeCurrent()), signal.str()));
    }
};
//+------------------------------------------------------------------+
