# CDF Platform Plugins

Custom plugins for the Call Data Foundation (CDF) platform, extending Wazo UC capabilities.

## Plugin Directory

| Plugin | Status | Description |
|--------|--------|-------------|
| [call-distribution](./call-distribution/) | ~70% | Full ACD (Automatic Call Distribution) system with queue management, agent routing, supervisor tools, WebSocket real-time updates, and reporting APIs |
| [call-survey](./call-survey/) | ~40% | Post-call survey system with Asterisk dialplan integration and webhook support |
| [ivr-system](./ivr-system/) | ~70% | Multi-level IVR with DTMF menus, TTS support (Amazon Polly/local), business hours routing |
| [ivr-boilerplate](./ivr-boilerplate/) | ~20% | Basic IVR boilerplate with mock Wazo clients for development |
| [uc-custom](./uc-custom/) | ~30% | Custom IVR plugin with demo SIP server integration |

## Installation

Plugins are installed on the CDF platform server via Ansible. Each plugin has its own installation method:

### call-distribution / ivr-system
```bash
cd /path/to/plugin
sudo ./install.sh
```

### call-survey
```bash
cd /path/to/plugin
pip install -e .
```

### ivr-boilerplate / uc-custom
Copy files to `/var/lib/wazo-provd/plugins/` and configure Asterisk dialplan.

## Development

Each plugin is maintained in its own directory with clear separation:

```
plugins/
├── call-distribution/    # ACD/queue management
├── call-survey/          # Post-call surveys
├── ivr-system/           # IVR flow engine
├── ivr-boilerplate/      # Development template
└── uc-custom/            # Custom extensions
```

## Requirements

- CDF Platform (Wazo UC) v22.0+
- Python 3.8+
- Asterisk (included with Wazo)

## Plugin-Specific Dependencies

### call-distribution / ivr-system
- boto3 (for Amazon Polly TTS)
- flask, requests, pyyaml, jinja2
- sox, flite, espeak, festival (for local TTS)

### call-survey
- See `call-survey/requirements.txt`

## License

MIT License - See individual plugin LICENSE files for details.
