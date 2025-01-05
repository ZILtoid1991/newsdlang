module newsdlang.etc;

import std.string : tr;

package @safe:
T[] removeFromArray(T)(T[] arr, size_t index) nothrow
{
    if (index == 0) return arr[1..$];
    else if (index + 1 == arr.length) return arr[0..$];
    return arr[0..index] ~ arr[index + 1..$];
}
string insertEscapeChars(string str)
{
    string result;
    foreach (char c ; str)
    {
        switch (c)
        {
        case '\'':
            result ~= `\'`;
            break;
        case '\"':
            result ~= `\"`;
            break;
        case '\t':
            result ~= `\t`;
            break;
        case '\n':
            result ~= `\n`;
            break;
        case '\r':
            result ~= `\r`;
            break;
        case '\f':
            result ~= `\f`;
            break;
        case '\0':
            result ~= `\0`;
            break;
        case '\v':
            result ~= `\v`;
            break;
        case '\a':
            result ~= `\a`;
            break;
        case '\b':
            result ~= `\b`;
            break;
        default:
            result ~= c;
            break;
        }
    }
    return result;
}
