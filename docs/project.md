# haffar — Project Understanding

## Overview

**Project:** أبطال المذاكرة التفاعلية (haffar)
**Type:** Mobile-first gamified learning app for Arabic-speaking middle school students
**Platform:** Stitch (TEXT_TO_UI_PRO, MOBILE)
**Visibility:** Private
**Created:** 2026-08-13 | **Last updated:** 2026-08-19
**Total screens:** 85

---

## Design System: "haffar"

### Brand Personality
Energetic, encouraging, and playful — designed specifically for the RTL (Arabic) reading experience.

### Visual Style: Tactile Gamification
- "Squishy" buttons with satisfying press feedback
- 3D-like depth via stacked color layers (tonal extrusion, not realistic shadows)
- High-energy character illustrations
- Candy-like saturated colors

### Color Palette

| Token | Hex | Purpose |
|-------|-----|---------|
| Primary | #58cc02 | Progress, correct answers, "Go" actions |
| Primary Dark | #2b6c00 | Active states, surface tint |
| Secondary | #1cb0f6 (override) | Informational UI, nav headers, new concepts |
| Tertiary | #ff9600 (override) | Energy, streaks, "Hard Mode" challenges |
| Purple | — | Special rewards, "Legendary" status, bonus XP |
| Background | #fbf9f9 | Light warm gray |
| Error | #ba1a1a | Incorrect answers, alerts |
| Surface | #efeded / #e3e2e2 | Cards, containers |

**Depth Logic:** Each color has a ~20% darker "Shadow" variant used for the bottom edge of buttons and containers to create a 3D pressable effect.

### Typography

| Level | Font | Size | Weight | Line Height |
|-------|------|------|--------|-------------|
| Display LG | Be Vietnam Pro | 32px | 800 | 40px |
| Headline MD | Be Vietnam Pro | 24px | 700 | 32px |
| Body LG | Plus Jakarta Sans | 18px | 500 | 26px |
| Body MD | Plus Jakarta Sans | 16px | 400 | 24px |
| Label Bold | Be Vietnam Pro | 14px | 700 | 18px (letter-spacing: 0.05em) |

**RTL Considerations:** Line heights slightly increased for Arabic ascenders/descenders (e.g., جيم, غين).

### Layout & Spacing
- **Model:** Fluid-Fixed Hybrid — single-column flow on mobile, thumb-reach optimized
- **RTL:** All layouts mirrored; progress bars fill right-to-left; speech bubble tails point to characters
- **Stack Rhythm:** Generous vertical spacing; cards use consistent 16px internal padding; word-bank interactions use 8px grid
- **Margin (mobile):** 20px | Gutter: 16px

### Elevation: Tonal Extrusion
- **Active elements:** 4px bottom border in darker shade → looks "thick"
- **Pressed state:** 4px border disappears, element moves down 2px → mechanical press feel
- **Speech bubbles:** 2px light grey outline instead of shadow

### Shapes
- Buttons & Cards: 16px radius (rounded-lg)
- Progress Bars: Fully pill-shaped (rounded-full)
- Word Bank Chips: 12px radius
- Speech Bubbles: rounded-lg with triangular "beak"

---

## Core Components

| Component | Description |
|-----------|-------------|
| **Primary Buttons** | Min-height 52px, extruded 3D bottom, heavy Arabic text |
| **Lesson Paths** | Circular nodes in S-curve; completed = colored, current = pulsing white ring, future = greyed out |
| **Speech Bubbles** | White background, light grey border, pointer/beak directed at character |
| **Progress Bars** | Glossy highlight on top half of fill (liquid/plastic look) |
| **Word Bank Chips** | Selectable tokens; selected state shows grey "ghost" in original slot |
| **Feedback Modals** | Full-width bottom drawers: Correct = green + "Continue"; Incorrect = red + correct solution + "Understood" |

---

## App Flow & Screen Map

### Onboarding & Authentication
| Screen | ID |
|--------|-----|
| شاشة البداية (Splash Screen) | `0a0036f2` |
| مرحبا بك في haffar (Welcome) | `0b0fba06` |
| إنشاء حساب جديد (Sign Up) | `27ccc07e` |
| تسجيل الدخول (Login) | `498a3dd0` |
| تفعيل التنبيهات (Enable Notifications) | `cf6700be` |
| انقطاع الاتصال بالإنترنت (No Internet ×2) | `8631e9ab`, `a872c788` |
| جاري التحميل... (Loading ×2) | `4f206c38`, `5874f425` |

### Core Navigation
| Screen | ID |
|--------|-----|
| الشاشة الرئيسية - رحلة التعلم (Home / Learning Journey) | `e8914a1e` |
| تحديد الهدف التعليمي (Set Learning Goal) | `16d03f48` |
| اختيار المادة (Subject Selection) | `dea3028c` |
| خريطة التعلم - المسار الشامل (Learning Map - Full Path) | `ace7ed09` |

### Subject Lesson Paths
| Subject | Screen | ID |
|---------|--------|-----|
| علوم (Science) | مسار العلوم | `1c343242` |
| رياضيات (Math) | مسار الرياضيات | `bc1f2f30` |
| لغة عربية (Arabic) | مسار اللغة العربية | `46ac1592` |

### Question Types (by subject)

**علوم (Science)**
- سؤال: تعريف المصطلحات (Term Definitions) — `50cf36ef`
- سؤال علوم: المصطلح العلمي (Scientific Term) — `de9f4759`
- سؤال علوم: علل (Explain Why) — `d2388883`
- سؤال علوم: مسألة حسابية (Calculation Problem) — `b336a03f`
- سؤال علوم: الرسم والبيانات (Charts & Data) — `8c092348`
- سؤال علوم: المزاوجة (Matching) — `96510c67`

**رياضيات (Math)**
- سؤال رياضيات: أكمل الفراغ (Fill Blank) — `e0ee767b`
- سؤال رياضيات: اختيار من متعدد (Multiple Choice) — `c52b895c`
- سؤال رياضيات: صواب أم خطأ (True/False) — `9df81edf`
- سؤال رياضيات: خطوات الحل (Solution Steps) — `b9ac4be4`

**لغة عربية (Arabic Language)**
- سؤال: القواعد والنحو (Grammar) — `6d178b9f`
- سؤال: الإملاء والخط (Spelling & Calligraphy) — `d3ec67c5`
- سؤال: معاني الكلمات والمضاد (Word Meanings & Antonyms) — `f99bffeefe`
- سؤال: علامات الترقيم (Punctuation) — `a828163a`
- سؤال: نسب الأبيات لقائلها (Attributing Verses) — `9523fb9a`
- سؤال: البلاغة والأدب (Rhetoric & Literature) — `b1258240`
- سؤال: التعبير والإنشاء (Composition) — `56f8344c`
- سؤال: الفهم والاستيعاب (Comprehension) — `b82a3c5a`
- سؤال: تحويل الجمل (Sentence Transformation) — `fcc8f0de`

**إسلامية (Islamic Studies)**
- سؤال إسلامية: الفقه والسيرة (مقالي) — `6522afde`
- سؤال إسلامية: تكملة الحديث (Hadith Completion) — `d39cf90d`
- سؤال إسلامية: حفظ القرآن (Quran Memorization) — `1d62e1d1`
- سؤال إسلامية: صواب أم خطأ (True/False) — `2efeb99a`
- سؤال إسلامية: معاني الكلمات (Word Meanings) — `6d178b9f` (related)

**تاريخ (History)**
- سؤال تاريخ: ترتيب أحداث (Chronological Ordering) — `3f9082e8`
- سؤال تاريخ: المزاوجة بين الحدث والعام (Event-Year Matching) — `c9447735`

**جغرافيا (Geography)**
- سؤال جغرافيا: الخريطة (Map Reading) — `eaf48b25`
- سؤال: تعريف المصطلحات الجغرافية (Geographic Terms) — `2a9f4bfd`
- سؤال: الخريطة (Map) — `8dfc31d4`

**ICT**
- سؤال ICT: وحدات قياس الذاكرة (Memory Units) — `cd30ae92`
- سؤال ICT: مسارات فنية (حفظ ملف) (Art Paths / Save File) — `b07cf763`
- سؤال ICT: تصنيف المكونات (إدخال وإخراج) (Component Classification I/O) — `8edb0426`

**التربية التقنية (Technical Education)**

**English**
- English: Grammar (Rewrite) — `a5fefe2d`
- English: Grammar (Arabic UI) — `840e5667`
- English: Grammar (Verb Correction) — `27453fa9`
- English: Grammar (Prepositions) — `bd780e61`
- English: Vocabulary (Matching) — `9fc196de`
- English: Vocabulary (Fill Blank) — `13651b43`
- English: Reading Comprehension (T/F) — `9752a6cf`
- English: Reading (Wh- Question) — `d5979a67`
- English: Composition (Paragraph) — `3dd3cb07`
- English: Composition (Arabic UI) — `b1a7008c`

### Feedback Screens
| Screen | ID |
|--------|-----|
| إجابة صحيحة (Correct — with sound) | `f30d07f2` |
| إجابة صحيحة (Correct) | `8225dc75` |
| إجابة خاطئة (Incorrect — with sound) | `3d4596b4` |
| إجابة خاطئة (Incorrect) | `e2ba13d3` |

### Gamification & Social
| Screen | ID |
|--------|-----|
| المتجر - haffar (Shop — final) | `0c42a86c` |
| المتجر - haffar (Shop — alt) | `2db7e99c` |
| جولة إرشادية - المتجر (Shop Walkthrough) | `32ab0a2e` |
| لوحة الصدارة - دوري البرونز (Leaderboard — Bronze League) | `993f8c36` |
| الإنجازات (Achievements) — `ffa53211` |
| المسابقات الأسبوعية (Weekly Competitions) — `6b01be52` |
| البحث عن أصدقاء (Search Friends) — `2988e249` |

### Profile & Settings
| Screen | ID |
|--------|-----|
| الملف الشخصي (Profile) | `c53172ed` |
| الإعدادات (Settings) | `357339e4` |

### Reference / Inspiration
Several screens reference Duolingo iOS as design inspiration:
- `10402861284513442575` — Duolingo iOS Starting a lesson 0
- `10402861284513442693` — Duolingo iOS Starting a lesson 5
- `10402861284513442811` — Duolingo iOS Starting a lesson 29
- `10402861284513442929` — Duolingo iOS Starting a lesson 30
- `10402861284513443047` — Duolingo iOS Starting a lesson 31
- `10402861284513443165` — Duolingo iOS Starting a lesson 32
- `fb9b22e4` — Gamified Learning App Flow
- `d571ccbd` — Educational Gamification Flow

---

## Gamification Systems

### Progression
- **Lesson Paths:** S-curve node arrangement per subject; completed/current/future states
- **Leagues:** Bronze league visible; implies tiered competitive ranking
- **Streaks:** Represented by tertiary orange color
- **XP & Rewards:** Purple reserved for legendary status and bonus XP

### Economy
- **Shop (المتجر):** Virtual goods, avatars, themes — purchasable with earned currency
- **Weekly Competitions (المسابقات الأسبوعية):** Time-limited challenges with rankings

### Feedback Loop
1. User answers a question
2. Correct → green modal + sound → continue
3. Incorrect → red modal + correct answer shown + sound → "Understood" → continue
4. XP/streak/league points awarded

---

## Technical Notes

- **Target Device:** Mobile (390px width standard, some 512px reference screens)
- **RTL-First:** All layouts, progress bars, and text alignment are designed for Arabic RTL from the start
- **Audio:** Feedback screens explicitly reference sound ("مع صوت")
- **Design Inspiration:** Duolingo iOS flow is heavily referenced as UX patterns
- **Reference Images:** Several screens are direct screenshots of Duolingo iOS for flow comparison

---

## Open Questions / Unknowns

1. No HTML code available for some key screens (shop, leaderboard) — may need regeneration
2. Several hidden screens (marked `hidden: true`) not fully explored
3. No detailed user flow diagram between screens yet
4. Gamification economy details (currency name, shop items) not yet specified
5. Leaderboard leagues beyond Bronze not visible yet
