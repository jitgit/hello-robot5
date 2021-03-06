//+------------------------------------------------------------------------------+
//|                                                      GetIndicatorBuffers.mqh |
//|                                                             Copyright DC2008 |
//|                                          https://www.mql5.com/en/articles/31 |
//+------------------------------------------------------------------------------+
#property copyright "DC2008"
#property link "http://www.mql5.com"

bool CopyBufferAsSeries(
    int handle,             // handle
    int bufferNumber,       // buffer number
    int start,              // start from
    int number,             // number of elements to copy
    bool asSeries,          // is as series
    double &targetBuffer[]  // target array for data
) {
    bool b1 = CopyBuffer(handle, bufferNumber, start, number, targetBuffer);
    bool b2 = ArraySetAsSeries(targetBuffer, asSeries);
    return b1 && b2;
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator ADX to the arrays                         |
//+------------------------------------------------------------------------------+
bool GetADXBuffers(int ADX_handle,
                   int start,
                   int number,
                   double &Main[],
                   double &PlusDI[],
                   double &MinusDI[],
                   bool asSeries = true  // as series
) {
    //--- Filling the array Main with the current values of MAIN_LINE
    if (!CopyBufferAsSeries(ADX_handle, 0, start, number, asSeries, Main)) return (false);
    //--- Filling the array PlusDI with the current values of PLUSDI_LINE
    if (!CopyBufferAsSeries(ADX_handle, 1, start, number, asSeries, PlusDI)) return (false);
    //--- Filling the array MinusDI with the current values of MINUSDI_LINE
    if (!CopyBufferAsSeries(ADX_handle, 2, start, number, asSeries, MinusDI)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator ADXWilder to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetADXWilderBuffers(int ADXWilder_handle,
                         int start,
                         int number,
                         double &Main[],
                         double &PlusDI[],
                         double &MinusDI[],
                         bool asSeries = true  // as series
) {
    //--- Filling the array Main with the current values of MAIN_LINE
    if (!CopyBufferAsSeries(ADXWilder_handle, 0, start, number, asSeries, Main)) return (false);
    //--- Filling the array PlusDI with the current values of PLUSDI_LINE
    if (!CopyBufferAsSeries(ADXWilder_handle, 1, start, number, asSeries, PlusDI)) return (false);
    //--- Filling the array MinusDI with the current values of MINUSDI_LINE
    if (!CopyBufferAsSeries(ADXWilder_handle, 2, start, number, asSeries, MinusDI)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Alligator to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetAlligatorBuffers(int Alligator_handle,
                         int start,
                         int number,
                         double &Jaws[],
                         double &Teeth[],
                         double &Lips[],
                         bool asSeries = true  // as series
) {
    //--- Filling the array Jaws with the current values of GATORJAW_LINE
    if (!CopyBufferAsSeries(Alligator_handle, 0, start, number, asSeries, Jaws)) return (false);
    //--- Filling the array Teeth with the current values of GATORTEETH_LINE
    if (!CopyBufferAsSeries(Alligator_handle, 1, start, number, asSeries, Teeth)) return (false);
    //--- Filling the array Lips with the current values of GATORLIPS_LINE
    if (!CopyBufferAsSeries(Alligator_handle, 2, start, number, asSeries, Lips)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Bands to the arrays                       |
//+------------------------------------------------------------------------------+
bool GetBandsBuffers(int Bands_handle,
                     int start,
                     int number,
                     double &Base[],
                     double &Upper[],
                     double &Lower[],
                     bool asSeries = true  // as series
) {
    //--- Filling the array Base with the current values of BASE_LINE
    if (!CopyBufferAsSeries(Bands_handle, 0, start, number, asSeries, Base)) return (false);
    //--- Filling the array Upper with the current values of UPPER_BAND
    if (!CopyBufferAsSeries(Bands_handle, 1, start, number, asSeries, Upper)) return (false);
    //--- Filling the array Lower with the current values of LOWER_BAND
    if (!CopyBufferAsSeries(Bands_handle, 2, start, number, asSeries, Lower)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Envelopes to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetEnvelopesBuffers(int Envelopes_handle,
                         int start,
                         int number,
                         double &Upper[],
                         double &Lower[],
                         bool asSeries = true  // as series
) {
    //--- Filling the array Upper with the current values of UPPER_LINE
    if (!CopyBufferAsSeries(Envelopes_handle, 0, start, number, asSeries, Upper)) return (false);
    //--- Filling the array Lower with the current values of LOWER_LINE
    if (!CopyBufferAsSeries(Envelopes_handle, 1, start, number, asSeries, Lower)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Fractals to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetFractalsBuffers(int Fractals_handle,
                        int start,
                        int number,
                        double &Upper[],
                        double &Lower[],
                        bool asSeries = true  // as series
) {
    //--- Filling the array Upper with the current values of UPPER_LINE
    if (!CopyBufferAsSeries(Fractals_handle, 0, start, number, asSeries, Upper)) return (false);
    //--- Filling the array Lower with the current values of LOWER_LINE
    if (!CopyBufferAsSeries(Fractals_handle, 1, start, number, asSeries, Lower)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Gator to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetGatorBuffers(int Gator_handle,
                     int start,
                     int number,
                     double &Upper[],
                     double &Lower[],
                     bool asSeries = true  // as series
) {
    //--- Filling the array Upper with the current values of UPPER_LINE
    if (!CopyBufferAsSeries(Gator_handle, 0, start, number, asSeries, Upper)) return (false);
    //--- Filling the array Lower with the current values of LOWER_LINE
    if (!CopyBufferAsSeries(Gator_handle, 1, start, number, asSeries, Lower)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Ichimoku to the arrays                    |
//+------------------------------------------------------------------------------+
bool GetIchimokuBuffers(int Ichimoku_handle,
                        int start,
                        int number,
                        double &Tenkansen[],
                        double &Kijunsen[],
                        double &SenkouspanA[],
                        double &SenkouspanB[],
                        double &Chinkouspan[],
                        bool asSeries = true) {
    //--- Filling the array Tenkansen with the current values of TENKANSEN_LINE
    if (!CopyBufferAsSeries(Ichimoku_handle, 0, start, number, asSeries, Tenkansen)) return (false);
    //--- Filling the array Kijunsen with the current values of KIJUNSEN_LINE
    if (!CopyBufferAsSeries(Ichimoku_handle, 1, start, number, asSeries, Kijunsen)) return (false);
    //--- Filling the array SenkouspanA with the current values of SENKOUSPANA_LINE
    if (!CopyBufferAsSeries(Ichimoku_handle, 2, start, number, asSeries, SenkouspanA)) return (false);
    //--- Filling the array SenkouspanB with the current values of SENKOUSPANB_LINE
    if (!CopyBufferAsSeries(Ichimoku_handle, 3, start, number, asSeries, SenkouspanB)) return (false);
    //--- Filling the array Chinkouspan with the current values of CHINKOUSPAN_LINE
    if (!CopyBufferAsSeries(Ichimoku_handle, 4, start, number, asSeries, Chinkouspan)) return (false);
    //---
    return (true);
}
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator MACD to the arrays                        |
//+------------------------------------------------------------------------------+
bool GetMACDBuffers(int MACD_handle,
                    int start,
                    int number,
                    double &Main[],
                    double &Signal[],
                    bool asSeries = true) {
    //--- Filling the array Main with the current values of MAIN_LINE
    if (!CopyBufferAsSeries(MACD_handle, 0, start, number, asSeries, Main)) return (false);
    //--- Filling the array Signal with the current values of SIGNAL_LINE
    if (!CopyBufferAsSeries(MACD_handle, 1, start, number, asSeries, Signal)) return (false);
    //---
    return (true);
}

bool GetRVIBuffers(int RVI_handle,
                   int start,
                   int number,
                   double &Main[],
                   double &Signal[],
                   bool asSeries = true) {
    bool b1 = CopyBufferAsSeries(RVI_handle, MAIN_LINE, start, number, asSeries, Main);
    bool b2 = CopyBufferAsSeries(RVI_handle, SIGNAL_LINE, start, number, asSeries, Signal);
    return b1 && b2;
}

bool GetStochasticBuffers(int Stochastic_handle,
                          int start,
                          int number,
                          double &Main[],
                          double &Signal[],
                          bool asSeries = true) {
    bool b1 = CopyBufferAsSeries(Stochastic_handle, SIGNAL_LINE, start, number, asSeries, Signal);  //SIGNAL_LINE
    bool b2 = CopyBufferAsSeries(Stochastic_handle, MAIN_LINE, start, number, asSeries, Main);      //MAIN_LINE;
    return b1 && b2;
}

bool GetSARParaboliBuffers(int sar_handle,
                           int start,
                           int number,
                           double &buffer[],
                           bool asSeries = true) {
    return CopyBufferAsSeries(sar_handle, 0, start, number, asSeries, buffer);
}

bool GetHeikinAshiBuffers(int ha_Handle,
                          int start,
                          int number,
                          double &haOpen[],
                          double &haHigh[],
                          double &haLow[],
                          double &haClose[],
                          double &haColor[],
                          bool asSeries = true) {
    bool b1 = CopyBufferAsSeries(ha_Handle, 0, start, number, asSeries, haOpen);
    bool b2 = CopyBufferAsSeries(ha_Handle, 1, start, number, asSeries, haHigh);
    bool b3 = CopyBufferAsSeries(ha_Handle, 2, start, number, asSeries, haLow);
    bool b4 = CopyBufferAsSeries(ha_Handle, 3, start, number, asSeries, haClose);
    bool b5 = CopyBufferAsSeries(ha_Handle, 4, start, number, asSeries, haColor);
    return b1 && b2 && b3 && b4 && b5;
    ;
}

//+------------------------------------------------------------------------------+