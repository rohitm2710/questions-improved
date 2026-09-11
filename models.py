from pydantic import BaseModel

class mcq(BaseModel):
    difficulty: str
    question: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    answer: str

class saq(BaseModel):
    question: str
    

class Question(BaseModel):
    category: str
    difficulty: str
    question_s: str
    answer: str