
#property strict

#include <Trade\AccountInfo.mqh>
#include <devd\include-base.mqh>

input int Slippage = 30;  //Slippage, points

class OrderManager {
   public:
    bool isSignalValid(SignalResult &signal) {
        return ((signal.go == GO_LONG || signal.go == GO_SHORT) && signal.entry > 0 && signal.stopLoss > 0 && signal.takeProfit > 0 && signal.SL > 0 && signal.TP > 0);
    }

    void bookTrade(SignalResult &signal, double lotSize, int magicNumber, int slippage = 30, string comment = "")  //TODO use a strategy for slippage
    {
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return;
        }

        if (!isSignalValid(signal)) {
            warn("Invalid Signal. " + signal.str());
            return;
        }
        bookTrade(signal.go == GO_LONG, signal.entry, signal.stopLoss, signal.takeProfit, lotSize, magicNumber, slippage, comment);
    }

    void bookTrade(bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, int slippage = 30, string comment = "")  //TODO use a strategy for slippage
    {
        //TODO check that stoploss diff is great than STOP_LEVEL
        if (!isTradingAllowed()) {
            warn("Auto trading is not allowed, or trading hours not active");
            return;
        }
        ResetLastError();
        MqlTradeRequest request;
        MqlTradeResult result;
        MqlTradeCheckResult check;
        ZeroMemory(request);
        ZeroMemory(result);
        ZeroMemory(check);

        request.price = entry;
        request.action = TRADE_ACTION_PENDING;  // setting a pending order
        request.symbol = _Symbol;
        request.volume = lotSize;
        request.magic = magicNumber;  // ORDER_MAGIC

        request.tp = takeProfit;
        request.sl = stoploss;
        request.type_filling = ORDER_FILLING_FOK;
        request.deviation = slippage;

        if (isLong) {
            request.type = ORDER_TYPE_BUY_LIMIT;
            request.comment = StringFormat("(%d) Buy. %s", magicNumber, comment);
        } else {
            request.type = ORDER_TYPE_SELL_LIMIT;
            request.comment = StringFormat("(%d) Sell. %s", magicNumber, comment);
        }

        if (!OrderCheck(request, check)) {
            Print("Error on OrderCheck :", ResultRetcodeDescription(check.retcode));
        }

        bool success = OrderSend(request, result);
        log(StringFormat("Result Code=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order));

        if (!success || result.retcode != TRADE_RETCODE_DONE) {
            int errorId = GetLastError();
            error(StringFormat("REJECTED. Error: %d(%s)", result.retcode, ResultRetcodeDescription(result.retcode)));
        } else
            info("Order ID, SUCCESSFUL");
    }

    int getTotalOrderByMagicNum(int magicNumber) {
        int result = 0;
        int totalOrder = PositionsTotal();
        debug(StringFormat("%s Magic(%d), Total Position : %d", _Symbol, magicNumber, totalOrder));
        for (int i = 0; i < totalOrder; i++) {
            if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                result++;
            }
        }
        return result;
    }

    int CloseAllBuy(int magicNumber) {
        MqlTradeRequest request;
        MqlTradeResult result;
        int total = PositionsTotal();
        for (int i = total - 1; i >= 0; i--) {
            ulong position_ticket = PositionGetTicket(i);                                     // position ticket
            string position_symbol = PositionGetString(POSITION_SYMBOL);                      // symbol
            int digits = (int)SymbolInfoInteger(position_symbol, SYMBOL_DIGITS);              // number of decimal places
            ulong magic = PositionGetInteger(POSITION_MAGIC);                                 // position magic number позиции
            double volume = PositionGetDouble(POSITION_VOLUME);                               // position volume
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // position type

            if ((position_symbol == _Symbol) && (type == POSITION_TYPE_BUY) && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                ZeroMemory(request);
                ZeroMemory(result);

                request.action = TRADE_ACTION_DEAL;
                request.position = position_ticket;
                request.symbol = position_symbol;
                request.volume = volume;
                request.deviation = Slippage;
                request.magic = magic;

                request.price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
                request.type = ORDER_TYPE_SELL;

                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // if unable to send the request, output the error code
            }
        }
        return (0);
    }

    int CloseAllSell(int magicNumber) {
        MqlTradeRequest request;
        MqlTradeResult result;
        int total = PositionsTotal();
        for (int i = total - 1; i >= 0; i--) {
            ulong position_ticket = PositionGetTicket(i);                                     // position ticket
            string position_symbol = PositionGetString(POSITION_SYMBOL);                      // symbol
            int digits = (int)SymbolInfoInteger(position_symbol, SYMBOL_DIGITS);              // number of decimal places
            ulong magic = PositionGetInteger(POSITION_MAGIC);                                 // position magic number позиции
            double volume = PositionGetDouble(POSITION_VOLUME);                               // position volume
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // position type

            if ((position_symbol == _Symbol) && (type == POSITION_TYPE_SELL) && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
                //--- zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);
                //--- set the operation parameters
                request.action = TRADE_ACTION_DEAL;
                request.position = position_ticket;
                request.symbol = position_symbol;
                request.volume = volume;
                request.deviation = Slippage;
                request.magic = magic;

                request.price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
                request.type = ORDER_TYPE_BUY;

                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // if unable to send the request, output the error code
            }
        }
        return (0);
    }
};
