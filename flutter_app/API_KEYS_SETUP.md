# 🔑 API Keys Setup for Image Retrieval

## Current Status

### ✅ **Working Right Now (No Setup Needed)**
- **Unsplash Source API** - Provides free, high-quality images without any API key
- Your app is fully functional with Unsplash alone!

### ⚠️ **Optional Enhancement (Better Quality)**
- **Pexels API** - Requires free API key (optional but recommended)

---

## 📋 How It Works Currently

When loading destination images, the system tries in this order:

1. ✅ **Firestore `imageUrl`** - If you've manually added image URLs
2. ✅ **Firestore `images` array** - If you've added an images array
3. ✅ **Unsplash API** - **WORKS NOW** (no key needed)
4. ⚠️ **Pexels API** - Skipped (no key configured)

**Result:** You'll see beautiful Unsplash images for all destinations! 🎉

---

## 🚀 Optional: Add Pexels API (Recommended)

Pexels provides **better image selection** and **higher quality** than Unsplash Source API.

### Benefits:
- ✅ More relevant images (better search algorithm)
- ✅ Higher resolution options
- ✅ 200 free requests per hour
- ✅ Better control over image selection

### Setup Steps (5 minutes):

**1. Get Free API Key:**
   ```
   Visit: https://www.pexels.com/api/
   Click: "Get Started" → Sign up (free)
   Copy your API key
   ```

**2. Add to `.env` file:**
   ```env
   # Open: flutter_app/.env
   # Add this line:
   PEXELS_API_KEY=your_actual_api_key_here
   ```

**3. Restart your app:**
   ```bash
   flutter run
   ```

**That's it!** The service will now use Pexels as a fallback if Unsplash fails.

---

## 🔍 How to Verify It's Working

### Check Console Logs:

**With Unsplash only:**
```
📸 Fetching from Unsplash: Taj Mahal monument India
✅ Unsplash image found for Taj Mahal monument India
```

**With Pexels configured:**
```
📸 Fetching from Unsplash: Taj Mahal monument India
⚠️ Unsplash fetch error: [some error]
📸 Fetching from Pexels: Taj Mahal India
✅ Pexels image found for Taj Mahal India
```

**With Pexels key missing:**
```
⚠️ Pexels API key not configured - skipping
```

---

## 📊 API Comparison

| Source | Setup | Quality | Rate Limit | Cost |
|--------|-------|---------|------------|------|
| **Unsplash Source** | ✅ None | ⭐⭐⭐⭐ | ~50/hour | Free |
| **Pexels** | 🔑 API Key | ⭐⭐⭐⭐⭐ | 200/hour | Free |

---

## ❓ FAQs

### Q: Do I need Pexels to make images work?
**A:** No! Unsplash works without any setup. Pexels is just an optional enhancement.

### Q: What if I don't add Pexels key?
**A:** No problem! The app will use Unsplash and work perfectly fine.

### Q: How do I know which API is being used?
**A:** Check the console logs when destinations load. You'll see messages like:
   - `✅ Unsplash image found`
   - `✅ Pexels image found`

### Q: Can I use both Unsplash and Pexels?
**A:** Yes! The system tries Unsplash first, then falls back to Pexels if needed.

### Q: What about rate limits?
**A:** 
- Unsplash Source: ~50 requests/hour
- Pexels: 200 requests/hour
- Images are cached for 24 hours to minimize API calls

---

## 🎯 Recommended Setup

### For Development/Testing:
```
✅ Use Unsplash (current setup)
❌ Skip Pexels
```

### For Production:
```
✅ Add image URLs to Firestore (best quality & control)
✅ Add Pexels API key (fallback for new destinations)
✅ Keep Unsplash (final fallback)
```

---

## 🔧 Advanced: Add Your Own Images

The **best** approach is to add image URLs directly to Firestore:

```javascript
// Firestore destination document
{
  "id": "taj_mahal_001",
  "title": "Taj Mahal",
  "subtitle": "Agra, Uttar Pradesh",
  
  // Add these:
  "imageUrl": "https://your-cdn.com/taj-mahal.jpg",
  "images": [
    "https://your-cdn.com/taj-1.jpg",
    "https://your-cdn.com/taj-2.jpg",
    "https://your-cdn.com/taj-3.jpg"
  ]
}
```

**Benefits:**
- ✅ Full control over images
- ✅ No API rate limits
- ✅ Consistent quality
- ✅ Works offline (when cached)

---

## ✨ Summary

**Current Status:** ✅ **Fully Working**
- Images load via Unsplash (no setup needed)
- Beautiful, relevant photos appear automatically
- 24-hour caching for fast performance

**Optional Enhancement:** Add Pexels key for even better images

**You're all set! Just run your app and enjoy the images! 🎉**
