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
int OnInit() {
   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printAverageAngle(double &array[], datetime &tm[], string arrayName) {
   Print(arrayName, " - valueArray :", ArraySize(array), " TimeArray :", ArraySize(tm));
   int x = 0;
   double totalAngle = 0;
   int arraySize = ArraySize(array);
   for (int i = arraySize - 1; i >= 1; i--) {
      int x1 = x;//tm[i];
      int x2 = x + 1; //tm[i-1];
      double y1 = array[i];
      double y2 = array[i - 1];
      double angle = MathArctanh((y2 - y1) / (x2 - x1));
      // PrintFormat(tm[i] +  " P2(%f,%f) , P1(%f,%f) , Angle: %f ", x2, y2, x1, y1, angle);
      totalAngle += angle;
      x++;
   }
   PrintFormat("%s - Avg Angle: %f", arrayName, (totalAngle / (arraySize - 1)) * 1000); //TODO not sure *10000
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart() {
   double tenkansenBuffer[];
   double kijunsenBuffer[];
   double senkouSpanABuffer[];
   double senkouSpanBBuffer[];
   double Chinkou_Span_Buffer[];
   uint tickCount = GetTickCount();
   int ichimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);
   ArraySetAsSeries(tenkansenBuffer, true);
   ArraySetAsSeries(kijunsenBuffer, true);
   ArraySetAsSeries(senkouSpanABuffer, true);
   ArraySetAsSeries(senkouSpanBBuffer, true);
   MqlDateTime dt;
   double t = TimeCurrent(dt);
   PrintFormat("Time Current %d, %d:%d", tickCount, dt.hour, dt.min);
   int aheadCloudDelta = -16; //Constant number of bar, Cloud will be ahead of the latest price
   int barBeforeCurrent = 3;
   int amount = MathAbs(aheadCloudDelta) + barBeforeCurrent;
   CopyBuffer(ichimokuHandle, 0, 0, amount + barBeforeCurrent, tenkansenBuffer);
   CopyBuffer(ichimokuHandle, 1, 0, amount + barBeforeCurrent, kijunsenBuffer);
   CopyBuffer(ichimokuHandle, 2, aheadCloudDelta, amount, senkouSpanABuffer);
   CopyBuffer(ichimokuHandle, 3, aheadCloudDelta, amount, senkouSpanBBuffer);


   datetime tm[]; // array storing the returned bar time
   ArraySetAsSeries(tm, true);
   CopyTime(_Symbol, _Period, 0, 1, tm); //Getting the current candle time

//Calculating the time line based on requested bar
   datetime timeSeries[];
   ArrayResize(timeSeries, amount);
   for (int i = 0; i < amount;  i++) {
      timeSeries[i] = tm[0] + ((PeriodSeconds(_Period) * (i - barBeforeCurrent + 1))) ;
   }
   ArraySetAsSeries(timeSeries, true);


   /*for (int i = ArraySize(senkouSpanABuffer) - 1; i >= 0; i--) {
      PrintFormat(timeSeries[i] + " (%f , %f)", senkouSpanABuffer[i], senkouSpanBBuffer[i]);
   }*/
   printAverageAngle(senkouSpanABuffer, timeSeries, "Span A");
   printAverageAngle(senkouSpanBBuffer, timeSeries, "Span B");

//ArrayPrint(tenkansenBuffer);
//ArrayPrint(kijunsenBuffer);
//ArrayPrint(senkouSpanABuffer);
//ArrayPrint(senkouSpanBBuffer);

//Print("Tenkan Sen ::: : "+ norm(tenkansenBuffer[0]));
//Print("Kijua Sen ::: "+ kijunsenBuffer[0]);
//Print("Span A ::: "+ senkouSpanABuffer[0]);
//Print("Span B ::: "+ senkouSpanBBuffer[0]);
}
//+------------------------------------------------------------------+
