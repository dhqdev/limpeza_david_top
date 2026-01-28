import './ProgressBar.css'

function ProgressBar({ progress, isActive, status }) {
  return (
    <div className="progress-container">
      <div className="progress-status">
        {status === 'idle' && 'Pronto para análise'}
        {status === 'scanning' && '🔍 Analisando...'}
        {status === 'cleaning' && '🧹 Limpando...'}
        {status === 'scan_complete' && '✅ Análise concluída!'}
        {status === 'clean_complete' && '✅ Limpeza concluída!'}
        {status === 'updating' && '🔄 Atualizando...'}
        {status === 'error' && '❌ Erro!'}
        {!['idle', 'scanning', 'cleaning', 'scan_complete', 'clean_complete', 'updating', 'error'].includes(status) && status}
      </div>
      
      <div className="progress-bar-wrapper">
        <div className="progress-bar">
          <div 
            className="progress-fill"
            style={{ width: `${progress}%` }}
          />
          
          {/* Efeito de partículas/sujeira sendo varrida */}
          {isActive && (
            <div className="dust-particles">
              {[...Array(8)].map((_, i) => (
                <span key={i} className="dust-particle" style={{ animationDelay: `${i * 0.1}s` }} />
              ))}
            </div>
          )}
          
          {/* Vassourinha animada */}
          {isActive && (
            <div 
              className="sweeper-container"
              style={{ left: `${Math.min(progress, 95)}%` }}
            >
              <div className="sweeper">
                <img 
                  src="/img/icon.png" 
                  alt="David" 
                  className="sweeper-person"
                />
                <div className="broom">
                  <div className="broom-handle"></div>
                  <div className="broom-head">
                    <div className="bristle"></div>
                    <div className="bristle"></div>
                    <div className="bristle"></div>
                    <div className="bristle"></div>
                    <div className="bristle"></div>
                  </div>
                </div>
              </div>
              {/* Rastro de limpeza */}
              <div className="sweep-trail"></div>
            </div>
          )}
        </div>
        
        <span className="progress-percentage">{Math.round(progress)}%</span>
      </div>
    </div>
  )
}

export default ProgressBar
