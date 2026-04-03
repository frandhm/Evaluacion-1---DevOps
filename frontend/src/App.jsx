import { useEffect, useState } from "react"
import "./App.css"

function App() {
  const [productos, setProductos] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(()=>{
    fetch("http://localhost:8080/api/ropas")
    .then(resp=>{
      if(!resp.ok) throw new Error("Error al obtener los productos")
      return resp.json()
    }).then(data=>{
      setProductos(data)
      setLoading(false)
    }).catch(ex=>{
      setError(ex.message)
      setLoading(false)
    })
  },[])

  return (
    <div>
      <h1>Ropa los overwarriors</h1>
      {loading && <p>Cargando productos...</p>}
      {error && <p>Error: {error}</p>}

      <ul>
        {productos.map(productos=>(
          <li key={productos.id}>
            <h2>{productos.nombre}</h2>
            <p>{productos.descripcion}</p>
            <strong>{productos.precio}</strong>
          </li>
        ))}
      </ul>
    </div>
  )
}

export default App