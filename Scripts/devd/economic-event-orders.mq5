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

void add(EconomicEvent* event, string ccyPair) {
    int s = ArraySize(event.pairs);
    ArrayResize(event.pairs, s + 1);
    event.pairs[s] = ccyPair;
}

void OnInit() {
    CArrayObj* events = new CArrayObj;
    EconomicEvent* NZ_IR = new EconomicEvent(IR, "NZD", 2, "2020-06-27 22:14:00");
    //add(NZ_IR, "AUDNZD");
    //add(NZ_IR, "NZDJPY");
    //add(NZ_IR, "NZDHKD");
    add(NZ_IR, "NZDSGD");
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
            bool result = submitBuySellOrder(symbol, 12);
            info(StringFormat("######### CCY PAIR %s = " + result, symbol));
        }
    }
}

bool submitBuySellOrder(string symbol, int pipDisplacement) {
    EconomicEventPricer* newsPricer = new EconomicEventPricer();
    OrderManager* orderManager = new OrderManager();
    RiskManager riskManager = new RiskManager();

    info(StringFormat("========================= BUY (%s) =========================", symbol));
    SignalResult* longSignal = new SignalResult(symbol, GO_LONG);
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(longSignal, pipDisplacement);
    //Calculating Lot Size
    double longLotSize = riskManager.optimalLotSizeFrom(longSignal, 2.0);
    //Try to book the order without SL & TP
    bool buySuccess = orderManager.bookStopOrder(longSignal, longLotSize, 0007);  //We don't want SL or TP

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

   PrintFormat("===========> Trade Request Symbol:%s , Comment:%s ", request.symbol, result.comment);
   PrintFormat("===========> Trade Result Symbol:%s , Comment:%s ", GetTradeTransactionResultRetcodeID(result.retcode), result.comment);

    switch (trans.type) {            
        case TRADE_TRANSACTION_POSITION: { // position modification
            ulong pos_ID = trans.position;
            PrintFormat("MqlTradeTransaction: Position  #%d %s modified: SL=%.5f TP=%.5f", pos_ID, trans_symbol, trans.price_sl, trans.price_tp);
            break;
        }
        case TRADE_TRANSACTION_REQUEST:  // sending a trade request
            PrintFormat("MqlTradeTransaction: TRADE_TRANSACTION_REQUEST");
            break;
        case TRADE_TRANSACTION_DEAL_ADD: {  // adding a trade
            ulong lastDealID = trans.deal;
            ENUM_DEAL_TYPE lastDealType = trans.deal_type;
            double lastDealVolume = trans.volume;
            //--- Trade ID in an external system - a ticket assigned by an exchange
            string Exchange_ticket = "";
            if (HistoryDealSelect(lastDealID))
                Exchange_ticket = HistoryDealGetString(lastDealID, DEAL_EXTERNAL_ID);
            if (Exchange_ticket != "")
                Exchange_ticket = StringFormat("(Exchange deal=%s)", Exchange_ticket);

            PrintFormat("MqlTradeTransaction: %s deal #%d %s %s %.2f lot   %s", EnumToString(trans_type),
                        lastDealID, EnumToString(lastDealType), trans_symbol, lastDealVolume, Exchange_ticket);
        } break;
        case TRADE_TRANSACTION_HISTORY_ADD: {  // adding an order to the history
            //--- order ID in an external system - a ticket assigned by an Exchange
            string Exchange_ticket = "";
            if (lastOrderState == ORDER_STATE_FILLED) {
                if (HistoryOrderSelect(lastOrderID))
                    Exchange_ticket = HistoryOrderGetString(lastOrderID, ORDER_EXTERNAL_ID);
                if (Exchange_ticket != "")
                    Exchange_ticket = StringFormat("(Exchange ticket=%s)", Exchange_ticket);
            }
            PrintFormat("MqlTradeTransaction: %s order #%d %s %s %s   %s", EnumToString(trans_type),
                        lastOrderID, EnumToString(lastOrderType), trans_symbol, EnumToString(lastOrderState), Exchange_ticket);
        } break;
        default: {  // other transactions
            //--- order ID in an external system - a ticket assigned by Exchange
            string Exchange_ticket = "";
            if (lastOrderState == ORDER_STATE_PLACED) {
                if (OrderSelect(lastOrderID))
                    Exchange_ticket = OrderGetString(ORDER_EXTERNAL_ID);
                if (Exchange_ticket != "")
                    Exchange_ticket = StringFormat("Exchange ticket=%s", Exchange_ticket);
            }
            PrintFormat("MqlTradeTransaction: %s order #%d %s %s   %s", EnumToString(trans_type),
                        lastOrderID, EnumToString(lastOrderType), EnumToString(lastOrderState), Exchange_ticket);
        } break;
    }
    //--- order ticket
    ulong orderID_result = result.order;
    //string retcode_result=GetRetcodeID(result.retcode);
    //if(orderID_result!=0)
    //("MqlTradeResult: order #%d retcode=%s ",orderID_result,retcode_result);
    //---
}