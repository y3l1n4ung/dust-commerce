# Storefront design QA

Source visual truth path: unavailable; the selected in-app browser is blocked
by the locked Mac.

Implementation screenshot path: unavailable for the same reason.

Viewport: desktop and `390 x 844` mobile captures are required but unavailable.

Pixel dimensions, CSS size, and density normalization: not measured because no
valid source or implementation capture could be produced.

State: `/store` with the shared footer visible, authenticated `/checkout` with
a saved address available, `/account/orders/details/:id`, and the profile
password editor closed and open, plus the equivalent Medusa DTC states pinned
in `docs/storefront-parity.md`.

**Findings**

- [P1] Rendered fidelity cannot be established
  Location: full Medusa DTC and Morrow storefront views.
  Evidence: source code and local runtime are available, but the locked Mac
  prevents both required browser captures and a combined comparison.
  Impact: typography, responsive spacing, link wrapping, image treatment, and
  footer placement, the saved-address selector, and order detail remain
  visually unverified.
  Fix: unlock the Mac, capture both sites at matching desktop and mobile
  viewports, combine the captures, and run the comparison loop.

**Required fidelity surfaces**

- Fonts and typography: blocked pending rendered comparison.
- Spacing and layout rhythm: blocked pending rendered comparison.
- Colors and visual tokens: source tokens are mapped in the parity ledger, but
  their rendered result remains blocked.
- Image quality and asset fidelity: blocked pending rendered comparison.
- Copy and content: source and implementation code have been compared,
  including the saved-address greeting and selector; rendered wrapping and
  truncation remain blocked.

**Full-view comparison evidence**

Unavailable because neither browser view can be captured while the Mac is
locked.

**Focused region comparison evidence**

Unavailable. The footer, navigation, product cards, filters, cart preview, and
checkout controls require focused captures after the full-view comparison.

**Comparison history**

- No visual iteration has run. This report records the initial capture blocker;
  no visual finding is claimed from source inspection alone.

**Implementation checklist**

- Capture matching desktop store views with the footer visible.
- Capture matching `390 x 844` store views and interactive menu/filter states.
- Capture authenticated checkout with the saved-address menu closed and open.
- Capture the same authenticated order-detail state at desktop and compact
  widths.
- Capture profile password closed, open, validation-error, and post-save
  signed-out states without exposing any secret text.
- Compare combined images and fix every P0/P1/P2 difference.
- Repeat captures after fixes and record post-fix evidence here.

**Follow-up polish**

- Classify any residual P3 differences only after normalized visual evidence is
  available.

final result: blocked
