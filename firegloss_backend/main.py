import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from firebase_service import firebase_service
from models import UserCreate, UserUpdate, UserResponse, APIResponse

app = FastAPI(
    title="FireGloss Backend API",
    description="Backend API for FireGloss Flutter application",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "FireGloss Backend API is running",
        "timestamp": datetime.now().isoformat()
    }

@app.post("/users", response_model=APIResponse)
async def create_user(user: UserCreate):
    """Create a new user"""
    try:
        user_data = {
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "avatar_url": user.avatar_url,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
        
        user_id = firebase_service.create_user(user_data)
        
        return APIResponse(
            success=True,
            message="User created successfully",
            data={"user_id": user_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}", response_model=APIResponse)
async def get_user(user_id: str):
    """Get user by ID"""
    try:
        user_data = firebase_service.get_user(user_id)
        
        if not user_data:
            raise HTTPException(status_code=404, detail="User not found")
        
        return APIResponse(
            success=True,
            message="User retrieved successfully",
            data=user_data
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/users/{user_id}", response_model=APIResponse)
async def update_user(user_id: str, user_update: UserUpdate):
    """Update user"""
    try:
        # Check if user exists
        existing_user = firebase_service.get_user(user_id)
        if not existing_user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Prepare update data (only include non-None fields)
        update_data = {}
        if user_update.name is not None:
            update_data["name"] = user_update.name
        if user_update.phone is not None:
            update_data["phone"] = user_update.phone
        if user_update.avatar_url is not None:
            update_data["avatar_url"] = user_update.avatar_url
        
        update_data["updated_at"] = datetime.now()
        
        firebase_service.update_user(user_id, update_data)
        
        return APIResponse(
            success=True,
            message="User updated successfully",
            data={"user_id": user_id}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/users/{user_id}", response_model=APIResponse)
async def delete_user(user_id: str):
    """Delete user"""
    try:
        # Check if user exists
        existing_user = firebase_service.get_user(user_id)
        if not existing_user:
            raise HTTPException(status_code=404, detail="User not found")
        
        firebase_service.delete_user(user_id)
        
        return APIResponse(
            success=True,
            message="User deleted successfully",
            data={"user_id": user_id}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users", response_model=APIResponse)
async def get_all_users():
    """Get all users"""
    try:
        users = firebase_service.get_all_users()
        
        return APIResponse(
            success=True,
            message=f"Retrieved {len(users)} users",
            data={"users": users, "count": len(users)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    host = os.getenv("API_HOST", "127.0.0.1")
    port = int(os.getenv("API_PORT", 8000))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=debug
    )