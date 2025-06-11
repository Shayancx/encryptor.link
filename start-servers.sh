#!/bin/bash

# Kill any existing processes on our ports
kill_port() {
  local port=$1
  local pid=$(lsof -i :$port -t 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "Killing process using port $port (PID: $pid)..."
    kill -9 $pid 2>/dev/null || true
  fi
}

echo "🔄 Stopping any existing processes..."
kill_port 3000
kill_port 5173

echo "✨ Starting servers in development mode..."

# First terminal - Rails server
echo "🔄 Starting Rails server on port 3000..."
gnome-terminal --tab -- bash -c "cd $(pwd) && bin/rails server -p 3000; exec bash" || \
xterm -e "cd $(pwd) && bin/rails server -p 3000" || \
konsole --new-tab -e "cd $(pwd) && bin/rails server -p 3000" || \
echo "Failed to open new terminal for Rails server. Please run 'bin/rails server -p 3000' in a separate terminal."

# Wait a moment to ensure Rails starts first
sleep 2

# Second terminal - Vite dev server
echo "🔄 Starting Vite dev server on port 5173..."
gnome-terminal --tab -- bash -c "cd $(pwd) && npm run dev; exec bash" || \
xterm -e "cd $(pwd) && npm run dev" || \
konsole --new-tab -e "cd $(pwd) && npm run dev" || \
echo "Failed to open new terminal for Vite server. Please run 'npm run dev' in a separate terminal."

echo "✅ Development environment started!"
echo "📝 Rails server: http://localhost:3000"
echo "📝 Vite dev server: http://localhost:5173"
echo ""
echo "💡 Press Ctrl+C to stop this script (but servers will continue running in their terminals)."

# Keep script running to allow easy termination of all processes
read -p "Press Enter to stop all servers..."

# Stop servers when user presses Enter
echo "🛑 Stopping all servers..."
kill_port 3000
kill_port 5173
echo "✅ Done!"
