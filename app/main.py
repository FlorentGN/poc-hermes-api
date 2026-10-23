from fastapi import FastAPI, Query
from hermes_math import add, multiply, get_greeting

app = FastAPI(
    title="Hermes API",
    description="API FastAPI consommant la bibliothèque interne hermes-math",
    version="0.1.0",
)

@app.get("/")
def read_root():
    return {
        "service": "hermes-api",
        "message": get_greeting("Dev"),
        "status": "healthy"
    }

@app.get("/add")
def compute_add(a: float = Query(..., description="Premier nombre"), b: float = Query(..., description="Second nombre")):
    return {
        "operation": "add",
        "a": a,
        "b": b,
        "result": add(a, b)
    }

@app.get("/multiply")
def compute_multiply(a: float = Query(..., description="Premier nombre"), b: float = Query(..., description="Second nombre")):
    return {
        "operation": "multiply",
        "a": a,
        "b": b,
        "result": multiply(a, b)
    }

