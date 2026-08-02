from flask import Blueprint, request, jsonify, current_app
from app.services.trends_service import TrendsService

trends_bp = Blueprint("trends", __name__)


@trends_bp.route("/trend-score", methods=["GET"])
def trend_score():
    """
    Ambil skor interest (0-100, relatif) untuk sekumpulan keyword.

    Contoh:
      GET /trend-score?keywords=sepatu lari,jam tangan,tas kulit&geo=ID
    """
    raw_keywords = request.args.get("keywords", "")
    geo = request.args.get("geo", current_app.config["DEFAULT_GEO"])
    timeframe = request.args.get("timeframe", current_app.config["DEFAULT_TIMEFRAME"])

    keywords = [k.strip() for k in raw_keywords.split(",") if k.strip()]
    if not keywords:
        return jsonify({"error": "parameter 'keywords' wajib diisi, pisahkan dengan koma"}), 400

    service: TrendsService = current_app.extensions["trends_service"]
    scores = service.fetch_scores(keywords, geo=geo, timeframe=timeframe)

    return jsonify({"geo": geo, "timeframe": timeframe, "scores": scores})


@trends_bp.route("/trending-now", methods=["GET"])
def trending_now():
    """
    Ambil daftar topik yang sedang trending saat ini, tanpa keyword awal.
    Sumber: RSS feed resmi Google Trends.

    Contoh:
      GET /trending-now?geo=ID&hours=48&limit=20
    """
    geo = request.args.get("geo", current_app.config["DEFAULT_GEO"])
    hours = int(request.args.get("hours", 48))
    limit = int(request.args.get("limit", 20))

    service: TrendsService = current_app.extensions["trends_service"]
    results = service.trending_now(geo=geo, hours=hours, limit=limit)

    if not results:
        return jsonify({"geo": geo, "results": [], "error": "gagal mengambil trending searches"}), 502

    return jsonify({"geo": geo, "results": results})