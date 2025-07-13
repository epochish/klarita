# Klarita - AI-Powered ADHD Task Management App

Klarita is a comprehensive mHealth application designed specifically for users with ADHD to overcome executive dysfunction by breaking down large goals into actionable steps. The app features AI-powered task decomposition, personalized coaching, and gamification elements to keep users engaged and motivated.

## 🌟 Features

### 🤖 AI-Powered Task Decomposition
- **Smart Goal Breakdown**: Converts complex goals into small, actionable tasks
- **Personalized Approach**: Adapts to user's time of day, mood, and energy levels
- **RAG-Powered Learning**: Learns from successful task completions to improve future suggestions

### 🎯 Gamification System
- **Points & Levels**: Earn points for completing tasks and level up
- **Streaks**: Track daily completion streaks for motivation
- **Badges & Achievements**: Unlock achievements for milestones
- **Progress Visualization**: Beautiful charts and analytics

### ⏱️ Focus Tools
- **Pomodoro Timer**: Integrated 25/5 minute work/break cycles
- **Focus Sessions**: Track actual vs. estimated task duration
- **Audio Feedback**: Sound notifications for timer completion

### 🧠 "Feeling Stuck" AI Coach
- **Emotional Support**: AI-powered chat for when you're overwhelmed
- **Actionable Advice**: Get specific suggestions to move forward
- **Mood Tracking**: Monitor emotional state throughout the day

### 📊 Analytics & Insights
- **Productivity Trends**: Track completion rates over time
- **Best Time Analysis**: Discover your most productive hours
- **Mood Correlation**: See how mood affects task completion
- **Focus Time Stats**: Monitor deep work sessions

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.32.6
- **State Management**: Provider pattern
- **UI/UX**: ADHD-friendly design with calming colors
- **Platforms**: iOS, Android, Web, macOS

### Backend (FastAPI)
- **Framework**: FastAPI with Python 3.9+
- **Database**: SQLite (with PostgreSQL support)
- **AI Integration**: Google Gemini API via LangChain
- **Vector Database**: ChromaDB for RAG functionality
- **Authentication**: JWT-based with secure storage

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.32.6+
- Python 3.9+
- Google Gemini API Key

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd klarita_backend
   ```

2. **Run setup script**:
   ```bash
   python3 setup.py
   ```

3. **Install dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```

4. **Configure environment**:
   - Edit `.env` file
   - Add your `GEMINI_API_KEY` from [Google AI Studio](https://makersuite.google.com/app/apikey)

5. **Start the backend**:
   ```bash
   python3 main.py
   ```

   The API will be available at `http://127.0.0.1:8000`
   API documentation at `http://127.0.0.1:8000/docs`

### Frontend Setup

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

## 🎨 Design Principles

### ADHD-Friendly UI/UX
- **Calming Color Palette**: Soft blues, greens, and neutral tones
- **Clear Visual Hierarchy**: Consistent spacing and typography
- **Minimal Distractions**: Clean, uncluttered interface
- **Predictable Layouts**: Familiar navigation patterns
- **Large Touch Targets**: Easy-to-tap buttons and controls

### Accessibility Features
- **High Contrast Mode**: Support for users with visual impairments
- **Screen Reader Support**: Full VoiceOver/TalkBack compatibility
- **Keyboard Navigation**: Complete keyboard accessibility
- **Font Scaling**: Dynamic text size adjustment

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the `klarita_backend` directory:

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

### API Endpoints

#### Authentication
- `POST /token` - Login
- `POST /users/` - Register

#### AI Services
- `POST /breakdown/` - Break down goals into tasks
- `POST /chat/stuck-coach` - AI coaching chat

#### Task Management
- `GET /sessions/` - Get user's task sessions
- `PUT /tasks/{task_id}` - Update task status

#### Timer
- `POST /timer/start` - Start Pomodoro timer
- `PUT /timer/{timer_id}/complete` - Complete timer session

#### Analytics
- `GET /analytics/summary` - Get user analytics and progress

#### Preferences
- `POST /preferences/` - Create user preferences
- `PUT /preferences/` - Update user preferences

## 📱 App Screenshots

### Home Screen
- AI goal breakdown interface
- Current task session display
- Quick mood and energy tracking

### Analytics Screen
- Productivity trends and charts
- Gamification progress
- Focus time statistics

### Coach Screen
- AI chat interface
- Quick action suggestions
- Mood tracking integration

### Profile Screen
- User statistics and achievements
- Settings and preferences
- About and help information

## 🔒 Security

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt for password security
- **Secure Storage**: Flutter secure storage for sensitive data
- **CORS Configuration**: Proper cross-origin resource sharing
- **Input Validation**: Comprehensive request validation

## 🧪 Testing

### Backend Testing
```bash
cd klarita_backend
python3 -m pytest tests/
```

### Frontend Testing
```bash
cd klarita
flutter test
```

## 📈 Performance

### Backend Optimizations
- **Async/Await**: Non-blocking I/O operations
- **Database Indexing**: Optimized query performance
- **Caching**: Vector store caching for RAG operations
- **Connection Pooling**: Efficient database connections

### Frontend Optimizations
- **Lazy Loading**: On-demand screen loading
- **Image Optimization**: Compressed assets
- **State Management**: Efficient Provider usage
- **Memory Management**: Proper disposal of resources

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Gemini API** for AI capabilities
- **LangChain** for RAG implementation
- **Flutter** for cross-platform development
- **FastAPI** for high-performance backend
- **ADHD Community** for feedback and insights

## 📞 Support

For support, please open an issue on GitHub or contact the development team.

---

**Made with ❤️ for the ADHD community** 