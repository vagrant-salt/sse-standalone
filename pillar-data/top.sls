{# Pillar Top File #}

{# Define SSE Servers #}
{% load_yaml as sse_servers %}
  - sse.test.local
{% endload %}

base:

  {# Assign Pillar Data to SSE Servers #}
  {% for server in sse_servers %}
  '{{ server }}':
    - sse
  {% endfor %}