import requests
import socket
from time import time
from functools import wraps

HUE_TRANSITION_TIME = 0 # default 400


def print_time(f):

    @wraps(f)
    def f_(*args, **kwargs):
        t1 = time()
        res = f(*args, **kwargs)
        t2 = time()
        print(f"{f.__name__} ran in {t2 - t1:.4f}s")
        return res

    return f_


@print_time
def send_to_group(group_id, parsed):
    return requests.put(HUE_BASE_URL + f'groups/{group_id}/action', json=parsed)
# send_to_group = print_time(send_to_group)


@print_time
def send_to_light(id, parsed):
    print(parsed)
    return requests.put(f"{HUE_BASE_URL}lights/{id}/state", json=parsed)


def listen():
    HOST = '127.0.0.1'
    PORT = 8888
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(1)
    conn, addr = s.accept()
    print('Connected by', addr)
    while True:
        data = conn.recv(1024)
        if not data: break
        print(data)
        parsed = parse_data(data)

        if 'group_id' in parsed:
            group_id = parsed.pop('group_id')
            r = send_to_group(group_id, parsed)
        elif 'id' in parsed:
            id = parsed.pop('id')
            r = requests.put(f"{HUE_BASE_URL}lights/{id}/state", json=parsed)
        elif 'sector' in parsed:
            sector_id = parsed.pop('sector')
            if sector_id < 0:
                print('Negative sector!')
            for i in range(len(ALL_LIGHTS)):
                send_to_light(ALL_LIGHTS[i], {"on": i == sector_id,
                                              "transitiontime": 1,
                                              "bri": 150})
        else:
            for id in ALL_LIGHTS:
                r = send_to_light(id, parsed)



        # do whatever you need to do with the data
    conn.close()
    # optionally put a loop here so that you start
    # listening again after the connection closes


HUE_BASE_URL = 'http://10.0.19.215/api/9L8mz8ETRmcIkKznrQrcs9CBNo6LdDq6uXjZ4nn8/'

# ideally we'd use a response from the api to discover fields instead of hardcoding it here
sample_hue_state = {'alert': 'none',
          'bri': 100,
          'colormode': 'ct',
          'ct': 366,
          'effect': 'none',
          'hue': 14956,
          'on': True,
          'reachable': True,
          'sat': 140,
          'xy': [0.4571, 0.4097]}


def get_lights():
    """Return list of ids that are reachable"""
    r = requests.get(HUE_BASE_URL + 'lights')
    return [k for k, v in r.json().items() if v['state']['reachable']]

#ALL_LIGHTS = get_lights()
ALL_LIGHTS = [2, 1, 6, 4, 5]

def set_brightness(id, brightness):
    return requests.put(f"{HUE_BASE_URL}lights/{id}/state", json={'on': True, 'bri': brightness})


# lights/1/state
# res = requests.put(f"{HUE_BASE_URL}lights/1/state", json={'on': False})

# 'state': {'alert': 'none',
#           'bri': 100,
#           'colormode': 'ct',
#           'ct': 366,
#           'effect': 'none',
#           'hue': 14956,
#           'on': True,
#           'reachable': True,
#           'sat': 140,
#           'xy': [0.4571, 0.4097]},


# for id in get_lights():
#     set_brightness(id, 30)

to_parse = b'id=1,bri=100,hue=15342'

END_TOKEN = '\n'

def parse_data(data):
    data = data.decode('utf-8')
    messages = data.split(END_TOKEN)
    if len(messages) > 1 and messages[1]:
        print(f"Discarding {len(messages) -1} messages")
    data = messages[0]
    assignments = data.split(',')
    parsed = dict([a.split('=') for a in assignments])

    for k in [key for key in ['bri', 'hue', 'sector'] if key in parsed]:
        parsed[k] = int(parsed[k])

    k = 'on'
    if k in parsed:
        parsed[k] = bool(int(parsed[k]))

    parsed['transitiontime'] = HUE_TRANSITION_TIME
    return parsed


def test_parse_data():
    assert parse_data(to_parse) == ('1', {
        'bri': '100',
        'hue': '15342'
    })


if __name__ == '__main__':
    # test_parse_data()
    listen()
