import { useState } from "react";
import API from "../api";

export default function StudentForm({ onStudentAdded }) {
  const [form, setForm] = useState({
    name: "",
    email: "",
    course: "",
  });

  const handleChange = (e) => {
    setForm({
      ...form,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    await API.post("/students", form);

    setForm({ name: "", email: "", course: "" });

    onStudentAdded(); // refresh list
  };

  return (
    <div style={{ marginBottom: "20px" }}>
      <h3 className="text-lg font-semibold mb-3 dark:text-white">Add Student</h3>

      <form onSubmit={handleSubmit} className="space-y-3">
        <input
          name="name"
          placeholder="Name"
          value={form.name}
          onChange={handleChange}
          className="w-full border p-3 rounded-lg dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:placeholder-gray-400"
        />

        <input
          name="email"
          placeholder="Email"
          value={form.email}
          onChange={handleChange}
          className="w-full border p-3 rounded-lg dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:placeholder-gray-400"
        />

        <input
          name="course"
          placeholder="Course"
          value={form.course}
          onChange={handleChange}
          className="w-full border p-3 rounded-lg dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:placeholder-gray-400"
        />

        <button
          type="submit"
          className="bg-indigo-500 hover:bg-indigo-600 text-white px-4 py-2 rounded-lg"
        >
          Add Student
        </button>
      </form>
    </div>
  );
}