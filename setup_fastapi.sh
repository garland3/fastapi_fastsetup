#!/bin/bash

# Prompt for project name
read -p "Enter your project name: " PROJECT_NAME

# Validate project name
if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

# Prompt for additional options
read -p "Enter the port number for your FastAPI app (default: 8000): " PORT
PORT=${PORT:-8000}

read -p "Include example API endpoints? (y/n, default: n): " INCLUDE_EXAMPLES
INCLUDE_EXAMPLES=${INCLUDE_EXAMPLES:-n}

read -p "Include database setup (SQLAlchemy)? (y/n, default: n): " INCLUDE_DB
INCLUDE_DB=${INCLUDE_DB:-n}

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create necessary directories
mkdir -p "static/css" "static/js" "templates"

# Create main.py file
cat << EOF > main.py
from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.get('/')
def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

EOF

# Add example endpoints if requested
if [[ "$INCLUDE_EXAMPLES" =~ ^[Yy]$ ]]; then
    cat << EOF >> main.py
@app.get('/api/hello')
def hello():
    return {"message": "Hello, World!"}

@app.get('/api/items/{item_id}')
def read_item(item_id: int):
    return {"item_id": item_id}
EOF
fi

# Add database setup if requested
if [[ "$INCLUDE_DB" =~ ^[Yy]$ ]]; then
    cat << EOF >> main.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF
fi

# Add main block
cat << EOF >> main.py

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='127.0.0.1', port=$PORT)
EOF

# Create template for index.html file
cat << EOF > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME</title>
    <link rel="stylesheet" href="{{ url_for('static', path='/css/main.css') }}">
</head>
<body>
    <h1>Welcome to $PROJECT_NAME!</h1>
    <p>Built with FastAPI</p>
    <script src="{{ url_for('static', path='/js/script.js') }}"></script>
</body>
</html>
EOF

# Create empty files for CSS and JavaScript
touch static/css/main.css
touch static/js/script.js

# Create requirements.txt
cat << EOF > requirements.txt
fastapi
uvicorn
jinja2
EOF

# Add SQLAlchemy to requirements if database setup is included
if [[ "$INCLUDE_DB" =~ ^[Yy]$ ]]; then
    echo "sqlalchemy" >> requirements.txt
fi

echo "$PROJECT_NAME has been created successfully!"
echo "To run the app:"
echo "1. cd $PROJECT_NAME"
echo "2. pip install -r requirements.txt"
echo "3. uvicorn main:app --reload --port $PORT"





# Create run_server.sh
cat << EOF > run_server.sh
#!/bin/bash

# Check if we're in the correct directory
if [ ! -f "main.py" ]; then
    echo "Error: main.py not found. Make sure you're in the project directory."
    exit 1
fi

# Check if virtual environment exists and activate it
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "Virtual environment not found. Consider creating one for better dependency management."
fi

# Install or upgrade dependencies
echo "Installing/upgrading dependencies..."
pip install -r requirements.txt

# Run the FastAPI server
echo "Starting FastAPI server on port $PORT..."
uvicorn main:app --reload --port $PORT
EOF

# Make run_server.sh executable
chmod +x run_server.sh

echo "$PROJECT_NAME has been created successfully!"
echo "To run the app:"
echo "1. cd $PROJECT_NAME"
echo "2. ./run_server.sh"
