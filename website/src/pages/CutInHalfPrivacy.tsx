function CutInHalfPrivacy() {
  return (
    <div className="page-container">
      <h1 className="page-title">Cut in Half — Privacy Policy</h1>
      <div className="page-content">
        <p><strong>Last Updated:</strong> {new Date().toLocaleDateString()}</p>

        <h2>Introduction</h2>
        <p>
          This Privacy Policy explains how the <strong>Cut in Half</strong> game ("the Game",
          "we", "us", or "our") collects, uses, and protects your information when you play.
          Cut in Half is a puzzle game where you progress through different levels. By
          downloading or playing the Game, you agree to the practices described in this policy.
        </p>

        <h2>Information We Collect</h2>

        <h3>1. Google Account Information</h3>
        <p>
          The Game offers the option to sign in with your Google account. When you choose to
          sign in with Google, we receive the following information from Google:
        </p>
        <ul>
          <li><strong>Name:</strong> Your display name, used to personalize your profile.</li>
          <li><strong>Email address:</strong> Used to identify your account and sync your progress.</li>
          <li><strong>Profile picture:</strong> Your Google profile photo, shown in the Game (where applicable).</li>
          <li><strong>Google account identifier:</strong> A unique ID used to securely link the Game to your account.</li>
        </ul>
        <p>
          Signing in with Google is optional. You can play the Game without signing in, though
          some features such as cloud-saved progress and leaderboards may not be available.
        </p>

        <h3>2. Gameplay Data</h3>
        <ul>
          <li><strong>Level progress:</strong> Which levels you have unlocked, completed, and your scores or stars.</li>
          <li><strong>Game settings:</strong> Your preferences such as sound, music, and other in-game options.</li>
          <li><strong>Achievements and statistics:</strong> Progress milestones and gameplay statistics.</li>
        </ul>

        <h3>3. Information Collected Automatically</h3>
        <ul>
          <li><strong>Device information:</strong> Device type, operating system version, and unique device identifiers.</li>
          <li><strong>Crash and performance data:</strong> Diagnostic information to help us fix bugs and improve stability.</li>
          <li><strong>Usage data:</strong> How you interact with the Game, such as session length and features used.</li>
        </ul>

        <h2>How We Use Your Information</h2>
        <p>We use the information we collect to:</p>
        <ul>
          <li>Authenticate you and create or access your account</li>
          <li>Save and sync your level progress across devices</li>
          <li>Personalize your in-game experience</li>
          <li>Maintain, improve, and develop new levels and features</li>
          <li>Diagnose crashes and fix technical issues</li>
          <li>Protect against fraud, abuse, and security threats</li>
          <li>Comply with legal obligations</li>
        </ul>

        <h2>Information Sharing and Disclosure</h2>
        <p>
          <strong>We do NOT sell, rent, or trade your personal information.</strong> We only
          share information in the following limited circumstances:
        </p>
        <ul>
          <li><strong>Service Providers:</strong> We use trusted third-party services (such as
          Google Firebase) for authentication, cloud storage, analytics, and crash reporting.
          These providers process data on our behalf and are obligated to protect it.</li>
          <li><strong>Legal Requirements:</strong> We may disclose information if required by law
          or to protect our rights, users, or the public.</li>
          <li><strong>Business Transfers:</strong> If we are involved in a merger or acquisition,
          information may be transferred as part of that transaction.</li>
        </ul>

        <h2>Google Sign-In and Third-Party Services</h2>
        <p>
          When you sign in with Google, the use of information received from Google APIs adheres
          to the Google API Services User Data Policy, including its Limited Use requirements. We
          only request the minimum access needed to authenticate you and provide the Game's
          features. We do not use Google account data for advertising.
        </p>

        <h2>Data Security</h2>
        <p>
          We implement industry-standard security measures to protect your information, including
          encryption of data in transit and secure cloud storage. However, no method of
          transmission or storage is 100% secure, and we cannot guarantee absolute security.
        </p>

        <h2>Data Retention</h2>
        <p>
          We retain your account and gameplay data for as long as your account is active. You may
          request deletion of your account and associated data at any time through our{' '}
          <a href="/delete-account-cut-in-half">Delete Account</a> page, after which your data
          will be permanently removed from our systems.
        </p>

        <h2>Children's Privacy</h2>
        <p>
          Cut in Half is not directed at children under the age of 13 (or the minimum age
          required in your jurisdiction). We do not knowingly collect personal information from
          children. If you believe a child has provided us with personal information, please
          contact us so we can delete it.
        </p>

        <h2>Your Rights and Choices</h2>
        <p>Depending on your location, you may have the right to:</p>
        <ul>
          <li>Access the personal information we hold about you</li>
          <li>Correct inaccurate information</li>
          <li>Request deletion of your account and personal data</li>
          <li>Revoke the Game's access to your Google account at any time via your Google account settings</li>
          <li>Disable optional permissions in your device settings</li>
        </ul>

        <h2>Changes to This Privacy Policy</h2>
        <p>
          We may update this Privacy Policy from time to time. We will notify you of significant
          changes by updating the "Last Updated" date above. We encourage you to review this
          policy periodically.
        </p>

        <h2>Contact Us</h2>
        <p>
          If you have any questions about this Privacy Policy or our data practices, please
          contact us:
        </p>
        <p>
          📧 Email: byteberg18@gmail.com
        </p>
      </div>
    </div>
  );
}

export default CutInHalfPrivacy;
