
#property strict

#include <devd\include-base.mqh>

input int Slippage = 30;  //Slippage, points

class TradeManager {
   protected:
    bool itsCloseCounter;

   public:
    TradeManager(bool closeCounter = true) {
        itsCloseCounter = closeCounter;
    }

    void closeCounterTrades(SignalResult &signal, int magicNumber) {
        if (itsCloseCounter) {
            if (signal.go == GO_LONG) {
                info("Closing All Sell Trade as we gone into long posistion");
                CloseAllSellPosition(magicNumber);
            } else if (signal.go == GO_SHORT) {
                info("Closing All Buy Trade as we gone into Short posistion");
                CloseAllBuyPosition(magicNumber);
            }
        }
    }

    int CloseAllBuyPosition(int magicNumber) {
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

            if ((position_symbol == _Symbol) && (type == POSITION_TYPE_BUY) && magic == magicNumber) {
                ZeroMemory(request);
                ZeroMemory(result);

                request.action = TRADE_ACTION_DEAL;
                request.position = position_ticket;
                request.symbol = position_symbol;
                request.volume = volume;
                request.deviation = Slippage;
                request.magic = magic;
                request.comment = StringFormat("(%d) Closing due to counter Trade taken", magicNumber);
                request.price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
                request.type = ORDER_TYPE_SELL;

                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // if unable to send the request, output the error code
            }
        }
        return (0);
    }

    int CloseAllSellPosition(int magicNumber) {
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

            if ((position_symbol == _Symbol) && (type == POSITION_TYPE_SELL) && magic == magicNumber) {
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
                request.comment = StringFormat("(%d) Closing due to counter Trade taken", magicNumber);

                request.price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
                request.type = ORDER_TYPE_BUY;

                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // if unable to send the request, output the error code
            }
        }
        return (0);
    }
};
