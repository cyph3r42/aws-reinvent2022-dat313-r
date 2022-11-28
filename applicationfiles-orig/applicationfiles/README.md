# DAT202 Building microservices applications with Amazon MemoryDB

- [FastAPI](https://github.com/tiangolo/fastapi)
- [redis oM](https://github.com/redis/redis-om-python)

## Demo

```bash
export REDIS_HOST=toronto22-dat202.0iymrw.clustercfg.memorydb.us-east-1.amazonaws.com
export REDIS_PORT=6379
export API_URL=http://$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo ${API_URL}
export INVENTORY_API=${API_URL}:8000
export ORDER_API=${API_URL}:8001

redis-cli -h ${REDIS_HOST} -c -3 PING
redis-benchmark -h ${REDIS_HOST} -c 50 -n 100000 -d 250 -P 1 --cluster -q -t get,set --csv

cd summits/amer-toronto/dat202/inventory/
source venv/bin/activate
python -V
http --version
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
python inventory_worker.py

cd summits/amer-toronto/dat202/order/
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
python order_worker.py
```

Testing APIs
```bash
cd summits/amer-toronto/dat202/inventory/
source venv/bin/activate
http --version

export API_URL=http://$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo ${API_URL}
export INVENTORY_API=${API_URL}:8000
echo ${INVENTORY_API}
export ORDER_API=${API_URL}:8001
echo ${ORDER_API}

# list products
http GET ${INVENTORY_API}/products

# add items to the catalog
http POST ${INVENTORY_API}/products name="Pizza" price=28.99 quantity=10
http POST ${INVENTORY_API}/products name="Donut" price=19.99 quantity=10
http POST ${INVENTORY_API}/products name="Soda" price=1.99 quantity=100

http GET ${INVENTORY_API}/products/01G68ND7B90Y57QR3YWYT9C1WZ

http GET ${INVENTORY_API}/products

# Order a Pizza
http POST ${ORDER_API}/orders id=01G68P0BG0NFPQNQYA87YVER92 quantity=1

http GET ${ORDER_API}/orders/01G68P1SMKTQYWTSXGKVK60M63

# Remove Pizza from the menu, ran out of dough
http DELETE ${INVENTORY_API}/products/01G3BXJZ1YHECATCRV3JHT2MGX 
```

# Load Test
```bash

redis-benchmark -h ${MEMORYDB_REDIS} -c 100 -n 1000000 -d 100 -P 4 --cluster --threads 1 -q -t get,set --csv


redis-benchmark -h ${REDIS_HOST} -c 100 -n 1000000 -d 100 -P 4 --cluster --threads 1 -q -t get,set --csv
redis-benchmark -h ${REDIS_HOST} -c 50 -n 100000 -d 250 -P 1 --cluster -q -t get,set --csv
```

----

## Developer Notes

Install Python dependencies
```bash
conda deactivate
python3 -m venv venv
python3.8 -m venv venv
source venv/bin/activate
pip list
python -m pip install --upgrade pip
pip install fastapi
pip install "pydantic[email]"
pip install "uvicorn[standard]"
pip install redis-om
pip install requests

pip freeze > requirements.txt
pip install -r requirements.txt
```

Redis Modules
```bash
docker pull redislabs/redismod
docker volume create redismod_data
docker run \
  -p 16379:6379 \
  -v redismod_data:/data \
  redislabs/redismod \
  --loadmodule /usr/lib/redis/modules/rejson.so \
  --dir /data
```

Run backend services
```bash
uvicorn inventory.main:app --host 0.0.0.0 --port 8000 --reload
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

uvicorn main:app --reload --port 8000
uvicorn main:app --reload --port 8001
python inventory_worker.py
python order_worker.py
```



Create frontend
```bash
npx create-react-app@5.0.1 frontend
npm i react-router-dom
npm audit fix --force
npm start
```