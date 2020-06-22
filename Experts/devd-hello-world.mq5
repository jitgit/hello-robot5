//+------------------------------------------------------------------+
//|                                                        Hello.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"

#include <devd/strat/bb_strat.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    //---

    //---
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //---
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnStart() {
    /*int TP = 300;     //In pips
    int SL = 100;     //In pips
    double risk = 2;  //Risk in percentage
    double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double accEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double minBalance = MathMin(accBalance, accEquity);
    
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    int digit = int(SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    long stopLossLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

    //Sell SL/TP calcuated based on Ask due to Spread
    double sell_tp = NormalizeDouble(Ask - TP * point, digit);
    double sell_sl = NormalizeDouble(Ask + SL * point, digit);
    //Buy SL/TP calcuated based on Bid due to Spread
    double buy_tp = NormalizeDouble(Bid + TP * point, digit);
    double buy_sl = NormalizeDouble(Bid - SL * point, digit);

    double valueToRisk = (risk / 100) * minBalance;
    
    double sell_lots = valueToRisk /(sell_sl * ( tickValue / tickSize));
    double buy_lots = valueToRisk /(buy_sl * ( tickValue / tickSize));

    double spreadPips = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

    PrintFormat("Balance :%f, Equity :%f, Risk :%f", accBalance, accEquity, valueToRisk);
    PrintFormat("Tick (Value :%f, Size :%f), stopLossLevel(%d), _Point:(%f)", tickValue, tickSize, stopLossLevel, _Point);
    PrintFormat("PIPS TakeProfit:%d , StopLoss: %d", TP, SL);
    PrintFormat("Ask:%f , Bid: %f", Ask, Bid);
    PrintFormat("SELL TP(%f) < (%f) < SL(%f), LotSize(%f)", sell_tp, Bid, sell_sl, sell_lots);
    PrintFormat("BUY  TP(%f) > (%f) > SL(%f), LotSize(%f)", buy_tp, Ask, buy_sl, buy_lots);

    PrintFormat("Spread (%f)Pips (Ask-Bid):%f", spreadPips, spreadPips * point);*/

    //---
    main();
}
//+------------------------------------------------------------------+
