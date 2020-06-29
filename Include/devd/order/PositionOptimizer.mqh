#property strict
#include <devd\include-base.mqh>

class PositionOptimizer {
   private:
    int itsTakeProfit;     //TakeProfit, points
    int itsTrailingStart;  //Trailing Start, points
    int itsTrailingStop;   //Trailing Stop, points
    int itsTrailingStep;   //Trailing Step, points
    int itsSL_prof;        //Start BE, points
    int itsSL_lev;         //BE level, points

   public:
    PositionOptimizer(int trailingStop = 0, int trailingStep = 0, int trailingStart = 0, int sL_prof = 0, int sL_lev = 0) {
        itsTrailingStep = trailingStep;
        itsTrailingStop = trailingStop;
        itsTrailingStart = trailingStart;
        itsSL_prof = sL_prof;
        itsSL_lev = sL_lev;
    }

    int trailingStop(int magicNumber) {
        if (itsTrailingStart > 0 && itsTrailingStop > 0) {
            for (int i = 0; i < PositionsTotal(); i++) {
                if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                        ulong ticket = PositionGetTicket(i);
                        double pp = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        double sl = PositionGetDouble(POSITION_SL);
                        double op = PositionGetDouble(POSITION_PRICE_OPEN);
                        double tp = PositionGetDouble(POSITION_TP);

                        if (pp - op >= itsTrailingStart * _Point) {
                            if (sl < pp - (itsTrailingStop + itsTrailingStep) * _Point || sl == 0) {
                                Modify(ticket, pp - itsTrailingStop * _Point, tp, magicNumber);
                            }
                        }
                    }
                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                        ulong ticket = PositionGetTicket(i);
                        double pp = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double sl = PositionGetDouble(POSITION_SL);
                        double op = PositionGetDouble(POSITION_PRICE_OPEN);
                        double tp = PositionGetDouble(POSITION_TP);

                        if (op - pp >= itsTrailingStart * _Point) {
                            if (sl > pp + (itsTrailingStop + itsTrailingStep) * _Point || sl == 0) {
                                Modify(ticket, pp + itsTrailingStop * _Point, tp, magicNumber);
                            }
                        }
                    }
                }
            }

            return 0;
        } else {
            Print("TODO Traling Stop not set . Ref: https://www.mql5.com/en/articles/3215");
            return -1;
        }
    }

    int breakEven(int magicNumber) {
        if (itsSL_prof > 0) {
            for (int i = 0; i < PositionsTotal(); i++) {
                if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                        ulong ticket = PositionGetTicket(i);
                        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double sl = PositionGetDouble(POSITION_SL);
                        double op = PositionGetDouble(POSITION_PRICE_OPEN);
                        double tp = PositionGetDouble(POSITION_TP);
                        if ((bid - op) > itsSL_prof * _Point) {
                            double sl1 = NormalizeDouble(op + (itsSL_lev * _Point), _Digits);
                            if (sl1 != sl) {
                                Modify(ticket, sl1, tp, magicNumber);
                            }
                        }
                    }
                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                        ulong ticket = PositionGetTicket(i);
                        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double sl = PositionGetDouble(POSITION_SL);
                        double op = PositionGetDouble(POSITION_PRICE_OPEN);
                        double tp = PositionGetDouble(POSITION_TP);
                        if ((op - ask) > itsSL_prof * _Point) {
                            double sl1 = NormalizeDouble(op - (itsSL_lev * _Point), _Digits);
                            if (sl1 != sl) {
                                Modify(ticket, sl1, tp, magicNumber);
                            }
                        }
                    }
                }
            }

            return (0);
        } else {
            Print("TODO Break Even not set . Ref: https://www.mql5.com/en/articles/3215");
            return -1;
        }
    }

    int Modify(ulong t, double sl, double tp, int magicNumber) {
        MqlTradeRequest request;
        MqlTradeResult result;
        MqlTradeCheckResult check;
        ZeroMemory(request);
        ZeroMemory(result);
        ZeroMemory(check);
        request.action = TRADE_ACTION_SLTP;
        request.position = t;
        request.symbol = _Symbol;
        request.sl = sl;
        request.tp = tp;
        request.magic = magicNumber;

        if (!OrderCheck(request, check)) {
            Print(__FUNCTION__, "(): Error inputs for trade order");
            Print(__FUNCTION__, "(): OrderCheck(): ", ResultRetcodeDescription(check.retcode));
            return (-1);
        }
        if (!OrderSend(request, result) || result.retcode != TRADE_RETCODE_DONE) {
            Print(__FUNCTION__, "(): Unable to modify");
            Print(__FUNCTION__, "(): Modify(): ", ResultRetcodeDescription(result.retcode));
            return (-1);
        } else if (result.retcode != TRADE_RETCODE_DONE)

        {
            Print(__FUNCTION__, "(): Unable to modify");
            Print(__FUNCTION__, "(): Modify(): ", ResultRetcodeDescription(result.retcode));
            return (-1);
        }

        return (0);
    }
};