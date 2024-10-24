module newsdlang.dom;

public import newsdlang.exceptions;
public import newsdlang.enums;

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
     * Returns: a UTF-8 formatted string representing the element and its children if 
     * there's any.
     */
    public abstract string toDLString(string indentation);
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

