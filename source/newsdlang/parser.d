module newsdlang.parser;

public import newsdlang.lexer;
import newsdlang.enums;

import std.conv : to;

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
}

bool isNumber(char c) @nogc nothrow
{
    return c >= '0' && c <= '9';
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