#include <devd/acc/RiskManager.mqh>
#include <devd/include-base.mqh>
#include <devd/order/OrderManager.mqh>
#include <devd/order/PositionOptimizer.mqh>
#include <devd/price/EconomicEventPricer.mqh>
#include <devd\trailingsl\ATRTrailingStop.mqh>

int POSITION_OPTIMIZE_INTERVAL = 5;  //secs
long positionOptimizerTick = 0;

OrderManager* orderManager = new OrderManager();
//PositionOptimizer* positionOptimizer = new PositionOptimizer(100, 2, 10);
TrailingStop* tralingStop = new ATRTrailingStop();
CArrayObj* economic_news;

void add(EconomicEvent* event, string ccyPair) {
    int s = ArraySize(event.pairs);
    ArrayResize(event.pairs, s + 1);
    event.pairs[s] = ccyPair;
}

EconomicEvent* build_NZ_IR(string newsTime) {
    EconomicEvent* NZ_IR = new EconomicEvent(IR, "NZD", 2, newsTime);
    add(NZ_IR, "AUDNZD");
    //add(NZ_IR, "NZDJPY");
    //add(NZ_IR, "NZDHKD");
    //add(NZ_IR, "NZDSGD");
    //add(NZ_IR, "GBPNZD");
    //add(NZ_IR, "EURNZD");
    //add(NZ_IR, "NZDCHF");
    //add(NZ_IR, "NZDUSD");
    return NZ_IR;
}

EconomicEvent* build_NZ_CPI(string newsTime) {
    EconomicEvent* NZ_CPI = new EconomicEvent(CPI, "NZD", 2, newsTime);
    add(NZ_CPI, "AUDNZD");
    add(NZ_CPI, "NZDJPY");
    //add(NZ_IR, "NZDHKD");
    //add(NZ_IR, "NZDSGD");
    add(NZ_CPI, "NZDCAD");
    add(NZ_CPI, "EURNZD");
    add(NZ_CPI, "NZDUSD");
    return NZ_CPI;
}

EconomicEvent* build_Oil_Inventories(string newsTime) {
    EconomicEvent* e = new EconomicEvent(OIL_INVENTORIES, "OIL", 2, newsTime);
    add(e, "WTI");
    add(e, "BRENT");
    return e;
}
EconomicEvent* build_CAD_Ivy_PMI(string newsTime) {
    EconomicEvent* e = new EconomicEvent(PMI, "CAD", 2, newsTime);
    add(e, "CADJPY");
    add(e, "EURCAD");
    add(e, "GBPCAD");
    add(e, "CADCHF");
    return e;
}

CArrayObj* buildEcoEvents() {
    CArrayObj* events = new CArrayObj;

    EconomicEvent* NZ_IR = build_NZ_IR("2020-06-29 21:46:00");
    EconomicEvent* NZ_CPI = build_NZ_IR("2020-06-29 21:46:00");
    EconomicEvent* OIL = build_Oil_Inventories("2020-07-01 17:56:40");
    EconomicEvent* CAD_IVEY = build_CAD_Ivy_PMI("2020-07-07 14:59:45");
    //events.Add(NZ_IR);
    //events.Add(NZ_CPI);
    //events.Add(OIL);
    events.Add(CAD_IVEY);
    return events;
}

int OnInit() {
    Print("Starting the Economics EA ..");
    economic_news = buildEcoEvents();

    EventSetTimer(1);
    return (INIT_SUCCEEDED);
}

void OnDeinit() {
    EventKillTimer();
}

void OnTimer() {
    datetime localTime = TimeLocal();
    for (int i = 0; i < economic_news.Total(); i++) {
        EconomicEvent* e = economic_news.At(i);
        datetime event_time = e.eventTime;
        //info(StringFormat("About to execute the events. Size(%d) , "+ localTime + " -> event_time: " + event_time,  economic_news.Total()));
        if (e.isOrderExecuted == false && event_time == localTime) {
            info("Submitting the Orders for " + e.str());
            for (int j = 0; j < ArraySize(e.pairs); j++) {
                string symbol = e.pairs[j];
                bool result = submitBuySellOrder(symbol, 10);
                debug(StringFormat("######### CCY PAIR %s = " + result, symbol));
            }
            e.isOrderExecuted = true;
            economic_news.Delete(i);
        }
    }
    /*if (economic_news.Total() == 0) {
        info(StringFormat("Killing Timer as no event left to execute %d", economic_news.Total()));
        EventKillTimer();
    }*/

    positionOptimizerTick = (positionOptimizerTick + 1) % POSITION_OPTIMIZE_INTERVAL;
    if (positionOptimizerTick == POSITION_OPTIMIZE_INTERVAL - 1) {
        tralingStop.updateTrailingStop(ECONOMICS_EVENT_MAGIC);
        positionOptimizerTick = 0;
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
    bool buySuccess = orderManager.bookStopOrder(longSignal, longLotSize, ECONOMICS_EVENT_MAGIC);  //We don't want SL or TP

    info(StringFormat("========================= SELL (%s) =========================", symbol));

    SignalResult* shortSignal = new SignalResult(symbol, GO_SHORT);
    //Calculating entry, SL,TP
    newsPricer.addEntryStopLossAndTakeProfit(shortSignal, pipDisplacement);
    //Calculating Lot Size
    double shortLotSize = riskManager.optimalLotSizeFrom(shortSignal, 2.0);
    //Try to book the order without SL & TP
    bool sellSuccess = orderManager.bookStopOrder(shortSignal, shortLotSize, ECONOMICS_EVENT_MAGIC);  //We don't want SL or TP

    return sellSuccess && buySuccess;
}

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
    ulong lastOrderID = trans.order;
    ENUM_ORDER_TYPE lastOrderType = trans.order_type;
    ENUM_ORDER_STATE lastOrderState = trans.order_state;
    string trans_symbol = trans.symbol;
    ENUM_TRADE_TRANSACTION_TYPE trans_type = trans.type;

    //info("===================================================================================================");
    //info(StringFormat("Transaction Symbol(%s) ,Type(%s), State(%s), Order Type(%s)", trans.symbol, EnumToString(trans.type), EnumToString(trans.order_state), EnumToString(trans.order_type)));
    //info(StringFormat("Request Symbol(%s), Action(%s), Type(%s),  magic(%d), Comment(%s)", request.symbol, EnumToString(request.action), EnumToString(request.type), request.magic, request.comment));
    //info(StringFormat("Result :%s, %s ", GetTradeTransactionResultRetcodeID(result.retcode), result.comment));

    //TODO this must be read from result
    if (trans.type == TRADE_TRANSACTION_HISTORY_ADD && trans.order_state == ORDER_STATE_FILLED) {
        //If one buy/sell stop is filled we remove the other trade
        info(StringFormat("SERVER TIME %s,  Removing counter trade Symbol(%s), Type(%s), Order Id:" + trans.order, TimeToString(TimeTradeServer()), trans.symbol, EnumToString(trans.order_type)));
        ENUM_ORDER_TYPE toDeleteOrderType = trans.order_type == ORDER_TYPE_BUY_STOP ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_BUY_STOP;
        orderManager.DeleteAllOrdersBy(trans.symbol, ECONOMICS_EVENT_MAGIC, toDeleteOrderType, trans.order);
    }
}