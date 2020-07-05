#property strict

class IchimokuLine {
   public:
    double values[];
    int flatCount;  //Number of TS when non change
    double lineAngle;
    int candleForAngle;
    string str() {
        return StringFormat("flatCount(%d), (%d)Line Angle(%f)", flatCount, candleForAngle, lineAngle);
    }
    IchimokuLine() {
        flatCount = 0;
        candleForAngle = -1;
    }
};

class Kumo {
   public:
    IchimokuLine *spanA;
    IchimokuLine *spanB;
    IchimokuLine *kijuan;  //Baseline
    IchimokuLine *tenkan;  //Fast MA
    datetime ts[];
    int cloudLength;  //Index of above TS when most recently cloud flips - 1, This can be array as well.
    int cloudDirection;
    double cloudMouthSpread;

    int senDirection;
    double senMouthSpread;

    int senCrossOver;
    int pricePositionToKumo;

    Kumo() {
        spanA = new IchimokuLine();
        spanB = new IchimokuLine();
        kijuan = new IchimokuLine();
        tenkan = new IchimokuLine();
        cloudDirection = 0;
        cloudMouthSpread = 0.0;
        senCrossOver = -1;
        senDirection = 0;
        senMouthSpread = 0;
        pricePositionToKumo = 0;
    }

    string str() {
        string c = StringFormat("Kumo/Total(%d/%d), range [%s ,%s], cloud(↑↓(%d), width %f)", cloudLength, ArraySize(spanA.values), tsDate(ts[cloudLength]), tsDate(ts[0]), cloudDirection, cloudMouthSpread);
        string sen = StringFormat("Sen(↑↓(%d), width %f) Cross (%d)@%s", senDirection, senMouthSpread, senCrossOver, tsDate(ts[senCrossOver + KUMO_AHEAD_COUNT]));
        string position = StringFormat("Kumo <-> Price(↑↓(%d)) ", pricePositionToKumo);
        return c + "\n" + sen + "\n" + position;
    }
};

class KumoParam {
   public:
    ENUM_TIMEFRAMES timeFrame;
    int totalHistory;
    int ichimokuHandle;
    string symbol;

    KumoParam(string sym, ENUM_TIMEFRAMES tf) {
        symbol = sym;
        timeFrame = tf;
        totalHistory = 100;  //We take an appx. number of candle in which a kumo flip can be found
    }

    string str() {
        return StringFormat("%s - %s", symbol, EnumToString(timeFrame));
    }
};