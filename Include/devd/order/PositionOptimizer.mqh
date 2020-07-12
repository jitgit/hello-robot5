#property strict
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <devd\include-base.mqh>

class PositionOptimizer {
   private:
    ushort itsStopLoss;      // Stop Loss, in pips (1.00045-1.00055=1 pips)
    ushort itsTakeProfit;    // Take Profit, in pips (1.00045-1.00055=1 pips)
                             //ushort InpTrailingFrequency = 10;      // Trailing, in seconds (< "10" -> only on a new bar)
    ushort itsTrailingStop;  // Trailing Stop (min distance from price to Stop Loss, in pips
    ushort itsTrailingStep;  // Trailing Step, in pips (1.00045-1.00055=1 pips)

    CTrade* getTradeInstance(SymbolData* s, int magicNumber, int deviation = 10) {
        CTrade* trade = new CTrade();
        trade.SetExpertMagicNumber(magicNumber);
        trade.SetDeviationInPoints(deviation);
        trade.SetTypeFilling(ORDER_FILLING_RETURN);
        trade.LogLevel(LOG_LEVEL_ALL);
        trade.SetAsyncMode(true);
        trade.SetMarginMode();
        trade.SetTypeFillingBySymbol(s.Name());
        return trade;
    }

   public:
    PositionOptimizer(ushort trailingStop = 0, ushort trailingStep = 5, ushort trailingStart = 0, ushort stopLoss = 55, ushort takeProfit = 105) {
        itsTrailingStep = trailingStep;
        itsTrailingStop = trailingStop;
        itsStopLoss = stopLoss;
        itsTakeProfit = takeProfit;
    }

    // returns the number of open positions
    int getPositionCount(string symbol, int magicNumber) {
        int result = 0;
        CPositionInfo position;
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            if (position.SelectByIndex(i))
                if (position.Symbol() == symbol && position.Magic() == magicNumber)
                    result++;
        }
        return result;
    }

    int getPendingOrderCount(string symbol, int magicNumber) {
        COrderInfo m_order;
        int result = 0;
        for (int i = OrdersTotal() - 1; i >= 0; i--)  // returns the number of current orders
            if (m_order.SelectByIndex(i))             // selects the pending order by index for further access to its properties
                if (m_order.Symbol() == symbol && m_order.Magic() == magicNumber)
                    result++;
        //---
        return result;
    }

    //+------------------------------------------------------------------+
    //| Check Freeze and Stops levels                                    |
    //+------------------------------------------------------------------+
    /*Type of order/position  |  Activation price  |  Check
      ------------------------|--------------------|--------------------------------------------
      Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
      Buy Stop order          |  Ask	            |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell Limit order        |  Bid	            |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell Stop order	      |  Bid	            |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
      Buy position            |  Bid	            |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL 
                              |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell position           |  Ask	            |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                              |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
                              
      Buying is done at the Ask price                 |  Selling is done at the Bid price
      ------------------------------------------------|----------------------------------
      TakeProfit        >= Bid                        |  TakeProfit        <= Ask
      StopLoss          <= Bid	                     |  StopLoss          >= Ask
      TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
      Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
    */

    bool FreezeStopsLevels(SymbolData* s, double& level) {
        if (!s.RefreshRates() || !s.Refresh())
            return (false);
        //--- FreezeLevel -> for pending order and modification
        double freeze_level = s.FreezeLevel() * s.Point();
        if (freeze_level == 0.0)
            freeze_level = (s.Ask() - s.Bid()) * 3.0;
        freeze_level *= 1.1;
        //--- StopsLevel -> for TakeProfit and StopLoss
        double stop_level = s.StopsLevel() * s.Point();
        if (stop_level == 0.0)
            stop_level = (s.Ask() - s.Bid()) * 3.0;
        stop_level *= 1.1;

        if (freeze_level <= 0.0 || stop_level <= 0.0)
            return (false);

        level = (freeze_level > stop_level) ? freeze_level : stop_level;
        //---
        return (true);
    }

    void trailingStop(SymbolData* s, int magicNumber) {
        double level;
        if (FreezeStopsLevels(s, level)) {
            Trailing(level, s, magicNumber);
        } else {
            warn(StringFormat("Freeze Level error %d", level));
        }
    }

    /*
         Buying is done at the Ask price                 |  Selling is done at the Bid price
         ------------------------------------------------|----------------------------------
         TakeProfit        >= Bid                        |  TakeProfit        <= Ask
         StopLoss          <= Bid	                     |  StopLoss          >= Ask
         TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
         Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
         */

    void Trailing(const double stop_level, SymbolData* s, int magicNumber) {
        if (itsTrailingStop == 0) {
            warn(StringFormat("Skipping trailing stop as itsTrailingStop:%d", itsTrailingStop));
            return;
        }

        if (!s.refreshRates()) {
            warn("Unable to Refresh rates for " + s.str());
            return;
        }

        debug(StringFormat("Trailing stop for %s ........%d ", s.str(), magicNumber));
        double ExtAdjustedPoint = s.digitAdjust();

        double ExtStopLoss = itsStopLoss * ExtAdjustedPoint;          // Stop Loss      -> double
        double ExtTakeProfit = itsTakeProfit * ExtAdjustedPoint;      // Take Profit    -> double
        double ExtTrailingStop = itsTrailingStop * ExtAdjustedPoint;  // Trailing Stop  -> double
        double ExtTrailingStep = itsTrailingStep * ExtAdjustedPoint;  // Trailing Step  -> double
        CPositionInfo position;
        debug(StringFormat("Total %d ExtStopLoss(%f) , ExtTakeProfit(%f)  ExtTrailingStop(%f) ExtTrailingStep(%f) ", PositionsTotal(), ExtStopLoss, ExtTakeProfit, ExtTrailingStop, ExtTrailingStep));
        for (int i = PositionsTotal() - 1; i >= 0; i--)  // returns the number of open positions
            if (position.SelectByIndex(i))
                if (position.Symbol() == s.Name() && position.Magic() == magicNumber) {
                    if (position.PositionType() == POSITION_TYPE_BUY) {
                        ulong ticket = position.Ticket();
                        double pp = position.PriceCurrent();
                        double op = position.PriceOpen();
                        double sl = position.StopLoss();
                        double tp = position.TakeProfit();

                        debug(StringFormat("BUY OP(%f) , PP(%f)  Diff(%f) >= Trailing start(%f) ", op, pp, pp - op, ExtTrailingStop + ExtTrailingStep));
                        if (pp - op > ExtTrailingStop + ExtTrailingStep)
                            if (sl < pp - (ExtTrailingStop + ExtTrailingStep))
                                if (ExtTrailingStop >= stop_level) {
                                    CTrade* m_trade = getTradeInstance(s, magicNumber);
                                    if (!m_trade.PositionModify(ticket, s.NormalizePrice(pp - ExtTrailingStop), tp))
                                        Print("Modify ", ticket, " Position -> false. Result Retcode: ", m_trade.ResultRetcode(), ", description of result: ", m_trade.ResultRetcodeDescription());
                                    //s.refreshRates();
                                    position.SelectByIndex(i);
                                    //PrintResultModify(m_trade, s, position);
                                    continue;
                                }
                    } else {
                        ulong ticket = position.Ticket();
                        double pp = position.PriceCurrent();
                        double op = position.PriceOpen();
                        double sl = position.StopLoss();
                        double tp = position.TakeProfit();
                        debug(StringFormat("SELL OP(%f) , PP(%f)  Diff(%f) > Trailing start(%f) ", op, pp, op - pp, ExtTrailingStop + ExtTrailingStep));
                        if (op - pp > ExtTrailingStop + ExtTrailingStep)
                            if ((sl > (pp + (ExtTrailingStop + ExtTrailingStep))) || (sl == 0))
                                if (ExtTrailingStop >= stop_level) {
                                    CTrade* m_trade = getTradeInstance(s, magicNumber);
                                    if (!m_trade.PositionModify(ticket, s.NormalizePrice(pp + ExtTrailingStop), tp))
                                        Print("Modify ", ticket, " Position -> false. Result Retcode: ", m_trade.ResultRetcode(), ", description of result: ", m_trade.ResultRetcodeDescription());
                                    //s.refreshRates();
                                    position.SelectByIndex(i);
                                    //PrintResultModify(m_trade, s, position);
                                }
                    }
                }
    }

    void ClosePositions(const ENUM_POSITION_TYPE pos_type, SymbolData* s, int magicNumber) {
        double stop_level;
        if (!FreezeStopsLevels(s, stop_level)) {
            warn("Unable to close Opposite position");
            return;
        }

        if (!s.refreshRates()) {
            warn("Unable to Refresh rates for " + s.str());
            return;
        }

        CPositionInfo position;
        for (int i = PositionsTotal() - 1; i >= 0; i--)  // returns the number of current positions
            if (position.SelectByIndex(i))               // selects the position by index for further access to its properties
                if (position.Symbol() == s.Name() && position.Magic() == magicNumber) {
                    CTrade* m_trade = getTradeInstance(s, magicNumber);
                    if (position.PositionType() == pos_type) {
                        if (position.PositionType() == POSITION_TYPE_BUY)
                            if (MathAbs(s.Bid() - position.PriceOpen()) >= stop_level)
                                m_trade.PositionClose(position.Ticket());  // close a position by the specified symbol
                        if (position.PositionType() == POSITION_TYPE_SELL)
                            if (MathAbs(s.Ask() - position.PriceOpen()) >= stop_level)
                                m_trade.PositionClose(position.Ticket());  // close a position by the specified symbol
                    }
                }
    }

    void CloseOppositePosition(const ENUM_POSITION_TYPE pos_type, SymbolData* s, int magicNumber) {
        CPositionInfo position;
        for (int i = PositionsTotal() - 1; i >= 0; i--)  // returns the number of current positions
            if (position.SelectByIndex(i))               // selects the position by index for further access to its properties
                if (position.Symbol() == s.Name() && position.Magic() == magicNumber) {
                    CTrade* m_trade = getTradeInstance(s, magicNumber);
                    if (position.PositionType() == pos_type) {
                        info("Closing the position as opposite signal came");
                        m_trade.PositionClose(position.Ticket());  // close a position by the specified symbol
                    }
                }
    }

    void closeUnreachablePendingOrders(ENUM_ORDER_TYPE order_type, SymbolData* s, int magicNumber, int maxPips) {
        COrderInfo order;
        double maxDiffInPrice = maxPips * s.Point();
        info(StringFormat("Total Order %d  maxDiffInPrice %f %s  ", OrdersTotal(), maxDiffInPrice, s.str()));
        for (int i = OrdersTotal() - 1; i >= 0; i--) {  // returns the number of current orders

            if (order.SelectByIndex(i))  // selects the pending order by index for further access to its properties
                if (order.Symbol() == s.Name() && order.Magic() == magicNumber) {
                    ulong ticket = order.Ticket();
                    double pp = order.PriceCurrent();
                    double op = order.PriceOpen();
                    double sl = order.StopLoss();
                    double tp = order.TakeProfit();

                    info(StringFormat("ticket: %d , %s %s OP(%f) , PP(%f)  Diff(%f)  ", ticket, EnumToString(order_type), EnumToString(order.OrderType()), op, pp, pp - op));
                    CTrade* m_trade = getTradeInstance(s, magicNumber);
                    double openPriceDistance = -1;
                    if (order.OrderType() == ORDER_TYPE_BUY_LIMIT && order_type == ORDER_TYPE_BUY_LIMIT) {
                        openPriceDistance = MathAbs(s.Ask() - op);
                    }
                    if (order.OrderType() == ORDER_TYPE_SELL_LIMIT && order_type == ORDER_TYPE_SELL_LIMIT) {
                        openPriceDistance = MathAbs(s.Bid() - op);
                    }
                    info(StringFormat("ticket: %d , %s %s ,openPriceDistance(%f)  >= (%f) maxDiffInPrice", ticket, EnumToString(order_type), EnumToString(order.OrderType()), openPriceDistance, maxDiffInPrice));

                    if (openPriceDistance >= maxDiffInPrice) {
                        m_trade.OrderDelete(ticket);
                    }
                }
        }
    }
};