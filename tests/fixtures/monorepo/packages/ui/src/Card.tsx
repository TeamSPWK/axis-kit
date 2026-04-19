import React from 'react';

interface CardProps {
  title: string;
  description?: string;
  children?: React.ReactNode;
}

const Card: React.FC<CardProps> = ({ title, description, children }) => {
  return (
    <div
      className="card"
      style={{
        border: '1px solid #e2e8f0',
        borderRadius: '8px',
        padding: '16px',
        background: '#ffffff',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      }}
    >
      <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#1a202c' }}>{title}</h2>
      {description && (
        <p style={{ color: '#718096', marginTop: '8px' }}>{description}</p>
      )}
      {children}
    </div>
  );
};

export default Card;
