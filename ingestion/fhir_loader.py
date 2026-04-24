import json
import os
from pathlib import Path

import psycopg


FHIR_DIR = Path("data/fhir")


def get_conn():
    return psycopg.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "ehr"),
        password=os.getenv("PGPASSWORD", "ehr"),
        dbname=os.getenv("PGDATABASE", "ehr_analytics"),
    )


def load_fhir_file(cur, file_path: Path):
    with file_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            resource = json.loads(line)
            resource_type = resource.get("resourceType")
            if resource_type == "Patient":
                insert_patient(cur, resource)
            elif resource_type == "Encounter":
                insert_encounter(cur, resource)
            elif resource_type == "Condition":
                insert_condition(cur, resource)
            elif resource_type == "Observation":
                insert_observation(cur, resource)


def first_code(resource: dict, key: str):
    codings = resource.get(key, [])
    if codings and isinstance(codings, list):
        return codings[0].get("code")
    return None


def single_reference(resource: dict, key: str):
    ref = resource.get(key, {}).get("reference")
    if not ref:
        return None
    return ref.split("/")[-1]


def insert_patient(cur, patient: dict):
    patient_id = patient.get("id")
    name = patient.get("name", [{}])[0]
    given = " ".join(name.get("given", [])) if name.get("given") else None
    family = name.get("family")
    gender = patient.get("gender")
    birth_date = patient.get("birthDate")
    deceased = patient.get("deceasedBoolean")

    cur.execute(
        """
        insert into raw.fhir_patients
        (patient_id, given_name, family_name, gender, birth_date, deceased_flag, raw_payload)
        values (%s, %s, %s, %s, %s, %s, %s::jsonb)
        on conflict (patient_id) do update set
          given_name = excluded.given_name,
          family_name = excluded.family_name,
          gender = excluded.gender,
          birth_date = excluded.birth_date,
          deceased_flag = excluded.deceased_flag,
          raw_payload = excluded.raw_payload
        """,
        (patient_id, given, family, gender, birth_date, deceased, json.dumps(patient)),
    )


def insert_encounter(cur, encounter: dict):
    encounter_id = encounter.get("id")
    patient_id = single_reference(encounter, "subject")
    encounter_class = encounter.get("class", {}).get("code")
    encounter_status = encounter.get("status")
    start_time = encounter.get("period", {}).get("start")
    end_time = encounter.get("period", {}).get("end")

    cur.execute(
        """
        insert into raw.fhir_encounters
        (encounter_id, patient_id, encounter_class, encounter_status, start_time, end_time, raw_payload)
        values (%s, %s, %s, %s, %s, %s, %s::jsonb)
        on conflict (encounter_id) do update set
          patient_id = excluded.patient_id,
          encounter_class = excluded.encounter_class,
          encounter_status = excluded.encounter_status,
          start_time = excluded.start_time,
          end_time = excluded.end_time,
          raw_payload = excluded.raw_payload
        """,
        (
            encounter_id,
            patient_id,
            encounter_class,
            encounter_status,
            start_time,
            end_time,
            json.dumps(encounter),
        ),
    )


def insert_condition(cur, condition: dict):
    condition_id = condition.get("id")
    patient_id = single_reference(condition, "subject")
    encounter_id = single_reference(condition, "encounter")
    code = first_code(condition.get("code", {}), "coding")
    text = condition.get("code", {}).get("text")
    clinical_status = first_code(condition.get("clinicalStatus", {}), "coding")
    onset_date = condition.get("onsetDateTime")

    cur.execute(
        """
        insert into raw.fhir_conditions
        (condition_id, patient_id, encounter_id, condition_code, condition_text, clinical_status, onset_time, raw_payload)
        values (%s, %s, %s, %s, %s, %s, %s, %s::jsonb)
        on conflict (condition_id) do update set
          patient_id = excluded.patient_id,
          encounter_id = excluded.encounter_id,
          condition_code = excluded.condition_code,
          condition_text = excluded.condition_text,
          clinical_status = excluded.clinical_status,
          onset_time = excluded.onset_time,
          raw_payload = excluded.raw_payload
        """,
        (
            condition_id,
            patient_id,
            encounter_id,
            code,
            text,
            clinical_status,
            onset_date,
            json.dumps(condition),
        ),
    )


def insert_observation(cur, observation: dict):
    observation_id = observation.get("id")
    patient_id = single_reference(observation, "subject")
    encounter_id = single_reference(observation, "encounter")
    code = first_code(observation.get("code", {}), "coding")
    code_text = observation.get("code", {}).get("text")
    value_num = observation.get("valueQuantity", {}).get("value")
    unit = observation.get("valueQuantity", {}).get("unit")
    observed_at = observation.get("effectiveDateTime")

    cur.execute(
        """
        insert into raw.fhir_observations
        (observation_id, patient_id, encounter_id, observation_code, observation_text, value_numeric, unit, observed_at, raw_payload)
        values (%s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb)
        on conflict (observation_id) do update set
          patient_id = excluded.patient_id,
          encounter_id = excluded.encounter_id,
          observation_code = excluded.observation_code,
          observation_text = excluded.observation_text,
          value_numeric = excluded.value_numeric,
          unit = excluded.unit,
          observed_at = excluded.observed_at,
          raw_payload = excluded.raw_payload
        """,
        (
            observation_id,
            patient_id,
            encounter_id,
            code,
            code_text,
            value_num,
            unit,
            observed_at,
            json.dumps(observation),
        ),
    )


def main():
    files = sorted(FHIR_DIR.glob("*.ndjson"))
    if not files:
        print("No FHIR files found.")
        return

    with get_conn() as conn:
        with conn.cursor() as cur:
            for file_path in files:
                load_fhir_file(cur, file_path)
        conn.commit()
    print(f"Loaded {len(files)} FHIR file(s).")


if __name__ == "__main__":
    main()
