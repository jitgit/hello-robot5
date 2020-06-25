//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property strict

#include <devd/include-base.mqh>

/**
* Calculate price based on pip distance from Ask/Bid. 
* Stop loss is zero as on counter order need to be manually cancel. May be that can be automated (TODO)
*/
class EconomicEventPricer {
   protected:
    double itsTakeProfitRatio;

   public:
    EconomicEventPricer(double takeProfitRatio = 3.0) {
        itsTakeProfitRatio = takeProfitRatio;
    }

    void addEntryStopLossAndTakeProfit(SignalResult &scanResult, int pipDistance) {
        double stopLoss = 0;
        double takeProfit = 0;
        double Ask = normalizeAsk(_Symbol);
        double Bid = normalizeBid(_Symbol);
        debug(StringFormat("Calculating SL for %s", scanResult.str()));
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        debug(StringFormat("Ask: %f, Bid: %f, Point(%f), Pip Distance(%d)", Ask, Bid, point, pipDistance));

        if (scanResult.go != GO_NOTHING) {
            scanResult.SL = 0;    //The pips are irrelavent as SL is at BE
            scanResult.TP = 300;  // TODO can be 300 as in case of Economic Event there is expected a huge spike

            if (scanResult.go == GO_LONG) {
                scanResult.entry = Ask + (pipDistance * point);         //Closes to ASK for a Pending order
                scanResult.stopLoss = 0;                                //SL at BE, as we will have a sudden spike from news event
                scanResult.takeProfit = Bid + (scanResult.TP * point);  //
            }

            if (scanResult.go == GO_SHORT) {
                scanResult.entry = Bid - (pipDistance * point);  //Closes to BID for a Pending order
                scanResult.stopLoss = 0;                         //SL at BE, as we will have a sudden spike from news event
                scanResult.takeProfit = Ask - (scanResult.TP * point);
            }
        }
        PrintFormat("%s ==> Updated Scan %s", tsDate(TimeCurrent()), scanResult.str());
    }
};
//+------------------------------------------------------------------+
