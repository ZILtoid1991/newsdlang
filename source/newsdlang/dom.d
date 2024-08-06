module newsdlang.dom;

import newsdlang.exceptions;

@safe:

public abstract class DLElement {
    public DLElement[] _allChildElements;
    public abstract string toDLString();
    public DLElement[] allChildElements() {
        throw new DLException("This element does not support having any child elements");
    }
}