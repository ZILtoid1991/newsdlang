module newsdlang.var;

public import newsdlang.enums;
public import newsdlang.exceptions;
import newsdlang.etc;
public import std.datetime;
import std.traits;
import std.bitmanip;
import std.format;

@safe:
/**
 * Implements a safe way to handle the accessing of data types held in a *DL variable.
 */
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
    package ubyte _type;
    package ubyte style;
    package ubyte format0;
    package ubyte format1;
    /// Creates a DLVar that simply holds a "null" value.
    static DLVar createNull() @nogc nothrow pure
    {
        DLVar result;
        result._type = DLValueType.Null;
        return result;
    }
    /**
     * Creates a DLVar with the given parameters.
     * Params:
     *   val = The value to be held by the struct.
     *   _type = the type of the value, or zero for autodetect.
     *   style = the style to be used for the given value (hexadecimal numbers, 
     * quote/escape styles, etc.)
     *   format0 = integer part underscores, zero otherwise.
     *   format1 = fraction part underscores, zero otherwise.
     */
    this(T)(T val, ubyte _type, ubyte style, ubyte format0 = 0, ubyte format1 = 0) @nogc nothrow pure
    {
        static if (isIntegral!T)
        {
            accessor.i = val;
            if (!_type) _type = DLValueType.Integer;
        }
        else static if (isFloatingPoint!T)
        {
            accessor.fl = val;
            if (!_type) _type = DLValueType.Float;
        }
        else static if (is(T == string))
        {
            str = val;
            if (!_type) _type = DLValueType.String;
        }
        else static if (is(T == ubyte[]))
        {
            bin = val;
            if (!_type) _type = DLValueType.Binary;
        }
        else static if (is(T == bool))
        {
            accessor.i = val ? 1 : 0;
            if (!_type) _type = DLValueType.Boolean;
        }
        else static if (is(T == DLDateTime))
        {
            accessor.date = val;
            if (!_type)
            {
                if (val.timeOnly) _type = DLValueType.Time;
                else if (val.hasTime) _type = DLValueType.DateTime;
                else _type = DLValueType.Date;
            }
        }
        // else static if (is(T == TimeOfDay))
        // {
        //     accessor.time = val;
        // }
        else static assert(0,
                "Value type not supported directly, use serialization techniques for classes, structs, etc.!");
        this._type = _type;
        this.style = style;
        this.format0 = format0;
        this.format1 = format1;
    }
    /// Returns the value held by this DLVar as given type if possible, throws 
    /// `ValueTypeException` if type is mismatched.
    T get(T)()
    {
        static if (isIntegral!T)
        {
            if (_type == DLValueType.Integer || _type == DLValueType.SDLInt || _type == DLValueType.SDLUint ||
                    _type == DLValueType.SDLLong || _type == DLValueType.SDLUlong || _type == DLValueType.Null)
            {
                return cast(T)accessor.i;
            }
        }
        else static if (isFloatingPoint!T)
        {
            if (_type == DLValueType.Float || _type == DLValueType.SDLFloat || _type == DLValueType.SDLDouble)
            {
                return cast(T)accessor.fl;
            }
        }
        else static if (is(T == string))
        {
            if (_type == DLValueType.String)
            {
                return str;
            }
        }
        else static if (is(T == ubyte[]))
        {
            if (_type == DLValueType.Binary)
            {
                return bin;
            }
        }
        else static if (is(T == bool))
        {
            if (_type == DLValueType.Boolean)
            {
                return accessor.i != 0;
            }
        }
        else static if (is(T == DLDateTime))
        {
            if (_type == DLValueType.DateTime || _type == DLValueType.Date)
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
    /// Converts data to *DL string.
    string toDLString() const
    {
        switch (_type)
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
                    return format("0b%,*_b", format0, accessor.i);
                }
                return format("0b%b", accessor.i);
            case DLNumberStyle.Octal:
                if (format0)
                {
                    return format("0o%,*_o", format0, accessor.i);
                }
                return format("0o%o", accessor.i);
            case DLNumberStyle.Hexadecimal:
                // if (format0)
                // {
                //     return format("0x%,*,X", format0, accessor.i);
                // }
                return format("0x%X", accessor.i);
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
            case DLStringType.Backtick:
                return CharTokens.Backtick ~ str ~ CharTokens.Backtick;
            case DLStringType.Scope:
                return Tokens.StringScopeBegin ~ str ~ Tokens.StringScopeEnd;
            case DLStringType.Quote:
                return CharTokens.Quote ~ insertEscapeChars(str) ~ CharTokens.Quote;
            case DLStringType.Apostrophe:
                return CharTokens.Apostrophe ~ insertEscapeChars(str) ~ CharTokens.Apostrophe;
            default:
                break;
            }
            break;
        default:
                return "null";
            break;
        }
        return null;
    }
    bool opEquals(DLVar rhs) @safe @nogc pure nothrow const
    {
        if (this._type != rhs.type) return false;
        final switch (_type) with (DLValueType)
        {
            case init: return false;
            case Null: return true;
            case SDLInt:
            case SDLUint:
            case SDLLong:
            case SDLUlong:
            case Boolean:
            case Integer: return accessor.i == rhs.accessor.i;
            case SDLFloat:
            case SDLDouble:
            case Float: return accessor.fl == rhs.accessor.fl;
            case String: return str == rhs.str;
            case Date:
            case DateTime:
            case Time:
            case Binary: return bin == rhs.bin;

        }
    }
    /// Returns the typeID of this DLVar value.
    DLValueType type() const @nogc nothrow pure
    {
        return cast(DLValueType)type;
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
