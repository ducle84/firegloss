import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from firebase_service import firebase_service
from models import (
    UserCreate, UserUpdate, UserResponse, APIResponse,
    CompanyCreate, CompanyUpdate, EmployeeCreate, EmployeeUpdate,
    CategoryCreate, CategoryUpdate, ItemCreate, ItemUpdate
)

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
"""
Health-check endpoint for the FastAPI application.

This asynchronous GET handler responds to requests at the root path ("/") and
returns a JSON-serializable dictionary describing service health.

Meaning of the syntax used:
- @app.get("/") : a FastAPI decorator that registers this function as the handler
    for HTTP GET requests to the "/" route.
- async def health_check(): declares an asynchronous coroutine function; FastAPI
    will run it in the event loop and can await I/O inside it.
- The function returns a Python dict; FastAPI automatically serializes this to a
    JSON HTTP response with a 200 status code by default.
- firebase_status is determined by evaluating the truthiness of
    firebase_service.db: if truthy -> "connected", otherwise -> "not connected".
- datetime.now().isoformat() produces an ISO 8601 timestamp string included in
    the response.

Returns:
        dict: A JSON-serializable mapping with keys:
                - "status": overall service status (e.g., "healthy")
                - "message": human-readable message about the API
                - "firebase_status": "connected" or "not connected" depending on Firebase DB
                - "timestamp": ISO-formatted current timestamp
"""
async def health_check():
    """Health check endpoint"""
    firebase_status = "connected" if firebase_service.db else "not connected"
    return {
        "status": "healthy",
        "message": "FireGloss Backend API is running",
        "firebase_status": firebase_status,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/test")
async def test_endpoint():
    """Simple test endpoint that doesn't require Firebase"""
    return {
        "success": True,
        "message": "Backend server is running successfully!",
        "test_data": {
            "server": "FastAPI",
            "python_version": "3.x",
            "timestamp": datetime.now().isoformat()
        }
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

# Company Endpoints
@app.post("/companies", response_model=APIResponse)
async def create_company(company: CompanyCreate):
    """Create a new company"""
    try:
        company_data = {
            **company.dict(),
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        company_id = firebase_service.create_document("companies", company_data)
        
        return APIResponse(
            success=True,
            message="Company created successfully",
            data={"id": company_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/companies", response_model=APIResponse)
async def get_companies():
    """Get all companies"""
    try:
        companies = firebase_service.get_all_documents("companies")
        
        return APIResponse(
            success=True,
            message=f"Retrieved {len(companies)} companies",
            data={"companies": companies, "count": len(companies)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/companies/{company_id}", response_model=APIResponse)
async def update_company(company_id: str, company_update: CompanyUpdate):
    """Update company"""
    try:
        update_data = {k: v for k, v in company_update.dict().items() if v is not None}
        update_data["updatedAt"] = datetime.now()
        
        firebase_service.update_document("companies", company_id, update_data)
        
        return APIResponse(
            success=True,
            message="Company updated successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/companies/{company_id}", response_model=APIResponse)
async def delete_company(company_id: str):
    """Delete company"""
    try:
        firebase_service.delete_document("companies", company_id)
        
        return APIResponse(
            success=True,
            message="Company deleted successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Employee Endpoints
@app.post("/employees", response_model=APIResponse)
async def create_employee(employee: EmployeeCreate):
    """Create a new employee"""
    try:
        employee_data = {
            **employee.dict(),
            "isActive": True,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        employee_id = firebase_service.create_document("employees", employee_data)
        
        return APIResponse(
            success=True,
            message="Employee created successfully",
            data={"id": employee_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees", response_model=APIResponse)
async def get_employees():
    """Get all employees"""
    try:
        employees = firebase_service.get_all_documents("employees")
        
        return APIResponse(
            success=True,
            message=f"Retrieved {len(employees)} employees",
            data={"employees": employees, "count": len(employees)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/employees/{employee_id}", response_model=APIResponse)
async def update_employee(employee_id: str, employee_update: EmployeeUpdate):
    """Update employee"""
    try:
        update_data = {k: v for k, v in employee_update.dict().items() if v is not None}
        update_data["updatedAt"] = datetime.now()
        
        firebase_service.update_document("employees", employee_id, update_data)
        
        return APIResponse(
            success=True,
            message="Employee updated successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/employees/{employee_id}", response_model=APIResponse)
async def delete_employee(employee_id: str):
    """Delete employee"""
    try:
        firebase_service.delete_document("employees", employee_id)
        
        return APIResponse(
            success=True,
            message="Employee deleted successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Item Category Endpoints
@app.post("/categories", response_model=APIResponse)
async def create_category(category: CategoryCreate):
    """Create a new item category"""
    try:
        category_data = {
            **category.dict(),
            "isActive": True,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        category_id = firebase_service.create_document("item_categories", category_data)
        
        return APIResponse(
            success=True,
            message="Category created successfully",
            data={"id": category_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/categories", response_model=APIResponse)
async def get_categories():
    """Get all item categories"""
    try:
        categories = firebase_service.get_all_documents("item_categories")
        
        return APIResponse(
            success=True,
            message=f"Retrieved {len(categories)} categories",
            data={"categories": categories, "count": len(categories)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/categories/{category_id}", response_model=APIResponse)
async def update_category(category_id: str, category_update: CategoryUpdate):
    """Update category"""
    try:
        update_data = {k: v for k, v in category_update.dict().items() if v is not None}
        update_data["updatedAt"] = datetime.now()
        
        firebase_service.update_document("item_categories", category_id, update_data)
        
        return APIResponse(
            success=True,
            message="Category updated successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/categories/{category_id}", response_model=APIResponse)
async def delete_category(category_id: str):
    """Delete category"""
    try:
        firebase_service.delete_document("item_categories", category_id)
        
        return APIResponse(
            success=True,
            message="Category deleted successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Item Endpoints
@app.post("/items", response_model=APIResponse)
async def create_item(item: ItemCreate):
    """Create a new item"""
    try:
        item_data = {
            **item.dict(),
            "isActive": True,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        item_id = firebase_service.create_document("items", item_data)
        
        return APIResponse(
            success=True,
            message="Item created successfully",
            data={"id": item_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/items", response_model=APIResponse)
async def get_items():
    """Get all items"""
    try:
        items = firebase_service.get_all_documents("items")
        
        return APIResponse(
            success=True,
            message=f"Retrieved {len(items)} items",
            data={"items": items, "count": len(items)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/items/{item_id}", response_model=APIResponse)
async def update_item(item_id: str, item_update: ItemUpdate):
    """Update item"""
    try:
        update_data = {k: v for k, v in item_update.dict().items() if v is not None}
        update_data["updatedAt"] = datetime.now()
        
        firebase_service.update_document("items", item_id, update_data)
        
        return APIResponse(
            success=True,
            message="Item updated successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/items/{item_id}", response_model=APIResponse)
async def delete_item(item_id: str):
    """Delete item"""
    try:
        firebase_service.delete_document("items", item_id)
        
        return APIResponse(
            success=True,
            message="Item deleted successfully"
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