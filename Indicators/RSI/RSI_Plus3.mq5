//+------------------------------------------------------------------+
//|                                                   RSI plus 3.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link "http://www.mql5.com"
#property version "1.0"
//--- Свойства
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 7
#property indicator_plots 5
#property indicator_color1 clrSteelBlue
#property indicator_color2 clrMediumSeaGreen
#property indicator_color3 clrRed
#property indicator_color4 clrMediumSeaGreen
#property indicator_color5 clrRed
//--- Стрелки для сигналов: 159 - точки; 233/234 - стрелки;
#define ARROW_BUY 159
#define ARROW_SELL 159
//--- Перечисление режимов пробоя границ канала
enum ENUM_BREAK_INOUT {
    BREAK_IN = 0,          // Break in
    BREAK_IN_REVERSE = 1,  // Break in reverse
    BREAK_OUT = 2,         // Break out
    BREAK_OUT_REVERSE = 3  // Break out reverse
};
//--- Входные параметры
input int PeriodRSI = 8;                       // RSI Period
input double SignalLevel = 30;                 // Signal Level
input ENUM_BREAK_INOUT BreakMode = BREAK_OUT;  // Break Mode
//--- Индикаторные буферы
double rsi_buffer[];
double buy_buffer[];
double sell_buffer[];
double pos_buffer[];
double neg_buffer[];
double buy_counter_buffer[];
double sell_counter_buffer[];
//--- Отступ для стрелок
int arrow_shift = 0;
//--- Период индикатора
int period_rsi = 0;
//--- Значения горизонтальных уровней индикатора и их количество
double up_level = 0;
double down_level = 0;
int up_levels_total = 0;
int down_levels_total = 0;
//--- Массивы горизонтальных уровней
double up_levels[];
double down_levels[];
//--- Начальная позиция для расчётов индикатора
int start_pos = 0;
//--- Счётчики непрерывных последовательностей сигналов
int buy_counter = 0;
int sell_counter = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit(void) {
    //--- Проверка значения внешнего параметра
    if (PeriodRSI < 1) {
        period_rsi = 2;
        Print("Incorrect value for input variable PeriodRSI =", PeriodRSI,
              "Indicator will use value =", period_rsi, "for calculations.");
    } else
        period_rsi = PeriodRSI;
    //--- Установим свойства индикатора
    SetPropertiesIndicator();
}
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
    //--- Выйти, если данных недостаточно
    if (rates_total <= period_rsi)
        return (0);
    //--- Предварительные расчеты
    PreliminaryCalculations(prev_calculated, close);
    //--- Основной цикл для расчётов
    for (int i = start_pos; i < rates_total && !::IsStopped(); i++) {
        //--- Рассчитывает индикатор RSI
        CalculateRSI(i, close);
        //--- Рассчитывает сигналы
        CalculateSignals(i, rates_total);
    }
    //--- Вернуть последнее рассчитанное количество элементов
    return (rates_total);
}
//+------------------------------------------------------------------+
//| Возвращает уровни индикатора                                     |
//+------------------------------------------------------------------+
int GetLevelsIndicator(void) {
    int levels_counter = 0;
    double level = down_level;
    //--- Нижние уровни до нижнего предела
    while (level > 0 && !::IsStopped()) {
        int size = ::ArraySize(down_levels);
        ::ArrayResize(down_levels, size + 1);
        down_levels[size] = level;
        level -= 5;
        levels_counter++;
    }
    level = up_level;
    //--- Верхние уровни до верхнего предела
    while (level < 100 && !::IsStopped()) {
        int size = ::ArraySize(up_levels);
        ::ArrayResize(up_levels, size + 1);
        up_levels[size] = level;
        level += 5;
        levels_counter++;
    }
    //---
    return (levels_counter);
}
//+------------------------------------------------------------------+
//| Устанавливает свойства индикатора                                |
//+------------------------------------------------------------------+
void SetPropertiesIndicator(void) {
    //--- Короткое имя
    ::IndicatorSetString(INDICATOR_SHORTNAME, "RSI_PLUS3");
    //--- Знаков после запятой
    ::IndicatorSetInteger(INDICATOR_DIGITS, 2);
    //--- Буферы индикатора
    ::SetIndexBuffer(0, rsi_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(1, buy_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(2, sell_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(3, buy_counter_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(4, sell_counter_buffer, INDICATOR_DATA);
    ::SetIndexBuffer(5, pos_buffer, INDICATOR_CALCULATIONS);
    ::SetIndexBuffer(6, neg_buffer, INDICATOR_CALCULATIONS);
    //--- Инициализация массивов
    ZeroIndicatorBuffers();
    //--- Установим текстовые метки
    string plot_label[] = {"RSI", "buy", "sell", "buy counter", "sell counter"};
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetString(i, PLOT_LABEL, plot_label[i]);
    //--- Установим толщину для индикаторных массивов
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_LINE_WIDTH, 1);
    //--- Установим тип для индикаторных массивов
    ENUM_DRAW_TYPE draw_type[] = {DRAW_LINE, DRAW_ARROW, DRAW_ARROW, DRAW_LINE, DRAW_LINE};
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_DRAW_TYPE, draw_type[i]);
    //--- Номера меток
    ::PlotIndexSetInteger(1, PLOT_ARROW, ARROW_BUY);
    ::PlotIndexSetInteger(2, PLOT_ARROW, ARROW_SELL);
    //--- Индекс элемента, от которого начинается расчёт
    for (int i = 0; i < indicator_plots; i++)
        ::PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, period_rsi);
    //--- Расчёт первых уровней
    up_level = 100 - SignalLevel;
    down_level = SignalLevel;
    //--- Обнуление массивов уровней
    ::ArrayFree(up_levels);
    ::ArrayFree(down_levels);
    //--- Количество горизонтальных уровней индикатора
    ::IndicatorSetInteger(INDICATOR_LEVELS, GetLevelsIndicator());
    //--- Значения горизонтальных уровней индикатора нижнего уровня
    down_levels_total = ::ArraySize(down_levels);
    for (int i = 0; i < down_levels_total; i++)
        ::IndicatorSetDouble(INDICATOR_LEVELVALUE, i, down_levels[i]);
    //--- Значения горизонтальных уровней индикатора верхнего уровня
    up_levels_total = ::ArraySize(up_levels);
    int total = up_levels_total + down_levels_total;
    for (int i = down_levels_total, k = 0; i < total; i++, k++)
        ::IndicatorSetDouble(INDICATOR_LEVELVALUE, i, up_levels[k]);
    //--- Стиль линии
    ::IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, STYLE_DOT);
    ::IndicatorSetInteger(INDICATOR_LEVELSTYLE, 1, STYLE_DOT);
    //--- Пустое значение для построения, для которого нет отрисовки
    for (int i = 0; i < indicator_buffers; i++)
        ::PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0);
    //--- Сдвиг по оси Y
    if (BreakMode == BREAK_IN_REVERSE || BreakMode == BREAK_OUT_REVERSE) {
        ::PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, arrow_shift);
        ::PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -arrow_shift);
    } else {
        ::PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -arrow_shift);
        ::PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, arrow_shift);
    }
}
//+------------------------------------------------------------------+
//| Обнуление индикаторных буферов                                   |
//+------------------------------------------------------------------+
void ZeroIndicatorBuffers() {
    ::ArrayInitialize(rsi_buffer, 0);
    ::ArrayInitialize(buy_buffer, 0);
    ::ArrayInitialize(sell_buffer, 0);
    ::ArrayInitialize(buy_counter_buffer, 0);
    ::ArrayInitialize(sell_counter_buffer, 0);
}
//+------------------------------------------------------------------+
//| Предварительные расчёты                                          |
//+------------------------------------------------------------------+
void PreliminaryCalculations(const int prev_calculated, const double &price[]) {
    double diff = 0;
    //---
    start_pos = prev_calculated - 1;
    if (start_pos <= period_rsi) {
        //--- Первое значение индикатора не рассчитывается
        rsi_buffer[0] = 0.0;
        pos_buffer[0] = 0.0;
        neg_buffer[0] = 0.0;
        //---
        double sum_p = 0.0;
        double sum_n = 0.0;
        //---
        for (int i = 1; i <= period_rsi; i++) {
            rsi_buffer[i] = 0.0;
            pos_buffer[i] = 0.0;
            neg_buffer[i] = 0.0;
            //---
            diff = price[i] - price[i - 1];
            sum_p += (diff > 0 ? diff : 0);
            sum_n += (diff < 0 ? -diff : 0);
        }
        //--- Расчёт первого значения
        pos_buffer[period_rsi] = sum_p / period_rsi;
        neg_buffer[period_rsi] = sum_n / period_rsi;
        //---
        if (neg_buffer[period_rsi] != 0.0)
            rsi_buffer[period_rsi] = 100.0 - (100.0 / (1.0 + pos_buffer[period_rsi] / neg_buffer[period_rsi]));
        else {
            if (pos_buffer[period_rsi] != 0.0)
                rsi_buffer[period_rsi] = 100.0;
            else
                rsi_buffer[period_rsi] = 50.0;
        }
        //--- Начальная позиция для расчётов
        start_pos = period_rsi + 1;
    }
}
//+------------------------------------------------------------------+
//| Рассчитывает индикатор RSI                                       |
//+------------------------------------------------------------------+
void CalculateRSI(const int i, const double &price[]) {
    double diff = price[i] - price[i - 1];
    //---
    pos_buffer[i] = (pos_buffer[i - 1] * (period_rsi - 1) + (diff > 0.0 ? diff : 0.0)) / period_rsi;
    neg_buffer[i] = (neg_buffer[i - 1] * (period_rsi - 1) + (diff < 0.0 ? -diff : 0.0)) / period_rsi;
    //---
    if (neg_buffer[i] != 0.0)
        rsi_buffer[i] = 100.0 - 100.0 / (1 + pos_buffer[i] / neg_buffer[i]);
    else {
        rsi_buffer[i] = (pos_buffer[i] != 0.0) ? 100.0 : 50.0;
    }
}
//+------------------------------------------------------------------+
//| Рассчитывает сигналы индикатора                                  |
//+------------------------------------------------------------------+
void CalculateSignals(const int i, const int rates_total) {
    int last_index = rates_total - 1;
    //---
    bool condition1 = false;
    bool condition2 = false;
    //--- Пробой внутрь канала
    if (BreakMode == BREAK_IN || BreakMode == BREAK_IN_REVERSE) {
        if (rsi_buffer[i] < 50) {
            for (int j = 0; j < down_levels_total; j++) {
                condition1 = rsi_buffer[i - 1] < down_levels[j] && rsi_buffer[i] > down_levels[j];
                if (condition1)
                    break;
            }
        }
        //---
        if (rsi_buffer[i] > 50) {
            for (int j = 0; j < up_levels_total; j++) {
                condition2 = rsi_buffer[i - 1] > up_levels[j] && rsi_buffer[i] < up_levels[j];
                if (condition2)
                    break;
            }
        }
    } else {
        for (int j = 0; j < up_levels_total; j++) {
            condition1 = rsi_buffer[i - 1] < up_levels[j] && rsi_buffer[i] > up_levels[j];
            if (condition1)
                break;
        }
        //---
        for (int j = 0; j < down_levels_total; j++) {
            condition2 = rsi_buffer[i - 1] > down_levels[j] && rsi_buffer[i] < down_levels[j];
            if (condition2)
                break;
        }
    }
    //--- Отображаем сигналы, если условия исполнились
    if (BreakMode == BREAK_IN || BreakMode == BREAK_OUT) {
        buy_buffer[i] = (condition1) ? rsi_buffer[i] : 0;
        sell_buffer[i] = (condition2) ? rsi_buffer[i] : 0;
        //--- Счётчик только по сформировавшимся барам
        if (i < last_index) {
            if (condition1) {
                buy_counter++;
                sell_counter = 0;
            } else if (condition2) {
                sell_counter++;
                buy_counter = 0;
            }
        }
    } else {
        buy_buffer[i] = (condition2) ? rsi_buffer[i] : 0;
        sell_buffer[i] = (condition1) ? rsi_buffer[i] : 0;
        //--- Счётчик только по сформировавшимся барам
        if (i < last_index) {
            if (condition2) {
                buy_counter++;
                sell_counter = 0;
            } else if (condition1) {
                sell_counter++;
                buy_counter = 0;
            }
        }
    }
    //--- Корректировка последнего значения (равно предпоследнему)
    if (i < last_index) {
        buy_counter_buffer[i] = buy_counter;
        sell_counter_buffer[i] = sell_counter;
    } else {
        buy_counter_buffer[i] = buy_counter_buffer[i - 1];
        sell_counter_buffer[i] = sell_counter_buffer[i - 1];
    }
}
//+------------------------------------------------------------------+
