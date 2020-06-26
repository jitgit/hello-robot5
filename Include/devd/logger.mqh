#property strict
input bool LOG_DEBUG_LEVEL = true;
input bool LOG_INFO_LEVEL = true;
input bool LOG_WARN_LEVEL = true;

void debug(string s) {
    if (LOG_DEBUG_LEVEL) {
        Print("DBUG - " + s);
    }
}

void info(string s) {
    if (LOG_INFO_LEVEL) {
        Print("INFO - " + s);
    }
}

void warn(string s) {
    if (LOG_WARN_LEVEL) {
        Print("WARN - " + s);
    }
}

void error(string s) {
    if (LOG_WARN_LEVEL || LOG_DEBUG_LEVEL) {
        Print("ERRR - " + s);
    }
}

void printArrayInfo(const double &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %d", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
}

void printArrayInfo(const datetime &a[], string msg, bool printValue = false) {
    PrintFormat("%s , size: %d", msg, ArraySize(a));
    if (printValue) {
        for (int i = 0; i < MathMin(100, ArraySize(a)); i++)
            PrintFormat("%d , %f", i, a[i]);
    }
}