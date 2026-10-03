import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Laptop,
  Map,
  Bell,
  Bot,
  Wifi,
  WifiOff
} from 'lucide-react';

type TabType = 'devices' | 'gps' | 'push' | 'mcp';

interface Preset {
  name: string;
  lat: number;
  lng: number;
  x: number;
  y: number;
  isTeam?: boolean;
}

const PRESETS: Preset[] = [
  { name: 'San Francisco', lat: 37.7749, lng: -122.4194, x: 28, y: 52 },
  { name: 'Seattle HQ', lat: 47.6062, lng: -122.3321, x: 35, y: 38, isTeam: true },
  { name: 'Berlin Lab', lat: 52.5200, lng: 13.4050, x: 68, y: 32, isTeam: true },
  { name: 'Sydney Hub', lat: -33.8688, lng: 151.2093, x: 82, y: 82, isTeam: true }
];

export default function SimulatorDeck() {
  const [activeTab, setActiveTab] = useState<TabType>('devices');
  const [isBooted, setIsBooted] = useState(false);

  // Geofencing states
  const [coords, setCoords] = useState({ lat: 37.7749, lng: -122.4194, x: 28, y: 52 });
  const [inputLat, setInputLat] = useState('37.7749');
  const [inputLng, setInputLng] = useState('-122.4194');

  // Notification banner states
  const [notification, setNotification] = useState({ visible: false, title: '', body: '' });

  // Push states
  const [pushPreset, setPushPreset] = useState('welcome');
  const [pushPayload, setPushPayload] = useState(JSON.stringify({
    aps: {
      alert: {
        title: "Welcome to DevBar! 🚀",
        body: "Get ready for unified iOS & Android simulator controls."
      },
      badge: 1,
      sound: "default"
    }
  }, null, 2));

  // MCP console logs states
  const [consoleLogs, setConsoleLogs] = useState<{ text: string; class: string }[]>([]);
  const consoleEndRef = useRef<HTMLDivElement>(null);
  const activeSequenceRef = useRef<number | null>(null);

  // Auto-scroll console
  useEffect(() => {
    if (consoleEndRef.current) {
      consoleEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [consoleLogs]);

  // Handle push notification preset switch
  const handlePushPresetChange = (key: string) => {
    setPushPreset(key);
    let title = '';
    let body = '';
    if (key === 'welcome') {
      title = "Welcome to DevBar! 🚀";
      body = "Get ready for unified iOS & Android simulator controls.";
    } else if (key === 'transaction') {
      title = "Payment Successful 💳";
      body = "Your receipt of $19.00 has been sent to your email.";
    } else if (key === 'geofence') {
      title = "Geofence Triggered 📍";
      body = "User entered Sydney Hub boundary circle.";
    }

    setPushPayload(JSON.stringify({
      aps: {
        alert: { title, body },
        badge: 1,
        sound: "default"
      }
    }, null, 2));
  };

  // Helper to trigger push banner
  const triggerNotificationBanner = (title: string, body: string) => {
    setNotification({ visible: true, title, body });
    setTimeout(() => {
      setNotification(prev => ({ ...prev, visible: false }));
    }, 4500);
  };

  // Coordinate setter
  const applyCoordinates = (lat: number, lng: number, xVal?: number, yVal?: number) => {
    if (!isBooted) {
      triggerNotificationBanner('Simulator Offline', 'Please boot the simulator first.');
      return;
    }

    const finalX = xVal !== undefined ? xVal : Math.min(Math.max(((lng + 180) / 360) * 100, 10), 90);
    const finalY = yVal !== undefined ? yVal : Math.min(Math.max((1 - (lat + 90) / 180) * 100, 10), 90);

    setCoords({ lat, lng, x: finalX, y: finalY });
    setInputLat(lat.toFixed(4));
    setInputLng(lng.toFixed(4));
    triggerNotificationBanner('🗺️ GPS Spoofed', `Teleported to ${lat.toFixed(4)}, ${lng.toFixed(4)}`);
  };

  // Preset click
  const handlePresetClick = (preset: Preset) => {
    setInputLat(preset.lat.toString());
    setInputLng(preset.lng.toString());
    applyCoordinates(preset.lat, preset.lng, preset.x, preset.y);
  };

  // Inject Push
  const handleInjectPush = () => {
    if (!isBooted) {
      triggerNotificationBanner('Simulator Offline', 'Boot the device to inject push payloads.');
      return;
    }

    try {
      const parsed = JSON.parse(pushPayload);
      const title = parsed.aps?.alert?.title || parsed.title || 'Notification Injected';
      const body = parsed.aps?.alert?.body || parsed.body || 'Custom JSON payload synced.';
      triggerNotificationBanner(title, body);
    } catch {
      triggerNotificationBanner('⚠️ JSON Error', 'Invalid push JSON syntax.');
    }
  };

  // MCP Simulated loop
  const startMcpSimulation = useCallback(() => {
    setConsoleLogs([]);
    if (activeSequenceRef.current) {
      clearTimeout(activeSequenceRef.current);
    }

    const lines = [
      { text: '$ claude-code', class: 'text-cobalt', delay: 400 },
      { text: 'AI Agent starting... connected to DevBar local stdio server.', class: 'text-grey', delay: 700 },
      { text: '🤖 agent: "Search for active devices and teleport to Berlin Lab HQ."', class: 'text-grey', delay: 900 },
      { text: '>>> [JSON-RPC Request: devbar_set_location]', class: 'text-cobalt', delay: 800 },
      { text: '{\n  "jsonrpc": "2.0",\n  "method": "tools/call",\n  "params": {\n    "name": "devbar_set_location",\n    "arguments": {\n      "latitude": 52.5200,\n      "longitude": 13.4050\n    }\n  },\n  "id": 101\n}', class: 'text-ivory', delay: 1400 },
      { text: '>>> [JSON-RPC Response from DevBar]', class: 'text-green', delay: 700 },
      { text: '{\n  "jsonrpc": "2.0",\n  "result": {\n    "content": [\n      {\n        "type": "text",\n        "text": "SUCCESS: Spoofed GPS coordinates to Berlin Lab (52.5200, 13.4050) across all runtimes."\n      }\n    ]\n  },\n  "id": 101\n}', class: 'text-ivory', delay: 1000 },
      { text: '🤖 agent: "Successfully teleported virtual devices to Berlin!"', class: 'text-green', delay: 300 }
    ];

    let index = 0;
    const run = () => {
      if (index >= lines.length) return;
      const line = lines[index];
      setConsoleLogs(prev => [...prev, { text: line.text, class: line.class }]);

      // Auto-trigger Berlin coordinates panning in simulated device
      if (index === 4 && isBooted) {
        setCoords({ lat: 52.5200, lng: 13.4050, x: 68, y: 32 });
        setInputLat('52.5200');
        setInputLng('13.4050');
      }

      index++;
      activeSequenceRef.current = window.setTimeout(run, line.delay);
    };

    run();
  }, [isBooted]);

  // Run MCP logs typing sequence when tab enters 'mcp'
  useEffect(() => {
    let kickoffTimer: number | undefined;

    if (activeTab === 'mcp') {
      kickoffTimer = window.setTimeout(() => {
        startMcpSimulation();
      }, 0);
    } else {
      if (activeSequenceRef.current) {
        clearTimeout(activeSequenceRef.current);
      }
    }
    return () => {
      if (kickoffTimer !== undefined) {
        clearTimeout(kickoffTimer);
      }
      if (activeSequenceRef.current) {
        clearTimeout(activeSequenceRef.current);
      }
    };
  }, [activeTab, startMcpSimulation]);

  return (
    <section id="demo" style={{
      paddingBlock: '6.5rem',
      backgroundColor: 'rgba(255, 255, 255, 0.01)',
      borderBlock: '1px solid var(--border-subtle)'
    }}>
      <div className="container">
        {/* Header */}
        <div style={{
          textAlign: 'center',
          maxWidth: '650px',
          marginInline: 'auto',
          marginBottom: '4.5rem'
        }}>
          <h2 style={{ marginBottom: '1.2rem', letterSpacing: '-0.02em' }}>
            Experience the Command HUD
          </h2>
          <p style={{ fontSize: '1.05rem', color: 'var(--text-grey)', lineHeight: '1.6' }}>
            Interact with the actual DevBar controller options on the left to boot runtimes, mock coordinate overlays, or inject FCM JSON push payloads on the right.
          </p>
        </div>

        {/* Deck Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '3.5rem',
          alignItems: 'center'
        }}>
          {/* Left panel controller */}
          <div className="glass-card" style={{
            padding: '2.5rem',
            textAlign: 'left',
            boxSizing: 'border-box'
          }}>
            {/* Header Tabs */}
            <div style={{
              display: 'flex',
              gap: '0.4rem',
              borderBottom: '1px solid var(--border-subtle)',
              paddingBottom: '1rem',
              marginBottom: '2rem',
              overflowX: 'auto'
            }}>
              {(['devices', 'gps', 'push', 'mcp'] as TabType[]).map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  style={{
                    backgroundColor: activeTab === tab ? 'var(--accent-cobalt-glow)' : 'transparent',
                    border: 'none',
                    borderRadius: '6px',
                    color: activeTab === tab ? 'var(--text-ivory)' : 'var(--text-grey)',
                    padding: '0.5rem 0.9rem',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.4rem',
                    transition: 'all 0.2s',
                    outline: 'none',
                    whiteSpace: 'nowrap'
                  }}
                >
                  {tab === 'devices' && <Laptop size={14} />}
                  {tab === 'gps' && <Map size={14} />}
                  {tab === 'push' && <Bell size={14} />}
                  {tab === 'mcp' && <Bot size={14} />}
                  {tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
              ))}
            </div>

            {/* Tab Body Content */}
            <div style={{ minHeight: '340px' }}>
              {/* Tab 1: Devices */}
              {activeTab === 'devices' && (
                <div style={{ animation: 'fadeIn 0.3s ease' }}>
                  <h3 style={{ marginBottom: '0.5rem' }}>Platform Runtimes</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-grey)', marginBottom: '2rem' }}>
                    Launch, shutdown, and control active simulators and AVD emulators instantly.
                  </p>

                  <div style={{ marginBottom: '2rem' }}>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem', fontWeight: 600 }}>
                      DEVICE POWER STATE
                    </label>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      fontFamily: 'var(--font-mono)',
                      fontSize: '0.9rem',
                      fontWeight: 600,
                      color: isBooted ? 'var(--accent-green)' : 'var(--text-grey)',
                      marginBottom: '1rem'
                    }}>
                      {isBooted ? <Wifi size={16} /> : <WifiOff size={16} />}
                      <span>{isBooted ? 'Online (iPhone 15 Pro)' : 'Offline'}</span>
                    </div>

                    <button
                      onClick={() => setIsBooted(!isBooted)}
                      className="btn"
                      style={{
                        width: '100%',
                        backgroundColor: isBooted ? 'var(--accent-hot)' : 'var(--accent-cobalt)',
                        color: 'var(--text-ivory)',
                        fontWeight: 600,
                        border: 'none'
                      }}
                    >
                      {isBooted ? 'Shutdown iPhone 15 Pro' : 'Boot iPhone 15 Simulator'}
                    </button>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.75rem', fontWeight: 600 }}>
                      LIVE preferences.plist SANDBOX
                    </label>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                      <div style={prefRow}>
                        <span style={prefKey}>isUserSubscribed</span>
                        <span style={prefVal}>true</span>
                      </div>
                      <div style={prefRow}>
                        <span style={prefKey}>launchCount</span>
                        <span style={prefVal}>24</span>
                      </div>
                      <div style={prefRow}>
                        <span style={prefKey}>appTheme</span>
                        <span style={prefVal}>matte-dark</span>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Tab 2: GPS */}
              {activeTab === 'gps' && (
                <div style={{ animation: 'fadeIn 0.3s ease' }}>
                  <h3 style={{ marginBottom: '0.5rem' }}>Geofence Mocking</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-grey)', marginBottom: '1.5rem' }}>
                    Spoof coordinate telemetry. Interactive preset pins load instantly.
                  </p>

                  <div style={{ marginBottom: '1.5rem' }}>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem', fontWeight: 600 }}>
                      WORKSPACE LOCATIONS
                    </label>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem' }}>
                      {PRESETS.map((preset) => (
                        <button
                          key={preset.name}
                          onClick={() => handlePresetClick(preset)}
                          style={{
                            backgroundColor: 'rgba(255, 255, 255, 0.02)',
                            border: `1px solid ${preset.isTeam ? 'var(--accent-green)' : 'var(--border-subtle)'}`,
                            borderRadius: '6px',
                            color: preset.isTeam ? 'var(--accent-green)' : 'var(--text-ivory)',
                            padding: '0.4rem 0.75rem',
                            fontSize: '0.75rem',
                            cursor: 'pointer',
                            transition: 'all 0.2s'
                          }}
                        >
                          {preset.isTeam ? '🟢 ' : ''}{preset.name}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div style={{ marginBottom: '1.5rem' }}>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem', fontWeight: 600 }}>
                      CUSTOM DEGREES
                    </label>
                    <div style={{ display: 'flex', gap: '0.8rem' }}>
                      <div style={{ flex: 1 }}>
                        <input
                          type="text"
                          value={inputLat}
                          onChange={(e) => setInputLat(e.target.value)}
                          style={inputField}
                          placeholder="Latitude"
                        />
                      </div>
                      <div style={{ flex: 1 }}>
                        <input
                          type="text"
                          value={inputLng}
                          onChange={(e) => setInputLng(e.target.value)}
                          style={inputField}
                          placeholder="Longitude"
                        />
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => applyCoordinates(parseFloat(inputLat) || 0, parseFloat(inputLng) || 0)}
                    className="btn"
                    style={{
                      width: '100%',
                      backgroundColor: 'transparent',
                      border: '1px solid var(--accent-cobalt)',
                      color: 'var(--text-ivory)',
                      fontWeight: 600
                    }}
                  >
                    Apply GPS Coordinates
                  </button>
                </div>
              )}

              {/* Tab 3: Push */}
              {activeTab === 'push' && (
                <div style={{ animation: 'fadeIn 0.3s ease' }}>
                  <h3 style={{ marginBottom: '0.5rem' }}>JSON Payload Injections</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-grey)', marginBottom: '1.5rem' }}>
                    Trigger system banners without configuring complex server nodes.
                  </p>

                  <div style={{ marginBottom: '1.25rem' }}>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem', fontWeight: 600 }}>
                      SCENARIO TEMPLATE
                    </label>
                    <select
                      value={pushPreset}
                      onChange={(e) => handlePushPresetChange(e.target.value)}
                      style={{
                        ...inputField,
                        background: '#121215',
                        cursor: 'pointer'
                      }}
                    >
                      <option value="welcome">🎉 Welcome message</option>
                      <option value="transaction">💳 Payment Receipt</option>
                      <option value="geofence">📍 Geofence Notification</option>
                    </select>
                  </div>

                  <div style={{ marginBottom: '1.25rem' }}>
                    <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem', fontWeight: 600 }}>
                      RAW JSON PAYLOAD
                    </label>
                    <textarea
                      value={pushPayload}
                      onChange={(e) => setPushPayload(e.target.value)}
                      style={{
                        ...inputField,
                        height: '110px',
                        resize: 'none',
                        fontSize: '0.75rem',
                        lineHeight: '1.4'
                      }}
                    />
                  </div>

                  <button
                    onClick={handleInjectPush}
                    className="btn"
                    style={{
                      width: '100%',
                      backgroundColor: 'var(--accent-cobalt)',
                      border: 'none',
                      color: 'var(--text-ivory)',
                      fontWeight: 600
                    }}
                  >
                    Inject Push Notification
                  </button>
                </div>
              )}

              {/* Tab 4: MCP */}
              {activeTab === 'mcp' && (
                <div style={{ animation: 'fadeIn 0.3s ease' }}>
                  <div style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.35rem',
                    backgroundColor: 'rgba(0,102,204,0.08)',
                    border: '1px solid rgba(0,102,204,0.2)',
                    color: 'var(--accent-cobalt)',
                    padding: '0.3rem 0.6rem',
                    borderRadius: '4px',
                    fontSize: '0.7rem',
                    fontWeight: 600,
                    marginBottom: '0.85rem'
                  }}>
                    STDIO JSON-RPC 2.0 PROTOCOL
                  </div>
                  <h3 style={{ marginBottom: '0.5rem' }}>AI Agent Automation</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-grey)', marginBottom: '1.2rem' }}>
                    Let Claude or Cursor discover and boot virtual simulators natively.
                  </p>

                  <div style={{
                    backgroundColor: '#070709',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: '8px',
                    padding: '1rem',
                    height: '190px',
                    overflowY: 'auto',
                    fontFamily: 'var(--font-mono)',
                    fontSize: '0.75rem',
                    lineHeight: '1.4',
                    boxSizing: 'border-box'
                  }}>
                    {consoleLogs.map((log, index) => (
                      <div key={index} className={log.class} style={{
                        marginBottom: '0.4rem',
                        whiteSpace: 'pre-wrap',
                        textAlign: 'left'
                      }}>
                        {log.text}
                      </div>
                    ))}
                    <div ref={consoleEndRef} />
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right side: Mock iPhone device */}
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            position: 'relative'
          }}>
            {/* Main Phone frame */}
            <div style={{
              width: '270px',
              height: '540px',
              border: '9px solid #1c1d22',
              borderRadius: '38px',
              backgroundColor: '#000',
              boxShadow: '0 25px 60px rgba(0,0,0,0.8), 0 0 30px rgba(255,255,255,0.01)',
              position: 'relative',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column'
            }}>
              {/* Camera Notch */}
              <div style={{
                width: '100px',
                height: '24px',
                backgroundColor: '#1c1d22',
                borderRadius: '0 0 12px 12px',
                position: 'absolute',
                top: 0,
                left: '50%',
                transform: 'translateX(-50%)',
                zIndex: 20
              }} />

              {/* Push Notification drop down overlay */}
              <div style={{
                position: 'absolute',
                top: '36px',
                left: '10px',
                right: '10px',
                backgroundColor: 'rgba(20, 20, 24, 0.95)',
                border: '1px solid rgba(255,255,255,0.08)',
                borderRadius: '10px',
                padding: '0.65rem 0.8rem',
                display: 'flex',
                gap: '0.6rem',
                boxShadow: '0 10px 25px rgba(0,0,0,0.6)',
                zIndex: 30,
                transform: notification.visible ? 'translateY(0)' : 'translateY(-160%)',
                transition: 'transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
              }}>
                <div style={{
                  width: '18px',
                  height: '18px',
                  borderRadius: '4px',
                  backgroundColor: 'var(--accent-cobalt)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'var(--text-ivory)',
                  fontSize: '0.6rem',
                  fontWeight: 600,
                  flexShrink: 0
                }}>
                  ⚙️
                </div>
                <div style={{ textAlign: 'left' }}>
                  <h4 style={{ fontSize: '0.72rem', margin: '0 0 0.1rem 0', color: 'var(--text-ivory)', fontWeight: 600 }}>{notification.title}</h4>
                  <p style={{ fontSize: '0.62rem', margin: 0, color: 'var(--text-grey)', lineHeight: '1.3' }}>{notification.body}</p>
                </div>
              </div>

              {/* Device Offline Overlay */}
              <div style={{
                position: 'absolute',
                inset: 0,
                backgroundColor: '#09090b',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                zIndex: 10,
                transition: 'opacity 0.4s ease',
                opacity: isBooted ? 0 : 1,
                pointerEvents: isBooted ? 'none' : 'auto',
                gap: '1rem'
              }}>
                <Laptop size={44} style={{ color: 'var(--text-muted)' }} />
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>Device is Offline</span>
              </div>

              {/* Device Screen container */}
              <div style={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                padding: '1.25rem',
                boxSizing: 'border-box'
              }}>
                {/* Status Bar */}
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  fontSize: '0.7rem',
                  color: 'var(--text-grey)',
                  marginTop: '0.3rem',
                  marginBottom: '0.85rem'
                }}>
                  <span>9:41</span>
                  <span style={{ fontWeight: 600, color: 'var(--text-ivory)' }}>iPhone 15 Pro</span>
                  <span>🔋 100%</span>
                </div>

                {/* Map Simulator Application */}
                <div style={{
                  flex: 1,
                  backgroundColor: '#101013',
                  borderRadius: '18px',
                  border: '1px solid rgba(255,255,255,0.05)',
                  display: 'flex',
                  flexDirection: 'column',
                  position: 'relative',
                  overflow: 'hidden'
                }}>
                  <div style={{
                    flex: 1,
                    background: 'radial-gradient(circle at center, #1b2030 0%, #0d0f18 100%)',
                    position: 'relative',
                    overflow: 'hidden'
                  }}>
                    {/* Simulated coordinate grids */}
                    <div style={{
                      position: 'absolute',
                      inset: 0,
                      backgroundImage: 'linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)',
                      backgroundSize: '16px 16px'
                    }} />

                    {/* Geofence target marker pin */}
                    <div style={{
                      width: '12px',
                      height: '12px',
                      backgroundColor: 'var(--accent-cobalt)',
                      border: '2px solid var(--text-ivory)',
                      borderRadius: '50%',
                      boxShadow: '0 0 12px var(--accent-cobalt)',
                      position: 'absolute',
                      left: `${coords.x}%`,
                      top: `${coords.y}%`,
                      transform: 'translate(-50%, -50%)',
                      transition: 'all 0.6s cubic-bezier(0.16, 1, 0.3, 1)'
                    }}>
                      <div style={{
                        position: 'absolute',
                        top: '50%',
                        left: '50%',
                        width: '32px',
                        height: '32px',
                        border: '1px solid rgba(0, 102, 204, 0.4)',
                        borderRadius: '50%',
                        animation: 'radarPulse 2s infinite'
                      }} />
                    </div>
                  </div>

                  {/* Telemetry info bar */}
                  <div style={{
                    padding: '0.75rem',
                    background: 'rgba(0,0,0,0.5)',
                    borderTop: '1px solid rgba(255,255,255,0.05)',
                    fontSize: '0.72rem',
                    textAlign: 'center'
                  }}>
                    <span style={{ display: 'block', fontSize: '0.6rem', textTransform: 'uppercase', color: 'var(--text-grey)', marginBottom: '0.15rem' }}>
                      SPOOFED GPS COORDINATES
                    </span>
                    <code style={{ color: 'var(--accent-cobalt)', fontWeight: 600 }}>
                      {coords.lat.toFixed(4)}° N, {coords.lng.toFixed(4)}° W
                    </code>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// Custom styles
const prefRow: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
  padding: '0.5rem 0.75rem',
  backgroundColor: 'rgba(255, 255, 255, 0.01)',
  border: '1px solid var(--border-subtle)',
  borderRadius: '6px'
};

const prefKey: React.CSSProperties = {
  fontFamily: 'var(--font-mono)',
  fontSize: '0.75rem',
  color: 'var(--text-grey)'
};

const prefVal: React.CSSProperties = {
  fontFamily: 'var(--font-mono)',
  fontSize: '0.75rem',
  color: 'var(--accent-cobalt)',
  fontWeight: 600
};

const inputField: React.CSSProperties = {
  backgroundColor: 'rgba(0, 0, 0, 0.2)',
  border: '1px solid var(--border-subtle)',
  borderRadius: '6px',
  padding: '0.55rem 0.75rem',
  color: 'var(--text-ivory)',
  fontFamily: 'var(--font-sans)',
  fontSize: '0.85rem',
  width: '100%',
  boxSizing: 'border-box',
  outline: 'none'
};
