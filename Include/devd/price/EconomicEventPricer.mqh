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

    void addEntryStopLossAndTakeProfit(SignalResult &signal, int pipDistance) {
        double stopLoss = 0;
        double takeProfit = 0;
        double Ask = normalizeAsk(signal.symbol);
        double Bid = normalizeBid(signal.symbol);
        debug(StringFormat("Calculating SL for %s", signal.str()));
        double point = SymbolInfoDouble(signal.symbol, SYMBOL_POINT);
        debug(StringFormat("Ask: %f, Bid: %f, Point(%f), Pip Distance(%d)", Ask, Bid, point, pipDistance));

        if (signal.go != GO_NOTHING) {
            signal.SL = 0;    //The pips are irrelavent as SL is at BE
            signal.TP = 300;  // TODO can be 300 as in case of Economic Event there is expected a huge spike

            if (signal.go == GO_LONG) {
                signal.entry = Ask + (pipDistance * point);     //Closes to ASK for a Pending order
                signal.stopLoss = 0;                            //SL at BE, as we will have a sudden spike from news event
                signal.takeProfit = Bid + (signal.TP * point);  //
            }

            if (signal.go == GO_SHORT) {
                signal.entry = Bid - (pipDistance * point);  //Closes to BID for a Pending order
                signal.stopLoss = 0;                         //SL at BE, as we will have a sudden spike from news event
                signal.takeProfit = Ask - (signal.TP * point);
            }
        }
        info(StringFormat("%s - UPDATED Scan %s", tsDate(TimeCurrent()), signal.str()));
    }
};
//+------------------------------------------------------------------+
