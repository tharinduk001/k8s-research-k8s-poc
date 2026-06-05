import { useEffect, useState } from "react";
import API from "./api";
import StudentForm from "./components/StudentForm";
import {
  Pencil,
  Trash2,
  X,
  Moon,
  Sun,
  Search,
} from "lucide-react";

function App() {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState("");

  const [darkMode, setDarkMode] = useState(
    localStorage.getItem("theme") === "dark"
  );

  const [editingStudent, setEditingStudent] = useState(null);

  const [editForm, setEditForm] = useState({
    name: "",
    email: "",
    course: "",
  });

  useEffect(() => {
    fetchStudents();
  }, []);

  useEffect(() => {
    localStorage.setItem("theme", darkMode ? "dark" : "light");
  }, [darkMode]);

  const fetchStudents = async () => {
    try {
      setLoading(true);

      const res = await API.get("/students");

      setStudents(res.data);
    } catch (error) {
      console.error("Fetch Error:", error);
    } finally {
      setLoading(false);
    }
  };

  const deleteStudent = async (id) => {
    try {
      await API.delete(`/students/${id}`);
      fetchStudents();
    } catch (error) {
      console.error(error);
    }
  };

  const openEdit = (student) => {
    setEditingStudent(student);

    setEditForm({
      name: student.name,
      email: student.email,
      course: student.course,
    });
  };

  const updateStudent = async () => {
    try {
      await API.put(
        `/students/${editingStudent.id}`,
        editForm
      );

      setEditingStudent(null);

      fetchStudents();
    } catch (error) {
      console.error(error);
    }
  };

  const totalStudents = students.length;

  const uniqueCourses = [
    ...new Set(students.map((s) => s.course))
  ].length;

  const latestStudent =
    students.length > 0
      ? students[students.length - 1].name
      : "None";

  const filteredStudents = students.filter(
    (student) =>
      student.name
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      student.email
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      student.course
        .toLowerCase()
        .includes(search.toLowerCase())
  );

  return (
    <div
      className={`min-h-screen p-6 transition-all duration-300 ${
        darkMode
          ? "dark bg-gray-950 text-white"
          : "bg-gradient-to-br from-indigo-50 via-white to-purple-50"
      }`}
    >
      <div className="max-w-6xl mx-auto">

        {/* HEADER */}

        <div className="flex justify-between items-center mb-8">
          <div className="flex-1 text-center">
            <h1 className="text-5xl font-extrabold">
              Student Management Dashboard
            </h1>

            <p className="mt-2 text-gray-500 dark:text-gray-400">
              Manage students efficiently
            </p>
          </div>

          <button
            onClick={() => setDarkMode(!darkMode)}
            className="p-3 rounded-xl bg-indigo-500 text-white"
          >
            {darkMode ? (
              <Sun size={20} />
            ) : (
              <Moon size={20} />
            )}
          </button>
        </div>

        {/* STATS */}

        <div className="grid md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-lg">
            <p className="text-gray-500 dark:text-gray-400">Total Students</p>
            <h2 className="text-4xl font-bold dark:text-white">
              {totalStudents}
            </h2>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-lg">
            <p className="text-gray-500 dark:text-gray-400">Courses</p>
            <h2 className="text-4xl font-bold dark:text-white">
              {uniqueCourses}
            </h2>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-lg">
            <p className="text-gray-500 dark:text-gray-400">Latest Student</p>
            <h2 className="text-2xl font-bold dark:text-white">
              {latestStudent}
            </h2>
          </div>
        </div>

        {/* SEARCH */}

        <div className="relative mb-6">
          <Search
            size={18}
            className="absolute left-4 top-4 text-gray-400"
          />

          <input
            type="text"
            placeholder="Search students..."
            value={search}
            onChange={(e) =>
              setSearch(e.target.value)
            }
            className="w-full pl-12 pr-4 py-3 rounded-xl border bg-white dark:bg-gray-800 text-black dark:text-white dark:border-gray-700"
          />
        </div>

        {/* FORM */}

        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-5 mb-6">
          <StudentForm onStudentAdded={fetchStudents} />
        </div>

        {/* LOADING */}

        {loading && (
          <div className="text-center py-10">
            Loading students...
          </div>
        )}

        {/* EMPTY */}

        {!loading &&
          filteredStudents.length === 0 && (
            <div className="text-center py-10">
              No students found
            </div>
          )}

       {/* STUDENT TABLE */}

<div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg overflow-hidden">
  <table className="w-full">
    <thead className="bg-indigo-600 text-white">
      <tr>
        <th className="text-left px-6 py-4">ID</th>
        <th className="text-left px-6 py-4">Name</th>
        <th className="text-left px-6 py-4">Email</th>
        <th className="text-left px-6 py-4">Course</th>
        <th className="text-center px-6 py-4">Actions</th>
      </tr>
    </thead>

    <tbody>
      {filteredStudents.map((s) => (
        <tr
          key={s.id}
          className="border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 transition"
        >
          <td className="px-6 py-4 dark:text-gray-200">{s.id}</td>

          <td className="px-6 py-4 font-medium dark:text-white">
            {s.name}
          </td>

          <td className="px-6 py-4 dark:text-gray-200">
            {s.email}
          </td>

          <td className="px-6 py-4">
            <span className="bg-indigo-100 dark:bg-indigo-900 text-indigo-600 dark:text-indigo-300 px-3 py-1 rounded-full text-sm">
              {s.course}
            </span>
          </td>

          <td className="px-6 py-4">
            <div className="flex justify-center gap-2">
              <button
                onClick={() => openEdit(s)}
                className="bg-indigo-500 hover:bg-indigo-600 text-white p-2 rounded-lg"
              >
                <Pencil size={16} />
              </button>

              <button
                onClick={() => deleteStudent(s.id)}
                className="bg-red-500 hover:bg-red-600 text-white p-2 rounded-lg"
              >
                <Trash2 size={16} />
              </button>
            </div>
          </td>
        </tr>
      ))}
    </tbody>
  </table>
</div>

        {/* EDIT MODAL */}

        {editingStudent && (
          <div className="fixed inset-0 bg-black/50 flex justify-center items-center">
            <div className="bg-white p-6 rounded-2xl w-[90%] max-w-md relative">

              <button
                onClick={() =>
                  setEditingStudent(null)
                }
                className="absolute top-4 right-4"
              >
                <X />
              </button>

              <h2 className="text-2xl font-bold mb-4 text-black">
                Edit Student
              </h2>

              <div className="space-y-3">
                <input
                  className="w-full border p-3 rounded-lg text-black"
                  value={editForm.name}
                  onChange={(e) =>
                    setEditForm({
                      ...editForm,
                      name: e.target.value,
                    })
                  }
                />

                <input
                  className="w-full border p-3 rounded-lg text-black"
                  value={editForm.email}
                  onChange={(e) =>
                    setEditForm({
                      ...editForm,
                      email: e.target.value,
                    })
                  }
                />

                <input
                  className="w-full border p-3 rounded-lg text-black"
                  value={editForm.course}
                  onChange={(e) =>
                    setEditForm({
                      ...editForm,
                      course: e.target.value,
                    })
                  }
                />

                <button
                  onClick={updateStudent}
                  className="w-full bg-indigo-500 text-white py-3 rounded-xl"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;