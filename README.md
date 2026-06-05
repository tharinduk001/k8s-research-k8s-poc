# Student Management System

A full-stack Student Management System built with:

* Frontend: React + Vite + Tailwind CSS
* Backend: FastAPI + SQLAlchemy
* Database: PostgreSQL

## Features

* Add Students
* View Students
* Update Students
* Delete Students
* Search Students
* Dashboard Statistics
* Dark Mode

---

## Project Structure

```text
student_management/
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── ...
│
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── crud.py
│   ├── venv/
│   └── ...
│
└── README.md
```

---

## Prerequisites

Install the following:

* Python 3.10+
* Node.js 18+
* PostgreSQL

---

## Database Setup

Create a PostgreSQL database:

```sql
CREATE DATABASE studentdb;
```

Create the students table:

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    course VARCHAR(100)
);
```

---

## Backend Setup

Navigate to backend:

```bash
cd backend
```

Activate virtual environment:

```powershell
.\venv\Scripts\activate
```

Run FastAPI server:

```powershell
uvicorn main:app --reload
```

Backend runs at:

```text
http://127.0.0.1:8000
```

API Documentation:

```text
http://127.0.0.1:8000/docs
```

---

## Frontend Setup

Open a new terminal and navigate to frontend:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
```

Start development server:

```bash
npm run dev
```

Frontend runs at:

```text
http://localhost:5173
```

---

## API Endpoints

| Method | Endpoint       | Description       |
| ------ | -------------- | ----------------- |
| GET    | /students      | Get all students  |
| POST   | /students      | Create student    |
| GET    | /students/{id} | Get student by ID |
| PUT    | /students/{id} | Update student    |
| DELETE | /students/{id} | Delete student    |

---

## Running the Application

### Terminal 1 (Backend)

```powershell
cd backend
.\venv\Scripts\activate
uvicorn main:app --reload
```

### Terminal 2 (Frontend)

```bash
cd frontend
npm run dev
```

Open:

```text
http://localhost:5173
```

---

## Technologies Used

* React
* Vite
* Tailwind CSS
* FastAPI
* SQLAlchemy
* PostgreSQL
* Axios


