import time
from decouple import config
from main import Order, redis_order
from redis.cluster import RedisCluster as Redis

stream_refunds = f"events:refunds"
consumer_group = f"order:group"
consumer_name = f"{consumer_group}:1"

try:
    redis_order.xgroup_create(
        name=stream_refunds, 
        groupname=consumer_group, 
        mkstream=True
    )
    print(f"Consumer Group {consumer_group} created!")
except:
    print(f"Consumer Group {consumer_group} already exists!")

while True:
    try:
        results = redis_order.xreadgroup(
            groupname=consumer_group, 
            consumername=consumer_name, 
            streams={stream_refunds: '>'}, 
            count=1,
            block=1000,
            noack=False
        )
        if results != []:
            for result in results:
                obj = result[1][0][1]
                try:
                    order = Order.get(obj['pk'])
                    order.status = 'refunded'
                    order.save()
                    # Send an email that the order is refunded
                except Exception as e:
                    print(str(e))            
    except Exception as e:
        print(str(e))
    time.sleep(10)


'''
Sample payload

['refund_order', [('1652889846896-0', {'pk': '01G3BYJVVHJFVJ0EEX7YRR53S1', 'product_id': '01G3BYDWW5HXK8GHCZ9NPKDZAC', 'price': '28.99', 'fee': '5.798', 'total': '69.576', 'quantity': '2', 'status': 'completed'})]]
'''
