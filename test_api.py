#!/usr/bin/env python3

import requests
import json
import base64
from typing import Dict, Any, Optional

# Configuration - Update these with your actual values
API_BASE_URL = "https://k.khulnasoft.com"  # From HealthEducationSettings
USERNAME = "demo"  # Default auto-login username
PASSWORD = "demo123"  # Default auto-login password

def login(username: str, password: str) -> Optional[str]:
    """Login and get authentication token"""
    print(f"\n1. Attempting login with username: {username}")
    
    url = f"{API_BASE_URL}/auth/login"
    data = {
        "username": username,
        "password": password
    }
    
    try:
        response = requests.post(url, data=data)
        print(f"   - Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            token = result.get("access_token")
            print(f"   - Login successful! Token: {token[:20]}...")
            return token
        else:
            print(f"   - Login failed: {response.text}")
            return None
    except Exception as e:
        print(f"   - Error: {e}")
        return None

def test_chat_api(token: str, query: str) -> Dict[str, Any]:
    """Test the chat API endpoint"""
    print(f"\n2. Testing chat API with query: '{query}'")
    
    url = f"{API_BASE_URL}/api/v2/chat"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "query": query,
        "include_images": True,
        "max_images": 3
    }
    
    print(f"   - Request URL: {url}")
    print(f"   - Request Headers: {headers}")
    print(f"   - Request Body: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"   - Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   - Response received successfully!")
            return result
        else:
            print(f"   - Error: {response.text}")
            return {}
    except Exception as e:
        print(f"   - Error: {e}")
        return {}

def analyze_response(response: Dict[str, Any]):
    """Analyze and display the API response"""
    print("\n3. Analyzing API Response:")
    
    # Basic info
    print(f"   - Answer length: {len(response.get('answer', ''))} characters")
    print(f"   - Sources count: {len(response.get('sources', []))}")
    print(f"   - Images count: {len(response.get('images', []))}")
    
    # Answer preview
    answer = response.get('answer', '')
    if answer:
        preview = answer[:200] + "..." if len(answer) > 200 else answer
        print(f"\n   Answer Preview:")
        print(f"   {preview}")
    
    # Images analysis
    images = response.get('images', [])
    if images:
        print(f"\n   Images Details:")
        for i, img in enumerate(images, 1):
            print(f"\n   Image {i}:")
            print(f"     - ID: {img.get('image_id', 'N/A')}")
            print(f"     - Filename: {img.get('filename', 'N/A')}")
            print(f"     - Description: {img.get('description', 'N/A')}")
            print(f"     - Has base64_data: {img.get('base64_data') is not None}")
            if img.get('base64_data'):
                print(f"     - Base64 length: {len(img['base64_data'])}")
            print(f"     - Has image_url: {img.get('image_url') is not None}")
            print(f"     - File path: {img.get('file_path', 'N/A')}")
    
    # Sources
    sources = response.get('sources', [])
    if sources:
        print(f"\n   Sources:")
        for i, source in enumerate(sources[:3], 1):  # Show first 3 sources
            if isinstance(source, dict):
                source_text = source.get('value', str(source))
            else:
                source_text = str(source)
            preview = source_text[:100] + "..." if len(source_text) > 100 else source_text
            print(f"     {i}. {preview}")
    
    # Additional metadata
    if response.get('confidence_score'):
        print(f"\n   Confidence Score: {response['confidence_score']}")
    if response.get('model_used'):
        print(f"   Model Used: {response['model_used']}")
    if response.get('processing_time'):
        print(f"   Processing Time: {response['processing_time']}s")

def save_response_to_file(response: Dict[str, Any], filename: str = "api_response.json"):
    """Save the full response to a JSON file"""
    with open(filename, 'w') as f:
        json.dump(response, f, indent=2)
    print(f"\n4. Full response saved to: {filename}")

def main():
    print("=" * 60)
    print("Health Education API Test Script")
    print("=" * 60)
    
    # Step 1: Login
    token = login(USERNAME, PASSWORD)
    if not token:
        print("\nFailed to authenticate. Please check credentials.")
        return
    
    # Step 2: Test different queries
    queries = [
        "what is blood pressure in AD?",
        "what is autonomic dysreflexia?",
        "how to prevent pressure injuries?"
    ]
    
    for query in queries[:1]:  # Test first query for now
        response = test_chat_api(token, query)
        if response:
            analyze_response(response)
            save_response_to_file(response)
    
    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()