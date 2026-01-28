import { useState, useEffect } from 'react'
import { RefreshCw, Trash2, Search, CheckSquare, XSquare } from 'lucide-react'
import ProgressBar from './components/ProgressBar'
import CategorySelector from './components/CategorySelector'
import './App.css'

function App() {
  const [categories, setCategories] = useState({})
  const [selectedCategories, setSelectedCategories] = useState([])
  const [systemInfo, setSystemInfo] = useState({})
  const [state, setState] = useState({
    is_scanning: false,
    is_cleaning: false,
    is_updating: false,
    progress: 0,
    status: 'idle',
    current_task: '',
    logs: []
  })
  const [scanResults, setScanResults] = useState(null)

  useEffect(() => {
    fetchSystemInfo()
    fetchCategories()
  }, [])

  useEffect(() => {
    const interval = setInterval(() => {
      if (state.is_scanning || state.is_cleaning || state.is_updating) {
        fetchState()
      }
    }, 500)
    return () => clearInterval(interval)
  }, [state.is_scanning, state.is_cleaning, state.is_updating])

  const fetchSystemInfo = async () => {
    try {
      const res = await fetch('/api/system-info')
      const data = await res.json()
      setSystemInfo(data)
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const fetchCategories = async () => {
    try {
      const res = await fetch('/api/categories')
      const data = await res.json()
      setCategories(data)
      setSelectedCategories(Object.keys(data))
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const fetchState = async () => {
    try {
      const res = await fetch('/api/state')
      const data = await res.json()
      setState(data)
      if (data.status === 'scan_complete') fetchScanResults()
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const fetchScanResults = async () => {
    try {
      const res = await fetch('/api/scan-results')
      const data = await res.json()
      setScanResults(data)
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const handleScan = async () => {
    if (selectedCategories.length === 0) {
      alert('Selecione pelo menos uma categoria!')
      return
    }
    try {
      setScanResults(null)
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ categories: selectedCategories })
      })
      if (res.ok) setState(prev => ({ ...prev, is_scanning: true, status: 'scanning' }))
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const handleClean = async () => {
    if (!scanResults || scanResults.total_files === 0) return
    if (!window.confirm(`Remover ${scanResults.total_files} arquivos?\nLiberar: ${scanResults.total_size_formatted}`)) return
    try {
      const res = await fetch('/api/clean', { method: 'POST' })
      if (res.ok) {
        setState(prev => ({ ...prev, is_cleaning: true, status: 'cleaning' }))
        setScanResults(null)
      }
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const handleUpdate = async () => {
    if (!window.confirm('Verificar atualizações?')) return
    try {
      const res = await fetch('/api/update', { method: 'POST' })
      if (res.ok) setState(prev => ({ ...prev, is_updating: true, status: 'updating' }))
    } catch (error) {
      console.error('Erro:', error)
    }
  }

  const selectAll = () => setSelectedCategories(Object.keys(categories))
  const deselectAll = () => setSelectedCategories([])
  const toggleCategory = (catId) => {
    setSelectedCategories(prev => 
      prev.includes(catId) ? prev.filter(id => id !== catId) : [...prev, catId]
    )
  }

  const isWorking = state.is_scanning || state.is_cleaning || state.is_updating

  return (
    <div className="app">
      {/* Header compacto */}
      <header className="header">
        <div className="header-left">
          <img src="/img/icon.png" alt="Logo" className="logo" />
          <div>
            <h1>Limpeza David</h1>
            <span className="subtitle">{systemInfo.system} {systemInfo.release}</span>
          </div>
        </div>
        <button onClick={handleUpdate} className="btn-update" disabled={isWorking}>
          <RefreshCw size={18} className={state.is_updating ? 'spin' : ''} />
        </button>
      </header>

      {/* Conteúdo principal - Layout em grid */}
      <main className="main-content">
        {/* Lado esquerdo - Categorias */}
        <section className="panel categories-panel">
          <div className="panel-header">
            <h2>Categorias</h2>
            <div className="quick-actions">
              <button onClick={selectAll} disabled={isWorking} title="Selecionar todos">
                <CheckSquare size={16} />
              </button>
              <button onClick={deselectAll} disabled={isWorking} title="Desmarcar todos">
                <XSquare size={16} />
              </button>
            </div>
          </div>
          <CategorySelector 
            categories={categories}
            selected={selectedCategories}
            onToggle={toggleCategory}
            disabled={isWorking}
          />
        </section>

        {/* Lado direito - Ações e Progresso */}
        <section className="panel action-panel">
          {/* Barra de progresso com animação */}
          <div className="progress-area">
            <ProgressBar 
              progress={state.progress} 
              isActive={state.is_scanning || state.is_cleaning}
              status={state.current_task || state.status}
            />
          </div>

          {/* Resultado */}
          {scanResults && scanResults.total_files > 0 && (
            <div className="results-box">
              <div className="result-stat">
                <span className="stat-number">{scanResults.total_files}</span>
                <span className="stat-label">arquivos</span>
              </div>
              <div className="result-stat highlight">
                <span className="stat-number">{scanResults.total_size_formatted}</span>
                <span className="stat-label">a liberar</span>
              </div>
            </div>
          )}

          {/* Status */}
          {state.status !== 'idle' && (
            <div className="status-text">
              {state.status === 'scan_complete' && '✅ Análise concluída!'}
              {state.status === 'clean_complete' && '✅ Limpeza concluída!'}
              {state.status === 'scanning' && '🔍 Analisando...'}
              {state.status === 'cleaning' && '🧹 Limpando...'}
              {state.status === 'updating' && '🔄 Atualizando...'}
            </div>
          )}

          {/* Botões de ação */}
          <div className="action-buttons">
            <button 
              onClick={handleScan} 
              className="btn btn-primary"
              disabled={isWorking || selectedCategories.length === 0}
            >
              <Search size={20} />
              Analisar
            </button>

            <button 
              onClick={handleClean} 
              className="btn btn-danger"
              disabled={isWorking || !scanResults || scanResults.total_files === 0}
            >
              <Trash2 size={20} />
              Limpar
            </button>
          </div>
        </section>
      </main>
    </div>
  )
}

export default App
