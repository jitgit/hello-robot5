//+------------------------------------------------------------------+
//|                                                 Jatin Patel DevD |
//|                                                 https://devd.com |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum GO
{
    GO_NOTHING,
    GO_LONG,
    GO_SHORT
};

struct SignalResult
{
    GO go;
    double entry;
    double stopLoss;
    double takeProfit;

    string str()
    {
        return StringFormat(" GO: %d, entryPrice: %f, stopLoss: %f, takeProfit: %f", go, entry, stopLoss, takeProfit);
    }
};

class SignalScanner
{

public:
    virtual SignalResult scan()
    {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};
        return result;
    }

    virtual int magicNumber()
    {
        return -1;
    }

    virtual double optimizedLongTP()
    {
        return 0.0;
    }
    virtual double optimizedShortTP() { return 0.0; }

public:
    SignalScanner()
    {
    }
};

//+------------------------------------------------------------------+
