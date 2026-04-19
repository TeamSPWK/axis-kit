import React from 'react';

interface ButtonProps {
  label: string;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
  onClick?: () => void;
}

const Button: React.FC<ButtonProps> = ({ label, variant = 'primary', disabled, onClick }) => {
  return (
    <button
      className={`btn btn--${variant}`}
      style={{
        background: variant === 'primary' ? '#0070f3' : '#ffffff',
        color: variant === 'primary' ? '#ffffff' : '#0070f3',
        border: '1px solid #0070f3',
        padding: '8px 16px',
        borderRadius: '4px',
        fontSize: '14px',
        fontWeight: 600,
        cursor: disabled ? 'not-allowed' : 'pointer',
      }}
      disabled={disabled}
      onClick={onClick}
    >
      {label}
    </button>
  );
};

export default Button;
