#property strict

void PrintCurrencyInfo()
{
   MqlTick current;
   SymbolInfoTick(_Symbol, current);
   debug(StringFormat("Price [%f, %f], TL:%dm , %f , _Digits: %d", current.bid, current.ask, _Period, _Point, _Digits));
   /*debug(StringFormat("MinLot: %f SL Level: %f", MarketInfoMQL4(_Symbol, MODE_MINLOT), MarketInfoMQL4(_Symbol, MODE_STOPLEVEL)));
    debug(StringFormat("Day Range - [%f , %f]", MarketInfoMQL4(_Symbol, MODE_LOW), MarketInfoMQL4(_Symbol, MODE_HIGH)));*/
}

double GetPipValueFromDigits()
{
   if (_Digits >= 4)
      return 0.0001;
   else
      return 0.01;
}
