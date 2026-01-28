import './ProgressBar.css'

function ProgressBar({ progress, isActive, status }) {
  // Estado inicial - sem atividade
  if (!isActive && progress === 0) {
    return (
      <div className="progress-container">
        <div className="idle-state">
          <div className="idle-icon">🧹</div>
          <p className="idle-text">Selecione as categorias e clique em Analisar</p>
        </div>
      </div>
    )
  }

  // Durante a varredura/limpeza
  return (
    <div className="progress-container">
      {/* Status do processo */}
      <div className="progress-status">
        {status === 'scanning' && '🔍 Analisando sistema...'}
        {status === 'cleaning' && '🧹 Limpando arquivos...'}
        {status === 'scan_complete' && '✅ Análise concluída!'}
        {status === 'clean_complete' && '✨ Limpeza concluída!'}
        {typeof status === 'string' && status.includes('Analisando') && status}
        {typeof status === 'string' && status.includes('Limpando') && status}
      </div>

      {/* Área de varrição visual */}
      <div className="sweep-area">
        {/* Fundo sujo */}
        <div className="dirty-floor">
          {/* Sujeira espalhada */}
          {[...Array(20)].map((_, i) => (
            <span 
              key={i} 
              className="dirt-particle"
              style={{
                left: `${5 + (i * 4.5)}%`,
                top: `${20 + Math.sin(i) * 30}%`,
                animationDelay: `${i * 0.1}s`,
                opacity: (i * 5) < progress ? 0 : 0.8
              }}
            />
          ))}
        </div>

        {/* Área limpa (verde) que cresce */}
        <div 
          className="clean-floor"
          style={{ width: `${progress}%` }}
        />

        {/* Vassoura que varre */}
        {isActive && (
          <div 
            className="broom-sweeper"
            style={{ left: `${progress}%` }}
          >
            <div className="broom-handle" />
            <div className="broom-head">
              <span className="bristle" />
              <span className="bristle" />
              <span className="bristle" />
              <span className="bristle" />
              <span className="bristle" />
            </div>
            {/* Partículas de poeira sendo varridas */}
            <div className="sweep-dust">
              <span className="dust-puff" />
              <span className="dust-puff" />
              <span className="dust-puff" />
            </div>
          </div>
        )}

        {/* Conclusão - marca de verificação */}
        {!isActive && progress === 100 && (
          <div className="complete-check">✨</div>
        )}
      </div>

      {/* Barra de progresso numérica */}
      <div className="progress-bar-wrapper">
        <div className="progress-bar">
          <div 
            className={`progress-fill ${status === 'cleaning' ? 'cleaning' : ''}`}
            style={{ width: `${progress}%` }}
          />
        </div>
        <div className="progress-percentage">{Math.round(progress)}%</div>
      </div>
    </div>
  )
}

export default ProgressBar
