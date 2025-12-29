# --- IVR Flow Definition (Dynamic via API or Config File) ---

def load_ivr_flows(config_file: str) -> Dict[str, Any]:
    """
    Loads IVR flow definitions from a JSON configuration file.
    In a real system, this could also be fetched dynamically via a REST API.
    """
    if not os.path.exists(config_file):
        logger.warning(f"IVR flow config file not found: {config_file}. Loading default/empty flow.")
        # Provide a simple default IVR flow if the file doesn't exist
        return {
            "main_menu": {
                "prompt": "Welcome to our service. Press 1 for sales, 2 for support, or 9 to repeat.",
                "options": {
                    "1": {"action": "route_to_queue", "target": "sales_queue"},
                    "2": {"action": "route_to_queue", "target": "support_queue"},
                    "9": {"action": "repeat_menu"}
                },
                "fallback": {"action": "repeat_menu"}
            },
            "sales_queue": {
                "prompt": "Please wait while we connect you to sales.",
                "action": "transfer_to_queue",
                "target": "sales_queue_id_from_confd"
            },
            "support_queue": {
                "prompt": "Please wait while we connect you to support.",
                "action": "transfer_to_queue",
                "target": "support_queue_id_from_confd"
            }
        }
    try:
        with open(config_file, 'r') as f:
            flows = json.load(f)
            logger.info(f"Loaded IVR flows from {config_file}")
            return flows
    except json.JSONDecodeError as e:
        logger.error(f"Error decoding IVR flow config file {config_file}: {e}")
        return {}
    except Exception as e:
        logger.error(f"An unexpected error occurred loading IVR flows: {e}")
        return {}

# --- Wazo IVR Plugin Core ---

class WazoIVRPlugin:
    """
    Core Wazo IVR Plugin class.
    This class manages the IVR flow, interacts with Wazo APIs, and TTS backends.
    """
    def __init__(self, calld_client: MockWazoCalldClient,
                 confd_client: MockWazoConfdClient,
                 dird_client: MockWazoDirdClient,
                 tts_backend: Any): # Can be AmazonPollyTTS or AsteriskNativeTTS
        self.calld = calld_client
        self.confd = confd_client
        self.dird = dird_client
        self.tts = tts_backend
        self.ivr_flows = load_ivr_flows(IVR_FLOW_CONFIG_FILE)
        logger.info("WazoIVRPlugin initialized.")

    def _play_prompt(self, call_id: str, text: str, language: str = 'en-US') -> bool:
        """
        Plays a prompt to the caller using the configured TTS backend.
        Handles pre-generated audio if available, otherwise uses TTS.
        """
        # In a real scenario, you might check for pre-generated audio files first
        # based on 'text' and 'language'. If not found, then use TTS.
        logger.info(f"Playing prompt: '{text}' to call {call_id}")
        audio_path = self.tts.generate_audio(text)
        return self.calld.play_audio(call_id, audio_path)

    def _handle_menu(self, call_id: str, menu_node: Dict[str, Any]) -> str:
        """
        Handles a multi-level DTMF menu.
        Returns the action key based on DTMF input.
        """
        prompt = menu_node.get("prompt", "Invalid menu configuration.")
        options = menu_node.get("options", {})
        fallback_action = menu_node.get("fallback", {"action": "repeat_menu"})

        self._play_prompt(call_id, prompt)
        dtmf_input = self.calld.collect_dtmf(call_id, timeout=5, digits=1)

        if dtmf_input in options:
            logger.info(f"Call {call_id}: DTMF '{dtmf_input}' matched option.")
            return dtmf_input
        else:
            logger.warning(f"Call {call_id}: Invalid DTMF '{dtmf_input}'. Applying fallback.")
            # For boilerplate, we'll just return a special key for fallback
            return "FALLBACK_ACTION"

    def _apply_action(self, call_id: str, action_data: Dict[str, Any]) -> str:
        """
        Applies an action based on the IVR flow definition.
        Returns the next state/menu ID or "END" if the call is to be terminated/transferred.
        """
        action_type = action_data.get("action")
        target = action_data.get("target")
        logger.info(f"Call {call_id}: Applying action type '{action_type}' with target '{target}'")

        if action_type == "route_to_queue":
            # This would involve looking up queue details via confd and then bridging
            queue_id = target
            self.confd.get_queue_agents(queue_id) # Example confd interaction
            self._play_prompt(call_id, f"Connecting you to {queue_id}.")
            self.calld.bridge_call(call_id, queue_id)
            return "END"
        elif action_type == "transfer_to_extension":
            extension = target
            self.dird.get_user_details(extension) # Example dird interaction
            self._play_prompt(call_id, f"Transferring you to extension {extension}.")
            self.calld.bridge_call(call_id, extension)
            return "END"
        elif action_type == "language_selection":
            # Implement language change logic here
            # This would likely involve setting a call variable for the language
            # and re-prompting the current menu with the new language.
            logger.info(f"Call {call_id}: Language selected: {target}")
            # For boilerplate, we just return to the main menu
            return "main_menu"
        elif action_type == "call_recording_trigger":
            # Start/stop recording based on 'target' (e.g., "start", "stop")
            if target == "start":
                self.calld.record_call(call_id, start=True)
                self._play_prompt(call_id, "Call recording has started.")
            elif target == "stop":
                self.calld.record_call(call_id, start=False)
                self._play_prompt(call_id, "Call recording has stopped.")
            return "current_menu" # Stay in the current menu or go to next step
        elif action_type == "repeat_menu":
            return "current_menu" # Special key to indicate repeating the current menu
        elif action_type == "play_announcement":
            self._play_prompt(call_id, target)
            return "current_menu" # Or next logical step
        elif action_type == "time_based_routing":
            # Example time-based routing logic
            current_hour = datetime.datetime.now().hour
            if 9 <= current_hour < 17: # Business hours
                return action_data.get("business_hours_target", "main_menu")
            else: # After hours
                return action_data.get("after_hours_target", "voicemail_menu")
        elif action_type == "exit":
            self._play_prompt(call_id, "Thank you for calling. Goodbye.")
            return "END"
        else:
            logger.error(f"Call {call_id}: Unknown action type: {action_type}. Falling back.")
            return "main_menu" # Default fallback to main menu

    def handle_incoming_call(self, call_id: str, initial_context: str = "main_menu"):
        """
        Main entry point for handling an incoming call.
        This function orchestrates the IVR flow.
        """
        logger.info(f"Handling incoming call: {call_id} starting at context: {initial_context}")
        current_menu_id = initial_context

        while current_menu_id != "END":
            menu_node = self.ivr_flows.get(current_menu_id)

            if not menu_node:
                logger.error(f"Call {call_id}: IVR flow node '{current_menu_id}' not found. Exiting.")
                self._play_prompt(call_id, "We apologize, an error occurred. Goodbye.")
                break # Exit loop if menu node is not found

            # Check for time-based routing if configured for the current node
            if menu_node.get("type") == "time_based_routing":
                next_menu_id = self._apply_action(call_id, menu_node)
                if next_menu_id == "END":
                    break
                current_menu_id = next_menu_id
                continue # Skip menu handling and go to next iteration with new menu_id

            # Handle DTMF menu interaction
            selected_option_key = self._handle_menu(call_id, menu_node)

            if selected_option_key == "FALLBACK_ACTION":
                # Apply fallback logic defined in the menu_node
                fallback_action_data = menu_node.get("fallback", {"action": "repeat_menu"})
                next_menu_id = self._apply_action(call_id, fallback_action_data)
            else:
                # Apply action for the selected DTMF option
                action_data = menu_node["options"][selected_option_key]
                next_menu_id = self._apply_action(call_id, action_data)

            if next_menu_id == "END":
                break # Call transferred or ended
            elif next_menu_id == "current_menu":
                # Stay on the current menu (e.g., for repeat or announcement)
                pass
            else:
                current_menu_id = next_menu_id # Move to the next menu/state

        logger.info(f"Call {call_id}: IVR flow ended.")


# --- Plugin Deployment and Setup (Conceptual) ---

def setup_wazo_plugin():
    """
    Conceptual function for setting up the Wazo IVR plugin.
    This would involve:
    1. Creating necessary directories (e.g., CONFIG_DIR).
    2. Deploying the Python code to Wazo's plugin directory.
    3. Ensuring dependencies (like boto3 for Polly) are installed.
    4. Registering the plugin with Wazo's services (e.g., `calld` for event handling).
    5. Setting up API keys/credentials securely (e.g., AWS credentials for Polly).
    6. Potentially creating initial IVR flow configuration file.
    """
    logger.info("Running Wazo IVR Plugin setup script...")
    os.makedirs(CONFIG_DIR, exist_ok=True)
    logger.info(f"Ensured config directory exists: {CONFIG_DIR}")

    # Example: Create a dummy IVR flow config file if it doesn't exist
    if not os.path.exists(IVR_FLOW_CONFIG_FILE):
        default_flows = {
            "main_menu": {
                "prompt": "Welcome to our automated service. Press 1 for sales, 2 for support, or 9 to repeat this menu.",
                "options": {
                    "1": {"action": "route_to_queue", "target": "sales_queue"},
                    "2": {"action": "route_to_queue", "target": "support_queue"},
                    "9": {"action": "repeat_menu"}
                },
                "fallback": {"action": "repeat_menu"}
            },
            "sales_queue": {
                "prompt": "Connecting you to sales. Please hold.",
                "action": "transfer_to_extension",
                "target": "1001" # Example extension
            },
            "support_queue": {
                "prompt": "Connecting you to support. Your call is important to us.",
                "action": "transfer_to_extension",
                "target": "1002" # Example extension
            },
            "voicemail_menu": {
                "prompt": "Our offices are currently closed. Please leave a message after the tone.",
                "action": "transfer_to_extension",
                "target": "voicemail_ext" # Example voicemail extension
            }
        }
        with open(IVR_FLOW_CONFIG_FILE, 'w') as f:
            json.dump(default_flows, f, indent=4)
        logger.info(f"Created default IVR flow config at: {IVR_FLOW_CONFIG_FILE}")

    logger.info("Wazo IVR Plugin setup complete (conceptual).")

