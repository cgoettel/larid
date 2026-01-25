# Gull ID Design Document

**Date:** 2026-01-25
**Status:** Approved

## Overview

Gull ID is a cross-platform mobile and web app that helps birders identify gulls through feature-based filtering. Gull identification is difficult because plumages vary by age and season, with many overlapping characteristics between species. This app lets users select observable features (leg color, bill pattern, etc.) to narrow down possible species and plumage combinations.

## Goals & Constraints

### Primary Goal

Provide birders in the field with a fast, offline-capable tool to identify gulls by filtering on observable characteristics.

### Constraints

- Offline capability required for mobile (birding often happens in areas with poor connectivity)
- Web version does not need offline support
- No user accounts required - pure informational tool
- Privacy-first: optional anonymous usage analytics only, no personal data collection
- Start with ABA North America area, initial launch with ~10 California gull species

### Success Criteria (v1)

- Filter mechanism works with real-time results
- Shows species names and plumage types
- Includes reference photos for each plumage
- Works offline on mobile
- Handles "didn't see that feature" gracefully

## Technology Stack

### Platform: Flutter (Dart)

- Single codebase for Android, iOS, and web
- Native SQLite for offline data storage
- Hot reload for fast development iteration
- Strong type system (null-safety built-in)

**Rationale:** Flutter provides cross-platform coverage with excellent offline support. Dart's type system and tooling will be familiar coming from Rust/Go/Python background. Simpler build pipeline than React Native + web, better offline story than PWA.

### Development Environment

- VS Code with Flutter extension
- Flutter SDK
- Xcode (for iOS builds, macOS only)
- Android SDK (for Android builds)

### Infrastructure

- **Web hosting:** GitLab Pages (static site, free, automatic CI/CD)
- **Analytics endpoint:** Google Cloud Functions (serverless, pay-per-invocation)
- **Analytics storage:** Cloud Storage or lightweight database
- **Infrastructure as code:** Terraform
- **Custom domain:** TBD (required for GitLab Pages due to username constraint)

### Distribution

- **iOS:** App Store ($99/year Apple Developer Program)
- **Android:** Google Play ($25 one-time registration)
- **Web:** GitLab Pages with custom domain
- **Budget:** ~$200/year (well within limits)

## Architecture

### Three-Layer Structure

1. **Data Layer**
   - SQLite database bundled with app in `assets/` directory
   - Pre-populated with species, plumages, characteristics, photos, regions
   - Offline-first: all queries against local database
   - Database updates require new app version (v1 approach)

2. **Business Logic Layer**
   - Filtering engine: takes selected characteristics + optional location, returns matching plumages
   - Handles unknown/unselected characteristics (doesn't filter on them)
   - Query optimization for real-time results
   - Future: ranking/scoring by match confidence

3. **UI Layer**
   - Flutter widgets shared across mobile and web
   - Responsive layouts: mobile uses vertical layout, web uses sidebar
   - Real-time result updates as filters change
   - Navigation: main filter screen, detail view, settings

### Key User Flows

1. **Identification Flow**
   - User opens app → loads local database
   - User selects characteristic values (e.g., leg color = pink)
   - Results update in real-time (no network call)
   - User taps species → detail view with photos, plumage info
   - No filters selected = show all species/plumages

2. **Settings Flow**
   - User sets location preference (stored locally, no account)
   - User opts in/out of anonymous analytics
   - User toggles "show rare/vagrant species"

3. **Analytics Flow (if opted in)**
   - Events queued locally
   - Sent in batches when online
   - Simple HTTP POST to Cloud Function endpoint
   - No retry logic for v1

## Database Design

### Schema (Boyce-Codd Normal Form)

```sql
-- Species master table
species (
  id INTEGER PRIMARY KEY,
  common_name TEXT NOT NULL,
  scientific_name TEXT NOT NULL UNIQUE,
  taxonomic_order INTEGER
)

-- Plumage variations (normalized by age and season)
plumages (
  id INTEGER PRIMARY KEY,
  species_id INTEGER NOT NULL REFERENCES species(id),
  age_class TEXT NOT NULL,  -- "first_year", "second_year", "adult"
  season TEXT,              -- "breeding", "non_breeding", NULL
  description TEXT,
  UNIQUE(species_id, age_class, season)
)

-- Characteristic types (leg color, bill pattern, etc.)
characteristics (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  display_order INTEGER
)

-- Possible values for each characteristic
characteristic_values (
  id INTEGER PRIMARY KEY,
  characteristic_id INTEGER NOT NULL REFERENCES characteristics(id),
  value TEXT NOT NULL,
  display_name TEXT NOT NULL,
  UNIQUE(characteristic_id, value)
)

-- Links plumages to their characteristics (junction table)
-- Supports multiple values per characteristic if needed
plumage_characteristics (
  plumage_id INTEGER NOT NULL REFERENCES plumages(id),
  characteristic_value_id INTEGER NOT NULL REFERENCES characteristic_values(id),
  PRIMARY KEY(plumage_id, characteristic_value_id)
)

-- Geographic regions (hierarchical)
regions (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  region_type TEXT,
  parent_region_id INTEGER REFERENCES regions(id)
)

-- Species occurrence by region
species_regions (
  species_id INTEGER NOT NULL REFERENCES species(id),
  region_id INTEGER NOT NULL REFERENCES regions(id),
  occurrence TEXT,  -- "common", "uncommon", "rare", "vagrant"
  PRIMARY KEY(species_id, region_id)
)

-- Photo references (openly licensed)
photos (
  id INTEGER PRIMARY KEY,
  plumage_id INTEGER NOT NULL REFERENCES plumages(id),
  url TEXT NOT NULL,
  photographer TEXT,
  license TEXT NOT NULL,
  source TEXT
)
```

### Extensibility

**Adding species:** Insert rows into existing tables, no schema changes required.

**Adding characteristics:** Insert into `characteristics` and `characteristic_values`. Existing plumages can reference new values.

**Adding regions:** Hierarchical structure via `parent_region_id` supports nesting (e.g., Western Europe → UK → Scotland).

**Multiple values per characteristic:** Junction table already supports this (e.g., leg color can be both pink and yellow).

### Sample Query (Filtering)

```sql
-- Find plumages matching selected characteristic values
SELECT DISTINCT p.*
FROM plumages p
JOIN plumage_characteristics pc ON p.id = pc.plumage_id
WHERE pc.characteristic_value_id IN (selected_value_ids)
GROUP BY p.id
HAVING COUNT(DISTINCT pc.characteristic_value_id) >= threshold
```

## UI Structure

### Main Screen (Filter & Results)

- **Top section:** Filter chips/dropdowns for each characteristic
  - Tappable to select values
  - Shows count of active filters
  - "Clear all" button when filters applied
- **Bottom section:** Scrollable results list
  - Species name, plumage type (age/season), thumbnail photo
  - Tap to open detail view
- **Settings icon:** Top-right corner

### Detail View

- Species name, scientific name
- Current plumage being viewed (age/season indicator)
- Photo gallery (swipeable if multiple photos)
- Full characteristic list for this plumage
- Range information for user's region
- Back button

### Settings Screen

- Location picker (state/region dropdown)
- Toggle: "Include rare/vagrant species"
- Toggle: "Send anonymous usage statistics" (default: off)
- About section: data sources, licenses, version info

### Platform Differences

- **Mobile:** Vertical layout, potential bottom navigation for future features
- **Web:** Sidebar for filters (more horizontal space), otherwise same widgets

## Data Population Strategy

### Initial Database Build

Manual/semi-automated process (separate from app development):

1. Compile species list from eBird taxonomy (ABA area, California subset for v1)
2. Document plumage variations per species (field guides, eBird, expert resources)
3. Build characteristic matrix for each plumage
4. Collect photo URLs from Macaulay Library, iNaturalist (verify open licenses)
5. Generate SQLite file, include in app `assets/` directory

**v1 Scope:** 10 California gull species to validate approach before expanding to all ABA gulls.

### For Contributors

- Document data entry process clearly
- Provide validation scripts (e.g., "every plumage must have ≥1 photo")
- Consider separate repo or spreadsheet → SQLite pipeline for non-technical contributors
- Schema design enables adding species without code changes

## Analytics Implementation

### Event Structure

```json
{
  "event": "filter_applied",
  "characteristic": "leg_color",
  "value": "pink",
  "timestamp": "2026-01-25T12:00:00Z"
}
```

### Events to Track

- `filter_applied` / `filter_cleared`
- `results_viewed` (count of results shown)
- `species_detail_opened` (which species)
- `location_changed`

### Implementation Details

- Opt-in toggle in settings (default: off)
- Events queued locally, sent in batches when online
- Simple HTTP POST to Cloud Function endpoint
- No retry logic for v1 (if it fails, it fails)
- No PII, no session tracking, no IP logging

### Infrastructure Side

- Cloud Function accepting JSON events
- Write to Cloud Storage or lightweight database
- Used to guide development priorities:
  - Which filters are used most
  - Which species are searched frequently
  - Where users encounter issues

## Development Workflow

### Local Development

1. VS Code with Flutter extension
2. Hot reload for instant UI updates
3. Run on iOS simulator, Android emulator, or Chrome (web)
4. Test against bundled SQLite database

### Git Workflow

- Feature branches with descriptive names (`feat/add-filter-ui`)
- Conventional commit format (`feat:`, `fix:`, `docs:`, etc.)
- Commit messages include list of changes and reasoning
- Merge to `main` when ready

### CI/CD Pipeline (GitLab)

- Run tests on all commits
- Build Android/iOS/web on `main` branch
- Deploy web automatically to GitLab Pages
- Generate APK/IPA artifacts for manual store upload
- Automated store publishing deferred to later milestone

### Testing Strategy

- Unit tests for filtering logic
- Widget tests for UI components
- Manual testing on real devices before release
- CI runs tests automatically

### Data Management

- SQLite database in main repo `assets/` directory, OR
- Separate repo for data pipeline with export to main repo
- Database updates = new app version (v1)
- Future: delta updates or remote database sync

## Milestones

### Milestone 1: MVP (v1)

- Filter mechanism with real-time results
- 10 California gull species with photos
- Detail view with species info
- Location filtering (California regions)
- Offline capability (mobile)
- Web deployment to GitLab Pages
- Settings: location preference, analytics opt-in

### Future Milestones (Post-MVP)

- Result ranking by match confidence
- Expand to all ABA North America gulls
- Seasonal filtering (breeding vs non-breeding plumages)
- Range maps in detail view
- Database delta updates (no full app update required)
- Comparison view (side-by-side species)
- Field notes / personal sighting log (requires accounts)
- Community contributions (photo submissions, sightings)

## Open Questions

- Data repo strategy: separate repo or subdirectory?
- Domain name selection
- Which 10 California species for initial launch?
- Cloud provider preference for analytics (GCP, AWS, or Azure)?

## Risks & Mitigations

**Risk:** Dart/Flutter could lose Google support in future.
**Mitigation:** Large existing community and production usage provide momentum. 5+ year lifespan expected. For a personal project, acceptable risk.

**Risk:** Manual data entry is time-consuming and error-prone.
**Mitigation:** Start small (10 species), validate approach, build tooling to assist. Accept that data quality takes time.

**Risk:** iOS publishing costs may not justify usage.
**Mitigation:** Launch Android + web first, evaluate traction before committing to $99/year Apple fee. Can always add iOS later.

**Risk:** Openly licensed photos may be limited for some species/plumages.
**Mitigation:** Start with well-photographed species. Reach out to birding community for contributions. Consider fair use for field guide scans as last resort (legal review required).

## Success Metrics (Post-Launch)

- App installs and active users
- Most-used filters (guides photo collection priorities)
- Most-searched species (guides expansion priorities)
- User feedback on accuracy and usefulness
- Contributions from community (photos, data corrections)
