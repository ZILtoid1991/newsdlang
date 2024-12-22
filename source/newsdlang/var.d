module newsdlang.var;

public import newsdlang.enums;
public import newsdlang.exceptions;
import std.datetime;
import std.traits;

struct DLVar
{
    package union Access
    {
        long i;
        double fl;
        string str;
        ubyte[] bin;
        SysTime time;
        Duration dur;
    }
    protected Access accessor;
    protected DLValueType type;
    protected ubyte style;
    this(T)(T val, DLValueType type, ubyte style)
    {
        static if (isIntegral(T))
        {
            accessor.i = val;
        }
        else static if (isFloatingPoint(T))
        {
            accessor.fl = val;
        }
        else static if (is(T == string))
        {
            accessor.str = val;
        }
        else static if (is(T == ubyte[]))
        {
            accessor.bin = val;

        }
        else static if (is(T == bool))
        {
            accessor.i = val ? 1 : 0;

        }
        else static if (is(T == SysTime))
        {
            accessor.time = val;
        }
        else static if (is(T == Duration))
        {
            accessor.dur = val;
        }
        else static assert(0, "Value type not supported directly, use serialization techniques for classes, structs, etc.!");
        this.type = type;
        this.style = style;
    }
    T get(T)()
    {
        static if (isIntegral(T))
        {
            if (type == DLValueType.Integer || type == DLValueType.SDLInt || type == DLValueType.SDLUint ||
                    type == DLValueType.SDLLong || type == DLValueType.SDLUlong)
            {
                return accessor.i;
            }
        }
        else static if (isFloatingPoint(T))
        {
            if (type == DLValueType.Float || type == DLValueType.SDLFloat || type == DLValueType.SDLDouble)
            {
                return accessor.fl;
            }
        }
        else static if (is(T == string))
        {
            if (type == DLValueType.String)
            {
                return accessor.str;
            }
        }
        else static if (is(T == ubyte[]))
        {
            if (type == DLValueType.Binary)
            {
                return accessor.bin;
            }
        }
        else static if (is(T == bool))
        {
            if (type == DLValueType.Boolean)
            {
                return accessor.i != 0;
            }
        }
        else static if (is(T == SysTime))
        {
            if (type == DLValueType.DateTime || type == DLValueType.Date)
            {
                return accessor.time;
            }
        }
        else static if (is(T == Duration))
        {
            if (type == DLValueType.Time)
            {
                return accessor.dur;
            }
        }
        else static assert(0, "Value type not supported directly, use serialization techniques for classes, structs, etc.!");
        throw new ValueTypeException("Value type mismatch!");
    }
}
