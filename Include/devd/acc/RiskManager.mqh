//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property strict
#include <devd/include-base.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class RiskManager {
   protected:
    double itsRiskPercentage;

   public:
    RiskManager(double riskPercentage = 2) {
        itsRiskPercentage = riskPercentage;
    }

    double optimalLotSizeOnMarketPrice(string symbol, bool isLong, int SL, int TP, double maxRiskPerc) {
        double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double accEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double minBalance = MathMin(accBalance, accEquity);

        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        int digit = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double spreadPips = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
        long stopLossLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

        double valueToRisk = (maxRiskPerc / 100) * minBalance;

        debug(StringFormat("Balance :%f, Equity :%f, Risk :%f", accBalance, accEquity, valueToRisk));
        debug(StringFormat("Tick (Value :%f, Size :%f), stopLossLevel(%d), Point:(%f)", tickValue, tickSize, stopLossLevel, point));
        debug(StringFormat("PIPS TakeProfit(%d), StopLoss:(%d)", TP, SL));
        debug(StringFormat("Ask :%f , Bid :%f", Ask, Bid));

        debug(StringFormat("Spread Pips(%f) (Ask-Bid): %f", spreadPips, spreadPips * point));
        double lotSize = 0;
        if (isLong) {
            //Buy SL/TP calcuated based on Bid due to Spread
            double buy_tp = NormalizeDouble(Bid + TP * point, digit);
            double buy_sl = NormalizeDouble(Bid - SL * point, digit);
            debug(StringFormat("BUY  TP(%f) > (%f) > SL(%f)", buy_tp, Ask, buy_sl));

            lotSize = calculateLotSize(symbol, valueToRisk, SL, TP, buy_sl);
        } else {
            //Sell SL/TP calcuated based on Ask due to Spread
            double sell_tp = NormalizeDouble(Ask - TP * point, digit);
            double sell_sl = NormalizeDouble(Ask + SL * point, digit);
            debug(StringFormat("SELL TP(%f) < (%f) < SL(%f)", sell_tp, Bid, sell_sl));
            lotSize = calculateLotSize(symbol, valueToRisk, SL, TP, sell_sl);
        }
        return lotSize;
    }

    double optimalLotSizeFrom(SignalResult& signal, double maxRiskPerc) {
        double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double accEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double minBalance = MathMin(accBalance, accEquity);

        SymbolData* s = new SymbolData(signal.symbol);

        double valueToRisk = (maxRiskPerc / 100) * minBalance;

        debug(StringFormat("Balance :%f, Equity :%f, Risk :%f", accBalance, accEquity, valueToRisk));
        debug("Symbol :" + s.str());

        if (s.Ask == 0 || s.Bid == 0 || s.tickValue == 0) {  // CCYPAIR doesn't exists on the broker
            warn("Currrency pair is not supported on broker, Ask|Bid|TickValue ==0");
            return 0;
        }

        double lotSize = 0;
        if (signal.go == GO_LONG) {
            //Buy SL/TP calcuated based on Bid due to Spread
            double buy_tp = NormalizeDouble(s.Bid + signal.TP * s.point, s.digit);
            double buy_sl = NormalizeDouble(s.Bid - signal.SL * s.point, s.digit);
            debug(StringFormat("BUY  TP(%f) > (%f) > SL(%f)", buy_tp, s.Ask, buy_sl));

            lotSize = calculateLotSize(signal.symbol, valueToRisk, signal.SL, signal.TP, buy_sl);
        } else if (signal.go == GO_SHORT) {
            //Sell SL/TP calcuated based on Ask due to Spread
            double sell_tp = NormalizeDouble(s.Ask - signal.TP * s.point, s.digit);
            double sell_sl = NormalizeDouble(s.Ask + signal.SL * s.point, s.digit);
            debug(StringFormat("SELL TP(%f) < (%f) < SL(%f)", sell_tp, s.Bid, sell_sl));
            lotSize = calculateLotSize(signal.symbol, valueToRisk, signal.SL, signal.TP, sell_sl);
        }
        return lotSize;
    }

    double calculateLotSize(string symbol, double valueToRisk, int SL, int TP, double slPrice) {
        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double _lotcalculation = valueToRisk / (slPrice * (tickValue / tickSize));

        //rounding & checking min/max allowed
        double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        int lotdigits = (int)-MathLog(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
        double lots = NormalizeDouble(_lotcalculation, lotdigits);
        if (lots < min_lot) lots = min_lot;
        if (lots > max_lot) lots = max_lot;
        double roundedDown = MathRoundDown(lots, 0.01);
        info(StringFormat("===> LotSize rounded down  %f ==> %f", _lotcalculation, roundedDown));

        return roundedDown;
    }

    double MathRoundDown(double v, double to) { return to * MathFloor(v / to); }

    double optimalLotSizeWithPips(string symbol, double maxRiskPerc, int maxLossInPips) {
        double profit = AccountInfoDouble(ACCOUNT_PROFIT);
        double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        string accCurr = AccountInfoString(ACCOUNT_CURRENCY);
        double accEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double maxLoss = accEquity * maxRiskPerc;

        double lotSize = 100000;  //MarketInfo(_Symbol, MODE_LOTSIZE);
        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

        tickValue = tickValue;
        if (_Digits <= 3)  //handling JPY
            tickValue = tickValue / 100;
        info(StringFormat("Tick (Value :%f, Size :%f)", tickValue, tickSize));
        if (tickValue != 0) {
            double maxLossInQuoteCurrency = maxLoss / tickValue;

            double optimalLotSize = NormalizeDouble(maxLossInQuoteCurrency / (maxLossInPips * GetPipValueFromDigits()) / lotSize, 2);
            info(StringFormat("Balance :%+.0f %s, Equity: %+.0f %s, MaxLoss :%+.0f %s, maxLossInPips:%d", accBalance, accCurr, accEquity, accCurr, maxLoss, accCurr, maxLossInPips));

            info(StringFormat("RISK_ALLOWED: %f, maxLossInQuoteCurrency :%f, optimalLotSize: %f", maxRiskPerc, maxLossInQuoteCurrency, optimalLotSize));
            return optimalLotSize;
        } else {
            warn("Tick Value is zero");
            return 0;
        }
    }

    double optimalLotSize(string symbol, double maxRiskPerc, double entryPrice, double stopLoss) {
        int maxLossInPips = MathAbs(entryPrice - stopLoss) / GetPipValueFromDigits();
        return optimalLotSizeWithPips(symbol, maxRiskPerc, maxLossInPips);
    }

    double optimalLotSize(string symbol, double entryPrice, double stopLoss) {
        return optimalLotSize(symbol, itsRiskPercentage, entryPrice, stopLoss);
    }
};
//+------------------------------------------------------------------+
