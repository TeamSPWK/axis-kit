"""Backend API module — no UI code."""

from typing import Optional


def get_user(user_id: int) -> Optional[dict]:
    """Fetch user by ID from database."""
    # Simulated DB lookup
    users = {1: {"id": 1, "name": "Alice"}, 2: {"id": 2, "name": "Bob"}}
    return users.get(user_id)


def create_user(name: str, email: str) -> dict:
    """Create a new user record."""
    if not name or not email:
        raise ValueError("name and email are required")
    return {"id": 999, "name": name, "email": email}


def list_users(limit: int = 10, offset: int = 0) -> list:
    """Return paginated list of users."""
    return []
