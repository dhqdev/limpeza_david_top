import './ProgressBar.css'

function ProgressBar({ progress, isActive, status }) {
  if (!isActive && progress === 0) {
    return (
      <div className="progress-container">
        <div className="idle-state">
          <div className="avatar-container">
            <img src="/img/icon.png" alt="David" className="avatar" />
          </div>
          <p className="idle-text">Selecione as categorias e clique em Analisar</p>
        </div>
      </div>
    )
  }

  return (
    <div className="progress-container">
      <div className={`avatar-container ${isActive ? 'active' : ''}`}>
        <img src="/img/icon.png" alt="David" className="avatar" />
        
        {isActive && (
          <>
            {/* Anel de brilho girando */}
            <div className="glow-ring" />
            
            {/* Vassoura orbitando */}
            <div className="broom-orbit">
              <div className="broom-wrapper">
                <span className="broom-icon">🧹</span>
              </div>
            </div>
            
            {/* Partículas de sujeira */}
            <div className="dust-ring">
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
              <span className="dust" />
            </div>
          </>
        )}
      </div>

      <div className="progress-bar-container">
        <div className="progress-status">
          {status === 'scanning' && '🔍 Analisando sistema...'}
          {status === 'cleaning' && '🧹 Limpando arquivos...'}
          {status === 'scan_complete' && '✅ Análise concluída!'}
          {status === 'clean_complete' && '✅ Limpeza concluída!'}
          {typeof status === 'string' && status.includes('Analisando') && status}
          {typeof status === 'string' && status.includes('Limpando') && status}
        </div>
        
        <div className="progress-bar">
          <div 
            className="progress-fill" 
            style={{ width: `${progress}%` }}
          />
        </div>
        
        <div className="progress-percentage">{Math.round(progress)}%</div>
      </div>
    </div>
  )
}

export default ProgressBar
