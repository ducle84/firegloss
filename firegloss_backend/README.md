# FireGloss Backend

Python backend for the FireGloss Flutter application using Firebase Admin SDK.

**📍 Location**: Inside Flutter project at `firegloss/firegloss_backend/`

## Quick Start

1. **Navigate to backend directory:**

```bash
cd firegloss_backend
```

2. **Activate virtual environment:**

```bash
# Windows PowerShell
.\venv\Scripts\Activate.ps1
```

3. **Test Firebase connection:**

```bash
python test_firebase.py
```

4. **Start the API server:**

```bash
python main.py
```

## Setup Instructions

1. **Install dependencies** (if needed):

```bash
pip install -r requirements.txt
```

2. Set up Firebase credentials:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Generate a new private key
   - Save the JSON file as `service-account-key.json` in this directory

3. Copy environment file:

```bash
cp .env.example .env
```

4. Update `.env` with your configuration

5. Run the server:

```bash
python main.py
```

## API Endpoints

- `GET /` - Health check
- `POST /users` - Create a new user
- `GET /users/{user_id}` - Get user by ID
- `PUT /users/{user_id}` - Update user
- `DELETE /users/{user_id}` - Delete user

## Firebase Integration

The backend uses Firebase Admin SDK to:

- Read and write to Firestore
- Authenticate users
- Manage user data
