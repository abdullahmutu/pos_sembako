import logging
from flask import Flask
from flask_cors import CORS

from app.config import Config
from app.services.trends_service import TrendsService
from app.middleware.auth import register_auth_middleware
from app.routes.health import health_bp
from app.routes.trends import trends_bp


def create_app(config_class=Config) -> Flask:
    logging.basicConfig(level=logging.INFO)

    app = Flask(__name__)
    app.config.from_object(config_class)

    # Izinkan diakses dari domain lain (mis. Laravel di server/domain berbeda).
    # Untuk keamanan tambahan, batasi origins sesuai domain Laravel Anda,
    # contoh: CORS(app, origins=["https://app-laravel-anda.com"])
    CORS(app)

    # Service disimpan di app.extensions supaya bisa diakses dari route
    # tanpa membuat instance baru setiap request.
    app.extensions["trends_service"] = TrendsService(config_class)

    register_auth_middleware(app)

    app.register_blueprint(health_bp)
    app.register_blueprint(trends_bp)

    return app