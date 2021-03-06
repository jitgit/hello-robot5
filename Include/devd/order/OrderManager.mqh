
#property strict

#include <Trade\Trade.mqh>
#include <devd\include-base.mqh>

class OrderManager {
   private:
    CTrade *getTradeInstance(int magicNumber, int deviation) {
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
            error(StringFormat("ERROR: %d(%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription()));
        } else {
            info(StringFormat("Trade Executed successfully. Result(%d) - %s", trade.ResultRetcode(), trade.ResultRetcodeDescription()));
        }
    }

   public:
    bool isSignalValidForLimitOrder(SignalResult &signal) {
        return ((signal.go == GO_LONG || signal.go == GO_SHORT) && signal.entry > 0 && signal.stopLoss > 0 && signal.takeProfit > 0 && signal.SL > 0 && signal.TP > 0);
    }

    bool bookLimitOrder(SignalResult &signal, double lotSize, int magicNumber, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isSignalValidForLimitOrder(signal)) {
            warn("Invalid Signal. " + signal.str());
            return false;
        }
        return bookLimitOrder(signal.symbol, signal.go == GO_LONG, signal.entry, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, deviation, comment);
    }

    bool bookLimitOrder(string symbol, bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return false;
        }

        ResetLastError();

        CTrade trade = getTradeInstance(magicNumber, deviation);
        bool excutionResult = false;

        if (isLong) {
            excutionResult = trade.BuyLimit(lotSize, entry, symbol, stoploss, takeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d)%s", magicNumber, comment));
        } else {
            excutionResult = trade.SellLimit(lotSize, entry, symbol, stoploss, takeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d)%s", magicNumber, comment));
        }

        printResult(trade, excutionResult);
        return excutionResult;
    }

    //==================================================================================================================
    //==================================================================================================================
    bool isSignalValidForMarketOrder(SignalResult &signal) {
        return ((signal.go == GO_LONG || signal.go == GO_SHORT) && signal.entry > 0 && signal.stopLoss > 0 && signal.takeProfit > 0 && signal.SL > 0 && signal.TP > 0);
    }

    bool bookMarketOrder(SignalResult &signal, double lotSize, int magicNumber, string comment = "", int deviation = 30)  //TODO use a strategy for slippage
    {
        if (!isSignalValidForMarketOrder(signal)) {
            warn("Invalid Signal. " + signal.str());
            return false;
        }
        return bookMarketOrder(signal.symbol, signal.go == GO_LONG, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, comment, deviation);
    }

    bool bookMarketOrder(string symbol, bool isLong, double stoploss, double takeProfit, double lotSize, int magicNumber, string comment = "", int deviation = 30)  //TODO use a strategy for slippage
    {
        //TODO check that stoploss diff is great than STOP_LEVEL
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return false;
        }

        ResetLastError();
        CTrade trade = getTradeInstance(magicNumber, deviation);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digit = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));

        bool excutionResult = false;
        if (isLong) {
            double Ask = normalizeAsk(symbol);
            excutionResult = trade.Buy(lotSize, symbol, Ask, stoploss, takeProfit, StringFormat("(%d)%s", magicNumber, comment));
        } else {
            double Bid = normalizeBid(_Symbol);
            excutionResult = trade.Sell(lotSize, symbol, Bid, stoploss, takeProfit, StringFormat("(%d)%s", magicNumber, comment));
        }

        printResult(trade, excutionResult);
        return excutionResult;
    }

    //==================================================================================================================
    //==================================================================================================================
    bool isSignalValidForStopOrder(SignalResult &signal) {
        //SL can be zero
        return ((signal.go == GO_LONG || signal.go == GO_SHORT) && signal.entry > 0 && signal.takeProfit > 0 && signal.TP > 0);
    }

    bool bookStopOrder(SignalResult &signal, double lotSize, int magicNumber, bool setStopLoss = true, bool setTakeProfit = true, string comment = "", int deviation = 30)  //TODO use a strategy for slippage
    {
        if (!isSignalValidForStopOrder(signal)) {
            warn("Invalid Signal. " + signal.str());
            return false;
        }
        return bookStopOrder(signal.symbol, signal.go == GO_LONG, signal.entry, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, setStopLoss, setTakeProfit, comment, deviation);
    }

    bool bookStopOrder(string symbol, bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, bool setStopLoss = true, bool setTakeProfit = true, string comment = "", int deviation = 30)  //TODO use a strategy for slippage
    {
        //TODO check that stoploss diff is great than STOP_LEVEL
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return false;
        }

        if (!setStopLoss || !setTakeProfit) {
            warn("Stoploss and/or TakeProfit will not be set for this trade. setStopLoss(" + setStopLoss + "), setTakeProfit(" + setTakeProfit + ")");
        }

        ResetLastError();
        CTrade *trade = getTradeInstance(magicNumber, deviation);

        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digit = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));

        double actualStopLoss = setStopLoss ? stoploss : 0.00;
        double actualTakeProfit = setTakeProfit ? takeProfit : 0.00;
        bool excutionResult = false;
        if (isLong) {
            excutionResult = trade.BuyStop(lotSize, entry, symbol, actualStopLoss, actualTakeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d)%s", magicNumber, comment));
        } else {
            excutionResult = trade.SellStop(lotSize, entry, symbol, actualStopLoss, actualTakeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d)%s", magicNumber, comment));
        }

        printResult(trade, excutionResult);
        return excutionResult;
    }

    //==================================================================================================================
    //==================================================================================================================
    int getTotalOrderByMagicNum(string symbol, int magicNumber) {
        int result = 0;
        int totalOrder = OrdersTotal();
        ulong order_ticket;
        for (int i = 0; i < totalOrder; i++) {
            if ((order_ticket = OrderGetTicket(i)) > 0) {
                if (OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_MAGIC) == magicNumber) {
                    result++;
                }
            }
        }
        debug(StringFormat("%s Magic(%d), Total Position : %d", symbol, magicNumber, totalOrder));
        return result;
    }

    //+------------------------------------------------------------------+
    //| Deletes all pending orders with specified ORDER_MAGIC            |
    //+------------------------------------------------------------------+
    void DeleteAllOrdersBy(string symbol, long const magic_number, ENUM_ORDER_TYPE orderTypeToDelete, ulong placedOrderId) {
        ulong order_ticket;
        info(StringFormat("DeleteAllOrdersBy Input Symbol(%s), Magic(%d), Placed order Id(%d),  Type:%s", symbol, magic_number, placedOrderId, EnumToString(orderTypeToDelete)));

        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if ((order_ticket = OrderGetTicket(i)) > 0) {
                debug(StringFormat("Checking order_ticket(%d), magic(%d), OrderSymbol(%s), OrderType(%d)", order_ticket, OrderGetInteger(ORDER_MAGIC), OrderGetString(ORDER_SYMBOL), OrderGetInteger(ORDER_TYPE)));
                if (magic_number == OrderGetInteger(ORDER_MAGIC) && OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_TYPE) == orderTypeToDelete) {
                    MqlTradeResult result = {0};
                    MqlTradeRequest request = {0};
                    request.order = order_ticket;
                    request.action = TRADE_ACTION_REMOVE;
                    request.comment = StringFormat("Counter Trade of %d  Removed", placedOrderId);
                    OrderSend(request, result);
                    info(StringFormat("Removing Trade(%d) %s - %s  - magic(%d). Result: %s", order_ticket, symbol, EnumToString(orderTypeToDelete), magic_number, result.comment));
                }
            }
        }
    }
};
