import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import Placeholder from '@tiptap/extension-placeholder'
import { Toggle } from '@/components/ui/toggle'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { 
  Bold, Italic, Underline, Strikethrough, 
  Code, List, ListOrdered, Link as LinkIcon, Maximize2
} from 'lucide-react'
import { cn } from '@/lib/utils'

interface TiptapEditorProps {
  content: string
  onChange: (content: string) => void
  placeholder?: string
  editable?: boolean
}

export function TiptapEditor({
  content,
  onChange,
  placeholder = 'Enter your message here...',
  editable = true,
}: TiptapEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({
        openOnClick: false,
      }),
      Image,
      Placeholder.configure({
        placeholder,
      }),
    ],
    content,
    editable,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML())
    },
  })

  if (!editor) {
    return null
  }

  return (
    <div className="border border-input rounded-md bg-background">
      <div className="border-b p-2 flex flex-wrap gap-1">
        <ToggleGroup type="multiple">
          <ToggleGroupItem 
            value="bold" 
            aria-label="Toggle bold"
            onClick={() => editor.chain().focus().toggleBold().run()}
            data-active={editor.isActive('bold')}
            className={cn(editor.isActive('bold') && 'bg-accent text-accent-foreground')}
          >
            <Bold className="h-4 w-4" />
          </ToggleGroupItem>
          <ToggleGroupItem 
            value="italic" 
            aria-label="Toggle italic"
            onClick={() => editor.chain().focus().toggleItalic().run()}
            data-active={editor.isActive('italic')}
            className={cn(editor.isActive('italic') && 'bg-accent text-accent-foreground')}
          >
            <Italic className="h-4 w-4" />
          </ToggleGroupItem>
          <ToggleGroupItem 
            value="strike" 
            aria-label="Toggle strikethrough"
            onClick={() => editor.chain().focus().toggleStrike().run()}
            data-active={editor.isActive('strike')}
            className={cn(editor.isActive('strike') && 'bg-accent text-accent-foreground')}
          >
            <Strikethrough className="h-4 w-4" />
          </ToggleGroupItem>
          <ToggleGroupItem 
            value="code" 
            aria-label="Toggle code"
            onClick={() => editor.chain().focus().toggleCode().run()}
            data-active={editor.isActive('code')}
            className={cn(editor.isActive('code') && 'bg-accent text-accent-foreground')}
          >
            <Code className="h-4 w-4" />
          </ToggleGroupItem>
        </ToggleGroup>
        
        <div className="mx-2 border-r border-input h-full" />
        
        <ToggleGroup type="multiple">
          <ToggleGroupItem 
            value="bulletList" 
            aria-label="Toggle bullet list"
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            data-active={editor.isActive('bulletList')}
            className={cn(editor.isActive('bulletList') && 'bg-accent text-accent-foreground')}
          >
            <List className="h-4 w-4" />
          </ToggleGroupItem>
          <ToggleGroupItem 
            value="orderedList" 
            aria-label="Toggle ordered list"
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            data-active={editor.isActive('orderedList')}
            className={cn(editor.isActive('orderedList') && 'bg-accent text-accent-foreground')}
          >
            <ListOrdered className="h-4 w-4" />
          </ToggleGroupItem>
          <ToggleGroupItem 
            value="link" 
            aria-label="Add link"
            onClick={() => {
              const url = window.prompt('URL')
              if (url) {
                editor.chain().focus().setLink({ href: url }).run()
              } else {
                editor.chain().focus().unsetLink().run()
              }
            }}
            data-active={editor.isActive('link')}
            className={cn(editor.isActive('link') && 'bg-accent text-accent-foreground')}
          >
            <LinkIcon className="h-4 w-4" />
          </ToggleGroupItem>
        </ToggleGroup>
        
        <div className="flex-1"></div>
        
        <Toggle 
          aria-label="Toggle fullscreen"
          onClick={() => {
            // Fullscreen functionality would go here
          }}
        >
          <Maximize2 className="h-4 w-4" />
        </Toggle>
      </div>
      
      <EditorContent 
        editor={editor} 
        className="prose prose-sm dark:prose-invert max-w-none p-4 min-h-[200px] focus:outline-none"
      />
    </div>
  )
}
