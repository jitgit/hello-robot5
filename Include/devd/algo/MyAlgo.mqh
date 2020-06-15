#property strict

class MyAlgo : public Algo
{

public:
    double calculateSL(bool isLong)
    {
        double slPrice = pipsCalculator.sl() * pipsCalculator.pips();
        double tpPrice = pipsCalculator.tp() * pipsCalculator.pips();
        return isLong ? Ask - slPrice : Bid + slPrice;
    }

    double calculateTP(bool isLong)
    {
        double slPrice = pipsCalculator.sl() * pipsCalculator.pips();
        double tpPrice = pipsCalculator.tp() * pipsCalculator.pips();
        return isLong ? Ask + tpPrice : Bid - slPrice;
    }

public:
    MyAlgo(PipsCalculator *pipsCalcultor) : Algo(pipsCalcultor)
    {
    }
};

class MyPipsCalculator : public PipsCalculator
{

public:
    double sl()
    {
        return 20;
    }

    double tp()
    {
        return 40;
    }
};