from flask import request, jsonify, current_app

# Endpoint yang tidak perlu API key (health check harus tetap bisa diakses
# monitoring/load balancer tanpa autentikasi)
EXEMPT_PATHS = {"/health"}


def register_auth_middleware(app):
    @app.before_request
    def check_api_key():
        if request.path in EXEMPT_PATHS:
            return None

        api_key = current_app.config.get("API_KEY", "")

        # Kalau API_KEY tidak diset di environment, proteksi dianggap nonaktif.
        # Cocok untuk development, TIDAK disarankan untuk production.
        if not api_key:
            return None

        provided = request.headers.get("X-API-Key", "")
        if provided != api_key:
            return jsonify({"error": "unauthorized"}), 401

        return None