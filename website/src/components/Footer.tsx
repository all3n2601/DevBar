import React from 'react';

export default function Footer() {
  return (
    <footer style={{
      backgroundColor: '#030304',
      borderTop: '1px solid var(--border-subtle)',
      paddingBlock: '4.5rem',
      textAlign: 'center'
    }}>
      <div className="container" style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '2rem'
      }}>
        {/* Brand */}
        <a href="#" style={{
          display: 'flex',
          alignItems: 'center',
          gap: '0.65rem',
          textDecoration: 'none',
          color: 'var(--text-ivory)',
          fontFamily: 'var(--font-heading)',
          fontWeight: 700,
          fontSize: '1.25rem'
        }}>
          <img
            src="/assets/app_icon.png"
            alt="DevBar Logo"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px'
            }}
          />
          <span>DevBar</span>
        </a>

        {/* Footer Nav */}
        <div style={{
          display: 'flex',
          gap: '2.5rem',
          justifyContent: 'center'
        }}>
          <a href="#features" style={footerLink}>Features</a>
          <a href="#demo" style={footerLink}>HUD Demo</a>
          <a href="#team" style={footerLink}>Team Presets</a>
          <a href="#pricing" style={footerLink}>Pricing</a>
        </div>

        {/* Legal copyrights */}
        <p style={{
          fontSize: '0.82rem',
          color: 'var(--text-muted)',
          margin: 0
        }}>
          &copy; 2026 DevBar. Engineered in pure Swift. Keep your mobile builds local.
        </p>
      </div>
    </footer>
  );
}

const footerLink: React.CSSProperties = {
  color: 'var(--text-grey)',
  textDecoration: 'none',
  fontSize: '0.85rem',
  fontWeight: 500,
  transition: 'color 0.2s'
};
