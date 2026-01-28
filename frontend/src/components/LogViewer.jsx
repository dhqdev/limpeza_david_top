import './LogViewer.css'

function LogViewer({ logs }) {
  const getLogClass = (level) => {
    const classes = {
      info: 'log-info',
      success: 'log-success',
      warning: 'log-warning',
      error: 'log-error',
      header: 'log-header'
    }
    return classes[level] || 'log-info'
  }

  return (
    <div className="log-viewer">
      {logs.length === 0 ? (
        <div className="log-empty">
          <span>📋 Os logs das operações aparecerão aqui...</span>
        </div>
      ) : (
        logs.map((log, index) => (
          <div key={index} className={`log-entry ${getLogClass(log.level)}`}>
            {log.message}
          </div>
        ))
      )}
    </div>
  )
}

export default LogViewer
