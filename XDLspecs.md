XDL (Extendible Declarative Language) is a declarative language built upon the SDLang (Simple Declarative Language) specification.

# Main differences

* Single integer type and single floating-point type only. Distinction is done via the decimal point, API provides automatic conversions from and to the target types.
* More formatting options for numeric types (underscores, hexadecimal, etc.).
* ISO 8601 support, dropping of SDLang's own datetime formatting.
* Standardization of how brace styles and semicolons work.

# Concepts

## Comments

The following comments styles are available in XDL:

```
/* Block comment */
/+ Block comment +/
// Single-line comment
# Single-line comment
```

Block comments can be multi-line, or inlined into a tag

## Tags

Tags are the main building blocks of an XDL element. A tag name is consisting of any letter or number type characters of UTF-8, can also contain dots and underscores, but the first character of a tag must not be a number or a dot. Space is used for separation. Optionally a tag can also contain any number of values and attributes on the same line.

```s
123tag                  #Illegal
.Tag                    #Illegal
Tag                     #OK
_Tag                    #OK
Tag123                  #OK
Tag.Tag                 #OK
Tag_Tag
タッグ                  #OK
ÁrvíztűrőTükörfúrógép   #OK
true                    #Illegal, collision with keyword
yes                     #Illegal, collision with keyword
false                   #Illegal, collision with keyword
no                      #Illegal, collision with keyword
null                    #Illegal, collision with keyword
```

XDL supports namespaces, and is noted by a single `:` character.

```s
Namespace:Name
```

Normally one tag can reside on a single line, but the semicolon (`;`) character can be used for separating multiple tags on the same line, if needed. Linebreaks are ignored inside strings and especially string scopes. A backlash (`\`) character can be used to force a tag into multiple lines.

```s
Tag1; Tag2; Tag3; ...
```

Tag names cannot be the following to avoid collision with 

Tags can be nameless, in that case, a tag only contains values and/or attributes, but cannot have child tags.

### Scopes and child tags

```s
ParentTag {
    ChildTag0
    ChildTag1
    ChildTag2 {
        ChildTag2_0
        ChildTag2_1
    }
}
```

Tags can have an optional scope, which is denoted by curly braces (`{ ... }`). A scope can contain any number of tags, which may have their own children. 

## Values

XDL has the following types available in multiple styles:

* Integer
* Floating-point
* Boolean
* String
* Base64
* Date and Time
* Null

Values can be added to a tag if needed, or are parts of an attribute

### Integer values

XDL can store integer numbers as decimal, hexadecimal, octal, and binary. Integers can be formatted with underscores for better readability.

```
123 123_123 -123 -123_123 0x123 0x123_abc 0o123 0o123_123 0b010101 0b01010101_01010101
```

To simplicity sake, all integer values are treated as 64 bit ones.

### Floating-point values

Floating-point numbers are denoted by the presence of a decimal point, and underscores can be used for formatting.

```
123 123_123 123.123 123_123.123_123 -123 -123.123
```

Normal format is also an option.

```
1.123e4 1.123e-4
```

Hexadecimal values are also an option if the following format is used:

```
0x123acbp4 0x1.23acbp4 0x1.23abcp-a 0x-1.23acbp4
```

For simplicity sake, all floating-point values are treated as 64 bit ones.

### Boolean

The following values can be used for boolean types:

```s
true                #means true
yes                 #means true
false               #means false
no                  #means false
```

### Strings

```
'Apostrophes can be used for regular strings, this one supports C style character escaping \' '
"Quotes can be used for regular strings, this one supports C style character escaping \" "
`Backticks are unescaped strings, they can contain ', ", and \, but not other backticks`
q{"
    String scopes are lifted from the D programming language, and are unescaped. Great for embedding scripting 
    languages into your XDL document as long as they don't have string scopes themselves. Fortunately, D 
    supports multiple ones, if you really need to embed D code into your document.
    IMPORTANT: Should not be used for embedding binary data, use the BASE64 capabilities instead!
"}
```

### Base64

Binary data can be embedded into an XDL document using a very basic Base64 encoding, at the cost of being ~33% bigger than the original unencoded binary.

### Date and Time

The following date and time formats are valid:

```
2024-09-19                      #YYYY-MM-DD
18:35:45Z                       #HH:mm:SSZ
2024-09-19T18:35:45Z            #YYYY-MM-DDTHH:mm:SSZ
2024-09-19T06:35:45−12:00       #YYYY-MM-DDTHH:mm:SSZ-UTC
2024-09-19T18:35:45+00:00       #YYYY-MM-DDTHH:mm:SSZ+UTC
18:35:45.000Z                   #HH:mm:SS.sssZ
2024-09-19T18:35:45.000Z        #YYYY-MM-DDTHH:mm:SS.sssZ
2024-09-19T06:35:45.000−12:00   #YYYY-MM-DDTHH:mm:SS.sssZ-UTC
2024-09-19T18:35:45.000+00:00   #YYYY-MM-DDTHH:mm:SS.sssZ+UTC
```

Time as in amount is denoted as:

```
1:35:45                         #HH:mm:SS
18:35:45.000                    #HH:mm:SS.sss
```

In this case, hours can be any arbitrary number of digits.

### Null

```
null
```

Simply just the word null, can be used as a placeholder

## Attributes

Attributes are a name and value pair within a tag, should be used for optional things. Has the same naming rules as tags

```
someAttribute = 860684
namespace:name = "fish"
```