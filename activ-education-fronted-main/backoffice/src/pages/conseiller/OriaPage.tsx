import { useState, useRef, useEffect } from 'react'
import { Send, Trash2, Sparkles, Bot, User, Loader2 } from 'lucide-react'
import api from '@/api/client'

interface OriaMessage {
  role: 'user' | 'assistant'
  contenu: string
}

export default function OriaPage() {
  const [messages, setMessages] = useState<OriaMessage[]>([
    {
      role: 'assistant',
      contenu:
        "Bonjour ! Je suis ORIA, ton assistant d'orientation scolaire. Pose-moi des questions sur les métiers, les études, les filières, les établissements, ou tout sujet lié à ton parcours éducatif ! 🎓",
    },
  ])
  const [input, setInput] = useState('')
  const [sessionId, setSessionId] = useState<string | null>(null)
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const sendMessage = async () => {
    const text = input.trim()
    if (!text || sending) return
    setInput('')
    setMessages((prev) => [...prev, { role: 'user', contenu: text }])
    setSending(true)

    try {
      const res = await api.post('/oria/message', {
        message: text,
        sessionId,
      })
      const data = res.data as {
        message: string
        sessionId: string
        historique: OriaMessage[]
      }
      setSessionId(data.sessionId)
      setMessages(data.historique)
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          role: 'assistant',
          contenu: "Désolé, je n'ai pas pu répondre. Vérifie ta connexion et réessaie.",
        },
      ])
    } finally {
      setSending(false)
    }
  }

  const clearSession = async () => {
    if (sessionId) {
      try {
        await api.delete(`/oria/session/${sessionId}`)
      } catch {
        // Session déjà expirée
      }
    }
    setSessionId(null)
    setMessages([
      {
        role: 'assistant',
        contenu: 'Conversation effacée. Pose-moi une nouvelle question ! 🎯',
      },
    ])
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-white">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center">
            <Bot className="w-5 h-5 text-white" />
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">ORIA</h2>
            <p className="text-sm text-gray-500">Assistant IA d'orientation</p>
          </div>
        </div>
        {sessionId && (
          <button
            onClick={clearSession}
            className="flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <Trash2 className="w-4 h-4" />
            Nouvelle conversation
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4 bg-gray-50">
        {messages.map((msg, i) => (
          <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div
              className={`flex gap-3 max-w-[80%] ${
                msg.role === 'user' ? 'flex-row-reverse' : 'flex-row'
              }`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                  msg.role === 'user' ? 'bg-blue-600' : 'bg-gray-300'
                }`}
              >
                {msg.role === 'user' ? (
                  <User className="w-4 h-4 text-white" />
                ) : (
                  <Sparkles className="w-4 h-4 text-gray-700" />
                )}
              </div>
              <div
                className={`px-4 py-3 rounded-2xl text-sm leading-relaxed ${
                  msg.role === 'user'
                    ? 'bg-blue-600 text-white rounded-tr-none'
                    : 'bg-white text-gray-800 rounded-tl-none shadow-sm border border-gray-100'
                }`}
              >
                {msg.contenu}
              </div>
            </div>
          </div>
        ))}
        {sending && (
          <div className="flex justify-start">
            <div className="flex gap-3">
              <div className="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center">
                <Sparkles className="w-4 h-4 text-gray-700" />
              </div>
              <div className="px-4 py-3 rounded-2xl bg-white shadow-sm border border-gray-100">
                <Loader2 className="w-5 h-5 animate-spin text-blue-600" />
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="px-6 py-4 border-t border-gray-200 bg-white">
        <div className="flex items-center gap-3">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Pose ta question à ORIA..."
            disabled={sending}
            className="flex-1 px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm disabled:opacity-50"
          />
          <button
            onClick={sendMessage}
            disabled={sending || !input.trim()}
            className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center disabled:opacity-50 hover:bg-blue-700 transition-colors"
          >
            {sending ? (
              <Loader2 className="w-4 h-4 text-white animate-spin" />
            ) : (
              <Send className="w-4 h-4 text-white" />
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
