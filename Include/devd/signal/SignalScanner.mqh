#property strict

class SignalScanner {
   public:
    SignalScanner() {
    }
    virtual SignalResult* scan(string symbol) {
        SignalResult* result = new SignalResult(symbol);
        return result;
    }

    virtual SignalResult* scan(string symbol, ENUM_TIMEFRAMES timeFrame) {
        SignalResult* result = new SignalResult(symbol);
        return result;
    }

    virtual int magic() {
        return -1;
    }

    virtual double optimizedLongTP(string symbol) {
        return 0.0;
    }
    virtual double optimizedShortTP(string symbol) { return 0.0; }
};