# Klarita - AI-Powered ADHD Task Management

Klarita is a comprehensive AI-powered task management application designed specifically for users with ADHD. It combines cutting-edge AI technology with proven behavioral techniques to help users overcome executive dysfunction and achieve their goals.

## 🚀 Features

### 1. AI-Powered Task Decomposition Engine
- **Smart Goal Breakdown**: Input any large goal and get it broken down into manageable, actionable steps
- **Personalized Task Generation**: AI learns from your patterns and preferences over time
- **Dynamic Task Management**: Edit, reorder, and customize generated tasks
- **Time Estimation**: AI provides realistic time estimates for each task
- **Priority Management**: Intelligent task prioritization based on your patterns

### 2. Hyper-Personalization Engine (RAG + Reinforcement Learning)
- **Learning System**: AI learns from your task completion patterns and preferences
- **Adaptive Recommendations**: Gets smarter with each interaction
- **Pattern Recognition**: Identifies your most productive times and task types
- **Memory System**: Remembers past successes and uses them as templates

### 3. Adaptive Gamification System
- **Points & Levels**: Earn points for completing tasks and level up
- **Badges & Achievements**: Unlock badges for milestones and streaks
- **Progress Tracking**: Visual progress indicators and statistics
- **Streak System**: Maintain daily streaks for consistent motivation
- **Rewards**: Immediate positive feedback for task completion

### 4. Integrated Focus Mode (Pomodoro Timer)
- **Built-in Timer**: Each task has an integrated Pomodoro timer
- **Focus Sessions**: Dedicated focus blocks for single tasks
- **Break Management**: Automatic break reminders and tracking
- **Audio Feedback**: Sound notifications for session completion
- **Progress Visualization**: Real-time timer with progress bars

### 5. "Feeling Stuck" AI Coach
- **Socratic Dialogue**: Gentle questioning to help identify the smallest first step
- **Emotional Support**: Calming, supportive conversation style
- **Context Awareness**: Remembers your past struggles and solutions
- **Quick Actions**: Pre-built responses for common stuck situations
- **Personalized Advice**: Tailored suggestions based on your history

### 6. Modern, ADHD-Friendly Design
- **Clean Interface**: Minimalist design with reduced cognitive load
- **Calming Colors**: Muted blues and greens for tranquility
- **Clear Hierarchy**: Well-organized layout with consistent navigation
- **Predictable Layouts**: Consistent placement of elements throughout
- **Smooth Animations**: Gentle transitions and micro-interactions

## 🏗️ Architecture

### Frontend (Flutter)
```
lib/
├── main.dart                 # App entry point and navigation
├── theme/
│   └── app_theme.dart        # ADHD-friendly design system
├── models/
│   └── task_models.dart      # Data models for tasks, sessions, etc.
├── providers/
│   ├── auth_provider.dart    # Authentication state management
│   └── task_provider.dart    # Task and gamification state
├── services/
│   └── api_service.dart      # Backend API communication
├── screens/
│   ├── analytics_screen.dart # Progress and statistics
│   ├── stuck_coach_screen.dart # AI coaching interface
│   └── profile_screen.dart   # User settings and profile
├── widgets/
│   └── enhanced_task_card.dart # Interactive task cards with timers
└── auth_screen.dart          # Login and registration
```

### Backend (FastAPI + Python)
```
klarita_backend/
├── main.py                   # FastAPI application and endpoints
├── models.py                 # SQLAlchemy database models
├── schemas.py                # Pydantic request/response schemas
├── database.py               # Database configuration
├── auth.py                   # Authentication and security
├── rag_handler.py            # AI and RAG implementation
└── requirements.txt          # Python dependencies
```

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **Google Fonts**: Typography
- **Flutter Animate**: Smooth animations
- **Audio Players**: Sound feedback
- **FL Chart**: Data visualization

### Backend
- **FastAPI**: Modern Python web framework
- **SQLAlchemy**: Database ORM
- **PostgreSQL**: Primary database
- **LangChain**: AI/LLM orchestration
- **ChromaDB**: Vector database for RAG
- **JWT**: Authentication tokens

## 📱 Installation & Setup

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.8+
- PostgreSQL
- Git

### Frontend Setup
```bash
# Clone the repository
git clone <repository-url>
cd klarita

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Backend Setup
```bash
# Navigate to backend directory
cd klarita_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
python -c "from database import engine; from models import Base; Base.metadata.create_all(engine)"

# Start the server
uvicorn main:app --reload
```

## 🎨 Design Principles

### ADHD-Friendly Design
- **Reduced Cognitive Load**: Clean, uncluttered interfaces
- **Clear Visual Hierarchy**: Consistent typography and spacing
- **Predictable Navigation**: Familiar patterns and layouts
- **Calming Color Palette**: Muted blues, greens, and neutral tones
- **Gentle Animations**: Smooth, non-distracting transitions

### Accessibility
- **High Contrast**: Clear text and element boundaries
- **Consistent Spacing**: Uniform padding and margins
- **Readable Typography**: Clear, legible fonts with good line height
- **Touch-Friendly**: Adequate button sizes and touch targets
- **Audio Feedback**: Optional sound notifications

## 🔧 Configuration

### Environment Variables
```bash
# Backend (.env)
DATABASE_URL=postgresql://user:password@localhost/klarita
SECRET_KEY=your-secret-key
OPENAI_API_KEY=your-openai-key
CHROMA_DB_PATH=./chroma_db
```

### App Configuration
- **Pomodoro Duration**: Default 25 minutes (customizable)
- **Break Duration**: Default 5 minutes (customizable)
- **Notification Settings**: Configurable reminders and alerts
- **AI Preferences**: Communication style and task breakdown preferences

## 📊 Analytics & Insights

### User Progress Tracking
- **Task Completion Rates**: Daily, weekly, and monthly statistics
- **Focus Time**: Total time spent in focused work sessions
- **Productivity Patterns**: Best times of day and task types
- **Gamification Stats**: Points, levels, badges, and streaks
- **Mood Tracking**: Post-task mood ratings for personalization

### AI Learning Metrics
- **Task Success Patterns**: What types of tasks work best for you
- **Time Estimation Accuracy**: How well AI predicts task duration
- **Personalization Effectiveness**: How well AI adapts to your preferences
- **Coaching Impact**: Effectiveness of "Feeling Stuck" sessions

## 🔒 Security & Privacy

### Data Protection
- **Encrypted Storage**: Secure token and sensitive data storage
- **JWT Authentication**: Secure session management
- **Input Validation**: Comprehensive request validation
- **SQL Injection Protection**: Parameterized queries
- **CORS Configuration**: Proper cross-origin resource sharing

### Privacy Features
- **Local Processing**: Sensitive data processed locally when possible
- **Data Anonymization**: Personal data anonymized for AI training
- **User Control**: Full control over data sharing and deletion
- **Transparent AI**: Clear explanation of AI decisions and recommendations

## 🚀 Future Enhancements

### Planned Features
- **Voice Input**: Speech-to-text for task creation
- **Smart Notifications**: AI-powered reminder timing
- **Social Features**: Optional sharing and accountability partners
- **Advanced Analytics**: Detailed productivity insights and trends
- **Integration APIs**: Connect with calendar, email, and other tools
- **Offline Mode**: Work without internet connection
- **Multi-Platform**: Web and desktop applications

### AI Improvements
- **Advanced RAG**: More sophisticated retrieval and generation
- **Multi-Modal AI**: Support for images and voice input
- **Predictive Analytics**: Anticipate user needs and patterns
- **Emotional Intelligence**: Better understanding of user emotional states
- **Contextual Awareness**: Deeper understanding of user environment

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for details on:
- Code style and standards
- Testing requirements
- Pull request process
- Issue reporting

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **ADHD Community**: For insights and feedback on design and features
- **Open Source Community**: For the amazing tools and libraries used
- **Research Community**: For studies on ADHD and productivity techniques
- **Beta Testers**: For valuable feedback and bug reports

## 📞 Support

- **Documentation**: [Link to docs]
- **Issues**: [GitHub Issues]
- **Discussions**: [GitHub Discussions]
- **Email**: support@klarita.app

---

**Klarita** - Empowering ADHD users to achieve their goals, one task at a time. 🚀
