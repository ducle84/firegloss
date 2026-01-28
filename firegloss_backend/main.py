import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from firebase_service import firebase_service
from models import (
    UserCreate, UserUpdate, UserResponse, APIResponse,
    CompanyCreate, CompanyUpdate, EmployeeCreate, EmployeeUpdate,
    CategoryCreate, CategoryUpdate, ItemCreate, ItemUpdate,
    TransactionCreate, TransactionUpdate, TransactionLineCreate, TransactionLineUpdate,
    TransactionStatus, PaymentMethod, ItemType
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

# Transaction endpoints
@app.get("/transactions", response_model=APIResponse)
async def get_transactions():
    """Get all transactions"""
    try:
        transactions = firebase_service.get_all_transactions()
        
        return APIResponse(
            success=True,
            message="Transactions retrieved successfully",
            data={"transactions": transactions}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transactions", response_model=APIResponse)
async def create_transaction(transaction: TransactionCreate):
    """Create a new transaction"""
    try:
        # Use the client-provided timestamps if available, otherwise use UTC time
        from datetime import timezone
        current_time = datetime.now(timezone.utc)
        transaction_data = {
            "companyId": transaction.companyId,
            "transactionNumber": transaction.transactionNumber,
            "transactionDate": transaction.transactionDate,
            "customerId": transaction.customerId,
            "customerName": transaction.customerName,
            "customerPhone": transaction.customerPhone,
            "customerEmail": transaction.customerEmail,
            "employeeId": transaction.employeeId,
            "status": transaction.status,
            "paymentMethod": transaction.paymentMethod,
            "subtotal": transaction.subtotal,
            "tax": transaction.tax,
            "discount": transaction.discount,
            "tip": transaction.tip,
            "total": transaction.total,
            "notes": transaction.notes,
            "createdAt": transaction.createdAt if hasattr(transaction, 'createdAt') and transaction.createdAt else current_time,
            "updatedAt": transaction.updatedAt if hasattr(transaction, 'updatedAt') and transaction.updatedAt else current_time
        }
        
        transaction_id = firebase_service.create_transaction(transaction_data)
        
        # Get the created transaction to return it
        created_transaction = firebase_service.get_transaction(transaction_id)
        created_transaction['id'] = transaction_id
        
        return APIResponse(
            success=True,
            message="Transaction created successfully",
            data={"transaction": created_transaction}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/transactions/{transaction_id}", response_model=APIResponse)
async def get_transaction(transaction_id: str):
    """Get transaction by ID"""
    try:
        transaction = firebase_service.get_transaction(transaction_id)
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        transaction['id'] = transaction_id
        
        return APIResponse(
            success=True,
            message="Transaction retrieved successfully",
            data={"transaction": transaction}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/transactions/{transaction_id}", response_model=APIResponse)
async def update_transaction(transaction_id: str, transaction_update: TransactionUpdate):
    """Update transaction"""
    try:
        # Check if transaction exists
        existing_transaction = firebase_service.get_transaction(transaction_id)
        if not existing_transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        # Prepare update data
        update_data = {
            "updatedAt": datetime.now()
        }
        
        # Add only provided fields to update data
        if transaction_update.customerId is not None:
            update_data["customerId"] = transaction_update.customerId
        if transaction_update.customerName is not None:
            update_data["customerName"] = transaction_update.customerName
        if transaction_update.customerPhone is not None:
            update_data["customerPhone"] = transaction_update.customerPhone
        if transaction_update.customerEmail is not None:
            update_data["customerEmail"] = transaction_update.customerEmail
        if transaction_update.status is not None:
            update_data["status"] = transaction_update.status
        if transaction_update.paymentMethod is not None:
            update_data["paymentMethod"] = transaction_update.paymentMethod
        if transaction_update.subtotal is not None:
            update_data["subtotal"] = transaction_update.subtotal
        if transaction_update.tax is not None:
            update_data["tax"] = transaction_update.tax
        if transaction_update.discount is not None:
            update_data["discount"] = transaction_update.discount
        if transaction_update.tip is not None:
            update_data["tip"] = transaction_update.tip
        if transaction_update.total is not None:
            update_data["total"] = transaction_update.total
        if transaction_update.notes is not None:
            update_data["notes"] = transaction_update.notes
        
        firebase_service.update_transaction(transaction_id, update_data)
        
        return APIResponse(
            success=True,
            message="Transaction updated successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/transactions/{transaction_id}", response_model=APIResponse)
async def delete_transaction(transaction_id: str):
    """Delete transaction"""
    try:
        # Check if transaction exists
        existing_transaction = firebase_service.get_transaction(transaction_id)
        if not existing_transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        firebase_service.delete_transaction(transaction_id)
        
        return APIResponse(
            success=True,
            message="Transaction deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Transaction Lines endpoints
@app.get("/transactions/{transaction_id}/lines", response_model=APIResponse)
async def get_transaction_lines(transaction_id: str):
    """Get all lines for a transaction"""
    try:
        # Check if transaction exists
        transaction = firebase_service.get_transaction(transaction_id)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        lines = firebase_service.get_transaction_lines(transaction_id)
        
        return APIResponse(
            success=True,
            message="Transaction lines retrieved successfully",
            data={"lines": lines}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transactions/{transaction_id}/lines", response_model=APIResponse)
async def add_transaction_line(transaction_id: str, line: TransactionLineCreate):
    """Add a line to a transaction"""
    try:
        # Check if transaction exists
        transaction = firebase_service.get_transaction(transaction_id)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        line_data = {
            "transactionId": transaction_id,
            "itemId": line.itemId,
            "itemName": line.itemName,
            "itemType": line.itemType,
            "quantity": line.quantity,
            "unitPrice": line.unitPrice,
            "lineTotal": line.lineTotal,
            "technicianId": line.technicianId,
            "serviceDuration": line.serviceDuration,
            "notes": line.notes,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        line_id = firebase_service.create_transaction_line(line_data)
        
        return APIResponse(
            success=True,
            message="Transaction line added successfully",
            data={"line_id": line_id}
        )
    except HTTPException:
        raise
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