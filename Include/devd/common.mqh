#property strict
input bool DEBUG_INFO = true;
input bool WARN_INFO = true;

void log(string s)
{
    Print("INFO - " + s);
}

void debug(string s)
{
    if (DEBUG_INFO)
    {
        Print("DBUG - " + s);
    }
}

void warn(string s)
{
    if (WARN_INFO)
    {
        Print("WARN - " + s);
    }
}

double norm(double d)
{
    return NormalizeDouble(d, _Digits);
}

string tsMin(datetime dt)
{
    return TimeToString(dt, TIME_MINUTES);
}

string tsDate(datetime dt)
{
    return StringFormat("%s %s", TimeToString(dt, TIME_DATE), tsMin(dt));
}
