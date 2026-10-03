import React from 'react';
import {
  Scan,
  Download,
  MapPin,
  Bell,
  Video,
  Shield
} from 'lucide-react';

interface FeatureItem {
  icon: React.ReactNode;
  title: string;
  desc: string;
}

export default function Features() {
  const list: FeatureItem[] = [
    {
      icon: <Scan size={20} />,
      title: 'Dynamic Platform Scanning',
      desc: 'Discovers local Xcode simulator paths and Android SDK platform-tools runtimes instantly. Automatically reports running devices.'
    },
    {
      icon: <Download size={20} />,
      title: 'Drag-and-Drop Deployments',
      desc: 'Drop an .apk, .app, or .ipa onto any device row. DevBar automatically deploys build bundles in the background.'
    },
    {
      icon: <MapPin size={20} />,
      title: 'MapKit Location Spoofing',
      desc: 'Simulate coordinate geofences globally. Manually pan coordinates or playback GPX XML route files reactively.'
    },
    {
      icon: <Bell size={20} />,
      title: 'Push Intent Injection',
      desc: 'Bypass remote notification setups. Inject raw JSON notification payloads directly via simctl and Android intents.'
    },
    {
      icon: <Video size={20} />,
      title: 'SIGINT-Safe Captures',
      desc: 'Take clipboard screenshots or record lossless device screen videos. Triggers graceful SIGINT interrupts to avoid corrupted files.'
    },
    {
      icon: <Shield size={20} />,
      title: 'AI Agent MCP Integration',
      desc: 'Features a self-contained stdio JSON-RPC 2.0 server. Empower Claude Code, Cursor, or Windsurf to execute target commands natively.'
    }
  ];

  return (
    <section id="features" style={{
      paddingBlock: '6.5rem',
      position: 'relative'
    }}>
      <div className="container">
        {/* Section Header */}
        <div style={{
          textAlign: 'center',
          maxWidth: '620px',
          marginInline: 'auto',
          marginBottom: '4.5rem'
        }}>
          <h2 style={{ marginBottom: '1rem', letterSpacing: '-0.02em' }}>
            Unified controls. Zero IDE bloat.
          </h2>
          <p style={{ fontSize: '1.05rem', color: 'var(--text-grey)', lineHeight: '1.6' }}>
            Bypass heavy workspaces. Launch and control iOS Simulators and Android Emulators straight from a lightweight, native macOS command deck.
          </p>
        </div>

        {/* Feature Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '1.8rem'
        }}>
          {list.map((item, index) => (
            <div
              key={index}
              className="glass-card"
              style={{
                padding: '2.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                textAlign: 'left'
              }}
            >
              <div style={{
                width: '42px',
                height: '42px',
                borderRadius: '8px',
                backgroundColor: 'rgba(255, 255, 255, 0.03)',
                border: '1px solid var(--border-subtle)',
                color: 'var(--accent-cobalt)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '1.5rem'
              }}>
                {item.icon}
              </div>
              <h3 style={{
                fontSize: '1.25rem',
                color: 'var(--text-ivory)',
                marginBottom: '0.85rem'
              }}>
                {item.title}
              </h3>
              <p style={{
                fontSize: '0.95rem',
                lineHeight: '1.6',
                color: 'var(--text-grey)'
              }}>
                {item.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
