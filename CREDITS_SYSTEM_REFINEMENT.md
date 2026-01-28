# Credits System Refinement - Implementation Summary

## Overview

The credits system has been fully refined to:
1. **Encourage new users** with bonus credits in their first 14 days
2. **Reward consistent users** with streak-based multipliers (but require longer streaks)
3. **Highlight differences** between brothers and sisters with distinct credit paths
4. **Balance the economy** to prevent going bankrupt

---

## 🎯 New User Bonus System

### First 14 Days: 1.5x Multiplier
- **New users** (first 14 days after account creation) get a **50% bonus** on all credits
- This encourages early engagement and helps users build momentum
- Example: 50 base credits → **75 credits** with new user bonus

### After 14 Days: Streak-Based System
- New user bonus expires after 14 days
- Users then transition to streak-based multipliers
- Requires maintaining a streak to earn bonuses

---

## 📈 Streak-Based Multipliers (For Consistent Users)

Consistent users need **longer streaks** but get **bigger bonuses**:

| Streak Length | Multiplier | Bonus |
|---------------|------------|-------|
| 0-6 days | 1.0x | No bonus |
| 7-14 days | 1.1x | +10% |
| 15-29 days | 1.2x | +20% |
| 30-59 days | 1.3x | +30% |
| 60-89 days | 1.4x | +40% |
| 90-179 days | 1.5x | +50% |
| 180+ days | 1.6x | +60% |

**Minimum streak required**: 7 days to unlock any bonus

---

## 👨‍🦱 Brothers - Distinct Credit Path

### Base Credits (Brothers):
- **On Time**: 10 credits
- **Late**: 6 credits
- **Qada** (Made up): 4 credits
- **Missed**: 0 credits
- **Prayed at Masjid**: **18 credits** (increased from 15) - Extra reward for congregation

### Streak Bonuses (Brothers):
- **15+ day streak**: +3 credits per day
- **30+ day streak**: +5 credits per day

### Maximum Daily Credits (Brothers):
- Base: 5 prayers × 18 = **90 credits** (if all at masjid)
- With 180+ day streak: 90 × 1.6 = **144 credits** + 5 bonus = **149 credits/day**

---

## 👩‍🦰 Sisters - Distinct Credit Path

### Base Credits (Sisters):
- **On Time**: 10 credits
- **Late**: 6 credits
- **Qada** (Made up): 4 credits
- **Missed**: 0 credits
- **Prayed at Home**: **12 credits** (increased from 10) - Encourages consistency
- **Menstrual Period**: 0 credits (does not break streak)

### Streak Bonuses (Sisters):
- **15+ day streak**: +2 credits per day
- **30+ day streak**: +4 credits per day

### Maximum Daily Credits (Sisters):
- Base: 5 prayers × 12 = **60 credits** (if all at home)
- With 180+ day streak: 60 × 1.6 = **96 credits** + 4 bonus = **100 credits/day**

---

## 💰 Credit Examples

### New User (First 14 Days) - Brother:
- All 5 prayers on time at masjid: 90 base × 1.5 = **135 credits/day**
- All 5 prayers on time: 50 base × 1.5 = **75 credits/day**

### New User (First 14 Days) - Sister:
- All 5 prayers on time at home: 60 base × 1.5 = **90 credits/day**
- All 5 prayers on time: 50 base × 1.5 = **75 credits/day**

### Consistent User (30+ Day Streak) - Brother:
- All 5 prayers at masjid: 90 base × 1.3 = 117 + 5 bonus = **122 credits/day**
- All 5 prayers on time: 50 base × 1.3 = **65 credits/day**

### Consistent User (30+ Day Streak) - Sister:
- All 5 prayers at home: 60 base × 1.3 = 78 + 4 bonus = **82 credits/day**
- All 5 prayers on time: 50 base × 1.3 = **65 credits/day**

---

## ⚖️ Economic Balance

### Why This System Works:

1. **New Users Get Encouraged**:
   - 1.5x multiplier for first 14 days helps them build initial credits
   - Makes the app feel rewarding from day one

2. **Consistent Users Need Longer Streaks**:
   - Must maintain 7+ day streak to unlock bonuses
   - Longer streaks (30+, 60+, 90+ days) required for bigger bonuses
   - Prevents easy credit accumulation

3. **Gender Differences Highlighted**:
   - Brothers: Higher masjid credits (18 vs 12) + bigger streak bonuses
   - Sisters: Consistent home prayer credits (12) + different streak bonuses
   - Each path is balanced but distinct

4. **Prevents Bankruptcy**:
   - New user bonus expires after 14 days
   - Consistent users must maintain long streaks
   - Conversion rate remains 100 credits = $1.00
   - System scales appropriately

---

## 🔄 Credit Calculation Flow

1. **Calculate Base Credits**: Sum of all 5 prayer statuses
2. **Apply New User Bonus** (if account age ≤ 14 days): Multiply by 1.5x
3. **OR Apply Streak Multiplier** (if streak ≥ 7 days): Multiply by streak multiplier
4. **Add Gender-Specific Streak Bonus** (if streak ≥ 15 days): Add bonus credits
5. **Final Credits**: Base × Multiplier + Bonus

---

## 📊 Implementation Details

### Files Updated:
- `Core/CreditRules.swift` - Complete rewrite with new bonus system
- `Models/PrayerModels.swift` - Updated to use new credit calculation
- `ViewModels/HomePrayerViewModel.swift` - Loads profile data and applies bonuses
- `Models/Prayer.swift` - Updated xpValue to use CreditRules

### Key Functions:
- `CreditRules.calculateFinalCredits()` - Main calculation with all bonuses
- `CreditRules.isNewUser()` - Checks if in bonus period
- `CreditRules.streakMultiplier()` - Returns multiplier based on streak
- `CreditRules.brotherStreakBonus()` / `sisterStreakBonus()` - Gender-specific bonuses
- `PrayerDay.recalculateCredits()` - Applies bonuses to prayer day

---

## ✅ Benefits

1. **Encourages New Users**: 1.5x bonus makes early experience rewarding
2. **Rewards Consistency**: Long streaks unlock bigger bonuses
3. **Highlights Gender Differences**: Brothers and sisters have distinct paths
4. **Balanced Economy**: Prevents easy credit accumulation, maintains conversion rate
5. **Motivates Long-Term Engagement**: Streak system encourages daily consistency

---

## 🎮 User Experience

### New User Journey:
- Day 1-14: Earn 1.5x credits (encouraged to build habit)
- Day 15+: Transition to streak system (must maintain consistency)

### Consistent User Journey:
- Week 1: Build 7-day streak to unlock 1.1x multiplier
- Week 2-4: Maintain 15+ day streak for 1.2x + gender bonus
- Month 1+: Unlock 1.3x multiplier + bigger gender bonus
- Month 2+: Unlock 1.4x multiplier
- Month 3+: Unlock 1.5x multiplier
- Month 6+: Unlock 1.6x multiplier (maximum)

---

## 🔐 Important Notes

- Credits are **personal tracking scores** to motivate consistency
- They do **NOT** represent actual religious reward (hasanat) from Allah
- System is designed to encourage good habits, not create pressure
- Menstrual periods (sisters) do not break streaks or reduce credits
- All bonuses are applied automatically - users just track their prayers
