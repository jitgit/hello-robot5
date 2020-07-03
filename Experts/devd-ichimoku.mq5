#property copyright "DevD"
#property link "https://www.devd.com"
#property version "1.00"
#include <devd/common.mqh>
int KUMO_AHEAD_COUNT = 26;
class KumoSpan {
   public:
    double values[];
    int flatCount;  //Number of TS when non change
    double avgAngle;
    string str() {
        return StringFormat("flatCount(%d), averageAngle (%f)", flatCount, avgAngle);
    }
    KumoSpan() {
        flatCount = 0;
        avgAngle = 0;
    }
};

class Kumo {
   public:
    KumoSpan *spanA;
    KumoSpan *spanB;
    double kijun[];   //Baseline
    double tenkan[];  //Fast MA
    datetime ts[];
    int cloudLength;  //Index of above TS when most recently cloud flips - 1, This can be array as well.
    int cloudDirection;
    double cloudMouthSpread;
    
    int senCrossOver;

    Kumo() {
        spanA = new KumoSpan();
        spanB = new KumoSpan();
        cloudDirection = 0;
        cloudMouthSpread = 0.0;
        senCrossOver = -1;
    }

    string str() {
         string c =  StringFormat("Kumo/Total(%d/%d), range [%s ,%s], cloud(↑↓(%d), width %f)", cloudLength, ArraySize(spanA.values), tsDate(ts[cloudLength]), tsDate(ts[0]), cloudDirection, cloudMouthSpread);
         string sen = StringFormat("Sen Cross (%d) @ %s ",senCrossOver,tsDate(ts[senCrossOver + KUMO_AHEAD_COUNT]));
         return c +"\n"+sen;
    }
};

class KumoParam {
   public:
    ENUM_TIMEFRAMES timeFrame;
    int totalHistory;
    int ichimokuHandle;

    KumoParam(ENUM_TIMEFRAMES tf) {
        timeFrame = tf;
        totalHistory = 100;  //We take an appx. number of candle in which a kumo flip can be found
    }
};

void OnStart() {
    KumoParam *h4Param = new KumoParam(_Period);
    Kumo *h4Kumo = buildKumo(h4Param);

    /*KumoParam* h1Param = new KumoParam(PERIOD_H1);
   Kumo* h1Kumo = buildKumo(h1Param);

   KumoParam* m5Param = new KumoParam(PERIOD_M5);
   Kumo* m5Kumo = buildKumo(m5Param);

   KumoParam* m1Param = new KumoParam(PERIOD_M1);
   Kumo* m1Kumo = buildKumo(m1Param);*/
}

Kumo *buildKumo(KumoParam &kumoParam) {
    kumoParam.ichimokuHandle = iIchimoku(_Symbol, kumoParam.timeFrame, 9, 26, 52);

    Kumo *kumpBeforeCurrentTS = new Kumo();
    addPreviousKumo(kumoParam, kumpBeforeCurrentTS);

    Kumo *futureKumo = futureKumoInfo(kumoParam);

    Kumo *totalKumo = mergePreviousAndFutureKumo(kumpBeforeCurrentTS, futureKumo);

    findKumoFlip(kumoParam.totalHistory, totalKumo);
    findTenkenKijunFlip(kumoParam.totalHistory, totalKumo);

    addFlatKumoBarCountAndAngle(totalKumo);

    Print("=============================", PeriodSeconds(kumoParam.timeFrame) / 60, "(m)=================================");
    printKumo(totalKumo);
    return totalKumo;
}

void addFlatKumoBarCountAndAngle(Kumo &k) {
    printAverageAngle(k.spanA, k.ts, "Span A", k.cloudLength);
    printAverageAngle(k.spanB, k.ts, "Span B", k.cloudLength);

    if (ArraySize(k.spanA.values) > 0 && ArraySize(k.spanB.values) > 0) {
        /*SymbolData *s = new SymbolData(_Symbol);
            PrintFormat("---> %s", s.str());
            PrintFormat("Diff spanA.values[0] - spanB.values[0] = %f", spanA.values[0] - spanB.values[0]);*/
        k.cloudDirection = k.spanA.values[0] > k.spanB.values[0] ? 1 : -1;
        k.cloudMouthSpread = k.spanA.values[0] - k.spanB.values[0];
    }
}

void printAverageAngle(KumoSpan *span, datetime &tm[], string arrayName, int cloudLength) {
    int arraySize = ArraySize(span.values);

    // Print(arrayName, " - valueArray :", arraySize, ", TimeArray :", ArraySize(tm), ", cloudLength :" , cloudLength);
    int x = 0;
    double totalAngle = 0;

    datetime xOriginShift = tm[cloudLength];
    double yOriginShift = span.values[arraySize - 1];
    for (int i = cloudLength + 1; i >= 1; i--) {
        int x1 = tm[i] - xOriginShift;
        int x2 = tm[i - 1] - xOriginShift;
        double y1 = span.values[i];      //(MathPow(10, _Digits) * array[i]) - yOriginShift;
        double y2 = span.values[i - 1];  //(MathPow(10, _Digits) * array[i - 1]) - yOriginShift;
        double angle = MathTanh((y2 - y1) / (x2 - x1));

        if (y1 == y2) {  //Collecting how many time the curve is flat
            // PrintFormat(tm[i] + " P2(%f,%f) "+tm[i-1]+ " P1(%f,%f) , Angle: %f ", x2, y2, x1, y1, angle);
            span.flatCount = span.flatCount + 1;
        }

        totalAngle += angle;
        x++;
    }
    span.avgAngle = totalAngle;
    // PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}

void addPreviousKumo(KumoParam &kumoParam, Kumo &k) {
    datetime currentCandleTS = getCurrentCandleTS(kumoParam);

    //Copy Previous TS/SpanAB values
    ArraySetAsSeries(k.spanA.values, true);
    ArraySetAsSeries(k.spanB.values, true);
    ArraySetAsSeries(k.ts, true);
    ArraySetAsSeries(k.kijun, true);
    ArraySetAsSeries(k.tenkan, true);

    CopyBuffer(kumoParam.ichimokuHandle, 0, 0, kumoParam.totalHistory, k.tenkan);
    CopyBuffer(kumoParam.ichimokuHandle, 1, 0, kumoParam.totalHistory, k.kijun);
    CopyBuffer(kumoParam.ichimokuHandle, 2, 0, kumoParam.totalHistory, k.spanA.values);
    CopyBuffer(kumoParam.ichimokuHandle, 3, 0, kumoParam.totalHistory, k.spanB.values);
    CopyTime(_Symbol, kumoParam.timeFrame, currentCandleTS, kumoParam.totalHistory, k.ts);
}

Kumo *futureKumoInfo(KumoParam &kumoParam) {
    Kumo *r = new Kumo();

    int aheadCloudDelta = -KUMO_AHEAD_COUNT;  //As kumo cloud has 26 bar more values
    int totalCandles = MathAbs(aheadCloudDelta);
    ArraySetAsSeries(r.spanA.values, true);
    ArraySetAsSeries(r.spanB.values, true);
    ArraySetAsSeries(r.ts, true);
    ArrayResize(r.ts, totalCandles);

    CopyBuffer(kumoParam.ichimokuHandle, 2, aheadCloudDelta, totalCandles, r.spanA.values);
    CopyBuffer(kumoParam.ichimokuHandle, 3, aheadCloudDelta, totalCandles, r.spanB.values);

    //Future TS needs to manually calculated, CopyTime doesn't work. TODO Exclude weekend
    datetime currentCandleTS = getCurrentCandleTS(kumoParam);
    for (int i = totalCandles - 1; i >= 0; i--) {
        r.ts[i] = currentCandleTS + (PeriodSeconds(kumoParam.timeFrame) * (totalCandles - i));
    }

    return r;
}

void findTenkenKijunFlip(int totalHistory, Kumo &kumo) {
    int arrayLength = ArraySize(kumo.tenkan);

    int result = arrayLength - 1;
    for (int i = 0; i < arrayLength - 1; i++) {
        double t0 = kumo.tenkan[i];
        double k0 = kumo.kijun[i];
        double t1 = kumo.tenkan[i + 1];
        double k1 = kumo.kijun[i + 1];
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
    ArraySetAsSeries(r.tenkan, true);
    ArraySetAsSeries(r.kijun, true);

    int futureArraySize = ArraySize(future.spanA.values);

    ArrayCopy(r.spanA.values, future.spanA.values, 0, 0, futureArraySize);
    ArrayCopy(r.spanB.values, future.spanB.values, 0, 0, futureArraySize);
    ArrayCopy(r.ts, future.ts, 0, 0, futureArraySize);

    ArrayCopy(r.spanA.values, previous.spanA.values, futureArraySize, 0, ArraySize(previous.spanA.values));
    ArrayCopy(r.spanB.values, previous.spanB.values, futureArraySize, 0, ArraySize(previous.spanB.values));
    ArrayCopy(r.ts, previous.ts, futureArraySize, 0, ArraySize(previous.ts));
    ArrayCopy(r.kijun, previous.kijun, 0, 0, ArraySize(previous.spanA.values));
    ArrayCopy(r.tenkan, previous.tenkan, 0, 0, ArraySize(previous.spanB.values));

    return r;
}

void printKumo(Kumo *k) {
    //for (int i = ArraySize(k.spanA.values) - 1; i >= 0; i--)  PrintFormat(k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
    PrintFormat("%s", k.str());
    PrintFormat("SpanA[%s]", k.spanA.str());
    PrintFormat("SpanB[%s]", k.spanB.str());
}

datetime getCurrentCandleTS(KumoParam &kumoParam) {
    datetime tm[];  // array storing the returned bar time
    ArraySetAsSeries(tm, true);
    CopyTime(_Symbol, kumoParam.timeFrame, 0, 1, tm);  //Getting the current candle time
    return tm[0];
}
