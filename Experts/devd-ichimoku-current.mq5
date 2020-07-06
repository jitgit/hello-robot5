#property strict

#include <devd/ichimoku/kumo.mqh>
#include <devd/signal/Stochastic/StochasticKDCrossOverScanner.mqh>
#include <devd/signal/Stochastic/StochasticLimitsScanner.mqh>

SignalScanner *crossOverScanner = new StochasticKDCrossOverScanner();
SignalScanner *confirmationInHTF = new StochasticLimitsScanner();
int ichiHandle = 0;
int OnInit() {
    ichiHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);  //TO add ichimoku to tester
    return INIT_SUCCEEDED;
}

void OnTick() {
    SignalResult *signal = crossOverScanner.scan(_Symbol, _Period);

    if (signal.go != GO_NOTHING) {
        SymbolData *s = new SymbolData(_Symbol);

        KumoAnalysis *d1 = getKumoAnalysis(s, PERIOD_D1);
        KumoAnalysis *h4 = getKumoAnalysis(s, PERIOD_H4);
        KumoAnalysis *h1 = getKumoAnalysis(s, PERIOD_H1);
        KumoAnalysis *m30 = getKumoAnalysis(s, PERIOD_M30);

        datetime candleTime = iTime(s.symbol, _Period, 0);

        if (signal.go == GO_LONG) {
            if (d1.trend >= 0 || h4.trend >= 0 || h1.trend >= 0 || m30.trend >= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend > 0 && d1.trend * h4.trend * h1.trend * m30.trend >= 0) {  // Making sure two TFs trends are not opposite
                    ENUM_TIMEFRAMES higherTF = PERIOD_H4;

                    if (d1.trend == 1)
                        higherTF = PERIOD_D1;

                    SignalResult *confirmationSignal = new SignalResult(s.symbol);
                    confirmationSignal = confirmationInHTF.scan(s.symbol, higherTF);

                    info(StringFormat("►►►►1st Confirmation GO_LONG, DOUBLE CONFIRMATION - TF %s , %s", EnumToString(higherTF), EnumToString(confirmationSignal.go)));
                    if (confirmationSignal.go != GO_SHORT) {
                        info(StringFormat("►►►►►►►►►►►►►►►► BUY BUY BUY %s", signal.str()));
                        PrintFormat("%s ", d1.str());
                        PrintFormat("%s ", h4.str());
                        PrintFormat("%s ", h1.str());
                        PrintFormat("%s ", m30.str());
                    }
                }
        } else if (signal.go == GO_SHORT) {
            if (d1.trend <= 0 || h4.trend <= 0 || h1.trend <= 0 || m30.trend <= 0)
                if (d1.trend + h4.trend + h1.trend + m30.trend < 0 && d1.trend * h4.trend * h1.trend * m30.trend <= 0) {  // Making sure two TFs trends are not opposite

                    ENUM_TIMEFRAMES higherTF = PERIOD_H4;
                    if (d1.trend == -1)
                        higherTF = PERIOD_D1;

                    SignalResult *confirmationSignal = new SignalResult(s.symbol);
                    confirmationSignal = confirmationInHTF.scan(s.symbol, higherTF);

                    info(StringFormat("►►►►1st Confirmation GO_SHORT, DOUBLE CONFIRMATION - TF %s , %s", EnumToString(higherTF), EnumToString(confirmationSignal.go)));
                    if (confirmationSignal.go != GO_LONG) {
                        info(StringFormat("►►►►►►►►►►►►►►►► SELL SELL SELL %s", signal.str()));
                        PrintFormat("%s ", d1.str());
                        PrintFormat("%s ", h4.str());
                        PrintFormat("%s ", h1.str());
                        PrintFormat("%s ", m30.str());
                    }
                }
        }
    }
}
