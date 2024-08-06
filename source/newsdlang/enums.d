module newsdlang.enums;

@safe:

enum DLElementType : ubyte {
    init,
    Tag,
    Document,
    Value,
    Attribute,
    Comment,
}

enum DLDocumentType : ubyte {
    init,       ///Undefined/unknown
    SDL,        ///Original SDLang specs
    KDL,        ///KDL specification with its enhancements and limitations
    XDL,        ///XDL specification (SDLang, but with better date and )
}

enum DLValueType : ubyte {
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

enum DLCommentType : ubyte {
    init,
    Slash,
    Hash,
    Asterisk,
    Plus,
}

enum DLStringType : ubyte {
    init,
    Quote,
    Apostrophe,
    Backtick,
    Scope,
}

enum DLTokens {
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
}