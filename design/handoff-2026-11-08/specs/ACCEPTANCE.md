# Builder acceptance checklist

These checks are requirements for the future native build, not assertions that packaging ran them.

## Baseline and regression

- Build supplied/reconciled Xcode project; resolve existing packages, keep signing/environment boundaries. Run iOS tests and API npm check/test from the native baseline instructions.
- All42review routes plus community subpages and studio states are accessible through real app navigation. Back/close/dismiss returns to right destination; free exit works.
- Real Scripture preserved across translation, long verse/chapter, offline reads, likes/saves/bookmarks/notes, related verses and restored position. No fixture replacement or hard-coded user attendance.
- Home Notes contains Bible-entered note; edit/delete/relaunch synchronization. Bookmarks distinct from saved verses. Home begins verse ofday then devotional. Avatar/settings and streak alignment match.
- Discover submenu pins, search/filter/saved rows work, contextual art and title metrics match. Bible menu shows actual translucency with content behind it; safe areas reach edges without clipped backgrounds.
- Community dark/light matches current screenshot, correct filled three-personnav, gear/saved header. Vote/cancel/change/closed/offline flows; cause/suggestion validation, edit, confirmation and real server state.

## Onboarding

- Run all14screens in sequence plus guest, skipped/empty, Back, long names/Unicode, all comparison/familiarity/season/heart/pace branches. Max3heart choices, private season exclusion, first-letter normalization, deterministic prayer cases.
- Record acknowledgement->question transitions: no overlap, layoutjump, early options/CTA or disappearing words. Page2Continue waits through bridge+flower. Prayer fullyreveals beforeCTA. Hold speech/release/Back cancel correctly.
- Reminder time visible when off; on save request native prompt once if needed. Denied/provisional/granted and change-time cases; actual notification text/style scheduling. Complete flow persists preferences without unwanted reset.
- ReduceMotion toggled before and midflow, appbackground, keyboard resize, fastBack/Next and interruption cancel tasks safely. Haptics calibrated on physicaliPhone, no continuous buzz.

## Studios/widget

- Separate drafts/stores and selected verses. Each background/font/ink/format, custom two/threecolor/intensity/direction, photoorientation/HEIC, shade/crop/replacement/missingphoto; longverse never truncated.
- Add/remove up to6art layers; accurate drag/onehandhandle/pinch/rotate/remainingfingercontinuity, snapguides,48pttargets, slider alternatives. Tray detents don't move artwork coordinates.
- Dirty Save/Discard/Keep editing, Reset draft, relaunch, theme, rotation, storagefailure preserve work. ExportedPNG exact1080×1440/1080×1080/1080×1920 with correct signature; no controls/guides, no double share.
- Widget all3families, chosenvsdaily, AppGroupimageaccess, restart/offline/dayrollover, timeline reload and deep link. Save cannot pretend to install. Verify actual widget fullcolor/tinted/accented output on device.

## System, commerce and launch

- Purewhite/pureblack/System themes allpages; correct native status/home areas. Compact andlargeiPhone/iPad, portrait/landscape as supported, largerDynamicType, VoiceOver, keyboard, contrast andReduceMotion. Content can scroll foraccessibility; don't shrink text to force an arbitrary fit.
- Icon4options/defaultwhite, selectedring/tick, realalternateiconAPI, error state. Profilephoto andaccount actions never trigger onboarding.
- StoreKit/Superwall eligibility/localizedprice/trial/ineligible/restore/pending/cancel/fail/grace/expired, verification and safe free reading. No false nopayment message on nontrial monthly.
- Freshreturning launchlight/dark/System, warmresume(noanimation), pendingroutebypass, incomingroutecancel, backgroundcancel, missingassetfallback, ReduceMotion, rootreconstruction. Actualapprovedlogo finalframe;2.4send bound independentofnetwork.
- Releasebuild measured frame pacing/memory on slowest supporteddevice; record majorflows atfullspeed and inspect frames. Return evidence/changedfiles and unresolveddecisions; do notmark untested items passed.
