-- Gull ID Database Schema
-- Normalized to Boyce-Codd Normal Form (BCNF)

-- Species master table
CREATE TABLE IF NOT EXISTS species (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  common_name TEXT NOT NULL,
  scientific_name TEXT NOT NULL UNIQUE,
  taxonomic_order INTEGER
);

-- Plumage variations (normalized by age and season)
CREATE TABLE IF NOT EXISTS plumages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  species_id INTEGER NOT NULL,
  age_class TEXT NOT NULL,
  season TEXT,
  description TEXT,
  UNIQUE(species_id, age_class, season),
  FOREIGN KEY (species_id) REFERENCES species(id) ON DELETE CASCADE
);

-- Characteristic types (leg color, bill pattern, etc.)
CREATE TABLE IF NOT EXISTS characteristics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  display_order INTEGER
);

-- Possible values for each characteristic
CREATE TABLE IF NOT EXISTS characteristic_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  characteristic_id INTEGER NOT NULL,
  value TEXT NOT NULL,
  display_name TEXT NOT NULL,
  UNIQUE(characteristic_id, value),
  FOREIGN KEY (characteristic_id) REFERENCES characteristics(id) ON DELETE CASCADE
);

-- Links plumages to their characteristics (junction table)
-- Supports multiple values per characteristic if needed
CREATE TABLE IF NOT EXISTS plumage_characteristics (
  plumage_id INTEGER NOT NULL,
  characteristic_value_id INTEGER NOT NULL,
  PRIMARY KEY(plumage_id, characteristic_value_id),
  FOREIGN KEY (plumage_id) REFERENCES plumages(id) ON DELETE CASCADE,
  FOREIGN KEY (characteristic_value_id) REFERENCES characteristic_values(id) ON DELETE CASCADE
);

-- Geographic regions (hierarchical)
CREATE TABLE IF NOT EXISTS regions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  region_type TEXT,
  parent_region_id INTEGER,
  FOREIGN KEY (parent_region_id) REFERENCES regions(id) ON DELETE CASCADE
);

-- Species occurrence by region
CREATE TABLE IF NOT EXISTS species_regions (
  species_id INTEGER NOT NULL,
  region_id INTEGER NOT NULL,
  occurrence TEXT,
  PRIMARY KEY(species_id, region_id),
  FOREIGN KEY (species_id) REFERENCES species(id) ON DELETE CASCADE,
  FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE CASCADE
);

-- Photo references (openly licensed)
CREATE TABLE IF NOT EXISTS photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plumage_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  photographer TEXT,
  license TEXT NOT NULL,
  source TEXT,
  FOREIGN KEY (plumage_id) REFERENCES plumages(id) ON DELETE CASCADE
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_plumages_species ON plumages(species_id);
CREATE INDEX IF NOT EXISTS idx_characteristic_values_characteristic ON characteristic_values(characteristic_id);
CREATE INDEX IF NOT EXISTS idx_plumage_characteristics_plumage ON plumage_characteristics(plumage_id);
CREATE INDEX IF NOT EXISTS idx_plumage_characteristics_value ON plumage_characteristics(characteristic_value_id);
CREATE INDEX IF NOT EXISTS idx_species_regions_species ON species_regions(species_id);
CREATE INDEX IF NOT EXISTS idx_species_regions_region ON species_regions(region_id);
CREATE INDEX IF NOT EXISTS idx_photos_plumage ON photos(plumage_id);
