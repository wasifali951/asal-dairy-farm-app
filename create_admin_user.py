import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth

# Keep the service-account key local and out of source control.
cred = credentials.Certificate(
    'asal-dairy-milk-shop-firebase-adminsdk-fbsvc-b4d7b6083d.json'
)
firebase_admin.initialize_app(cred)

db = firestore.client()

admin_email = "nexanovasolutions.site@gmail.com"

try:
    user = auth.get_user_by_email(admin_email)
    user_id = user.uid
    auth.update_user(user_id, email_verified=True)

    user_data = {
        "id": user_id,
        "name": "Asal Dairy Admin",
        "email": admin_email,
        "phone": "03218409358",
        "address": "",
        "role": "admin",  # This is the crucial part for admin access
        "isRegistered": True,
    }

    db.collection("users").document(user_id).set(user_data)
    print(
        f"Successfully verified {admin_email} and updated user {user_id} "
        "with admin role."
    )
except Exception as e:
    print(f"Error creating/updating user: {e}")
    if hasattr(e, "details"):
        print(f"Details: {e.details}")
