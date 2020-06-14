//+------------------------------------------------------------------+
//|                                                devd-ichimoku.mq5 |
//|                                                             DevD |
//|                                             https://www.devd.com |
//+------------------------------------------------------------------+
#property copyright "DevD"
#property link "https://www.devd.com"
#property version "1.00"
#include <devd/common.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printAverageAngle(double &array[], datetime &tm[], string arrayName) {
   Kumo* result = new Kumo();
// Print(arrayName, " - valueArray :", ArraySize(array), " TimeArray :", ArraySize(tm));
   int x = 0;
   double totalAngle = 0;
   int arraySize = ArraySize(array);
   datetime xOriginShift = tm[arraySize - 1];
   double yOriginShift = array[arraySize - 1];
   for (int i = arraySize - 1; i >= 1; i--) {
      int x1 = tm[i] - xOriginShift;
      int x2 = tm[i - 1] - xOriginShift;
      double y1 = (MathPow(10, _Digits) * array[i]) - yOriginShift;
      double y2 = (MathPow(10, _Digits) * array[i - 1]) - yOriginShift;
      double angle = MathTanh((y2 - y1) / (x2 - x1));
      //PrintFormat(tm[i] + " P2(%f,%f) , P1(%f,%f) , Angle: %f ", x2, y2, x1, y1, angle);
      totalAngle += angle;
      x++;
   }
   PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}


class Kumo {
public:
   
   double            spanA[];
   double            spanB[];
   datetime          ts[];
   
   int               flatCount;   
   datetime          flipTS; //TS when most recently cloud flips - 1, This can be array as well.
   

};

datetime getCurrentCandleTS() {
   datetime tm[]; // array storing the returned bar time
   ArraySetAsSeries(tm, true);
   CopyTime(_Symbol, _Period, 0, 1, tm); //Getting the current candle time
   return tm[0];
}


void OnStart() {


   //We take an appx. number of candle in which a kumo flip can be found
   int barBeforeCurrent = 200;
   Kumo* kumpBeforeCurrentTS = new Kumo();
   addPreviousKumo(barBeforeCurrent, kumpBeforeCurrentTS);


   Kumo* futureKumo = futureKumoInfo();
   
   Kumo* totalKumo = mergePreviousAndFutureKumo(kumpBeforeCurrentTS, futureKumo);
   
   findKumoFlip(barBeforeCurrent, totalKumo);
   PrintFormat("================================================================");
   
   printKumo(totalKumo);
   

   /*double tenkansenBuffer[];
   double kijunsenBuffer[];

   int ichimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);
   ArraySetAsSeries(tenkansenBuffer, true);
   ArraySetAsSeries(kijunsenBuffer, true);

   int aheadCloudDelta = -16; //Constant number of bar, Cloud will be ahead of the latest price
   int barBeforeCurrent = 3;
   int totalCandles = MathAbs(aheadCloudDelta) + barBeforeCurrent;
   CopyBuffer(ichimokuHandle, 0, 0, totalCandles + barBeforeCurrent, tenkansenBuffer);
   CopyBuffer(ichimokuHandle, 1, 0, totalCandles + barBeforeCurrent, kijunsenBuffer);

   */


   /*


   printKumo(k);

   printAverageAngle(k.spanA, k.ts, "Span A");
   printAverageAngle(k.spanB, k.ts, "Span B");
   */




//ArrayPrint(tenkansenBuffer);
//ArrayPrint(kijunsenBuffer);
//ArrayPrint(spanA);
//ArrayPrint(spanB);

//Print("Tenkan Sen ::: : "+ norm(tenkansenBuffer[0]));
//Print("Kijua Sen ::: "+ kijunsenBuffer[0]);
//Print("Span A ::: "+ spanA[0]);
//Print("Span B ::: "+ spanB[0]);
}


void addPreviousKumo(int barBeforeCurrent, Kumo &k) {

   datetime currentCandleTS = getCurrentCandleTS();
   int ichimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);


//Copy Previous TS/SpanAB values
   ArraySetAsSeries(k.spanA, true);
   ArraySetAsSeries(k.spanB, true);
   ArraySetAsSeries(k.ts, true);
   CopyBuffer(ichimokuHandle, 2, 0, barBeforeCurrent, k.spanA);
   CopyBuffer(ichimokuHandle, 3, 0, barBeforeCurrent, k.spanB);
   CopyTime(_Symbol, _Period, currentCandleTS, barBeforeCurrent, k.ts);

   PrintFormat("currentCandleTS: " + currentCandleTS);
}



Kumo* futureKumoInfo() {
   Kumo* r = new Kumo();

   int ichimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);
   int aheadCloudDelta = -26; //Constant number of bar, Cloud will be ahead of the latest price
   int totalCandles = MathAbs(aheadCloudDelta);
   ArraySetAsSeries(r.spanA, true);
   ArraySetAsSeries(r.spanB, true);
   ArraySetAsSeries(r.ts, true);
   ArrayResize(r.ts, totalCandles);

   CopyBuffer(ichimokuHandle, 2, aheadCloudDelta, totalCandles, r.spanA);
   CopyBuffer(ichimokuHandle, 3, aheadCloudDelta, totalCandles, r.spanB);


   datetime currentCandleTS = getCurrentCandleTS();

//Future TS needs to manually calculated, CopyTime doesn't work. TODO Exclude weekend
   for (int i = totalCandles - 1; i >= 0; i--) {
      r.ts[i] = currentCandleTS + (PeriodSeconds(_Period) * (totalCandles - i ));
   }

   return r;
}


void findKumoFlip(int barBeforeCurrent, Kumo &k) {
   int arrayLength = ArraySize(k.spanA);

   k.flipTS = k.ts[arrayLength - 1];
   double  pA = k.spanA[0];
   double pB = k.spanB[0];
   for (int i = 0; i < arrayLength; i++) {
      if((pA > pB && k.spanA[i] < k.spanB[i])
            || (pA < pB && k.spanA[i] > k.spanB[i])) {

         //PrintFormat(i + ". " + k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
         //PrintFormat(i + ". " + k.ts[i] + " PA(%f), PB(%f)", pA, pB);

         k.flipTS  =  k.ts[MathMin(i, arrayLength - 1)];
         if(i >= 10) {
            break;
         }
      }
      pA = k.spanA[i];
      pB = k.spanB[i];
   }
}


Kumo* mergePreviousAndFutureKumo(Kumo &previous, Kumo *future) {
   Kumo* r = new Kumo();

   r.flipTS = previous.flipTS;

   int totalLength = ArraySize(previous.spanA) + ArraySize(future.spanA);
   ArrayResize(r.spanA, totalLength);
   ArrayResize(r.spanB, totalLength);
   ArrayResize(r.ts, totalLength);

   ArraySetAsSeries(r.spanA, true);
   ArraySetAsSeries(r.spanB, true);
   ArraySetAsSeries(r.ts, true);

   int futureArraySize = ArraySize(future.spanA);

   ArrayCopy(r.spanA, future.spanA, 0, 0, futureArraySize);
   ArrayCopy(r.spanB, future.spanB, 0, 0, futureArraySize);
   ArrayCopy(r.ts, future.ts, 0, 0, futureArraySize);

   ArrayCopy(r.spanA, previous.spanA, futureArraySize, 0, ArraySize(previous.spanA));
   ArrayCopy(r.spanB, previous.spanB, futureArraySize, 0, ArraySize(previous.spanB));
   ArrayCopy(r.ts, previous.ts, futureArraySize, 0, ArraySize(previous.ts));

   printKumo(r);

   return r;

}


void printKumo(Kumo * k) {
   for (int i = ArraySize(k.spanA) - 1; i >= 0; i--) {
      PrintFormat(k.ts[i] + " (%f , %f)", k.spanA[i], k.spanB[i]);
   }
   PrintFormat("Total TS(%d), Flip TS " + k.flipTS, ArraySize(k.spanA));
}
