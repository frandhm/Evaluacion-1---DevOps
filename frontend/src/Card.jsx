import React from 'react';

function Card({ producto }) {
    return (
        <div className="card">
            <img
                src={producto.imagen}
                alt={producto.nombre}
                className="card-image"
            />
            <div className="card-body">
                <h2 className="card-title">{producto.nombre}</h2>
                <p className="card-description">{producto.descripcion}</p>
                <div className="card-footer">
                    <span className="card-price">{producto.precio}</span>
                    <button className="btn-comprar">Comprar</button>
                </div>
            </div>
        </div>
    );
}

export default Card;