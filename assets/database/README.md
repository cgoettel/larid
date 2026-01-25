# Gull ID Database

This directory contains the SQLite database schema and data for the Gull ID app.

## Files

- `schema.sql`: Database schema (BCNF normalized)
- `sample_data.sql`: Sample data for testing and development
- `gull_id.db`: The compiled SQLite database (bundled with app)

## Schema Overview

The database is normalized to Boyce-Codd Normal Form (BCNF) for extensibility. Key tables:

- **species**: Master list of gull species
- **plumages**: Age and season-specific plumage variations
- **characteristics**: Observable features (leg color, bill pattern, etc.)
- **characteristic_values**: Possible values for each characteristic
- **plumage_characteristics**: Junction table linking plumages to their characteristics
- **regions**: Geographic regions (hierarchical)
- **species_regions**: Species occurrence by region
- **photos**: Openly licensed photo references

## Building the Database

To create or rebuild the database:

```bash
# Create empty database
sqlite3 gull_id.db < schema.sql

# Add sample data (for testing)
sqlite3 gull_id.db < sample_data.sql

# Add production data (when available)
sqlite3 gull_id.db < production_data.sql
```

## Adding New Species

To add a new species, insert rows into the following tables (in order):

1. **species**: Add the species
2. **plumages**: Add each age/season combination
3. **plumage_characteristics**: Link each plumage to its characteristic values
4. **species_regions**: Add regional occurrence data
5. **photos**: Add photo references (openly licensed only)

Example:

```sql
-- Add species
INSERT INTO species (common_name, scientific_name, taxonomic_order)
VALUES ('Ring-billed Gull', 'Larus delawarensis', 3);

-- Add adult breeding plumage
INSERT INTO plumages (species_id, age_class, season, description)
VALUES (3, 'adult', 'breeding', 'Adult Ring-billed Gull in breeding plumage');

-- Link characteristics (assuming characteristic_value_ids are known)
INSERT INTO plumage_characteristics (plumage_id, characteristic_value_id) VALUES
  (5, 2),  -- yellow legs
  (5, 6),  -- yellow bill
  (5, 14); -- black ring on bill

-- Add regional data
INSERT INTO species_regions (species_id, region_id, occurrence)
VALUES (3, 1, 'common');

-- Add photos
INSERT INTO photos (plumage_id, url, photographer, license, source)
VALUES (5, 'https://example.com/ring-billed-adult.jpg', 'Name', 'CC BY 4.0', 'Source');
```

## Data Sources

All data should come from reputable sources:

- **Species/Taxonomy**: eBird taxonomy
- **Plumage descriptions**: Field guides, eBird, expert birders
- **Photos**: Macaulay Library, iNaturalist (verify CC licenses)
- **Regional data**: eBird occurrence maps

## Photo Licensing

Only use photos with open licenses:
- Creative Commons (BY, BY-SA)
- Public Domain
- Explicitly permitted for educational use

Always record:
- Photographer name
- License type
- Source

## Validation

Before deploying database updates:

1. Every plumage must have at least one photo
2. All characteristic values must be defined in characteristic_values table
3. Region hierarchies must be valid (no circular references)
4. Foreign key constraints must be satisfied

TODO: Create validation script
