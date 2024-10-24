module newsdlang.enums;

@safe:

enum DLElementType : ubyte 
{
    init,
    Tag,
    Document,
    Value,
    Attribute,
    Comment,
}

enum DLDocumentType : ubyte 
{
    init,       ///Undefined/unknown
    SDL,        ///Original SDLang specs
    KDL,        ///KDL specification with its enhancements and limitations
    XDL,        ///XDL specification (SDLang, but with better specifications)
}

enum DLValueType : ubyte 
{
    init,
    Null,
    Integer,    ///Generic integer type
    Float,      ///Generic floating-point type
    Boolean,
    String,
    Date,       ///SDLang or ISO (XDL) date
    DateTime,   ///SDLang or ISO (XDL) date and time
    Time,       ///SDLang or ISO (XDL) time
    Binary,     ///Base64 encoded data
    SDLInt,
    SDLUint,
    SDLLong,
    SDLUlong,
    SDLFloat,
    SDLDouble,
}

enum DLNumberStyle : ubyte 
{
    init,
    Hexadecimal,
    Decimal,
    Octal,
    Binary,
}

enum DLCommentType : ubyte 
{
    init,
    Slash,
    Hash,
    Asterisk,
    Plus,
}

enum DLDateTimeType : ubyte 
{
    init,
    Date,               ///YYYY-MM-DD
    Time,               ///HH:mm:SSZ
    DateTime,           ///YYYY-MM-DDTHH:mm:SSZ
    DateTimeZone,       ///YYYY-MM-DDTHH:mm:SSZ-UTC
    TimeMS,             ///HH:mm:SS.sssZ
    DateTimeMS,         ///YYYY-MM-DDTHH:mm:SS.sssZ
    DateTimeMSZone,     ///YYYY-MM-DDTHH:mm:SS.sssZ-UTC
    Duration,           ///HH:mm:SS
    DurationMS,         ///HH:mm:SS.sss
}

enum DLStringType : ubyte 
{
    init,
    Quote,
    Apostrophe,
    Backtick,
    Scope,
}

package enum Tokens 
{
    Base64Begin = "[",
    Base64End = "]",
    ScopeBegin = "{",
    ScopeEnd = "}",
    SingleLineComment = "//",
    SingleLineCommentH = "#",
    CommentBlockBegin = "/*",
    CommentBlockEnd = "*/",
    CommentBlockBeginS = "/+",
    CommentBlockEndS = "+/",
    EndOfTag = ";\n\r",
    EndOfElement = " ;\t\n\r",
    EndOfLine = "\n\r",
    WhiteSpaces = " \t",
    BoolTrue = "true",
    BoolFalse = "false",
    BoolYes = "yes",
    BoolNo = "no",
    Nulltype = "null",
    StringScopeBegin = `q{"`,
    StringScopeEnd = `"}`,
}

package enum CharTokens 
{
    Semicolon = ';',
    Colon = ':',
    Apostrophe = '\'',
    Backtick = '`',
    Quote = '"',
    Equals = '=',
    NoTimeZoneIdentifier = 'Z',
    DateTimeSeparator = 'T',
    Minus = '-',
    Plus = '+',
    HexIdentifier = 'x',
    OctIdentifier = 'o',
    BinIdentifier = 'b',
    Underscore = '_',
}