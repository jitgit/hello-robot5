#property strict

class SignalScanner {
   public:
    virtual SignalResult scan() {
        SignalResult result = {GO_NOTHING, -1.0, -1.0, -1.0};
        return result;
    }

    virtual int magicNumber() {
        return -1;
    }

    virtual double optimizedLongTP() {
        return 0.0;
    }
    virtual double optimizedShortTP() { return 0.0; }

   public:
    SignalScanner() {
    }
};