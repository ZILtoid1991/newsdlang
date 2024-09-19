module newsdlang.lexer;

/*
* Originally by Lodovico Giaretta from newxml/experimental.xml
*/

import std.string : indexOf;
import std.range.primitives;
import std.traits;
import std.exception : enforce, assertThrown, assertNotThrown;
public import newsdlang.exceptions;

@safe:
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
struct Lexer
{
    package string input;
    package size_t pos;
    package size_t begin;

    this(string input)
    {
        this.input = input;
    }

    /// Sets the source of the lexer
    void setSource(string input)
    {
        this.input = input;
        pos = 0;
    }

    auto save()
    {
        Lexer result = this;
        result.input = input.save;
        return result;
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

    /// Returns the current slice
    string get() const
    {
        return input[begin .. pos];
    }
    /// Peeks the current character.
    char peek() const
    {
        return input[pos];
    }
    /// Peeks the current position for a string of size indicated by `am`.
    /// Returns the string, or null if string would be out of bounds.
    string peek(size_t am) const
    {
        if (pos + am > input.length) return null;
        return input[pos..pos + am];
    }
    /// Peeks the previous character.
    char peekBack() const
    {
        return input[pos - 1];
    }
    /// Steps one forward.
    size_t step()
    {
        if (!empty) pos++;
        return pos;
    }

    /// Move forward until any of the characters are being encountered
    void dropWhile(string s)
    {
        while (pos < input.length && indexOf(s, input[pos]) != -1)
        {
            pos++;
        }
    }

    /// Moves forward one if current char is equals with `c` and returns true, otherwise returns false
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

    /** 
     * Advances until character character `c` is hit. If `included`, then the character will be stepped over.
     */
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
    /** 
     * Advances until character sequence `s` is hit. If `included`, then the sequence will be stepped over.
     */
    void advanceUntil(string s, bool included)
    {
        enforce!LexerException(!empty, "No more characters are found!");
        //handler();
        for (sizediff_t i = pos ; i + s.length < input.length ; i++) 
            {
            if (s == input[i..i + s.length]) 
            {
                pos = i;
                if (included)
                {
                    enforce!LexerException(!empty, "No more characters are found!");
                    pos += s.length;
                }
                return;
            }
        }
        pos = input.length;
    }
    /// Advance forward if any of the characters in `s` is encountered.
    /// Steps forward an extra if `included` is true.
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
    Lexer testLexer;
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