//+------------------------------------------------------------------+
//|                                                     devd-rci.mq5 |
//|                                                             Devd |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "Devd"
#property link "https://www.devd.com"
#property version "1.00"

#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/price/EconomicEventPricer.mqh>
int MAGIC_NUMBER = 007;
OrderManager* orderManager = new OrderManager();
void add(EconomicEvent* event, string ccyPair) {
    int s = ArraySize(event.pairs);
    ArrayResize(event.pairs, s + 1);
    event.pairs[s] = ccyPair;
}

void OnInit() {
    CArrayObj* events = new CArrayObj;
    EconomicEvent* NZ_IR = new EconomicEvent(IR, "NZD", 2, "2020-06-27 22:14:00");
    add(NZ_IR, "AUDNZD");
    //add(NZ_IR, "NZDJPY");
    //add(NZ_IR, "NZDHKD");
    //add(NZ_IR, "NZDSGD");
    //add(NZ_IR, "GBPNZD");
    //add(NZ_IR, "EURNZD");
    //add(NZ_IR, "NZDCHF");
    //add(NZ_IR, "NZDUSD");

    events.Add(NZ_IR);
    for (int i = 0; i < events.Total(); i++) {
        EconomicEvent* e = events.At(i);
        info(e.str());
        for (int j = 0; j < ArraySize(e.pairs); j++) {
            string symbol = e.pairs[j];
            bool result = submitBuySellOrder(symbol, 10);
            info(StringFormat("######### CCY PAIR %s = " + result, symbol));
        }
    }
}

bool submitBuySellOrder(string symbol, int pipDisplacement) {
    EconomicEventPricer* newsPricer = new EconomicEventPricer();

    RiskManager riskManager = new RiskManager();

    info(StringFormat("========================= BUY (%s) =========================", symbol));
    SignalResult* longSignal = new SignalResult(symbol, GO_LONG);
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(longSignal, pipDisplacement);
    //Calculating Lot Size
    double longLotSize = riskManager.optimalLotSizeFrom(longSignal, 2.0);
    //Try to book the order without SL & TP
    bool buySuccess = orderManager.bookStopOrder(longSignal, longLotSize, MAGIC_NUMBER);  //We don't want SL or TP

    info(StringFormat("========================= SELL (%s) =========================", symbol));

    SignalResult* shortSignal = new SignalResult(symbol, GO_SHORT);
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(shortSignal, pipDisplacement);
    //Calculating Lot Size
    double shortLotSize = riskManager.optimalLotSizeFrom(shortSignal, 2.0);
    //Try to book the order without SL & TP
    bool sellSuccess = orderManager.bookStopOrder(shortSignal, shortLotSize, 0007);  //We don't want SL or TP

    return sellSuccess && buySuccess;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
/*int OnInit() {
    EventSetTimer(1);
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    datetime start_time = TimeLocal();
    datetime event_time = StringToTime("2020-06-27 22:14:00");
    Print("Timer ... ", start_time, " ", event_time);

    if (start_time == event_time) {
        Print("Event Time ....... ", start_time);
        EventKillTimer();
    }
}*/

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
    ulong lastOrderID = trans.order;
    ENUM_ORDER_TYPE lastOrderType = trans.order_type;
    ENUM_ORDER_STATE lastOrderState = trans.order_state;
    string trans_symbol = trans.symbol;
    ENUM_TRADE_TRANSACTION_TYPE trans_type = trans.type;

    PrintFormat("===================================================================================================");
    PrintFormat("Transaction Symbol(%s) ,Type(%s), State(%s), Order Type(%s)", trans.symbol, EnumToString(trans.type), EnumToString(trans.order_state), EnumToString(trans.order_type));
    PrintFormat("Request Symbol(%s), Action(%s), Type(%s),  magic(%d), Comment(%s)", request.symbol, EnumToString(request.action), EnumToString(request.type), request.magic, request.comment);
    //PrintFormat("Result :%s, %s ", GetTradeTransactionResultRetcodeID(result.retcode), result.comment);

    //TODO this must be read from result
    if (trans.type == TRADE_TRANSACTION_HISTORY_ADD && trans.order_state == ORDER_STATE_FILLED) {
        //If one buy/sell stop is filled we remove the other trade
        PrintFormat("######## Removing counter trade Symbol(%s), Type(%s), Order Id:" + trans.order, trans.symbol, EnumToString(trans.order_type));
        ENUM_ORDER_TYPE toDeleteOrderType = trans.order_type == ORDER_TYPE_BUY_STOP ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_BUY_STOP;
        orderManager.DeleteAllOrdersBy(trans.symbol, MAGIC_NUMBER, toDeleteOrderType, trans.order);
    }
}