# Klarita Setup Guide

## 🚀 Quick Start (Recommended)

1. **Get your Google Gemini API Key**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key

2. **Configure the backend**:
   ```bash
   cd klarita_backend
   python3 setup.py
   # Edit .env file and add your GEMINI_API_KEY
   ```

3. **Start everything with one command**:
   ```bash
   ./start_klarita.sh
   ```

## 📋 Detailed Setup

### Prerequisites

- **Flutter SDK 3.32.6+**
- **Python 3.9+**
- **Google Gemini API Key**

### Step 1: Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd klarita_backend
   ```

2. **Run the setup script**:
   ```bash
   python3 setup.py
   ```

3. **Configure environment variables**:
   ```bash
   # Edit the .env file
   nano .env
   ```
   
   Add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_actual_api_key_here
   ```

4. **Start the backend**:
   ```bash
   python3 main.py
   ```

   The API will be available at `http://127.0.0.1:8000`
   API documentation at `http://127.0.0.1:8000/docs`

### Step 2: Frontend Setup

1. **Navigate to Flutter app**:
   ```bash
   cd klarita
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🔧 Configuration Options

### Backend Configuration (.env file)

```env
# Required
GEMINI_API_KEY=your_gemini_api_key_here

# Optional
DATABASE_URL=postgresql://user:password@localhost/klarita
JWT_SECRET=your_jwt_secret_here
HOST=127.0.0.1
PORT=8000
DEBUG=True
```

### Frontend Configuration

The Flutter app is configured to connect to `http://127.0.0.1:8000` by default. If you need to change this, edit `klarita/lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

## 🧪 Testing the Setup

### Backend Health Check

```bash
curl http://127.0.0.1:8000/
# Should return: {"message": "Welcome to the Enhanced Klarita AI Engine!"}
```

### API Documentation

Visit `http://127.0.0.1:8000/docs` in your browser to see the interactive API documentation.

### Flutter App Test

1. Start the Flutter app
2. Try to register a new account
3. Test the AI goal breakdown feature

## 🐛 Troubleshooting

### Common Issues

#### Backend Issues

**"Module not found" errors**:
```bash
cd klarita_backend
pip3 install -r requirements.txt
```

**"GEMINI_API_KEY not found"**:
- Make sure you've added your API key to the `.env` file
- Check that the file is in the `klarita_backend` directory

**Port already in use**:
```bash
# Find the process using port 8000
lsof -i :8000
# Kill the process
kill -9 <PID>
```

#### Frontend Issues

**"Connection refused" errors**:
- Make sure the backend is running
- Check that the API URL in `api_service.dart` is correct

**Flutter dependencies issues**:
```bash
cd klarita
flutter clean
flutter pub get
```

### Getting Help

1. Check the logs in the terminal
2. Visit the API documentation at `http://127.0.0.1:8000/docs`
3. Open an issue on GitHub

## 📱 Using the App

### First Time Setup

1. **Register an account** with your email and password
2. **Set your preferences** in the Profile screen
3. **Try the AI goal breakdown** by entering a goal on the Home screen

### Key Features

- **AI Goal Breakdown**: Enter any goal and get actionable steps
- **Pomodoro Timer**: Use the timer on task cards for focused work
- **Analytics**: Track your progress and productivity patterns
- **AI Coach**: Get help when you're feeling stuck

### Tips for ADHD Users

- **Start small**: Break down large goals into tiny steps
- **Use the timer**: 25-minute focused sessions work well
- **Track your mood**: This helps the AI personalize suggestions
- **Check analytics**: See your most productive times

## 🔄 Development Workflow

### Making Changes

1. **Backend changes**: Edit files in `klarita_backend/`
2. **Frontend changes**: Edit files in `klarita/lib/`
3. **Restart services** after making changes

### Adding New Features

1. **Backend**: Add new endpoints in `main.py`
2. **Frontend**: Add new screens in `klarita/lib/screens/`
3. **Models**: Update schemas in `schemas.py` and `task_models.dart`

## 📊 Monitoring

### Backend Logs

The backend logs are displayed in the terminal where you started it.

### Flutter Debug Console

Flutter app logs appear in the debug console when running `flutter run`.

## 🚀 Production Deployment

For production deployment, consider:

1. **Database**: Use PostgreSQL instead of SQLite
2. **Environment**: Set `DEBUG=False`
3. **Security**: Use strong JWT secrets
4. **Hosting**: Deploy backend to a cloud service
5. **SSL**: Use HTTPS in production

## 📞 Support

If you encounter issues:

1. Check this setup guide
2. Review the main README.md
3. Open an issue on GitHub
4. Check the API documentation at `http://127.0.0.1:8000/docs`

---

**Happy coding! 🎉** 