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

    void addEntryStopLossAndTakeProfit(SignalResult &scanResult) {
        double stopLoss = 0;
        double takeProfit = 0;
        double ATRValue[];                                // Variable to store the value of ATR
        int ATRHandle = iATR(_Symbol, 0, itAtrMAPeriod);  // returns a handle for ATR
        double Ask = normalizeAsk(_Symbol);
        double Bid = normalizeBid(_Symbol);
        PrintFormat("Calculating SL for %s", scanResult.str());
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        PrintFormat("Ask:%f , Bid: %f , Point: %f", Ask, Bid, point);

        ArraySetAsSeries(ATRValue, true);

        if (CopyBuffer(ATRHandle, 0, 0, 1, ATRValue) > 0 && scanResult.go != GO_NOTHING) {
            double atrValue = ATRValue[0];
            PrintFormat("ATR Value %f", atrValue);

            //SL = 2* atr & TP = 3 * SL; (1:3)
            if (scanResult.go == GO_LONG) {
                scanResult.entry = Ask - (10 * point);  //Closes to ASK for a Pending order
                scanResult.stopLoss = Ask - (itsScale * atrValue);
                scanResult.takeProfit = Bid + (itsTakeProfitRatio * itsScale * atrValue);
            }

            if (scanResult.go == GO_SHORT) {
                scanResult.entry = Bid + (10 * point);  //Closes to BID for a Pending order
                scanResult.stopLoss = Bid + (itsScale * atrValue);
                scanResult.takeProfit = Ask - (itsTakeProfitRatio * itsScale * atrValue);
            }
            scanResult.SL = MathAbs(scanResult.entry - scanResult.stopLoss) / point;
            scanResult.TP = MathAbs(scanResult.entry - scanResult.takeProfit) / point;
        }
        PrintFormat("%s ==> Updated Scan %s", tsDate(TimeCurrent()), scanResult.str());
    }
};
//+------------------------------------------------------------------+
