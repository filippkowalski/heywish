# Web Onboarding Testing Guide

## Overview

The web onboarding flow has been implemented to match the mobile app experience. New users without a username are automatically redirected to `/onboarding` after signing in with Google or Apple.

## Test Scenarios

### 1. New User Sign-Up (Google)

**Steps:**
1. Go to the home page
2. Click "Sign In"
3. Click "Continue with Google"
4. Sign in with a **NEW** Google account (not previously used with Jinnie)
5. Verify you're redirected to `/onboarding`

**Expected Flow:**
1. **Step 1: Shopping Interests**
   - [ ] See 12 category chips with emojis
   - [ ] Can select multiple categories
   - [ ] Selected categories change color and show checkmark
   - [ ] "Continue" button is enabled when at least 1 selected
   - [ ] "Skip for now" button works
   - [ ] Selected count shows at bottom

2. **Step 2: Profile Details**
   - [ ] Birthday date picker is shown
   - [ ] Can't select dates less than 13 years ago
   - [ ] Gender options (4 buttons) are shown
   - [ ] Must select both birthday and gender to continue
   - [ ] "Back" button returns to shopping interests
   - [ ] Progress dots show (2 filled, 2 empty)

3. **Step 3: Username**
   - [ ] Username field prefills from email (if available)
   - [ ] "@" symbol shows in field
   - [ ] Input auto-converts to lowercase
   - [ ] Real-time validation shows error messages
   - [ ] After 500ms of no typing, availability check runs
   - [ ] "Checking availability..." message appears
   - [ ] If available: Green checkmark + "Available!" message
   - [ ] If taken: Red X + "Username is already taken" + suggestions
   - [ ] Can click suggestions to auto-fill
   - [ ] "Complete" button only enabled when available
   - [ ] Shows loading spinner when submitting
   - [ ] Progress dots show (3 filled, 1 empty)

4. **Step 4: Completion**
   - [ ] Success icon (green circle with checkmark)
   - [ ] Welcome message
   - [ ] Profile link shown: `jinnie.app/[username]`
   - [ ] "Copy" button copies link to clipboard
   - [ ] Toast notification shows "Profile link copied!"
   - [ ] Shows selected interests count
   - [ ] "Go to Home" button redirects to `/`
   - [ ] All 4 progress dots are filled

### 2. New User Sign-Up (Apple)

**Steps:**
Same as Google test but use "Continue with Apple"

**Additional Checks:**
- [ ] Apple sign-in popup appears
- [ ] After sign-in, redirects to onboarding
- [ ] Username prefills from Apple ID email (if available)

### 3. Existing User Sign-In

**Steps:**
1. Sign in with an account that already has a username
2. Verify you're **NOT** redirected to onboarding
3. Verify you land on home page

### 4. Username Validation Edge Cases

**Test these usernames:**

| Username | Expected Result |
|----------|----------------|
| `ab` | Error: "Must be at least 3 characters" |
| `abc` | Valid (if available) |
| `ABC` | Auto-converts to `abc` |
| `user name` | Error: "Cannot contain spaces" |
| `user@name` | Error: "Only lowercase letters, numbers, periods, underscores" |
| `user.name` | Valid (if available) |
| `user_name` | Valid (if available) |
| `.username` | Error: "Cannot start or end with a period" |
| `username.` | Error: "Cannot start or end with a period" |
| `user..name` | Error: "Cannot have consecutive periods" |
| `verylongusernamethatexceedsthirtychars` | Error: "Must be 30 characters or less" |

### 5. Back Button Navigation

**Steps:**
1. Start onboarding
2. Select interests → Continue
3. Click "Back" → Should return to interests with selections preserved
4. Continue to profile details
5. Enter birthday and gender → Continue
6. Click "Back" → Should return to profile with data preserved

### 6. Data Persistence

**Steps:**
1. Start onboarding
2. Select 3 shopping interests
3. Enter birthday and gender
4. Start typing username
5. Refresh the page (⌘+R / Ctrl+R)
6. Verify you're still on onboarding page
7. **Note:** Data will NOT persist across refresh (expected behavior)

### 7. Direct URL Access

**Test A - Authenticated User Without Username:**
1. Sign in as new user
2. Complete onboarding up to username step
3. Open new tab
4. Go directly to `https://yoursite.com/` (not `/onboarding`)
5. Verify you're redirected back to `/onboarding`

**Test B - Authenticated User With Username:**
1. Sign in as existing user (with username)
2. Try to access `/onboarding` directly
3. Verify you're redirected to home page

**Test C - Unauthenticated User:**
1. Sign out
2. Try to access `/onboarding` directly
3. Verify you're redirected to home page

### 8. Mobile Responsiveness

**Test on mobile devices or browser dev tools:**
- [ ] iPhone SE (375px width)
- [ ] iPhone 12 Pro (390px width)
- [ ] iPad (768px width)
- [ ] Desktop (1280px width)

**Check:**
- [ ] Category grid adjusts (2 cols on mobile, 3 on desktop)
- [ ] Buttons are full width on mobile
- [ ] Text is readable
- [ ] Touch targets are adequate (minimum 44px)

### 9. Error Handling

**Network Errors:**
1. Open Dev Tools → Network tab
2. Set throttling to "Offline"
3. Try to check username availability
4. Verify error message: "Network error. Please try again."
5. Re-enable network
6. Verify it works again

**Backend Errors:**
1. Try to submit with a username that's already taken (bypass frontend check by editing HTML)
2. Verify backend returns error
3. Verify error is displayed to user

### 10. API Integration

**Check Network Tab:**
1. Open Dev Tools → Network tab
2. Start onboarding
3. Type username
4. Verify you see: `GET /jinnie/v1/auth/check-username/[username]`
5. Wait 500ms after typing
6. Verify response shows `{ "username": "...", "available": true/false }`
7. Complete onboarding
8. Verify you see: `PATCH /jinnie/v1/users/profile`
9. Verify request body contains:
   ```json
   {
     "username": "...",
     "birthdate": "YYYY-MM-DD",
     "gender": "...",
     "shopping_interests": [...]
   }
   ```

## Common Issues & Solutions

### Issue: Not redirected to onboarding after sign-in
**Solution:** Check browser console for errors. Verify `backendUser` doesn't have a username.

### Issue: Username check shows "checking" forever
**Solution:** Check Network tab for failed API calls. Verify backend is running.

### Issue: Can't proceed past username step
**Solution:** Verify username is marked as "Available!" (green). Check console for errors.

### Issue: Profile link copy doesn't work
**Solution:** Check browser permissions for clipboard access. Some browsers block this in dev environments.

### Issue: Styling looks broken
**Solution:** Verify Tailwind CSS is building properly. Check for any CSS errors in console.

## Database Verification

After completing onboarding, verify in database:

```sql
SELECT
  id,
  username,
  birthdate,
  gender,
  shopping_interests,
  created_at
FROM users
WHERE firebase_uid = '[firebase_uid]';
```

**Expected:**
- `username` is set
- `birthdate` is in YYYY-MM-DD format
- `gender` is one of: male, female, other, prefer_not_to_say
- `shopping_interests` is JSON array of strings

## Performance Checks

- [ ] Username check debounces properly (only fires 500ms after stop typing)
- [ ] Page transitions are smooth
- [ ] No visual layout shifts
- [ ] Images/emojis load quickly
- [ ] No console errors or warnings

## Accessibility Checks

- [ ] Can navigate with keyboard (Tab key)
- [ ] Enter key submits forms
- [ ] Focus indicators are visible
- [ ] Form labels are associated with inputs
- [ ] Error messages are announced to screen readers

## Sign-Off Checklist

Before marking onboarding as "production ready":

- [ ] All test scenarios pass
- [ ] Tested on Chrome, Safari, Firefox
- [ ] Tested on mobile devices (iOS + Android)
- [ ] No console errors
- [ ] API calls succeed
- [ ] Database updates correctly
- [ ] Loading states work
- [ ] Error states work
- [ ] Back button works
- [ ] Progress indicators update correctly
- [ ] Copy to clipboard works
- [ ] Redirects work as expected
