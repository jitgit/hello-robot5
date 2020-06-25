
#property strict

class AccountManager {
   protected:
    double itsRiskPercentage;

   public:
    AccountManager(double riskPercentage = 0.02) {
        itsRiskPercentage = riskPercentage;
    }

    void printAccountInfo() {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double profit = AccountInfoDouble(ACCOUNT_PROFIT);
        string accCurr = AccountInfoString(ACCOUNT_CURRENCY);
        debug(StringFormat("AccountCurrency :%s, _Symbol: %s", accCurr, _Symbol));
    }
};
