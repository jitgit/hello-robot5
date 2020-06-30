#property strict
#include <devd\include-base.mqh>
#include <devd\indicator-buffers.mqh>
#include <devd\trailingsl\TrailingStop.mqh>

class SARTrailingStop : public TrailingStop {
   private:
    int m_handle;  // indicator handle
    double itsSarStep;
    double itsSarMax;

   public:
    SARTrailingStop(double sarstep = 0.02, double sarmaximum = 0.2) : TrailingStop("SAR") {
        itsSarStep = sarstep;
        itsSarMax = sarmaximum;
    }

    double BuyStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double buffer[];
        int sarHandle = iSAR(symbol, timeFrame, itsSarStep, itsSarMax);
        GetSARParaboliBuffers(sarHandle, 0, 1, buffer);

        PrintFormat("buffer[0] :%f", buffer[0]);
        return buffer[0];
    };

    double SellStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        return BuyStoploss(symbol, timeFrame);
    };
};
