import time
import requests
from typing import Union
from decouple import config
from redis.cluster import RedisCluster as Redis
from redis_om import get_redis_connection, HashModel
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.background import BackgroundTasks

BACKEND = config('BACKEND_HOST')
FRONTEND = config('FRONTEND_HOST')
REDIS_HOST = config('REDIS_HOST')
REDIS_PORT = config('REDIS_PORT')
stream_orders = f"events:orders"

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[FRONTEND],
    allow_methods=['*'],
    allow_headers=['*'],
)
redis_order = Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, ssl=True)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    time.process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(time.process_time)
    return response

class Order(HashModel):
    product_id: str
    price: float
    fee: float
    total: float
    quantity: int
    status: str # pending, processing, completed, refunded
    class Meta:
        # database: redis_order
        database = Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, ssl=True)

@app.get('/orders/{pk}')
def get(pk: str):
    return Order.get(pk)

@app.post('/orders')
async def create_order(request: Request, background_tasks: BackgroundTasks): # id, quantity
    body = await request.json()
    req = requests.get(f"{BACKEND}/products/{body['id']}")
    product = req.json()
    order = Order(
        product_id=body['id'],
        price=product['price'],
        fee=0.2 * product['price'],
        total=1.2 * product['price'] * float(body['quantity']),
        quantity=body['quantity'],
        status='pending'
    )
    order.save()
    background_tasks.add_task(order_completed, order)
    return order

def order_completed(order: Order):
    order.status='processing'
    order.save()
    time.sleep(20)
    order.status='completed'
    order.save()
    redis_order.xadd(stream_orders, order.dict(), '*')

@app.get("/")
def read_root():
    return {"Service": "Order"}
