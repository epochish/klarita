#!/bin/bash

# Klarita Startup Script
# This script starts both the backend and frontend of the Klarita app

echo "🚀 Starting Klarita - AI-Powered ADHD Task Management App"
echo "=================================================="

# Check if .env file exists and has GEMINI_API_KEY
if [ ! -f "klarita_backend/.env" ]; then
    echo "❌ .env file not found in klarita_backend/"
    echo "Please run: cd klarita_backend && python3 setup.py"
    exit 1
fi

if ! grep -q "GEMINI_API_KEY=" klarita_backend/.env || grep -q "GEMINI_API_KEY=your_gemini_api_key_here" klarita_backend/.env; then
    echo "⚠️  Please add your GEMINI_API_KEY to klarita_backend/.env"
    echo "Get your API key from: https://makersuite.google.com/app/apikey"
    exit 1
fi

# Function to cleanup background processes
cleanup() {
    echo "🛑 Stopping Klarita..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start backend
echo "🔧 Starting backend server..."
cd klarita_backend
python3 main.py &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 3

# Check if backend is running
if ! curl -s http://127.0.0.1:8000/ > /dev/null; then
    echo "❌ Backend failed to start"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Backend running at http://127.0.0.1:8000"
echo "📚 API docs at http://127.0.0.1:8000/docs"

# Start frontend
echo "📱 Starting Flutter app..."
cd klarita
flutter run &
FRONTEND_PID=$!
cd ..

echo "✅ Klarita is starting up!"
echo "📱 Flutter app will open in a new window"
echo "🌐 Backend API: http://127.0.0.1:8000"
echo ""
echo "Press Ctrl+C to stop both services"

# Wait for processes
wait 