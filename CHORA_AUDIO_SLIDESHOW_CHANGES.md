# Chora Audio Player with Background Image

## Overview
Simplified Chora player with **full-screen background image**, **centered lyrics**, and **audio streaming** from Firebase. The design prioritizes text readability with a beautiful background image.

## Changes Made

### 1. Data Model (`chora_model.dart`)

#### Simplified `ChoraModel` Class
- `audioUrl`: Firebase Storage URL for audio file
- `coverImage`: Firebase Storage URL for cover image (shown in list view)
- `backgroundImage`: Firebase Storage URL for full-screen background image
- `text`: Complete lyrics/text (newline separated)
- `order`: Display order
- `duration`: Total audio duration in seconds

**Helper Method:**
- `textLines`: Returns text split into lines (filtered for empty lines)

### 2. Firestore Schema

**Document Structure:**
```javascript
{
  title: "টুকটুকি",
  audio_url: "https://firebasestorage.googleapis.com/.../audios/tuktuki.wav",
  cover_image: "https://firebasestorage.googleapis.com/.../images/tuktuki_cover.jpg",
  background_image: "https://firebasestorage.googleapis.com/.../images/tuktuki_bg.jpg",
  text: "টুক টুক টুক, দরজা খোলো\nকে এসেছে বলো বলো\nছোট্ট একটা পাখি এলো\nগান গেয়ে সে উড়ে গেলো।",
  order: 1,
  duration: 30.0
}
```

### 3. UI/UX Features (`chora_player_view.dart`)

#### Full-Screen Background
- **Background image** covers entire screen
- **Dark gradient overlay** for text readability
- Smooth loading with placeholder gradients

#### Centered Text Display
- **Beautiful typography** with shadows for readability
- **Current line highlighted** in gold color with larger font
- **Animated entrance** for each line
- **Auto-scrolling** to keep current line visible
- **Rounded background** for current line

#### Audio Controls
- **Large center play/pause button** (overlay)
- **Progress bar** with time display
- **Tap to seek** on progress bar
- **Auto-play** when switching chora

#### Navigation
- Previous/Next buttons at bottom
- Retry button replays current chora
- Close button at top

### 4. List View (`chora_list_view.dart`)

#### Cover Image Display
- Uses `coverImage` field from Firestore
- Wooden frame overlay (unchanged)
- Play button overlay

## Firebase Storage Setup

### Required Storage Structure
```
firebase-storage/
├── audios/
│   ├── tuktuki.wav
│   ├── chand_mama.wav
│   ├── khokon.wav
│   └── ghum_parani.wav
└── images/
    ├── tuktuki_cover.jpg
    ├── tuktuki_bg.jpg
    ├── chand_mama_cover.jpg
    ├── chand_mama_bg.jpg
    └── ...
```

### Image Requirements

#### Background Image
- **Aspect Ratio**: 9:16 (portrait) or 16:9 (landscape)
- **Resolution**: Minimum 1080x1920px (for full-screen coverage)
- **Format**: JPG (optimized for photos)
- **Style**: Should not be too busy - text needs to be readable over it

#### Cover Image
- **Aspect Ratio**: 1:1 (square)
- **Resolution**: Minimum 500x500px
- **Format**: JPG or PNG

## How to Add New Chora

1. **Upload audio file** to Firebase Storage (`audios/`)
2. **Upload images** to Firebase Storage (`images/`):
   - 1 cover image (for list view, square)
   - 1 background image (for player, full-screen)
3. **Get download URLs** from Firebase Console
4. **Add to Firestore**:
   ```javascript
   {
     title: "Your Title",
     audio_url: "https://firebasestorage.../audio.wav",
     cover_image: "https://firebasestorage.../cover.jpg",
     background_image: "https://firebasestorage.../bg.jpg",
     text: "Line 1\nLine 2\nLine 3\nLine 4",
     order: 5,
     duration: 25.0
   }
   ```

## Text Formatting

The `text` field supports multi-line text using newline characters (`\n`):

```
"টুক টুক টুক, দরজা খোলো\nকে এসেছে বলো বলো\nছোট্ট একটা পাখি এলো\nগান গেয়ে সে উড়ে গেলো।"
```

Each line will be:
- Displayed separately
- Highlighted individually during playback
- Auto-scrolled into view

## Design Features

### Text Readability
- **Dark gradient overlay** on background image
- **Text shadows** for better contrast
- **Current line highlighting** with gold color
- **Larger font** for active line
- **Subtle background** behind current line

### Visual Hierarchy
1. **Title** - Top, bold white text
2. **Progress bar** - Below title
3. **Lyrics** - Center, scrollable
4. **Play/Pause** - Large center overlay
5. **Navigation** - Bottom buttons

### Animations
- **Fade-in** for each text line
- **Smooth scrolling** to current line
- **Crossfade** for background images
- **Progress bar** updates smoothly

## Testing Checklist

- [ ] Cover images load in list view
- [ ] Background image loads full-screen
- [ ] Audio streams from Firebase URL
- [ ] Text displays centered and readable
- [ ] Current line highlights correctly
- [ ] Auto-scroll works smoothly
- [ ] Progress bar updates and is seekable
- [ ] Play/Pause button works
- [ ] Previous/Next navigation works
- [ ] Text timing syncs with audio

## Migration from Previous Version

If you have existing data with `image_segments`:

### Option 1: Manual Migration
1. Choose/upload a single background image per chora
2. Update Firestore documents with new schema
3. Remove `image_segments` array
4. Add `background_image` field

### Option 2: Keep Both Temporarily
The old model can coexist - just add the new fields:
- `background_image`: Required for new UI
- Keep `image_segments` if needed for backward compatibility

## Best Practices

### Background Images
- Use **subtle, non-distracting** images
- Ensure **good contrast** with white text
- Avoid **busy patterns** or high-contrast areas
- Consider adding a **blur effect** in post-processing

### Text Content
- Keep lines **reasonably short** (10-20 words)
- Use **natural line breaks** (by phrase/meaning)
- Avoid very long paragraphs
- Test readability on different screen sizes

### Audio Files
- Normalize volume levels across choras
- Use consistent format (WAV or MP3)
- Keep file sizes reasonable (< 5MB preferred)
- Test streaming performance

## Future Enhancements

- Add offline download support
- Implement audio caching
- Background audio playback
- Lock screen controls
- Share functionality
- Favorite/bookmark choras
- Download for offline listening
- Adjustable text size
- Multiple background themes
