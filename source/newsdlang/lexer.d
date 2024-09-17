/*
* Originally by Lodovico Giaretta from newxml/experimental.xml
*/

import std.range.primitives;
import std.traits;
import std.exception : enforce, assertThrown, assertNotThrown;
public import newsdlang.exceptions;

/++
+   A lexer that takes a sliceable input.
+
+   This lexer will always return slices of the original input; thus, it does not
+   allocate memory and calls to `start` don't invalidate the outputs of previous
+   calls to `get`.
+
+   This is the fastest of all lexers, as it only performs very quick searches and
+   slicing operations. It has the downside of requiring the entire input to be loaded
+   in memory at the same time; as such, it is optimal for small file but not suitable
+   for very big ones.
+
+   Parameters:
+       T = a sliceable type used as input for this lexer
+/
struct SliceLexer(T)
{
    package T input;
    package size_t pos;
    package size_t begin;

    /++
    +   See detailed documentation in
    +   $(LINK2 ../interfaces/isLexer, `newxml.interfaces.isLexer`)
    +/
    alias CharacterType = ElementEncodingType!T;
    /// ditto
    alias InputType = T;

    //mixin UsesAllocator!Alloc;
    //mixin UsesErrorHandler!ErrorHandler;

    /// ditto
    void setSource(T input)
    {
        this.input = input;
        pos = 0;
    }

    static if (isForwardRange!T)
    {
        auto save()
        {
            SliceLexer result = this;
            result.input = input.save;
            return result;
        }
    }

    /// Returns true if position is hit the end of the input range
    auto empty() const
    {
        return pos >= input.length;
    }

    /// Sets the current position as the new mark
    void start()
    {
        begin = pos;
    }

    /// ditto
    CharacterType[] get() const
    {
        return input[begin .. pos];
    }

    char peek() const
    {
        return input[pos];
    }

    /// ditto
    void dropWhile(string s)
    {
        while (pos < input.length && indexOf(s, input[pos]) != -1)
        {
            pos++;
        }
    }

    /// ditto
    bool testAndAdvance(char c)
    {
        enforce!LexerException(!empty, "No more characters are found!");
        //handler();
        if (input[pos] == c)
        {
            pos++;
            return true;
        }
        return false;
    }

    /// ditto
    void advanceUntil(char c, bool included)
    {
        enforce!LexerException(!empty, "No more characters are found!");
        //handler();
        auto adv = indexOf(input[pos .. $], c);
        if (adv != -1)
        {
            pos += adv;
            enforce!LexerException(!empty, "No more characters are found!");
            //handler();
        }
        else
        {
            pos = input.length;
        }

        if (included)
        {
            enforce!LexerException(!empty, "No more characters are found!");
            //handler();
            pos++;
        }
    }

    /// ditto
    size_t advanceUntilAny(string s, bool included)
    {
        enforce!LexerException(!empty, "No more characters are found!");

        ptrdiff_t res;
        while ((res = indexOf(s, input[pos])) == -1)
        {
            enforce!LexerException(++pos < input.length, "No more characters are found!");
        }

        if (included)
        {
            pos++;
        }

        return res;
    }
}

unittest {
    string sdlangString = q"{
        foo "bar" 513
        bar "baz" 0x56_4F
        baz 8640.84
        fish 2024-09-17T20:55:43Z
    }";
    SliceLexer!string testLexer;
    testLexer.setSource = sdlangString;
    testLexer.dropWhile(" \n\f\t");
    testLexer.start;
    assertNotThrown!LexerException(testLexer.advanceUntil(' ', false));
    assert(testLexer.get == "foo");
    assert(testLexer.advanceUntilAny("[{\'\"", true) == 3);
    testLexer.start;
    assertNotThrown!LexerException(testLexer.advanceUntil('"', false));
    assert(testLexer.get == "bar");
}