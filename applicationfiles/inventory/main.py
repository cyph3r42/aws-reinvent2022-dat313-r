import time
from typing import Union
from decouple import config
from redis.cluster import RedisCluster as Redis
from redis_om import get_redis_connection, HashModel
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware

BACKEND = config('BACKEND_HOST')
FRONTEND = config('FRONTEND_HOST')
REDIS_HOST = config('REDIS_HOST')
REDIS_PORT = config('REDIS_PORT')

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[FRONTEND],
    allow_methods=['*'],
    allow_headers=['*'],
)
redis_inventory = Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, ssl=True)

# Process Time Header
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    time.process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(time.process_time)
    return response

class Product(HashModel):
    name: str
    price: float
    quantity: int # quantity available
    class Meta:
        # database = redis_inventory
        database = Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, ssl=True)

@app.post('/products')
def create_product(product: Product):
    return product.save()

@app.get('/products')
def all_products():
    return [
        format_product(pk) for pk in Product.all_pks()
    ]

def format_product(pk: str):
    try:
        product = Product.get(pk)
        return {
            'id': pk,
            'name': product.name,
            'price': product.price,
            'quantity': product.quantity,
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail="Item not found")

@app.get('/products/{pk}')
def get_product(pk: str):
    return Product.get(pk)

@app.delete('/products/{pk}')
def delete_product(pk: str):
    return Product.delete(pk)

@app.get("/")
def read_root():
    return {"Service": "Inventory"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}
