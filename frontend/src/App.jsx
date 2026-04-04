import { useEffect, useState } from "react"
import Card from "./Card.jsx";
import "./App.css"
import logo from "./assets/overwatch.png"

function App() {
  const [productos, setProductos] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)


  useEffect(() => {
    fetch("/api/ropas")
      .then(resp => {
        if (!resp.ok) throw new Error("Error al obtener los productos")
        return resp.json()
      }).then(data => {
        setProductos(data)
        setLoading(false)
      }).catch(ex => {
        setError(ex.message)
        setLoading(false)
      })
  }, [])

  return (
    <div className="layout-container">
      <header className="header">
        <div className="header-side left">
          <img className="logo-img" src={logo} alt="logo" />
        </div>
        <h1 className="header-title">Tienda los OverWarriors</h1>
        <div className="header-side right"></div>
      </header>

      <main className="main-content">
        {loading && <p className="mensaje-estado">Cargando productos...</p>}
        {error && <p className="mensaje-estado error">Error: {error}</p>}

        {/* Aquí va el grid de productos */}
        <div className="productos-grid">
          {productos.map(producto => (
            <Card key={producto.id} producto={producto} />
          ))}
        </div>
      </main>
      <footer>
        <p>Derechos reservados &copy; 2026 Ropa los overwarriors</p>
      </footer>
    </div>
  )
}

export default App