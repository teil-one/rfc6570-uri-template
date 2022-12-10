export type OperatorType = '+' | '#' | '.' | '/' | ';' | '?' | '&';

export declare class VariableData {
  name: string;
  maxLength?: number;
  explode?: boolean;
}

export declare class ExpressionData {
  operator: OperatorType;
  variables: VariableData[];
}
