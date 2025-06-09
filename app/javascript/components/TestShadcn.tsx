import React from "react"
import { Button } from "@/components/ui/button"

export default function TestShadcn() {
  return (
    <div className="p-8 space-y-4">
      <h1 className="text-2xl font-bold">Shadcn UI Test</h1>
      <div className="flex gap-4 flex-wrap">
        <Button>Default Button</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="destructive">Destructive</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="link">Link</Button>
        <Button size="sm">Small</Button>
        <Button size="lg">Large</Button>
      </div>
    </div>
  )
}
