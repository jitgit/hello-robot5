//+------------------------------------------------------------------+
//|                                                devd-ichimoku.mq5 |
//|                                                             DevD |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "DevD"
#property link "https://www.devd.com"
#property version "1.00"
#include <devd/common.mqh>

class KumoSpan{
public:
   double            values[];
   int flatCount;//Number of TS when non change between TS
   double avgAngle;
   string str()
    {
        return StringFormat("flatCount(%d), averageAngle (%f)", flatCount, avgAngle);
    }
};

class Kumo {
public:   
   KumoSpan* spanA;
   KumoSpan* spanB;   
   
   datetime          ts[];
   int flipTSIndex; //Index of above TS when most recently cloud flips - 1, This can be array as well.
   
   Kumo(){
   spanA = new KumoSpan();
   spanB = new KumoSpan();
   }

};

void OnStart() {


   //We take an appx. number of candle in which a kumo flip can be found
   int ichimokuHandle= iIchimoku(_Symbol, _Period, 9, 26, 52);
   int totalHistory = 200;
   
   Kumo* kumpBeforeCurrentTS = new Kumo();   
   addPreviousKumo(totalHistory, kumpBeforeCurrentTS,ichimokuHandle);

   Kumo* futureKumo = futureKumoInfo(ichimokuHandle);
   
   Kumo* totalKumo = mergePreviousAndFutureKumo(kumpBeforeCurrentTS, futureKumo);
   
   findKumoFlip(totalHistory, totalKumo);
   
   addFlatKumoBarCountAndAngle(totalKumo);
   
   PrintFormat("================================================================");   
   
   printKumo(totalKumo);
   
}

void addFlatKumoBarCountAndAngle(Kumo &k){
   printAverageAngle(k.spanA,k.ts,"Span A", k.flipTSIndex);
   printAverageAngle(k.spanB,k.ts,"Span B", k.flipTSIndex);
}

void printAverageAngle(KumoSpan*  span, datetime &tm[], string arrayName, int flipTSIndex) {
   int arraySize = ArraySize(span.values);
   
   // Print(arrayName, " - valueArray :", arraySize, ", TimeArray :", ArraySize(tm), ", flipTSIndex :" , flipTSIndex);
   int x = 0;
   double totalAngle = 0;
   
   datetime xOriginShift = tm[arraySize - 1];
   double yOriginShift = span.values[arraySize - 1];
   for (int i = flipTSIndex+1; i >= 1; i--) {
      int x1 = tm[i] - xOriginShift;
      int x2 = tm[i - 1] - xOriginShift;
      double y1 = span.values[i];//(MathPow(10, _Digits) * array[i]) - yOriginShift;
      double y2 = span.values[i-1];//(MathPow(10, _Digits) * array[i - 1]) - yOriginShift;
      double angle = MathTanh((y2 - y1) / (x2 - x1));
      
      
      if(y1 == y2 ){ //Collecting how many time the curve is flat
         // PrintFormat(tm[i] + " P2(%f,%f) "+tm[i-1]+ " P1(%f,%f) , Angle: %f ", x2, y2, x1, y1, angle);
         span.flatCount = span.flatCount +1;
       }      
      
      totalAngle += angle;
      x++;
   }
   span.avgAngle = totalAngle;
   // PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}


void addPreviousKumo(int totalHistory, Kumo &k, int ichimokuHandle) {

   datetime currentCandleTS = getCurrentCandleTS();

//Copy Previous TS/SpanAB values
   ArraySetAsSeries(k.spanA.values, true);
   ArraySetAsSeries(k.spanB.values, true);
   ArraySetAsSeries(k.ts, true);
   CopyBuffer(ichimokuHandle, 2, 0, totalHistory, k.spanA.values);
   CopyBuffer(ichimokuHandle, 3, 0, totalHistory, k.spanB.values);
   CopyTime(_Symbol, _Period, currentCandleTS, totalHistory, k.ts);

   PrintFormat("currentCandleTS: " + currentCandleTS);
}



Kumo* futureKumoInfo(int ichimokuHandle) {
   Kumo* r = new Kumo();
    
   int aheadCloudDelta = -26; //As kumo cloud has 26 bar more values
   int totalCandles = MathAbs(aheadCloudDelta);
   ArraySetAsSeries(r.spanA.values, true);
   ArraySetAsSeries(r.spanB.values, true);
   ArraySetAsSeries(r.ts, true);
   ArrayResize(r.ts, totalCandles);

   CopyBuffer(ichimokuHandle, 2, aheadCloudDelta, totalCandles, r.spanA.values);
   CopyBuffer(ichimokuHandle, 3, aheadCloudDelta, totalCandles, r.spanB.values);

   //Future TS needs to manually calculated, CopyTime doesn't work. TODO Exclude weekend
   datetime currentCandleTS = getCurrentCandleTS();   
   for (int i = totalCandles - 1; i >= 0; i--) {
      r.ts[i] = currentCandleTS + (PeriodSeconds(_Period) * (totalCandles - i ));
   }

   return r;
}


void findKumoFlip(int totalHistory, Kumo &k) {
   int arrayLength = ArraySize(k.spanA.values);

   k.flipTSIndex = arrayLength - 1;
   double  pA = k.spanA.values[0];
   double pB = k.spanB.values[0];
   for (int i = 0; i < arrayLength; i++) {
      if((pA > pB && k.spanA.values[i] < k.spanB.values[i])
            || (pA < pB && k.spanA.values[i] > k.spanB.values[i])) {

         //PrintFormat(i + ". " + k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
         //PrintFormat(i + ". " + k.ts[i] + " PA(%f), PB(%f)", pA, pB);
         int flipIndex = MathMin(i, arrayLength - 1);
         k.flipTSIndex =flipIndex;
         if(i >= 10) {
            break;
         }
      }
      pA = k.spanA.values[i];
      pB = k.spanB.values[i];
   }
}


Kumo* mergePreviousAndFutureKumo(Kumo &previous, Kumo *future) {
   Kumo* r = new Kumo();

   r.flipTSIndex = previous.flipTSIndex;

   int totalLength = ArraySize(previous.spanA.values) + ArraySize(future.spanA.values);
   ArrayResize(r.spanA.values, totalLength);
   ArrayResize(r.spanB.values, totalLength);
   ArrayResize(r.ts, totalLength);

   ArraySetAsSeries(r.spanA.values, true);
   ArraySetAsSeries(r.spanB.values, true);
   ArraySetAsSeries(r.ts, true);

   int futureArraySize = ArraySize(future.spanA.values);

   ArrayCopy(r.spanA.values, future.spanA.values, 0, 0, futureArraySize);
   ArrayCopy(r.spanB.values, future.spanB.values, 0, 0, futureArraySize);
   ArrayCopy(r.ts, future.ts, 0, 0, futureArraySize);

   ArrayCopy(r.spanA.values, previous.spanA.values, futureArraySize, 0, ArraySize(previous.spanA.values));
   ArrayCopy(r.spanB.values, previous.spanB.values, futureArraySize, 0, ArraySize(previous.spanB.values));
   ArrayCopy(r.ts, previous.ts, futureArraySize, 0, ArraySize(previous.ts));   

   return r;
}


void printKumo(Kumo * k) {
   for (int i = ArraySize(k.spanA.values) - 1; i >= 0; i--) {
     // PrintFormat(k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
   }
   PrintFormat("Total TS(%d), Flip TS(%s)", ArraySize(k.spanA.values));
   PrintFormat("Kumo: size(%d),Range [%s ,%s]",k.flipTSIndex, tsMin(k.ts[k.flipTSIndex]), tsMin(k.ts[0]));
   PrintFormat("SpanA[%s]", k.spanA.str());
   PrintFormat("SpanB[%s]",k.spanB.str());
   
}

datetime getCurrentCandleTS() {
   datetime tm[]; // array storing the returned bar time
   ArraySetAsSeries(tm, true);
   CopyTime(_Symbol, _Period, 0, 1, tm); //Getting the current candle time
   return tm[0];
}
