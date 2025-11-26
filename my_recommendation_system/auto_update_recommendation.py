import os
import sys
import time
import logging
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

# ==================== CẤU HÌNH ====================
DB_PATH = "recommendation1.sqlite3"          # Đường dẫn DB của bạn
LOG_DIR = Path("logs")
LOG_DIR.mkdir(exist_ok=True)

LOCK_FILE = Path("auto_update.lock")
MIN_INTERVAL_HOURS = 1        # Tối thiểu bao lâu chạy lại 1 lần (tránh chạy liên tục)
MAX_INTERVAL_HOURS = 6        # Nếu quá lâu thì vẫn chạy (đề phòng missed schedule)

# ================================================

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-8s | %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "auto_update.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("AutoUpdateRec")

# ==================== KHÓA CHỐNG CHỒNG ====================
def acquire_lock():
    if LOCK_FILE.exists():
        # Kiểm tra thời gian lock file
        mtime = datetime.fromtimestamp(LOCK_FILE.stat().st_mtime)
        if datetime.now() - mtime < timedelta(hours=8):  # quá 8 tiếng coi như crash
            logger.error("Một tiến trình khác đang chạy hoặc bị crash. Thoát.")
            return False
        else:
            logger.warning("Lock file cũ, xóa và tiếp tục...")
            LOCK_FILE.unlink(missing_ok=True)

    try:
        LOCK_FILE.write_text(datetime.now().isoformat())
        return True
    except Exception as e:
        logger.error(f"Không tạo được lock file: {e}")
        return False

def release_lock():
    if LOCK_FILE.exists():
        LOCK_FILE.unlink(missing_ok=True)

# ==================== KIỂM TRA ĐÃ CHẠY GẦN ĐÂY CHƯA ====================
def should_run():
    if not Path(DB_PATH).exists():
        logger.error(f"Không tìm thấy database: {DB_PATH}")
        return False

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Kiểm tra lần chạy cuối của rating
    cur.execute("SELECT MAX(created) FROM analytics_rating WHERE rating_type = 'implicit'")
    last_rating = cur.fetchone()[0]

    # Kiểm tra lần chạy cuối của similarity
    cur.execute("SELECT MAX(created) FROM similarity")
    last_sim = cur.fetchone()[0]

    conn.close()

    now = datetime.now()

    def parse_dt(s):
        if not s:
            return None
        try:
            return datetime.fromisoformat(s)
        except:
            return None

    last_rating_dt = parse_dt(last_rating)
    last_sim_dt = parse_dt(last_sim)
    last_any = max(filter(None, [last_rating_dt, last_sim_dt]), default=None)

    if last_any:
        hours_since_last = (now - last_any).total_seconds() / 3600
        if hours_since_last < MIN_INTERVAL_HOURS:
            logger.info(f"Chỉ mới chạy {hours_since_last:.1f} giờ trước → bỏ qua lần này.")
            return False
        if hours_since_last > MAX_INTERVAL_HOURS * 2:
            logger.warning(f"Lâu quá không chạy ({hours_since_last:.1f} giờ), sẽ chạy lại ngay!")
    else:
        logger.info("Chưa từng chạy → bắt đầu tính toán.")

    return True

# ==================== CHẠY CÁC HÀM TÍNH TOÁN ====================
def run_rating_calculation():
    logger.info("Bắt đầu tính toán implicit ratings...")
    from implicit_ratings_calculator import main as run_rating  # giả sử file của bạn tên là implicit_rating_script.py
    
    try:
        run_rating()
        logger.info("Tính rating hoàn tất.")
    except Exception as e:
        logger.exception(f"Lỗi khi tính rating: {e}")
        raise

def run_similarity_calculation():
    logger.info("Bắt đầu tính độ tương đồng sản phẩm...")
    from item_similarity_calculator import build_item_similarity

    try:
        # Thay đổi tham số theo ý bạn (ở đây dùng giá trị tốt cho production)
        build_item_similarity(min_overlap=5, min_sim=0.25)
        logger.info("Tính similarity hoàn tất.")
    except Exception as e:
        logger.exception(f"Lỗi khi tính similarity: {e}")
        raise

# ==================== MAIN ====================
def main():
    start_time = time.time()
    logger.info("=== BẮT ĐẦU AUTO UPDATE RECOMMENDATION ===")

    if not acquire_lock():
        sys.exit(1)

    try:
        if not should_run():
            logger.info("Không cần chạy lúc này.")
            return

        # GỌI 2 FILE CŨ CỦA BẠN (có thể import hoặc dán trực tiếp)
        run_rating_calculation()
        run_similarity_calculation()

        elapsed = time.time() - start_time
        logger.info(f"HOÀN TẤT toàn bộ trong {elapsed:.1f} giây.")

    except Exception as e:
        logger.exception(f"Job thất bại: {e}")
        sys.exit(1)
    finally:
        release_lock()

if __name__ == "__main__":
    main()