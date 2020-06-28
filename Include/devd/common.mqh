#property strict

double normalizeAsk(string symbol) {
    int digit = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    return NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), digit);
}

double normalizeBid(string symbol) {
    int digit = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    return NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), digit);
}

double norm(double d) {
    return NormalizeDouble(d, _Digits);
}

string tsMin(datetime dt) {
    return TimeToString(dt, TIME_MINUTES);
}

string tsDate(datetime dt) {
    return StringFormat("%s %s", TimeToString(dt, TIME_DATE), tsMin(dt));
}

string ResultRetcodeDescription(int retcode) {
    string str;
    //----
    switch (retcode) {
        case TRADE_RETCODE_REQUOTE:
            str = "Requote";
            break;
        case TRADE_RETCODE_REJECT:
            str = "Rejected";
            break;
        case TRADE_RETCODE_CANCEL:
            str = "Cancelled";
            break;
        case TRADE_RETCODE_PLACED:
            str = "Order placed";
            break;
        case TRADE_RETCODE_DONE:
            str = "Request done";
            break;
        case TRADE_RETCODE_DONE_PARTIAL:
            str = "Request done partial";
            break;
        case TRADE_RETCODE_INVALID:
            str = "Invalid request";
            break;
        case TRADE_RETCODE_INVALID_VOLUME:
            str = "Invalid volume";
            break;
        case TRADE_RETCODE_INVALID_PRICE:
            str = "Invalid price";
            break;
        case TRADE_RETCODE_INVALID_STOPS:
            str = "INVALID STOPS";
            break;
        case TRADE_RETCODE_TRADE_DISABLED:
            str = "Trade disabled";
            break;
        case TRADE_RETCODE_MARKET_CLOSED:
            str = "Market closed";
            break;
        case TRADE_RETCODE_NO_MONEY:
            str = "Of insufficient funds";
            break;
        case TRADE_RETCODE_PRICE_CHANGED:
            str = "Price changed";
            break;
        case TRADE_RETCODE_ORDER_CHANGED:
            str = "Order changed ";
            break;
        case TRADE_RETCODE_TOO_MANY_REQUESTS:
            str = "Too many requests";
            break;
        case TRADE_RETCODE_NO_CHANGES:
            str = "No changes";
            break;
        case TRADE_RETCODE_SERVER_DISABLES_AT:
            str = "Server disables autotrading";
            break;
        case TRADE_RETCODE_CLIENT_DISABLES_AT:
            str = "Client disables autotrading";
            break;
        case TRADE_RETCODE_LOCKED:
            str = "Request is locked";
            break;
        case TRADE_RETCODE_LIMIT_ORDERS:
            str = "Limit orders";
            break;
        case TRADE_RETCODE_LIMIT_VOLUME:
            str = "Limit volume";
            break;
        default:
            str = "Unknown error " + IntegerToString(retcode);
    }
    //----
    return (str);
}

string GetTradeTransactionResultRetcodeID(int retcode) {
    switch (retcode) {
        case 10004:
            return ("TRADE_RETCODE_REQUOTE");
            break;
        case 10006:
            return ("TRADE_RETCODE_REJECT");
            break;
        case 10007:
            return ("TRADE_RETCODE_CANCEL");
            break;
        case 10008:
            return ("TRADE_RETCODE_PLACED");
            break;
        case 10009:
            return ("TRADE_RETCODE_DONE");
            break;
        case 10010:
            return ("TRADE_RETCODE_DONE_PARTIAL");
            break;
        case 10011:
            return ("TRADE_RETCODE_ERROR");
            break;
        case 10012:
            return ("TRADE_RETCODE_TIMEOUT");
            break;
        case 10013:
            return ("TRADE_RETCODE_INVALID");
            break;
        case 10014:
            return ("TRADE_RETCODE_INVALID_VOLUME");
            break;
        case 10015:
            return ("TRADE_RETCODE_INVALID_PRICE");
            break;
        case 10016:
            return ("TRADE_RETCODE_INVALID_STOPS");
            break;
        case 10017:
            return ("TRADE_RETCODE_TRADE_DISABLED");
            break;
        case 10018:
            return ("TRADE_RETCODE_MARKET_CLOSED");
            break;
        case 10019:
            return ("TRADE_RETCODE_NO_MONEY");
            break;
        case 10020:
            return ("TRADE_RETCODE_PRICE_CHANGED");
            break;
        case 10021:
            return ("TRADE_RETCODE_PRICE_OFF");
            break;
        case 10022:
            return ("TRADE_RETCODE_INVALID_EXPIRATION");
            break;
        case 10023:
            return ("TRADE_RETCODE_ORDER_CHANGED");
            break;
        case 10024:
            return ("TRADE_RETCODE_TOO_MANY_REQUESTS");
            break;
        case 10025:
            return ("TRADE_RETCODE_NO_CHANGES");
            break;
        case 10026:
            return ("TRADE_RETCODE_SERVER_DISABLES_AT");
            break;
        case 10027:
            return ("TRADE_RETCODE_CLIENT_DISABLES_AT");
            break;
        case 10028:
            return ("TRADE_RETCODE_LOCKED");
            break;
        case 10029:
            return ("TRADE_RETCODE_FROZEN");
            break;
        case 10030:
            return ("TRADE_RETCODE_INVALID_FILL");
            break;
        case 10031:
            return ("TRADE_RETCODE_CONNECTION");
            break;
        case 10032:
            return ("TRADE_RETCODE_ONLY_REAL");
            break;
        case 10033:
            return ("TRADE_RETCODE_LIMIT_ORDERS");
            break;
        case 10034:
            return ("TRADE_RETCODE_LIMIT_VOLUME");
            break;
        case 10035:
            return ("TRADE_RETCODE_INVALID_ORDER");
            break;
        case 10036:
            return ("TRADE_RETCODE_POSITION_CLOSED");
            break;
        default:
            return ("TRADE_RETCODE_UNKNOWN=" + IntegerToString(retcode));
            break;
    }
    //---
}

string timFrameToString(ENUM_TIMEFRAMES tf) {
    string str;
    switch (tf) {
        case PERIOD_W1:
            str = "PERIOD_W1";
            break;
        case PERIOD_D1:
            str = "PERIOD_D1";
            break;
        case PERIOD_H1:
            str = "PERIOD_H1";
            break;
        case PERIOD_H2:
            str = "PERIOD_H2";
            break;
        case PERIOD_H4:
            str = "PERIOD_H4";
            break;
        case PERIOD_H8:
            str = "PERIOD_H8";
            break;
        case PERIOD_M1:
            str = "PERIOD_M1";
            break;
        case PERIOD_M5:
            str = "PERIOD_M5";
            break;
        default:
            str = PeriodSeconds(tf) / 60 + "M";
    }
    return str;
}
