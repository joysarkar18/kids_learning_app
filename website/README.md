# Kids App Website

A modern React-based website for the Kids App, built with React, TypeScript, and Vite.

## Features

- **Home Page**: Showcases app features, benefits, and information
- **Terms & Conditions**: Comprehensive legal terms for app usage
- **Privacy Policy**: Detailed privacy policy including permission explanations

## Tech Stack

- React 18
- TypeScript
- React Router (for navigation)
- Vite (build tool)
- CSS3 with animations

## Project Structure

```
website/
├── src/
│   ├── components/
│   │   ├── Header.tsx      # Navigation header
│   │   └── Footer.tsx      # Site footer
│   ├── pages/
│   │   ├── Home.tsx                    # Home page
│   │   ├── TermsAndConditions.tsx      # Terms page
│   │   └── PrivacyPolicy.tsx           # Privacy policy page
│   ├── App.tsx             # Main app component
│   ├── main.tsx            # Entry point
│   └── index.css           # Global styles
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Getting Started

### Installation

```bash
cd website
npm install
```

### Development

Run the development server:

```bash
npm run dev
```

The site will be available at `http://localhost:5173`

### Build

Create a production build:

```bash
npm run build
```

The built files will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Pages

### Home Page
- Hero section with call-to-action buttons
- Features grid showcasing app capabilities
- About section with app information

### Terms & Conditions Page
- Acceptance of terms
- Service description
- User eligibility
- Parental controls
- Account management
- Acceptable use policy
- Content guidelines
- In-app purchases
- Liability and warranties

### Privacy Policy Page
- Information collection details
- Permission explanations (storage, microphone, camera, etc.)
- Data usage policies
- Information sharing practices
- Children's privacy (COPPA compliance)
- Data security measures
- User rights and choices
- Contact information

## Customization

### Update Contact Information

Edit the following files to update contact details:
- `src/components/Footer.tsx`
- `src/pages/TermsAndConditions.tsx`
- `src/pages/PrivacyPolicy.tsx`

### Modify Features

Edit `src/pages/Home.tsx` to update the features section.

### Styling

All styles are in `src/index.css`. You can modify colors, fonts, and layouts there.

## License

© 2026 Kids App. All rights reserved.
