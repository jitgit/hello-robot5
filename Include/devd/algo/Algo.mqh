#property strict

class PipsCalculator
{
public:
    virtual double sl()
    {
        return 0.0;
    };
    virtual double tp()
    {
        return 0.0;
    };

    double pips()
    {
        if (_Digits >= 4)
            return 0.0001;
        else
            return 0.01;
    }
};

class Algo
{
protected:
    PipsCalculator *pipsCalculator;

public:
    virtual double calculateSL(bool isLong)
    {
        return 0.0;
    }
    virtual double calculateTP(bool isLong)
    {
        return 0.0;
    }

public:
    Algo(PipsCalculator *calc)
    {
        pipsCalculator = calc;
    }
};