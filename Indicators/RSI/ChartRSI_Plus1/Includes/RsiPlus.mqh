//+------------------------------------------------------------------+
//|                                                          RSI.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "ATR.mqh"
#include "FirstTrueBar.mqh"
//--- Перечисление режимов пробоя каналов
enum ENUM_BREAK_INOUT {
    BREAK_IN = 0,          // Break in
    BREAK_IN_REVERSE = 1,  // Break in reverse
    BREAK_OUT = 2,         // Break out
    BREAK_OUT_REVERSE = 3  // Break out reverse
};
//+------------------------------------------------------------------+
//| Индикатор RSI с фильтром по волатильности                        |
//+------------------------------------------------------------------+
class CRsiPlus {
   private:
    //--- Для определения первого истинного бара
    CFirstTrueBar m_first_true_bar;
    //--- Указатель на ATR
    CATR *m_atr;

    //--- Период индикатора
    int m_period;
    //--- Уровень RSI
    double m_signal_level;
    //--- Режим для формирования сигналов
    ENUM_BREAK_INOUT m_break_mode;

    //--- Счётчики однонаправленных сигналов
    int m_buy_counter;
    int m_sell_counter;
    //--- Индикаторные уровни
    double m_up_level;
    double m_down_level;
    double m_up_levels[];
    double m_down_levels[];
    int m_up_levels_total;
    int m_down_levels_total;

    //--- Ограничитель в расчётах значений индикатора
    int m_limit;
    //--- Для определения последнего бара
    bool m_is_last_index;
    //---
   public:
    //--- Индикаторные буферы
    double m_rsi_buffer[];
    double m_pos_buffer[];
    double m_neg_buffer[];
    //---
    double m_buy_buffer[];
    double m_sell_buffer[];
    double m_buy_level_buffer[];
    double m_sell_level_buffer[];
    double m_buy_counter_buffer[];
    double m_sell_counter_buffer[];
    //---
   public:
    CRsiPlus(const int period, const double signal_level, const ENUM_BREAK_INOUT break_mode);
    ~CRsiPlus(void) {}
    //--- Указатель на ATR
    void AtrPointer(CATR &object) { m_atr = ::GetPointer(object); }
    CATR *AtrPointer(void) { return (::GetPointer(m_atr)); }
    //--- Рассчитывает индикатор RSI
    bool CalculateIndicatorRSI(const int rates_total, const int prev_calculated, const double &close[], const int &spread[]);
    //--- Инициализация всех индикаторных буферов
    void ZeroIndicatorBuffers(void);
    //---
   private:
    //--- Получает уровни индикатора
    int GetLevelsIndicator(void);
    //--- Предварительные расчёты
    bool PreliminaryCalc(const int rates_total, const int prev_calculated, const double &close[]);
    //--- Рассчитывает серию RSI
    void CalculateRSI(const int i, const double &price[]);
    //--- Рассчитывает сигналы индикатора
    void CalculateSignals(const int i, const int rates_total, const double &close[], const int &spread[]);

    //--- Проверка условий
    void CheckConditions(const int i, bool &condition1, bool &condition2);
    //--- Проверка счётчиков
    void CheckCounters(bool &condition1, bool &condition2);
    //--- Увеличивает buy- и sell-счётчики
    void IncreaseBuyCounter(const bool condition);
    void IncreaseSellCounter(const bool condition);

    //--- Контроль направления движения
    void DirectionControl(const int i, bool &condition1, bool &condition2);
    //--- Удаляют лишние buy- и sell-сигналы
    void DeleteBuySignal(const int i);
    void DeleteSellSignal(const int i);
    //--- Обнуление указанного элемента индикаторных буферов
    void ZeroIndexBuffers(const int index);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRsiPlus::CRsiPlus(const int period, const double signal_level, const ENUM_BREAK_INOUT break_mode) : m_limit(0),
                                                                                                     m_buy_counter(0),
                                                                                                     m_sell_counter(0),
                                                                                                     m_is_last_index(false)

{
    //--- Проверка значения внешнего параметра
    if (period < 2) {
        m_period = 2;
        ::Print("Incorrect value for input variable RSI period = ", period,
                ". Indicator will use value = ", m_period, " for calculations.");
    } else
        m_period = period;
    //---
    m_signal_level = signal_level;
    m_break_mode = break_mode;
    m_up_level = 100 - signal_level;
    m_down_level = signal_level;
    //--- Получим уровни индикатора
    GetLevelsIndicator();
}
//+------------------------------------------------------------------+
//| Получает уровни индикатора                                       |
//+------------------------------------------------------------------+
int CRsiPlus::GetLevelsIndicator(void) {
    m_up_levels_total = 0;
    m_down_levels_total = 0;
    ::ArrayFree(m_up_levels);
    ::ArrayFree(m_down_levels);
    //---
    int levels_counter = 0;
    double level = m_down_level;
    while (level > 0 && !::IsStopped()) {
        int size = ::ArraySize(m_down_levels);
        ::ArrayResize(m_down_levels, size + 1);
        m_down_levels[size] = level;
        level -= 5;
        levels_counter++;
    }
    level = m_up_level;
    while (level < 100 && !::IsStopped()) {
        int size = ::ArraySize(m_up_levels);
        ::ArrayResize(m_up_levels, size + 1);
        m_up_levels[size] = level;
        level += 5;
        levels_counter++;
    }
    //---
    m_up_levels_total = ::ArraySize(m_up_levels);
    m_down_levels_total = ::ArraySize(m_down_levels);
    return (levels_counter);
}
//+------------------------------------------------------------------+
//| Рассчитывает индикатор RSI                                       |
//+------------------------------------------------------------------+
bool CRsiPlus::CalculateIndicatorRSI(const int rates_total, const int prev_calculated, const double &close[], const int &spread[]) {
    //--- Предварительные расчёты
    if (!PreliminaryCalc(rates_total, prev_calculated, close))
        return (false);
    //--- Основной цикл
    for (int i = m_limit; i < rates_total && !::IsStopped(); i++) {
        //--- Расчёты нужно вести от первого значения ATR
        if (::CheckPointer(m_atr) != POINTER_INVALID) {
            if (m_atr.m_atr_buffer[i] == 0) {
                ZeroIndexBuffers(i);
                continue;
            }
        }
        //--- Рассчитать индикатор и его сигналы
        CalculateRSI(i, close);
        CalculateSignals(i, rates_total, close, spread);
    }
    //---
    return (true);
}
//+------------------------------------------------------------------+
//| Предварительные расчёты                                          |
//+------------------------------------------------------------------+
bool CRsiPlus::PreliminaryCalc(const int rates_total, const int prev_calculated, const double &close[]) {
    //--- Если расчёт в первый раз или были изменения
    if (prev_calculated == 0) {
        //--- Определим номер истинного бара
        m_first_true_bar.DetermineFirstTrueBar();
        //--- Выйти, если истинный бар не определён
        if (m_first_true_bar.LimitBar() < 0)
            return (false);
        //---
        double diff = 0.0;
        double sum_p = 0.0;
        double sum_n = 0.0;
        //--- Первое значение индикатора не рассчитывается
        ZeroIndexBuffers(0);
        //--- Очистим всё до первого истинного бара
        m_limit = (::Period() < PERIOD_D1) ? m_first_true_bar.LimitBar() + m_period : m_period;
        //--- Выйти, если выходим из диапазона (недостаточно баров)
        if (m_limit > rates_total)
            return (false);
        //---
        for (int i = 1; i < m_limit && i < rates_total; i++) {
            ZeroIndexBuffers(i);
            //---
            diff = close[i] - close[i - 1];
            sum_p += (diff > 0 ? diff : 0);
            sum_n += (diff < 0 ? -diff : 0);
        }
        //--- Расчёт первого значения
        m_pos_buffer[m_period] = sum_p / m_period;
        m_neg_buffer[m_period] = sum_n / m_period;
        //---
        if (m_neg_buffer[m_period] != 0.0)
            m_rsi_buffer[m_period] = 100.0 - (100.0 / (1.0 + m_pos_buffer[m_period] / m_neg_buffer[m_period]));
        else {
            m_rsi_buffer[m_period] = (m_pos_buffer[m_period] != 0.0) ? 100.0 : 50.0;
        }
    } else
        m_limit = prev_calculated - 1;
    //---
    return (true);
}
//+------------------------------------------------------------------+
//| Рассчитывает серию RSI                                           |
//+------------------------------------------------------------------+
void CRsiPlus::CalculateRSI(const int i, const double &price[]) {
    double diff = price[i] - price[i - 1];
    //---
    m_pos_buffer[i] = (m_pos_buffer[i - 1] * (m_period - 1) + (diff > 0.0 ? diff : 0.0)) / m_period;
    m_neg_buffer[i] = (m_neg_buffer[i - 1] * (m_period - 1) + (diff < 0.0 ? -diff : 0.0)) / m_period;
    //---
    if (m_neg_buffer[i] != 0.0)
        m_rsi_buffer[i] = 100.0 - 100.0 / (1.0 + m_pos_buffer[i] / m_neg_buffer[i]);
    else {
        m_rsi_buffer[i] = (m_pos_buffer[i] != 0.0) ? 100.0 : 50.0;
    }
}
//+------------------------------------------------------------------+
//| Рассчитывает сигналы индикатора                                  |
//+------------------------------------------------------------------+
void CRsiPlus::CalculateSignals(const int i, const int rates_total, const double &close[], const int &spread[]) {
    //--- Проверка последнего бара
    m_is_last_index = (i >= rates_total - 1);
    //--- Для проверки сигналов
    bool condition1 = false;
    bool condition2 = false;
    //--- Проверка условий
    CheckConditions(i, condition1, condition2);
    //--- Обнуление
    m_buy_buffer[i] = 0;
    m_sell_buffer[i] = 0;
    m_buy_level_buffer[i] = 0;
    m_sell_level_buffer[i] = 0;
    //--- Получим спред
    double current_spread = 0.0;
    if (!m_is_last_index)
        current_spread = spread[i];
    else
        current_spread = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK) - ::SymbolInfoDouble(_Symbol, SYMBOL_BID);
    //--- Если реверс отключен
    if (m_break_mode == BREAK_IN || m_break_mode == BREAK_OUT) {
        m_buy_buffer[i] = (condition1) ? close[i] + current_spread * _Point : 0;
        m_sell_buffer[i] = (condition2) ? close[i] : 0;
        m_buy_level_buffer[i] = (condition1) ? m_buy_buffer[i] : m_buy_level_buffer[i - 1];
        m_sell_level_buffer[i] = (condition2) ? m_sell_buffer[i] : m_sell_level_buffer[i - 1];
    } else {
        m_buy_buffer[i] = (condition2) ? close[i] + current_spread * _Point : 0;
        m_sell_buffer[i] = (condition1) ? close[i] : 0;
        m_buy_level_buffer[i] = (condition2) ? m_buy_buffer[i] : m_buy_level_buffer[i - 1];
        m_sell_level_buffer[i] = (condition1) ? m_sell_buffer[i] : m_sell_level_buffer[i - 1];
    }
    //--- Проверка счётчиков для всех кроме последнего
    if (!m_is_last_index)
        CheckCounters(condition1, condition2);
    //--- Контроль направления движения
    DirectionControl(i, condition1, condition2);
    //--- Если это не последний бар
    if (!m_is_last_index) {
        m_buy_counter_buffer[i] = m_buy_counter;
        m_sell_counter_buffer[i] = m_sell_counter;
        m_buy_level_buffer[i] = m_buy_level_buffer[i];
        m_sell_level_buffer[i] = m_sell_level_buffer[i];
    }
    //--- Последний бар
    else {
        m_buy_counter_buffer[i] = m_buy_counter_buffer[i - 1];
        m_sell_counter_buffer[i] = m_sell_counter_buffer[i - 1];
        m_buy_level_buffer[i] = m_buy_level_buffer[i - 1];
        m_sell_level_buffer[i] = m_sell_level_buffer[i - 1];
    }
}
//+------------------------------------------------------------------+
//| Проверка условий                                                 |
//+------------------------------------------------------------------+
void CRsiPlus::CheckConditions(const int i, bool &condition1, bool &condition2) {
    if (m_break_mode == BREAK_IN || m_break_mode == BREAK_IN_REVERSE) {
        if (m_rsi_buffer[i] < 50) {
            for (int j = 0; j < m_down_levels_total; j++) {
                condition1 = m_rsi_buffer[i - 1] < m_down_levels[j] && m_rsi_buffer[i] > m_down_levels[j];
                if (condition1)
                    break;
            }
        }
        //---
        if (m_rsi_buffer[i] > 50) {
            for (int j = 0; j < m_up_levels_total; j++) {
                condition2 = m_rsi_buffer[i - 1] > m_up_levels[j] && m_rsi_buffer[i] < m_up_levels[j];
                if (condition2)
                    break;
            }
        }
    } else {
        for (int j = 0; j < m_up_levels_total; j++) {
            condition1 = m_rsi_buffer[i - 1] < m_up_levels[j] && m_rsi_buffer[i] > m_up_levels[j];
            if (condition1)
                break;
        }
        //---
        for (int j = 0; j < m_down_levels_total; j++) {
            condition2 = m_rsi_buffer[i - 1] > m_down_levels[j] && m_rsi_buffer[i] < m_down_levels[j];
            if (condition2)
                break;
        }
    }
}
//+------------------------------------------------------------------+
//| Проверка счётчиков                                               |
//+------------------------------------------------------------------+
void CRsiPlus::CheckCounters(bool &condition1, bool &condition2) {
    //--- Если реверс отключен
    if (m_break_mode == BREAK_IN || m_break_mode == BREAK_OUT) {
        IncreaseBuyCounter(condition1);
        IncreaseSellCounter(condition2);
    } else {
        IncreaseBuyCounter(condition2);
        IncreaseSellCounter(condition1);
    }
}
//+------------------------------------------------------------------+
//| Увеличивает buy-счётчик                                          |
//+------------------------------------------------------------------+
void CRsiPlus::IncreaseBuyCounter(const bool condition) {
    if (!condition)
        return;
    //---
    m_buy_counter++;
    m_sell_counter = 0;
}
//+------------------------------------------------------------------+
//| Увеличивает sell-счётчик                                         |
//+------------------------------------------------------------------+
void CRsiPlus::IncreaseSellCounter(const bool condition) {
    if (!condition)
        return;
    //---
    m_sell_counter++;
    m_buy_counter = 0;
}
//+------------------------------------------------------------------+
//| Контроль направления движения                                    |
//+------------------------------------------------------------------+
void CRsiPlus::DirectionControl(const int i, bool &condition1, bool &condition2) {
    double atr_coeff = 0.0;
    double impulse_size = 0.0;
    bool atr_condition = false;
    //---
    bool buy_condition = false;
    bool sell_condition = false;
    //--- Если реверс отключен
    if (m_break_mode == BREAK_IN || m_break_mode == BREAK_OUT) {
        buy_condition = condition1 && m_buy_counter > 1;
        impulse_size = ::fabs(m_buy_buffer[i] - m_buy_level_buffer[i - 1]);
        atr_condition = impulse_size < m_atr.m_atr_buffer[i];
        //---
        if ((m_buy_counter > 1 && atr_condition) ||
            (m_break_mode == BREAK_IN && buy_condition && m_buy_buffer[i] > m_buy_level_buffer[i - 1]) ||
            (m_break_mode == BREAK_OUT && buy_condition && m_buy_buffer[i] < m_buy_level_buffer[i - 1])) {
            DeleteBuySignal(i);
        }
        //---
        sell_condition = condition2 && m_sell_counter > 1;
        impulse_size = ::fabs(m_sell_buffer[i] - m_sell_level_buffer[i - 1]);
        atr_condition = impulse_size < m_atr.m_atr_buffer[i];
        //---
        if ((m_sell_counter > 1 && atr_condition) ||
            (m_break_mode == BREAK_IN && sell_condition && m_sell_buffer[i] < m_sell_level_buffer[i - 1]) ||
            (m_break_mode == BREAK_OUT && sell_condition && m_sell_buffer[i] > m_sell_level_buffer[i - 1])) {
            DeleteSellSignal(i);
        }
    }
    //--- Реверс включен
    else {
        buy_condition = condition2 && m_buy_counter > 1;
        impulse_size = ::fabs(m_buy_buffer[i] - m_buy_level_buffer[i - 1]);
        atr_condition = impulse_size < m_atr.m_atr_buffer[i];
        //---
        if ((m_buy_counter > 1 && atr_condition) ||
            (m_break_mode == BREAK_IN_REVERSE && buy_condition && m_buy_buffer[i] < m_buy_level_buffer[i - 1]) ||
            (m_break_mode == BREAK_OUT_REVERSE && buy_condition && m_buy_buffer[i] > m_buy_level_buffer[i - 1])) {
            DeleteBuySignal(i);
        }
        //---
        sell_condition = condition1 && m_sell_counter > 1;
        impulse_size = ::fabs(m_sell_buffer[i] - m_sell_level_buffer[i - 1]);
        atr_condition = impulse_size < m_atr.m_atr_buffer[i];
        //---
        if ((m_sell_counter > 1 && atr_condition) ||
            (m_break_mode == BREAK_IN_REVERSE && sell_condition && m_sell_buffer[i] > m_sell_level_buffer[i - 1]) ||
            (m_break_mode == BREAK_OUT_REVERSE && sell_condition && m_sell_buffer[i] < m_sell_level_buffer[i - 1])) {
            DeleteSellSignal(i);
        }
    }
}
//+------------------------------------------------------------------+
//| Удаляет лишний buy-сигнал                                        |
//+------------------------------------------------------------------+
void CRsiPlus::DeleteBuySignal(const int i) {
    if (!m_is_last_index) {
        if (m_buy_counter - 1 >= m_buy_counter_buffer[i])
            m_buy_counter--;
    } else {
        if (m_buy_counter - 1 >= m_buy_counter_buffer[i - 1])
            m_buy_counter--;
    }
    //---
    m_buy_buffer[i] = 0;
    m_buy_level_buffer[i] = m_buy_level_buffer[i - 1];
}
//+------------------------------------------------------------------+
//| Удаляет лишний sell-сигнал                                       |
//+------------------------------------------------------------------+
void CRsiPlus::DeleteSellSignal(const int i) {
    if (!m_is_last_index) {
        if (m_sell_counter - 1 >= m_sell_counter_buffer[i])
            m_sell_counter--;
    } else {
        if (m_sell_counter - 1 >= m_sell_counter_buffer[i - 1])
            m_sell_counter--;
    }
    //---
    m_sell_buffer[i] = 0;
    m_sell_level_buffer[i] = m_sell_level_buffer[i - 1];
}
//+------------------------------------------------------------------+
//| Обнуление индикаторных буферов                                   |
//+------------------------------------------------------------------+
void CRsiPlus::ZeroIndicatorBuffers(void) {
    m_limit = 0;
    m_buy_counter = 0;
    m_sell_counter = 0;
    //---
    ::ArrayInitialize(m_rsi_buffer, 0);
    ::ArrayInitialize(m_buy_buffer, 0);
    ::ArrayInitialize(m_sell_buffer, 0);
    ::ArrayInitialize(m_buy_level_buffer, 0);
    ::ArrayInitialize(m_sell_level_buffer, 0);
    ::ArrayInitialize(m_buy_counter_buffer, 0);
    ::ArrayInitialize(m_sell_counter_buffer, 0);
}
//+------------------------------------------------------------------+
//| Обнуление указанного элемента индикаторных буферов               |
//+------------------------------------------------------------------+
void CRsiPlus::ZeroIndexBuffers(const int index) {
    m_rsi_buffer[index] = 0.0;
    m_pos_buffer[index] = 0.0;
    m_neg_buffer[index] = 0.0;
    m_buy_buffer[index] = 0.0;
    m_sell_buffer[index] = 0.0;
    m_buy_level_buffer[index] = 0.0;
    m_sell_level_buffer[index] = 0.0;
    m_buy_counter_buffer[index] = 0.0;
    m_sell_counter_buffer[index] = 0.0;
}
//+------------------------------------------------------------------+
