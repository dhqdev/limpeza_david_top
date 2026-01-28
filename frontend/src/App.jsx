import { useState, useEffect, useCallback } from 'react'
import { RefreshCw, Trash2, Search, CheckSquare, XSquare, Monitor } from 'lucide-react'
import ProgressBar from './components/ProgressBar'
import LogViewer from './components/LogViewer'
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

  // Carrega informações iniciais
  useEffect(() => {
    fetchSystemInfo()
    fetchCategories()
  }, [])

  // Poll do estado
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
      console.error('Erro ao buscar info do sistema:', error)
    }
  }

  const fetchCategories = async () => {
    try {
      const res = await fetch('/api/categories')
      const data = await res.json()
      setCategories(data)
      setSelectedCategories(Object.keys(data))
    } catch (error) {
      console.error('Erro ao buscar categorias:', error)
    }
  }

  const fetchState = async () => {
    try {
      const res = await fetch('/api/state')
      const data = await res.json()
      setState(data)
      
      // Se terminou o scan, busca resultados
      if (data.status === 'scan_complete') {
        fetchScanResults()
      }
    } catch (error) {
      console.error('Erro ao buscar estado:', error)
    }
  }

  const fetchScanResults = async () => {
    try {
      const res = await fetch('/api/scan-results')
      const data = await res.json()
      setScanResults(data)
    } catch (error) {
      console.error('Erro ao buscar resultados:', error)
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
      
      if (res.ok) {
        setState(prev => ({ ...prev, is_scanning: true, status: 'scanning' }))
      }
    } catch (error) {
      console.error('Erro ao iniciar scan:', error)
    }
  }

  const handleClean = async () => {
    if (!scanResults || scanResults.total_files === 0) return

    const confirm = window.confirm(
      `Deseja remover ${scanResults.total_files} arquivos?\n` +
      `Espaço a ser liberado: ${scanResults.total_size_formatted}\n\n` +
      `⚠️ Esta ação não pode ser desfeita!`
    )

    if (!confirm) return

    try {
      const res = await fetch('/api/clean', { method: 'POST' })
      
      if (res.ok) {
        setState(prev => ({ ...prev, is_cleaning: true, status: 'cleaning' }))
        setScanResults(null)
      }
    } catch (error) {
      console.error('Erro ao iniciar limpeza:', error)
    }
  }

  const handleUpdate = async () => {
    const confirm = window.confirm(
      'Deseja verificar atualizações?\n\n' +
      'Isso irá executar "git pull" para baixar as últimas mudanças.'
    )

    if (!confirm) return

    try {
      const res = await fetch('/api/update', { method: 'POST' })
      
      if (res.ok) {
        setState(prev => ({ ...prev, is_updating: true, status: 'updating' }))
      }
    } catch (error) {
      console.error('Erro ao iniciar atualização:', error)
    }
  }

  const selectAll = () => setSelectedCategories(Object.keys(categories))
  const deselectAll = () => setSelectedCategories([])

  const toggleCategory = (catId) => {
    setSelectedCategories(prev => 
      prev.includes(catId) 
        ? prev.filter(id => id !== catId)
        : [...prev, catId]
    )
  }

  const isWorking = state.is_scanning || state.is_cleaning || state.is_updating

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="header-left">
          <img src="/img/icon.png" alt="Logo" className="logo" />
          <h1>Limpeza David</h1>
        </div>
        <div className="header-right">
          <Monitor size={18} />
          <span>{systemInfo.system} {systemInfo.release}</span>
          <span className="version">v{systemInfo.version}</span>
        </div>
      </header>

      {/* Main Content */}
      <main className="main-content">
        {/* Categories Section */}
        <section className="card categories-section">
          <div className="card-header">
            <h2>📂 Categorias de Limpeza</h2>
            <div className="category-actions">
              <button onClick={selectAll} className="btn-small" disabled={isWorking}>
                <CheckSquare size={16} />
                Selecionar Todos
              </button>
              <button onClick={deselectAll} className="btn-small" disabled={isWorking}>
                <XSquare size={16} />
                Desmarcar Todos
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

        {/* Action Buttons */}
        <section className="actions-section">
          <button 
            onClick={handleScan} 
            className="btn btn-primary"
            disabled={isWorking || selectedCategories.length === 0}
          >
            <Search size={20} />
            Analisar Sistema
          </button>

          <button 
            onClick={handleClean} 
            className="btn btn-danger"
            disabled={isWorking || !scanResults || scanResults.total_files === 0}
          >
            <Trash2 size={20} />
            Limpar Selecionados
          </button>

          <button 
            onClick={handleUpdate} 
            className="btn btn-secondary"
            disabled={isWorking}
          >
            <RefreshCw size={20} className={state.is_updating ? 'spin' : ''} />
            Atualizar App
          </button>
        </section>

        {/* Progress Section */}
        <section className="card progress-section">
          <ProgressBar 
            progress={state.progress} 
            isActive={state.is_scanning || state.is_cleaning}
            status={state.current_task || state.status}
          />
        </section>

        {/* Results Summary */}
        {scanResults && scanResults.total_files > 0 && (
          <section className="card results-section">
            <h3>📊 Resultado da Análise</h3>
            <div className="results-summary">
              <div className="result-item">
                <span className="result-label">Total de Arquivos:</span>
                <span className="result-value">{scanResults.total_files}</span>
              </div>
              <div className="result-item highlight">
                <span className="result-label">Espaço a Liberar:</span>
                <span className="result-value">{scanResults.total_size_formatted}</span>
              </div>
            </div>
            <div className="results-details">
              {Object.entries(scanResults.results).map(([catId, data]) => (
                <div key={catId} className="result-category">
                  <span>{data.name}</span>
                  <span>{data.file_count} arquivos ({data.size_formatted})</span>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Log Section */}
        <section className="card log-section">
          <h3>📋 Log de Operações</h3>
          <LogViewer logs={state.logs} />
        </section>
      </main>

      {/* Footer */}
      <footer className="footer">
        <span>© 2024 David Fernandes - Limpeza David</span>
      </footer>
    </div>
  )
}

export default App
