import time
from decouple import config
from main import Product, redis_inventory
from redis.cluster import RedisCluster as Redis

stream_orders = f"events:orders"
stream_refunds = f"events:refunds"
consumer_group = f"inventory:group"
consumer_name = f"{consumer_group}:1"

try:
    redis_inventory.xgroup_create(
        name=stream_orders, 
        groupname=consumer_group, 
        mkstream=True
    )
    print(f"Consumer Group {consumer_group} created!")
except:
    print(f"Consumer Group {consumer_group} already exists!")

while True:
    try:
        results = redis_inventory.xreadgroup(
            groupname=consumer_group, 
            consumername=consumer_name, 
            streams={stream_orders: '>'}, 
            count=1,
            block=1000,
            noack=False
        )
        if results != []:
            for result in results:
                order = result[1][0][1]
                try:
                    product = Product.get(order['product_id'])
                    product_quantity = product.quantity - int(order['quantity'])
                    if product_quantity < 0:
                        raise Exception('Not enough items in the inventory')
                    product.quantity = product_quantity
                    product.save()
                except Exception as e:
                    print(str(e))
                    redis_inventory.xadd(stream_refunds, order, '*')
    except Exception as e:
        print(str(e))
    time.sleep(10)

'''
['events:orders', [('1652884648277-0', {'pk': '01G3BSMAAVSS7M9AMZ46TT4MYK', 'product_id': '01G381YY6RMR3T50HBXAXJ3YA7', 'price': '1.09', 'fee': '0.21800000000000003', 'total': '1.308', 'quantity': '1', 'status': 'completed'})]]
'''
