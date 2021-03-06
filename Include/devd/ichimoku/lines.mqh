#property strict
#include <Object.mqh>

class IchimokuLine {
   public:
    double values[];
    int flats;  //Number of TS when non change
    double lineAngle;
    int candleForAngle;
    string str() {
        return StringFormat("(%2.1f)", lineAngle);
    }
    string str1() {
        return StringFormat("flats(%d), (%d)Angle(%2.1f)", flats, candleForAngle, lineAngle);
    }
    IchimokuLine() {
        flats = 0;
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
        //string c = StringFormat("Kumo(%d/%d), [%s ,%s], Cloud(↨%d, width %f)", cloudLength, ArraySize(spanA.values), tsDate(ts[cloudLength]), tsDate(ts[0]), cloudDirection, cloudMouthSpread);
        string c = StringFormat("Kumo(%d/%d), Cloud(↨%d)", cloudLength, ArraySize(spanA.values), cloudDirection);
        string sen = StringFormat("Sen↨(%d)", senDirection);  //, width %f) Cross (%d)@%s", senDirection, senMouthSpread, senCrossOver, tsDate(ts[senCrossOver + KUMO_AHEAD_COUNT]));
        string position = StringFormat("Kumo↨Price(%d)", pricePositionToKumo);
        string spanA = StringFormat("Span A%s", spanA.str());
        string spanB = StringFormat("Span B%s", spanB.str());
        string tenkan = StringFormat("Tenkan%s", tenkan.str());
        string kijuan = StringFormat("Kijuan%s", kijuan.str());
        return c + ", " + sen + ", " + position + ", " + spanA + ", " + spanB + ", " + tenkan + ", " + kijuan;
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

class KumoAnalysis : public CObject {
   public:
    Kumo *k;
    KumoParam *p;  //Number of TS when non change
    int trend;

    string str() {
        return StringFormat("%s(%s), %s, ║%d║", p.symbol, EnumToString(p.timeFrame), k.str(), trend);
    }
    KumoAnalysis() {
        trend = 0;
    }
};