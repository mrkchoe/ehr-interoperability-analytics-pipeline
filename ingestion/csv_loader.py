import csv
from pathlib import Path

from db import get_conn


CSV_DIR = Path("data/csv")


def load_patients(cur, file_path: Path):
    with file_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute(
                """
                insert into raw.csv_patients
                (patient_id, given_name, family_name, gender, birth_date, source_file)
                values (%s, %s, %s, %s, %s, %s)
                on conflict (patient_id) do update set
                  given_name = excluded.given_name,
                  family_name = excluded.family_name,
                  gender = excluded.gender,
                  birth_date = excluded.birth_date,
                  source_file = excluded.source_file
                """,
                (
                    row["patient_id"],
                    row.get("given_name"),
                    row.get("family_name"),
                    row.get("gender"),
                    row.get("birth_date"),
                    file_path.name,
                ),
            )


def load_encounters(cur, file_path: Path):
    with file_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute(
                """
                insert into raw.csv_encounters
                (encounter_id, patient_id, encounter_class, encounter_status, start_time, end_time, source_file)
                values (%s, %s, %s, %s, %s, %s, %s)
                on conflict (encounter_id) do update set
                  patient_id = excluded.patient_id,
                  encounter_class = excluded.encounter_class,
                  encounter_status = excluded.encounter_status,
                  start_time = excluded.start_time,
                  end_time = excluded.end_time,
                  source_file = excluded.source_file
                """,
                (
                    row["encounter_id"],
                    row.get("patient_id"),
                    row.get("encounter_class"),
                    row.get("encounter_status"),
                    row.get("start_time"),
                    row.get("end_time"),
                    file_path.name,
                ),
            )


def load_observations(cur, file_path: Path):
    with file_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute(
                """
                insert into raw.csv_observations
                (observation_id, patient_id, encounter_id, observation_code, observation_text, value_numeric, unit, observed_at, source_file)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                on conflict (observation_id) do update set
                  patient_id = excluded.patient_id,
                  encounter_id = excluded.encounter_id,
                  observation_code = excluded.observation_code,
                  observation_text = excluded.observation_text,
                  value_numeric = excluded.value_numeric,
                  unit = excluded.unit,
                  observed_at = excluded.observed_at,
                  source_file = excluded.source_file
                """,
                (
                    row["observation_id"],
                    row.get("patient_id"),
                    row.get("encounter_id"),
                    row.get("observation_code"),
                    row.get("observation_text"),
                    row.get("value_numeric"),
                    row.get("unit"),
                    row.get("observed_at"),
                    file_path.name,
                ),
            )


def main():
    with get_conn() as conn:
        with conn.cursor() as cur:
            patients_file = CSV_DIR / "patients.csv"
            encounters_file = CSV_DIR / "encounters.csv"
            observations_file = CSV_DIR / "observations.csv"
            if patients_file.exists():
                load_patients(cur, patients_file)
            if encounters_file.exists():
                load_encounters(cur, encounters_file)
            if observations_file.exists():
                load_observations(cur, observations_file)
        conn.commit()

    print("Loaded CSV extracts.")


if __name__ == "__main__":
    main()
