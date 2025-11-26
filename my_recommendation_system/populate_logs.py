import datetime
import random
import sqlite3

# connect sqlite
conn = sqlite3.connect("recommendation1.sqlite3")
cursor = conn.cursor()

SEED = 0

cursor.execute("""
CREATE TABLE IF NOT EXISTS collector_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    product_id TEXT,
    event TEXT,
    session_id TEXT,
    created TEXT
)
""")
conn.commit()

prods = {
    'donglanh': [
        '02fe5545-2dcf-41c7-a048-2fbf6fba6ac5',
        '076be717-e821-42b6-bf27-b6f9e55d622e',
        '12d93c76-8d76-4ae0-81cc-81180fb0c730',
        '2ece797a-7067-4842-b9df-b5f24a4c6cb1',
        '333fad89-3988-445c-9c07-4e34210bd59c',
        '37f3792e-d4c5-4b26-8283-60ec9aa815fc',
        '3ab745e6-4cf1-48af-8a85-1462d742f7bb',
        '5a939602-a382-45a1-b259-50f70f3de465',
        '6041e5ec-f98e-407c-8472-9e9cbeb776a0',
        '6195a9c1-b998-4457-bd68-b8bb37c3cca1',
        '6d36f5ad-5708-4f3f-8c7b-52c19a9bdcd6',
        '9619979c-8efd-4fd3-9621-4602112e6e73',
        'aacc4f2f-36d8-4248-8753-8b0680f60ea3',
        'ad280815-b402-41cb-9755-06cefe82f6c0',
        'b0827e03-f261-47ac-ba0e-c60eec2b94e9',
        'bc8af952-910f-4976-bbac-36e1af50b93a',
        'd31a953d-2f7e-45cb-805a-d98954a8b15b',
        'e534f2db-0637-4526-bee8-20588298498b',
    ],
    'giavi': [
        '01cd48ac-a5d2-4c00-a532-ea9148e6d46b',
        '0711a244-83a8-4d6a-9e05-8d723e0add09',
        '33c10450-3b2b-46d6-995a-d6eda2992cdb',
        '506f43e4-f0e4-4ebd-b68f-4717f97e426d',
        '583a568d-19f3-410a-91f8-4499f4add13c',
        '5c365dbb-bc0e-4703-8c23-a6fba385eb5c',
        '66f61816-65fc-4b03-a62b-694bc66e949c',
        '97b78010-a622-46d2-b8db-b51bf12c81fd',
        'a873693c-bf1f-490c-9b92-b9d3a70b2299',
        'a8ea4305-c12f-4747-a152-331ad8dfdcda',
        'b3070840-4d8b-417c-ab31-e82fefd81359',
        'b3100293-5cd3-4db8-9630-9c04f81370d7',
        'dd983fbc-3c5c-4aa7-a4da-1f3179f069a8',
        'ef9df21c-dd10-4d1a-b17c-d0289b17b621',
        'f8dbbacc-8e91-407b-8a82-cf92cb75920d',
    ],
    'anlien': [
        '064e2089-2901-4011-a3fc-60b627ccbed7',
        '135c95fc-7e56-4058-b909-2cfcb5a57ef1',
        '2cf10434-55ad-4db7-91a9-1689115f2806',
        '5110cc91-13c1-408e-aab8-bc15f7187f97',
        '571b98c0-3cb2-4693-8dd7-59a6173eda24',
        '6375ff20-0444-4c10-a30c-b1ee805156b0',
        '6bd7926d-5f63-4068-ab34-31e04af4a63b',
        '7b56d89d-123b-4f9e-93af-4993c598f571',
        '97aae7e3-4983-4fe5-97da-471a0010938d',
        '9e467b7f-b7cf-4f03-8d15-7cd574b69be6',
        '9f616193-6572-4391-b8ad-fb04e8cc7599',
        'aa254f3a-a618-472e-a41d-31d4d911fc7e',
        'ae7a6fda-fd41-426f-ab5e-31b6bd369920',
        'c5a947eb-6d91-4609-ac70-409305653033',
        'ca35988a-66cc-4ac6-9f6b-932aa72256b9',
        'cfa745f4-448a-4d11-b52b-c39c56722be3',
        'db2694e6-ecd6-4b2b-b21b-5e60496adcb6',
        'db407a2b-6274-4ed3-85ca-f78b22efe4b2',
        'ef4cc5d3-4196-4b3a-b4ed-72e504afa545',
        'fa643860-54be-4c58-8e59-58e788029cd9',
    ],'chebien': [
        '070d5f00-5d21-405e-b361-1b4ec8d07572',
        '0f1dd319-9197-48cb-b692-956c9dd032bb',
        '24a3f6f8-1de9-4ec2-aae1-e868d50d00f3',
        '2f90be6f-9603-475e-a091-372576cf1b17',
        '34f2019d-339e-4125-a308-690047b74806',
        '3b11e152-7692-4f67-a78e-a737c356eb23',
        '433529a8-6e55-468f-82f3-ce47a1e7cf30',
        '4b3d0303-af37-444e-81c7-1fb0f3d1944c',
        '4e96a97b-cc31-4944-8dcb-9790fd68f3b7',
        '6b52da02-2234-49d9-a29e-b61437da8c12',
        'ad5003f6-7d21-4a8e-883a-bf6942e3109f',
        'afa0c227-53ae-491e-89ae-5fc562d62701',
        'cae8e817-dcb0-4007-b4be-c236fb688b0b',
        'cb6fed66-64f0-414e-b3e7-0af962f2a21c',
        'cbb597c4-de62-4315-a843-31a424628c66',
        'cdac3603-cc2f-4071-b3e6-aaed3ea9473d',
    ], 'trungdauhu': [
        '03e1b4b5-58a7-4728-b876-7b219b5ff2e6',
        '07f35267-5493-4f4f-a64d-7677493ad38f',
        '172e0187-0b21-4f43-8ab4-2f07ee3ec3d6',
        '17e7b932-8fb8-46a1-8747-b32fbaeb2a70',
        '2e994b1d-8bfb-4d4b-aa25-7c3cfdc4f22e',
        '37836c37-045c-4bc9-8ebe-67cf419a2671',
        '4c31165d-cbf4-4b92-8aff-8ba2a828a230',
        '6970391a-c242-4433-b7f8-58f76bb34a18',
        '841c4f9d-366c-4276-9b39-f0f8ed17ce19',
        'b3785754-e9f5-424e-9bf2-f920f946d262',
        'bfecc09a-aa56-463c-8d2b-8a534794fe13',
        'c7f954c4-f2fb-4d43-9331-52c55cbe38a4',
        'd7b81824-19f6-4a63-add5-e86347743c34',
        'f47bb53d-bf32-4ca9-be2b-8091a5c958bd',
    ], 'raucu': [
        '0654c0ec-aa39-4e76-8090-89a0743b51ca',
        '0b2fae82-3642-49af-8547-32dec661b172',
        '25d86462-b61d-4110-8c9f-e024e2d9a305',
        '421c5eb2-c6cf-4075-93c4-898543d7b6e1',
        '42aba54f-49e4-4a7c-81ec-1a985740990c',
        '50f3b778-9121-46de-859c-596068946db2',
        '58a0d441-3f98-4c41-a3c8-a2fc4107a158',
        '59a44283-5a1e-4f11-bf19-83e5bc238e16',
        '5b325771-3ab7-497e-81f1-3dd865e2db03',
        '7039c026-3fb7-4df4-be2c-d3753865d141',
        '7527c027-6701-4dcc-985d-647bdb5ae053',
        '8c2c2523-ff93-486d-a8a8-ea2f7c2b51dd',
        '95e2a7f1-a2ff-4901-9b7b-81c4b879b658',
        '97c25a08-ca83-4103-80c4-1caa3bb2a462',
        '995f4ae0-6e67-4cba-a785-1c79f5190c16',
        'b6c8f51d-4275-4be5-95d0-a3f5ed565603',
        'bc25cc0f-c37e-48eb-b158-a15ee3207c1d',
        'c6be4f7a-4ff8-492d-b621-aa742d74ebba',
        'e540f3bc-3ac0-48b7-807c-e0da588bec2c',
        'f4100bb2-ccc8-41aa-b329-c2a985aadf28',
    ]
}

class User:
    sessionId = 0
    userId = 0
    likes = {}
    events = {}

    def __init__(self, user_id, donglanh, giavi, anlien, chebien, trungdauhu, raucu):
        self.sessionId = random.randint(0, 1000000)
        self.userId = user_id
        self.likes = {'donglanh': donglanh, 'giavi': giavi, 'anlien': anlien, 'chebien': chebien, 'trungdauhu': trungdauhu, 'raucu': raucu}
        self.events = {self.sessionId: []}

    def get_session_id(self):
        if random.randint(0, 100) > 90:
            self.sessionId += 1
            self.events[self.sessionId] = []

        return self.sessionId

    def select_cate(self):
        return sample(self.likes)


def select_prod(user):

    # 20% random ngoài category
    if random.random() < 0.5:
        cate = random.choice(list(prods.keys()))
    else:
        cate = user.select_cate()

    #cate = user.select_cate()
        
    interested_prods = prods[cate]
    product_id = ''
    while product_id == '':
        product_candidate = interested_prods[random.randint(0, len(interested_prods) - 1)]
        if product_candidate not in user.events[user.sessionId]:
            product_id = product_candidate

    return product_id


def select_action(user):
    actions = {
        'categoryView': 15,
        'prod_details': 50,
        'add_to_cart': 24,
        'wishlist_add': 10,
        'purchase': 1
    }

    return sample(actions)


def sample(dictionary):
    random_number = random.randint(0, 100)
    index = 0

    for key, value in dictionary.items():
        index += value
        if random_number <= index:
            return key

    # fallback: trả về key cuối cùng
    return list(dictionary.keys())[-1]


def main():
    random.seed(SEED)

    number_of_events = 500000 

    print("Generating Data")
    users = [
        # nhóm user "đa dạng – thực tế"
        User(500001, 40, 20, 15, 10, 10, 5),
        User(500002, 25, 15, 25, 20, 10, 5),
        User(500003, 30, 30, 20, 10, 5, 5),
        User(500004, 20, 20, 30, 15, 10, 5),
        User(500005, 35, 10, 25, 10, 10, 10),
        User(500006, 30, 15, 20, 20, 10, 5),

        # nhóm chuyên 1 category nhưng không quá cực đoan
        User(500101, 60, 10, 10, 10, 5, 5),
        User(500102, 10, 60, 10, 10, 5, 5),
        User(500103, 10, 10, 60, 10, 5, 5),
        User(500104, 10, 10, 10, 60, 5, 5),
        User(500105, 10, 10, 10, 10, 60, 5),
        User(500106, 10, 10, 10, 10, 5, 60),

        # nhóm user cold-start
        User(500201, 15, 15, 15, 15, 15, 15),
        User(500202, 20, 10, 20, 10, 20, 20),
        User(500203, 10, 20, 10, 30, 20, 10),
        User(500204, 5, 10, 20, 20, 25, 20),
        User(500205, 18, 18, 16, 16, 16, 16),
        User(500206, 22, 18, 12, 20, 15, 13),
    ]
    print("Simulating " + str(len(users)) + " visitors")

    for x in range(number_of_events):
        user = random.choice(users)
        selected_prod = select_prod(user)
        action = select_action(user)
            
        if action == 'purchase':
            user.events[user.sessionId].append(selected_prod)

        print(f"user id {user.userId} selects product {selected_prod} and {action}")

        cursor.execute("""
            INSERT INTO collector_log (user_id, product_id, event, session_id, created)
            VALUES (?, ?, ?, ?, ?)
        """, (
            str(user.userId),
            selected_prod,
            action,
            str(user.get_session_id()),
            datetime.datetime.now().isoformat()
        ))
        conn.commit()

    print("users\n")
    for u in users:
        print(f"user with id {u.userId}\n")
        for key, value in u.events.items():
            if len(value) > 0:
                print(f" {key}: {value}")


if __name__ == '__main__':
    print("Starting Grocery Log Population script...")
    main()
