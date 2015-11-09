"""
Mutalyzer config file

Specify the location of this file in the `MUTALYZER_SETTINGS` environment
variable.
"""


from __future__ import unicode_literals


EMAIL = 'mutalyzer@humgen.nl'

BATCH_NOTIFICATION_EMAIL = '{{ mutalyzer_batch_notification_email }}'

CACHE_DIR = '/opt/mutalyzer/cache'

LOG_FILE = '/opt/mutalyzer/log/mutalyzer.log'

EXTRACTOR_MAX_INPUT_LENGTH = {{ mutalyzer_extractor_max_input_length }}

REVERSE_PROXIED = True

DATABASE_URI = 'postgresql://mutalyzer:{{ mutalyzer_database_password }}@localhost/mutalyzer'

REDIS_URI = 'redis://localhost'

WEBSITE_ROOT_URL = 'https://{{ mutalyzer_server_name }}'

SOAP_WSDL_URL = 'https://{{ mutalyzer_server_name }}/services/?wsdl'

JSON_ROOT_URL = 'https://{{ mutalyzer_server_name }}/json'
{% if mutalyzer_piwik %}

PIWIK = True

PIWIK_BASE_URL = '{{ mutalyzer_piwik.base_url }}'

PIWIK_SITE_ID = {{ mutalyzer_piwik.site_id }}
{% endif %}
