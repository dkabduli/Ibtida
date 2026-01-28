# Ibtida 🕌

Ibtida is a **native iOS application** built with SwiftUI that encourages consistent prayer, intentional worship, and charitable giving. The app allows users to track daily prayers, build streaks, earn credits, and convert those credits into donations for verified non-profit organizations — all within a calm, minimal, faith-focused experience.

---

## 🌟 Purpose

Ibtida (meaning *“a beginning”*) exists to bring together two essential acts of worship:
- **Prayer (Salah)** — through consistency and awareness
- **Charity (Sadaqah)** — through accessible, transparent giving

By combining prayer tracking with a credit-based donation system, Ibtida helps users turn intention into action and build meaningful spiritual habits from the ground up.

---

## ✨ Core Features (MVP)

- Email & password authentication
- Daily prayer tracking (5 daily prayers)
- Weekly prayer overview with visual status indicators:
  - 🟢 Green — prayed on time  
  - 🔴 Red — prayed late  
  - ⚫ Black — missed  
- Prayer streaks and credit accumulation
- Qibla compass with prayer times
- Donation hub with verified charities
- Donate using credits or card (card payments stubbed in v1)
- Community dua wall (anonymous or public)
- Light & dark mode support
- User profile, donation receipts, and settings

---

## 💎 Credits & Points System

Ibtida uses a **credit-based system** to track prayer consistency and enable charitable giving. Credits are earned through daily prayer tracking and can be converted into real donations.

### 📊 Earning Credits

Credits are earned based on how you log your prayers:

| Prayer Status | Credits Earned |
|--------------|----------------|
| **On Time** (prayed within valid time) | **10 credits** |
| **Late** (prayed after valid time but still completed) | **6 credits** |
| **Qada** (made up a missed prayer) | **4 credits** |
| **Missed** (not prayed) | **0 credits** |
| **Not Logged** | **0 credits** |

#### Special Cases:

- **Brothers - Prayed at Masjid**: **15 credits** (extra reward for congregational prayer)
- **Sisters - Prayed at Home**: **10 credits** (standard on-time credit)
- **Sisters - Menstrual Period**: **0 credits** (not applicable, does not break streak)

### 📈 Daily Maximum

- **Maximum credits per day**: **50 credits** (5 prayers × 10 credits each)
- Credits are calculated automatically when you log your prayer status
- Your total credits accumulate over time and are stored in your profile

### 🎯 Milestones & Journey Progression

As you earn credits, you progress through spiritual milestones:

| Milestone | Arabic Name | Required Credits |
|-----------|-------------|------------------|
| Getting Started | البداية | 0 |
| Consistent | مواظب | 100 |
| Steady | ثابت | 250 |
| Committed | ملتزم | 500 |
| Devoted | متفاني | 1,000 |
| Elite | متميز | 2,500 |
| Master | خبير | 5,000 |
| Legend | أسطورة | 10,000 |

### 💰 Converting Credits to Donations

Credits can be converted into real monetary donations:

- **Conversion Rate**: **100 credits = $1.00 USD**
- **Minimum Conversion**: 10 credits required
- Convert any amount of your earned credits to donate to verified charities
- Credits are deducted from your total when converted
- Conversion requests are tracked in your donation history

**Example:**
- 500 credits = $5.00 donation
- 1,000 credits = $10.00 donation
- 5,000 credits = $50.00 donation

### 🔄 How It Works

1. **Track Your Prayers**: Log each of the 5 daily prayers with their status
2. **Earn Credits**: Credits are automatically calculated and added to your total
3. **View Progress**: See your credit balance and milestone progress in the Home tab
4. **Convert & Donate**: Choose a charity and convert credits to make a donation
5. **Track Impact**: View your donation history and receipts

### ⚠️ Important Notes

- **Credits are personal tracking scores** to motivate consistency
- They do **NOT** represent actual religious reward (hasanat) from Allah
- Credits are stored securely in your Firestore user profile
- Credits persist across app sessions and devices
- Menstrual periods (sisters) do not break your streak or reduce your credits

---

## 📱 Navigation

Ibtida uses a **5-tab layout**:

1. **Home** — Prayer tracking, weekly overview, credit summary  
2. **Dua** — View and submit community duas  
3. **Qibla** — Qibla direction and prayer times  
4. **Donate** — Browse charities and donate credits or money  
5. **Settings** — Profile, receipts, preferences, logout  

A settings icon is accessible from all primary screens.
