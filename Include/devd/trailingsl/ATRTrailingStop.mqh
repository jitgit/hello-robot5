#property strict

#include <devd\include-base.mqh>
#include <devd\indicator-buffers.mqh>
#include <devd\trailingsl\TrailingStop.mqh>

class ATRTrailingStop : public TrailingStop {
   private:
    double itsScale;
    double itsPeriod;

   public:
    ATRTrailingStop(int atrPeriod = 14, double scale = 1.5) : TrailingStop("ATR") {
        itsPeriod = atrPeriod;
        itsScale = scale;
    }

    double getAtrValue(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double atrs[1];
        int atr_handle = iATR(symbol, timeFrame, itsPeriod);
        CopyBuffer(atr_handle, 0, 0, 1, atrs);
        return atrs[0];
    }

    double BuyStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double atrValue = getAtrValue(symbol, timeFrame);
        double Ask = normalizeAsk(symbol);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double sl = Ask - (itsScale * atrValue);
        return sl;
    };

    double SellStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double atrValue = getAtrValue(symbol, timeFrame);
        double Bid = normalizeBid(symbol);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double sl = Bid + (itsScale * atrValue);
        return sl;
    };
};
