#property strict

void PrintCurrencyInfo() {
    MqlTick current;
    SymbolInfoTick(_Symbol, current);
    debug(StringFormat("Price [%f, %f], TL:%dm , %f , _Digits: %d", current.bid, current.ask, _Period, _Point, _Digits));
    /*debug(StringFormat("MinLot: %f SL Level: %f", MarketInfoMQL4(_Symbol, MODE_MINLOT), MarketInfoMQL4(_Symbol, MODE_STOPLEVEL)));
    debug(StringFormat("Day Range - [%f , %f]", MarketInfoMQL4(_Symbol, MODE_LOW), MarketInfoMQL4(_Symbol, MODE_HIGH)));*/
}

double GetPipValueFromDigits() {
    if (_Digits >= 4)
        return 0.0001;
    else
        return 0.01;
}

bool isTradingAllowed() {
    if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) {
        Alert("Automated trading is forbidden for the account ", AccountInfoInteger(ACCOUNT_LOGIN),
              " at the trade server side");
        warn("Auto Trading is disable for Expert Advisor");
        return false;
    } else {
        //TODO
        /*if (!IsTradeAllowed(_Symbol, TimeCurrent()))
            {
                warn(StringFormat("Trading Hours are closed for %s.", _Symbol));
                return false;
            }*/
    }
    return true;
}
