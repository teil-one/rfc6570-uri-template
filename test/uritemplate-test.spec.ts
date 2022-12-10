import * as examplesBySection from './uritemplate-test/spec-examples-by-section.json';
import * as examples from './uritemplate-test/spec-examples.json';
import * as extended from './uritemplate-test/extended-tests.json';
import * as negative from './uritemplate-test/negative-tests.json';

import { parse } from '../src/index';

type TestSection = Record<
  string,
  Record<
    string,
    {
      variables?: Record<string, unknown>;
      testcases?: Array<[string, string | string[] | boolean]>;
    }
  >
>;

function runStandardTests(testSection: TestSection): void {
  for (const x of Object.values(testSection)) {
    for (const section of Object.values(x)) {
      const variables = section.variables;
      const testCases = section.testcases;

      if (variables == null || testCases == null) {
        continue;
      }

      for (const testCase of testCases) {
        const uriTemplate = testCase[0];

        const parseExpand = (): string => parse(uriTemplate).expand(variables);

        test(`Template ${uriTemplate} and variables ${JSON.stringify(variables)}`, () => {
          const shouldFail = testCase[1] === false;
          if (shouldFail) {
            expect(parseExpand).toThrowError();
          } else {
            const expectedResults = Array.isArray(testCase[1]) ? testCase[1] : [testCase[1]];
            expect(expectedResults).toContain(parseExpand());
          }
        });
      }
    }
  }
}

describe('spec-examples-by-section', () => {
  runStandardTests(examplesBySection as TestSection);
});

describe('spec-examples', () => {
  runStandardTests(examples as TestSection);
});

describe('extended', () => {
  runStandardTests(extended as TestSection);
});

describe('negative', () => {
  runStandardTests(negative as TestSection);
});
