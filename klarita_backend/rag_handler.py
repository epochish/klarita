"""
AI RAG Handler for Klarita (Revamped)
Manages the Retrieval-Augmented Generation pipeline for all AI features.
"""
import os
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_community.vectorstores import Chroma
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from sqlalchemy.orm import Session
from . import models

# --- Configuration ---
# Make sure to set your GEMINI_API_KEY in your .env file
# (This is a placeholder, a proper config service should be used)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables. Please set it in your .env file.")

# --- AI Models ---
llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", google_api_key=GEMINI_API_KEY)
embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001", google_api_key=GEMINI_API_KEY)

# --- Vector Store ---
# In-memory vector store for demonstration. In production, use a persistent ChromaDB.
vector_store = Chroma(embedding_function=embeddings, persist_directory="./chroma_db_memories")
retriever = vector_store.as_retriever()

# --- Prompt Templates ---
task_breakdown_prompt = ChatPromptTemplate.from_messages([
    ("system", """
You are Klarita, an expert AI assistant specializing in helping users with ADHD break down overwhelming tasks into manageable steps. 
Your goal is to be encouraging, clear, and very specific. Always follow these rules:
1.  Deconstruct the user's goal into a sequence of small, concrete, and actionable sub-tasks.
2.  Each task title MUST start with an action verb (e.g., "Write", "Create", "Call", "Book").
3.  Estimate a realistic duration in minutes for each task. Assume the user needs short, focused work sprints.
4.  Provide a brief, one-sentence description for each task.
5.  The final output MUST be a JSON array of objects, with each object having 'title', 'description', and 'estimated_duration' keys. Do not include any other text or formatting.
"""),
    ("human", "My goal is: {goal}")
])

# --- Chains ---
task_breakdown_chain = task_breakdown_prompt | llm | StrOutputParser()

stuck_coach_prompt = ChatPromptTemplate.from_messages([
    ("system", """
You are Klarita, a calm and empathetic AI coach. Your role is to help users who feel "stuck" or overwhelmed. 
Use a gentle, Socratic questioning style to help them identify the smallest possible next step. Do not give direct advice.
Your tone should be reassuring and non-judgmental. Your goal is to reduce their anxiety and help them feel capable of starting.
Keep your responses short and focused on asking one question at a time.
"""),
    ("human", "{message}")
])

stuck_coach_chain = stuck_coach_prompt | llm | StrOutputParser()

# New prompt template for the RAG chain
rag_prompt = ChatPromptTemplate.from_messages([
    ("system", """
You are Klarita, an expert AI assistant specializing in helping users with ADHD break down overwhelming tasks.
You have been provided with examples of how this user has successfully broken down similar tasks in the past.
Use these examples to inform your new breakdown, but adapt it to the new goal.

Here are the user's past successful breakdowns (memories):
{context}

Here are the user's known preferences:
{preferences}

Your goal is to be encouraging, clear, and very specific. Always follow these rules:
1.  Deconstruct the user's new goal into a sequence of small, concrete, and actionable sub-tasks.
2.  Each task title MUST start with an action verb (e.g., "Write", "Create", "Call", "Book").
3.  Estimate a realistic duration in minutes for each task.
4.  Provide a brief, one-sentence description for each task.
5.  The final output MUST be a JSON array of objects, with each object having 'title', 'description', and 'estimated_duration' keys. Do not include any other text or formatting.
"""),
    ("human", "My new goal is: {goal}")
])

rag_chain = rag_prompt | llm | StrOutputParser()


def add_memory_to_vector_store(user_id: int, memory: models.TaskMemory):
    """
    Adds a user's successful task breakdown to their vector store.
    """
    vector_store.add_texts(
        texts=[f"Goal: {memory.original_goal}\nBreakdown: {json.dumps(memory.task_breakdown)}"],
        metadatas=[{"user_id": user_id, "memory_id": memory.id}],
        ids=[f"mem_{memory.id}"]
    )
    print(f"Added memory {memory.id} to vector store for user {user_id}")

def get_memories_from_vector_store(user_id: int, goal: str):
    """
    Retrieves relevant memories from the vector store for a given user and goal,
    ensuring that only memories belonging to the specific user are returned.
    """
    print(f"Retrieving memories for user_id: {user_id} with goal: '{goal}'")
    # Use similarity search with a metadata filter to ensure user-specific results.
    return vector_store.similarity_search(
        query=goal,
        k=3,  # Retrieve top 3 most relevant memories
        filter={"user_id": user_id}
    )


def get_initial_breakdown(db: Session, goal: str, user_id: int):
    """
    Invokes the AI to get a structured breakdown of a user's goal, personalized with RAG.
    """
    print(f"Generating RAG-powered breakdown for goal: '{goal}' for user_id: {user_id}")

    # 1. Retrieve relevant memories
    memories = get_memories_from_vector_store(user_id, goal)
    context = "\n---\n".join([mem.page_content for mem in memories]) if memories else "No past examples found."

    # Fetch user preferences
    user_pref = db.query(models.UserPreference).filter(models.UserPreference.user_id == user_id).first()
    if user_pref:
        pref_str = (
            f"Breakdown style: {user_pref.breakdown_style}. "
            f"Preferred task duration: {user_pref.preferred_task_duration} minutes. "
            f"Communication style: {user_pref.communication_style}."
        )
    else:
        pref_str = "No explicit preferences yet."

    try:
        # 2. Invoke the RAG chain
        ai_response_str = rag_chain.invoke({"goal": goal, "context": context, "preferences": pref_str})
        
        # 3. Parse the JSON response
        task_list = json.loads(ai_response_str)
        
        # Basic validation
        if not isinstance(task_list, list) or not all(isinstance(t, dict) for t in task_list):
            raise ValueError("AI response is not a valid list of tasks.")

        print(f"Successfully received and parsed {len(task_list)} tasks from the RAG chain.")
        return task_list

    except json.JSONDecodeError:
        print(f"Error: Failed to decode AI response into JSON. Response was:\n{ai_response_str}")
        return [{"title": "Review AI Suggestion", "description": "AI response was not valid JSON.", "estimated_duration": 5}]
    except Exception as e:
        print(f"An unexpected error occurred in the RAG handler: {e}")
        return [{"title": "Error", "description": "Sorry, an error occurred.", "estimated_duration": 5}]


def get_stuck_coach_response(message: str, user_id: int):
    """
    Invokes the AI coach to get a Socratic response.
    """
    print(f"Generating AI coach response for user_id: {user_id}")
    
    try:
        # Invoke the LangChain chain
        ai_response = stuck_coach_chain.invoke({"message": message})
        return ai_response
    except Exception as e:
        print(f"An unexpected error occurred in the stuck coach handler: {e}")
        return "I'm sorry, I'm having a little trouble thinking right now. Could you try asking again in a moment?"

