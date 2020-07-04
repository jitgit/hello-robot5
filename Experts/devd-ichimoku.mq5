#property copyright "DevD"
#property link "https://www.devd.com"
#property version "1.00"
#include <devd/include-base.mqh>

int KUMO_AHEAD_COUNT = 26;

int ANGLE_AVERAGE_COUNT = 3;

class IchimokuLine {
   public:
    double values[];
    int flatCount;  //Number of TS when non change
    double avgAngle;
    double lineAngle;
    int candleForAngle;
    string str() {
        return StringFormat("flatCount(%d), Avg-Angle(%f), (%d)Line Angle(%f)", flatCount, avgAngle, candleForAngle, lineAngle);
    }
    IchimokuLine() {
        flatCount = 0;
        avgAngle = 0;
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
    int priceToKumoPosition;

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
        priceToKumoPosition = 0;
    }

    string str() {
        string c = StringFormat("Kumo/Total(%d/%d), range [%s ,%s], cloud(↑↓(%d), width %f)", cloudLength, ArraySize(spanA.values), tsDate(ts[cloudLength]), tsDate(ts[0]), cloudDirection, cloudMouthSpread);
        string sen = StringFormat("Sen(↑↓(%d), width %f) Cross (%d)@%s", senDirection, senMouthSpread, senCrossOver, tsDate(ts[senCrossOver + KUMO_AHEAD_COUNT]));
        string position = StringFormat("Kumo<->Price(↑↓(%d)) ", priceToKumoPosition);
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
};

void OnStart() {
    KumoParam *h4Param = new KumoParam(_Symbol, _Period);
    Kumo *h4Kumo = buildKumo(h4Param);

    /*KumoParam* h1Param = new KumoParam(PERIOD_H1);
   Kumo* h1Kumo = buildKumo(h1Param);

   KumoParam* m5Param = new KumoParam(PERIOD_M5);
   Kumo* m5Kumo = buildKumo(m5Param);

   KumoParam* m1Param = new KumoParam(PERIOD_M1);
   Kumo* m1Kumo = buildKumo(m1Param);*/
}

Kumo *buildKumo(KumoParam &kumoParam) {
    kumoParam.ichimokuHandle = iIchimoku(kumoParam.symbol, kumoParam.timeFrame, 9, 26, 52);

    Kumo *kumpBeforeCurrentTS = new Kumo();
    addPreviousKumo(kumoParam, kumpBeforeCurrentTS);

    Kumo *futureKumo = futureKumoInfo(kumoParam);

    Kumo *totalKumo = mergePreviousAndFutureKumo(kumpBeforeCurrentTS, futureKumo);

    findKumoFlip(kumoParam.totalHistory, totalKumo);
    findTenkenKijunFlip(kumoParam.totalHistory, totalKumo);

    addFlatKumoBarCountAndAngle(totalKumo, kumoParam);

    Print("=============================", EnumToString(kumoParam.timeFrame), "=======================================");
    printKumo(totalKumo);
    return totalKumo;
}

void addFlatKumoBarCountAndAngle(Kumo &k, KumoParam &p) {
    addAverageAngleFor(k.spanA, k.ts, "Span A", ANGLE_AVERAGE_COUNT);
    addAverageAngleFor(k.spanB, k.ts, "Span B", ANGLE_AVERAGE_COUNT);
    addLineAngleFor(k.spanA, k.ts, "Span A", 10 * ANGLE_AVERAGE_COUNT);
    addLineAngleFor(k.spanB, k.ts, "Span B", 10 * ANGLE_AVERAGE_COUNT);

    addAverageAngleFor(k.tenkan, k.ts, "Tenken", 2 * ANGLE_AVERAGE_COUNT);
    addAverageAngleFor(k.kijuan, k.ts, "Kijuan", 2 * ANGLE_AVERAGE_COUNT);
    addLineAngleFor(k.tenkan, k.ts, "Tenken", 10 * ANGLE_AVERAGE_COUNT, KUMO_AHEAD_COUNT);
    addLineAngleFor(k.kijuan, k.ts, "Kijuan", 10 * ANGLE_AVERAGE_COUNT, KUMO_AHEAD_COUNT);

    addCloudAndSenDirection(k, p);


    double high = iHigh(p.symbol, p.timeFrame, 0);
    double low = iLow(p.symbol, p.timeFrame, 0);
    // PrintFormat("%s %s @ %s  O(%f), H(%f), L(%f), C(%f) ", p.symbol, EnumToString(p.timeFrame), tsDate(iTime(p.symbol, p.timeFrame, 0)), iOpen(p.symbol, p.timeFrame, 0), high, low, iClose(p.symbol, p.timeFrame, 0));
    double spanA = k.spanA.values[KUMO_AHEAD_COUNT];
    double spanB = k.spanB.values[KUMO_AHEAD_COUNT];
    // PrintFormat("%s A(%f) B(%f) ", tsDate(k.ts[KUMO_AHEAD_COUNT]), spanA, spanB);
    if (high > spanA && high > spanB && low > spanA && low > spanB)
        k.priceToKumoPosition = 1;
    else if (high < spanA && high < spanB && low < spanA && low < spanB)
        k.priceToKumoPosition = -1;
    else
        k.priceToKumoPosition = 0;
}

void addCloudAndSenDirection(Kumo &k, KumoParam &p) {
    if (ArraySize(k.spanA.values) > 0 && ArraySize(k.spanB.values) > 0) {
        k.cloudDirection = k.spanA.values[0] > k.spanB.values[0] ? 1 : -1;
        k.cloudMouthSpread = k.spanA.values[0] - k.spanB.values[0];
    } else {
        warn("Kumo Span Arrays are empty");
    }

    if (ArraySize(k.tenkan.values) > 0 && ArraySize(k.kijuan.values) > 0) {
        k.senDirection = k.tenkan.values[0] > k.kijuan.values[0] ? 1 : -1;
        k.senMouthSpread = k.tenkan.values[0] - k.kijuan.values[0];
    } else {
        warn("Sen Arrays are empty");
    }
}

void addAverageAngleFor(IchimokuLine *span, datetime &tm[], string arrayName, int cloudLength) {
    int arraySize = ArraySize(span.values);

    // Print(arrayName, " - valueArray :", arraySize, ", TimeArray :", ArraySize(tm), ", cloudLength :" , cloudLength);
    int x = 0;
    double totalAngle = 0;
    SymbolData *s = new SymbolData(_Symbol);
    datetime xOriginShift = tm[cloudLength + 1];
    double yOriginShift = span.values[arraySize - 1];
    for (int i = cloudLength; i >= 1; i--) {
        int x1 = tm[i] - xOriginShift;
        int x2 = tm[i - 1] - xOriginShift;
        double y1 = span.values[i];
        double y2 = span.values[i - 1];
        if (y1 == y2) {  //Collecting how many time the curve is flat
            span.flatCount = span.flatCount + 1;
        }
        double angle_with_point_scaling = (angleInDegree(x1, y1, x2, y2) / s.point) * 100;
        //PrintFormat("%s -> P1(%s) [%d, %f] ===>  P2(%s) [%d, %f]  , Angle= %f", arrayName, tsDate(tm[i]), x1, y1, tsDate(tm[i - 1]), x2, y2, angle_with_point_scaling);
        totalAngle += angle_with_point_scaling;
        x++;
    }
    span.avgAngle = totalAngle / (cloudLength - 1);
    // PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}

void addLineAngleFor(IchimokuLine *span, datetime &tm[], string arrayName, int barCount, int cloudDisplacment = 0) {
    datetime xOriginShift = tm[barCount + cloudDisplacment];

    SymbolData *s = new SymbolData(_Symbol);
    int x1 = tm[barCount + cloudDisplacment] - xOriginShift;
    int x2 = tm[cloudDisplacment] - xOriginShift;
    double y1 = span.values[barCount];
    double y2 = span.values[0];
    double angle_with_point_scaling = (angleInDegree(x1, y1, x2, y2) / s.point) * 100;
    span.candleForAngle = barCount;
    span.lineAngle = angle_with_point_scaling;
    //PrintFormat("%s -> P1(%s) [%d, %f] ===>  P2(%s) [%d, %f]  , Angle= %f", arrayName, tsDate(tm[barCount + cloudDisplacment]), x1, y1, tsDate(tm[cloudDisplacment]), x2, y2, angle_with_point_scaling);
}
double angleInDegree(double x1, double y1, double x2, double y2) {
    double angle_in_radians = MathArctan((y2 - y1) / (x2 - x1));
    double angle_in_degree = 180 * angle_in_radians / MathArccos(-1.0);
    return angle_in_degree;
}

void addPreviousKumo(KumoParam &p, Kumo &k) {
    datetime currentCandleTS = getCurrentCandleTS(p);

    //Copy Previous TS/SpanAB values
    ArraySetAsSeries(k.spanA.values, true);
    ArraySetAsSeries(k.spanB.values, true);
    ArraySetAsSeries(k.ts, true);
    ArraySetAsSeries(k.kijuan.values, true);
    ArraySetAsSeries(k.tenkan.values, true);

    CopyBuffer(p.ichimokuHandle, 0, 0, p.totalHistory, k.tenkan.values);
    CopyBuffer(p.ichimokuHandle, 1, 0, p.totalHistory, k.kijuan.values);
    CopyBuffer(p.ichimokuHandle, 2, 0, p.totalHistory, k.spanA.values);
    CopyBuffer(p.ichimokuHandle, 3, 0, p.totalHistory, k.spanB.values);
    CopyTime(p.symbol, p.timeFrame, currentCandleTS, p.totalHistory, k.ts);
}

Kumo *futureKumoInfo(KumoParam &p) {
    Kumo *r = new Kumo();

    int aheadCloudDelta = -KUMO_AHEAD_COUNT;  //As kumo cloud has 26 bar more values
    int totalCandles = MathAbs(aheadCloudDelta);
    ArraySetAsSeries(r.spanA.values, true);
    ArraySetAsSeries(r.spanB.values, true);
    ArraySetAsSeries(r.ts, true);
    ArrayResize(r.ts, totalCandles);

    CopyBuffer(p.ichimokuHandle, 2, aheadCloudDelta, totalCandles, r.spanA.values);
    CopyBuffer(p.ichimokuHandle, 3, aheadCloudDelta, totalCandles, r.spanB.values);

    //Future TS needs to manually calculated, CopyTime doesn't work. TODO Exclude weekend
    datetime currentCandleTS = getCurrentCandleTS(p);
    for (int i = totalCandles - 1; i >= 0; i--) {
        r.ts[i] = currentCandleTS + (PeriodSeconds(p.timeFrame) * (totalCandles - i));
    }

    return r;
}

void findTenkenKijunFlip(int totalHistory, Kumo &kumo) {
    int arrayLength = ArraySize(kumo.tenkan.values);

    int result = arrayLength - 1;
    for (int i = 0; i < arrayLength - 1; i++) {
        double t0 = kumo.tenkan.values[i];
        double k0 = kumo.kijuan.values[i];
        double t1 = kumo.tenkan.values[i + 1];
        double k1 = kumo.kijuan.values[i + 1];
        //PrintFormat(i + ". %s  T0(%f), K0(%f)", tsDate(kumo.ts[i + KUMO_AHEAD_COUNT]), t0, k0);
        //PrintFormat(i + 1 + ". %s  T1(%f), K1(%f)", tsDate(kumo.ts[i + 1 + KUMO_AHEAD_COUNT]), t1, k1);
        if ((t0 > k0 && t1 <= k1) || (t0 < k0 && t1 >= k1)) {
            result = MathMin(i + 1, arrayLength - 1);
            break;
        }
    }
    kumo.senCrossOver = result;
}

void findKumoFlip(int totalHistory, Kumo &k) {
    int arrayLength = ArraySize(k.spanA.values);

    k.cloudLength = arrayLength - 1;
    for (int i = 0; i < arrayLength - 1; i++) {
        double pA0 = k.spanA.values[i];
        double pB0 = k.spanB.values[i];
        double pA1 = k.spanA.values[i + 1];
        double pB1 = k.spanB.values[i + 1];

        //PrintFormat(i + ". %s  pA0(%f), K0(%f)", tsDate(k.ts[i]), pA0, pB0);
        //PrintFormat(i + 1 + ". %s  pA1(%f), K1(%f)", tsDate(k.ts[i + 1 ]), pA1, pB1);
        if ((pA0 > pB0 && pA1 <= pB1) || (pA0 < pB0 && pA1 >= pB1)) {
            k.cloudLength = MathMin(i, arrayLength - 1);
            break;
        }
    }
}

Kumo *mergePreviousAndFutureKumo(Kumo &previous, Kumo *future) {
    Kumo *r = new Kumo();

    r.cloudLength = previous.cloudLength;

    int totalLength = ArraySize(previous.spanA.values) + ArraySize(future.spanA.values);
    ArrayResize(r.spanA.values, totalLength);
    ArrayResize(r.spanB.values, totalLength);
    ArrayResize(r.ts, totalLength);

    ArraySetAsSeries(r.spanA.values, true);
    ArraySetAsSeries(r.spanB.values, true);
    ArraySetAsSeries(r.ts, true);
    ArraySetAsSeries(r.tenkan.values, true);
    ArraySetAsSeries(r.kijuan.values, true);

    int futureArraySize = ArraySize(future.spanA.values);

    ArrayCopy(r.spanA.values, future.spanA.values, 0, 0, futureArraySize);
    ArrayCopy(r.spanB.values, future.spanB.values, 0, 0, futureArraySize);
    ArrayCopy(r.ts, future.ts, 0, 0, futureArraySize);

    ArrayCopy(r.spanA.values, previous.spanA.values, futureArraySize, 0, ArraySize(previous.spanA.values));
    ArrayCopy(r.spanB.values, previous.spanB.values, futureArraySize, 0, ArraySize(previous.spanB.values));
    ArrayCopy(r.ts, previous.ts, futureArraySize, 0, ArraySize(previous.ts));
    ArrayCopy(r.kijuan.values, previous.kijuan.values, 0, 0, ArraySize(previous.kijuan.values));
    ArrayCopy(r.tenkan.values, previous.tenkan.values, 0, 0, ArraySize(previous.tenkan.values));

    return r;
}

void printKumo(Kumo *k) {
    //for (int i = ArraySize(k.spanA.values) - 1; i >= 0; i--)  PrintFormat(k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
    SymbolData *s = new SymbolData(_Symbol);
    PrintFormat("#%s", s.str());
    PrintFormat("%s", k.str());
    PrintFormat("SpanA[%s]", k.spanA.str());
    PrintFormat("SpanB[%s]", k.spanB.str());
    PrintFormat("Tenkan[%s]", k.tenkan.str());
    PrintFormat("Kijuan[%s]", k.kijuan.str());
}

datetime getCurrentCandleTS(KumoParam &kumoParam) {
    datetime tm[];  // array storing the returned bar time
    ArraySetAsSeries(tm, true);
    CopyTime(_Symbol, kumoParam.timeFrame, 0, 1, tm);  //Getting the current candle time
    return tm[0];
}
