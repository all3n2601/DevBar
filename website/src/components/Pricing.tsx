import React from 'react';
import { Check } from 'lucide-react';

export default function Pricing() {
  const triggerDemo = (tier: string) => {
    alert(`Demo Purchase Triggered! Thank you for supporting DevBar ${tier}.`);
  };

  return (
    <section id="pricing" style={{
      paddingBlock: '6.5rem',
      position: 'relative'
    }}>
      <div className="container">
        {/* Section Header */}
        <div style={{
          textAlign: 'center',
          maxWidth: '600px',
          marginInline: 'auto',
          marginBottom: '4.5rem'
        }}>
          <h2 style={{ marginBottom: '1rem', letterSpacing: '-0.02em' }}>
            Subscription-Free Licenses
          </h2>
          <p style={{ fontSize: '1.05rem', color: 'var(--text-grey)', lineHeight: '1.6' }}>
            One-time purchases. Keep all your developer data local, with zero background subscription friction.
          </p>
        </div>

        {/* Pricing Layout */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: '2.5rem',
          maxWidth: '840px',
          marginInline: 'auto'
        }}>
          {/* Indie License */}
          <div className="glass-card" style={cardStyle}>
            <div style={tierLabel}>INDIE LICENSE</div>
            <div style={priceStyle}>$19 <span style={oneTime}>/ one-time</span></div>
            <p style={descStyle}>For personal developer setups. Complete CLI and simulator command deck included.</p>

            <ul style={featuresList}>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Dynamic platform scanning</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Drag-and-Drop deploy installer</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Geofencing & GPX playbacks</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Clipboard screenshots & records</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Headless command-line CLI</li>
              <li style={{ ...featureItem, opacity: 0.35, textDecoration: 'line-through' }}>
                <Check size={14} /> Git-shared devbar.config presets
              </li>
            </ul>

            <button
              onClick={() => triggerDemo('Indie')}
              className="btn btn-secondary"
              style={{ width: '100%', marginTop: 'auto', fontWeight: 600 }}
            >
              Get Indie License
            </button>
          </div>

          {/* Team License */}
          <div className="glass-card" style={{
            ...cardStyle,
            borderColor: 'var(--accent-cobalt)',
            boxShadow: '0 20px 45px rgba(0, 102, 204, 0.25)'
          }}>
            <div style={{ ...tierLabel, color: 'var(--accent-cobalt)' }}>TEAM LICENSE</div>
            <div style={priceStyle}>$49 <span style={oneTime}>/ one-time</span></div>
            <p style={descStyle}>Up to 5 developer seats. Features workspace-wide preset synchronization.</p>

            <ul style={featuresList}>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> All Indie developer features</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Exposes local MCP stdio server</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Shared Git-based presets config</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Deploy across 5 device seats</li>
              <li style={featureItem}><Check size={14} style={{ color: 'var(--accent-green)' }} /> Priority Slack channel support</li>
            </ul>

            <button
              onClick={() => triggerDemo('Team')}
              className="btn btn-primary"
              style={{ width: '100%', marginTop: 'auto', fontWeight: 600 }}
            >
              Get Team License
            </button>
          </div>
        </div>

        {/* Workspace Preset Config Details Box */}
        <div id="team" className="glass-card" style={{
          maxWidth: '840px',
          marginInline: 'auto',
          marginTop: '4.5rem',
          padding: '2.5rem',
          textAlign: 'left',
          backgroundColor: 'rgba(255, 255, 255, 0.01)',
          borderColor: 'rgba(16, 185, 129, 0.2)'
        }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            backgroundColor: 'rgba(16, 185, 129, 0.08)',
            border: '1px solid rgba(16, 185, 129, 0.2)',
            color: 'var(--accent-green)',
            padding: '0.25rem 0.65rem',
            borderRadius: '4px',
            fontSize: '0.72rem',
            fontWeight: 600,
            marginBottom: '1rem'
          }}>
            TEAM WORKSPACE PRESETS
          </div>
          <h3 style={{ fontSize: '1.45rem', marginBottom: '0.85rem' }}>Dynamic Git-Shared Configurations</h3>
          <p style={{ fontSize: '0.95rem', color: 'var(--text-grey)', lineHeight: '1.6', marginBottom: '1.5rem' }}>
            Collaborate on push testing and coordinate setups across your developer pod. Add a <code>devbar.config.json</code> in your repository root, and DevBar automatically parses and merges shared presets directly into your HUD row, marked with green tags.
          </p>
          <pre style={{
            backgroundColor: '#070709',
            border: '1px solid var(--border-subtle)',
            borderRadius: '8px',
            padding: '1rem 1.25rem',
            fontSize: '0.8rem',
            lineHeight: '1.4',
            color: 'var(--accent-green)',
            overflowX: 'auto',
            margin: 0
          }}>
            <code>{`{
  "gpsPresets": [
    { "name": "Seattle HQ", "latitude": 47.6062, "longitude": -122.3321 },
    { "name": "Berlin Lab", "latitude": 52.5200, "longitude": 13.4050 }
  ]
}`}</code>
          </pre>
        </div>
      </div>
    </section>
  );
}

// Styling definitions
const cardStyle: React.CSSProperties = {
  padding: '3rem 2.2rem',
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'flex-start',
  textAlign: 'left',
  height: '100%',
  boxSizing: 'border-box'
};

const tierLabel: React.CSSProperties = {
  fontSize: '0.75rem',
  fontWeight: 700,
  color: 'var(--accent-gold)',
  letterSpacing: '0.08em',
  marginBottom: '0.5rem'
};

const priceStyle: React.CSSProperties = {
  fontSize: '3rem',
  fontWeight: 800,
  fontFamily: 'var(--font-heading)',
  color: 'var(--text-ivory)',
  lineHeight: 1,
  marginBottom: '1.25rem',
  display: 'flex',
  alignItems: 'baseline'
};

const oneTime: React.CSSProperties = {
  fontSize: '0.95rem',
  color: 'var(--text-grey)',
  fontWeight: 500,
  marginLeft: '0.25rem'
};

const descStyle: React.CSSProperties = {
  fontSize: '0.95rem',
  color: 'var(--text-grey)',
  lineHeight: '1.5',
  marginBottom: '2rem'
};

const featuresList: React.CSSProperties = {
  listStyle: 'none',
  padding: 0,
  margin: '0 0 2.5rem 0',
  display: 'flex',
  flexDirection: 'column',
  gap: '0.85rem',
  width: '100%'
};

const featureItem: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '0.65rem',
  fontSize: '0.9rem',
  color: 'var(--text-grey)',
  textAlign: 'left'
};
