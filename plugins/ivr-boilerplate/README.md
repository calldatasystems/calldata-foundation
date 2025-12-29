# **Wazo IVR Plugin**

## **Project Overview**

This project provides boilerplate Python code for a custom Interactive Voice Response (IVR) plugin designed for the Wazo Platform. The goal of this plugin is to transform existing Wazo UC installations into powerful, enterprise-grade call centers by offering dynamic IVR flow management and integration with various voice backends.

This repository serves as a starting point for developers to build a modular Python plugin that fully integrates with Wazo's calld, confd, and dird APIs.

## **Key Features**

* **Dynamic IVR Flow Definitions:** IVR flows can be defined via a configurable JSON file, allowing for flexible and easily modifiable call routing logic without requiring code changes. The architecture supports future integration with a REST API for dynamic updates.  
* **Selectable Voice Backends:**  
  * **Amazon Polly:** Integration with Amazon Polly for high-quality, natural-sounding Text-to-Speech (TTS). (Requires AWS SDK boto3).  
  * **Asterisk Native TTS:** Support for Asterisk's built-in TTS capabilities (e.g., Festival, gTTS) via Wazo's calld interface.  
  * **Pre-generated Audio Support:** Designed to handle playing pre-recorded audio files for prompts to optimize performance and cost.  
* **Multi-level DTMF Menus:** Enables callers to navigate through complex IVR trees using DTMF (Dual-Tone Multi-Frequency) inputs.  
* **Time-based Routing:** Allows for call routing decisions based on time of day, day of week, or specific dates (e.g., business hours vs. after-hours routing).  
* **Queue/Agent Routing:** Directs calls to specific call queues or individual agents based on IVR selections, leveraging Wazo's confd for queue and agent status.  
* **Language Selection:** Provides options for callers to choose their preferred language for IVR prompts, influencing TTS voice or pre-generated audio.  
* **Call Recording Triggers:** Ability to dynamically start or stop call recording based on IVR flow logic or caller input, utilizing Wazo's calld.  
* **Robust Fallback Options:** Configurable fallback actions for invalid DTMF input or other unexpected scenarios, ensuring a graceful user experience.

## **Architecture**

The plugin is structured in Python and interacts with Wazo's core services:

* **calld (Call Daemon):** Handles real-time call control, including playing audio, collecting DTMF digits, bridging calls, and managing call recording.  
* **confd (Configuration Daemon):** Used for retrieving system configuration, such as details about call queues, agents, and extensions.  
* **dird (Directory Daemon):** Provides access to user and extension details within the Wazo directory.

The current implementation uses mock clients for calld, confd, and dird for demonstration and development purposes. These mocks should be replaced with actual Wazo SDK or direct API calls in a production environment.

## **Getting Started**

### **Prerequisites**

* Python 3.x  
* Wazo Platform (version 22+ recommended)  
* (For Amazon Polly) AWS credentials configured and boto3 Python library (pip install boto3)

### **Installation (Conceptual)**

The setup\_wazo\_plugin function in the boilerplate code outlines the conceptual steps for deployment:

1. **Create Configuration Directory:** Ensures /etc/wazo-ivr-plugin (or the path specified by WAZO\_IVR\_CONFIG\_DIR) exists.  
2. **Deploy Code:** Copy the plugin Python files to the appropriate Wazo plugin directory (specific to your Wazo installation).  
3. **Install Dependencies:** Ensure all Python dependencies (e.g., boto3 for Amazon Polly) are installed in the Wazo environment.  
4. **Wazo Integration:** Register the plugin with Wazo services. This typically involves configuring calld to hand off calls to the plugin for IVR processing.  
5. **API Keys/Credentials:** Securely configure any external API keys (e.g., AWS credentials for Amazon Polly).  
6. **Initial IVR Flow:** A default ivr\_flows.json file is created if one doesn't exist, providing a basic IVR structure.

### **Configuration**

The IVR flow is defined in a JSON file, by default located at /etc/wazo-ivr-plugin/ivr\_flows.json. An example structure is provided in the setup\_wazo\_plugin function. You can modify this file to define your desired IVR menus, options, and actions.

**Example ivr\_flows.json structure:**

{  
    "main\_menu": {  
        "prompt": "Welcome to our automated service. Press 1 for sales, 2 for support, or 9 to repeat this menu.",  
        "options": {  
            "1": {"action": "route\_to\_queue", "target": "sales\_queue"},  
            "2": {"action": "route\_to\_queue", "target": "support\_queue"},  
            "9": {"action": "repeat\_menu"}  
        },  
        "fallback": {"action": "repeat\_menu"}  
    },  
    "sales\_queue": {  
        "prompt": "Connecting you to sales. Please hold.",  
        "action": "transfer\_to\_extension",  
        "target": "1001"  
    },  
    "support\_queue": {  
        "prompt": "Connecting you to support. Your call is important to us.",  
        "action": "transfer\_to\_extension",  
        "target": "1002"  
    },  
    "voicemail\_menu": {  
        "prompt": "Our offices are currently closed. Please leave a message after the tone.",  
        "action": "transfer\_to\_extension",  
        "target": "voicemail\_ext"  
    }  
}

## **Usage**

Once deployed and configured, the plugin will intercept incoming calls configured to use its IVR services. The handle\_incoming\_call method is the entry point for processing a call through the defined IVR flow.

## **Development Notes**

* **Replace Mocks:** The MockWazoCalldClient, MockWazoConfdClient, and MockWazoDirdClient classes are placeholders. In a production environment, you will need to replace these with actual API calls to your Wazo instance, likely using requests or a Wazo Python SDK if available.  
* **Error Handling:** Enhance error handling throughout the plugin to gracefully manage API failures, invalid configurations, and unexpected call states.  
* **Asynchronous Operations:** For high-performance call centers, consider implementing asynchronous API calls to Wazo services to prevent blocking the IVR flow.  
* **Security:** Ensure secure handling of API keys and credentials, potentially using environment variables or a dedicated secrets management system.  
* **Pre-generated Audio:** Implement logic to check for and play pre-generated audio files before resorting to TTS, which can improve latency and reduce costs.

## **Contributing**

Contributions are welcome\! Please feel free to fork the repository, make improvements, and submit pull requests.

## **License**

(Choose your preferred license here, e.g., MIT, Apache 2.0)

## **Contact**

For questions or support, please open an issue in this repository.