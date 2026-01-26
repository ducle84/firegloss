import os
import json
from typing import Optional
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

class FirebaseService:
    def __init__(self):
        self.app = None
        self.db = None
        self.initialize_firebase()
    
    def initialize_firebase(self):
        """Initialize Firebase Admin SDK"""
        try:
            # Check if Firebase is already initialized
            if not firebase_admin._apps:
                # Try to use service account file
                cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
                
                if cred_path and os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    self.app = firebase_admin.initialize_app(cred)
                else:
                    # Use default credentials (useful for Cloud Run/GCP)
                    self.app = firebase_admin.initialize_app()
                
                self.db = firestore.client()
                print("Firebase initialized successfully")
            else:
                self.app = firebase_admin.get_app()
                self.db = firestore.client()
                print("Using existing Firebase app")
                
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            raise e
    
    def create_user(self, user_data: dict) -> str:
        """Create a new user document"""
        try:
            doc_ref = self.db.collection('users').document()
            doc_ref.set(user_data)
            return doc_ref.id
        except Exception as e:
            print(f"Error creating user: {e}")
            raise e
    
    def get_user(self, user_id: str) -> Optional[dict]:
        """Get a user document by ID"""
        try:
            doc_ref = self.db.collection('users').document(user_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting user: {e}")
            raise e
    
    def update_user(self, user_id: str, user_data: dict) -> bool:
        """Update a user document"""
        try:
            doc_ref = self.db.collection('users').document(user_id)
            doc_ref.update(user_data)
            return True
        except Exception as e:
            print(f"Error updating user: {e}")
            raise e
    
    def delete_user(self, user_id: str) -> bool:
        """Delete a user document"""
        try:
            doc_ref = self.db.collection('users').document(user_id)
            doc_ref.delete()
            return True
        except Exception as e:
            print(f"Error deleting user: {e}")
            raise e
    
    def get_all_users(self) -> list:
        """Get all users from the collection"""
        try:
            users = []
            docs = self.db.collection('users').stream()
            
            for doc in docs:
                user_data = doc.to_dict()
                user_data['id'] = doc.id
                users.append(user_data)
            
            return users
        except Exception as e:
            print(f"Error getting all users: {e}")
            raise e
    
    def create_document(self, collection_name: str, data: dict) -> str:
        """Create a document in any collection"""
        try:
            doc_ref = self.db.collection(collection_name).document()
            doc_ref.set(data)
            return doc_ref.id
        except Exception as e:
            print(f"Error creating document in {collection_name}: {e}")
            raise e
    
    def get_document(self, collection_name: str, document_id: str) -> Optional[dict]:
        """Get a document from any collection"""
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting document from {collection_name}: {e}")
            raise e

# Create a singleton instance
firebase_service = FirebaseService()