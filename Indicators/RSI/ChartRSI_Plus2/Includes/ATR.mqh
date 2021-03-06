//+------------------------------------------------------------------+
//|                                                          ATR.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "FirstTrueBar.mqh"
//+------------------------------------------------------------------+
//| Индикатор ATR                                                    |
//+------------------------------------------------------------------+
class CATR {
   private:
    //--- To determine the first true bar
    CFirstTrueBar m_first_true_bar;
    //--- Indicator period
    int m_period;
    //---Limiter in calculating indicator values
    int m_limit;
    //---
   public:
    //--- Indicator buffers
    double m_tr_buffer[];
    double m_atr_buffer[];
    //---
   public:
    CATR(const int period);
    ~CATR(void);
    //--- Calculates ATR indicator
    bool CalculateIndicatorATR(const int rates_total, const int prev_calculated, const datetime &time[], const double &close[], const double &high[], const double &low[]);
    //--- Zeroing indicator buffers
    void ZeroIndicatorBuffers(void);
    //---
   private:
    //--- Preliminary calculations
    bool PreliminaryCalc(const int rates_total, const int prev_calculated, const double &close[], const double &high[], const double &low[]);
    //--- Рассчитывает ATR
    void CalculateATR(const int i, const datetime &time[], const double &close[], const double &high[], const double &low[]);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CATR::CATR(const int period) : m_limit(0) {
    //---Checking the value of an external parameter
    if (period <= 0) {
        m_period = 1;
        printf("Incorrect input parameter InpAtrPeriod = %d. Indicator will use value %d for calculations.", period, m_period);
    } else
        m_period = period;
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CATR::~CATR(void) {
}
//+------------------------------------------------------------------+
//| Calculates ATR indicator                                      |
//+------------------------------------------------------------------+
bool CATR::CalculateIndicatorATR(const int rates_total, const int prev_calculated, const datetime &time[], const double &close[], const double &high[], const double &low[]) {
    //--- Предварительные расчёты
    if (!PreliminaryCalc(rates_total, prev_calculated, close, high, low))
        return (false);
    //--- Основной цикл
    for (int i = m_limit; i < rates_total && !::IsStopped(); i++)
        CalculateATR(i, time, close, high, low);
    //---
    return (true);
}
//+------------------------------------------------------------------+
//| Preliminary calculations                                          |
//+------------------------------------------------------------------+
bool CATR::PreliminaryCalc(const int rates_total, const int prev_calculated, const double &close[], const double &high[], const double &low[]) {
    //--- Если расчёт в первый раз или были изменения
    if (prev_calculated == 0) {
        //--- Определим номер истинного бара
        m_first_true_bar.DetermineFirstTrueBar();
        //--- Выйти, если истинный бар не определён
        if (m_first_true_bar.LimitBar() < 0)
            return (false);
        //---
        m_tr_buffer[0] = 0.0;
        m_atr_buffer[0] = 0.0;
        //--- Бар, от которого будет расчёт
        m_limit = (::Period() < PERIOD_D1) ? m_first_true_bar.LimitBar() + m_period : m_period;
        //--- Выйти, если выходим из диапазона (недостаточно баров)
        if (m_limit >= rates_total)
            return (false);
        //--- Рассчитаем значения истинного диапазона
        int start_pos = (m_first_true_bar.LimitBar() < 1) ? 1 : m_first_true_bar.LimitBar();
        for (int i = start_pos; i < m_limit && !::IsStopped(); i++)
            m_tr_buffer[i] = ::fmax(high[i], close[i - 1]) - ::fmin(low[i], close[i - 1]);
        //--- Первые значения ATR не рассчитываются
        double first_value = 0.0;
        for (int i = m_first_true_bar.LimitBar(); i < m_limit; i++) {
            m_atr_buffer[i] = 0.0;
            first_value += m_tr_buffer[i];
        }
        //--- Расчёт первого значения
        first_value /= m_period;
        m_atr_buffer[m_limit - 1] = first_value;
    } else
        m_limit = prev_calculated - 1;
    //---
    return (true);
}
//+------------------------------------------------------------------+
//| Рассчитывает индикатор ATR                                       |
//+------------------------------------------------------------------+
void CATR::CalculateATR(const int i, const datetime &time[], const double &close[], const double &high[], const double &low[]) {
    if (m_atr_buffer[i - 1] == 0)
        return;
    //--- Выйти, если выходим из диапазона
    m_tr_buffer[i] = ::fmax(high[i], close[i - 1]) - ::fmin(low[i], close[i - 1]);
    m_atr_buffer[i] = m_atr_buffer[i - 1] + (m_tr_buffer[i] - m_tr_buffer[i - m_period]) / (double)m_period;
}
//+------------------------------------------------------------------+
//| Обнуление индикаторных буферов                                   |
//+------------------------------------------------------------------+
void CATR::ZeroIndicatorBuffers(void) {
    ::ArrayInitialize(m_tr_buffer, 0);
    ::ArrayInitialize(m_atr_buffer, 0);
}
//+------------------------------------------------------------------+
