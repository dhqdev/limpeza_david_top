import './CategorySelector.css'

function CategorySelector({ categories, selected, onToggle, disabled }) {
  return (
    <div className="category-grid">
      {Object.entries(categories).map(([catId, catInfo]) => (
        <label 
          key={catId} 
          className={`category-item ${selected.includes(catId) ? 'selected' : ''} ${disabled ? 'disabled' : ''}`}
        >
          <input
            type="checkbox"
            checked={selected.includes(catId)}
            onChange={() => onToggle(catId)}
            disabled={disabled}
          />
          <span className="category-icon">{catInfo.icon}</span>
          <span className="category-name">{catInfo.name}</span>
        </label>
      ))}
    </div>
  )
}

export default CategorySelector
