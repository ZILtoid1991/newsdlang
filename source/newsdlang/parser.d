module newsdlang.parser;

public import newsdlang.lexer;
import newsdlang.enums;

@safe:
struct Parser
{
    package Lexer lexer;

    void consumeWhitespace()
    {
        lexer.dropWhile(Tokens.WhiteSpaces);
    }

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

    string parseString(DLStringType style)
    {
        string result;
        switch (style) 
        {
        case DLStringType.Quote:
            lexer.advanceUntil(CharTokens.Quote, false);
            result = lexer.get;
            break;
        case DLStringType.Apostrophe:
            lexer.advanceUntil(CharTokens.Apostrophe, false);
            result = lexer.get;
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

    string parseRegularElement()
    {
        lexer.advanceUntilAny(Tokens.EndOfElement, false);
        return lexer.get;
    }
}