#property strict
#include <Trade\Trade.mqh>
#include <devd\include-base.mqh>

class TrailingStop {
   private:
    string itsName;

    CTrade *getTradeInstance(int magicNumber, int deviation = 30) {
        CTrade *trade = new CTrade();
        trade.SetExpertMagicNumber(magicNumber);
        trade.SetDeviationInPoints(deviation);
        trade.SetTypeFilling(ORDER_FILLING_RETURN);
        trade.LogLevel(LOG_LEVEL_ALL);
        trade.SetAsyncMode(true);
        return trade;
    }

    void printResult(CTrade &trade, bool excutionResult) {
        if (!excutionResult) {
            error(StringFormat("ERROR: TrailingStop %d(%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription()));
        } else {
            info(StringFormat("TrailingStop(%s) Modified Successfully. Result(%d) - %s", itsName, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
        }
    }

    bool Modify(ulong t, string symbol, double sl, double tp, int magicNumber) {
        CTrade *trade = getTradeInstance(magicNumber);
        bool executionResult = trade.PositionModify(t, sl, tp);
        printResult(trade, executionResult);
        return executionResult;
    }

   public:
    TrailingStop(string name) {
        itsName = name;
    }
    bool updateTrailingStop(int magicNumber, ENUM_TIMEFRAMES timeFrame = PERIOD_M5) {
        // PrintFormat("Trying Trailing Stop for %d .. PositionsTotal():%d", magicNumber, PositionsTotal());
        for (int i = 0; i < PositionsTotal(); i++) {
            string symbol = PositionGetSymbol(i);
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);  // number of digits after comma for price

            if (PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                ulong ticket = PositionGetTicket(i);

                double currentSL = NormalizeDouble(PositionGetDouble(POSITION_SL), digits);
                double currentTP = PositionGetDouble(POSITION_TP);
                ENUM_POSITION_TYPE position = PositionGetInteger(POSITION_TYPE);

                //PrintFormat("ticket:%d (%s), point(%f), digit(%f) (%s)", ticket, symbol, point, digits, EnumToString(position));
                if (position == POSITION_TYPE_BUY) {
                    double suggestedSL = NormalizeDouble(BuyStoploss(symbol, timeFrame), digits);
                    double minimal = SymbolInfoDouble(symbol, SYMBOL_BID) - point * SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
                    suggestedSL = MathMin(suggestedSL, minimal);  //Minimum allowed
                    debug(StringFormat("ticket:%d %s (%s) suggestedSL(%f), currentSL(%f)", ticket, symbol, EnumToString(position), suggestedSL, currentSL));
                    if (suggestedSL > currentSL) {
                        Modify(ticket, symbol, suggestedSL, currentTP, magicNumber);
                    }
                }

                if (position == POSITION_TYPE_SELL) {
                    double suggestedSL = SellStoploss(symbol, timeFrame);
                    suggestedSL += (SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID));  //adding spread, since Sell is closing by the Ask price
                    suggestedSL = NormalizeDouble(suggestedSL, digits);

                    double minimal = SymbolInfoDouble(symbol, SYMBOL_ASK) + point * SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

                    suggestedSL = MathMin(suggestedSL, minimal);  //Minimum allowed

                    debug(StringFormat("ticket:%d %s (%s) suggestedSL(%f), currentSL(%f)", ticket, symbol, EnumToString(position), suggestedSL, currentSL));
                    if (suggestedSL < currentSL || currentSL == 0) {
                        Modify(ticket, symbol, suggestedSL, currentTP, magicNumber);
                    }
                }
            }
        }
        return true;
    }

    virtual double BuyStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        return 0;
    };
    virtual double SellStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        return 0;
    };
};