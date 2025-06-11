#!/bin/bash

set -e
echo "🔧 Starting encryptor.link module compatibility fix..."

# Fix the PostCSS config file - convert to .cjs extension
echo "📝 Converting PostCSS config to CommonJS format..."
mv postcss.config.js postcss.config.cjs

# Fix the Tailwind config file - convert to .cjs extension
echo "📝 Converting Tailwind config to CommonJS format..."
mv tailwind.config.js tailwind.config.cjs

# Update Vite config to use ES modules syntax
echo "📝 Updating Vite config to use ES modules..."
cat > vite.config.ts << 'EOF'
import path from "path"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    }
  },
})
EOF

# Update package.json to correctly reference the CSS files
echo "📝 Updating package.json to fix module references..."
tmp=$(mktemp)
if grep -q '"type": "module"' package.json; then
  jq '.scripts.build = "tsc && vite build"' package.json > "$tmp" && mv "$tmp" package.json
else
  jq '. + {"type": "module"} | .scripts.build = "tsc && vite build"' package.json > "$tmp" && mv "$tmp" package.json
fi

# Update the imports in utils.ts
echo "📝 Fixing utility imports..."
cat > src/lib/utils.ts << 'EOF'
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import type { ClassValue } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# Create a components.json for shadcn/ui config
echo "📝 Creating components.json for Shadcn UI..."
cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.cjs",
    "css": "src/styles/globals.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOF

# Fix import paths in button.tsx
cat > src/components/ui/button.tsx << 'EOF'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        outline:
          "border border-input bg-transparent shadow-sm hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
EOF

# Update App.tsx to fix import path
cat > src/App.tsx << 'EOF'
import { Button } from "./components/ui/button";

function App() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background">
      <div className="container max-w-md p-6 bg-card rounded-lg shadow-lg text-card-foreground">
        <h1 className="text-2xl font-bold mb-4 text-center">Encryptor.link</h1>
        <p className="text-muted-foreground mb-6 text-center">
          Zero-knowledge, end-to-end encrypted messaging service
        </p>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Button variant="default">New Message</Button>
            <Button variant="outline">Open Message</Button>
          </div>
        </div>
        <p className="text-xs mt-6 text-center text-muted-foreground">
          Your data never leaves your browser unencrypted
        </p>
      </div>
    </div>
  );
}

export default App;
EOF

# Rebuild the frontend
echo "🏗️ Rebuilding the frontend..."
npm run build

echo "✅ Module compatibility fix completed successfully!"
echo "🚀 To start the development server, run: npm run dev"