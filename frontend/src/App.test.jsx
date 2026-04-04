import { render, screen } from "@testing-library/react"
import "@testing-library/jest-dom"
import App from "./App"

global.fetch = () =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([]),
  })

test("muestra el título Tienda los OverWarriors", async () => {
  render(<App />)

  const titulo = await screen.findByText("Tienda los OverWarriors")

  expect(titulo).toBeInTheDocument()
})