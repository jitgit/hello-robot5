#property strict
#resource "\\Indicators\\devd\\trailingsl\\nrtr.ex5"

#include <devd\include-base.mqh>
#include <devd\indicator-buffers.mqh>
#include <devd\trailingsl\TrailingStop.mqh>

class NRTRTrailingStop : public TrailingStop {
   private:
    double itsTrailingNRTRPeriod;
    double itsTrailingNRTRK;

   public:
    NRTRTrailingStop(double TrailingNRTRPeriod = 40, double TrailingNRTRK = 2) : TrailingStop("NRTR") {
        itsTrailingNRTRPeriod = TrailingNRTRPeriod;
        itsTrailingNRTRK = TrailingNRTRK;
    }

    double BuyStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double sup[1];                                                                                                                  // value of support level
        double dnTarget[1];                                                                                                             // value of support level
        int nrtr_handle = iCustom(symbol, timeFrame, "::Indicators\\devd\\trailingsl\\nrtr", itsTrailingNRTRPeriod, itsTrailingNRTRK);  // loading indicator

        CopyBuffer(nrtr_handle, 0, 0, 1, sup);
        CopyBuffer(nrtr_handle, 3, 0, 1, dnTarget);
        //PrintFormat("sup[0] :%f  (%f)", sup[0], dnTarget[0]);
        return sup[0] == 0.0 ? dnTarget[0] : sup[0];
    };

    double SellStoploss(string symbol, ENUM_TIMEFRAMES timeFrame) {
        double res[1];  // value of resistance level
        double upTarget[1];
        int nrtr_handle = iCustom(symbol, timeFrame, "::Indicators\\devd\\trailingsl\\nrtr", itsTrailingNRTRPeriod, itsTrailingNRTRK);  // loading indicator

        CopyBuffer(nrtr_handle, 1, 0, 1, res);
        CopyBuffer(nrtr_handle, 2, 0, 1, upTarget);
        //PrintFormat("res[0] :%f  (%f)", res[0], upTarget[0]);
        return res[0] == 0.0 ? upTarget[0] : res[0];
    };
};
