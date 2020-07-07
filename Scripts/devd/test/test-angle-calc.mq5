#property  strict

#include <devd/ichimoku/kumo.mqh>


void OnStart()
  {
   double result = angleInDegree(0, 143.583000,3600, 143.644750);//  , Angle= 98.278177
   Comment("=============== angleInDegree: %f",result);
  }
//+------------------------------------------------------------------+
