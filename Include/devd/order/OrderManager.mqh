#property strict
#include <Trade\AccountInfo.mqh>

class OrderManager
{

public:
    bool isTradingAllowed()
    {
        if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {

            Alert("Automated trading is forbidden for the account ", AccountInfoInteger(ACCOUNT_LOGIN),
                  " at the trade server side");
            warn("Auto Trading is disable for Expert Advisor");
            return false;
        }
        else
        {
            //TODO
            /*if (!IsTradeAllowed(_Symbol, TimeCurrent()))
            {
                warn(StringFormat("Trading Hours are closed for %s.", _Symbol));
                return false;
            }*/
        }
        return true;
    }

    void bookTrade(bool isLong, double entry, double stoploss, double takeProfit, double lotSize, int magicNumber, int slippage = 10, string comment = "") //TODO use a strategy for slippage
    {
        //TODO check that stoploss diff is great than STOP_LEVEL
        if (isTradingAllowed())
        {
            long orderId = -1;
            MqlTradeResult result = {0};
            MqlTradeRequest request = {0};
            request.action = TRADE_ACTION_PENDING; // setting a pending order
            request.magic = magicNumber;           // ORDER_MAGIC
            request.symbol = _Symbol;
            request.volume = lotSize;
            request.sl = stoploss;
            request.tp = takeProfit;
            request.price = entry;
            request.deviation = slippage;

            if (isLong)
            {
                request.type = ORDER_TYPE_BUY_LIMIT;
                request.comment = StringFormat("(%d) Buy. %s", magicNumber, comment);
            }
            else
            {
                request.type = ORDER_TYPE_SELL_LIMIT;
                request.comment = StringFormat("(%d) Sell. %s", magicNumber, comment);
            }
            bool success = OrderSend(request, result);

            log(StringFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order));
            if (success)
            {
                int error = GetLastError();
                log(StringFormat("ORDER ID(%d) REJECTED. Error: %d(%s)", orderId, "TODO Error Desc"));
            }
            else
                log(StringFormat("Order ID(%d), SUCCESSFUL", orderId));
        }
        else
        {
            log("Auto trading is not allowed, or trading hours not active");
        }
    }

    int getTotalOrderByMagicNum(int magicNumber, long &orderIds[])
    {
        //TODO
        /*int openOrders = OrdersTotal();
        int index = 0;
        for (int i = 0; i < openOrders; i++)
        {
            if (OrderSelect(i, SELECT_BY_POS) == true)
            {
                if (OrderMagicNumber() == magicNumber)
                {
                    ArrayResize(orderIds, ArraySize(orderIds) + 1);
                    orderIds[index++] = OrderTicket();
                }
            }
        }*/
        return 0; //ArraySize(orderIds);
    }

public:
    OrderManager()
    {
    }
};
