# ALORA Backend API Documentation

Complete API documentation for the ALORA Electronics Component Intelligence Backend.

## Base URL

```
http://localhost:8000
```

## Authentication

All protected endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-access-token>
```

Tokens expire after 24 hours (configurable via `ACCESS_TOKEN_EXPIRE_HOURS`).

---

## API Endpoints

### 1. Health Check

**GET** `/`

Check if the API is running.

**Response:**
```json
{
  "message": "ALORA Backend API",
  "status": "running"
}
```

---

### 2. Register User

**POST** `/register`

Register a new user account. Returns a JWT token upon successful registration.

**Request Body:**
```json
{
  "username": "string",
  "email": "string (valid email)",
  "password": "string"
}
```

**Response:** `201 Created`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Error Responses:**
- `400 Bad Request`: Username or email already registered
```json
{
  "detail": "Username or email already registered"
}
```

**Example:**
```bash
curl -X POST "http://localhost:8000/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

---

### 3. Login

**POST** `/login`

Authenticate and receive a JWT access token.

**Request Body (form-data):**
```
username: string
password: string
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Error Responses:**
- `401 Unauthorized`: Incorrect username or password
```json
{
  "detail": "Incorrect username or password"
}
```

**Example:**
```bash
curl -X POST "http://localhost:8000/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

**Note:** Default admin credentials:
- Username: `admin`
- Password: `admin123`
(Change in production!)

---

### 4. Get Current User

**GET** `/me`

Get information about the currently authenticated user.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "username": "admin",
  "email": "admin@alora.local"
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or missing token
```json
{
  "detail": "Could not validate credentials"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/me" \
  -H "Authorization: Bearer <your-token>"
```

---

### 5. Chat with ALORA Agent

**POST** `/chat`

Query the ALORA agent about components, inventory, and equivalents. The agent uses database tools to provide accurate information.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "message": "string"
}
```

**Response:** `200 OK`
```json
{
  "answer": "S9012 is out of stock (0 units). BC857B is a compatible PNP replacement with 150 units available at $0.12 per unit. Total inventory value: $18.00.",
  "confidence": "HIGH"
}
```

**Confidence Levels:**
- `HIGH`: Agent used multiple tools and has high confidence
- `MEDIUM`: Agent used at least one tool
- `LOW`: Agent answered without using tools or encountered an error

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token
- `500 Internal Server Error`: Error processing the request
```json
{
  "detail": "Error processing chat request: <error message>"
}
```

**Example Queries:**
```bash
# Check component availability
curl -X POST "http://localhost:8000/chat" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Do we have S9012? Suggest replacement if not."}'

# Check inventory with pricing
curl -X POST "http://localhost:8000/chat" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the total value of our BC857B inventory?"}'

# Find component by marking
curl -X POST "http://localhost:8000/chat" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Find component with marking 2N3904 and check stock"}'
```

---

## Data Models

### Component Data Structure

Components returned by the API include inventory information and support multiple component types:

**Complete Component Structure:**
```json
{
  "id": 1,
  "part_number": "S9012",
  "marking": "S9012",
  "category_id": 1,
  "category_name": "Transistor",
  "technology": "PNP",
  "polarity": "PNP",
  "channel": null,
  "package": "SOT-23",
  "v_max": "25V",
  "i_max": "0.5A",
  "power_max": "0.625W",
  "gain_min": null,
  "gain_max": null,
  "unit_price": 0.15,
  "status": "ACTIVE",
  "notes": null,
  "additional_characteristics": null,
  "quantity": 0,
  "min_qty": 10,
  "location": "A1-B2",
  "inventory_last_updated": "2024-01-15T10:30:00",
  "total_value": 0.0,
  "rds_on": null,
  "vgs_max": null,
  "vgs_th": null,
  "qg": null,
  "ciss": null,
  "switching_type": null,
  "vf": null,
  "trr": null,
  "cj": null,
  "diode_type": null,
  "internal_config": null,
  "v_in_max": null,
  "v_out": null,
  "i_out_max": null,
  "accuracy": null,
  "reg_type": null
}
```

**Field Categories:**

1. **Basic Fields** (all components):
   - `id`, `part_number`, `marking`, `category_id`, `category_name`
   - `technology`, `polarity`, `channel`, `package`
   - `v_max`, `i_max`, `power_max`, `gain_min`, `gain_max` (strings with units)
   - `unit_price`, `status`, `notes`
   - `additional_characteristics` (flexible JSON object)

2. **MOSFET Fields** (for MOSFET components):
   - `rds_on`: On-resistance, e.g. "22mΩ @ 4.5V"
   - `vgs_max`: Max gate-source voltage, e.g. "±20V"
   - `vgs_th`: Gate threshold voltage, e.g. "1–3V"
   - `qg`: Gate charge, e.g. "15nC"
   - `ciss`: Input capacitance, e.g. "500pF"
   - `switching_type`: Switching type, e.g. "Logic-Level", "High-Speed"

3. **Diode Fields** (for diode components):
   - `vf`: Forward voltage @ IF, e.g. "1.0V @ 10mA", "0.35V @ 100mA"
   - `trr`: Reverse recovery time, e.g. "4ns", "N/A"
   - `cj`: Junction capacitance, e.g. "2pF", "20pF"
   - `diode_type`: Diode type, e.g. "Switching", "Schottky"
   - `internal_config`: Configuration type, e.g. "Series", "Common Cathode", "Single"

4. **Voltage Regulator Fields** (for voltage regulator components):
   - `v_in_max`: Maximum input voltage, e.g. "36V", "35V"
   - `v_out`: Output voltage, e.g. "3.3V", "5V", "2.5V adjustable"
   - `i_out_max`: Maximum output current, e.g. "1A", "500mA", "100mA"
   - `accuracy`: Voltage accuracy, e.g. "±1%", "±5%"
   - `reg_type`: Regulator type, e.g. "Linear", "Switching", "Voltage Reference"

5. **Inventory Fields** (included with each component):
   - `quantity`: Current stock quantity (0 if no inventory record)
   - `min_qty`: Minimum quantity threshold
   - `location`: Storage location
   - `inventory_last_updated`: Last inventory update timestamp
   - `total_value`: Total inventory value (calculated as `quantity * unit_price`)

**Notes:** 
- `v_max`, `i_max`, `power_max`, `gain_min`, `gain_max` are strings to support units (e.g., "25V", "0.5A", "0.625W")
- Component-specific fields (MOSFET, Diode, Voltage Regulator) are `null` for components that don't use them
- Inventory fields are included with each component. If no inventory record exists, `quantity` will be `0` and other inventory fields will be `null`
- `total_value` is calculated as `quantity * unit_price`
- `additional_characteristics` is a flexible JSON object for any component-specific attributes

### Inventory Data Structure

Inventory information includes:

```json
{
  "component_id": 1,
  "quantity": 150,
  "min_qty": 20,
  "location": "A2-B3",
  "last_updated": "2024-01-15T10:30:00",
  "unit_price": 0.12,
  "total_value": 18.00
}
```

**Note:** `total_value` is calculated as `quantity * unit_price`.

### Equivalent Components

Equivalents include pricing and inventory:

```json
{
  "id": 1,
  "component_id": 1,
  "equivalent_id": 2,
  "reason": "Both are PNP transistors in SOT-23 package. BC857B has higher voltage rating.",
  "part_number": "BC857B",
  "marking": "BC857B",
  "technology": "PNP",
  "package": "SOT-23",
  "v_max": "45V",
  "i_max": "0.1A",
  "unit_price": 0.12,
  "quantity": 150,
  "total_value": 18.00
}
```

---

## Agent Capabilities

The ALORA agent can:

1. **Lookup Components** - Find components by part number or marking
2. **Check Inventory** - Get stock levels, locations, and total value
3. **Find Equivalents** - Suggest compatible replacements with pricing
4. **Log Actions** - Record important decisions and operations

The agent automatically uses these tools when answering questions. It will:
- Never invent components not in the database
- Check inventory before making recommendations
- Include pricing information (unit_price and total_value)
- Suggest equivalents only when stock is insufficient
- Explain its reasoning clearly

---

## Error Handling

### Standard Error Response Format

```json
{
  "detail": "Error message description"
}
```

### Common HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or failed
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

## Authentication Flow

### Typical Frontend Flow

1. **User Registration/Login**
   ```javascript
   // Login
   const response = await fetch('http://localhost:8000/login', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/x-www-form-urlencoded',
     },
     body: new URLSearchParams({
       username: 'admin',
       password: 'admin123'
     })
   });
   
   const { access_token } = await response.json();
   localStorage.setItem('token', access_token);
   ```

2. **Making Authenticated Requests**
   ```javascript
   const token = localStorage.getItem('token');
   
   const response = await fetch('http://localhost:8000/chat', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       message: 'Check S9012 availability'
     })
   });
   
   const data = await response.json();
   ```

3. **Handle Token Expiration**
   ```javascript
   if (response.status === 401) {
     // Token expired, redirect to login
     localStorage.removeItem('token');
     window.location.href = '/login';
   }
   ```

---

## Component Management Examples

### Create Component
```typescript
const component = await client.createComponent({
  part_number: "BC547",
  marking: "BC547",
  category_id: 1,
  technology: "NPN",
  package: "TO-92",
  v_max: "45V",
  unit_price: 0.10
});
```

### Update Component
```typescript
const updated = await client.updateComponent(5, {
  unit_price: 0.12,
  v_max: "50V"
});
```

### Soft Delete Component
```typescript
await client.deleteComponent(5); // Sets status to INACTIVE
```

### List Components
```typescript
// Get all active components
const activeComponents = await client.listComponents({ status_filter: "ACTIVE" });

// Get components by category
const transistors = await client.listComponents({ category_id: 1 });
```

---

## Example Integration (JavaScript/TypeScript)

```typescript
// API Client Class
class ALORAClient {
  private baseURL: string;
  private token: string | null = null;

  constructor(baseURL: string = 'http://localhost:8000') {
    this.baseURL = baseURL;
    this.token = localStorage.getItem('token');
  }

  async login(username: string, password: string): Promise<string> {
    const formData = new URLSearchParams();
    formData.append('username', username);
    formData.append('password', password);

    const response = await fetch(`${this.baseURL}/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData
    });

    if (!response.ok) {
      throw new Error('Login failed');
    }

    const data = await response.json();
    this.token = data.access_token;
    localStorage.setItem('token', this.token);
    return this.token;
  }

  async chat(message: string): Promise<{ answer: string; confidence: string }> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/chat`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ message })
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      throw new Error('Chat request failed');
    }

    return await response.json();
  }

  async getCurrentUser(): Promise<{ id: number; username: string; email: string }> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/me`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    return await response.json();
  }

  async createComponent(component: any): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/components`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(component)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to create component');
    }

    return await response.json();
  }

  async listComponents(filters?: { status_filter?: string; category_id?: number }): Promise<any[]> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const params = new URLSearchParams();
    if (filters?.status_filter) params.append('status_filter', filters.status_filter);
    if (filters?.category_id !== undefined) params.append('category_id', filters.category_id.toString());

    const url = `${this.baseURL}/components${params.toString() ? '?' + params.toString() : ''}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    return await response.json();
  }

  async getComponent(id: number): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/components/${id}`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (response.status === 404) {
      throw new Error('Component not found');
    }

    return await response.json();
  }

  async updateComponent(id: number, updates: any): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/components/${id}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(updates)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to update component');
    }

    return await response.json();
  }

  async deleteComponent(id: number): Promise<void> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/components/${id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (response.status === 404) {
      throw new Error('Component not found');
    }

    if (!response.ok) {
      throw new Error('Failed to delete component');
    }
  }

  async getInventoryCost(filters?: { category_id?: number; status_filter?: string; include_low_stock?: boolean }): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const params = new URLSearchParams();
    if (filters?.category_id !== undefined) params.append('category_id', filters.category_id.toString());
    if (filters?.status_filter) params.append('status_filter', filters.status_filter);
    if (filters?.include_low_stock !== undefined) params.append('include_low_stock', filters.include_low_stock.toString());

    const url = `${this.baseURL}/inventory/cost${params.toString() ? '?' + params.toString() : ''}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    return await response.json();
  }

  async addInventory(inventory: { component_id: number; quantity: number; min_qty?: number; location?: string }): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/inventory`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(inventory)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to add inventory');
    }

    return await response.json();
  }

  async listInventory(component_id?: number): Promise<any[]> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const params = new URLSearchParams();
    if (component_id !== undefined) params.append('component_id', component_id.toString());

    const url = `${this.baseURL}/inventory${params.toString() ? '?' + params.toString() : ''}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    return await response.json();
  }

  async getInventory(component_id: number): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/inventory/${component_id}`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (response.status === 404) {
      throw new Error('Inventory not found');
    }

    return await response.json();
  }

  async updateInventory(component_id: number, updates: { quantity?: number; min_qty?: number; location?: string }): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/inventory/${component_id}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(updates)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to update inventory');
    }

    return await response.json();
  }

  async adjustInventoryQuantity(component_id: number, adjustment: number): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/inventory/${component_id}/adjust?adjustment=${adjustment}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to adjust inventory');
    }

    return await response.json();
  }

  async createCategory(category: { name: string; description?: string }): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/categories`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(category)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to create category');
    }

    return await response.json();
  }

  async listCategories(status_filter?: string): Promise<any[]> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const params = new URLSearchParams();
    if (status_filter) params.append('status_filter', status_filter);

    const url = `${this.baseURL}/categories${params.toString() ? '?' + params.toString() : ''}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    return await response.json();
  }

  async getCategory(category_id: number): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/categories/${category_id}`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (response.status === 404) {
      throw new Error('Category not found');
    }

    return await response.json();
  }

  async updateCategory(category_id: number, updates: { name?: string; description?: string; status?: string }): Promise<any> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/categories/${category_id}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(updates)
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to update category');
    }

    return await response.json();
  }

  async deleteCategory(category_id: number): Promise<void> {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const response = await fetch(`${this.baseURL}/categories/${category_id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (response.status === 401) {
      this.token = null;
      localStorage.removeItem('token');
      throw new Error('Token expired');
    }

    if (response.status === 404) {
      throw new Error('Category not found');
    }

    if (!response.ok) {
      throw new Error('Failed to delete category');
    }
  }
}

// Usage
const client = new ALORAClient();

// Login
await client.login('admin', 'admin123');

// Chat with agent
const result = await client.chat('Do we have S9012?');
console.log(result.answer); // "S9012 is out of stock..."
console.log(result.confidence); // "HIGH"

// Get user info
const user = await client.getCurrentUser();
console.log(user.username); // "admin"
```

---

## Python Example

```python
import requests

class ALORAClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.token = None
    
    def login(self, username: str, password: str) -> str:
        response = requests.post(
            f"{self.base_url}/login",
            data={"username": username, "password": password}
        )
        response.raise_for_status()
        self.token = response.json()["access_token"]
        return self.token
    
    def chat(self, message: str) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.post(
            f"{self.base_url}/chat",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json={"message": message}
        )
        response.raise_for_status()
        return response.json()
    
    def get_current_user(self) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.get(
            f"{self.base_url}/me",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
        return response.json()
    
    def create_component(self, component: dict) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.post(
            f"{self.base_url}/components",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json=component
        )
        response.raise_for_status()
        return response.json()
    
    def list_components(self, status_filter: str = None, category_id: int = None) -> list:
        if not self.token:
            raise ValueError("Not authenticated")
        
        params = {}
        if status_filter:
            params["status_filter"] = status_filter
        if category_id is not None:
            params["category_id"] = category_id
        
        response = requests.get(
            f"{self.base_url}/components",
            headers={"Authorization": f"Bearer {self.token}"},
            params=params
        )
        response.raise_for_status()
        return response.json()
    
    def get_component(self, component_id: int) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.get(
            f"{self.base_url}/components/{component_id}",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
        return response.json()
    
    def update_component(self, component_id: int, updates: dict) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.put(
            f"{self.base_url}/components/{component_id}",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json=updates
        )
        response.raise_for_status()
        return response.json()
    
    def delete_component(self, component_id: int) -> None:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.delete(
            f"{self.base_url}/components/{component_id}",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
    
    def get_inventory_cost(self, category_id: int = None, status_filter: str = "ACTIVE", include_low_stock: bool = True) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        params = {}
        if category_id is not None:
            params["category_id"] = category_id
        if status_filter:
            params["status_filter"] = status_filter
        params["include_low_stock"] = include_low_stock
        
        response = requests.get(
            f"{self.base_url}/inventory/cost",
            headers={"Authorization": f"Bearer {self.token}"},
            params=params
        )
        response.raise_for_status()
        return response.json()
    
    def add_inventory(self, component_id: int, quantity: int, min_qty: int = 0, location: str = None) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.post(
            f"{self.base_url}/inventory",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json={
                "component_id": component_id,
                "quantity": quantity,
                "min_qty": min_qty,
                "location": location
            }
        )
        response.raise_for_status()
        return response.json()
    
    def list_inventory(self, component_id: int = None) -> list:
        if not self.token:
            raise ValueError("Not authenticated")
        
        params = {}
        if component_id is not None:
            params["component_id"] = component_id
        
        response = requests.get(
            f"{self.base_url}/inventory",
            headers={"Authorization": f"Bearer {self.token}"},
            params=params
        )
        response.raise_for_status()
        return response.json()
    
    def get_inventory(self, component_id: int) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.get(
            f"{self.base_url}/inventory/{component_id}",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
        return response.json()
    
    def update_inventory(self, component_id: int, quantity: int = None, min_qty: int = None, location: str = None) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        updates = {}
        if quantity is not None:
            updates["quantity"] = quantity
        if min_qty is not None:
            updates["min_qty"] = min_qty
        if location is not None:
            updates["location"] = location
        
        response = requests.put(
            f"{self.base_url}/inventory/{component_id}",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json=updates
        )
        response.raise_for_status()
        return response.json()
    
    def adjust_inventory_quantity(self, component_id: int, adjustment: int) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.post(
            f"{self.base_url}/inventory/{component_id}/adjust",
            headers={"Authorization": f"Bearer {self.token}"},
            params={"adjustment": adjustment}
        )
        response.raise_for_status()
        return response.json()
    
    def create_category(self, name: str, description: str = None) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.post(
            f"{self.base_url}/categories",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json={"name": name, "description": description}
        )
        response.raise_for_status()
        return response.json()
    
    def list_categories(self, status_filter: str = None) -> list:
        if not self.token:
            raise ValueError("Not authenticated")
        
        params = {}
        if status_filter:
            params["status_filter"] = status_filter
        
        response = requests.get(
            f"{self.base_url}/categories",
            headers={"Authorization": f"Bearer {self.token}"},
            params=params
        )
        response.raise_for_status()
        return response.json()
    
    def get_category(self, category_id: int) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.get(
            f"{self.base_url}/categories/{category_id}",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
        return response.json()
    
    def update_category(self, category_id: int, name: str = None, description: str = None, status: str = None) -> dict:
        if not self.token:
            raise ValueError("Not authenticated")
        
        updates = {}
        if name is not None:
            updates["name"] = name
        if description is not None:
            updates["description"] = description
        if status is not None:
            updates["status"] = status
        
        response = requests.put(
            f"{self.base_url}/categories/{category_id}",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            },
            json=updates
        )
        response.raise_for_status()
        return response.json()
    
    def delete_category(self, category_id: int) -> None:
        if not self.token:
            raise ValueError("Not authenticated")
        
        response = requests.delete(
            f"{self.base_url}/categories/{category_id}",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()

# Usage
client = ALORAClient()
client.login("admin", "admin123")

# Chat with agent
result = client.chat("Check S9012 availability")
print(result["answer"])

# Create component
component = client.create_component({
    "part_number": "BC547",
    "category_id": 1,
    "technology": "NPN",
    "package": "TO-92",
    "unit_price": 0.10
})

# List components
components = client.list_components(status_filter="ACTIVE")

# Update component
updated = client.update_component(component["id"], {"unit_price": 0.12})

# Soft delete component
client.delete_component(component["id"])

# Get inventory cost summary
cost_summary = client.get_inventory_cost()
print(f"Total inventory value: ${cost_summary['total_value']}")
print(f"Total components: {cost_summary['total_components']}")
print(f"Total quantity: {cost_summary['total_quantity']}")

# Get cost for specific category
transistor_cost = client.get_inventory_cost(category_id=1)

# Add inventory for a component
inventory = client.add_inventory(component_id=1, quantity=150, min_qty=20, location="A2-B3")

# List all inventory
all_inventory = client.list_inventory()

# Get inventory for specific component
component_inventory = client.get_inventory(component_id=1)

# Update inventory
updated_inventory = client.update_inventory(component_id=1, quantity=200, min_qty=25)

# Adjust inventory quantity (add 10 units)
adjusted = client.adjust_inventory_quantity(component_id=1, adjustment=10)

# Adjust inventory quantity (subtract 5 units)
adjusted = client.adjust_inventory_quantity(component_id=1, adjustment=-5)
```

---

## Notes

1. **CORS**: The API is configured to allow all origins. Configure appropriately for production.

2. **Token Storage**: Store tokens securely. Consider using httpOnly cookies in production.

3. **Error Handling**: Always check response status codes and handle errors appropriately.

4. **Rate Limiting**: Currently not implemented. Consider adding for production.

5. **Unit Prices**: All prices are in the base currency (configure as needed). The `unit_price` field is stored per component, and `total_value` is calculated as `quantity * unit_price`.

6. **Database**: SQLite database is automatically initialized on first startup. Default admin user is created if it doesn't exist.

7. **Additional Characteristics**: The `additional_characteristics` field is a flexible JSON object that can store any component-specific attributes. This allows the schema to handle different component types (ICs, resistors, capacitors, diodes, etc.) without schema changes.

8. **Component-Specific Fields**: The API supports dedicated fields for different component types:
   - **MOSFET fields**: `rds_on`, `vgs_max`, `vgs_th`, `qg`, `ciss`, `switching_type`
   - **Diode fields**: `vf`, `trr`, `cj`, `diode_type`, `internal_config`
   - **Voltage Regulator fields**: `v_in_max`, `v_out`, `i_out_max`, `accuracy`, `reg_type`
   - These fields are optional and should be `null` for components that don't use them

9. **Inventory Cost Calculation**: The `/inventory/cost` endpoint calculates total inventory value by summing `quantity * unit_price` for all components. It also provides breakdowns by category and identifies low stock items.

10. **Inventory Management**: Use `/inventory` endpoints to add, update, and manage component quantities. The `/inventory/{id}/adjust` endpoint allows you to add or subtract quantities easily without needing to know the current quantity.

11. **Components with Inventory**: The `/components` endpoints automatically include inventory information (quantity, min_qty, location, total_value) with each component. If no inventory record exists, `quantity` will be `0` and other inventory fields will be `null`.

12. **Component Specifications as Strings**: The `v_max`, `i_max`, `power_max`, `gain_min`, and `gain_max` fields are strings to support units (e.g., "25V", "0.5A", "0.625W"). This allows flexible specification formats with units included.

13. **Internal Configuration**: The `internal_config` field is used for dual diode configurations (e.g., "Series", "Common Cathode", "Single") and can be used for other component-specific internal configurations.

---

## Component Management Endpoints

### 6. Create Component

**POST** `/components`

Create a new component in the database.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "part_number": "BC547",
  "marking": "BC547",
  "category_id": 1,
  "technology": "NPN",
  "polarity": "NPN",
  "channel": "SINGLE",
  "package": "TO-92",
  "v_max": "45V",
  "i_max": "0.1A",
  "power_max": "0.5W",
  "gain_min": "110",
  "gain_max": "800",
  "unit_price": 0.10,
  "notes": "General purpose NPN transistor",
  "additional_characteristics": {
    "ft": 300,
    "vce_sat": "0.2V"
  }
}
```

**Example for MOSFET:**
```json
{
  "part_number": "2N7002",
  "marking": "7002/703",
  "category_id": 6,
  "technology": "MOSFET",
  "polarity": "N-MOSFET",
  "channel": "N",
  "package": "SOT-23",
  "v_max": "60V",
  "i_max": "300mA",
  "power_max": "350mW",
  "unit_price": 0.10,
  "rds_on": "5Ω @ 4.5V",
  "vgs_max": "±20V",
  "vgs_th": "2–4V",
  "qg": "2.5nC",
  "ciss": "50pF",
  "switching_type": "Standard",
  "notes": "Small-signal switching MOSFET"
}
```

**Example for Diode:**
```json
{
  "part_number": "1N4148",
  "marking": "1N4148",
  "category_id": 7,
  "technology": "DIODE",
  "polarity": "PN",
  "channel": "SINGLE",
  "package": "SOD-323",
  "v_max": "100V",
  "i_max": "150mA",
  "power_max": "200mW",
  "unit_price": 0.05,
  "vf": "1.0V @ 10mA",
  "trr": "4ns",
  "cj": "2pF",
  "diode_type": "Switching",
  "notes": "High-speed switching diode"
}
```

**Example for Voltage Regulator:**
```json
{
  "part_number": "TL431",
  "marking": "431",
  "category_id": 10,
  "technology": "IC",
  "package": "SOT-23/TO-92",
  "v_in_max": "36V",
  "v_out": "2.5V adjustable",
  "i_out_max": "100mA",
  "power_max": "500mW",
  "accuracy": "±1%",
  "reg_type": "Voltage Reference",
  "unit_price": 0.25,
  "notes": "Precision adjustable voltage reference"
}
```

**Note:** The `v_max`, `i_max`, `power_max`, `gain_min`, and `gain_max` fields are strings to support units (e.g., "45V", "0.1A", "0.5W").

**Note:** The `additional_characteristics` field is a flexible JSON object that can store any component-specific attributes. Examples:
- **For ICs (like RK1808):** `{"pin_count": 48, "operating_voltage": "3.3V", "core": "ARM Cortex-A35", "memory": "512KB"}`
- **For Resistors:** `{"resistance": "10k", "tolerance": "5%", "power_rating": "0.25W"}`
- **For Capacitors:** `{"capacitance": "100uF", "voltage_rating": "25V", "tolerance": "20%", "type": "Electrolytic"}`

**Note:** Use dedicated fields when available:
- **For MOSFETs**: Use `rds_on`, `vgs_max`, `vgs_th`, `qg`, `ciss`, `switching_type`
- **For Diodes**: Use `vf`, `trr`, `cj`, `diode_type`, `internal_config`
- **For Voltage Regulators**: Use `v_in_max`, `v_out`, `i_out_max`, `accuracy`, `reg_type`

**Response:** `201 Created`
```json
{
  "id": 5,
  "part_number": "BC547",
  "marking": "BC547",
  "category_id": 1,
  "category_name": "Transistor",
  "technology": "NPN",
  "polarity": "NPN",
  "channel": null,
  "package": "TO-92",
  "v_max": "45V",
  "i_max": "0.1A",
  "power_max": "0.5W",
  "gain_min": null,
  "gain_max": null,
  "unit_price": 0.10,
  "status": "ACTIVE",
  "notes": "General purpose NPN transistor",
  "quantity": 0,
  "min_qty": null,
  "location": null,
  "inventory_last_updated": null,
  "total_value": 0.0
}
```

**Note:** The response includes inventory fields. If no inventory record exists yet, `quantity` will be `0` and other inventory fields will be `null`.

**Error Responses:**
- `400 Bad Request`: Component with same part_number already exists
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X POST "http://localhost:8000/components" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "part_number": "BC547",
    "marking": "BC547",
    "category_id": 1,
    "technology": "NPN",
    "package": "TO-92",
    "v_max": "45V",
    "unit_price": 0.10
  }'
```

---

### 7. List Components

**GET** `/components`

Get a list of all components with optional filters. **Each component includes inventory information.**

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status_filter` (optional): Filter by status (`ACTIVE` or `INACTIVE`)
- `category_id` (optional): Filter by category ID

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "part_number": "S9012",
    "marking": "S9012",
    "category_id": 1,
    "category_name": "Transistor",
    "technology": "PNP",
    "polarity": "PNP",
    "package": "SOT-23",
    "v_max": "25V",
    "i_max": "0.5A",
    "power_max": "0.625W",
    "unit_price": 0.15,
    "status": "ACTIVE",
    "notes": null,
    "quantity": 0,
    "min_qty": 10,
    "location": "A1-B2",
    "inventory_last_updated": "2024-01-15T10:30:00",
    "total_value": 0.0
  },
  {
    "id": 2,
    "part_number": "BC857B",
    "marking": "BC857B",
    "category_id": 1,
    "category_name": "Transistor",
    "technology": "PNP",
    "package": "SOT-23",
    "v_max": "45V",
    "i_max": "0.1A",
    "power_max": "0.25W",
    "unit_price": 0.12,
    "status": "ACTIVE",
    "notes": null,
    "quantity": 150,
    "min_qty": 20,
    "location": "A2-B3",
    "inventory_last_updated": "2024-01-15T10:30:00",
    "total_value": 18.00
  }
]
```

**Note:** Inventory fields (`quantity`, `min_qty`, `location`, `inventory_last_updated`, `total_value`) are included with each component. If no inventory record exists, `quantity` will be `0` and other inventory fields will be `null`.

**Example:**
```bash
# Get all active components
curl -X GET "http://localhost:8000/components?status_filter=ACTIVE" \
  -H "Authorization: Bearer <your-token>"

# Get components by category
curl -X GET "http://localhost:8000/components?category_id=1" \
  -H "Authorization: Bearer <your-token>"
```

---

### 8. Get Component by ID

**GET** `/components/{component_id}`

Get a single component by its ID. **Includes inventory information.**

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Response:** `200 OK`
```json
{
  "id": 1,
  "part_number": "S9012",
  "marking": "S9012",
  "category_id": 1,
  "category_name": "Transistor",
  "technology": "PNP",
  "polarity": "PNP",
  "package": "SOT-23",
  "v_max": "25V",
  "i_max": "0.5A",
  "power_max": "0.625W",
  "unit_price": 0.15,
  "status": "ACTIVE",
  "notes": null,
  "quantity": 0,
  "min_qty": 10,
  "location": "A1-B2",
  "inventory_last_updated": "2024-01-15T10:30:00",
  "total_value": 0.0
}
```

**Note:** Inventory information is automatically included. If no inventory record exists, `quantity` will be `0` and other inventory fields will be `null`.

**Error Responses:**
- `404 Not Found`: Component not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X GET "http://localhost:8000/components/1" \
  -H "Authorization: Bearer <your-token>"
```

---

### 9. Update Component

**PUT** `/components/{component_id}`

Update an existing component. Only provided fields will be updated.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Request Body:** (All fields optional)
```json
{
  "part_number": "BC547A",
  "unit_price": 0.12,
  "v_max": "50V",
  "notes": "Updated specifications"
}
```

**Response:** `200 OK`
```json
{
  "id": 5,
  "part_number": "BC547A",
  "marking": "BC547",
  "category_id": 1,
  "category_name": "Transistor",
  "technology": "NPN",
  "package": "TO-92",
  "v_max": "50V",
  "i_max": "0.1A",
  "power_max": "0.5W",
  "unit_price": 0.12,
  "status": "ACTIVE",
  "notes": "Updated specifications",
  "quantity": 0,
  "min_qty": null,
  "location": null,
  "inventory_last_updated": null,
  "total_value": 0.0
}
```

**Note:** Response includes inventory information. If no inventory exists, `quantity` will be `0`.

**Error Responses:**
- `400 Bad Request`: New part_number already exists or no fields provided
- `404 Not Found`: Component not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X PUT "http://localhost:8000/components/5" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "unit_price": 0.12,
    "v_max": "50V"
  }'
```

---

### 10. Delete Component (Soft Delete)

**DELETE** `/components/{component_id}`

Soft delete a component by setting its status to `INACTIVE`. The component is not physically deleted from the database.

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Response:** `204 No Content`

**Error Responses:**
- `404 Not Found`: Component not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X DELETE "http://localhost:8000/components/5" \
  -H "Authorization: Bearer <your-token>"
```

**Note:** After soft deletion, the component status will be `INACTIVE` and won't appear in active component listings. It can be restored by updating the status back to `ACTIVE`.

---

## Quick Reference

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/` | GET | No | Health check |
| `/register` | POST | No | Register new user |
| `/login` | POST | No | Authenticate user |
| `/me` | GET | Yes | Get current user info |
| `/chat` | POST | Yes | Chat with ALORA agent |
| `/components` | POST | Yes | Create new component |
| `/components` | GET | Yes | List components (with filters, includes inventory) |
| `/components/{id}` | GET | Yes | Get component by ID (includes inventory) |
| `/components/{id}` | PUT | Yes | Update component |
| `/components/{id}` | DELETE | Yes | Soft delete component |
| `/inventory` | POST | Yes | Add/Update inventory for component |
| `/inventory` | GET | Yes | List all inventory items |
| `/inventory/{id}` | GET | Yes | Get inventory by component ID |
| `/inventory/{id}` | PUT | Yes | Update inventory |
| `/inventory/{id}/adjust` | POST | Yes | Adjust inventory quantity (add/subtract) |
| `/inventory/cost` | GET | Yes | Calculate inventory cost summary |
| `/categories` | POST | Yes | Create new category |
| `/categories` | GET | Yes | List categories (with status filter) |
| `/categories/{id}` | GET | Yes | Get category by ID |
| `/categories/{id}` | PUT | Yes | Update category |
| `/categories/{id}` | DELETE | Yes | Soft delete category (set status to INACTIVE) |

---

## Inventory Management Endpoints

### 11. Add/Update Inventory

**POST** `/inventory`

Add or update inventory for a component. If inventory exists for the component, it will be updated. If it doesn't exist, it will be created.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "component_id": 1,
  "quantity": 150,
  "min_qty": 20,
  "location": "A2-B3"
}
```

**Response:** `201 Created`
```json
{
  "component_id": 1,
  "part_number": "BC857B",
  "component_name": "BC857B",
  "category_name": "Transistor",
  "quantity": 150,
  "min_qty": 20,
  "location": "A2-B3",
  "last_updated": "2024-01-15T10:30:00",
  "unit_price": 0.12,
  "total_value": 18.00
}
```

**Error Responses:**
- `404 Not Found`: Component not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X POST "http://localhost:8000/inventory" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "component_id": 1,
    "quantity": 150,
    "min_qty": 20,
    "location": "A2-B3"
  }'
```

---

### 12. List All Inventory

**GET** `/inventory`

Get a list of all inventory items with component details.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `component_id` (optional): Filter by specific component ID

**Response:** `200 OK`
```json
[
  {
    "component_id": 1,
    "part_number": "BC857B",
    "component_name": "BC857B",
    "category_name": "Transistor",
    "quantity": 150,
    "min_qty": 20,
    "location": "A2-B3",
    "last_updated": "2024-01-15T10:30:00",
    "unit_price": 0.12,
    "total_value": 18.00
  },
  {
    "component_id": 2,
    "part_number": "2N3904",
    "component_name": "2N3904",
    "category_name": "Transistor",
    "quantity": 75,
    "min_qty": 15,
    "location": "B1-C2",
    "last_updated": "2024-01-15T10:30:00",
    "unit_price": 0.08,
    "total_value": 6.00
  }
]
```

**Example:**
```bash
# Get all inventory
curl -X GET "http://localhost:8000/inventory" \
  -H "Authorization: Bearer <your-token>"

# Get inventory for specific component
curl -X GET "http://localhost:8000/inventory?component_id=1" \
  -H "Authorization: Bearer <your-token>"
```

---

### 13. Get Inventory by Component ID

**GET** `/inventory/{component_id}`

Get inventory details for a specific component.

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Response:** `200 OK`
```json
{
  "component_id": 1,
  "part_number": "BC857B",
  "component_name": "BC857B",
  "category_name": "Transistor",
  "quantity": 150,
  "min_qty": 20,
  "location": "A2-B3",
  "last_updated": "2024-01-15T10:30:00",
  "unit_price": 0.12,
  "total_value": 18.00
}
```

**Error Responses:**
- `404 Not Found`: Inventory not found for this component
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X GET "http://localhost:8000/inventory/1" \
  -H "Authorization: Bearer <your-token>"
```

---

### 14. Update Inventory

**PUT** `/inventory/{component_id}`

Update inventory for a component. Only provided fields will be updated.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Request Body:** (All fields optional)
```json
{
  "quantity": 200,
  "min_qty": 25,
  "location": "B1-C2"
}
```

**Response:** `200 OK`
```json
{
  "component_id": 1,
  "part_number": "BC857B",
  "component_name": "BC857B",
  "category_name": "Transistor",
  "quantity": 200,
  "min_qty": 25,
  "location": "B1-C2",
  "last_updated": "2024-01-15T11:00:00",
  "unit_price": 0.12,
  "total_value": 24.00
}
```

**Error Responses:**
- `400 Bad Request`: No fields provided for update
- `404 Not Found`: Inventory not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X PUT "http://localhost:8000/inventory/1" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 200,
    "min_qty": 25
  }'
```

---

### 15. Adjust Inventory Quantity

**POST** `/inventory/{component_id}/adjust`

Add or subtract quantity from existing inventory. Use positive number to add, negative to subtract.

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `component_id` (integer): The component ID

**Query Parameters:**
- `adjustment` (integer, required): Quantity to add (positive) or subtract (negative)

**Response:** `200 OK`
```json
{
  "component_id": 1,
  "part_number": "BC857B",
  "component_name": "BC857B",
  "category_name": "Transistor",
  "quantity": 160,
  "min_qty": 20,
  "location": "A2-B3",
  "last_updated": "2024-01-15T11:15:00",
  "unit_price": 0.12,
  "total_value": 19.20
}
```

**Error Responses:**
- `400 Bad Request`: Adjustment would result in negative quantity
- `404 Not Found`: Inventory not found
- `401 Unauthorized`: Missing or invalid token

**Examples:**
```bash
# Add 10 units to inventory
curl -X POST "http://localhost:8000/inventory/1/adjust?adjustment=10" \
  -H "Authorization: Bearer <your-token>"

# Subtract 5 units from inventory
curl -X POST "http://localhost:8000/inventory/1/adjust?adjustment=-5" \
  -H "Authorization: Bearer <your-token>"
```

**Note:** The adjustment cannot result in negative quantity. If the adjustment would make quantity negative, a 400 error will be returned with details about current quantity and the attempted adjustment.

---

## Inventory Cost Calculation

### 16. Calculate Inventory Cost

**GET** `/inventory/cost`

Calculate total inventory value and provide detailed cost summary.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `category_id` (optional): Filter by category ID
- `status_filter` (optional): Filter by status (`ACTIVE` or `INACTIVE`). Default: `ACTIVE`
- `include_low_stock` (optional): Include low stock items in response. Default: `true`

**Response:** `200 OK`
```json
{
  "total_components": 4,
  "total_quantity": 425,
  "total_value": 36.50,
  "currency": "USD",
  "breakdown_by_category": {
    "Transistor": {
      "component_count": 3,
      "total_quantity": 225,
      "total_value": 27.00
    },
    "Diode": {
      "component_count": 1,
      "total_quantity": 200,
      "total_value": 10.00
    }
  },
  "low_stock_items": [
    {
      "component_id": 1,
      "part_number": "S9012",
      "category_name": "Transistor",
      "quantity": 0,
      "min_qty": 10,
      "unit_price": 0.15,
      "total_value": 0.0,
      "shortage": 10
    }
  ]
}
```

**Example:**
```bash
# Get total inventory cost
curl -X GET "http://localhost:8000/inventory/cost" \
  -H "Authorization: Bearer <your-token>"

# Get cost for specific category
curl -X GET "http://localhost:8000/inventory/cost?category_id=1" \
  -H "Authorization: Bearer <your-token>"

# Get cost without low stock items
curl -X GET "http://localhost:8000/inventory/cost?include_low_stock=false" \
  -H "Authorization: Bearer <your-token>"
```

---

## Component Types and Additional Characteristics

The schema supports various component types through the flexible `additional_characteristics` JSON field. Here are examples for different component types:

### Integrated Circuits (ICs) - Example: RK1808
```json
{
  "part_number": "RK1808",
  "marking": "RK1808",
  "category_id": 2,
  "package": "LQFP-48",
  "unit_price": 5.50,
  "additional_characteristics": {
    "pin_count": 48,
    "operating_voltage": "3.3V",
    "core": "ARM Cortex-A35",
    "memory": "512KB",
    "clock_speed": "1.2GHz",
    "interface": ["SPI", "I2C", "UART"],
    "temperature_range": "-40°C to +85°C"
  }
}
```

### Resistors
```json
{
  "part_number": "R-10K-5%",
  "marking": "103",
  "category_id": 3,
  "package": "0805",
  "unit_price": 0.01,
  "additional_characteristics": {
    "resistance": "10kΩ",
    "tolerance": "5%",
    "power_rating": "0.25W",
    "temperature_coefficient": "100ppm/°C"
  }
}
```

### Capacitors
```json
{
  "part_number": "C-100uF-25V",
  "marking": "100uF",
  "category_id": 4,
  "package": "Radial",
  "unit_price": 0.15,
  "additional_characteristics": {
    "capacitance": "100µF",
    "voltage_rating": "25V",
    "tolerance": "20%",
    "type": "Electrolytic",
    "temperature_range": "-40°C to +105°C"
  }
}
```

### Diodes (using dedicated diode fields)
```json
{
  "part_number": "1N4148",
  "marking": "1N4148",
  "category_id": 7,
  "technology": "DIODE",
  "polarity": "PN",
  "channel": "SINGLE",
  "package": "SOD-323",
  "v_max": "100V",
  "i_max": "150mA",
  "power_max": "200mW",
  "unit_price": 0.05,
  "vf": "1.0V @ 10mA",
  "trr": "4ns",
  "cj": "2pF",
  "diode_type": "Switching",
  "internal_config": null,
  "notes": "High-speed switching diode"
}
```

### Dual Diodes (using internal_config)
```json
{
  "part_number": "BAV99",
  "marking": "A7",
  "category_id": 8,
  "technology": "DIODE",
  "polarity": "PN",
  "channel": "DUAL",
  "package": "SOT-23",
  "v_max": "70V",
  "i_max": "200mA",
  "power_max": "250mW",
  "unit_price": 0.08,
  "vf": "1.0V @ 10mA",
  "trr": "4ns",
  "cj": "1.5pF",
  "diode_type": "Switching",
  "internal_config": "Series",
  "notes": "Dual series switching diode"
}
```

### Schottky Diodes
```json
{
  "part_number": "BAT54",
  "marking": "KL1",
  "category_id": 9,
  "technology": "DIODE",
  "polarity": "PN",
  "channel": "SINGLE",
  "package": "SOT-23",
  "v_max": "30V",
  "i_max": "200mA",
  "power_max": "250mW",
  "unit_price": 0.06,
  "vf": "0.35V @ 100mA",
  "trr": "N/A",
  "cj": "20pF",
  "diode_type": "Schottky",
  "internal_config": "Single",
  "notes": "Low Vf Schottky diode"
}
```

### MOSFETs (using dedicated MOSFET fields)
```json
{
  "part_number": "2N7002",
  "marking": "7002/703",
  "category_id": 6,
  "technology": "MOSFET",
  "polarity": "N-MOSFET",
  "channel": "N",
  "package": "SOT-23",
  "v_max": "60V",
  "i_max": "300mA",
  "power_max": "350mW",
  "unit_price": 0.10,
  "rds_on": "5Ω @ 4.5V",
  "vgs_max": "±20V",
  "vgs_th": "2–4V",
  "qg": "2.5nC",
  "ciss": "50pF",
  "switching_type": "Standard",
  "notes": "Small-signal switching MOSFET"
}
```

### Voltage Regulators (using dedicated regulator fields)
```json
{
  "part_number": "TL431",
  "marking": "431",
  "category_id": 10,
  "technology": "IC",
  "package": "SOT-23/TO-92",
  "v_in_max": "36V",
  "v_out": "2.5V adjustable",
  "i_out_max": "100mA",
  "power_max": "500mW",
  "accuracy": "±1%",
  "reg_type": "Voltage Reference",
  "unit_price": 0.25,
  "notes": "Precision adjustable voltage reference"
}
```

### Linear Voltage Regulators
```json
{
  "part_number": "CJ78L05",
  "marking": "L05",
  "category_id": 10,
  "technology": "IC",
  "package": "TO-92/TO-220",
  "v_in_max": "35V",
  "v_out": "5V",
  "i_out_max": "1000mA",
  "power_max": "1W",
  "accuracy": "±5%",
  "reg_type": "Linear Regulator",
  "unit_price": 0.15,
  "notes": "5V linear voltage regulator"
}
```

### Transistors (using standard fields + additional)
```json
{
  "part_number": "BC547",
  "marking": "BC547",
  "category_id": 1,
  "technology": "NPN",
  "polarity": "NPN",
  "channel": "SINGLE",
  "package": "TO-92",
  "v_max": "45V",
  "i_max": "0.1A",
  "power_max": "0.5W",
  "gain_min": "110",
  "gain_max": "800",
  "unit_price": 0.10,
  "additional_characteristics": {
    "ft": 300,
    "vce_sat": "0.2V"
  }
}
```

**Note:** 
- The `additional_characteristics` field allows you to store any component-specific attributes that don't fit in the standard schema fields
- Component-specific fields (MOSFET, Diode, Voltage Regulator) are `null` for components that don't use them
- Use dedicated fields (`rds_on`, `vf`, `v_out`, etc.) when available instead of `additional_characteristics` for better type safety and querying
- The `internal_config` field is used for dual diode configurations (e.g., "Series", "Common Cathode", "Single")

---

## Category Management Endpoints

### 17. Create Category

**POST** `/categories`

Create a new category in the database.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "Transistor",
  "description": "Semiconductor transistors"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "name": "Transistor",
  "description": "Semiconductor transistors",
  "status": "ACTIVE"
}
```

**Error Responses:**
- `400 Bad Request`: Category with same name already exists
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X POST "http://localhost:8000/categories" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Transistor",
    "description": "Semiconductor transistors"
  }'
```

---

### 18. List Categories

**GET** `/categories`

Get a list of all categories with optional status filter.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status_filter` (optional): Filter by status (`ACTIVE` or `INACTIVE`)

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "Transistor",
    "description": "Semiconductor transistors",
    "status": "ACTIVE"
  },
  {
    "id": 2,
    "name": "Resistor",
    "description": "Passive resistors",
    "status": "ACTIVE"
  },
  {
    "id": 3,
    "name": "Old Category",
    "description": "Deprecated category",
    "status": "INACTIVE"
  }
]
```

**Example:**
```bash
# Get all categories
curl -X GET "http://localhost:8000/categories" \
  -H "Authorization: Bearer <your-token>"

# Get only active categories
curl -X GET "http://localhost:8000/categories?status_filter=ACTIVE" \
  -H "Authorization: Bearer <your-token>"
```

---

### 19. Get Category by ID

**GET** `/categories/{category_id}`

Get a single category by its ID.

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `category_id` (integer): The category ID

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Transistor",
  "description": "Semiconductor transistors",
  "status": "ACTIVE"
}
```

**Error Responses:**
- `404 Not Found`: Category not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X GET "http://localhost:8000/categories/1" \
  -H "Authorization: Bearer <your-token>"
```

---

### 20. Update Category

**PUT** `/categories/{category_id}`

Update an existing category. Only provided fields will be updated.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Path Parameters:**
- `category_id` (integer): The category ID

**Request Body:** (All fields optional)
```json
{
  "name": "Transistor Updated",
  "description": "Updated description",
  "status": "ACTIVE"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Transistor Updated",
  "description": "Updated description",
  "status": "ACTIVE"
}
```

**Error Responses:**
- `400 Bad Request`: New name already exists, invalid status, or no fields provided
- `404 Not Found`: Category not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X PUT "http://localhost:8000/categories/1" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "status": "ACTIVE"
  }'
```

---

### 21. Delete Category (Soft Delete)

**DELETE** `/categories/{category_id}`

Soft delete a category by setting its status to `INACTIVE`. The category is not physically deleted from the database.

**Headers:**
```
Authorization: Bearer <token>
```

**Path Parameters:**
- `category_id` (integer): The category ID

**Response:** `204 No Content`

**Error Responses:**
- `404 Not Found`: Category not found
- `401 Unauthorized`: Missing or invalid token

**Example:**
```bash
curl -X DELETE "http://localhost:8000/categories/3" \
  -H "Authorization: Bearer <your-token>"
```

**Note:** After soft deletion, the category status will be `INACTIVE`. Components using this category will still reference it, but the category will be marked as inactive. The category can be restored by updating the status back to `ACTIVE`.

---

---

## Component Field Reference

### All Available Component Fields

**Basic Fields (All Components):**
- `id` (integer, read-only): Component ID
- `part_number` (string, required): Unique part number
- `marking` (string, optional): Component marking
- `category_id` (integer, optional): Category ID
- `category_name` (string, read-only): Category name
- `technology` (string, optional): Technology type (e.g., "NPN", "PNP", "MOSFET", "DIODE", "IC")
- `polarity` (string, optional): Polarity (e.g., "NPN", "PNP", "N-MOSFET", "P-MOSFET", "PN")
- `channel` (string, optional): Channel type (e.g., "SINGLE", "DUAL", "N", "P")
- `package` (string, optional): Package type (e.g., "TO-92", "SOT-23", "DIP-16")
- `v_max` (string, optional): Maximum voltage with units (e.g., "25V", "60V", "-200V")
- `i_max` (string, optional): Maximum current with units (e.g., "0.5A", "300mA", "100mA")
- `power_max` (string, optional): Maximum power with units (e.g., "0.625W", "350mW", "1W")
- `gain_min` (string, optional): Minimum gain with units (e.g., "100", "110")
- `gain_max` (string, optional): Maximum gain with units (e.g., "300", "800")
- `unit_price` (float, optional): Price per unit (default: 0.0)
- `status` (string, optional): Status ("ACTIVE" or "INACTIVE", default: "ACTIVE")
- `notes` (string, optional): Additional notes
- `additional_characteristics` (object, optional): Flexible JSON object for component-specific attributes

**MOSFET-Specific Fields:**
- `rds_on` (string, optional): On-resistance (e.g., "5Ω @ 4.5V", "22mΩ @ 4.5V")
- `vgs_max` (string, optional): Max gate-source voltage (e.g., "±20V", "±12V")
- `vgs_th` (string, optional): Gate threshold voltage (e.g., "2–4V", "1–3V")
- `qg` (string, optional): Gate charge (e.g., "2.5nC", "15nC")
- `ciss` (string, optional): Input capacitance (e.g., "50pF", "500pF")
- `switching_type` (string, optional): Switching type (e.g., "Standard", "Logic-Level", "High-Speed")

**Diode-Specific Fields:**
- `vf` (string, optional): Forward voltage @ IF (e.g., "1.0V @ 10mA", "0.35V @ 100mA")
- `trr` (string, optional): Reverse recovery time (e.g., "4ns", "2ns", "N/A")
- `cj` (string, optional): Junction capacitance (e.g., "2pF", "20pF", "25pF")
- `diode_type` (string, optional): Diode type (e.g., "Switching", "Schottky")
- `internal_config` (string, optional): Configuration type (e.g., "Series", "Common Cathode", "Common Anode", "Single")

**Voltage Regulator-Specific Fields:**
- `v_in_max` (string, optional): Maximum input voltage (e.g., "36V", "35V")
- `v_out` (string, optional): Output voltage (e.g., "3.3V", "5V", "2.5V adjustable")
- `i_out_max` (string, optional): Maximum output current (e.g., "1A", "500mA", "100mA")
- `accuracy` (string, optional): Voltage accuracy (e.g., "±1%", "±5%")
- `reg_type` (string, optional): Regulator type (e.g., "Linear", "Switching", "Voltage Reference")

**Inventory Fields (Included in Component Responses):**
- `quantity` (integer, read-only): Current stock quantity (0 if no inventory record)
- `min_qty` (integer, read-only): Minimum quantity threshold
- `location` (string, read-only): Storage location
- `inventory_last_updated` (string, read-only): Last inventory update timestamp
- `total_value` (float, read-only): Total inventory value (quantity * unit_price)

---

**check rules.md**

**Last Updated:** 2024-01-15
**API Version:** 1.0.0
