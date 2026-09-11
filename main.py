from contextlib import asynccontextmanager
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import models
import sqlite3

db = os.getenv("DATABASE_PATH", "/tmp/question.db" if os.getenv("VERCEL") else "question.db")


def init_mcq():
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    cursor.execute('''
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
    ''')
    conn.commit()
    conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Make sure the table exists before the first request, so a fresh
    # deployment doesn't 500 on GET /questions before anyone has POSTed.
    init_mcq()
    yield


app = FastAPI(lifespan=lifespan)

# The frontend (Vite dev server / static file / Vercel deployment) is a
# different origin than this API, so the browser needs an explicit CORS
# allow before it will let fetch() calls through. Wide open for local
# development; narrow this to the real frontend origin(s) in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/questions")
def get_all_questions():
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM mcq")

    rows = [dict(row) for row in cursor.fetchall()]

    conn.close()

    return {
        "value": rows,
        "Count": len(rows),
    }


@app.post("/mcq")
def add_mcq(ques: models.mcq):
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    cursor.execute(
        '''
            INSERT INTO mcq (difficulty, question, option_a, option_b, option_c, option_d, answer)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        (ques.difficulty, ques.question, ques.option_a, ques.option_b, ques.option_c, ques.option_d, ques.answer)
    )
    conn.commit()

    ques_num = cursor.lastrowid

    conn.close()

    return {
        "message": "Question succesfully added",
        "number": ques_num
    }
