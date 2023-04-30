# rfc6570-uri-template

[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) URI template parser

## Getting started

```javascript
import { parse } from 'rfc6570-uri-template';

const template = parse('http://www.example.com/users/{id}');
const url = template.expand({ id: 1 }); // http://www.example.com/users/1
```

## Examples

`url = parse('{controller}/{action}').expand({ controller:  'books', action:  'read' });`\
books/read

`url = parse('foo{?query,number}').expand({ query:  'mycelium', number:  100 });`\
foo?query=mycelium&number=100

`url = parse('X{#hello}').expand({ hello:  'Hello World!' });`\
X#Hello%20World!

`url = parse('{+path:6}/here').expand({ path:  '/foo/bar' });`\
/foo/b/here

`url = parse('{list}').expand({ list: ['red', 'green', 'blue'] });`\
red,green,blue

`url = parse('{keys}').expand({ keys: { semi:  ';', dot:  '.', comma:  ',' } });`\
semi,%3B,dot,.,comma,%2C

`url = parse('{keys*}').expand({ keys: { semi:  ';', dot:  '.', comma:  ',' } });`\
semi=%3B,dot=.,comma=%2C

See more examples in the [RFC 6570 specification](https://www.rfc-editor.org/rfc/rfc6570).

[GitHub](https://github.com/teil-one/rfc6570-uri-template) · [NPM package](https://www.npmjs.com/package/rfc6570-uri-template)
