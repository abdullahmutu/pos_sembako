from dotenv import load_dotenv

load_dotenv()  # muat variabel dari file .env sebelum app dibuat

from app import create_app  # noqa: E402  (import setelah load_dotenv sengaja)
from app.config import Config  # noqa: E402

app = create_app()

if __name__ == "__main__":
    # Untuk development saja. Untuk production pakai gunicorn (lihat README/Dockerfile).
    app.run(host="0.0.0.0", port=Config.PORT, debug=False)