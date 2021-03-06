#property strict

#include <devd/ichimoku/lines.mqh>
#include <devd/include-base.mqh>

int KUMO_AHEAD_COUNT = 26;
int KUMO_ANGLE_BARS = 2;
int SEN_ANGLE_BARS = 2;

int MINIMUM_ANGLE = 3;
int MINIMUM_CLOUD_LENGTH = 7;
int TENKAN_ANGLE = 30;

KumoAnalysis *getKumoAnalysis(SymbolData *s, ENUM_TIMEFRAMES tf) {
    KumoAnalysis *result = new KumoAnalysis();
    KumoParam *p = new KumoParam(s.Name(), tf);
    Kumo *k = buildKumo(p, s);
    result.p = p;
    result.k = k;
    result.trend = getTrend(k);
    return result;
}

int getTrend(Kumo *k) {
    int t = 0;
    if (k.cloudDirection > 0 && k.cloudLength >= MINIMUM_CLOUD_LENGTH                                              //Cloud Overall Direction
        && (k.spanB.lineAngle >= MINIMUM_ANGLE || (k.spanB.lineAngle == 0 && k.spanA.lineAngle >= MINIMUM_ANGLE))  //Angle of cloud
        && (k.kijuan.lineAngle >= MINIMUM_ANGLE)                                                                   // || (k.kijuan.lineAngle  == 0 && k.tenkan.lineAngle>= TENKAN_ANGLE))
        && k.pricePositionToKumo > 0) {
        t = 1;
    } else if (k.cloudDirection < 0 && k.cloudLength >= MINIMUM_CLOUD_LENGTH                                               //Cloud Overall Direction
               && (k.spanB.lineAngle <= -MINIMUM_ANGLE || (k.spanB.lineAngle == 0 && k.spanA.lineAngle <= MINIMUM_ANGLE))  //Angle of cloud
               && (k.kijuan.lineAngle <= -MINIMUM_ANGLE)                                                                   // || (k.kijuan.lineAngle  == 0 && k.tenkan.lineAngle<= -TENKAN_ANGLE))
               && k.pricePositionToKumo < 0) {
        t = -1;
    }
    return t;
}

Kumo *buildKumo(KumoParam *p, SymbolData *s) {
    p.ichimokuHandle = iIchimoku(p.symbol, p.timeFrame, 9, 26, 52);
    Kumo *kumpBeforeCurrentTS = new Kumo();
    addPreviousKumo(p, kumpBeforeCurrentTS);

    Kumo *futureKumo = futureKumoInfo(p);

    Kumo *totalKumo = mergePreviousAndFutureKumo(kumpBeforeCurrentTS, futureKumo);

    findKumoFlip(p.totalHistory, totalKumo);
    findTenkenKijunFlip(p.totalHistory, totalKumo);

    addFlatKumoBarCountAndAngle(totalKumo, p, s);

    debug(StringFormat("=============================(%s)=======================================", EnumToString(p.timeFrame)));
    debug(StringFormat("%s", totalKumo.str()));
    return totalKumo;
}

void addFlatKumoBarCountAndAngle(Kumo *k, KumoParam *p, SymbolData *s) {
    //Kumo Span
    addFlatsCountFor(k.spanA, s, k.ts, "Span A", KUMO_ANGLE_BARS);
    addFlatsCountFor(k.spanB, s, k.ts, "Span B", KUMO_ANGLE_BARS);
    addLineAngleFor(k.spanA, s, k.ts, "Span A", KUMO_ANGLE_BARS);
    addLineAngleFor(k.spanB, s, k.ts, "Span B", KUMO_ANGLE_BARS);

    //Sen Lines
    addFlatsCountFor(k.tenkan, s, k.ts, "Tenken", 2 * SEN_ANGLE_BARS);
    addFlatsCountFor(k.kijuan, s, k.ts, "Kijuan", 2 * SEN_ANGLE_BARS);
    addLineAngleFor(k.tenkan, s, k.ts, "Tenken", SEN_ANGLE_BARS, KUMO_AHEAD_COUNT);
    addLineAngleFor(k.kijuan, s, k.ts, "Kijuan", SEN_ANGLE_BARS, KUMO_AHEAD_COUNT);

    addCloudAndSenDirection(k, p);

    double open = iOpen(p.symbol, p.timeFrame, 0);
    double close = iClose(p.symbol, p.timeFrame, 0);
    // PrintFormat("%s %s @ %s  O(%f), H(%f), L(%f), C(%f) ", p.symbol, EnumToString(p.timeFrame), tsDate(iTime(p.symbol, p.timeFrame, 0)), iOpen(p.symbol, p.timeFrame, 0), high, low, iClose(p.symbol, p.timeFrame, 0));
    double spanA = k.spanA.values[KUMO_AHEAD_COUNT];
    double spanB = k.spanB.values[KUMO_AHEAD_COUNT];
    // PrintFormat("%s A(%f) B(%f) ", tsDate(k.ts[KUMO_AHEAD_COUNT]), spanA, spanB);
    if (open > spanA && open > spanB && close > spanA && close > spanB)
        k.pricePositionToKumo = 1;
    else if (open < spanA && open < spanB && close < spanA && close < spanB)
        k.pricePositionToKumo = -1;
    else
        k.pricePositionToKumo = 0;
}

void addCloudAndSenDirection(Kumo *k, KumoParam *p) {
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

void addFlatsCountFor(IchimokuLine *span, SymbolData *s, datetime &tm[], string arrayName, int includedBars) {
    int arraySize = ArraySize(span.values);

    // Print(arrayName, " - valueArray :", arraySize, ", TimeArray :", ArraySize(tm), ", cloudLength :" , cloudLength);
    double totalAngle = 0;
    datetime xOriginShift = tm[includedBars + 1];
    double yOriginShift = span.values[arraySize - 1];
    for (int i = includedBars - 1; i >= 1; i--) {
        int x1 = tm[i] - xOriginShift;
        int x2 = tm[i - 1] - xOriginShift;
        double y1 = span.values[i];
        double y2 = span.values[i - 1];
        if (y1 == y2) {  //Collecting how many time the curve is flat
            span.flats = span.flats + 1;
        }
        //double angle_with_point_scaling = (angleInDegree(x1, y1, x2, y2) / s.point) * 100;
        //PrintFormat("%s -> P1(%s) [%d, %f] ===>  P2(%s) [%d, %f]  , Angle= %f", arrayName, tsDate(tm[i]), x1, y1, tsDate(tm[i - 1]), x2, y2, angle_with_point_scaling);
        //totalAngle += angle_with_point_scaling;
    }
    // PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}

void addLineAngleFor(IchimokuLine *span, SymbolData *s, datetime &tm[], string arrayName, int includedBars, int cloudDisplacment = 0) {
    datetime xOriginShift = tm[includedBars - 1 + cloudDisplacment];

    int startIndex = includedBars - 1 + cloudDisplacment;
    int x1 = tm[startIndex] - xOriginShift;
    int x2 = tm[cloudDisplacment] - xOriginShift;
    double y1 = span.values[includedBars - 1];
    double y2 = span.values[0];
    double hundreds = s.digit == 5 ? 100 : 10;  //Angle is not exact but it will make sure atleast positive/negative based on digits & that is what we use for trend
    double angle_with_point_scaling = (angleInDegree(x1, y1, x2, y2) / s.point) * hundreds;
    span.candleForAngle = includedBars;
    span.lineAngle = angle_with_point_scaling;
    //info(StringFormat("%s -> P1(%s) [%d, %f] ===>  P2(%s) [%d, %f]  , Angle= %f", arrayName, tsDate(tm[startIndex]), x1, y1, tsDate(tm[cloudDisplacment]), x2, y2, angle_with_point_scaling));
}
double angleInDegree(double x1, double y1, double x2, double y2) {
    double angle_in_radians = MathArctan((y2 - y1) / (x2 - x1));
    double angle_in_degree = 180 * angle_in_radians / MathArccos(-1.0);
    return angle_in_degree;
}

void addPreviousKumo(KumoParam *p, Kumo *k) {
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

Kumo *futureKumoInfo(KumoParam *p) {
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

void findTenkenKijunFlip(int totalHistory, Kumo *kumo) {
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

void findKumoFlip(int totalHistory, Kumo *k) {
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

Kumo *mergePreviousAndFutureKumo(Kumo *previous, Kumo *future) {
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
datetime getCurrentCandleTS(KumoParam *p) {
    datetime tm[];  // array storing the returned bar time
    ArraySetAsSeries(tm, true);
    CopyTime(p.symbol, p.timeFrame, 0, 1, tm);  //Getting the current candle time
    return tm[0];
}