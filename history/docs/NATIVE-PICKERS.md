# Native selection controls

All dropdowns use HTML select/option elements with platform-owned menus: reader chapter and KJV translation, Home verse search, Settings reading pace and contact/support topic selection. Native appearance, light/dark color scheme, keyboard focus and 44px targets are retained. Form text is at least 16px.

Chapter selection resets the reader to the chosen chapter’s first verse and rebuilds its segmented rail. The previous custom chapter sheet is no longer used by the toolbar. The sample library still contains Genesis 1 and Psalm 23; KJV is the only available translation.

A desktop phone frame does not emulate the iOS system picker. The preview uses the host OS/browser’s native popup; on iOS the browser supplies its native selection UI. No iOS simulator validation was performed.

Browser verified opening chapter selection and selecting Psalm 23 using the keyboard, with the six-verse rail and correct passage displayed. Reader test suite passed.
