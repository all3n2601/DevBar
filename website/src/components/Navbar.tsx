export default function Navbar() {
  return (
    <nav style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 100,
      backgroundColor: 'rgba(7, 7, 9, 0.8)',
      backdropFilter: 'blur(20px)',
      WebkitBackdropFilter: 'blur(20px)',
      borderBottom: '1px solid var(--border-subtle)',
      paddingBlock: '0.9rem'
    }}>
      <div className="container" style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <a href="#" style={{
          display: 'flex',
          alignItems: 'center',
          gap: '0.65rem',
          textDecoration: 'none',
          color: 'var(--text-ivory)',
          fontFamily: 'var(--font-heading)',
          fontWeight: 700,
          fontSize: '1.2rem',
          letterSpacing: '-0.01em'
        }}>
          <img
            src="/assets/app_icon.png"
            alt="DevBar App Icon"
            style={{
              width: '28px',
              height: '28px',
              borderRadius: '7px',
              objectFit: 'cover'
            }}
          />
          <span>DevBar</span>
        </a>

        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '2.2rem'
        }}>
          <a href="#features" style={linkStyle}>Features</a>
          <a href="#demo" style={linkStyle}>Interactive HUD</a>
          <a href="#team" style={linkStyle}>Team Sync</a>
          <a href="#pricing" style={linkStyle}>Pricing</a>
          <a
            href="#pricing"
            className="btn btn-primary"
            style={{
              padding: '0.45rem 1.1rem',
              fontSize: '0.85rem',
              borderRadius: '6px'
            }}
          >
            Buy Now — $19
          </a>
        </div>
      </div>
    </nav>
  );
}

const linkStyle: React.CSSProperties = {
  color: 'var(--text-grey)',
  textDecoration: 'none',
  fontSize: '0.9rem',
  fontWeight: 500,
  transition: 'color 0.2s'
};
