
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
        return bookLimitOrder(signal.go == GO_LONG, signal.entry, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, deviation, comment);
    }

    bool bookLimitOrder(bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return false;
        }

        ResetLastError();

        CTrade trade = getTradeInstance(magicNumber, deviation);
        bool excutionResult = false;

        if (isLong) {
            excutionResult = trade.BuyLimit(lotSize, entry, _Symbol, stoploss, takeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d) Buy. %s", magicNumber, comment));
        } else {
            excutionResult = trade.SellLimit(lotSize, entry, _Symbol, stoploss, takeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d) Sell. %s", magicNumber, comment));
        }

        printResult(trade, excutionResult);
        return excutionResult;
    }

    //==================================================================================================================
    //==================================================================================================================
    bool isSignalValidForMarketOrder(SignalResult &signal) {
        return ((signal.go == GO_LONG || signal.go == GO_SHORT) && signal.entry > 0 && signal.stopLoss > 0 && signal.takeProfit > 0 && signal.SL > 0 && signal.TP > 0);
    }

    bool bookMarketOrder(SignalResult &signal, double lotSize, int magicNumber, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isSignalValidForMarketOrder(signal)) {
            warn("Invalid Signal. " + signal.str());
            return false;
        }
        return bookMarketOrder(signal.go == GO_LONG, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, deviation, comment);
    }

    bool bookMarketOrder(bool isLong, double stoploss, double takeProfit, double lotSize, int magicNumber, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        //TODO check that stoploss diff is great than STOP_LEVEL
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return false;
        }

        ResetLastError();
        CTrade trade = getTradeInstance(magicNumber, deviation);
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        int digit = int(SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));

        bool excutionResult = false;
        if (isLong) {
            double Ask = normalizeAsk(_Symbol);
            excutionResult = trade.Buy(lotSize, _Symbol, Ask, stoploss, takeProfit, StringFormat("(%d) Market Buy. %s", magicNumber, comment));
        } else {
            double Bid = normalizeBid(_Symbol);
            excutionResult = trade.Sell(lotSize, _Symbol, Bid, stoploss, takeProfit, StringFormat("(%d) Market Sell. %s", magicNumber, comment));
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

    bool bookStopOrder(SignalResult &signal, double lotSize, int magicNumber, bool setStopLoss = true, bool setTakeProfit = true, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isSignalValidForStopOrder(signal)) {
            warn("Invalid Signal. " + signal.str());
            return false;
        }
        return bookStopOrder(signal.go == GO_LONG, signal.entry, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, setStopLoss, setTakeProfit, deviation, comment);
    }

    bool bookStopOrder(bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, bool setStopLoss = true, bool setTakeProfit = true, int deviation = 30, string comment = "")  //TODO use a strategy for slippage
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

        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        int digit = int(SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));

        double actualStopLoss = setStopLoss ? stoploss : 0.00;
        double actualTakeProfit = setTakeProfit ? takeProfit : 0.00;
        bool excutionResult = false;
        if (isLong) {
            excutionResult = trade.BuyStop(lotSize, entry, _Symbol, actualStopLoss, actualTakeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d) Stop Buy. %s", magicNumber, comment));
        } else {
            excutionResult = trade.SellStop(lotSize, entry, _Symbol, actualStopLoss, actualTakeProfit, ORDER_TIME_GTC, 0, StringFormat("(%d) Stop Sell. %s", magicNumber, comment));
        }

        printResult(trade, excutionResult);
        return excutionResult;
    }

    //==================================================================================================================
    //==================================================================================================================
    int getTotalOrderByMagicNum(int magicNumber) {
        int result = 0;
        int totalOrder = OrdersTotal();
        ulong order_ticket;
        for (int i = 0; i < totalOrder; i++) {
            if ((order_ticket = OrderGetTicket(i)) > 0) {
                if (OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == magicNumber) {
                    result++;
                }
            }
        }
        debug(StringFormat("%s Magic(%d), Total Position : %d", _Symbol, magicNumber, totalOrder));
        return result;
    }

    //+------------------------------------------------------------------+
    //| Deletes all pending orders with specified ORDER_MAGIC            |
    //+------------------------------------------------------------------+
    void DeleteAllOrdersByMagic(long const magic_number) {
        ulong order_ticket;
        //--- go through all pending orders
        for (int i = OrdersTotal() - 1; i >= 0; i--)
            if ((order_ticket = OrderGetTicket(i)) > 0)
                //--- order with appropriate ORDER_MAGIC
                if (magic_number == OrderGetInteger(ORDER_MAGIC)) {
                    MqlTradeResult result = {0};
                    MqlTradeRequest request = {0};
                    request.order = order_ticket;
                    request.action = TRADE_ACTION_REMOVE;
                    OrderSend(request, result);
                    //--- write the server reply to log
                    Print(__FUNCTION__, ": ", result.comment, " reply code ", result.retcode);
                }
        //---
    }
};
