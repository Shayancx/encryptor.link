"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Trash2, Download, RefreshCw, Bug } from "lucide-react"

export function StreamingDebugDashboard() {
  const [debugEnabled, setDebugEnabled] = useState(false)
  const [logs, setLogs] = useState<any[]>([])
  const [errors, setErrors] = useState<any[]>([])
  
  useEffect(() => {
    const enabled = localStorage.getItem('debug_streaming') === 'true'
    setDebugEnabled(enabled)
    
    if (enabled) {
      refreshLogs()
    }
  }, [])
  
  const refreshLogs = () => {
    const logData = (window as any).streamingDebug?.dump()
    if (logData) {
      setLogs(logData.logs || [])
      setErrors(logData.errors || [])
    }
  }
  
  const toggleDebug = () => {
    if (debugEnabled) {
      (window as any).streamingDebug?.disable()
      setDebugEnabled(false)
      setLogs([])
      setErrors([])
    } else {
      (window as any).streamingDebug?.enable()
      setDebugEnabled(true)
      window.location.reload()
    }
  }
  
  const clearLogs = () => {
    (window as any).streamingDebug?.clear()
    setLogs([])
    setErrors([])
  }
  
  const downloadLogs = () => {
    const data = {
      timestamp: new Date().toISOString(),
      logs,
      errors,
      userAgent: navigator.userAgent,
      url: window.location.href
    }
    
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `streaming-debug-${Date.now()}.json`
    a.click()
    URL.revokeObjectURL(url)
  }
  
  if (!debugEnabled) {
    return (
      <Alert>
        <Bug className="h-4 w-4" />
        <AlertDescription>
          Streaming debug mode is disabled.{' '}
          <Button variant="link" size="sm" onClick={toggleDebug}>
            Enable Debug Mode
          </Button>
        </AlertDescription>
      </Alert>
    )
  }
  
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span className="flex items-center gap-2">
            <Bug className="h-5 w-5" />
            Streaming Debug Dashboard
          </span>
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={refreshLogs}>
              <RefreshCw className="h-4 w-4 mr-1" />
              Refresh
            </Button>
            <Button size="sm" variant="outline" onClick={downloadLogs}>
              <Download className="h-4 w-4 mr-1" />
              Export
            </Button>
            <Button size="sm" variant="outline" onClick={clearLogs}>
              <Trash2 className="h-4 w-4 mr-1" />
              Clear
            </Button>
            <Button size="sm" variant="destructive" onClick={toggleDebug}>
              Disable
            </Button>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Errors */}
          {errors.length > 0 && (
            <div>
              <h3 className="font-semibold mb-2 text-destructive">
                Errors ({errors.length})
              </h3>
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {errors.map((error, i) => (
                  <div key={i} className="text-xs p-2 bg-destructive/10 rounded">
                    <div className="font-mono">
                      [{error.timestamp}] {error.context}: {error.message}
                    </div>
                    {error.error && (
                      <div className="mt-1 text-destructive">{error.error}</div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
          
          {/* Logs */}
          <div>
            <h3 className="font-semibold mb-2">
              Logs ({logs.length})
            </h3>
            <div className="space-y-1 max-h-96 overflow-y-auto">
              {logs.slice(-100).reverse().map((log, i) => (
                <div key={i} className="text-xs font-mono p-1 hover:bg-muted rounded">
                  <span className="text-muted-foreground">[{log.timestamp}]</span>{' '}
                  <Badge variant="outline" className="text-xs py-0">
                    {log.context}
                  </Badge>{' '}
                  {log.message}
                  {log.data && (
                    <pre className="mt-1 text-muted-foreground">
                      {JSON.stringify(log.data, null, 2)}
                    </pre>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
