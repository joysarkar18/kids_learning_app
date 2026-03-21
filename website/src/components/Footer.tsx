import { Link } from 'react-router-dom';

function Footer() {
  return (
    <footer className="footer">
      <div className="footer-content">
        <div className="footer-section">
          <h3>🎈 বর্ণমালা AI</h3>
          <p>An educational and entertaining app designed for children to learn and play in a safe environment.</p>
        </div>
        <div className="footer-section">
          <h3>Quick Links</h3>
          <ul className="footer-links">
            <li><Link to="/">Home</Link></li>
            <li><Link to="/terms">Terms & Conditions</Link></li>
            <li><Link to="/privacy">Privacy Policy</Link></li>
          </ul>
        </div>
        <div className="footer-section">
          <h3>Contact</h3>
          <p>For any inquiries or support, please contact us at:</p>
          <p>📧 byteberg18@gmail.com</p>
        </div>
      </div>
      <div className="footer-bottom">
        <p>&copy; {new Date().getFullYear()} বর্ণমালা AI. All rights reserved.</p>
      </div>
    </footer>
  );
}

export default Footer;
