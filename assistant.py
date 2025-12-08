# assistant.py
from google import genai
from config import GEMINI_API_KEY

def fetch_gemini_data(query):
    """
    Fetches a response from the Gemini API using the official SDK.
    """
    try:
        # Initialize the client
        client = genai.Client(api_key=GEMINI_API_KEY)
        
        # Generate content
        response = client.models.generate_content(
            model="gemini-2.0-flash", 
            contents=query
        )
        
        return response.text
    except Exception as e:
        return f"An error occurred: {e}"

if __name__ == "__main__":
    # Simple test call
    user_query = "Hello, world! Tell me a fun fact about space."
    print(f"Query: {user_query}")
    result = fetch_gemini_data(user_query)
    print("Response:")
    print(result)
