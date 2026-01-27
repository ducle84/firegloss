from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class UserBase(BaseModel):
    email: str
    name: str
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

class UserResponse(UserBase):
    id: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

# Company Models
class CompanyCreate(BaseModel):
    uid: str  # Firebase Auth UID for company login
    name: str
    address: str
    phone: str
    email: str
    website: Optional[str] = None
    taxId: Optional[str] = None
    logoUrl: Optional[str] = None

class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    taxId: Optional[str] = None
    logoUrl: Optional[str] = None
    isActive: Optional[bool] = None

# Employee Models
class EmployeeCreate(BaseModel):
    uid: str
    companyId: str
    email: str
    firstName: str
    lastName: str
    phone: Optional[str] = None
    role: str  # technician, manager, admin
    hourlyRate: Optional[float] = None
    commissionRate: Optional[float] = None
    hiredDate: datetime

class EmployeeUpdate(BaseModel):
    email: Optional[str] = None
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    hourlyRate: Optional[float] = None
    commissionRate: Optional[float] = None
    isActive: Optional[bool] = None

# Item Category Models
class CategoryCreate(BaseModel):
    name: str
    description: str
    color: Optional[str] = None

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    color: Optional[str] = None
    isActive: Optional[bool] = None

# Item Models
class ItemCreate(BaseModel):
    name: str
    description: str
    type: str  # service or product
    categoryId: str
    price: float
    durationMinutes: Optional[int] = None
    sku: Optional[str] = None
    stockQuantity: Optional[int] = None

class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    categoryId: Optional[str] = None
    price: Optional[float] = None
    durationMinutes: Optional[int] = None
    sku: Optional[str] = None
    stockQuantity: Optional[int] = None
    isActive: Optional[bool] = None

# Transaction Models
class TransactionStatus(str, Enum):
    NEW = "newTransaction"
    ASSIGNED = "assigned"
    IN_PROGRESS = "inProgress"
    ON_HOLD = "onHold"
    CANCELLED = "cancelled"
    VOIDED = "voided"
    COMPLETE = "complete"

class PaymentMethod(str, Enum):
    CASH = "cash"
    CARD = "card"
    CHECK = "check"
    OTHER = "other"

class ItemType(str, Enum):
    SERVICE = "service"
    PRODUCT = "product"

class TransactionCreate(BaseModel):
    companyId: str
    transactionNumber: str
    transactionDate: datetime
    customerId: Optional[str] = None
    customerName: Optional[str] = None
    customerPhone: Optional[str] = None
    customerEmail: Optional[str] = None
    employeeId: str
    status: TransactionStatus = TransactionStatus.NEW
    paymentMethod: PaymentMethod = PaymentMethod.CASH
    subtotal: float = 0.0
    tax: float = 0.0
    discount: float = 0.0
    tip: float = 0.0
    total: float = 0.0
    notes: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

class TransactionUpdate(BaseModel):
    customerId: Optional[str] = None
    customerName: Optional[str] = None
    customerPhone: Optional[str] = None
    customerEmail: Optional[str] = None
    status: Optional[TransactionStatus] = None
    paymentMethod: Optional[PaymentMethod] = None
    subtotal: Optional[float] = None
    tax: Optional[float] = None
    discount: Optional[float] = None
    tip: Optional[float] = None
    total: Optional[float] = None
    notes: Optional[str] = None

class TransactionLineCreate(BaseModel):
    transactionId: str
    itemId: str
    itemName: str
    itemType: ItemType
    quantity: int
    unitPrice: float
    lineTotal: float
    technicianId: Optional[str] = None
    serviceDuration: Optional[int] = None
    notes: Optional[str] = None

class TransactionLineUpdate(BaseModel):
    quantity: Optional[int] = None
    unitPrice: Optional[float] = None
    lineTotal: Optional[float] = None
    technicianId: Optional[str] = None
    serviceDuration: Optional[int] = None
    notes: Optional[str] = None

class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None