import { useState, useEffect } from 'react';
import { Sparkles, Laptop, Map, Wrench, RefreshCw, Power } from 'lucide-react';

type StepType =
  | 'idle'
  | 'pan-to-menu'
  | 'click-menu'
  | 'pan-to-boot'
  | 'booting'
  | 'pan-to-gps-tab'
  | 'click-gps-tab'
  | 'pan-to-berlin'
  | 'spoof-berlin'
  | 'pan-to-tools-tab'
  | 'click-tools-tab'
  | 'pan-to-push'
  | 'inject-push'
  | 'pan-to-screenshot'
  | 'screenshot-flash'
  | 'reset';

export default function Hero() {
  const [step, setStep] = useState<StepType>('idle');
  const [hudOpen, setHudOpen] = useState(false);
  const [hudTab, setHudTab] = useState<'devices' | 'gps' | 'tools'>('devices');
  const [phoneBooted, setPhoneBooted] = useState(false);

  // Geofence coordinate states
  const [coords, setCoords] = useState({ lat: 37.7749, lng: -122.4194, x: 28, y: 55 });
  const [activePreset, setActivePreset] = useState<string>('SF');

  // Simulated Cursor and Flash states
  const [cursorPos, setCursorPos] = useState({ x: 50, y: 70, opacity: 0 });
  const [screenshotFlash, setScreenshotFlash] = useState(false);
  const [pushVisible, setPushVisible] = useState(false);

  const setMapPin = (p: { lat: number, lng: number, x: number, y: number }) => {
    setCoords(p);
  };

  useEffect(() => {
    let timer: number;

    const runWorkflow = () => {
      // Step 0: Initial State - Phone is Offline, HUD is closed
      setStep('idle');
      setHudOpen(false);
      setHudTab('devices');
      setPhoneBooted(false);
      setMapPin({ lat: 37.7749, lng: -122.4194, x: 28, y: 55 });
      setActivePreset('SF');
      setPushVisible(false);
      setCursorPos({ x: 50, y: 70, opacity: 0 });

      // Step 1: Cursor pans to macOS Menu Bar icon on the top right
      timer = window.setTimeout(() => {
        setStep('pan-to-menu');
        setCursorPos({ x: 88, y: 5, opacity: 1 });
      }, 1500);

      // Step 2: Click Menu Bar Icon - Popover HUD opens directly below the icon
      timer = window.setTimeout(() => {
        setStep('click-menu');
        setHudOpen(true);
      }, 2800);

      // Step 3: Pan cursor to "Boot" action on the iOS Simulator row
      timer = window.setTimeout(() => {
        setStep('pan-to-boot');
        setCursorPos({ x: 83, y: 35, opacity: 1 });
      }, 4000);

      // Step 4: Boot device - Simulator turns Online on the left side of the desktop
      timer = window.setTimeout(() => {
        setStep('booting');
        setPhoneBooted(true);
      }, 4800);

      // Step 5: Pan cursor to "GPS Mock" bottom tab button
      timer = window.setTimeout(() => {
        setStep('pan-to-gps-tab');
        setCursorPos({ x: 74, y: 88, opacity: 1 });
      }, 6000);

      // Step 6: Click GPS tab
      timer = window.setTimeout(() => {
        setStep('click-gps-tab');
        setHudTab('gps');
      }, 6800);

      // Step 7: Pan cursor to "🟢 Berlin Lab" preset geofence pill
      timer = window.setTimeout(() => {
        setStep('pan-to-berlin');
        setCursorPos({ x: 78, y: 41, opacity: 1 });
      }, 7800);

      // Step 8: Click Berlin geofence preset - map pans on the floating phone
      timer = window.setTimeout(() => {
        setStep('spoof-berlin');
        setActivePreset('Berlin');
        setMapPin({ lat: 52.5200, lng: 13.4050, x: 68, y: 30 });
      }, 8600);

      // Step 9: Pan cursor to "Tools" bottom tab button
      timer = window.setTimeout(() => {
        setStep('pan-to-tools-tab');
        setCursorPos({ x: 86, y: 88, opacity: 1 });
      }, 9800);

      // Step 10: Click Tools tab
      timer = window.setTimeout(() => {
        setStep('click-tools-tab');
        setHudTab('tools');
      }, 10500);

      // Step 11: Pan cursor to "Inject Notification" action in Tools
      timer = window.setTimeout(() => {
        setStep('pan-to-push');
        setCursorPos({ x: 81, y: 44, opacity: 1 });
      }, 11500);

      // Step 12: Inject Push - Notification banner drops down on the floating phone
      timer = window.setTimeout(() => {
        setStep('inject-push');
        setPushVisible(true);
      }, 12300);

      // Step 13: Pan cursor to "Take Screenshot" in Tools
      timer = window.setTimeout(() => {
        setStep('pan-to-screenshot');
        setCursorPos({ x: 81, y: 64, opacity: 1 });
      }, 13500);

      // Step 14: Trigger Screenshot Flash over the simulator screen
      timer = window.setTimeout(() => {
        setStep('screenshot-flash');
        setScreenshotFlash(true);
      }, 14300);

      timer = window.setTimeout(() => {
        setScreenshotFlash(false);
      }, 14600);

      // Restart loop
      timer = window.setTimeout(() => {
        setStep('reset');
        setPushVisible(false);
        runWorkflow();
      }, 18000);
    };

    runWorkflow();

    return () => {
      clearTimeout(timer);
    };
  }, []);

  return (
    <section style={{
      position: 'relative',
      paddingTop: '9rem',
      paddingBottom: '6rem',
      overflow: 'hidden',
      textAlign: 'center'
    }}>
      <div className="ambient-glow" style={{ top: '-15%', left: '50%', transform: 'translateX(-50%)' }} />

      <div className="container">
        {/* Release badge */}
        <div style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '0.45rem',
          backgroundColor: 'rgba(255, 255, 255, 0.03)',
          border: '1px solid var(--border-subtle)',
          color: 'var(--text-ivory)',
          padding: '0.35rem 0.9rem',
          borderRadius: '999px',
          fontSize: '0.8rem',
          fontWeight: 500,
          marginBottom: '2rem',
          boxShadow: '0 2px 10px rgba(0,0,0,0.2)'
        }}>
          <Sparkles size={13} style={{ color: 'var(--accent-gold)' }} />
          <span style={{ color: 'var(--text-grey)' }}>Approved Setup:</span>
          <span>Sleek macOS Menu-Bar HUD</span>
        </div>

        <h1 style={{
          maxWidth: '850px',
          marginInline: 'auto',
          marginBottom: '1.5rem',
          letterSpacing: '-0.02em',
          lineHeight: '1.1'
        }}>
          Mac Menu Bar Command Deck<br />
          <span style={{
            background: 'linear-gradient(to right, var(--text-ivory), #a3a3a3)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>
            for iOS & Android Runtimes
          </span>
        </h1>

        <p style={{
          maxWidth: '650px',
          marginInline: 'auto',
          fontSize: '1.15rem',
          lineHeight: '1.6',
          color: 'var(--text-grey)',
          marginBottom: '2.5rem'
        }}>
          DevBar lives strictly inside your macOS Menu Bar. Click the icon to drop down
          the vertically-stacked HUD. Control boot states, set geofence coordinates,
          and mock JSON FCM payloads across separate, floating device simulators.
        </p>

        <div style={{
          display: 'flex',
          justifyContent: 'center',
          gap: '1rem',
          marginBottom: '4.5rem'
        }}>
          <a href="#pricing" className="btn btn-primary">
            Get Started — $19
          </a>
          <a href="#demo" className="btn btn-secondary">
            See Live HUD Demo
          </a>
        </div>

        {/* --- SHARP ANIMATED MACOS DESKTOP SHOWCASE --- */}
        <div style={{
          maxWidth: '1000px',
          marginInline: 'auto',
          position: 'relative',
          borderRadius: '16px',
          backgroundColor: '#050507',
          border: '1px solid rgba(255, 255, 255, 0.08)',
          boxShadow: '0 30px 100px rgba(0, 0, 0, 0.95)',
          overflow: 'hidden',
          aspectRatio: '16 / 9',
          display: 'flex',
          flexDirection: 'column'
        }}>

          {/* Simulated macOS Menu Bar (Top row) */}
          <div style={{
            height: '28px',
            backgroundColor: 'rgba(18, 18, 20, 0.96)',
            borderBottom: '1px solid rgba(255, 255, 255, 0.06)',
            paddingInline: '1.25rem',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: '0.75rem',
            color: 'var(--text-ivory)',
            position: 'relative',
            zIndex: 50
          }}>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <span style={{ fontWeight: 600, fontSize: '0.85rem' }}></span>
              <span style={{ fontWeight: 500 }}>File</span>
              <span style={{ fontWeight: 500 }}>Edit</span>
              <span style={{ fontWeight: 500 }}>Device</span>
              <span style={{ fontWeight: 500 }}>Window</span>
              <span style={{ fontWeight: 500, color: 'var(--text-grey)' }}>Help</span>
            </div>

            {/* Menu Bar Status Triggers (Right hand) */}
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <span>9:41 AM</span>
              <span>🔋 100%</span>

              {/* DevBar Menu Tray Icon (Trigger) */}
              <div
                style={{
                  width: '26px',
                  height: '18px',
                  borderRadius: '4px',
                  backgroundColor: hudOpen ? 'var(--accent-cobalt)' : 'rgba(255, 255, 255, 0.05)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '0.65rem',
                  fontFamily: 'var(--font-mono)',
                  fontWeight: 600,
                  color: 'var(--text-ivory)',
                  transition: 'background-color 0.2s',
                  animation: step === 'pan-to-menu' ? 'pulseMenuIcon 1.5s infinite' : 'none'
                }}
              >
                &gt;_
              </div>
            </div>
          </div>

          {/* Desktop Wallpaper Space */}
          <div style={{
            flex: 1,
            background: 'radial-gradient(ellipse at bottom, #111422 0%, #060608 100%)',
            position: 'relative',
            padding: '1.5rem',
            boxSizing: 'border-box'
          }}>

            {/* 1. REALISTIC FLOATING COGNITIVE PHONE SIMULATOR (On the left) */}
            <div style={{
              position: 'absolute',
              left: '12%',
              top: '50%',
              transform: 'translateY(-50%)',
              transition: 'all 0.5s cubic-bezier(0.16, 1, 0.3, 1)',
              opacity: phoneBooted ? 1 : 0.4,
              zIndex: 10
            }}>
              {/* Simulator Title Window bar */}
              <div style={{
                backgroundColor: '#1b1b22',
                border: '1px solid rgba(255,255,255,0.06)',
                borderRadius: '8px 8px 0 0',
                padding: '0.35rem 0.75rem',
                fontSize: '0.65rem',
                fontFamily: 'var(--font-mono)',
                color: 'var(--text-grey)',
                textAlign: 'left',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                width: '180px'
              }}>
                <span>iPhone 15 Pro</span>
                <div style={{ display: 'flex', gap: '3px' }}>
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#ff5f56' }} />
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#ffbd2e' }} />
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#27c93f' }} />
                </div>
              </div>

              {/* iPhone device body */}
              <div style={{
                width: '180px',
                height: '350px',
                border: '6px solid #1a1a20',
                borderTop: 'none',
                borderRadius: '0 0 24px 24px',
                backgroundColor: '#000',
                boxShadow: '0 20px 50px rgba(0,0,0,0.6)',
                position: 'relative',
                overflow: 'hidden',
                display: 'flex',
                flexDirection: 'column'
              }}>
                {/* Mock screenshot camera flash overlay */}
                <div style={{
                  position: 'absolute',
                  inset: 0,
                  backgroundColor: '#fff',
                  zIndex: 35,
                  opacity: screenshotFlash ? 0.85 : 0,
                  pointerEvents: 'none',
                  transition: 'opacity 0.15s ease'
                }} />

                {/* Simulated Push drop down overlay */}
                <div style={{
                  position: 'absolute',
                  top: '16px',
                  left: '6px',
                  right: '6px',
                  backgroundColor: 'rgba(20, 20, 24, 0.96)',
                  border: '1px solid rgba(255,255,255,0.08)',
                  borderRadius: '6px',
                  padding: '0.4rem 0.5rem',
                  display: 'flex',
                  gap: '0.35rem',
                  boxShadow: '0 8px 20px rgba(0,0,0,0.6)',
                  zIndex: 30,
                  transform: pushVisible ? 'translateY(0)' : 'translateY(-150%)',
                  transition: 'transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
                }}>
                  <div style={{
                    width: '10px',
                    height: '10px',
                    borderRadius: '2px',
                    backgroundColor: 'var(--accent-cobalt)',
                    color: '#fff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '0.4rem',
                    flexShrink: 0
                  }}>⚙️</div>
                  <div style={{ textAlign: 'left' }}>
                    <h5 style={{ fontSize: '0.5rem', margin: '0 0 0.02rem 0', color: '#fff', fontWeight: 600 }}>Welcome to DevBar!</h5>
                    <p style={{ fontSize: '0.45rem', margin: 0, color: 'var(--text-grey)', lineHeight: '1.2' }}>Unified iOS & Android simulator controls.</p>
                  </div>
                </div>

                {/* Device offline screen */}
                <div style={{
                  position: 'absolute',
                  inset: 0,
                  backgroundColor: '#09090b',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  zIndex: 10,
                  opacity: phoneBooted ? 0 : 1,
                  transition: 'opacity 0.35s ease',
                  gap: '0.4rem'
                }}>
                  <Laptop size={24} style={{ color: 'var(--text-muted)' }} />
                  <span style={{ fontSize: '0.6rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>Device Offline</span>
                </div>

                {/* Active Phone map content */}
                <div style={{
                  flex: 1,
                  display: 'flex',
                  flexDirection: 'column',
                  padding: '0.65rem',
                  boxSizing: 'border-box'
                }}>
                  <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    fontSize: '0.5rem',
                    color: 'var(--text-grey)',
                    marginBottom: '0.45rem'
                  }}>
                    <span>9:41</span>
                    <span style={{ fontWeight: 600 }}>iPhone 15 Pro</span>
                    <span>🔋 100%</span>
                  </div>

                  {/* Simulated App Frame */}
                  <div style={{
                    flex: 1,
                    backgroundColor: '#121216',
                    borderRadius: '10px',
                    border: '1px solid rgba(255,255,255,0.04)',
                    display: 'flex',
                    flexDirection: 'column',
                    overflow: 'hidden',
                    position: 'relative'
                  }}>
                    <div style={{
                      flex: 1,
                      background: 'radial-gradient(circle at center, #1b2030 0%, #0d0f18 100%)',
                      position: 'relative',
                      overflow: 'hidden'
                    }}>
                      <div style={{
                        position: 'absolute',
                        inset: 0,
                        backgroundImage: 'linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)',
                        backgroundSize: '10px 10px'
                      }} />

                      {/* Map Coordinate Marker Dot */}
                      <div style={{
                        width: '6px',
                        height: '6px',
                        backgroundColor: 'var(--accent-cobalt)',
                        border: '1px solid #fff',
                        borderRadius: '50%',
                        position: 'absolute',
                        left: `${coords.x}%`,
                        top: `${coords.y}%`,
                        transform: 'translate(-50%, -50%)',
                        boxShadow: '0 0 10px var(--accent-cobalt)',
                        transition: 'all 0.75s cubic-bezier(0.16, 1, 0.3, 1)'
                      }}>
                        <div style={{
                          position: 'absolute',
                          top: '50%',
                          left: '50%',
                          width: '18px',
                          height: '18px',
                          border: '1px solid rgba(0, 102, 204, 0.4)',
                          borderRadius: '50%',
                          animation: 'radarPulse 2s infinite'
                        }} />
                      </div>
                    </div>

                    <div style={{
                      padding: '0.35rem',
                      background: 'rgba(0,0,0,0.5)',
                      borderTop: '1px solid rgba(255,255,255,0.05)',
                      fontSize: '0.5rem',
                      textAlign: 'center'
                    }}>
                      <code style={{ color: 'var(--accent-cobalt)', fontWeight: 600 }}>
                        {coords.lat.toFixed(4)}° N, {coords.lng.toFixed(4)}° W
                      </code>
                    </div>
                  </div>
                </div>

              </div>
            </div>

            {/* 2. MATHEMATICALLY PRECISE 360x500px DEVBAR POPOVER HUD (Positioned under the trigger icon) */}
            <div style={{
              position: 'absolute',
              right: '30px',
              top: '8px',
              width: '260px', /* scaled proportionally from 360px for presentation space */
              height: '360px', /* scaled proportionally from 500px for presentation space */
              transform: hudOpen ? 'translateY(0)' : 'translateY(-15px)',
              opacity: hudOpen ? 1 : 0,
              pointerEvents: hudOpen ? 'auto' : 'none',
              transition: 'all 0.35s cubic-bezier(0.16, 1, 0.3, 1)',
              backgroundColor: 'rgba(21, 21, 26, 0.95)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              backdropFilter: 'blur(20px)',
              WebkitBackdropFilter: 'blur(20px)',
              borderRadius: '10px',
              boxShadow: '0 20px 60px rgba(0, 0, 0, 0.7), inset 0 1px 0 rgba(255,255,255,0.05)',
              zIndex: 30,
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              boxSizing: 'border-box',
              overflow: 'hidden'
            }}>

              {/* Main View Popover Layout: Header */}
              <div style={{
                padding: '0.75rem 0.9rem',
                borderBottom: '1px solid rgba(255,255,255,0.06)',
                backgroundColor: 'rgba(255,255,255,0.01)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
              }}>
                <div style={{ textAlign: 'left' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '3px' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 900, fontFamily: 'var(--font-heading)', color: '#fff' }}>DevBar</span>
                    <div style={{ width: '4px', height: '4px', borderRadius: '50%', backgroundColor: 'var(--accent-cobalt)' }} />
                  </div>
                  <span style={{ fontSize: '0.55rem', fontWeight: 'bold', color: 'var(--text-grey)', textTransform: 'uppercase', tracking: '0.5px' } as React.CSSProperties}>
                    Simulator Command Deck
                  </span>
                </div>

                {/* Power and Refresh indicators */}
                <div style={{ display: 'flex', gap: '0.4rem' }}>
                  {phoneBooted && (
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '3px',
                      backgroundColor: 'rgba(16, 185, 129, 0.1)',
                      border: '1px solid rgba(16, 185, 129, 0.2)',
                      borderRadius: '100px',
                      padding: '2px 6px',
                      color: 'var(--accent-green)',
                      fontSize: '0.55rem',
                      fontWeight: 'bold'
                    }}>
                      <div style={{ width: '3px', height: '3px', borderRadius: '50%', backgroundColor: 'var(--accent-green)' }} />
                      <span>1 active</span>
                    </div>
                  )}
                  <div style={circleBtnIcon}><RefreshCw size={9} /></div>
                  <div style={circleBtnIcon}><Power size={9} /></div>
                </div>
              </div>

              {/* Central Switchboard based on Active Tab */}
              <div style={{ flex: 1, padding: '0.9rem', boxSizing: 'border-box', overflowY: 'auto' }}>
                {/* 2.1 Tab: Devices */}
                {hudTab === 'devices' && (
                  <div style={{ animation: 'fadeIn 0.25s ease', textAlign: 'left' }}>
                    {/* Compact Filter buttons */}
                    <div style={{ display: 'flex', gap: '3px', marginBottom: '0.75rem' }}>
                      <span style={miniPlatformFilter}>All</span>
                      <span style={{ ...miniPlatformFilter, backgroundColor: 'transparent', color: 'var(--text-grey)' }}>iOS</span>
                      <span style={{ ...miniPlatformFilter, backgroundColor: 'transparent', color: 'var(--text-grey)' }}>Android</span>
                    </div>

                    {/* Exact Device Row replicating DeviceRowView.swift */}
                    <div style={{
                      backgroundColor: 'rgba(255,255,255,0.02)',
                      border: '1px solid rgba(255,255,255,0.06)',
                      borderRadius: '6px',
                      padding: '0.55rem 0.65rem',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center'
                    }}>
                      <div style={{ textAlign: 'left' }}>
                        <h4 style={{ fontSize: '0.75rem', fontWeight: 600, color: '#fff', margin: '0 0 1px 0' }}>iPhone 15 Pro</h4>
                        <span style={{ fontSize: '0.55rem', color: 'var(--text-grey)' }}>iOS 17.4 • iOS Simulator</span>
                      </div>

                      {/* State trigger button */}
                      <button
                        style={{
                          backgroundColor: phoneBooted ? 'var(--accent-hot)' : 'var(--accent-cobalt)',
                          border: 'none',
                          borderRadius: '4px',
                          color: '#fff',
                          padding: '3px 8px',
                          fontSize: '0.62rem',
                          fontWeight: 700,
                          cursor: 'pointer'
                        }}
                      >
                        {phoneBooted ? 'Shutdown' : 'Boot'}
                      </button>
                    </div>
                  </div>
                )}

                {/* 2.2 Tab: GPS Mock */}
                {hudTab === 'gps' && (
                  <div style={{ animation: 'fadeIn 0.25s ease', textAlign: 'left' }}>
                    <span style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.35rem', fontWeight: 600 }}>
                      TEAM COORDINATES MOCK
                    </span>

                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', marginBottom: '0.75rem' }}>
                      <span style={{
                        ...miniGpsPill,
                        borderColor: activePreset === 'SF' ? 'var(--accent-cobalt)' : 'rgba(255,255,255,0.05)',
                        color: activePreset === 'SF' ? 'var(--text-ivory)' : 'var(--text-grey)'
                      }}>San Francisco</span>
                      <span style={{
                        ...miniGpsPill,
                        borderColor: activePreset === 'Berlin' ? 'var(--accent-green)' : 'rgba(16,185,129,0.2)',
                        color: activePreset === 'Berlin' ? 'var(--text-ivory)' : 'var(--accent-green)'
                      }}>🟢 Berlin Lab</span>
                    </div>

                    <div style={{ display: 'flex', gap: '0.4rem' }}>
                      <input type="text" value={coords.lat.toFixed(4)} disabled style={miniInputField} />
                      <input type="text" value={coords.lng.toFixed(4)} disabled style={miniInputField} />
                    </div>
                  </div>
                )}

                {/* 2.3 Tab: Tools */}
                {hudTab === 'tools' && (
                  <div style={{ animation: 'fadeIn 0.25s ease', textAlign: 'left' }}>
                    <span style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.45rem', fontWeight: 600 }}>
                      DEVELOPER QUICK PLUGS
                    </span>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                      <button style={mockActionBtn}>
                        <span>Inject FCM Push Notification</span>
                      </button>
                      <button style={mockActionBtn}>
                        <span>📸 Capture Clipboard Screenshot</span>
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* Popover Tab Bar Selector Dock */}
              <div style={{
                height: '32px',
                borderTop: '1px solid rgba(255,255,255,0.06)',
                display: 'flex',
                alignItems: 'center',
                paddingInline: '0.5rem',
                backgroundColor: 'rgba(255,255,255,0.005)'
              }}>
                <button
                  onClick={() => setHudTab('devices')}
                  style={{
                    ...tabBtnStyle,
                    color: hudTab === 'devices' ? 'var(--text-ivory)' : 'var(--text-grey)',
                    backgroundColor: hudTab === 'devices' ? 'rgba(255,255,255,0.04)' : 'transparent'
                  }}
                >
                  <Laptop size={10} />
                  <span>Devices</span>
                </button>
                <button
                  onClick={() => setHudTab('gps')}
                  style={{
                    ...tabBtnStyle,
                    color: hudTab === 'gps' ? 'var(--text-ivory)' : 'var(--text-grey)',
                    backgroundColor: hudTab === 'gps' ? 'rgba(255,255,255,0.04)' : 'transparent'
                  }}
                >
                  <Map size={10} />
                  <span>GPS Mock</span>
                </button>
                <button
                  onClick={() => setHudTab('tools')}
                  style={{
                    ...tabBtnStyle,
                    color: hudTab === 'tools' ? 'var(--text-ivory)' : 'var(--text-grey)',
                    backgroundColor: hudTab === 'tools' ? 'rgba(255,255,255,0.04)' : 'transparent'
                  }}
                >
                  <Wrench size={10} />
                  <span>Tools</span>
                </button>
              </div>

            </div>

            {/* Simulated Animated Mouse Pointer */}
            <div style={{
              position: 'absolute',
              left: `${cursorPos.x}%`,
              top: `${cursorPos.y}%`,
              width: '12px',
              height: '16px',
              opacity: cursorPos.opacity,
              pointerEvents: 'none',
              zIndex: 100,
              transition: 'left 0.9s cubic-bezier(0.25, 0.8, 0.25, 1), top 0.9s cubic-bezier(0.25, 0.8, 0.25, 1), opacity 0.3s ease',
              display: 'flex',
              alignItems: 'flex-start'
            }}>
              <svg width="12" height="16" viewBox="0 0 12 16" fill="none">
                <path d="M0 0V15.2L4.3 10.9H11.2L0 0Z" fill="#0066cc" stroke="#ffffff" strokeWidth="1.5" />
              </svg>
            </div>

          </div>
        </div>

      </div>
    </section>
  );
}

// Sub styling configurations
const circleBtnIcon: React.CSSProperties = {
  width: '18px',
  height: '18px',
  borderRadius: '50%',
  backgroundColor: 'rgba(255,255,255,0.03)',
  border: '1px solid rgba(255,255,255,0.05)',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  color: 'var(--text-grey)'
};

const miniPlatformFilter: React.CSSProperties = {
  fontSize: '0.55rem',
  fontWeight: 'bold',
  padding: '2px 8px',
  borderRadius: '4px',
  backgroundColor: 'rgba(255,255,255,0.06)',
  border: '1px solid rgba(255,255,255,0.03)',
  color: 'var(--text-ivory)'
};

const miniGpsPill: React.CSSProperties = {
  fontSize: '0.55rem',
  padding: '3px 6px',
  borderRadius: '4px',
  border: '1px solid rgba(255,255,255,0.05)',
  display: 'inline-block',
  cursor: 'pointer'
};

const miniInputField: React.CSSProperties = {
  width: '100%',
  backgroundColor: 'rgba(0,0,0,0.2)',
  border: '1px solid rgba(255,255,255,0.05)',
  borderRadius: '4px',
  color: 'var(--text-ivory)',
  fontFamily: 'var(--font-mono)',
  fontSize: '0.65rem',
  padding: '4px 6px',
  boxSizing: 'border-box',
  outline: 'none'
};

const mockActionBtn: React.CSSProperties = {
  width: '100%',
  backgroundColor: 'rgba(255,255,255,0.02)',
  border: '1px solid rgba(255,255,255,0.05)',
  borderRadius: '6px',
  padding: '6px 8px',
  color: 'var(--text-ivory)',
  fontSize: '0.62rem',
  fontWeight: 600,
  textAlign: 'left',
  cursor: 'pointer'
};

const tabBtnStyle: React.CSSProperties = {
  flex: 1,
  height: '22px',
  border: 'none',
  borderRadius: '4px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  gap: '3px',
  fontSize: '0.58rem',
  fontWeight: 700,
  cursor: 'pointer',
  outline: 'none',
  transition: 'all 0.2s'
};
