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

    void addEntryStopLossAndTakeProfit(SignalResult &signal) {
        double stopLoss = 0;
        double takeProfit = 0;
        double ATRValue[];                                // Variable to store the value of ATR
        int ATRHandle = iATR(_Symbol, 0, itAtrMAPeriod);  // returns a handle for ATR
        double Ask = normalizeAsk(_Symbol);
        double Bid = normalizeBid(_Symbol);
        info(StringFormat("Calculating SL for %s", signal.str()));
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        info(StringFormat("Ask:%f , Bid: %f , Point: %f", Ask, Bid, point));

        ArraySetAsSeries(ATRValue, true);

        if (CopyBuffer(ATRHandle, 0, 0, 1, ATRValue) > 0 && signal.go != GO_NOTHING) {
            double atrValue = ATRValue[0];
            info(StringFormat("ATR Value %f", atrValue));

            //SL = 2* atr & TP = 3 * SL; (1:3)
            if (signal.go == GO_LONG) {
                signal.entry = Ask - (10 * point);  //Closes to ASK for a Pending order
                signal.stopLoss = Ask - (itsScale * atrValue);
                signal.takeProfit = Bid + (itsTakeProfitRatio * itsScale * atrValue);
            }

            if (signal.go == GO_SHORT) {
                signal.entry = Bid + (10 * point);  //Closes to BID for a Pending order
                signal.stopLoss = Bid + (itsScale * atrValue);
                signal.takeProfit = Ask - (itsTakeProfitRatio * itsScale * atrValue);
            }
            signal.SL = MathAbs(signal.entry - signal.stopLoss) / point;
            signal.TP = MathAbs(signal.entry - signal.takeProfit) / point;
        }
        info(StringFormat("%s - UPDATED Signal %s", tsDate(TimeCurrent()), signal.str()));
    }
};
//+------------------------------------------------------------------+
