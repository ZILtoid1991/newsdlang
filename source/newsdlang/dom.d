module newsdlang.dom;

public import newsdlang.exceptions;
public import newsdlang.enums;
import core.stdc.stdlib;
import std.exception : enforce;

@safe:
/**
 * The base building block of any *DL document. Implements multi-level and ambiguous 
 * type containment where it's applicable.
 * 
 */
public abstract class DLElement 
{
    protected DLElement[] _allChildElements;        ///Contains all child elements regardless of namespace or type.
    protected DLElement _parent;                    ///Contains the reference to the parent element.
    protected DLElementType _type;
    protected ubyte _field1;
    protected ubyte _field2;
    protected ubyte _field3;
    /**
     * Converts element into its *DL representation with its internal and supplied 
     * formatting parameters.
     * Params:
     *   indentation = the indentation characters if applicable.
     *   endOfLine = endOfLine character(s).
     *   output = the outputted string.
     */
    public abstract void toDLString(string indentation, string endOfLine, ref string output);
    public string name() const nothrow
    {
        return null;
    }
    public string namespace() const nothrow
    {
        return null;
    }
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
    public final DLElementType type() @nogc pure nothrow {
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
    public void add(ElementRange)(ElementRange children)
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
 * 
 */
public class DLTag : DLElement 
{
    protected string _name;
    protected string _namespace;
    protected DLValue[] _values;
    protected DLAttribute _attributes;
    protected NamespaceAccess[] _namespaces;
    public NamespaceAccess namespace(string ns) nothrow
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
    /*public DLAttribute attribute(string attr)
    {
        
    }*/
}
/**
 *
 */
public class DLAttribute : DLElement
{
    protected string _name;
    protected string _namespace;
    protected DLValue _value;
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
}
/**
 *
 */
public class DLValue : DLElement
{
    protected ubyte[] _data;
    protected alias _valueType = _field1;
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
     * Gets type of T from value if type is matching, throws ValueTypeException if types are mismatched.
     */
    public T get(T)() @trusted
    {
        U _derefFunc(U)() @system
        {
            return *cast(U*)_data.ptr;
        }
        /* U _safeCast(U)() @system
        {
            return cast(U)_data.ptr;
        } */
        static if (is(T == long) || is(T == int) || is(T == short) || is(T == byte)) 
        {
            enforce!ValueTypeException
                    (_valueType == DLValueType.Integer || _valueType == DLValueType.SDLLong || 
                    _valueType == DLValueType.SDLInt, "Value type mismatch!");
            long result = _derefFunc!long;
            return cast(T)result;
        }
        else static if(is(T == ulong) || is(T == uint) || is(T == ushort) || is(T == ubyte))
        {
            enforce!ValueTypeException
                    (_valueType == DLValueType.Integer || _valueType == DLValueType.SDLULong || 
                    _valueType == DLValueType.SDLUInt, "Value type mismatch!");
            ulong result = _derefFunc!ulong;
            return cast(T)result;
        }
        else static if(is(T == double))
        {
            enforce!ValueTypeException(_valueType == DLValueType.Float || _valueType == DLValueType.SDLDouble, 
                    "Value type mismatch!");
            double result = _derefFunc!double;
            return result;
        }
        else static if(is(T == float))
        {
            enforce!ValueTypeException(_valueType == DLValueType.SDLFloat, "Value type mismatch!");
            float result = _derefFunc!float;
            return result;
        }
        else static if(is(T == ubyte[]))
        {
            enforce!ValueTypeException(_valueType == DLValueType.Binary, "Value type mismatch!");
            return _data;
        }
        else static if(is(T == string))
        {
            enforce!ValueTypeException(_valueType == DLValueType.String, "Value type mismatch!");
            return _data;
        }
        else static assert(0, "Unsupported type");
    }
    public T set(T)(T val) @trusted
    {
        
    }
}
/**
 *
 */
public class DLComment : DLElement
{
    protected string _content;
    protected alias _commentType = _field1;
    protected alias _commentStyle = _field2;
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