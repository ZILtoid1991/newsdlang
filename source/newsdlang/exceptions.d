module newsdlang.exceptions;

@safe:

public class DLException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc {
        super(msg, file, line, nextInChain);
    }
}

