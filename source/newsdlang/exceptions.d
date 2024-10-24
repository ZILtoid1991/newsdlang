module newsdlang.exceptions;

@safe:

public class DLException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc {
        super(msg, file, line, nextInChain);
    }
}

/**
 * Thrown on lexing errors.
 */
public class LexerException : DLException
{
    @nogc pure nothrow this(string msg, string file = __FILE__,
            size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }

    @nogc pure nothrow this(string msg, Throwable nextInChain,
            string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}

class ValueTypeException : DLException {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc 
    {
        super(msg, file, line, nextInChain);
    }
}
