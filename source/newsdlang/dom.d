module newsdlang.dom;

public import newsdlang.exceptions;
public import newsdlang.enums;
public import newsdlang.var;
import newsdlang.etc;
import core.stdc.stdlib;
import std.exception : enforce;
import std.algorithm.searching : countUntil;

@safe:
/**
 * Parses the source text and builds a *DL DOM structure from it.
 * Params:
 *   domSource = The textsource for the *DL document
 * Returns: The parsed document as a DOM tree structure.
 * Throws: Some form of a ParserException or DLException if error encountered while parsing.
 */
public DLDocument readDOM(string domSource)
{
    import newsdlang.parser;
    Parser domParser;
    domParser.lexer.setSource(domSource);
    DLDocument doc = new DLDocument(null);
    DLTag[] tagStack = [doc];
    DLElement[] currTag;
    string tagName;
    void addToTopAndFlush(bool increaseScope = false)
    {
        if (!currTag && !tagName) return;
        if (currTag.length == 1 && currTag[0].type == DLElementType.Comment)
        {
            tagStack[$ - 1].add(currTag);
        }
        else
        {
            const sizediff_t namespacePos = countUntil(tagName, CharTokens.Colon);
            string name, nameSpace;
            if (namespacePos != -1)
            {
                nameSpace = tagName[0..namespacePos];
                name = tagName[namespacePos + 1..$];
            }
            else
            {
                name = tagName;
            }
            DLTag t = new DLTag(name, nameSpace, currTag);
            tagStack[$ - 1].add(t);
            if (increaseScope)
            {
                tagStack ~= t;
            }
        }
        tagName = null;
        currTag.length = 0;
    }
    while (!domParser.consumeWhitespace())
    {
        DLStringType stringTy;
        DLCommentType cmntTy;
        if (domParser.isNumericValue())
        {
            currTag ~= new DLValue(domParser.parseVariable());
        }
        else if ((stringTy = domParser.isString()) != DLStringType.init)
        {
            currTag ~= new DLValue(domParser.parseString(stringTy));
        }
        else if ((cmntTy = domParser.isComment()) != DLCommentType.init)
        {
            string cmnt = domParser.parseComment(cmntTy);
            switch (cmntTy)
            {
            case DLCommentType.Asterisk, DLCommentType.Plus:
                currTag ~= new DLComment(cmnt[2..$-2], cmntTy,
                        currTag || tagName ? DLCommentStyle.Inline : DLCommentStyle.Block);
                break;
            case DLCommentType.Hash:
                currTag ~= new DLComment(cmnt[1..$], cmntTy,
                        currTag.length ? DLCommentStyle.LineEnd : DLCommentStyle.Block);

                break;
            case DLCommentType.Slash:
                currTag ~= new DLComment(cmnt[2..$], cmntTy,
                        currTag.length ? DLCommentStyle.LineEnd : DLCommentStyle.Block);
                break;
            default:
                break;
            }
        }
        else if (domParser.isScopeBegin)
        {
            addToTopAndFlush(true);
            domParser.consumeAnyWhitespace();
        }
        else if (domParser.isScopeEnd)
        {
            enforce!ParserException(domParser.scopeLevel >= 0, "Malformed scope encountered!");
            if (currTag.length)
            {
                addToTopAndFlush();
            }
            tagStack.length -= 1;
        }
        else if (domParser.isClosingOfTag)
        {
            addToTopAndFlush();
            domParser.consumeAnyWhitespace();
        }
        else
        {
            string temp = domParser.parseRegularElement();
            if (domParser.isAttribute)
            {
                DLVar attrVal;
                if ((stringTy = domParser.isString()) != DLStringType.init)
                {
                    attrVal = domParser.parseString(stringTy);
                }
                else
                {
                    attrVal = domParser.parseVariable();
                }
                const namespacePos = countUntil(temp, CharTokens.Colon);
                string name, nameSpace;
                if (namespacePos != -1)
                {
                    nameSpace = temp[0..namespacePos];
                    name = temp[namespacePos + 1..$];
                }
                else
                {
                    name = temp;
                }
                currTag ~= new DLAttribute(name, nameSpace, attrVal);
            }
            else if (isReservedName(temp))
            {
                currTag ~= new DLValue(domParser.parseVariable());
            }
            else
            {
                // if (tagName.length)
                // {
                //     throw new ParserException("Malformed *DL element or attribute!");
                // }
                tagName = temp;
            }
        }
    }
    return doc;
}
/**
 * The base building block of any *DL document. Implements multi-level and ambiguous 
 * type containment where it's applicable.
 * 
 */
public abstract class DLElement 
{
    package DLElement _parent;                    ///Contains the reference to the parent element.
    package DLElementType _type;
    package ubyte _field1;
    package ubyte _field2;
    package ubyte _field3;
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     *   endOfLine = endOfLine character(s).
     *   output = the outputted string.
     *   indentLevel = current indentation level.
     */
    public abstract void toDLString(string indentation, string endOfLine, ref string output, int indentLevel);
    ///Returns the name of the element, or null if it doesn't have any.
    public string name() const nothrow pure
    {
        return null;
    }
    ///Returns the namespace of the element, or null if it doesn't have any.
    public string namespace() const nothrow pure
    {
        return null;
    }
    ///Returns the full name of the element.
    public string fullname() const nothrow pure
    {
        string ns = namespace();
        if (ns.length)
        {
            return ns ~ ":" ~ name();
        }
        return name();
    }
    /**
     * Returns the type of this element.
     */
    public final DLElementType type() const @nogc pure nothrow {
        return _type;
    }
    /**
     * Returns all child elements of the tag. Throws if child elements not supported.
     */
    public DLElement[] allChildElements() 
    {
        throw new DLException("This element does not support having any child elements");
    }
    /**
     * Removes this element from its parent, then returns it.
     */
    public DLElement removeFromParent() 
    {
        _parent.remove(this);
        _parent = null;
        return this;
    }
    /**
     * Removes the supplied element from this, and returns it if could be removed. Returns 
     * null if it wasn't found among its children. Throws if child elements not supported.
     */
    public DLElement remove(DLElement child)
    {
        throw new DLException("This element does not support having any child elements");
    }
    /*public void remove(ElementRange)(ElementRange children)
    {
        foreach (child ; children)
        {
            remove(child);
        }
    }*/
    /**
     * Adds the supplied element to this, returns the added element on success, returns
     * null otherwise. Throws if child elements not supported.
     */
    public DLElement add(DLElement child)
    {
        throw new DLException("This element does not support having any child elements");
    }
    /**
     * Adds a range of *DL elements. Throws if child elements not supported.
     */
    public void add(DLElement[] children)
    {
        foreach (child ; children)
        {
            add(child);
        }
    }
}
/**
 * Implements access for namespaces.
 */
public struct NamespaceAccess
{
    package string _namespace;
    DLElement[] elements;
    package this(string _namespace, DLElement[] elements) 
    {
        this._namespace = _namespace;
        this.elements = elements;
    }
    /**
     * Returns all elements in this namespace.
     */
    DLElement[] all() 
    {
        return elements;
    }
    /**
     * Returns the tags of this namespace.
     */
    DLTag[] tags() 
    {
        DLTag[] result;
        foreach (key ; elements) 
        {
            if (key.type == DLElementType.Tag)
            {
                result ~= cast(DLTag)key;
            }
        }
        return result;
    }
    /**
     * Returns the attributes of this namespace.
     */
    DLAttribute[] attributes()
    {
        DLAttribute[] result;
        foreach (key ; elements)
        {
            if (key.type == DLElementType.Attribute)
            {
                result ~= cast(DLAttribute)key;
            }
        }
        return result;
    }
}
/**
 * Represents a tag within a *DL document.
 */
public class DLTag : DLElement 
{
    protected DLElement[] _allChildElements;        ///Contains all child elements regardless of namespace or type.
    protected string _name;
    protected string _namespace;
    protected DLValue[] _values;
    protected DLAttribute[] _attributes;
    protected DLTag[] _tags;
    protected NamespaceAccess[] _namespaces;
    public this(string _name, string _namespace, DLElement[] children)
    {
        _type = DLElementType.Tag;
        this._name = _name;
        this._namespace = _namespace;
        _namespaces ~= NamespaceAccess(null, null);
        add(children);
    }
    /// Gives access to all of the elements of this tag, including comments.
    public DLElement[] all() @nogc nothrow pure
    {
        return _allChildElements;
    }
    /// Gives access to the values of this tag.
    public DLValue[] values() @nogc nothrow pure
    {
        return _values;
    }
    /// Gives access to the attributes of this tag, in the form of an array.
    public DLAttribute[] attributes() @nogc nothrow pure
    {
        return _attributes;
    }
    /// Gives access to the child tags of this tag, in the form of an array.
    public DLTag[] tags() @nogc nothrow pure
    {
        return _tags;
    }
    /// Looks for the attribute specified by `fullname` and returns it if found, null if not.
    public DLAttribute searchAttribute(string fullname) nothrow pure
    {
        foreach (DLAttribute a ; _attributes)
        {
            if (a.fullname == fullname) return a;
        }
        return null;
    }
    /// Searches for the given attribute by `fullname`, returns its value, or returns defaultVal if not found.
    public T searchAttribute(T)(string fullname, T defaultVal)
    {
        DLAttribute a = searchAttribute(fullname);
        if (a) return a.get!T;
        return defaultVal;
    }
    /// Searches for the tag by `fullname`, returns the first one if found, or returns null if not.
    public DLTag searchTag(string fullname) nothrow pure
    {
        foreach (DLTag t ; _tags)
        {
            if (t.fullname == fullname) return t;
        }
        return null;
    }
    /**
     * Searches for the tag specified by the path.
     * Params:
     *   path = The path to the tag. Each entry is a name for a given tag.
     * Returns: The first tag by the name if found, null otherwise.
     */
    public DLTag searchTag(string[] path) nothrow pure
    {
        DLTag t = searchTag(path[0]);
        if (t !is null)
        {
            if (path.length >= 1)
            {
                return t.searchTag(path[1..$]);
            }
            return t;
        }
        return null;
    }
    /**
     * Searches for the tag specified by the path. Throws an exception if not found
     * Params:
     *   path = The path to the tag. Each entry is a name for a given tag.
     * Returns: The first tag by the name if found.
     * Throws: DLDOMException if tag is not found.
     */
    public DLTag searchTagX(string[] path) pure
    {
        DLTag t = searchTag(path[0]);
        if (t !is null)
        {
            if (path.length >= 1)
            {
                return t.searchTag(path[1..$]);
            }
            return t;
        }
        throw new DLDOMException("Tag not found!");
    }
    /// Returns the name of the element, or null if it doesn't have any.
    public override string name() const @nogc nothrow pure
    {
        return _name;
    }
    /// Returns the namespace of the element, or null if it doesn't have any.
    public override string namespace() const @nogc nothrow pure
    {
        return _namespace;
    }
    /// Return true if tag is anonymous.
    public bool isAnonymous() const @nogc nothrow pure
    {
        return _name.length == 0 && _namespace.length == 0;
    }
    /// Gets the access to the given namespace for reading. Returns an empty namespace structure if it
    public NamespaceAccess accessNamespace(string ns) nothrow
    {
        foreach (NamespaceAccess key ; _namespaces) 
        {
            if (key._namespace == ns)
            {
                return key;
            }
        }
        return NamespaceAccess.init;
    }
    /**
     * Converts element into its *DL representation with its internal and supplied
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     *   endOfLine = endOfLine character(s).
     *   output = the outputted string.
     *   indentLevel = current indentation level.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output, int indentLevel)
    {
        for (int i ; i < indentLevel ; i++)
        {
            output ~= indentation;
        }
        if (!_namespace)
        {
            output ~= _name;
        }
        else
        {
            output ~= _namespace ~ CharTokens.Colon ~ _name;
        }
        sizediff_t firstTag = countUntilFirstChildTag();

        size_t pos;
        for ( ; pos < _allChildElements.length ; pos++)
        {
            if (_allChildElements[pos]._type == DLElementType.Tag) break;
            _allChildElements[pos].toDLString(indentation, endOfLine, output, indentLevel);
        }
        if (pos < _allChildElements.length)
        {
            output ~= ' ';
            output ~= CharTokens.ScopeBegin;
            output ~= endOfLine;
            for ( ; pos < _allChildElements.length ; pos++)
            {
                _allChildElements[pos].toDLString(indentation, endOfLine, output, indentLevel + 1);
            }
            output ~= CharTokens.ScopeEnd;
        }
        output ~= endOfLine;
    }
    /**
     * Adds the supplied element to this, returns the added element on success, returns
     * null otherwise. Throws if child elements not supported.
     */
    public override DLElement add(DLElement child)
    {
        if (child._parent)
        {
            child.removeFromParent();
        }
        child._parent = this;
        switch (child.type())
        {
        case DLElementType.Value:
            insertAtLastDirectChild(child);
            _values ~= cast(DLValue)child;
            //_allChildElements ~= child;
            return child;
        case DLElementType.Attribute:
            insertAtLastDirectChild(child);
            //_attributes ~= cast(DLAttribute)child;
            break;
        case DLElementType.Comment:
            DLComment cmnt = cast(DLComment)child;
            if (cmnt._commentStyle == DLCommentStyle.Inline || (cmnt._commentStyle == DLCommentStyle.LineEnd &&
                !hasLineEndingComment))
            {
                insertAtLastDirectChild(child);
            }
            else
            {
                _allChildElements ~= child;
            }
            return child;
        case DLElementType.Tag:
            _tags ~= cast(DLTag)child;
            goto default;
        default:
            _allChildElements ~= child;
            break;
        }

        foreach (ref NamespaceAccess na ; _namespaces)
        {
            if (na._namespace == child.namespace)
            {
                na.elements ~= child;
                return child;
            }
        }
        _namespaces ~= NamespaceAccess(child.namespace, [child]);

        return child;
    }
    /**
     * Adds a range of *DL elements. Throws if child elements not supported.
     */
    public override void add(DLElement[] children)
    {
        super.add(children);
    }
    /**
     * Removes the supplied element from this, and returns it if could be removed. Returns
     * null if it wasn't found among its children. Throws if child elements not supported.
     */
    public override DLElement remove(DLElement child)
    {
        if (child._parent !is this)
        {
            return null;
        }
        foreach (size_t i, DLElement elem; _allChildElements)
        {
            if (elem is child)
            {
                child._parent = null;
                _allChildElements = removeFromArray(_allChildElements, i);
                switch (child._type)
                {
                case DLElementType.Value:
                    foreach (size_t j, DLValue val; _values)
                    {
                        if (val is child)
                        {
                            _values = removeFromArray(_values, j);
                            break;
                        }
                    }
                    break;
                case DLElementType.Attribute:
                    foreach (size_t j, DLAttribute val; _attributes)
                    {
                        if (val is child)
                        {
                            _attributes = removeFromArray(_attributes, j);
                            break;
                        }
                    }
                    break;
                case DLElementType.Tag:
                    foreach (size_t j, DLTag val; _tags)
                    {
                        if (val is child)
                        {
                            _tags = removeFromArray(_tags, j);
                            break;
                        }
                    }
                    break;
                default:
                    break;
                }
                if (child._type != DLElementType.Comment)
                {
                    foreach (ref NamespaceAccess na; _namespaces)
                    {
                        if (na._namespace == child.namespace)
                        {
                            foreach (size_t j, DLElement elem0; na.elements)
                            {
                                if (elem0 is child)
                                {
                                    na.elements = removeFromArray(na.elements, j);
                                    return child;
                                }
                            }
                        }
                    }
                }
                return child;
            }
        }
        return null;
    }
    /// Inserts element at the position of the last direct child (values, attributes,
    /// inline comments).
    package final void insertAtLastDirectChild(DLElement child) nothrow
    {
        const sizediff_t pos = countUntilFirstChildTag();
        if (pos == -1)
        {
            _allChildElements ~= child;
        }
        else
        {
            _allChildElements = _allChildElements[0..pos] ~ child ~ _allChildElements[pos..$];
        }
    }
    ///Returns true if tag already has a line ending comment.
    package final bool hasLineEndingComment() @nogc nothrow pure
    {
        foreach (size_t i , DLElement elem ; _allChildElements)
        {
            if (elem.type() == DLElementType.Comment && elem._field2 == DLCommentStyle.LineEnd)
            {
                return true;
            }
            else if (elem.type() == DLElementType.Tag)
            {
                return false;
            }
        }
        return false;
    }
    ///Counts until the first child tag then returns its position.
    ///Returns -1 if it doesn't have any child tags.
    package final sizediff_t countUntilFirstChildTag() @nogc nothrow pure
    {
        foreach (size_t i , DLElement elem ; _allChildElements)
        {
            if (elem.type() == DLElementType.Tag || (elem.type() == DLElementType.Comment &&
                elem._field2 == DLCommentStyle.Block))
            {
                return i;
            }
        }
        return -1;
    }
}
/**
 * Represents a *DL document.
 */
public class DLDocument : DLTag
{
    public this(DLElement[] children)
    {
        super(null, null, children);
        _type = DLElementType.Document;
    }
    ///Returns the name of the element, or null if it doesn't have any.
    public override string name() const nothrow
    {
        return null;
    }
    ///Returns the namespace of the element, or null if it doesn't have any.
    public override string namespace() const nothrow
    {
        return null;
    }
    /**
     * Creates a *DL document that can be used for
     * Params:
     *   indentation = The character string used for the indentation, default if four spaces.
     *   endOfLine = Line ending character string used for line ending, default is carriage return-newline
     * Returns: The textual representation of the *DL document as a string.
     */
    public string writeDOM(string indentation = "    ", string endOfLine = "\r\n")
    {
        string result;
        foreach (DLElement elem ; _allChildElements)
        {
            elem.toDLString(indentation, endOfLine, result, 0);
        }
        return result;
    }
}
/**
 * Represents an attribute within a *DL document, or a name and value pair that can be
 * assigned to a tag.
 */
public class DLAttribute : DLElement
{
    protected string _name;
    protected string _namespace;
    protected DLVar _value;
    public this (string _name, string _namespace, DLVar _value)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = _value;
    }
    public this(string _name, string _namespace, long data, DLNumberStyle style = DLNumberStyle.Decimal, ubyte numberingFrmt = 0)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, DLValueType.Integer, style, numberingFrmt, numberingFrmt);
    }
    public this(string _name, string _namespace, double data, DLNumberStyle style = DLNumberStyle.Decimal, ubyte numberingFrmt = 0)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, DLValueType.Float, style, numberingFrmt, numberingFrmt);
    }
    public this(string _name, string _namespace, string data, DLStringType style = DLStringType.Quote)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, DLValueType.String, style);
    }
    public this(string _name, string _namespace, bool data, DLBooleanStyle style = DLBooleanStyle.TrueFalse)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, DLValueType.Boolean, style);
    }
    public this(string _name, string _namespace, ubyte[] data)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, DLValueType.Binary, 0);
    }
    public this(string _name, string _namespace, DLDateTime data)
    {
        this._type = DLElementType.Attribute;
        this._namespace = _namespace;
        this._name = _name;
        this._value = DLVar(data, 0, 0);
    }
    ///Returns the name of the element, or null if it doesn't have any.
    public override string name() const @nogc nothrow pure
    {
        return _name;
    }
    ///Returns the namespace of the element, or null if it doesn't have any.
    public override string namespace() const @nogc nothrow pure
    {
        return _namespace;
    }
    /**
     * Gets type of T from value if type is matching, throws ValueTypeException if types are mismatched.
     */
    public T get(T)()
    {
        return _value.get!T();
    }
    /// Returns the underlying DLVar structure
    public DLVar get() @nogc nothrow pure
    {
        return _value;
    }
    /**
     * Sets the value of this element.
     * Params:
     *   val = The value to be set for.
     *   frmt = First formatting field.
     *   frmt0 = Second formatting field.
     * Returns: The value that was set.
     */
    public T set(T)(T val, ubyte frmt, ubyte frmt0 = 0)
    {
        _value = DLVar(val, 0, frmt, frmt0);
        return val;
    }
    /// Sets the value of this element from a DLVar structure
    public DLVar set(DLVar val)
    {
        return _value = val;
    }
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output, int indentLevel)
    {
        output ~= ' ';
        if (!_namespace)
        {
            output ~= _name ~ CharTokens.Equals ~_value.toDLString();
        }
        else
        {
            output ~= _namespace ~ CharTokens.Colon ~ _name ~ CharTokens.Equals ~ _value.toDLString();
        }
    }
    /// Returns the type held by the attribute
    public DLValueType type() const @nogc nothrow pure
    {
        return _value.type;
    }
}
/**
 * Represents a value that can be assigned to a *DL tag.
 */
public class DLValue : DLElement
{
    protected DLVar _data;

    public this(DLVar data)
    {
        _type = DLElementType.Value;
        _data = data;
    }
    public this(long data, DLNumberStyle style = DLNumberStyle.Decimal, ubyte numberingFrmt = 0)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, DLValueType.Integer, style, numberingFrmt, numberingFrmt);
    }
    public this(double data, DLNumberStyle style = DLNumberStyle.Decimal, ubyte numberingFrmt = 0)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, DLValueType.Float, style, numberingFrmt, numberingFrmt);
    }
    public this(string data, DLStringType style = DLStringType.Quote)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, DLValueType.String, style);
    }
    public this(bool data, DLBooleanStyle style = DLBooleanStyle.TrueFalse)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, DLValueType.Boolean, style);
    }
    public this(ubyte[] data)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, DLValueType.Binary, 0);
    }
    public this(DLDateTime data)
    {
        _type = DLElementType.Value;
        _data = DLVar(data, 0, 0);
    }
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output, int indentLevel)
    {
        output ~= ' ' ~ _data.toDLString();
    }
    public override string toString()
    {
        return _data.toDLString();
    }
    public override bool opEquals(Object rhs)
    {
        DLValue rhs1 = cast(DLValue)rhs;
        if (rhs1 !is null) {
            return _data == rhs1._data;
        }
        return false;
    }
    /** 
     * Gets type of T from value if type is matching, throws ValueTypeException if types are mismatched.
     */
    public T get(T)()
    {
        return _data.get!T();
    }
    /// Returns the underlying DLVar structure
    public DLVar get()
    {
        return _data;
    }
    /**
     * Sets the value of this element.
     * Params:
     *   val = The value to be set for.
     *   frmt = First formatting field.
     *   frmt0 = Second formatting field.
     * Returns: The value that was set.
     */
    public T set(T)(T val, ubyte frmt, ubyte frmt0 = 0)
    {
        _data = DLVar(val, 0, frmt, frmt0);
        return val;
    }
    /// Sets the value of this element from a DLVar structure
    public DLVar set(DLVar val)
    {
        return _data = val;
    }
    /// Returns the type held by the attribute
    public DLValueType type() const @nogc nothrow pure
    {
        return _data.type;
    }
}
/**
 * Represents a comment
 */
public class DLComment : DLElement
{
    public string content;      /// Contains the content of this element
    package alias _commentType = _field1;
    package alias _commentStyle = _field2;
    public this(string content, DLCommentType type = DLCommentType.Asterisk,
            DLCommentStyle style = DLCommentStyle.Block) @nogc nothrow pure
    {
        _type = DLElementType.Comment;
        this.content = content;
        _commentType = type;
        _commentStyle = style;
    }
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output, int indentLevel)
    {
        switch (_commentStyle) {
        case DLCommentStyle.Inline:
            output ~= ' ';
            switch (_commentType) 
            {
            case DLCommentType.Asterisk:
                output ~= Tokens.CommentBlockBegin ~ content ~ Tokens.CommentBlockEnd;
                break;
            case DLCommentType.Plus:
                output ~= Tokens.CommentBlockBeginS ~ content ~ Tokens.CommentBlockEndS;
                break;
            default:
                break;
            }
            break;
        case DLCommentStyle.LineEnd:
            output ~= ' ';
            switch (_commentType) 
            {
            case DLCommentType.Asterisk:
                output ~= Tokens.CommentBlockBegin ~ content ~ Tokens.CommentBlockEnd ~ endOfLine;
                break;
            case DLCommentType.Plus:
                output ~= Tokens.CommentBlockBeginS ~ content ~ Tokens.CommentBlockEndS ~ endOfLine;
                break;
            case DLCommentType.Hash:
                output ~= Tokens.SingleLineCommentH ~ content ~ endOfLine;
                break;
            case DLCommentType.Slash:
                output ~= Tokens.SingleLineComment ~ content ~ endOfLine;
                break;
            default:
                break;
            }
            break;
        case DLCommentStyle.Block:
            if (output.length >= endOfLine.length) 
            {
                if (output[$-endOfLine.length..$] != endOfLine) 
                {
                    output ~= endOfLine;
                }
            }
            for (int i ; i < indentLevel ; i++)
            {
                output ~= indentation;
            }
            goto case DLCommentStyle.LineEnd;
        default:
            break;
        }
    }
}

unittest
{
    import std.stdio;
    DLDocument doc = new DLDocument([
        (new DLTag("foo", null, [new DLValue("bar"), new DLValue(513)])),
        (new DLTag("bar", null,
            [
            new DLValue("baz", DLStringType.Backtick), new DLValue(0x56_4F, DLNumberStyle.Hexadecimal, 2),
            new DLAttribute("attr", null, DLVar(3, 0 ,0)), new DLTag("baz", null, [new DLValue(8640.84)])
            ]))
    ]);
    writeln(doc.writeDOM());
}

unittest
{
    import std.stdio;
    string sdlangString = q"{
        foo "bar" 513
        bar `baz` 0x56_4F attr=3 {
            baz 8640.84             //Comment for testing purposes
        }
        someTag "\"string\" with multiple spaces" /* Inlined comment */ 8419
    }";
    DLDocument doc = readDOM(sdlangString);
    assert(!doc.fullname);
    assert(doc.tags()[0].fullname == "foo", doc.tags()[0].fullname);
    assert(doc.tags()[0].values()[0].get!string == "bar");
    assert(doc.tags()[0].values()[1].get!long == 513);

    writeln(doc.writeDOM());
}


unittest
{
    string sdlangString = q"{
        magyar "árvíztűrő tükörfúrógép ÁRVÍZTŰRŐ TÜKÖRFÚRÓGÉP"
        日本語 "こにちわ世界"
        delimiterString q"{
            import std.stdio;

            void main() {
                writeln("Helló világ!");
            }
        }"
    }";
    DLDocument doc = readDOM(sdlangString);
}


unittest
{
    string sdlangString = q"{
        SDLangDouble 0.384D
        Numbertest00 0.0048D
        Numbertest01 0.00000048D
        Numbertest02 0.000000000048D
        Numbertest03 0.000000000000000000048D
        Numbertest04 0.48000000000000000000048D
        Numbertest08 0.3030000030994415283203125D
    }";
    DLDocument doc = readDOM(sdlangString);
    assert(doc.searchTag("SDLangDouble").values[0].get!double == 0.384);
    assert(doc.searchTag("Numbertest00").values[0].get!double == 0.0048);
    assert(doc.searchTag("Numbertest01").values[0].get!double == 0.00000048);
    assert(doc.searchTag("Numbertest02").values[0].get!double == 0.000000000048);
    assert(doc.searchTag("Numbertest03").values[0].get!double == 0.000000000000000000048);
    assert(doc.searchTag("Numbertest04").values[0].get!double == 0.48000000000000000000048,
            doc.searchTag("Numbertest04").values[0].get().toDLString());
    assert(doc.searchTag("Numbertest08").values[0].get!double == 0.3030000030994415283203125,
            doc.searchTag("Numbertest08").values[0].get().toDLString());
}
