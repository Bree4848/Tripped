# Tripped - Utility Fault Reporting Portal ⚡

A Flutter-based community utility management system integrated with **Supabase**. Tripped allows residents to report faults (electricity, water, etc.) and enables technicians and admins to manage repairs through a role-based dashboard system.

## 🚀 Features

* **Role-Based Access Control:** Distinct interfaces for Residents, Technicians, and Admins.
* **Real-time Fault Reporting:** Residents can submit issues with descriptions and track history.
* **Technician Dashboard:** View and manage assigned repair tasks.
* **News & Updates:** Centralized announcement feed for community members.
* **Secure Authentication:** Powered by Supabase Auth with password confirmation and visibility toggles.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Supabase (PostgreSQL, Auth, Storage)
* **State Management:** StatefulWidget / Provider logic
* **Security:** Row Level Security (RLS) & Environment Variables

## 📦 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git)
    cd your_repo_name
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Environment Variables:**
    Create a `.env` file in the root directory and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🔒 Security Note

This repository uses `.gitignore` to protect sensitive keys. Never commit your `.env` file to version control. Ensure **Row Level Security (RLS)** is enabled in your Supabase dashboard to protect user data.

## 📄 License
This project is for community utility management.
