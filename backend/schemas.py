from pydantic import BaseModel

class StudentCreate(BaseModel):
    name: str
    email: str
    course: str

class Student(StudentCreate):
    id: int

    class Config:
        from_attributes = True