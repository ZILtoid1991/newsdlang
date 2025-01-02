module newsdlang.dom;

public import newsdlang.exceptions;
public import newsdlang.enums;
public import newsdlang.var;
import core.stdc.stdlib;
import std.exception : enforce;

@safe:
public DLDocument parseDOM(string domSource)
{
    return null;
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
     */
    public abstract void toDLString(string indentation, string endOfLine, ref string output);
    ///Returns the name of the element, or null if it doesn't have any.
    public string name() const nothrow
    {
        return null;
    }
    ///Returns the namespace of the element, or null if it doesn't have any.
    public string namespace() const nothrow
    {
        return null;
    }
    ///Returns the full name of the element.
    public string fullname() const nothrow
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
    package DLElement remove(DLElement child)
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
    public override string name() const @nogc nothrow pure
    {
        return _name;
    }
    public override string namespace() const @nogc nothrow pure
    {
        return _namespace;
    }
    public bool isAnonymous() const @nogc nothrow pure
    {
        return _name.length == 0 && _namespace.length == 0;
    }
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
     * Returns: a UTF-8 formatted string representing the element and its children if
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output)
    {

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
        switch (child.type())
        {
        case DLElementType.Value:
            insertAtLastDirectChild(child);
            _values ~= cast(DLValue)child;
            _allChildElements ~= child;
            return child;
        case DLElementType.Attribute:
            insertAtLastDirectChild(child);
            _attributes ~= cast(DLAttribute)child;
            goto default;
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
    public override string name() const @nogc nothrow pure
    {
        return _name;
    }
    public override string namespace() const @nogc nothrow pure
    {
        return _namespace;
    }
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output) 
    {
        if (!_namespace.length)
        {
            output ~= _name ~ CharTokens.Equals ~_value.toDLString();
        }
        else
        {
            output ~= _namespace ~ CharTokens.Colon ~ _name ~ CharTokens.Equals ~ _value.toDLString();
        }
    }
}
/**
 * Represents a value that can be assigned to a *DL tag.
 */
public class DLValue : DLElement
{
    protected DLVar _data;
    // protected alias _valueType = _data.type;
    public this(DLVar data)
    {
        _type = DLElementType.Value;
        _data = data;
    }
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output) 
    {
        output ~= _data.toDLString();
    }
    /** 
     * Gets type of T from value if type is matching, throws ValueTypeException if types are mismatched.
     */
    public T get(T)()
    {
        return _data.get!T();
    }
    public T set(T)(T val, ubyte frmt, ubyte frmt0 = 0)
    {
        return _data = DLVar(val, 0, frmt, frmt0);
    }
}
/**
 *
 */
public class DLComment : DLElement
{
    protected string _content;
    package alias _commentType = _field1;
    package alias _commentStyle = _field2;
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public override void toDLString(string indentation, string endOfLine, ref string output) 
    {
        switch (_commentStyle) {
        case DLCommentStyle.Inline:
            switch (_commentType) 
            {
            case DLCommentType.Asterisk:
                output ~= Tokens.CommentBlockBegin ~ _content ~ Tokens.CommentBlockEnd;
                break;
            case DLCommentType.Plus:
                output ~= Tokens.CommentBlockBeginS ~ _content ~ Tokens.CommentBlockEndS;
                break;
            default:
                break;
            }
            break;
        case DLCommentStyle.LineEnd:
            switch (_commentType) 
            {
            case DLCommentType.Asterisk:
                output ~= Tokens.CommentBlockBegin ~ _content ~ Tokens.CommentBlockEnd ~ endOfLine;
                break;
            case DLCommentType.Plus:
                output ~= Tokens.CommentBlockBeginS ~ _content ~ Tokens.CommentBlockEndS ~ endOfLine;
                break;
            case DLCommentType.Hash:
                output ~= Tokens.SingleLineCommentH ~ _content ~ endOfLine;
                break;
            case DLCommentType.Slash:
                output ~= Tokens.SingleLineComment ~ _content ~ endOfLine;
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
            goto case DLCommentStyle.LineEnd;
        default:
            break;
        }
    }
}
