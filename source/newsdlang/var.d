module newsdlang.var;

public import newsdlang.enums;
import std.datetime;

struct DLVar
{
    package union Access {
        long i;
        double fl;
        string str;
        ubyte[] bin;
        SysTime time;
        Duration dur;
    }
}