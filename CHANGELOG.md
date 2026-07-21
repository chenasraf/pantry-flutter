# Changelog

## [0.22.0](https://github.com/chenasraf/pantry-flutter/compare/v0.21.0...v0.22.0) (2026-07-21)


### Features

* add a setting to move item actions into a menu instead of swiping ([d39c42b](https://github.com/chenasraf/pantry-flutter/commit/d39c42bf21fd8b7627c224fcec4754ea0afd0e6e)), closes [#101](https://github.com/chenasraf/pantry-flutter/issues/101)
* add stores field ([9640d69](https://github.com/chenasraf/pantry-flutter/commit/9640d69c1d83bff17e278f6ef5dec8c3b55f5ce3))
* **notes:** confirm before exit with unsaved changes ([64609d2](https://github.com/chenasraf/pantry-flutter/commit/64609d22c84f8f55ec910755361d35f14703d652)), closes [#95](https://github.com/chenasraf/pantry-flutter/issues/95)
* **settings:** add setting icons ([e7d2f6a](https://github.com/chenasraf/pantry-flutter/commit/e7d2f6a030472ef0797b7318e91e5a8adc10c733))
* suggest existing items while adding so you can reuse them ([200657e](https://github.com/chenasraf/pantry-flutter/commit/200657ef79c54cd8d4fdbb0ce62218c7b8d48e59)), closes [#104](https://github.com/chenasraf/pantry-flutter/issues/104)
* update filters UI ([9640d69](https://github.com/chenasraf/pantry-flutter/commit/9640d69c1d83bff17e278f6ef5dec8c3b55f5ce3))


### Bug Fixes

* dismiss toasts automatically after duration ([1aa0f42](https://github.com/chenasraf/pantry-flutter/commit/1aa0f42d34802852b1d1e5ca2fa490a53947250f)), closes [#100](https://github.com/chenasraf/pantry-flutter/issues/100)
* keep note content clear of the bottom controls in view mode ([a8526b1](https://github.com/chenasraf/pantry-flutter/commit/a8526b174b0d281305016752218ce9e486eab5aa)), closes [#96](https://github.com/chenasraf/pantry-flutter/issues/96)
* remove blank space at the bottom of the archive and trash lists ([dfd381f](https://github.com/chenasraf/pantry-flutter/commit/dfd381f07f3ba6c0ddf0c6ab9ca9164e91e49026)), closes [#105](https://github.com/chenasraf/pantry-flutter/issues/105)
* stop the archive and trash views from flashing on background refresh ([8a0d48f](https://github.com/chenasraf/pantry-flutter/commit/8a0d48f7b81d954177a405f472e217da89630804)), closes [#106](https://github.com/chenasraf/pantry-flutter/issues/106)

## [0.21.0](https://github.com/chenasraf/pantry-flutter/compare/v0.20.2...v0.21.0) (2026-07-18)


### Features

* archive checklist items ([fd9e8a2](https://github.com/chenasraf/pantry-flutter/commit/fd9e8a267fde224843c72c5be94b8f9b6278cd08))
* collapse the sort options into a dialog to shorten the menu ([678d101](https://github.com/chenasraf/pantry-flutter/commit/678d101621986734f1455d706c09bd066ed9d73f))
* filter to items without a category ([573bd48](https://github.com/chenasraf/pantry-flutter/commit/573bd48859cc92f842d6ac4f0913ae95e0a5c69b))
* group items under category headers when sorting by category ([0a9131a](https://github.com/chenasraf/pantry-flutter/commit/0a9131a9f4564d57090c71e86a93645598bc59ba))
* keep category headers pinned while scrolling their group ([dca0b91](https://github.com/chenasraf/pantry-flutter/commit/dca0b91a8e113a2f44f5bce142f40b34a9e941fc))
* select multiple trashed items to restore or delete ([2b4da35](https://github.com/chenasraf/pantry-flutter/commit/2b4da35b00b5feff21aefa6294d20eeb2c85c631))
* show a note icon on items that have a description ([174015a](https://github.com/chenasraf/pantry-flutter/commit/174015aae8f94cb11e7fa0c2d39d45a6b05f030a))


### Bug Fixes

* improve offline caching ([89c9ab4](https://github.com/chenasraf/pantry-flutter/commit/89c9ab43d0b4c4ba5651833622e705f40480ba88)), closes [#92](https://github.com/chenasraf/pantry-flutter/issues/92)
* **mobile:** hide the refresh menu item ([72c395b](https://github.com/chenasraf/pantry-flutter/commit/72c395b89cca3a0f304f6f3bc45532847095a119))

## [0.20.2](https://github.com/chenasraf/pantry-flutter/compare/v0.20.1...v0.20.2) (2026-07-06)


### Bug Fixes

* correctly package icons to prevent startup freeze ([68eaf0f](https://github.com/chenasraf/pantry-flutter/commit/68eaf0fa60c91cb92dd86218509232fb851ab7b4))

## [0.20.1](https://github.com/chenasraf/pantry-flutter/compare/v0.20.0...v0.20.1) (2026-07-06)


### Bug Fixes

* no longer freezes on startup ([3b61983](https://github.com/chenasraf/pantry-flutter/commit/3b619831a16e85f1373acafdc35173c1a3102438))

## [0.20.0](https://github.com/chenasraf/pantry-flutter/compare/v0.19.0...v0.20.0) (2026-07-05)


### Features

* add a dense list layout option to fit more items on screen ([0533f43](https://github.com/chenasraf/pantry-flutter/commit/0533f438ef24dda7a278f6de5fb04e1ec3ddefa4)), closes [#86](https://github.com/chenasraf/pantry-flutter/issues/86)
* **checklists:** multi-select items for group actions ([611c987](https://github.com/chenasraf/pantry-flutter/commit/611c9879a6f128b3ea4bbbb17f8acc920354c582))
* hide actions you don't have permission for in shared houses ([f7b4765](https://github.com/chenasraf/pantry-flutter/commit/f7b47654684aaaaf09c5b39061e1b056a8569dbd))
* respect per-item sharing permissions from the server ([7745c9f](https://github.com/chenasraf/pantry-flutter/commit/7745c9ffff1d7ac1ff9c7ab413d43b0b5e50f0f3))


### Bug Fixes

* lists no longer hang on a spinner when your server is unreachable ([e6391f9](https://github.com/chenasraf/pantry-flutter/commit/e6391f9a9faa94790a37fcac06359475c6c73700)), closes [#87](https://github.com/chenasraf/pantry-flutter/issues/87)
* **login:** connecting to a self-signed server no longer hangs forever ([61731a1](https://github.com/chenasraf/pantry-flutter/commit/61731a1035bce086fae9489be87734f6fd934ec0))
* new list items now follow your sort order instead of jumping to the top ([11ef2e4](https://github.com/chenasraf/pantry-flutter/commit/11ef2e4ccbef3934aa9c27715b202769adaecf82))
* notification status bar icon is no longer tiny ([efb691c](https://github.com/chenasraf/pantry-flutter/commit/efb691c5cfd56d5e4509b904ad27c07937d92074))
* tapping a list in the home-screen widget now opens that list ([9ec1292](https://github.com/chenasraf/pantry-flutter/commit/9ec1292f5404f9368b516d210481550fb1e7d9ab))

## [0.19.0](https://github.com/chenasraf/pantry-flutter/compare/v0.18.0...v0.19.0) (2026-06-28)


### Features

* **checklists:** filter the All lists view by list ([f8cca3f](https://github.com/chenasraf/pantry-flutter/commit/f8cca3fbc2950b9e609352d2a22d9be04c5027b1))
* **checklists:** hide the progress card per list, including All lists ([0ed0d82](https://github.com/chenasraf/pantry-flutter/commit/0ed0d82f34a1944815a0bce79ce7adf591592cbc))
* **checklists:** import and export lists as Markdown ([e905412](https://github.com/chenasraf/pantry-flutter/commit/e90541231a14670eea43603b1020d1d5cb0d4f36))
* **checklists:** reuse existing items when adding ([31a3b73](https://github.com/chenasraf/pantry-flutter/commit/31a3b73fb31328f8c034d1975d38d16a64f94a17))
* **checklists:** show or hide the progress card per list ([10e1827](https://github.com/chenasraf/pantry-flutter/commit/10e18276fb870f3397456cbf77f457a4dcadd4bb)), closes [#76](https://github.com/chenasraf/pantry-flutter/issues/76)
* choose which side of the row the checkbox appears on ([a77dc19](https://github.com/chenasraf/pantry-flutter/commit/a77dc1994920b88a0869f5bc56cd7af7d9afa76e)), closes [#78](https://github.com/chenasraf/pantry-flutter/issues/78)
* **login:** sign in with an app password ([bf8d218](https://github.com/chenasraf/pantry-flutter/commit/bf8d218ddcf1d8f89477a23fd48178b5ed1de617))


### Bug Fixes

* **checklists:** insert new items in the correct sort position ([a0ad014](https://github.com/chenasraf/pantry-flutter/commit/a0ad0143228e8a190913386ae86e93e6fc83b8cd)), closes [#81](https://github.com/chenasraf/pantry-flutter/issues/81)
* **checklists:** keep list visible while loading or re-sorting ([921e029](https://github.com/chenasraf/pantry-flutter/commit/921e0295c8204df7db40a5b73463eb86dfa76081))
* **checklists:** persist repeat-from-completion when creating items ([22097e1](https://github.com/chenasraf/pantry-flutter/commit/22097e1372f0987a236d2eac47ad40b270c274dd))
* **checklists:** restore drag-to-reorder under custom sort ([85600f3](https://github.com/chenasraf/pantry-flutter/commit/85600f313463ecd12ab52629082145b2dc2cf8e3))
* **checklists:** show all items in long lists ([a9aaf86](https://github.com/chenasraf/pantry-flutter/commit/a9aaf86255cf4fc1086fcff766dfbeef7a684c10)), closes [#80](https://github.com/chenasraf/pantry-flutter/issues/80)
* **checklists:** show every list in the All lists filter ([1fd8eab](https://github.com/chenasraf/pantry-flutter/commit/1fd8eab56d75b98e87097524942783acc49102f3))
* **checklists:** stop checked items flickering back during background refresh ([d4e982a](https://github.com/chenasraf/pantry-flutter/commit/d4e982ae168e45f83355e0f81fe84b389ae456b7))
* don't close the open screen when the language refreshes in the background ([5b15f76](https://github.com/chenasraf/pantry-flutter/commit/5b15f76f8d9cafe0de5abcdb911401068fe5039c))
* **ios:** allow local network access for .local servers ([4bf0e8d](https://github.com/chenasraf/pantry-flutter/commit/4bf0e8d08599e629570d51160f3e2383e198a41a))
* keep the progress card hidden after you dismiss it ([3ed75b2](https://github.com/chenasraf/pantry-flutter/commit/3ed75b21e4dabaff6f157713ec92ba7b145a0641))
* **login:** bound connection attempts and report the real failure ([b11357d](https://github.com/chenasraf/pantry-flutter/commit/b11357d4bd31ccde32e71dccd5133ab903007648))
* make checklist checkbox easier to tap ([9c47f0e](https://github.com/chenasraf/pantry-flutter/commit/9c47f0e799107f75c444c6d853a03a40df928b26)), closes [#82](https://github.com/chenasraf/pantry-flutter/issues/82)
* **notes:** render single newlines as line breaks ([a20bea8](https://github.com/chenasraf/pantry-flutter/commit/a20bea837f81393a3fdd9149a491211a55cf48f9)), closes [#79](https://github.com/chenasraf/pantry-flutter/issues/79)
* **onboarding:** wait for server capabilities before showing new feature pages ([157e02f](https://github.com/chenasraf/pantry-flutter/commit/157e02f1a30e2f919af9bed77dda3be3247a5e5a))

## [0.18.0](https://github.com/chenasraf/pantry-flutter/compare/v0.17.0...v0.18.0) (2026-06-19)


### Features

* **checklists:** add All lists view aggregating items across lists ([ff31598](https://github.com/chenasraf/pantry-flutter/commit/ff31598d45e10e61133178199020e357a1512884))
* **checklists:** add bulk item add via Multiple toggle ([d26ad10](https://github.com/chenasraf/pantry-flutter/commit/d26ad10dd765bc1078d2e4385876cc5232cb16b6))
* **checklists:** copy item to another list ([08c985f](https://github.com/chenasraf/pantry-flutter/commit/08c985f1104bbde766f7282cc25e447e0cf7d694))
* **checklists:** edit list label, color, and icon ([5cce8e0](https://github.com/chenasraf/pantry-flutter/commit/5cce8e0b63e27c934d45e11882f828c5cf4a130a))
* **checklists:** take photo from camera when adding item image ([c8a4967](https://github.com/chenasraf/pantry-flutter/commit/c8a49670fa918dc5ed2122da9959ec6bbe8d654e)), closes [#75](https://github.com/chenasraf/pantry-flutter/issues/75)
* **icons:** add pantry location and appliance icons ([5010da1](https://github.com/chenasraf/pantry-flutter/commit/5010da16ca1d8b59e9fe6357e929dd211b8d5095))


### Bug Fixes

* **desktop:** show all list icons in add list dialog ([b92977f](https://github.com/chenasraf/pantry-flutter/commit/b92977f186866eda69797256a77c5d2612206efb))
* **login:** support self-signed certificates ([9a2a398](https://github.com/chenasraf/pantry-flutter/commit/9a2a398926a74d35abd05cbb7f1652829d9a1bf2))
* **sync:** only show sync banner for offline backlog or errors ([12810e2](https://github.com/chenasraf/pantry-flutter/commit/12810e26905dc5b0dff248208003896bb3233a72))


### Miscellaneous Chores

* regenerate release pr ([d9e19d8](https://github.com/chenasraf/pantry-flutter/commit/d9e19d8b1e6d00f0fa5927cd7685c3e7e2657631))

## [0.17.0](https://github.com/chenasraf/pantry-flutter/compare/v0.16.0...v0.17.0) (2026-06-17)


### Features

* **checklists:** sort and reorder lists ([3673229](https://github.com/chenasraf/pantry-flutter/commit/3673229749dbbb677e4d2d803c3f18f9229d497f))
* **login:** show error details on connection failure ([d0f2971](https://github.com/chenasraf/pantry-flutter/commit/d0f29712b57b954880771e7d4f222b22f07782f7))
* **settings:** default item tap action — done, view, edit, or none ([ea85df2](https://github.com/chenasraf/pantry-flutter/commit/ea85df2d28c399997ab6a5ba9a1a1994792affa7))
* trash views for photos, notes, and checklists ([4b588b9](https://github.com/chenasraf/pantry-flutter/commit/4b588b9d809fe84616c2704fa65a6c1b2ee9accf))
* work offline — queue changes and sync when back online ([2004a69](https://github.com/chenasraf/pantry-flutter/commit/2004a69eeaad1762953f64a95a53289a30d90d58))


### Bug Fixes

* **android:** disable baseline profiles for reproducible builds ([c8c945f](https://github.com/chenasraf/pantry-flutter/commit/c8c945f6d4ad0e21630279fecc5e228e15a4d590))
* **android:** trust user-installed CAs for self-signed certs ([0539edc](https://github.com/chenasraf/pantry-flutter/commit/0539edc402744d93076a6d98e9c60626863971cd))
* **checklists:** keep new items sorted when adding ([646177f](https://github.com/chenasraf/pantry-flutter/commit/646177f1511689e5ee7cbacab9e130e6b0b2e48c))
* **checklists:** restore category divider/spacing preference ([c41af8a](https://github.com/chenasraf/pantry-flutter/commit/c41af8a470a541cacf71b2f32e2b4e55749b9992))
* **home:** preserve active tab when rotating device ([bbccdc5](https://github.com/chenasraf/pantry-flutter/commit/bbccdc5dd1053d3aa0fbe284022c301f0c81db2d))
* **ios:** tap status bar to scroll active tab to top ([e14a02e](https://github.com/chenasraf/pantry-flutter/commit/e14a02eba173cf1818460d286eeb9abab88376c4))
* keep server features and per-house sort preferences after offline launch ([3c29b3e](https://github.com/chenasraf/pantry-flutter/commit/3c29b3ed1fcec911ef1091673a555631922447d1))
* **l10n:** add missing pin list translation ([015ab8c](https://github.com/chenasraf/pantry-flutter/commit/015ab8c1b96e7f919aed6dac7859b0e1c94f80b2))

## [0.16.0](https://github.com/chenasraf/pantry-flutter/compare/v0.15.0...v0.16.0) (2026-06-14)


### Features

* **android:** pinned lists home-screen widget ([77951ca](https://github.com/chenasraf/pantry-flutter/commit/77951ca3b024d5fb3fc16fc6ffb245e5ce8130cb))
* **android:** widget follows app dark mode setting ([dcc68bd](https://github.com/chenasraf/pantry-flutter/commit/dcc68bde236ce8b281d2c39a4c0066115883b2ae))
* **android:** widget icons, count badges, larger items ([d68698d](https://github.com/chenasraf/pantry-flutter/commit/d68698d116be8fd52e16c553dfd40d50377c728a))
* **android:** widget shows house name when pins span multiple houses ([d564b5e](https://github.com/chenasraf/pantry-flutter/commit/d564b5e7960d936f901b4efff296ae77b2f4f2d4))
* **checklists:** auto-refresh list every 30s while open ([51e5498](https://github.com/chenasraf/pantry-flutter/commit/51e549824e11195612f8dbcd6e86de8ce772c076))
* **checklists:** redesigned checklist page ([211c8a8](https://github.com/chenasraf/pantry-flutter/commit/211c8a8abe31388fc0ea87917c31671d6a3af36c))
* **checklists:** redesigned edit item page ([35b1e73](https://github.com/chenasraf/pantry-flutter/commit/35b1e735e0f3440d4b72e81728481fcc4dabfa61))
* **checklists:** redesigned item view page ([12aa482](https://github.com/chenasraf/pantry-flutter/commit/12aa482c85eab350409da625a6e8099b860db188))
* hide UI for features your server doesn't support ([5f9380d](https://github.com/chenasraf/pantry-flutter/commit/5f9380d47e896c406d52a67a4e5a19744a3e29e8))
* **nav:** reorder navigation tabs from settings ([0d2c0ee](https://github.com/chenasraf/pantry-flutter/commit/0d2c0ee308f1e99166ca562722edb8af4fdfeac2))
* **notes:** pin notes to top of wall ([676f116](https://github.com/chenasraf/pantry-flutter/commit/676f116bea46641a5e1b8fe05443ac9ffbd02158))
* onboarding screen for new/updating users ([096bac6](https://github.com/chenasraf/pantry-flutter/commit/096bac6df672077c67cd0c8fe90f6752cdc90bfd))
* show create-list button in empty checklists state ([65ca582](https://github.com/chenasraf/pantry-flutter/commit/65ca5829aca9c92b50528031b3ab3452b826f958))


### Bug Fixes

* **android:** keep widget theme + pins in sync after background polls ([b4b2400](https://github.com/chenasraf/pantry-flutter/commit/b4b2400a654fb2d80e1d6336c30e4641f221ff42))
* **android:** refresh widget list when pins change ([fd9d90f](https://github.com/chenasraf/pantry-flutter/commit/fd9d90f9ddb09b15226c857532f1e20d20137894))
* **checklists:** auto-dismiss check snackbar after 6 seconds ([e2d439c](https://github.com/chenasraf/pantry-flutter/commit/e2d439cecdf3ac6557c6bee814b4ddc58c937db7))
* **checklists:** stabilize scroll position when toggling items ([4bf62e8](https://github.com/chenasraf/pantry-flutter/commit/4bf62e80d58fde8f97117f1d3fa7a93f51960dbc))
* theme accent color on Nextcloud 34+ ([41cf51a](https://github.com/chenasraf/pantry-flutter/commit/41cf51a312f69c11cf0d2eaf5958ea9c3e7eb68e))
* **theme:** cache Nextcloud accent color in local prefs ([13f0c23](https://github.com/chenasraf/pantry-flutter/commit/13f0c23f97bccfefc082e567ced10ac71fd5a3ca))


### Performance Improvements

* **checklists:** improve list performance ([4bf62e8](https://github.com/chenasraf/pantry-flutter/commit/4bf62e80d58fde8f97117f1d3fa7a93f51960dbc))
* faster app startup ([799576e](https://github.com/chenasraf/pantry-flutter/commit/799576ec956692011e6c6049949d5640ff67caba))

## [0.15.0](https://github.com/chenasraf/pantry-flutter/compare/v0.14.0...v0.15.0) (2026-06-11)


### Features

* **categories:** sort categories by name or custom order ([9a0f1e8](https://github.com/chenasraf/pantry-flutter/commit/9a0f1e809d28b748635c88c161a63fc2c7545e8d))
* **checklist:** show who added each item ([1fea252](https://github.com/chenasraf/pantry-flutter/commit/1fea2527c5ffe5f9713582ea64311913fe21ee07))
* **checklist:** undo snackbar when removing items ([4e4999e](https://github.com/chenasraf/pantry-flutter/commit/4e4999e3f0cc8a363ef5b2096d452c41bf9ace4e))
* **notes,photos:** snackbar confirming deletion ([0847cc5](https://github.com/chenasraf/pantry-flutter/commit/0847cc54ebca9a498c31fd010fe1e5e168902322))


### Performance Improvements

* **checklist:** resort items in place when category sort changes ([1a24d13](https://github.com/chenasraf/pantry-flutter/commit/1a24d13eefa3a39d8e461cac17df2b0af5f65bd7))

## [0.14.0](https://github.com/chenasraf/pantry-flutter/compare/v0.13.2...v0.14.0) (2026-05-29)


### Features

* **checklist:** remember "once" toggle value per-list ([ebe549a](https://github.com/chenasraf/pantry-flutter/commit/ebe549ad84653967f6f044c34b4fe34dd6bd4d3f))
* **desktop:** refresh button in app bar ([578c95f](https://github.com/chenasraf/pantry-flutter/commit/578c95f727c3a8df44da205ff30baa33247d0083))

## [0.13.2](https://github.com/chenasraf/pantry-flutter/compare/v0.13.1...v0.13.2) (2026-05-25)


### Bug Fixes

* **android:** add monochrome launcher icon for themed icons ([97d5675](https://github.com/chenasraf/pantry-flutter/commit/97d5675f939c0a5ed094303f03dbc9f29e3f7909))
* **checklists:** undo now properly unchecks items ([77c1097](https://github.com/chenasraf/pantry-flutter/commit/77c1097da2f6b05607f85a9bab8fadf59bdd75b2))
* **macos:** sign-in now opens in-app and closes automatically ([4aafaca](https://github.com/chenasraf/pantry-flutter/commit/4aafacaff61f1e47a8d9ee630f5ba8bbd4ee84cd))
* **splash:** honor dark mode on cold launch ([d4a1380](https://github.com/chenasraf/pantry-flutter/commit/d4a1380480beaf784d1e8621aaf2f3542fdcbcb5))

## [0.13.1](https://github.com/chenasraf/pantry-flutter/compare/v0.13.0...v0.13.1) (2026-05-22)


### Bug Fixes

* **checklists:** auto-dismiss item check snackbar after 6 seconds ([4e53481](https://github.com/chenasraf/pantry-flutter/commit/4e53481cdfcdba1d75cebadffb023b6a92b3df75))
* **macos:** esc to dismiss would ring bell and not work ([116eb18](https://github.com/chenasraf/pantry-flutter/commit/116eb18693137a0d8733c903d0f66a4e67f3210a))
* **macos:** use macos dedicated login browser for auth ([124c7dc](https://github.com/chenasraf/pantry-flutter/commit/124c7dce34197f9d53723151ca90e820f288b261))

## [0.13.0](https://github.com/chenasraf/pantry-flutter/compare/v0.12.0...v0.13.0) (2026-05-15)


### Features

* add trash view ([eb4d8d3](https://github.com/chenasraf/pantry-flutter/commit/eb4d8d3c509e6fe1c6ef998caaa58f6bd9a55a53))
* add undo action for checking items ([ddf0c36](https://github.com/chenasraf/pantry-flutter/commit/ddf0c365a1ea4fb27f66fc19a7c5ffd7d72f6de7))
* improve ui for larger devices ([eafc267](https://github.com/chenasraf/pantry-flutter/commit/eafc267e92b275796e1edb746c3c3b9dc75925e7))
* **ios:** open full file picker when running on macOS ([00241b8](https://github.com/chenasraf/pantry-flutter/commit/00241b8aceeda5175e0989f017031a94b6c53581))
* **macos:** go back by using Esc key ([88e153b](https://github.com/chenasraf/pantry-flutter/commit/88e153b96f249f4a8d8f19465a31cde7aa3ac8e0))
* switch between photos in photo view ([cf9135e](https://github.com/chenasraf/pantry-flutter/commit/cf9135e0695f70b8c8c658421306f6cda610b6b4))

## [0.12.0](https://github.com/chenasraf/pantry-flutter/compare/v0.11.0...v0.12.0) (2026-05-15)


### Features

* add setting to show spacing between categories in checklist items ([689e4d6](https://github.com/chenasraf/pantry-flutter/commit/689e4d6cad89a84621b77e300198d12ac43131ff))
* create new lists from the list selector ([41e8ac1](https://github.com/chenasraf/pantry-flutter/commit/41e8ac13a0ab78436bc2674220ed282f8410862d))
* share photos, links, and text to Pantry from other apps ([60b16aa](https://github.com/chenasraf/pantry-flutter/commit/60b16aad309ec0f02b542c53a7bfafb9f9652da3))
* take photos directly from the photo board ([d880269](https://github.com/chenasraf/pantry-flutter/commit/d8802690c0a3ab80346f84ea1df4b3774ba6e4ee))

## [0.11.0](https://github.com/chenasraf/pantry-flutter/compare/v0.10.1...v0.11.0) (2026-05-12)


### Features

* add setting to require checkbox tap to complete checklist items ([ef2bc85](https://github.com/chenasraf/pantry-flutter/commit/ef2bc851deedc180dda51fbfb7378aef7145cf5f))


### Bug Fixes

* preserve subpath for Nextcloud instances hosted on sub-paths ([0c575ea](https://github.com/chenasraf/pantry-flutter/commit/0c575eaa2601dc8c83c6b874f2d81b54a0f6bf01))

## [0.10.1](https://github.com/chenasraf/pantry-flutter/compare/v0.10.0...v0.10.1) (2026-04-26)


### Bug Fixes

* make markdown links clickable ([7b5f9c1](https://github.com/chenasraf/pantry-flutter/commit/7b5f9c151845dde90275a8289b3114483d2b214d))

## [0.10.0](https://github.com/chenasraf/pantry-flutter/compare/v0.9.10...v0.10.0) (2026-04-21)


### Features

* update notes view & edit ui ([36a74b3](https://github.com/chenasraf/pantry-flutter/commit/36a74b39e1beb37fc2f1446f8d45945a22289c6b))


### Bug Fixes

* bug where note grid would not clip correctly ([08159fa](https://github.com/chenasraf/pantry-flutter/commit/08159faec22422da983f23685c53b45088d74b2a))

## [0.9.10](https://github.com/chenasraf/pantry-flutter/compare/v0.9.9...v0.9.10) (2026-04-19)


### Build System

* fix signing ([9f45b23](https://github.com/chenasraf/pantry-flutter/commit/9f45b2344ef87708d55889e8fb80f465808fb0c7))

## [0.9.9](https://github.com/chenasraf/pantry-flutter/compare/v0.9.8...v0.9.9) (2026-04-19)


### Build System

* re-sign with stripping ([852e9c4](https://github.com/chenasraf/pantry-flutter/commit/852e9c47f3cf11145a72ed78b6415ecd0da2b111))

## [0.9.8](https://github.com/chenasraf/pantry-flutter/compare/v0.9.7...v0.9.8) (2026-04-19)


### Build System

* strip deps metadata from build ([132d9e3](https://github.com/chenasraf/pantry-flutter/commit/132d9e33a6662554149a7941053594c6c7ab9043))

## [0.9.7](https://github.com/chenasraf/pantry-flutter/compare/v0.9.6...v0.9.7) (2026-04-19)


### Build System

* disable deps metadata in apk ([7ea2901](https://github.com/chenasraf/pantry-flutter/commit/7ea2901867b25e2c4bcd46cd744af7b12656b6dd))

## [0.9.6](https://github.com/chenasraf/pantry-flutter/compare/v0.9.5...v0.9.6) (2026-04-19)


### Build System

* remove zipalign ([b1d7ecc](https://github.com/chenasraf/pantry-flutter/commit/b1d7eccd822fcbac56683a4085a329784c71ca7f))

## [0.9.5](https://github.com/chenasraf/pantry-flutter/compare/v0.9.4...v0.9.5) (2026-04-19)


### Build System

* zipalign ([6d2173f](https://github.com/chenasraf/pantry-flutter/commit/6d2173f08d72d8e188c9a4aabe044ff922d4b32f))

## [0.9.4](https://github.com/chenasraf/pantry-flutter/compare/v0.9.3...v0.9.4) (2026-04-19)


### Build System

* remove apk obfuscation ([d41d2b8](https://github.com/chenasraf/pantry-flutter/commit/d41d2b81beb512384cb3c2978bebd201c3bf53a0))

## [0.9.3](https://github.com/chenasraf/pantry-flutter/compare/v0.9.2...v0.9.3) (2026-04-19)


### Build System

* upgrade flutter version ([3e4051a](https://github.com/chenasraf/pantry-flutter/commit/3e4051a8462271543381496a9d60a22239b8d8da))

## [0.9.2](https://github.com/chenasraf/pantry-flutter/compare/v0.9.1...v0.9.2) (2026-04-19)


### Build System

* reproducible build ([9d4c832](https://github.com/chenasraf/pantry-flutter/commit/9d4c8327b035eb0433d6d0a571af406ffca84f83))

## [0.9.1](https://github.com/chenasraf/pantry-flutter/compare/v0.9.0...v0.9.1) (2026-04-18)


### Build System

* add abi split ([7d0c793](https://github.com/chenasraf/pantry-flutter/commit/7d0c7932ea9bf18d5ff391351f0058889abba5d8))

## [0.9.0](https://github.com/chenasraf/pantry-flutter/compare/v0.8.0...v0.9.0) (2026-04-18)


### Features

* add search in lists ([eb797dd](https://github.com/chenasraf/pantry-flutter/commit/eb797dd0e87f7eb14576a3bdf7e77f9fe1c0cb09))
* allow uploading list item image ([7243e43](https://github.com/chenasraf/pantry-flutter/commit/7243e43bbbfe8072327fc921ed2a4ffba228bd3f))

## [0.8.0](https://github.com/chenasraf/pantry-flutter/compare/v0.7.1...v0.8.0) (2026-04-16)


### Features

* add more icons to categories ([179c6d7](https://github.com/chenasraf/pantry-flutter/commit/179c6d781c1342434608b9af88daa807795c9a46))
* allow adding one-off list items ([a447fe1](https://github.com/chenasraf/pantry-flutter/commit/a447fe1c8a1d9de655c081015f287afeba75bee1))

## [0.7.1](https://github.com/chenasraf/pantry-flutter/compare/v0.7.0...v0.7.1) (2026-04-14)


### Bug Fixes

* about urls not opening ([64af382](https://github.com/chenasraf/pantry-flutter/commit/64af382f10bd696f05a23d31ee8e04d746fc4b46))

## [0.7.0](https://github.com/chenasraf/pantry-flutter/compare/v0.6.0...v0.7.0) (2026-04-14)


### Features

* add about page ([0cb6c06](https://github.com/chenasraf/pantry-flutter/commit/0cb6c06d9d418b61d5fd1c4852ec244366aa6af8))

## [0.6.0](https://github.com/chenasraf/pantry-flutter/compare/v0.5.0...v0.6.0) (2026-04-13)


### Features

* show next due date for list items ([e7ff39a](https://github.com/chenasraf/pantry-flutter/commit/e7ff39a2328ecd9967a3b162dc389bac8a645f38))


### Bug Fixes

* appbar icon spacings ([1197254](https://github.com/chenasraf/pantry-flutter/commit/11972542da777a5922aec564684b7f37b3330aa0))
* improve i18n recurrence string rules ([1e85d0c](https://github.com/chenasraf/pantry-flutter/commit/1e85d0c2a6d46d7561105f02683bbed97c907792))

## [0.5.0](https://github.com/chenasraf/pantry-flutter/compare/v0.4.0...v0.5.0) (2026-04-12)


### Features

* add de, es, fr locales ([7ec9526](https://github.com/chenasraf/pantry-flutter/commit/7ec952620db2d957278d58c3798e5b03ab8c59fc))


### Bug Fixes

* allow arbitrary text in quantity ([32326be](https://github.com/chenasraf/pantry-flutter/commit/32326beb8d39d4713c9f65d01dfb243c44a5dbda))
* improve rtl layout spacings ([9d474a6](https://github.com/chenasraf/pantry-flutter/commit/9d474a62fe6ae19f3c08cdb634eac725ffb403c4))
* rtl layout + switching ([b0fcd93](https://github.com/chenasraf/pantry-flutter/commit/b0fcd937922badb59467f1bf164e3668c658e531))

## [0.4.0](https://github.com/chenasraf/pantry-flutter/compare/v0.3.0...v0.4.0) (2026-04-12)


### Features

* add hebrew language translation ([7c572a6](https://github.com/chenasraf/pantry-flutter/commit/7c572a6e64eafcf3433a2e6599b698312ffa9cbe))


### Bug Fixes

* description field in items saving+displaying ([4d99694](https://github.com/chenasraf/pantry-flutter/commit/4d9969410935d0b8d64fcfbc3e11d317a17979a6))

## [0.3.0](https://github.com/chenasraf/pantry-flutter/compare/v0.2.1...v0.3.0) (2026-04-12)


### Features

* improve main page navigations ([ea8ff9a](https://github.com/chenasraf/pantry-flutter/commit/ea8ff9aabd0924f8273927c907b800576c7cd697))
* move items between lists ([c5595c0](https://github.com/chenasraf/pantry-flutter/commit/c5595c0d1ae07c3c2dbf35fba5a70a957fc9af17))


### Bug Fixes

* support back button when in photos foldeer ([e6284b9](https://github.com/chenasraf/pantry-flutter/commit/e6284b95774a5bd967af95626acb6ec3562ae9a5))

## [0.2.1](https://github.com/chenasraf/pantry-flutter/compare/v0.2.0...v0.2.1) (2026-04-11)


### Bug Fixes

* sorting prefs persistence & error wrapping ([a5c8e5b](https://github.com/chenasraf/pantry-flutter/commit/a5c8e5b479e92f87ea910b5af19ca24711ce7b16))

## [0.2.0](https://github.com/chenasraf/pantry-flutter/compare/v0.1.0...v0.2.0) (2026-04-11)


### Features

* add sorting by category for checklist ([5ae3afc](https://github.com/chenasraf/pantry-flutter/commit/5ae3afcd41628db0d1a758602e1a6fae652788ae))
* notifications support ([4d0c28f](https://github.com/chenasraf/pantry-flutter/commit/4d0c28f2633c75647b41e765fa02935386798034))


### Bug Fixes

* add bottom padding to accomodate fab ([3b89798](https://github.com/chenasraf/pantry-flutter/commit/3b897982d60f71d0cadd5ac21386929aad10851e))

## 0.1.0 (2026-04-10)


### Features

* add category in category picker ([9e67f06](https://github.com/chenasraf/pantry-flutter/commit/9e67f06826007c31ac35e694b33648957bc39871))
* add/edit/delete items ([138f9a5](https://github.com/chenasraf/pantry-flutter/commit/138f9a58c410bb08c25e489b57abf8f10055d3bf))
* checklist sorting/reordering ([cc7ff96](https://github.com/chenasraf/pantry-flutter/commit/cc7ff963269514107775264d4bfbf47b1333d3c5))
* checklist view ([5d54e1a](https://github.com/chenasraf/pantry-flutter/commit/5d54e1aa0328ade0902c3ea0de74079cf304447e))
* create house ([0987eac](https://github.com/chenasraf/pantry-flutter/commit/0987eac1459e694e6bedf90346a49506ac430b7c))
* handle server app not installed ([2c75a71](https://github.com/chenasraf/pantry-flutter/commit/2c75a715933fe6749d4486d279f95f207409279c))
* initial commit ([0015ba0](https://github.com/chenasraf/pantry-flutter/commit/0015ba053b6854b1f6236c7daa7634a64556d2ab))
* launcher icon, splash, i18n ([4b1e876](https://github.com/chenasraf/pantry-flutter/commit/4b1e8765724b8e2f9d3f0639da375b14b7106f8a))
* manage categories ([46dd3f2](https://github.com/chenasraf/pantry-flutter/commit/46dd3f21d6e289e1ed1c0dcc8ba084597b67973f))
* note markdown+rtl support ([0688294](https://github.com/chenasraf/pantry-flutter/commit/068829460524cd2be4fb07ad42ebefb43c12b5fe))
* notes wall ([755861a](https://github.com/chenasraf/pantry-flutter/commit/755861aa9134816a7f84eb0acf50579a945ebbe7))
* photo board ([43cc0a3](https://github.com/chenasraf/pantry-flutter/commit/43cc0a3fcf47b890fbc47328934dc72db73a0125))
* photos/notes multiselect ([0053f53](https://github.com/chenasraf/pantry-flutter/commit/0053f53cd7937445eca53b5d2c070b9b5a3eb82f))
* update user menu ([639fb86](https://github.com/chenasraf/pantry-flutter/commit/639fb86a2075895676c8b73b6bfb3c7e89517f0e))


### Bug Fixes

* note color options ([02aeb9e](https://github.com/chenasraf/pantry-flutter/commit/02aeb9ef2df11925d980a1c0810a8849f9be98e4))
* use dark avatar on dark mode ([0fca0d4](https://github.com/chenasraf/pantry-flutter/commit/0fca0d4d86187af0881f6f1eb976ec2c98d6a4d5))
