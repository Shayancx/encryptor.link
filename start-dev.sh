#!/bin/bash

# Kill any existing processes
echo "🔪 Stopping existing processes..."
pkill -f "rails server" || true
pkill -f "puma" || true  
pkill -f "vite" || true
pkill -f "npm run dev" || true

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

# Wait for cleanup
sleep 3

echo "🚀 Starting Rails server on port 3000..."
RAILS_ENV=development bundle exec rails server -p 3000 -b 0.0.0.0 &
RAILS_PID=$!

# Wait for Rails to start
echo "⏳ Waiting for Rails server to start..."
sleep 5

# Test Rails server
if curl -s http://localhost:3000/api/v1/health > /dev/null 2>&1; then
    echo "✅ Rails server is responding"
else
    echo "⚠️ Rails server might not be ready yet"
fi

echo "🚀 Starting Vite dev server on port 5173..."
npm run dev &
VITE_PID=$!

echo ""
echo "✅ Development servers started!"
echo "📝 Rails API: http://localhost:3000"
echo "📝 Frontend: http://localhost:5173"
echo "📝 API Health: http://localhost:3000/api/v1/health"
echo ""
echo "🧪 Test the API with:"
echo "   curl http://localhost:3000/api/v1/health"
echo ""
echo "Press Ctrl+C to stop both servers..."

# Trap Ctrl+C and kill both processes
trap 'echo "🛑 Stopping servers..."; kill $RAILS_PID $VITE_PID 2>/dev/null; pkill -f "rails server" || true; pkill -f "npm run dev" || true; exit' INT

# Wait for both processes
wait
