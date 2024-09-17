module newsdlang.dom;

public import newsdlang.exceptions;
public import newsdlang.enums;

@safe:

public abstract class DLElement 
{
    protected DLElement[] _allChildElements;
    protected DLElement _parent;
    protected DLElementType _type;
    protected ubyte _field1;
    protected ubyte _field2;
    protected ubyte _field3;
    public abstract string toDLString();
    public final DLElementType type() @nogc pure nothrow {
        return _type;
    }
    public DLElement[] allChildElements() 
    {
        throw new DLException("This element does not support having any child elements");
    }
    public DLElement removeFromParent() 
    {
        _parent.removeChild(this);
        _parent = null;
        return this;
    }
    public abstract DLElement removeChild(DLElement child);
}

