"use client"

import Link from "next/link"
import { User } from "lucide-react"

import { siteConfig } from "@/config/site"
import { buttonVariants } from "@/components/ui/button"
import { Icons } from "@/components/icons"
import { MainNav } from "@/components/main-nav"
import { ThemeToggle } from "@/components/theme-toggle"
import { useAuth } from "@/lib/contexts/auth-context"
import { Button } from "@/components/ui/button"

export function SiteHeader() {
  const { user, isLoading } = useAuth()

  return (
    <header className="sticky top-0 z-40 w-full border-b bg-background">
      <div className="container flex h-16 items-center space-x-4 sm:justify-between sm:space-x-0">
        <MainNav items={siteConfig.mainNav} />
        <div className="flex flex-1 items-center justify-end space-x-4">
          <nav className="flex items-center space-x-1">
            {!isLoading && (
              <>
                {user ? (
                  <Link href="/account">
                    <Button variant="ghost" size="sm">
                      <User className="mr-2 size-4" />
                      {user.email}
                    </Button>
                  </Link>
                ) : (
                  <Link href="/login">
                    <Button variant="ghost" size="icon">
                      <User className="size-6" />
                      <span className="sr-only">Account</span>
                    </Button>
                  </Link>
                )}
              </>
            )}
            {/* External links removed */}
            <ThemeToggle />
          </nav>
        </div>
      </div>
    </header>
  )
}
