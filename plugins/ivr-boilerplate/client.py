class MockWazoCalldClient:
    """
    Mock client for Wazo's calld API.
    Replace with actual Wazo SDK or API client for 'calld'.
    """
    def __init__(self, base_url="http://localhost:8000/calld"):
        self.base_url = base_url
        logger.info(f"Initialized MockWazoCalldClient for {base_url}")

    def get_call_info(self, call_id: str) -> Dict[str, Any]:
        """Simulates fetching call information."""
        logger.info(f"Mock: Fetching call info for {call_id}")
        # In a real scenario, this would make an HTTP GET request
        return {"call_id": call_id, "status": "active", "caller_id": "1234567890"}

    def bridge_call(self, call_id: str, destination: str) -> bool:
        """Simulates bridging a call to a destination (e.g., queue, agent)."""
        logger.info(f"Mock: Bridging call {call_id} to {destination}")
        # In a real scenario, this would make an HTTP POST request
        return True

    def play_audio(self, call_id: str, audio_path: str) -> bool:
        """Simulates playing an audio file to a call."""
        logger.info(f"Mock: Playing audio {audio_path} to call {call_id}")
        # This would typically involve instructing Asterisk via calld
        return True

    def collect_dtmf(self, call_id: str, timeout: int = 5, digits: int = 1) -> str:
        """Simulates collecting DTMF digits from a call."""
        logger.info(f"Mock: Collecting {digits} DTMF digits from call {call_id} with timeout {timeout}s")
        # This would involve interacting with Asterisk via calld
        # For boilerplate, we can simulate a digit, or return empty if no input
        return "1" # Simulate user pressing '1' for example

    def record_call(self, call_id: str, start: bool = True) -> bool:
        """Simulates starting or stopping call recording."""
        action = "starting" if start else "stopping"
        logger.info(f"Mock: {action} recording for call {call_id}")
        return True


class MockWazoConfdClient:
    """
    Mock client for Wazo's confd API.
    Replace with actual Wazo SDK or API client for 'confd'.
    """
    def __init__(self, base_url="http://localhost:8001/confd"):
        self.base_url = base_url
        logger.info(f"Initialized MockWazoConfdClient for {base_url}")

    def get_queue_agents(self, queue_id: str) -> Dict[str, Any]:
        """Simulates fetching agents for a given queue."""
        logger.info(f"Mock: Fetching agents for queue {queue_id}")
        return {"queue_id": queue_id, "agents": [{"id": "agent1", "status": "available"}]}

    def get_extension_details(self, extension: str) -> Dict[str, Any]:
        """Simulates fetching details for an extension."""
        logger.info(f"Mock: Fetching details for extension {extension}")
        return {"extension": extension, "type": "internal", "device": "SIP/1001"}


class MockWazoDirdClient:
    """
    Mock client for Wazo's dird API.
    Replace with actual Wazo SDK or API client for 'dird'.
    """
    def __init__(self, base_url="http://localhost:8002/dird"):
        self.base_url = base_url
        logger.info(f"Initialized MockWazoDirdClient for {base_url}")

    def get_user_details(self, user_id: str) -> Dict[str, Any]:
        """Simulates fetching user details from the directory."""
        logger.info(f"Mock: Fetching user details for {user_id}")
        return {"user_id": user_id, "name": "John Doe", "extension": "1001"}

