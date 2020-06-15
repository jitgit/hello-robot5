
#property strict

class RiskManager
{
protected:
    double itsRiskPercentage;

public:
    double optimalLotSize(double maxRiskPerc, int maxLossInPips)
    {

        double profit = AccountInfoDouble(ACCOUNT_PROFIT);
        double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        string accCurr = AccountInfoString(ACCOUNT_CURRENCY);
        double accEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double maxLoss = accEquity * maxRiskPerc;

        double lotSize = 100000; //MarketInfo(_Symbol, MODE_LOTSIZE);
        double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);

        tickValue = tickValue;
        if (_Digits <= 3) //handling JPY
            tickValue = tickValue / 100;
        log(StringFormat("Tick (Value :%f, Size :%f)", tickValue, tickSize));
        if (tickValue != 0)
        {

            double maxLossInQuoteCurrency = maxLoss / tickValue;

            double optimalLotSize = NormalizeDouble(maxLossInQuoteCurrency / (maxLossInPips * GetPipValueFromDigits()) / lotSize, 2);
            log(StringFormat("Balance :%+.0f %s, Equity: %+.0f %s, MaxLoss :%+.0f %s, maxLossInPips:%d", accBalance, accCurr, accEquity, accCurr, maxLoss, accCurr, maxLossInPips));

            log(StringFormat("RISK_ALLOWED: %f, maxLossInQuoteCurrency :%f, optimalLotSize: %f", maxRiskPerc, maxLossInQuoteCurrency, optimalLotSize));
            return optimalLotSize;
        }
        else
        {
            warn("Tick Value is zero");
            return 0;
        }
    }

    double optimalLotSize(double maxRiskPerc, double entryPrice, double stopLoss)
    {
        int maxLossInPips = MathAbs(entryPrice - stopLoss) / GetPipValueFromDigits();
        return optimalLotSize(maxRiskPerc, maxLossInPips);
    }

    double optimalLotSize(double entryPrice, double stopLoss)
    {
        return optimalLotSize(itsRiskPercentage, entryPrice, stopLoss);
    }

public:
    RiskManager(double riskPercentage = 0.02)
    {
        itsRiskPercentage = riskPercentage;
    }
};