# Klarita AI Engine - Enhanced Backend

## Overview

Klarita is an AI-powered mHealth application designed to help users with ADHD overcome executive dysfunction. This enhanced backend provides personalized task breakdown, Pomodoro timers, analytics, and emotional support through advanced AI features.

## 🚀 New Features in Version 0.7.0

### Core Enhancements
- **Personalized RAG Pipeline**: Context-aware task breakdowns based on time of day, mood, and user preferences
- **Pomodoro Timer System**: Integrated timer sessions with task completion tracking
- **Analytics Dashboard**: Comprehensive productivity metrics and insights
- **"Feeling Stuck" AI Coach**: Socratic questioning and emotional support
- **User Preferences**: Customizable AI behavior and productivity settings
- **Enhanced Task Management**: Task reordering, editing, and metadata tracking

### Technical Improvements
- **Enhanced Database Schema**: Support for timers, analytics, chat, and user preferences
- **Improved RAG Retrieval**: Better context retrieval with metadata filtering
- **Comprehensive API**: 15+ new endpoints for full feature coverage
- **Better Error Handling**: Robust error management and validation

## 🏗️ Architecture

```
klarita_backend/
├── main.py              # FastAPI application with all endpoints
├── models.py            # SQLAlchemy ORM models
├── schemas.py           # Pydantic request/response models
├── database.py          # Database connection and session management
├── auth.py              # JWT authentication and password hashing
├── rag_handler.py       # Enhanced RAG pipeline with personalization
├── requirements.txt     # Python dependencies
└── chroma_db/           # Vector database for RAG
```

## 🛠️ Setup Instructions

### Prerequisites
- Python 3.9+
- PostgreSQL database
- Google Gemini API key
- Conda environment (recommended)

### Installation

1. **Clone and navigate to the project**
   ```bash
   cd klarita_backend
   ```

2. **Create and activate conda environment**
   ```bash
   conda create -n klarita python=3.9
   conda activate klarita
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   Create a `.env` file:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   DATABASE_URL=postgresql://username:password@localhost:5432/klarita_db
   SECRET_KEY=your_secret_key_here
   ```

5. **Initialize database**
   ```bash
   python -c "from models import Base; from database import engine; Base.metadata.create_all(bind=engine)"
   ```

6. **Run the application**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

## 📚 API Documentation

### Authentication Endpoints
- `POST /token` - Login and get JWT token
- `POST /users/` - Register new user

### AI Services
- `POST /breakdown/` - Enhanced task breakdown with personalization
- `POST /chat/stuck-coach` - AI coach for when users feel stuck

### Timer Management
- `POST /timer/start` - Start a Pomodoro timer session
- `PUT /timer/{timer_id}/complete` - Complete a timer session

### Task Management
- `PUT /tasks/{task_id}` - Update task details and completion status

### Analytics
- `GET /analytics/summary` - Get comprehensive productivity analytics

### User Preferences
- `POST /preferences/` - Create user preferences
- `PUT /preferences/` - Update user preferences

### Feedback
- `POST /feedback/success/{session_id}` - Mark session as successful for RAG learning

## 🔧 Development Guide

### Adding New Features

1. **Database Changes**
   - Add new models in `models.py`
   - Create corresponding schemas in `schemas.py`
   - Run database migrations

2. **New Endpoints**
   - Add endpoint in `main.py`
   - Include proper authentication and error handling
   - Add to appropriate tag group

3. **AI Enhancements**
   - Extend `rag_handler.py` with new chains
   - Update prompt templates for better personalization

### Code Style Guidelines

- Use type hints for all function parameters and return values
- Include docstrings for all functions and classes
- Follow FastAPI best practices for endpoint design
- Use proper error handling with HTTP status codes

### Testing

```bash
# Run the application
uvicorn main:app --reload

# Test endpoints using the interactive docs
# Visit: http://localhost:8000/docs
```

## 🧠 AI Features Deep Dive

### Personalized RAG Pipeline

The enhanced RAG system considers:
- **Time of Day**: Morning (high energy) vs Evening (low energy) task suggestions
- **Mood Context**: Adapts task complexity based on user's current mood
- **User Preferences**: Communication style and task breakdown preferences
- **Historical Success**: Learns from past successful task completions

### "Feeling Stuck" Coach

The AI coach provides:
- **Socratic Questioning**: Helps users reflect on their situation
- **Emotional Support**: Acknowledges feelings without judgment
- **Actionable Steps**: Suggests small, achievable next steps
- **Context Awareness**: Considers current goal, mood, and energy level

### Analytics Engine

Tracks and analyzes:
- **Productivity Metrics**: Completion rates, focus time, session duration
- **Pattern Recognition**: Best times of day, mood correlations
- **Progress Tracking**: Trends over time and improvement areas
- **Personalized Insights**: User-specific recommendations

## 🚀 Deployment

### Production Setup

1. **Environment Variables**
   ```env
   GEMINI_API_KEY=your_production_key
   DATABASE_URL=your_production_db_url
   SECRET_KEY=your_production_secret
   ENVIRONMENT=production
   ```

2. **Database Migration**
   ```bash
   alembic upgrade head
   ```

3. **Run with Gunicorn**
   ```bash
   gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
   ```

### Docker Deployment

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 🔮 Future Roadmap

### Phase 1 (Current)
- ✅ Enhanced RAG with personalization
- ✅ Pomodoro timer integration
- ✅ Analytics dashboard
- ✅ "Feeling Stuck" coach

### Phase 2 (Next)
- [ ] Reinforcement Learning integration
- [ ] Advanced pattern recognition
- [ ] Real-time notifications
- [ ] Mobile push notifications

### Phase 3 (Future)
- [ ] Multi-modal AI (voice, image)
- [ ] Social features and accountability
- [ ] Integration with calendar apps
- [ ] Advanced analytics and ML insights

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with proper testing
4. Submit a pull request with detailed description

## 📄 License

This project is part of an MSc dissertation on AI-powered ADHD management tools.

## 🆘 Support

For technical issues or questions:
- Check the API documentation at `/docs`
- Review the code comments and docstrings
- Create an issue with detailed error information

---

**Built with ❤️ for the ADHD community** 