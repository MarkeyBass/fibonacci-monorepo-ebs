import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

jest.mock('./Fib', () => function FibMock() {
  return <div data-testid="fib-mock">Fib mock</div>;
});

jest.mock('react-router-dom', () => ({
  BrowserRouter: ({ children }) => <div>{children}</div>,
  Route: ({ component: Component }) => (Component ? <Component /> : null),
  Link: ({ children, to }) => <a href={to}>{children}</a>,
}));

const originalConsoleError = console.error;

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation((...args) => {
    const [firstArg] = args;
    if (
      typeof firstArg === 'string' &&
      firstArg.includes('ReactDOMTestUtils.act is deprecated in favor of React.act')
    ) {
      return;
    }
    originalConsoleError(...args);
  });
});

afterAll(() => {
  console.error.mockRestore();
});

test('renders learn react link', () => {
  render(<App />);
  const linkElement = screen.getByText(/learn react/i);
  expect(linkElement).toBeInTheDocument();
});
