from pathlib import Path

from db import get_conn


HL7_DIR = Path("data/hl7")


def parse_message(text: str):
    segments = [line.strip() for line in text.splitlines() if line.strip()]
    data = {"PID": None, "PV1": None, "OBX": []}
    for segment in segments:
        fields = segment.split("|")
        seg_type = fields[0]
        if seg_type == "PID":
            data["PID"] = fields
        elif seg_type == "PV1":
            data["PV1"] = fields
        elif seg_type == "OBX":
            data["OBX"].append(fields)
    return data


def parse_pid(pid_fields):
    if not pid_fields:
        return None
    patient_id = pid_fields[3] if len(pid_fields) > 3 else None
    name_field = pid_fields[5] if len(pid_fields) > 5 else ""
    parts = name_field.split("^")
    family_name = parts[0] if len(parts) > 0 else None
    given_name = parts[1] if len(parts) > 1 else None
    birth_date = pid_fields[7] if len(pid_fields) > 7 else None
    gender = pid_fields[8] if len(pid_fields) > 8 else None

    return {
        "patient_id": patient_id,
        "given_name": given_name,
        "family_name": family_name,
        "birth_date": birth_date,
        "gender": gender,
    }


def parse_pv1(pv1_fields):
    if not pv1_fields:
        return None
    encounter_id = pv1_fields[19] if len(pv1_fields) > 19 else None
    encounter_class = pv1_fields[2] if len(pv1_fields) > 2 else None
    location = pv1_fields[3] if len(pv1_fields) > 3 else None

    return {
        "encounter_id": encounter_id,
        "encounter_class": encounter_class,
        "location": location,
    }


def parse_obx(obx_fields):
    observation_id = obx_fields[1] if len(obx_fields) > 1 else None
    observation_code = obx_fields[3].split("^")[0] if len(obx_fields) > 3 else None
    observation_text = obx_fields[3].split("^")[1] if len(obx_fields) > 3 and "^" in obx_fields[3] else None
    value = obx_fields[5] if len(obx_fields) > 5 else None
    unit = obx_fields[6] if len(obx_fields) > 6 else None
    observed_at = obx_fields[14] if len(obx_fields) > 14 else None
    return {
        "observation_id": observation_id,
        "observation_code": observation_code,
        "observation_text": observation_text,
        "value": value,
        "unit": unit,
        "observed_at": observed_at,
    }


def load_hl7_file(cur, file_path: Path):
    text = file_path.read_text(encoding="utf-8")
    parsed = parse_message(text)
    pid = parse_pid(parsed["PID"])
    pv1 = parse_pv1(parsed["PV1"])

    if pid:
        cur.execute(
            """
            insert into raw.hl7_patients (patient_id, given_name, family_name, gender, birth_date, raw_payload)
            values (%s, %s, %s, %s, %s, %s)
            on conflict (patient_id) do update set
              given_name = excluded.given_name,
              family_name = excluded.family_name,
              gender = excluded.gender,
              birth_date = excluded.birth_date,
              raw_payload = excluded.raw_payload
            """,
            (pid["patient_id"], pid["given_name"], pid["family_name"], pid["gender"], pid["birth_date"], text),
        )

    if pid and pv1 and pv1["encounter_id"]:
        cur.execute(
            """
            insert into raw.hl7_encounters (encounter_id, patient_id, encounter_class, location, raw_payload)
            values (%s, %s, %s, %s, %s)
            on conflict (encounter_id) do update set
              patient_id = excluded.patient_id,
              encounter_class = excluded.encounter_class,
              location = excluded.location,
              raw_payload = excluded.raw_payload
            """,
            (pv1["encounter_id"], pid["patient_id"], pv1["encounter_class"], pv1["location"], text),
        )

    for obx in parsed["OBX"]:
        parsed_obx = parse_obx(obx)
        if not parsed_obx["observation_id"]:
            continue
        cur.execute(
            """
            insert into raw.hl7_observations
            (observation_id, patient_id, encounter_id, observation_code, observation_text, value_text, unit, observed_at, raw_payload)
            values (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            on conflict (observation_id) do update set
              patient_id = excluded.patient_id,
              encounter_id = excluded.encounter_id,
              observation_code = excluded.observation_code,
              observation_text = excluded.observation_text,
              value_text = excluded.value_text,
              unit = excluded.unit,
              observed_at = excluded.observed_at,
              raw_payload = excluded.raw_payload
            """,
            (
                parsed_obx["observation_id"],
                pid["patient_id"] if pid else None,
                pv1["encounter_id"] if pv1 else None,
                parsed_obx["observation_code"],
                parsed_obx["observation_text"],
                parsed_obx["value"],
                parsed_obx["unit"],
                parsed_obx["observed_at"],
                text,
            ),
        )


def main():
    files = sorted(HL7_DIR.glob("*.hl7"))
    if not files:
        print("No HL7 files found.")
        return

    with get_conn() as conn:
        with conn.cursor() as cur:
            for file_path in files:
                load_hl7_file(cur, file_path)
        conn.commit()
    print(f"Loaded {len(files)} HL7 file(s).")


if __name__ == "__main__":
    main()
