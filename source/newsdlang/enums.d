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
    Integer,
    Float,
    String,
    Date,
}