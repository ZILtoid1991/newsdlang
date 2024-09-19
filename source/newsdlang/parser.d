module newsdlang.parser;

public import newsdlang.lexer;
import newsdlang.enums;

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
    /// Parses a string token, and returns its content unescaped as a string.
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
            result = lexer.get;
            break;
        case DLStringType.Apostrophe:
            do {
                lexer.advanceUntil(CharTokens.Apostrophe, false);
            } while (lexer.peekBack != '\\');
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
    /// Parses a regular element (tag name, attribute name, numeric value, etc.).
    string parseRegularElement()
    {
        lexer.advanceUntilAny(Tokens.EndOfElement, false);
        return lexer.get;
    }
}
/// Removes excess whitespace in front of multiline comments
string removeExcessWhitespace(string input) {
    string output;
    return output;
}