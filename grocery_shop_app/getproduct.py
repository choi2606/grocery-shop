import firebase_admin
from firebase_admin import credentials, firestore

# 🔥 1. Load service account
cred = credentials.Certificate("grocery-96b92-firebase-adminsdk-fbsvc-b965e6332a.json")  
firebase_admin.initialize_app(cred)
db = firestore.client()

def get_products_by_category(category: str):
    """
    Lấy danh sách sản phẩm thuộc category truyền vào
    """
    products_ref = db.collection('products')
    query = products_ref.where('productCategoryName', '==', category)
    docs = query.stream()

    results = []
    for doc in docs:
        data = doc.to_dict()
        data["doc_id"] = doc.id
        results.append(data)

    return results


if __name__ == "__main__":
    category = "raucu"
    products = get_products_by_category(category)

    if not products:
        print("Không có sản phẩm nào!")
    else:
        print(f"Tìm thấy {len(products)} sản phẩm:")
        for p in products:
            print(f"'{p.get('id')}',")