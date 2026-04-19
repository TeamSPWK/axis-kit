import { styled } from '@emotion/styled';
import { css } from '@emotion/react';

export const PrimaryButton = styled.button`
  background: #0070f3;
  color: #ffffff;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;

  &:hover {
    background: #0051a2;
  }

  &:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
`;

export const containerStyle = css`
  display: flex;
  gap: 8px;
  padding: 16px;
  background: #f9fafb;
`;
