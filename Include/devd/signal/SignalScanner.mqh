#property strict

class SignalScanner {
   public:
    SignalScanner() {
    }
    virtual SignalResult scan() {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};
        return result;
    }

    virtual SignalResult scan(ENUM_TIMEFRAMES &timeFrames[]) {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};
        return result;
    }

    virtual int magic() {
        return -1;
    }

    virtual double optimizedLongTP() {
        return 0.0;
    }
    virtual double optimizedShortTP() { return 0.0; }
};