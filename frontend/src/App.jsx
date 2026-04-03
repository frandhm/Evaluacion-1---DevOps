import { useEffect, useState } from "react"
import "./App.css"

function App() {
  const [productos, setProductos] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch("http://10.0.2.20:8080/api/ropas")
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
          <img className="logo-img" src="./src/assets/overwatch.png" alt="" />
        </div>
        <h1 className="header-title">Tienda los OverWarriors</h1>
        <div className="header-side right"></div>
      </header>

      <main className="main-content">
        <div className="productos">
          {loading && <p>Cargando productos...</p>}
          {error && <p>Error: {error}</p>}
          {productos.map(productos => (
            <div key={productos.id}>
              <h2>{productos.nombre}</h2>
              <p>{productos.descripcion}</p>
              <strong>{productos.precio}</strong>
            </div>
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