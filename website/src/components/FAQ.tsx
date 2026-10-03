import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';

interface FaqItem {
  q: string;
  a: string;
}

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const list: FaqItem[] = [
    {
      q: 'Does DevBar dispatch developer data to external servers?',
      a: 'Absolutely not. DevBar operates 100% locally. Runtimes are scanned dynamically, and GPS mock updates are channeled over direct adb intents or local Apple simctl pipes. No telemetry servers or external background logs exist.'
    },
    {
      q: 'How does the Model Context Protocol (MCP) server operate?',
      a: 'DevBar registers a pure-Swift stdio server mode. By invoking swift run DevBar mcp, it listens on standard input and decodes JSON-RPC 2.0 requests. AI agents (Cursor, Claude Code) can discover and boot devices natively over stdio without any local HTTP daemons.'
    },
    {
      q: 'Do I need Xcode or Android Studio launched to operate it?',
      a: 'No. DevBar communicates directly with the underlying CLI binaries (xcrun simctl, adb). You can boot, interact with, set coordinates, or take clipboard captures without loading heavy IDE workspaces.'
    },
    {
      q: 'How does it handle Telnet authentication locks on Android?',
      a: 'DevBar bypasses brittle telnet handshake authentications by broadcasting coordinate updates over native adb package intents (am broadcast). Geofence locations spoof immediately without telnet console configuration.'
    }
  ];

  const handleToggle = (index: number) => {
    setOpenIndex(openIndex === index ? null : index);
  };

  return (
    <section style={{
      paddingBlock: '6.5rem',
      backgroundColor: '#050507',
      borderTop: '1px solid var(--border-subtle)'
    }}>
      <div className="container">
        {/* Header */}
        <div style={{
          textAlign: 'center',
          maxWidth: '600px',
          marginInline: 'auto',
          marginBottom: '4rem'
        }}>
          <h2 style={{ marginBottom: '1rem', letterSpacing: '-0.02em' }}>
            Frequently Asked Questions
          </h2>
          <p style={{ fontSize: '1.05rem', color: 'var(--text-grey)', lineHeight: '1.6' }}>
            Everything you need to know about DevBar simulator and emulator integrations.
          </p>
        </div>

        {/* FAQ List */}
        <div style={{
          maxWidth: '720px',
          marginInline: 'auto',
          display: 'flex',
          flexDirection: 'column',
          gap: '1rem'
        }}>
          {list.map((item, index) => {
            const isOpen = openIndex === index;
            return (
              <div
                key={index}
                className="glass-card"
                style={{
                  padding: '1.5rem',
                  cursor: 'pointer',
                  textAlign: 'left',
                  border: isOpen ? '1px solid rgba(255,255,255,0.15)' : '1px solid var(--border-subtle)',
                  backgroundColor: isOpen ? 'rgba(255,255,255,0.02)' : 'rgba(18,18,21,0.5)'
                }}
                onClick={() => handleToggle(index)}
              >
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  fontWeight: 500,
                  fontSize: '1.05rem',
                  color: isOpen ? 'var(--text-ivory)' : 'var(--text-grey)',
                  transition: 'color 0.2s'
                }}>
                  <span>{item.q}</span>
                  {isOpen ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                </div>

                <div style={{
                  maxHeight: isOpen ? '200px' : '0px',
                  opacity: isOpen ? 1 : 0,
                  overflow: 'hidden',
                  transition: 'all 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
                  marginTop: isOpen ? '1rem' : '0'
                }}>
                  <p style={{
                    fontSize: '0.95rem',
                    lineHeight: '1.6',
                    color: 'var(--text-grey)',
                    margin: 0
                  }}>
                    {item.a}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
