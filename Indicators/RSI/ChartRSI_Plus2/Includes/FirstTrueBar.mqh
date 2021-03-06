//+------------------------------------------------------------------+
//|                                                 FirstTrueBar.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Class for defining a true bar                             |
//+------------------------------------------------------------------+
class CFirstTrueBar {
   private:
    //--- True Bar Time
    datetime m_limit_time;
    //--- True Bar Number
    int m_limit_bar;
    //---
   public:
    CFirstTrueBar(void);
    ~CFirstTrueBar(void);
    //--- Returns (1) time and (2) true bar number
    datetime LimitTime(void) const { return (m_limit_time); }
    int LimitBar(void) const { return (m_limit_bar); }
    //--- Defines the first true bar
    bool DetermineFirstTrueBar(void);
    //---Check the bar
    //bool              CheckFirstTrueBar(const int bar_index);
    //---
   private:
    //--- Searches for the first true bar of the current period
    void GetFirstTrueBarTime(const datetime &time[]);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFirstTrueBar::CFirstTrueBar(void) : m_limit_time(NULL),
                                     m_limit_bar(WRONG_VALUE) {
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CFirstTrueBar::~CFirstTrueBar(void) {
}
//+------------------------------------------------------------------+
//| Defines the first true bar                                   |
//+------------------------------------------------------------------+
bool CFirstTrueBar::DetermineFirstTrueBar(void) {
    //--- Array of time bars
    datetime time[];
    //--- Get the total number of character bars
    int available_bars = ::Bars(_Symbol, _Period);
    //--- Copy the array of time bars. If it doesn’t work, try again.
    if (::CopyTime(_Symbol, _Period, 0, available_bars, time) < available_bars)
        return (false);
    //--- We get the time of the first true bar, which corresponds to the current timeframe
    GetFirstTrueBarTime(time);
    return (true);
}
//+------------------------------------------------------------------+
//| Searches for the first true bar of the current period                       |
//+------------------------------------------------------------------+
void CFirstTrueBar::GetFirstTrueBarTime(const datetime &time[]) {
    //---Get the size of the array
    int array_size = ::ArraySize(time);
    ::ArraySetAsSeries(time, false);
    //--- Поочередно проверяем каждый бар
    for (int i = 1; i < array_size; i++) {
        //--- Если бар соответствует текущему таймфрейму
        if (time[i] - time[i - 1] == ::PeriodSeconds()) {
            //--- Запомним и остановим цикл
            m_limit_time = time[i - 1];
            m_limit_bar = i - 1;
            break;
        }
    }
}
//+------------------------------------------------------------------+
//| Проверка первого истинного бара для отрисовки                    |
//+------------------------------------------------------------------+
//bool CFirstTrueBar::CheckFirstTrueBar(const int bar_index)
//  {
//   return(bar_index>=m_limit_bar);
//  }
//+------------------------------------------------------------------+
