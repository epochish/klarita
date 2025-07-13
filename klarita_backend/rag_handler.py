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
try:
    from . import enhanced_rl_handler, analytics_handler
    HAS_ENHANCED_FEATURES = True
except ImportError:
    HAS_ENHANCED_FEATURES = False

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
    Invokes the AI to get a structured breakdown of a user's goal, personalized with RAG and RL.
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

    # Enhance with RL recommendations and analytics
    if HAS_ENHANCED_FEATURES:
        try:
            # Get RL-based recommendations
            rl_recommendations = enhanced_rl_handler.get_rl_recommendations(db, user_id, goal)
            
            # Get analytics insights for context
            analytics_stats = analytics_handler.get_quick_stats(db, user_id)
            best_time_stats = analytics_handler.get_time_of_day_stats(db, user_id)
            
            # Enhance preferences with RL learning
            pref_str += f"\n\nRL-learned preferences: {rl_recommendations}"
            
            # Add analytics context
            if analytics_stats.overall_completion_rate > 0:
                pref_str += f"\nUser typically completes {analytics_stats.overall_completion_rate:.1f}% of tasks."
            
            if best_time_stats:
                best_time = max(best_time_stats, key=lambda x: x.completion_rate)
                pref_str += f"\nBest performance at {best_time.hour:02d}:00 with {best_time.completion_rate:.1f}% completion."
            
            # Add task categorization context
            task_category = analytics_handler.categorize_task(goal)
            category_stats = analytics_handler.get_category_stats(db, user_id)
            for cat_stat in category_stats:
                if cat_stat.category == task_category:
                    pref_str += f"\nFor {task_category} tasks, user typically completes {cat_stat.completion_rate:.1f}%."
                    break
                    
        except Exception as e:
            print(f"Error enhancing with RL/analytics: {e}")

    try:
        # 2. Invoke the RAG chain
        ai_response_str = rag_chain.invoke({"goal": goal, "context": context, "preferences": pref_str})

        # Cleanup: remove code fences/backticks if model wrapped JSON in markdown
        ai_response_str = ai_response_str.strip()
        if ai_response_str.startswith("```"):
            ai_response_str = ai_response_str.strip("` ")
        if ai_response_str.lower().startswith("json"):
            ai_response_str = ai_response_str[4:].strip()

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


def get_stuck_coach_response(message: str, user_id: int, db: Session = None) -> str:
    """
    Provides personalized stuck coach response using RAG and analytics context.
    """
    print(f"Generating enhanced stuck coach response for user {user_id}: '{message}'")
    
    # Enhanced stuck coach prompt with personalization
    enhanced_stuck_coach_prompt = ChatPromptTemplate.from_messages([
        ("system", """
You are Klarita, a calm and empathetic AI coach specializing in helping users with ADHD who feel "stuck" or overwhelmed.

Here is what you know about this user:
{user_context}

Your approach should be:
1. Use a gentle, Socratic questioning style to help them identify the smallest possible next step
2. Reference their past successes and patterns when appropriate
3. Be reassuring and non-judgmental
4. Keep responses short and focused on one question or gentle suggestion at a time
5. Help reduce their anxiety and help them feel capable of starting

Your goal is to help them break through their mental block and take action.
"""),
        ("human", "{message}")
    ])
    
    # Build user context
    user_context = "General user guidance."
    
    if db and HAS_ENHANCED_FEATURES:
        try:
            # Get user analytics for context
            analytics_stats = analytics_handler.get_quick_stats(db, user_id)
            category_stats = analytics_handler.get_category_stats(db, user_id)
            
            # Build personalized context
            context_parts = []
            
            if analytics_stats.overall_completion_rate > 0:
                context_parts.append(f"User typically completes {analytics_stats.overall_completion_rate:.1f}% of their tasks.")
            
            if analytics_stats.current_streak > 0:
                context_parts.append(f"User is currently on a {analytics_stats.current_streak}-day streak.")
            
            if category_stats:
                best_category = max(category_stats, key=lambda x: x.completion_rate)
                context_parts.append(f"User performs best with {best_category.category} tasks ({best_category.completion_rate:.1f}% success rate).")
            
            # Get recent memories for encouragement
            try:
                memories = get_memories_from_vector_store(user_id, message)
                if memories:
                    context_parts.append("User has successfully handled similar challenges before.")
            except Exception as e:
                print(f"Error getting memories: {e}")
            
            # Get RL insights about user preferences
            try:
                adaptive_prefs = enhanced_rl_handler.rl_handler.get_adaptive_preferences(db, user_id)
                if adaptive_prefs:
                    context_parts.append("AI has learned this user's optimal working patterns.")
            except Exception as e:
                print(f"Error getting RL preferences: {e}")
            
            if context_parts:
                user_context = " ".join(context_parts)
                
        except Exception as e:
            print(f"Error building user context: {e}")
    
    # Create enhanced chain
    enhanced_stuck_coach_chain = enhanced_stuck_coach_prompt | llm | StrOutputParser()
    
    try:
        # Get AI response with personalized context
        ai_response = enhanced_stuck_coach_chain.invoke({
            "message": message,
            "user_context": user_context
        })
        
        return ai_response.strip()
        
    except Exception as e:
        print(f"Error generating stuck coach response: {e}")
        return "I'm here to help. What's the smallest step you could take right now to move forward?"

