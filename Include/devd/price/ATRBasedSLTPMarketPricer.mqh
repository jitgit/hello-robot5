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
        info(StringFormat("Signal %s , Symbol:%s", signal.str(), s.str()));

        ArraySetAsSeries(ATRValue, true);

        if (CopyBuffer(ATRHandle, 0, 0, 1, ATRValue) > 0 && signal.go != GO_NOTHING) {
            double atrValue = ATRValue[0];
            info(StringFormat("ATR (%f), SL = %2.2f x ATR, TP = %2.2f x SL ", atrValue, itsScale, itsTakeProfitRatio));

            //SL = 2* atr & TP = 3 * SL; (1:3)
            if (signal.go == GO_LONG) {
                signal.entry = s.Ask - (50 * s.point);  //Closes to ASK for a Pending order
                signal.stopLoss = s.Ask - (itsScale * atrValue);
                signal.takeProfit = s.Bid + (itsTakeProfitRatio * itsScale * atrValue);
            }

            if (signal.go == GO_SHORT) {
                signal.entry = s.Bid + (60 * s.point);  //Closes to BID for a Pending order
                signal.stopLoss = s.Bid + (itsScale * atrValue);
                signal.takeProfit = s.Ask - (itsTakeProfitRatio * itsScale * atrValue);
            }
            signal.SL = MathAbs(signal.entry - signal.stopLoss) / s.point;
            signal.TP = MathAbs(signal.entry - signal.takeProfit) / s.point;
        } else {
            warn("There was no signal (long/short) specified");
        }
        info(StringFormat("%s - UPDATED Signal %s", tsDate(TimeCurrent()), signal.str()));
    }
};
//+------------------------------------------------------------------+
