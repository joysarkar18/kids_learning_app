function Home() {
  return (
    <>
      {/* Hero Section */}
      <section className="hero">
        <h1>Welcome to বর্ণমালা AI! 🎈</h1>
        <p>A safe, educational, and fun app designed to spark curiosity and creativity in children of all ages.</p>
        <div className="hero-buttons">
          <a href="#features" className="btn btn-primary">Explore Features</a>
          <a href="#about" className="btn btn-secondary">Learn More</a>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features">
        <h2>Amazing Features</h2>
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">📚</div>
            <h3>Interactive Stories</h3>
            <p>Engaging stories with beautiful illustrations and audio narration to captivate young minds.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🎵</div>
            <h3>Music & Songs</h3>
            <p>Fun educational songs and melodies that help children learn while having a great time.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🎨</div>
            <h3>Creative Activities</h3>
            <p>Drawing, coloring, and creative exercises to develop artistic skills and imagination.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🧩</div>
            <h3>Educational Games</h3>
            <p>Puzzles and games designed to enhance problem-solving skills and cognitive development.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🔒</div>
            <h3>Safe Environment</h3>
            <p>Child-safe content with parental controls to ensure a secure digital experience.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📊</div>
            <h3>Progress Tracking</h3>
            <p>Monitor your child's learning journey with detailed progress reports and achievements.</p>
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="about">
        <div className="about-content">
          <h2>About বর্ণমালা AI</h2>
          <p>
            বর্ণমালা AI is a comprehensive educational platform designed specifically for children. 
            Our mission is to provide a safe, engaging, and educational digital environment where 
            children can learn, explore, and grow at their own pace.
          </p>
          <p>
            With a team of experienced educators, child psychologists, and developers, we've created 
            an app that combines entertainment with education. Our content is carefully curated to 
            ensure it's age-appropriate, educational, and most importantly, fun!
          </p>
          <p>
            We believe in the power of technology to enhance learning while maintaining the highest 
            standards of child safety and privacy. Our app is designed with input from parents and 
            educators to ensure it meets the needs of modern families.
          </p>
        </div>
      </section>
    </>
  );
}

export default Home;
