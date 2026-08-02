import os


class Config:
    """Konfigurasi aplikasi, diambil dari environment variable (.env)."""

    # Kunci untuk proteksi endpoint (header X-API-Key). Kosongkan untuk
    # menonaktifkan proteksi (TIDAK disarankan untuk production).
    API_KEY = os.getenv("API_KEY", "")

    # Default negara & timeframe untuk request ke Google Trends
    DEFAULT_GEO = os.getenv("DEFAULT_GEO", "ID")
    DEFAULT_PN = os.getenv("DEFAULT_PN", "indonesia")  # nama negara untuk trending_searches
    DEFAULT_TIMEFRAME = os.getenv("DEFAULT_TIMEFRAME", "today 3-m")
    DEFAULT_HL = os.getenv("DEFAULT_HL", "id-ID")
    DEFAULT_TZ = int(os.getenv("DEFAULT_TZ", "420"))  # menit offset, 420 = WIB (UTC+7)

    # Batas & retry saat memanggil Google Trends
    BATCH_SIZE = int(os.getenv("BATCH_SIZE", "5"))
    RETRY_ATTEMPTS = int(os.getenv("RETRY_ATTEMPTS", "3"))
    RETRY_DELAY_SEC = int(os.getenv("RETRY_DELAY_SEC", "5"))

    # Port aplikasi (dipakai saat run lokal via run.py)
    PORT = int(os.getenv("PORT", "5000"))