import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Features from './components/Features';
import SimulatorDeck from './components/SimulatorDeck';
import Pricing from './components/Pricing';
import FAQ from './components/FAQ';
import Footer from './components/Footer';

export default function App() {
  return (
    <>
      <Navbar />
      <Hero />
      <Features />
      <SimulatorDeck />
      <Pricing />
      <FAQ />
      <Footer />
    </>
  );
}
