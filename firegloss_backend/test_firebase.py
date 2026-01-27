import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

def test_firebase_connection():
    """Test Firebase connection"""
    load_dotenv()
    
    try:
        if not firebase_admin._apps:
            print("Attempting to connect to Firebase...")
            
            # Try to use service account file from .env
            cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
            if cred_path and os.path.exists(cred_path):
                print(f"Using credentials file: {cred_path}")
                cred = credentials.Certificate(cred_path)
                app = firebase_admin.initialize_app(cred)
            else:
                print("No credentials file found, using default credentials...")
                app = firebase_admin.initialize_app()
        else:
            app = firebase_admin.get_app()
        
        db = firestore.client()
        
        print("Testing Firestore connection...")
        doc_ref = db.collection("test").document("connection_test")
        doc_ref.set({
            "message": "Backend connection test successful",
            "timestamp": firestore.SERVER_TIMESTAMP
        })
        print(" Firebase connection successful!")
        print(f"   Project ID: {app.project_id}")
        
        return True
        
    except Exception as e:
        print(f" Firebase connection failed: {e}")
        return False

if __name__ == "__main__":
    test_firebase_connection()
