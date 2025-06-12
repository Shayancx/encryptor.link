#!/bin/bash

# Kill any existing processes
echo "🔪 Stopping existing processes..."
pkill -f "rails server" || true
pkill -f "vite" || true

# Kill by port
kill_port() {
  local port=$1
  local pid=$(lsof -i :$port -t 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "🔪 Killing process using port $port (PID: $pid)..."
    kill -9 $pid 2>/dev/null || true
    sleep 1
  fi
}

kill_port 3000
kill_port 5173

# Start both servers
echo "🚀 Starting Rails server..."
bundle exec rails server -p 3000 &
RAILS_PID=$!

echo "🚀 Starting Vite dev server..."
npm run dev &
VITE_PID=$!

echo ""
echo "✅ Development servers started!"
echo "📝 Rails API: http://localhost:3000"
echo "📝 Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop both servers..."

# Trap Ctrl+C and kill both processes
trap 'echo "🛑 Stopping servers..."; kill $RAILS_PID $VITE_PID 2>/dev/null; exit' INT

# Wait for both processes
wait
