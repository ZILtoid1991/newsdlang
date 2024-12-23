module newsdlang.parser;

public import newsdlang.lexer;
public import newsdlang.var;
import newsdlang.enums;

import std.conv : to;
import std.datetime;

@safe:
struct Parser
{
    package Lexer lexer;
    /// Forwards the lexer until whitespaces are consumed, then sets the current position as the next beginning of a token.
    /// Returns true if lexer is empty.
    bool consumeWhitespace()
    {
        lexer.dropWhile(Tokens.WhiteSpaces);
        lexer.start();
        return lexer.empty();
    }
    /// Parses the comment, then returns its content as a string.
    /// `style` indicates the style of the comment.
    string parseComment(DLCommentType style)
    {
        string result;
        switch (style) 
        {
        case DLCommentType.Slash, DLCommentType.Hash:
            lexer.advanceUntilAny(Tokens.EndOfLine, false);
            result = lexer.get;
            break;
        case DLCommentType.Asterisk:
            lexer.advanceUntil(Tokens.CommentBlockEnd, false);
            result = lexer.get;
            break;
        case DLCommentType.Plus:
            lexer.advanceUntil(Tokens.CommentBlockEndS, false);
            result = lexer.get;
            break;
        default:
            break;
        }
        return result;
    }
    /// Parses a string token, and returns its content as a string, with escaping where it's necessary.
    /// `style` indicates the style of the string.
    string parseString(DLStringType style)
    {
        string result;
        switch (style) 
        {
        case DLStringType.Quote:
            do {
                lexer.advanceUntil(CharTokens.Quote, false);
            } while (lexer.peekBack != '\\');
            result = escapeString(lexer.get);
            break;
        case DLStringType.Apostrophe:
            do {
                lexer.advanceUntil(CharTokens.Apostrophe, false);
            } while (lexer.peekBack != '\\');
            result = escapeString(lexer.get);
            break;
        case DLStringType.Backtick:
            lexer.advanceUntil(CharTokens.Backtick, false);
            result = lexer.get;
            break;
        case DLStringType.Scope:
            lexer.advanceUntil(Tokens.StringScopeEnd, false);
            result = lexer.get;
            break;
        default:
            break;
        }
        return result;
    }
    /// Parses a regular element (tag name, attribute name, numeric value, etc.).
    string parseRegularElement()
    {
        lexer.advanceUntilAny(Tokens.EndOfElement, false);
        return lexer.get;
    }
    DLVar parseVariable()
    {
        string variableStr = parseRegularElement();
        switch (variableStr)
        {
        case "-0.0", "-.0":
            return DLVar(-0.0, DLValueType.Float, DLNumberStyle.Decimal);
        case "NaN":
            return DLVar(double.nan, DLValueType.Float, DLNumberStyle.Decimal);
        case "inf+":
            return DLVar(double.max, DLValueType.Float, DLNumberStyle.Decimal);
        case "inf-":
            return DLVar(double.min, DLValueType.Float, DLNumberStyle.Decimal);
        case "true":
            return DLVar(true, DLValueType.Boolean, DLBooleanStyle.TrueFalse);
        case "false":
            return DLVar(false, DLValueType.Boolean, DLBooleanStyle.TrueFalse);
        case "yes":
            return DLVar(true, DLValueType.Boolean, DLBooleanStyle.YesNo);
        case "no":
            return DLVar(false, DLValueType.Boolean, DLBooleanStyle.YesNo);
        default:
            return DLVar.init;
        }
    }
}

bool isNumber(char c) @nogc nothrow pure
{
    return c >= '0' && c <= '9';
}
bool isHexDigit(char c) @nogc nothrow pure
{
    return isNumber(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}
bool isOctalDigit(char c) @nogc nothrow pure
{
    return c >= '0' && c <= '7';
}
bool isBinaryDigit(char c) @nogc nothrow pure
{
    return c == '0' || c == '1';
}
unittest
{
    assert(isNumber('0'));
    assert(isNumber('1'));
    assert(isNumber('2'));
    assert(isNumber('3'));
    assert(isNumber('4'));
    assert(isNumber('5'));
    assert(isNumber('6'));
    assert(isNumber('7'));
    assert(isNumber('8'));
    assert(isNumber('9'));

    assert(isHexDigit('0'));
    assert(isHexDigit('1'));
    assert(isHexDigit('2'));
    assert(isHexDigit('3'));
    assert(isHexDigit('4'));
    assert(isHexDigit('5'));
    assert(isHexDigit('6'));
    assert(isHexDigit('7'));
    assert(isHexDigit('8'));
    assert(isHexDigit('9'));
    assert(isHexDigit('a'));
    assert(isHexDigit('b'));
    assert(isHexDigit('c'));
    assert(isHexDigit('d'));
    assert(isHexDigit('e'));
    assert(isHexDigit('f'));
    assert(!isHexDigit('g'));
    assert(isHexDigit('A'));
    assert(isHexDigit('B'));
    assert(isHexDigit('C'));
    assert(isHexDigit('D'));
    assert(isHexDigit('E'));
    assert(isHexDigit('F'));
    assert(!isHexDigit('G'));

    assert(isOctalDigit('0'));
    assert(isOctalDigit('1'));
    assert(isOctalDigit('2'));
    assert(isOctalDigit('3'));
    assert(isOctalDigit('4'));
    assert(isOctalDigit('5'));
    assert(isOctalDigit('6'));
    assert(isOctalDigit('7'));
    assert(!isOctalDigit('8'));
    assert(!isOctalDigit('9'));

    assert(isBinaryDigit('0'));
    assert(isBinaryDigit('1'));
    assert(!isBinaryDigit('2'));
    assert(!isBinaryDigit('3'));
    assert(!isBinaryDigit('4'));
    assert(!isBinaryDigit('5'));
    assert(!isBinaryDigit('6'));
    assert(!isBinaryDigit('7'));
    assert(!isBinaryDigit('8'));
    assert(!isBinaryDigit('9'));
}
int lookupHexDigit(char c) @nogc nothrow
{
    switch ( c )
    {
    case 'a', 'A':
        return 0x0a;
    case 'b', 'B':
        return 0x0b;
    case 'c', 'C':
        return 0x0c;
    case 'd', 'D':
        return 0x0d;
    case 'e', 'E':
        return 0x0e;
    case 'f', 'F':
        return 0x0f;
    case '0': .. case '9':
        return c - '0';
    default:
        return -1;
    }
}
/**
 * Detects numeric types, and parses it if it's a valid integer, floating point number, or a date.
 * Params:
 *   input = The string input
 *   parseOut = The parsed data, with the following layout: 
 *     [0]: Integer / floating point fractional part / year
 *     [1]: Floating point whole part / month
 *     [2]: Day
 *     [3]: Hours
 *     [4]: Minutes
 *     [5]: Second
 *     [6]: Miliseconds
 *     [7]: Timezone offsets in minutes
 * Returns: An 8 element array with the following layout:
 *   [0]: Type identifier if valid type, or zero otherwise
 *   [1]: Style of type if applicable
 *   [2]: Counter for underline styles, otherwise counter for digits (integer) or counter for fraction (floating-point)
 *   [3]: Non zero if underscore is used
 *   [4]: Counter for underline styles in floating point numbers' whole part, otherwise counter for whole digits
 *   [5]: Non zero if underscore is used for floating point numbers' whole part
 *   [6]: Unused
 *   [7]: Digit counter for floating point numbers' fraction
 */
ubyte[8] detectAndParseNumericType(string input, ref long[8] parseOut) nothrow
{
    ubyte[8] result;
    switch (input.length) 
    {
    case 9:     //Potential ISO Time
        if (input[$-1] == CharTokens.NoTimeZoneIdentifier) 
        {
            if (input[2] == CharTokens.Colon && input[5] == CharTokens.Colon) 
            {
                foreach (i ; [0,1,3,4,6,7])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                /* if (isNumber(input[0]) && isNumber(input[1]) && isNumber(input[3]) && isNumber(input[4]) && 
                        isNumber(input[6]) && isNumber(input[7]))
                { */
                result[0] = DLValueType.Time;
                result[1] = DLDateTimeType.Time;
                parseOut[3] = ((input[0] - '0') * 10) + input[1] - '0';
                parseOut[4] = ((input[3] - '0') * 10) + input[4] - '0';
                parseOut[5] = ((input[6] - '0') * 10) + input[7] - '0';
                /* } */
            }
        } 
        else 
        {
            goto default;
        }
        break;
    case 10:    //Potential ISO Date
        if (input[4] == CharTokens.Minus && input[7] == CharTokens.Minus) 
        {
            foreach (i ; [0,1,2,3,5,6,8,9])
            {
                if (!isNumber(input[i]))
                {
                    return [0,0,0,0,0,0,0,0];
                }
            }
            /* if (isNumber(input[0]) && isNumber(input[1]) && isNumber(input[2]) && isNumber(input[3]) && 
                    isNumber(input[5]) && isNumber(input[6]) && isNumber(input[8]) && isNumber(input[9]))
            { */
            result[0] = DLValueType.Date;
            result[1] = DLDateTimeType.Date;
            parseOut[0] = ((input[0] - '0') * 1000) + ((input[1] - '0') * 100) + ((input[2] - '0') * 10) + 
                    input[3] - '0';
            parseOut[1] = ((input[5] - '0') * 10) + input[6] - '0';
            parseOut[2] = ((input[8] - '0') * 10) + input[9] - '0';
            /* } */
        } 
        else 
        {
            goto default;
        }
        break;
    case 13:    //Potential ISO Time with miliseconds
        if (input[$-1] == CharTokens.NoTimeZoneIdentifier) 
        {
            if (input[2] == CharTokens.Colon && input[5] == CharTokens.Colon && input[8] == '.') 
            {
                foreach (i ; [0,1,3,4,6,7,9,10,11])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                /* if (isNumber(input[0]) && isNumber(input[1]) && isNumber(input[3]) && isNumber(input[4]) && 
                        isNumber(input[6]) && isNumber(input[7]) && isNumber(input[9]) && isNumber(input[10]) && 
                        isNumber(input[11]))
                { */
                result[0] = DLValueType.Time;
                result[1] = DLDateTimeType.TimeMS;
                parseOut[3] = ((input[0] - '0') * 10) + input[1] - '0';
                parseOut[4] = ((input[3] - '0') * 10) + input[4] - '0';
                parseOut[5] = ((input[6] - '0') * 10) + input[7] - '0';
                parseOut[6] = ((input[9] - '0') * 100) + ((input[10] - '0') * 10) + input[11] - '0';
                /* } */
            }
        } 
        else 
        {
            goto default;
        }
        break;
    case 20:    //Potential ISO Date and Time
        if (input[$-1] == CharTokens.NoTimeZoneIdentifier) 
        {
            if (input[4] == CharTokens.Minus && input[7] == CharTokens.Minus && 
                    input[10] == CharTokens.DateTimeSeparator && input[13] == CharTokens.Colon && 
                    input[16] == CharTokens.Colon) 
            {
                foreach (i ; [0,1,2,3,5,6,8,9,11,12,14,15,17,18])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                /* if (isNumber(input[0]) && isNumber(input[1]) && isNumber(input[2]) && isNumber(input[3]) && 
                        isNumber(input[5]) && isNumber(input[6]) && isNumber(input[8]) && isNumber(input[9]) &&
                        isNumber(input[11]) && isNumber(input[12]) && isNumber(input[14]) && isNumber(input[15]) &&
                        isNumber(input[17]) && isNumber(input[18]))
                { */
                result[0] = DLValueType.DateTime;
                result[1] = DLDateTimeType.DateTimeMS;
                parseOut[0] = ((input[0] - '0') * 1000) + ((input[1] - '0') * 100) + ((input[2] - '0') * 10) + 
                    input[3] - '0';
                parseOut[1] = ((input[5] - '0') * 10) + input[6] - '0';
                parseOut[2] = ((input[8] - '0') * 10) + input[9] - '0';
                parseOut[3] = ((input[11] - '0') * 10) + input[12] - '0';
                parseOut[4] = ((input[14] - '0') * 10) + input[15] - '0';
                parseOut[5] = ((input[17] - '0') * 10) + input[18] - '0';
                /* } */
            }
        } 
        else 
        {
            goto default;
        }
        break;
    case 24:    //Potential ISO Date and Time with miliseconds
        if (input[$-1] == CharTokens.NoTimeZoneIdentifier) 
        {
            if (input[4] == CharTokens.Minus && input[7] == CharTokens.Minus && 
                    input[10] == CharTokens.DateTimeSeparator && input[13] == CharTokens.Colon && 
                    input[16] == CharTokens.Colon && input[19] == '.') 
            {
                foreach (i ; [0,1,2,3,5,6,8,9,11,12,14,15,17,18,20,21,22])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                result[0] = DLValueType.DateTime;
                result[1] = DLDateTimeType.DateTime;
                parseOut[0] = ((input[0] - '0') * 1000) + ((input[1] - '0') * 100) + ((input[2] - '0') * 10) + 
                    input[3] - '0';
                parseOut[1] = ((input[5] - '0') * 10) + input[6] - '0';
                parseOut[2] = ((input[8] - '0') * 10) + input[9] - '0';
                parseOut[3] = ((input[11] - '0') * 10) + input[12] - '0';
                parseOut[4] = ((input[14] - '0') * 10) + input[15] - '0';
                parseOut[5] = ((input[17] - '0') * 10) + input[18] - '0';
                parseOut[6] = ((input[20] - '0') * 100) + ((input[21] - '0') * 10) + input[22] - '0';
            }
        } 
        else 
        {
            goto default;
        }
        break;
    case 25:    //Potential ISO Date and Time with timezone
        if (input[10] == CharTokens.DateTimeSeparator)
        {
            if (input[4] == CharTokens.Minus && input[7] == CharTokens.Minus && 
                    input[10] == CharTokens.DateTimeSeparator && input[13] == CharTokens.Colon && 
                    input[16] == CharTokens.Colon && input[22] == CharTokens.Colon)
            {
                foreach (i ; [0,1,2,3,5,6,8,9,11,12,14,15,17,18,20,21,23,24])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                parseOut[7] = ((input[20] - '0') * 600) + ((input[21] - '0') * 60) + ((input[23] - '0') * 10) + 
                        input[24] - '0';
                if (input[19] == CharTokens.Minus)
                {
                    parseOut[7] *= -1;
                }
                else if (input[19] != CharTokens.Plus)
                {
                    return [0,0,0,0,0,0,0,0];
                }
                result[0] = DLValueType.DateTime;
                result[1] = DLDateTimeType.DateTimeZone;
                parseOut[0] = ((input[0] - '0') * 1000) + ((input[1] - '0') * 100) + ((input[2] - '0') * 10) + 
                    input[3] - '0';
                parseOut[1] = ((input[5] - '0') * 10) + input[6] - '0';
                parseOut[2] = ((input[8] - '0') * 10) + input[9] - '0';
                parseOut[3] = ((input[11] - '0') * 10) + input[12] - '0';
                parseOut[4] = ((input[14] - '0') * 10) + input[15] - '0';
                parseOut[5] = ((input[17] - '0') * 10) + input[18] - '0';
            }
        }
        else
        {
            goto default;
        }
        break;
    case 29:    //Potential ISO Date and Time with miliseconds and timezone
        if (input[10] == CharTokens.DateTimeSeparator)
        {
            if (input[4] == CharTokens.Minus && input[7] == CharTokens.Minus && 
                    input[10] == CharTokens.DateTimeSeparator && input[13] == CharTokens.Colon && 
                    input[16] == CharTokens.Colon && input[26] == CharTokens.Colon && input[19] == '.')
            {
                foreach (i ; [0,1,2,3,5,6,8,9,11,12,14,15,17,18,20,21,22,24,25,27,28])
                {
                    if (!isNumber(input[i]))
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                parseOut[7] = ((input[24] - '0') * 600) + ((input[25] - '0') * 60) + ((input[27] - '0') * 10) + 
                        input[28] - '0';
                if (input[23] == CharTokens.Minus)
                {
                    parseOut[7] *= -1;
                }
                else if (input[23] != CharTokens.Plus)
                {
                    return [0,0,0,0,0,0,0,0];
                }
                result[0] = DLValueType.DateTime;
                result[1] = DLDateTimeType.DateTimeMSZone;
                parseOut[0] = ((input[0] - '0') * 1000) + ((input[1] - '0') * 100) + ((input[2] - '0') * 10) + 
                    input[3] - '0';
                parseOut[1] = ((input[5] - '0') * 10) + input[6] - '0';
                parseOut[2] = ((input[8] - '0') * 10) + input[9] - '0';
                parseOut[3] = ((input[11] - '0') * 10) + input[12] - '0';
                parseOut[4] = ((input[14] - '0') * 10) + input[15] - '0';
                parseOut[5] = ((input[17] - '0') * 10) + input[18] - '0';
                parseOut[6] = ((input[20] - '0') * 100) + ((input[21] - '0') * 10) + input[22] - '0';
            }
        }
        else
        {
            goto default;
        }
        break;        
    default:
        if (input.length > 2) 
        {
            if (input[1] == CharTokens.HexIdentifier) 
            { //Hexadecimal number
                if (input[0] == '0') 
                { //First digit must be zero
                    result[0] = DLValueType.Integer;
                    result[1] = DLNumberStyle.Hexadecimal;
                    for (sizediff_t i = 2 ; i < input.length ; i++) 
                    {
                        int hexDigit = lookupHexDigit(input[i]);
                        if (hexDigit != -1)
                        {   
                            parseOut[0] *= 16;
                            parseOut[0] += hexDigit;
                            result[2]++;
                            result[7]++;
                        }
                        else if (input[i] == CharTokens.Underscore)
                        { // Reset counter on underscore, also set field 3
                            result[3] = result[2];
                            result[2] = 0;
                        }
                        else if (input[i] == 'p')
                        { // Number is hexadecimal floating point
                            if (result[0] != DLValueType.Float)
                            {
                                result[0] = DLValueType.Float;
                                result[4] = result[2];
                                result[5] = result[3];
                                result[7] = 0;
                                parseOut[1] = parseOut[0];
                            }
                            else
                            {
                                return [0,0,0,0,0,0,0,0];
                            }
                        }
                        else if (input[i] == CharTokens.Minus)
                        {
                            parseOut[0] *= -1;
                        }
                        else
                        { // Return all zeros if invalid
                            return [0,0,0,0,0,0,0,0];
                        }
                    }
                    return result;
                }
                return [0,0,0,0,0,0,0,0];
            }
            else if (input[1] == CharTokens.OctIdentifier)
            {
                if (input[0] == '0') 
                { //First digit must be zero
                    result[0] = DLValueType.Integer;
                    result[1] = DLNumberStyle.Octal;
                    for (sizediff_t i = 2 ; i < input.length ; i++) 
                    {
                        if (isOctalDigit(input[i])) 
                        {   
                            parseOut[0] *= 8;
                            parseOut[0] += input[i] - '0';
                            result[2]++;
                            result[7]++;
                        }
                        else if (input[i] == CharTokens.Underscore)
                        { // Reset counter on underscore, also set field 3
                            result[3] = result[2];
                            result[2] = 0;
                        }
                        else
                        { // Return all zeros if invalid
                            return [0,0,0,0,0,0,0,0];
                        }
                    }
                    return result;
                }
                return [0,0,0,0,0,0,0,0];
            }
            else if (input[1] == CharTokens.BinIdentifier)
            {
                if (input[0] == '0') 
                { //First digit must be zero
                    result[0] = DLValueType.Integer;
                    result[1] = DLNumberStyle.Binary;
                    for (sizediff_t i = 2 ; i < input.length ; i++) 
                    {
                        if (isBinaryDigit(input[i])) 
                        {   
                            parseOut[0] *= 2;
                            parseOut[0] += input[i] - '0';
                            result[2]++;
                            result[7]++;
                        }
                        else if (input[i] == CharTokens.Underscore)
                        { // Reset counter on underscore, also set field 3
                            result[3] = result[2];
                            result[2] = 0;
                        }
                        else
                        { // Return all zeros if invalid
                            return [0,0,0,0,0,0,0,0];
                        }
                    }
                    return result;
                }
                return [0,0,0,0,0,0,0,0];
            }
        } 
        result[0] = DLValueType.Integer;
        result[1] = DLNumberStyle.Decimal;
        bool isNegative;
        for (sizediff_t i ; i < input.length ; i++)
        {
            if (isNumber(input[i]))
            {
                parseOut[0] *= 10;
                parseOut[0] += input[i] - '0';
                result[2]++;
                result[7]++;
            }
            else if (input[i] == CharTokens.Underscore)
            { // Reset counter on underscore, also set field 3
                result[3] = result[2];
                result[2] = 0;
            }
            else if (input[i] == '.')
            {
                if (result[0] != DLValueType.Float)
                {
                    result[0] = DLValueType.Float;
                    result[4] = result[2];
                    result[5] = result[3];
                    result[2] = 0;
                    result[3] = 0;
                    result[7] = 0;
                    parseOut[1] = parseOut[0];
                    parseOut[0] = 0L;
                }
                else
                {
                    return [0,0,0,0,0,0,0,0];
                }
            }
            else if (input[i] == '-' && i == 0)
            {
                isNegative = true;
            }
            else if (input[i] == 'U')
            {   //Value might be either SDL uint or ulong
                if (i + 2 == input.length)
                {
                    if (input[i + 1] == 'L')
                    {
                        result[0] = DLValueType.SDLUlong;
                        break;
                    }
                    else
                    {
                        return [0,0,0,0,0,0,0,0];
                    }
                }
                else if (i + 1 == input.length)
                {
                    result[0] = DLValueType.SDLUint;
                }
            }
            else if (i + 1 == input.length)
            {   //Value might be SDL long, float, or double
                switch(input[i]){
                case 'L':
                    result[0] = DLValueType.SDLLong;
                    break;
                case 'd':
                    result[0] = DLValueType.SDLDouble;
                    break;
                case 'f':
                    result[0] = DLValueType.SDLFloat;
                    break;
                default:
                    return [0,0,0,0,0,0,0,0];
                }
            }
            else
            {
                return [0,0,0,0,0,0,0,0];
            }
        }
        if (isNegative)
        {
            if (result[0] == DLValueType.Integer)
            {
                parseOut[0] *= -1;
            }
            else
            {
                parseOut[1] *= -1;
            }
        }
        break;
    }
    return result;
}
unittest
{
    import std.conv;
    long[8] parseOut;
    ubyte[8] frmt;
    assert(detectAndParseNumericType("0", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == 0, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("5", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == 5, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("23", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == 23, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("-23", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == -23, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("255", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == 255, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("65_536", parseOut)[0] == DLValueType.Integer);
    assert(parseOut[0] == 65_536, parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("65.536", parseOut)[0] == DLValueType.Float);
    assert(parseOut[0] == 536 && parseOut[1] == 65, parseOut[1].to!string ~ "." ~ parseOut[0].to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    assert(detectAndParseNumericType("65.0536", parseOut)[0] == DLValueType.Float);
    assert(parseOut[0] == 536 && parseOut[1] == 65, parseOut[1].to!string ~ "." ~ parseOut[0].to!string);

    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("65.0536", parseOut);
    assert(frmt[0] == DLValueType.Float && frmt[7] == 4);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("65.000536", parseOut);
    assert(frmt[0] == DLValueType.Float && frmt[7] == 6);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("65_536", parseOut);
    assert(frmt[0] == DLValueType.Integer && frmt[2] == 3, frmt.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("65_536.00_01", parseOut);
    assert(frmt[0] == DLValueType.Float && frmt[4] == 3 && frmt[2] == 2, frmt.to!string);

    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("0x65_536", parseOut);
    assert(frmt[0] == DLValueType.Integer && frmt[1] == DLNumberStyle.Hexadecimal && frmt[2] == 3, frmt.to!string);
    assert(parseOut[0] == 0x65_536, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("0xdd_CCC", parseOut);
    assert(frmt[0] == DLValueType.Integer && frmt[1] == DLNumberStyle.Hexadecimal && frmt[2] == 3, frmt.to!string);
    assert(parseOut[0] == 0xdd_ccc, parseOut.to!string);

    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("0o65_536", parseOut);
    assert(frmt[0] == DLValueType.Integer && frmt[1] == DLNumberStyle.Octal && frmt[2] == 3, frmt.to!string);
    assert(parseOut[0] == 27_486, parseOut.to!string);

    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("0b0110_1011_0101_1110", parseOut);
    assert(frmt[0] == DLValueType.Integer && frmt[1] == DLNumberStyle.Binary && frmt[2] == 4, frmt.to!string);
    assert(parseOut[0] == 27_486, parseOut.to!string);
    //Date and time tests
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("12:34:09Z", parseOut);
    assert(parseOut[3] == 12 && parseOut[4] == 34 && parseOut[5] == 9, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("2024-12-15", parseOut);
    assert(parseOut[0] == 2024 && parseOut[1] == 12 && parseOut[2] == 15, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("12:34:09.256Z", parseOut);
    assert(parseOut[3] == 12 && parseOut[4] == 34 && parseOut[5] == 9 && parseOut[6] == 256, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("2024-12-15T12:34:09Z", parseOut);
    assert(parseOut[0] == 2024 && parseOut[1] == 12 && parseOut[2] == 15 && parseOut[3] == 12 && parseOut[4] == 34 &&
            parseOut[5] == 9, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("2024-12-15T12:34:09.256Z", parseOut);
    assert(parseOut[0] == 2024 && parseOut[1] == 12 && parseOut[2] == 15 && parseOut[3] == 12 && parseOut[4] == 34 &&
            parseOut[5] == 9 && parseOut[6] == 256, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("2024-12-15T12:34:09+01:00", parseOut);
    assert(parseOut[0] == 2024 && parseOut[1] == 12 && parseOut[2] == 15 && parseOut[3] == 12 && parseOut[4] == 34 &&
            parseOut[5] == 9 && parseOut[7] == 60, parseOut.to!string);
    parseOut = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L];
    frmt = detectAndParseNumericType("2024-12-15T12:34:09.256+01:00", parseOut);
    assert(parseOut[0] == 2024 && parseOut[1] == 12 && parseOut[2] == 15 && parseOut[3] == 12 && parseOut[4] == 34 &&
            parseOut[5] == 9 && parseOut[6] == 256 && parseOut[7] == 60, parseOut.to!string);
}
/// Removes excess whitespace in front of multiline comments
string removeExcessWhitespace(string input) 
{
    string output;
    return output;
}

string encodeUTF8Char(int c) @safe nothrow 
{
    string result;
    if (c < 0x80) 
    {
        result ~= cast(char)(c & 0x7F);
    }
    else if (c < 0x800) 
    {
        result ~= cast(char)((c>>6) & 0x1F | 0xC0);
        result ~= cast(char)(c & 0x3F | 0x80);
    } 
    else if (c < 0x01_00_00) 
    {
        result ~= cast(char)((c>>12) & 0x0F | 0xE0);
        result ~= cast(char)((c>>6) & 0x3F | 0x80);
        result ~= cast(char)(c & 0x3F | 0x80);
    } 
    else if (c < 0x11_00_00) 
    {
        result ~= cast(char)((c>>18) & 0x07 | 0xF0);
        result ~= cast(char)((c>>12) & 0x3F | 0x80);
        result ~= cast(char)((c>>6) & 0x3F | 0x80);
        result ~= cast(char)(c & 0x3F | 0x80);
    }
    /* else 
    {
        result ~= cast(char)((c>>24) & 0x03 | 0xF8);
        result ~= cast(char)((c>>18) & 0x3F | 0x80);
        result ~= cast(char)((c>>12) & 0x3F | 0x80);
        result ~= cast(char)((c>>6) & 0x3F | 0x80);
        result ~= cast(char)(c & 0x3F | 0x80);
    } */

    return result;
}
string escapeString(string input) 
{
    size_t i;
    while (i < input.length) 
    {
        if (input[i] == '\\') 
        {
            switch (input[i + 1]) 
            {
            case 't':
                input = input[0..i] ~ '\t' ~ input[i+2..$];
                break;
            case 'n':
                input = input[0..i] ~ '\n' ~ input[i+2..$];
                break;
            case 'r':
                input = input[0..i] ~ '\r' ~ input[i+2..$];
                break;
            case 'f':
                input = input[0..i] ~ '\f' ~ input[i+2..$];
                break;
            case '0':
                input = input[0..i] ~ '\0' ~ input[i+2..$];
                break;
            case 'v':
                input = input[0..i] ~ '\v' ~ input[i+2..$];
                break;
            case 'a':
                input = input[0..i] ~ '\a' ~ input[i+2..$];
                break;
            case 'b':
                input = input[0..i] ~ '\b' ~ input[i+2..$];
                break;
            case 'x':
                input = input[0..i] ~ encodeUTF8Char(input[i+2..i+4].to!int(16)) ~ input[i+4..$];
                break;
            case 'u':
                input = input[0..i] ~ encodeUTF8Char(input[i+2..i+6].to!int(16)) ~ input[i+6..$];
                break;
            case 'U':
                input = input[0..i] ~ encodeUTF8Char(input[i+2..i+10].to!int(16)) ~ input[i+10..$];
                break;
            default:
                input = input[0..i] ~ input[i+1..$];
                i++;
                break;
            }
        }
        else
        {
            i++;
        }
    }
    return input;
}
unittest {
    assert(escapeString(`\\\\\\\\`) == `\\\\`);
    assert(escapeString(`\t`) == "\t"c);
    assert(escapeString(`\x33`) == "\x33"c);
    assert(escapeString(`\u3333`) == "\u3333"c);
    assert(escapeString(`\U00013333`) == "\U00013333"c);
}
