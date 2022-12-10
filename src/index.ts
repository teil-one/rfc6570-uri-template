import { OperatorType, VariableData, ExpressionData } from './grammar-types.js';
import { parse as parseWithGrammar } from './grammar.js';

export function parse(input: string): Template {
  return new Template(input);
}

class Template {
  constructor(input: string) {
    const items = parseWithGrammar(input, {});
    this.items = items;
  }

  items: Array<ExpressionData | string>;

  public expand(values: Record<string, unknown>): string {
    let result: string = '';

    let hasExpressions = false;

    for (const item of this.items) {
      if (typeof item === 'string') {
        if (item.charCodeAt(0) <= 0x20 || ['%', '<', '>', '\\', '^', '`', '{', '|', '}', '', '', ''].includes(item)) {
          throw new SyntaxError(`Invalid literal: ${item}`);
        }

        result += item;
        continue;
      }

      const expression = new Expression(item.variables, item.operator);
      result += expression.expand(values);

      hasExpressions = true;
    }

    if (!hasExpressions) {
      throw new ExpandingError('Template has no expressions');
    }
    return result;
  }
}

class Expression {
  operator: Operator;
  variables: VariableData[];

  constructor(variables: VariableData[], op?: OperatorType) {
    this.operator = new Operator(op);
    this.variables = variables;
  }

  expand(values: Record<string, unknown>): string {
    return this.operator.expand(this.variables, values);
  }
}

class Operator {
  prefix: string;
  config: ExpansionConfig;

  constructor(op?: OperatorType) {
    this.config = new ExpansionConfig(op);
    this.prefix = this.config.addPrefix ? op ?? '' : '';
  }

  expand(variables: VariableData[], values: Record<string, unknown>): string {
    const strings: string[] = [];
    variables.forEach((v) => {
      const variable = new Variable(v.name, this.config, v.maxLength, v.explode);

      const value = values[variable.name];
      if (isEmptyValue(value)) {
        return;
      }

      const string = variable.expand(value);
      strings.push(string ?? '');
    });

    if (strings.length === 0) {
      return '';
    }

    if (strings.length === 0) {
      return '';
    }

    const expanded = strings.join(this.config.separator);
    if (expanded.length === 0) {
      return this.config.emptyValue;
    }
    return this.prefix + expanded;
  }
}

class ExpansionConfig {
  addPrefix: boolean = true;
  separator: string = ',';
  emptyValue: string = '';
  addName: boolean = false;
  encode: (s: string) => string = ExpansionConfig.UrlSafeEncode;

  constructor(op?: OperatorType) {
    if (op == null) {
      return;
    }

    switch (op) {
      case '+':
        this.addPrefix = false;
        this.encode = ExpansionConfig.RestrictedEncode;
        break;
      case '#':
        this.encode = ExpansionConfig.RestrictedEncode;
        this.emptyValue = '#';
        break;
      case '.':
        this.separator = '.';
        this.emptyValue = '.';
        break;
      case '/':
        this.separator = '/';
        break;
      case ';':
        this.separator = ';';
        this.addName = true;
        break;
      case '?':
      case '&':
        this.separator = '&';
        this.emptyValue = '=';
        this.addName = true;
        break;
      default:
        throw new SyntaxError(`Invalid expression operator`);
    }
  }

  static UrlSafeEncode = (x: string): string => encodeURIComponent(x).replace('!', '%21');

  static RestrictedEncode = (x: string): string =>
    x
      .split(/%(?=[\da-fA-F]{2})/)
      .map((x) => encodeURI(x))
      .join('%');
}

class Variable {
  name: string;
  explode?: boolean;
  maxLength?: number;
  config: ExpansionConfig;

  constructor(name: string, config: ExpansionConfig, maxLength?: number, explode?: boolean) {
    this.name = name;
    this.config = config;
    this.maxLength = maxLength;
    this.explode = explode;
  }

  expand(value: unknown): string | undefined {
    if (this.explode === true) {
      return this.expandExplode(value);
    } else {
      return this.expandSingle(value);
    }
  }

  expandSingle(value: unknown): string {
    const { emptyValue, encode, addName } = this.config;

    if (typeof value === 'object' && this.maxLength != null) {
      throw new ExpandingError("Max-length prefix can't be used with object values");
    }

    let result = null;

    if (Array.isArray(value)) {
      result = value.map(encode).join(',');
    } else if (typeof value === 'object') {
      result = Object.entries(value as object)
        .map((entry) => entry.map(encode).join(','))
        .join(',');
    } else {
      result = value as string;
      if (this.maxLength != null) {
        result = result.substring(0, this.maxLength);
      }
      result = encode(result);
    }

    if (addName) {
      if (result.length > 0) {
        result = `${this.name}=${result}`;
      } else {
        result = `${this.name}${emptyValue}`;
      }
    }

    return result;
  }

  expandExplode(value: unknown): string {
    const { encode, addName, separator } = this.config;

    if (Array.isArray(value)) {
      let items = value.map(encode);
      if (addName) {
        items = items.map((item) => `${this.name}=${item}`);
      }

      return items.join(separator);
    } else if (typeof value === 'object') {
      const pairs: string[] = [];

      Object.entries(value as object).forEach(([k, v]) => {
        const encodedKey = encode(k);
        if (Array.isArray(v)) {
          v.forEach((valueItem) => {
            pairs.push(`${encodedKey}=${encode(valueItem)}`);
          });
        } else {
          pairs.push(`${encodedKey}=${encode(v)}`);
        }
      });

      return pairs.join(separator);
    } else {
      return encode(value as string);
    }
  }
}

class ExpandingError extends Error {}

function isEmptyValue(data: unknown): boolean {
  return (
    data == null ||
    (Array.isArray(data) && data.length === 0) ||
    (typeof data === 'object' && Object.keys(data).length === 0)
  );
}
