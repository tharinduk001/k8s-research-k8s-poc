import models
import schemas
from sqlalchemy.orm import Session

# CREATE
def create_student(db: Session, student: schemas.StudentCreate):
    db_student = models.Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student


# READ ALL
def get_students(db: Session):
    return db.query(models.Student).all()


# READ ONE
def get_student(db: Session, student_id: int):
    return db.query(models.Student).filter(models.Student.id == student_id).first()


# DELETE
def delete_student(db: Session, student_id: int):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()

    if student:
        db.delete(student)
        db.commit()
        return {"message": "deleted successfully"}

    return {"message": "student not found"}

def update_student(db: Session, student_id: int, updated_data):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()

    if student:
        student.name = updated_data.name
        student.email = updated_data.email
        student.course = updated_data.course

        db.commit()
        db.refresh(student)
        return student

    return {"message": "student not found"}