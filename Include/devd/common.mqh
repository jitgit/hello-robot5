#property strict
input bool DEBUG_INFO = true;
input bool WARN_INFO = true;

void log(string s) {
    Print("INFO - " + s);
}

void debug(string s) {
    if (DEBUG_INFO) {
        Print("DBUG - " + s);
    }
}

void warn(string s) {
    if (WARN_INFO) {
        Print("WARN - " + s);
    }
}

void printArrayInfo(const double &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %d", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
}

void printArrayInfo(const datetime &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %d", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
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