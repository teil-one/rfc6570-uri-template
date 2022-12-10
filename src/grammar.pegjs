/*
 * URI Template
 *
 * http://tools.ietf.org/html/rfc6570
 *
 * @append ietf/rfc3986-uri.pegjs
 * @append ietf/rfc3987-iri.pegjs
 * @append ietf/rfc5234-core-abnf.pegjs
 */
 

/* http://tools.ietf.org/html/rfc6570#section-2 Syntax */
URI_Template
  = items:(expression / literals )*

/* http://tools.ietf.org/html/rfc6570#section-2.1 Literals. Combined with https://www.rfc-editor.org/errata/eid6937 */
literals
  // any Unicode character except: CTL, SP,
  // DQUOTE, "%" (aside from pct-encoded),
  // "<", ">", "\", "^", "`", "{", "|", "}"
  = "\x21"
  / [\x23-\x24]
  / [\x26-\x3B]
  / "\x3D"
  / [\x3F-\x5B]
  / "\x5D"
  / "\x5F"
  / [\x61-\x7A]
  / "\x7E"
  / ucschar
  / iprivate
  / pct_encoded


/* http://tools.ietf.org/html/rfc6570#section-2.2 Expressions */
expression
  =  "{" operator:operator? variables:variable_list "}"
  { return { operator, variables }}

operator
  = op_level2
  / op_level3
  / op_reserve

op_level2
  = "+"
  / "#"

op_level3
  = "."
  / "/"
  / ";"
  / "?"
  / "&"

op_reserve
  = "="
  / ","
  / "!"
  / "@"
  / "|"


/* http://tools.ietf.org/html/rfc6570#section-2.3 Variables */
variable_list
  = first:varspec next:("," next:varspec { return next })*
  { const variables = [first, ...next]; return variables }

varspec
  = name:varname modifier:modifier_level4?
  { return { ...{ name }, ...modifier}}

varname
  = $(varchar ("."? varchar)*)

varchar
  = ALPHA
  / DIGIT
  / "_"
  / pct_encoded


/* http://tools.ietf.org/html/rfc6570#section-2.4 Value Modifiers */
modifier_level4
  = prefix
  / explode


/* http://tools.ietf.org/html/rfc6570#section-2.4.1 Prefix Values */
prefix
  = ":" value:max_length
  { return { maxLength: value }}

max_length
  // positive integer < 10000
  = $([\x31-\x39] DIGIT? DIGIT? DIGIT?)


/* http://tools.ietf.org/html/rfc6570#section-2.4.2 Composite Values */
explode
  = "*"
  { return { explode: true } }
/*
 * Uniform Resource Identifier (URI): Generic Syntax
 *
 * http://tools.ietf.org/html/rfc3986
 *
 * <host> element has been renamed to <hostname> as a dirty workaround for
 * element being re-defined with another meaning in HTTPbis
 *
 * @append ietf/rfc5234-core-abnf.pegjs
 */

/* http://tools.ietf.org/html/rfc3986#section-2.1 Percent-Encoding */
pct_encoded
  = $("%" HEXDIG HEXDIG)


/* http://tools.ietf.org/html/rfc3986#section-2.2 Reserved Characters */
reserved
  = gen_delims
  / sub_delims

gen_delims
  = ":"
  / "/"
  / "?"
  / "#"
  / "["
  / "]"
  / "@"

sub_delims
  = "!"
  / "$"
  / "&"
  / "'"
  / "("
  / ")"
  / "*"
  / "+"
  / ","
  / ";"
  / "="


/* http://tools.ietf.org/html/rfc3986#section-2.3 Unreserved Characters */
unreserved
  = ALPHA
  / DIGIT
  / "-"
  / "."
  / "_"
  / "~"


/* http://tools.ietf.org/html/rfc3986#section-3 Syntax Components */
URI
  = scheme ":" hier_part ("?" query)? ("#" fragment)?

hier_part
  = "//" authority path_abempty
  / path_absolute
  / path_rootless
  / path_empty


/* http://tools.ietf.org/html/rfc3986#section-3.1 Scheme */
scheme
  = $(ALPHA (ALPHA / DIGIT / "+" / "-" / ".")*)


/* http://tools.ietf.org/html/rfc3986#section-3.2 Authority */
// CHANGE host to hostname
authority
  = (userinfo "@")? hostname (":" port)?


/* http://tools.ietf.org/html/rfc3986#section-3.2.1 User Information */
userinfo
  = $(unreserved / pct_encoded / sub_delims / ":")*


/* http://tools.ietf.org/html/rfc3986#section-3.2.2 Host */
// CHANGE host to hostname
// CHANGE Add forward check for reg_name
hostname
  = IP_literal !reg_name_item_
  / IPv4address !reg_name_item_
  / reg_name

IP_literal
  = "[" (IPv6address / IPvFuture) "]"

IPvFuture
  = "v" $(HEXDIG+) "." $( unreserved
                        /*
                        // CHANGE Ignore due to https://github.com/for-GET/core-pegjs/issues/8
                        / sub_delims
                        */
                        / ":"
                        )+

IPv6address
  = $(                                                            h16_ h16_ h16_ h16_ h16_ h16_ ls32
     /                                                       "::"      h16_ h16_ h16_ h16_ h16_ ls32
     / (                                               h16)? "::"           h16_ h16_ h16_ h16_ ls32
     / (                               h16_?           h16)? "::"                h16_ h16_ h16_ ls32
     / (                         (h16_ h16_?)?         h16)? "::"                     h16_ h16_ ls32
     / (                   (h16_ (h16_ h16_?)?)?       h16)? "::"                          h16_ ls32
     / (             (h16_ (h16_ (h16_ h16_?)?)?)?     h16)? "::"                               ls32
     / (       (h16_ (h16_ (h16_ (h16_ h16_?)?)?)?)?   h16)? "::"                               h16
     / ( (h16_ (h16_ (h16_ (h16_ (h16_ h16_?)?)?)?)?)? h16)? "::"
     )

ls32
  // least_significant 32 bits of address
  = h16 ":" h16
  / IPv4address

h16_
  = h16 ":"

h16
  // 16 bits of address represented in hexadecimal
  = $(HEXDIG (HEXDIG (HEXDIG HEXDIG?)?)?)

IPv4address
  = $(dec_octet "." dec_octet "." dec_octet "." dec_octet)

// CHANGE order in reverse for greedy matching
dec_octet
  = $( "25" [\x30-\x35]      // 250-255
     / "2" [\x30-\x34] DIGIT // 200-249
     / "1" DIGIT DIGIT       // 100-199
     / [\x31-\x39] DIGIT     // 10-99
     / DIGIT                 // 0-9
     )

reg_name
  = $(reg_name_item_*)
reg_name_item_
  = unreserved
  / pct_encoded
  /*
  // CHANGE Ignore due to https://github.com/for-GET/core-pegjs/issues/8
  / sub_delims
  */


/* http://tools.ietf.org/html/rfc3986#section-3.2.3 Port */
port
  = $(DIGIT*)


/* http://tools.ietf.org/html/rfc3986#section-3.3 Path */
path
  = path_abempty  // begins with "/" or is empty
  / path_absolute // begins with "/" but not "//"
  / path_noscheme // begins with a non_colon segment
  / path_rootless // begins with a segment
  / path_empty    // zero characters

path_abempty
  = $("/" segment)*

path_absolute
  = $("/" (segment_nz ("/" segment)*)?)

path_noscheme
  = $(segment_nz_nc ("/" segment)*)

path_rootless
  = $(segment_nz ("/" segment)*)

path_empty
  = ""

segment
  = $(pchar*)

segment_nz
  = $(pchar+)

segment_nz_nc
  // non_zero_length segment without any colon ":"
  = $(unreserved / pct_encoded / sub_delims / "@")+

pchar
  = unreserved
  / pct_encoded
  / sub_delims
  / ":"
  / "@"


/* http://tools.ietf.org/html/rfc3986#section-3.4 Query */
query
  = $(pchar / "/" / "?")*


/* http://tools.ietf.org/html/rfc3986#section-3.5 Fragment */
fragment
  = $(pchar / "/" / "?")*


/* http://tools.ietf.org/html/rfc3986#section-4.1 URI Reference */
URI_reference
  = URI
  / relative_ref


/* http://tools.ietf.org/html/rfc3986#section-4.2 Relative Reference */
relative_ref
  = relative_part ("?" query)? ("#" fragment)?

relative_part
  = "//" authority path_abempty
  / path_absolute
  / path_noscheme
  / path_empty


/* http://tools.ietf.org/html/rfc3986#section-4.3 Absolute URI */
absolute_URI
  = scheme ":" hier_part ("?" query)?
/*
 * Internationalized Resource Identifiers (IRIs)
 *
 * http://tools.ietf.org/html/rfc3987
 *
 * @append ietf/rfc5234-core-abnf.pegjs
 */

ucschar
  = [\u00A0-\uD7FF]
  / [\uF900-\uFDCF]
  / [\uFDF0-\uFFEF]

  / [\u10000-\u1FFFD]
  / [\u20000-\u2FFFD]
  / [\u30000-\u3FFFD]

  / [\u40000-\u4FFFD]
  / [\u50000-\u5FFFD]
  / [\u60000-\u6FFFD]

  / [\u70000-\u7FFFD]
  / [\u80000-\u8FFFD]
  / [\u90000-\u9FFFD]

  / [\uA0000-\uAFFFD]
  / [\uB0000-\uBFFFD]
  / [\uC0000-\uCFFFD]

  / [\uD0000-\uDFFFD]
  / [\uE1000-\uEFFFD]

iprivate
  = [\uE000-\uF8FF]
  / [\uF0000-\uFFFFD]
  / [\u100000-\u10FFFD]
/*
 * Augmented BNF for Syntax Specifications: ABNF
 *
 * http://tools.ietf.org/html/rfc5234
 */

/* http://tools.ietf.org/html/rfc5234#appendix-B Core ABNF of ABNF */
ALPHA
  = [\x41-\x5A]
  / [\x61-\x7A]

BIT
  = "0"
  / "1"

CHAR
  = [\x01-\x7F]

CR
  = "\x0D"

CRLF
  = CR LF

CTL
  = [\x00-\x1F]
  / "\x7F"

DIGIT
  = [\x30-\x39]

DQUOTE
  = [\x22]

HEXDIG
  = DIGIT
  / "A"i
  / "B"i
  / "C"i
  / "D"i
  / "E"i
  / "F"i

HTAB
  = "\x09"

LF
  = "\x0A"

LWSP
  = $(WSP / CRLF WSP)*

OCTET
  = [\x00-\xFF]

SP
  = "\x20"

VCHAR
  = [\x21-\x7E]

WSP
  = SP
  / HTAB
