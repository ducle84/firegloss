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
                    self.db = firestore.client()
                    print("Firebase initialized successfully with service account")
                else:
                    # For development: create a mock app without real Firebase connection
                    print("⚠️  Firebase service account not found - running in test mode")
                    print("   To use Firebase: download service-account-key.json from Firebase Console")
                    self.app = None
                    self.db = None
                    return
                    
            else:
                self.app = firebase_admin.get_app()
                self.db = firestore.client()
                print("Using existing Firebase app")
                
        except Exception as e:
            print(f"⚠️  Firebase initialization failed: {e}")
            print("   Server will run without Firebase connectivity")
            self.app = None
            self.db = None
    
    def create_user(self, user_data: dict) -> str:
        """Create a new user document"""
        if not self.db:
            raise Exception("Firebase not initialized - please set up credentials")
        try:
            doc_ref = self.db.collection('users').document()
            doc_ref.set(user_data)
            return doc_ref.id
        except Exception as e:
            print(f"Error creating user: {e}")
            raise e
    
    def get_user(self, user_id: str) -> Optional[dict]:
        """Get a user document by ID"""
        if not self.db:
            raise Exception("Firebase not initialized - please set up credentials")
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
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            doc_ref = self.db.collection(collection_name).document()
            doc_ref.set(data)
            return doc_ref.id
        except Exception as e:
            print(f"Error creating document in {collection_name}: {e}")
            raise e
    
    def get_document(self, collection_name: str, document_id: str) -> Optional[dict]:
        """Get a document from any collection"""
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting document from {collection_name}: {e}")
            raise e
    
    def get_all_documents(self, collection_name: str) -> list:
        """Get all documents from any collection"""
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            docs = self.db.collection(collection_name).get()
            documents = []
            
            for doc in docs:
                doc_data = doc.to_dict()
                doc_data['id'] = doc.id
                documents.append(doc_data)
            
            return documents
        except Exception as e:
            print(f"Error getting documents from {collection_name}: {e}")
            raise e
    
    def update_document(self, collection_name: str, document_id: str, data: dict) -> None:
        """Update a document in any collection"""
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc_ref.update(data)
        except Exception as e:
            print(f"Error updating document in {collection_name}: {e}")
            raise e
    
    def delete_document(self, collection_name: str, document_id: str) -> None:
        """Delete a document from any collection"""
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc_ref.delete()
        except Exception as e:
            print(f"Error deleting document from {collection_name}: {e}")
            raise e
    
    # Transaction-specific methods
    def create_transaction(self, transaction_data: dict) -> str:
        """Create a new transaction document"""
        return self.create_document("transactions", transaction_data)
    
    def get_transaction(self, transaction_id: str) -> Optional[dict]:
        """Get a transaction by ID"""
        return self.get_document("transactions", transaction_id)
    
    def get_all_transactions(self) -> list:
        """Get all transactions"""
        return self.get_all_documents("transactions")
    
    def update_transaction(self, transaction_id: str, transaction_data: dict) -> None:
        """Update a transaction"""
        self.update_document("transactions", transaction_id, transaction_data)
    
    def delete_transaction(self, transaction_id: str) -> None:
        """Delete a transaction"""
        self.delete_document("transactions", transaction_id)
    
    # Transaction Lines methods
    def create_transaction_line(self, line_data: dict) -> str:
        """Create a new transaction line document"""
        return self.create_document("transaction_lines", line_data)
    
    def get_transaction_lines(self, transaction_id: str) -> list:
        """Get all transaction lines for a specific transaction"""
        if not self.db:
            raise Exception("Firebase not initialized")
        try:
            lines_ref = self.db.collection("transaction_lines").where("transactionId", "==", transaction_id)
            docs = lines_ref.stream()
            lines = []
            for doc in docs:
                line_data = doc.to_dict()
                line_data['id'] = doc.id
                lines.append(line_data)
            return lines
        except Exception as e:
            print(f"Error getting transaction lines: {e}")
            raise e
    
    def update_transaction_line(self, line_id: str, line_data: dict) -> None:
        """Update a transaction line"""
        self.update_document("transaction_lines", line_id, line_data)
    
    def delete_transaction_line(self, line_id: str) -> None:
        """Delete a transaction line"""
        self.delete_document("transaction_lines", line_id)

# Create a singleton instance
firebase_service = FirebaseService()