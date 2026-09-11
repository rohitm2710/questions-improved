import argparse
import json
import shutil
import sqlite3
import sys
from datetime import datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


COLUMNS = (
    "id",
    "difficulty",
    "question",
    "option_a",
    "option_b",
    "option_c",
    "option_d",
    "answer",
)


def fetch_questions(api_url: str) -> list[dict]:
    endpoint = api_url.rstrip("/") + "/questions"
    request = Request(endpoint, headers={"Accept": "application/json"})

    try:
        with urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except (HTTPError, URLError, TimeoutError) as error:
        raise RuntimeError(f"Could not fetch {endpoint}: {error}") from error

    questions = payload.get("value") if isinstance(payload, dict) else None
    if not isinstance(questions, list):
        raise RuntimeError("The API response does not contain a 'value' list.")

    for number, question in enumerate(questions, start=1):
        if not isinstance(question, dict) or any(column not in question for column in COLUMNS):
            raise RuntimeError(f"Question {number} is missing one or more required fields.")

    return questions


def prepare_database(database_path: Path) -> None:
    with sqlite3.connect(database_path) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS mcq(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                difficulty TEXT NOT NULL,
                question VARCHAR,
                option_a VARCHAR,
                option_b VARCHAR,
                option_c VARCHAR,
                option_d VARCHAR,
                answer TEXT NOT NULL
            )
            """
        )


def import_questions(database_path: Path, questions: list[dict], merge: bool) -> dict[str, int]:
    prepare_database(database_path)

    if not merge and database_path.exists():
        backup_path = database_path.with_name(
            f"{database_path.stem}.backup-{datetime.now():%Y%m%d-%H%M%S}{database_path.suffix}"
        )
        shutil.copy2(database_path, backup_path)
        print(f"Local backup: {backup_path}")

    with sqlite3.connect(database_path) as connection:
        if not merge:
            connection.execute("DELETE FROM mcq")

            connection.executemany(
                """
                INSERT INTO mcq
                    (id, difficulty, question, option_a, option_b, option_c, option_d, answer)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                [tuple(question[column] for column in COLUMNS) for question in questions],
            )
            return {"added": len(questions), "updated": 0, "skipped": 0}

        existing = {
            row[0]: dict(zip(COLUMNS, row))
            for row in connection.execute("SELECT * FROM mcq")
        }
        added = 0
        updated = 0
        skipped = 0

        for question in questions:
            question_id = question["id"]
            if question_id not in existing:
                connection.execute(
                    """
                    INSERT INTO mcq
                        (id, difficulty, question, option_a, option_b, option_c, option_d, answer)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    tuple(question[column] for column in COLUMNS),
                )
                added += 1
            elif all(existing[question_id][column] == question[column] for column in COLUMNS):
                skipped += 1
            else:
                connection.execute(
                    """
                    UPDATE mcq
                    SET difficulty = ?, question = ?, option_a = ?, option_b = ?,
                        option_c = ?, option_d = ?, answer = ?
                    WHERE id = ?
                    """,
                    tuple(question[column] for column in COLUMNS[1:]) + (question_id,),
                )
                updated += 1

    return {"added": added, "updated": updated, "skipped": skipped}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copy questions from a deployed Vercel API into a local SQLite database."
    )
    parser.add_argument("api_url", help="Vercel app URL, for example https://my-app.vercel.app")
    parser.add_argument(
        "--database",
        default="question.db",
        help="Local SQLite database path (default: question.db)",
    )
    parser.add_argument(
        "--merge",
        action="store_true",
        help="Keep existing local rows instead of replacing the mcq table",
    )
    arguments = parser.parse_args()
    database_path = Path(arguments.database).resolve()

    try:
        questions = fetch_questions(arguments.api_url)
        stats = import_questions(database_path, questions, arguments.merge)
    except (OSError, RuntimeError, sqlite3.Error) as error:
        print(f"Import failed: {error}", file=sys.stderr)
        return 1

    mode = "merged into" if arguments.merge else "copied into"
    print(
        f"{len(questions)} question(s) {mode} {database_path} "
        f"(added: {stats['added']}, updated: {stats['updated']}, skipped: {stats['skipped']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())