create schema if not exists raw;
create schema if not exists analytics;

create table if not exists raw.fhir_patients (
    patient_id text primary key,
    given_name text,
    family_name text,
    gender text,
    birth_date date,
    deceased_flag boolean,
    raw_payload jsonb
);

create table if not exists raw.fhir_encounters (
    encounter_id text primary key,
    patient_id text,
    encounter_class text,
    encounter_status text,
    start_time timestamptz,
    end_time timestamptz,
    raw_payload jsonb
);

create table if not exists raw.fhir_conditions (
    condition_id text primary key,
    patient_id text,
    encounter_id text,
    condition_code text,
    condition_text text,
    clinical_status text,
    onset_time timestamptz,
    raw_payload jsonb
);

create table if not exists raw.fhir_observations (
    observation_id text primary key,
    patient_id text,
    encounter_id text,
    observation_code text,
    observation_text text,
    value_numeric numeric,
    unit text,
    observed_at timestamptz,
    raw_payload jsonb
);

create table if not exists raw.hl7_patients (
    patient_id text primary key,
    given_name text,
    family_name text,
    gender text,
    birth_date text,
    raw_payload text
);

create table if not exists raw.hl7_encounters (
    encounter_id text primary key,
    patient_id text,
    encounter_class text,
    location text,
    raw_payload text
);

create table if not exists raw.hl7_observations (
    observation_id text primary key,
    patient_id text,
    encounter_id text,
    observation_code text,
    observation_text text,
    value_text text,
    unit text,
    observed_at text,
    raw_payload text
);

create table if not exists raw.csv_patients (
    patient_id text primary key,
    given_name text,
    family_name text,
    gender text,
    birth_date date,
    source_file text
);

create table if not exists raw.csv_encounters (
    encounter_id text primary key,
    patient_id text,
    encounter_class text,
    encounter_status text,
    start_time timestamptz,
    end_time timestamptz,
    source_file text
);

create table if not exists raw.csv_observations (
    observation_id text primary key,
    patient_id text,
    encounter_id text,
    observation_code text,
    observation_text text,
    value_numeric numeric,
    unit text,
    observed_at timestamptz,
    source_file text
);
