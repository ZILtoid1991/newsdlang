module newsdlang.var;

public import newsdlang.enums;
public import newsdlang.exceptions;
public import std.datetime;
import std.traits;
import std.bitmanip;
import std.format;

@safe:

struct DLVar
{
    package union Access
    {
        long i;
        double fl;
        DLDateTime date;
        // TimeOfDay time;
    }
    protected string str;
    protected ubyte[] bin;
    protected Access accessor;
    protected ubyte type;
    protected ubyte style;
    protected ubyte format0;
    protected ubyte format1;
    this(T)(T val, ubyte type, ubyte style, ubyte format0 = 0, ubyte format1 = 0) @nogc nothrow pure
    {
        static if (isIntegral!T)
        {
            accessor.i = val;
        }
        else static if (isFloatingPoint!T)
        {
            accessor.fl = val;
        }
        else static if (is(T == string))
        {
            str = val;
        }
        else static if (is(T == ubyte[]))
        {
            bin = val;

        }
        else static if (is(T == bool))
        {
            accessor.i = val ? 1 : 0;

        }
        else static if (is(T == DLDateTime))
        {
            accessor.date = val;
        }
        // else static if (is(T == TimeOfDay))
        // {
        //     accessor.time = val;
        // }
        else static assert(0, "Value type not supported directly, use serialization techniques for classes, structs, etc.!");
        this.type = type;
        this.style = style;
        this.format0 = format0;
        this.format1 = format1;
    }
    T get(T)()
    {
        static if (isIntegral!T)
        {
            if (type == DLValueType.Integer || type == DLValueType.SDLInt || type == DLValueType.SDLUint ||
                    type == DLValueType.SDLLong || type == DLValueType.SDLUlong)
            {
                return accessor.i;
            }
        }
        else static if (isFloatingPoint!T)
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
                return str;
            }
        }
        else static if (is(T == ubyte[]))
        {
            if (type == DLValueType.Binary)
            {
                return bin;
            }
        }
        else static if (is(T == bool))
        {
            if (type == DLValueType.Boolean)
            {
                return accessor.i != 0;
            }
        }
        else static if (is(T == DLDateTime))
        {
            if (type == DLValueType.DateTime || type == DLValueType.Date)
            {
                return accessor.date;
            }
        }
        // else static if (is(T == TimeOfDay))
        // {
        //     if (type == DLValueType.Time)
        //     {
        //         return accessor.time;
        //     }
        // }
        else static assert(0, "Value type not supported directly, use serialization techniques for classes, structs, etc.!");
        throw new ValueTypeException("Value type mismatch!");
    }
    string toDLString() const
    {
        switch (type)
        {
        case DLValueType.SDLInt:
            return format("%d", accessor.i);
        case DLValueType.SDLUint:
            return format("%dU", accessor.i);
        case DLValueType.SDLLong:
            return format("%dL", accessor.i);
        case DLValueType.SDLUlong:
            return format("%dUL", accessor.i);
        case DLValueType.Integer:
            switch (style)
            {
            case DLNumberStyle.Binary:
                if (format0)
                {
                    return format("%,*_b", format0, accessor.i);
                }
                return format("%b", accessor.i);
            case DLNumberStyle.Octal:
                if (format0)
                {
                    return format("%,*_o", format0, accessor.i);
                }
                return format("%o", accessor.i);
            case DLNumberStyle.Hexadecimal:
                if (format0)
                {
                    return format("%,*_X", format0, accessor.i);
                }
                return format("%X", accessor.i);
            default:
                if (format0)
                {
                    return format("%,*_d", format0, accessor.i);
                }
                return format("%d", accessor.i);
            }
        case DLValueType.SDLDouble:
            return format("%fD", accessor.fl);
        case DLValueType.Float, DLValueType.SDLFloat:
            switch (style)
            {
            case DLNumberStyle.FPHexNormal:
                return format("%a", accessor.fl);
            default:
                if (format0)
                {
                    return format("%,*_f", format0, accessor.fl);
                }
                return format("%f", accessor.fl);
            }
        case DLValueType.Boolean:
            if (style == DLBooleanStyle.TrueFalse)
            {
                return accessor.i != 0 ? "true" : "false";
            }
            return accessor.i != 0 ? "yes" : "no";
        case DLValueType.String:
            switch (style)
            {

            default:
                break;
            }
            break;
        default:
            break;
        }
        return null;
    }
}
/**
 * Stores ISO date and time information in an easy to understand structure.
 * Note: Does not do any calculations and/or processing, that is the responsibility of the user.
 */
struct DLDateTime
{
    ushort      year;
    ubyte       month;
    ubyte       day;

    ubyte       hour;
    ubyte       minute;
    ubyte       second;
    mixin(bitfields!(
            bool,   "hasTime",  1,
            bool,   "hasMS",    1,
            bool,   "hasTZ",    1,
            bool,   "timeOnly", 1,
            ubyte,  "padding",  4,
    ));

    ushort      milisec;
    short       timezone;

    this (ushort year, ubyte month, ubyte day) @nogc pure nothrow
    {
        this.year = year;
        this.month = month;
        this.day = day;
    }
    this (ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second) @nogc pure nothrow
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.second = second;
        hasTime = true;
    }
    this (ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second, ushort milisec)@nogc pure nothrow
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.second = second;
        this.milisec = milisec;
        hasTime = true;
        hasMS = true;
    }
    this (ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second, ushort milisec, short timezone)
            @nogc pure nothrow
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.second = second;
        this.milisec = milisec;
        this.timezone = timezone;
        hasTime = true;
        hasMS = true;
        hasTZ = true;
    }
    static DLDateTime tz(ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second,
            short timezone) @nogc pure nothrow
    {
        DLDateTime result;
        result.year = year;
        result.month = month;
        result.day = day;
        result.hour = hour;
        result.minute = minute;
        result.second = second;
        result.timezone = timezone;
        result.hasTime = true;
        result.hasTZ = true;
        return result;
    }
    static DLDateTime time(ubyte hour, ubyte minute, ubyte second) @nogc pure nothrow
    {
        DLDateTime result;
        result.hour = hour;
        result.minute = minute;
        result.second = second;
        result.hasTime = true;
        result.timeOnly = true;
        return result;
    }
    static DLDateTime time(ubyte hour, ubyte minute, ubyte second, ushort milisec) @nogc pure nothrow
    {
        DLDateTime result;
        result.hour = hour;
        result.minute = minute;
        result.second = second;
        result.milisec = milisec;
        result.hasTime = true;
        result.hasMS = true;
        result.timeOnly = true;
        return result;
    }
    string toString() const {
        if (timeOnly)
        {
            if (hasMS)
            {
                return format("%2u:%2u:%2u.%4u", hour, minute, second, milisec);
            }
            return format("%2u:%2u:%2u", hour, minute, second);
        }
        else if (hasTime)
        {
            if (hasMS)
            {
                if (hasTZ)
                {
                    if (timezone >= 0)
                    {
                        return format("%4u-%2u-%2uT%2u:%2u:%2u.%4u+%2u:$2u", year, month, day,
                                hour, minute, second, milisec, timezone / 60, timezone % 60);
                    }
                    return format("%4u-%2u-%2uT%2u:%2u:%2u.%4u-%2u:$2u", year, month, day,
                            hour, minute, second, milisec, timezone / -60, timezone % -60);
                }
                return format("%4u-%2u-%2uT%2u:%2u:%2u.%4uZ", year, month, day,
                        hour, minute, second, milisec);
            }
            else if (hasTZ)
            {
                if (timezone >= 0)
                {
                    return format("%4u-%2u-%2uT%2u:%2u:%2u+%2u:$2u", year, month, day,
                            hour, minute, second, timezone / 60, timezone % 60);
                }
                return format("%4u-%2u-%2uT%2u:%2u:%2u-%2u:$2u", year, month, day,
                        hour, minute, second, timezone / -60, timezone % -60);
            }
            return format("%4u-%2u-%2uT%2u:%2u:%2uZ", year, month, day,
                    hour, minute, second);
        }
        return format("%4u-%2u-%2u", year, month, day);
    }
}
double hardcastUlongToDouble(ulong input) @trusted @nogc pure nothrow
{
    double _internal() @system @nogc pure nothrow
    {
        return *cast(double*)&input;
    }
    return _internal();
}
