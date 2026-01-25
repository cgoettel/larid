-- Sample data for testing
-- This file contains example data to demonstrate the schema structure

-- Sample characteristics
INSERT INTO characteristics (name, display_name, display_order) VALUES
  ('leg_color', 'Leg Color', 1),
  ('bill_color', 'Bill Color', 2),
  ('bill_pattern', 'Bill Pattern', 3),
  ('head_color', 'Head Color', 4),
  ('size', 'Size', 5);

-- Sample characteristic values
INSERT INTO characteristic_values (characteristic_id, value, display_name) VALUES
  -- Leg colors
  (1, 'pink', 'Pink'),
  (1, 'yellow', 'Yellow'),
  (1, 'gray', 'Gray'),
  (1, 'red', 'Red'),
  (1, 'black', 'Black'),
  -- Bill colors
  (2, 'yellow', 'Yellow'),
  (2, 'black', 'Black'),
  (2, 'red', 'Red'),
  (2, 'orange', 'Orange'),
  (2, 'pink', 'Pink'),
  -- Bill patterns
  (3, 'solid', 'Solid'),
  (3, 'black_tip', 'Black Tip'),
  (3, 'red_spot', 'Red Spot'),
  (3, 'black_ring', 'Black Ring'),
  -- Head colors
  (4, 'white', 'White'),
  (4, 'gray', 'Gray'),
  (4, 'brown', 'Brown'),
  (4, 'black', 'Black'),
  -- Sizes
  (5, 'small', 'Small (13-16 inches)'),
  (5, 'medium', 'Medium (16-19 inches)'),
  (5, 'large', 'Large (19-24 inches)'),
  (5, 'very_large', 'Very Large (24+ inches)');

-- Sample regions (California)
INSERT INTO regions (name, region_type, parent_region_id) VALUES
  ('California', 'state', NULL),
  ('Northern California', 'region', 1),
  ('Central California', 'region', 1),
  ('Southern California', 'region', 1),
  ('San Francisco Bay Area', 'region', 2),
  ('Los Angeles Area', 'region', 4);

-- Sample species
INSERT INTO species (common_name, scientific_name, taxonomic_order) VALUES
  ('Western Gull', 'Larus occidentalis', 1),
  ('California Gull', 'Larus californicus', 2);

-- Sample plumages
INSERT INTO plumages (species_id, age_class, season, description) VALUES
  (1, 'adult', 'breeding', 'Adult Western Gull in breeding plumage'),
  (1, 'first_year', NULL, 'First year Western Gull'),
  (2, 'adult', 'breeding', 'Adult California Gull in breeding plumage'),
  (2, 'first_year', NULL, 'First year California Gull');

-- Link plumages to characteristics
-- Western Gull - Adult Breeding
INSERT INTO plumage_characteristics (plumage_id, characteristic_value_id) VALUES
  (1, 1),  -- pink legs
  (1, 6),  -- yellow bill
  (1, 13), -- red spot on bill
  (1, 15), -- white head
  (1, 23); -- large size

-- Western Gull - First Year
INSERT INTO plumage_characteristics (plumage_id, characteristic_value_id) VALUES
  (2, 1),  -- pink legs
  (2, 7),  -- black bill
  (2, 11), -- solid bill
  (2, 17), -- brown head
  (2, 23); -- large size

-- California Gull - Adult Breeding
INSERT INTO plumage_characteristics (plumage_id, characteristic_value_id) VALUES
  (3, 2),  -- yellow legs
  (3, 6),  -- yellow bill
  (3, 13), -- red spot on bill
  (3, 15), -- white head
  (3, 22); -- medium size

-- California Gull - First Year
INSERT INTO plumage_characteristics (plumage_id, characteristic_value_id) VALUES
  (4, 1),  -- pink legs
  (4, 7),  -- black bill
  (4, 11), -- solid bill
  (4, 17), -- brown head
  (4, 22); -- medium size

-- Species occurrences
INSERT INTO species_regions (species_id, region_id, occurrence) VALUES
  (1, 1, 'common'),      -- Western Gull in California
  (1, 2, 'common'),      -- Northern CA
  (1, 3, 'common'),      -- Central CA
  (1, 4, 'common'),      -- Southern CA
  (2, 1, 'common'),      -- California Gull in California
  (2, 2, 'common'),      -- Northern CA
  (2, 3, 'uncommon'),    -- Central CA
  (2, 4, 'uncommon');    -- Southern CA

-- Sample photos (placeholder URLs - replace with actual openly licensed photos)
INSERT INTO photos (plumage_id, url, photographer, license, source) VALUES
  (1, 'https://example.com/western-gull-adult.jpg', 'Photographer Name', 'CC BY 4.0', 'Macaulay Library'),
  (2, 'https://example.com/western-gull-first-year.jpg', 'Photographer Name', 'CC BY 4.0', 'iNaturalist'),
  (3, 'https://example.com/california-gull-adult.jpg', 'Photographer Name', 'CC BY 4.0', 'Macaulay Library'),
  (4, 'https://example.com/california-gull-first-year.jpg', 'Photographer Name', 'CC BY 4.0', 'iNaturalist');
