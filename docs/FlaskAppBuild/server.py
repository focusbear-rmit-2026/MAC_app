from flask import Flask, send_from_directory
import os

static_folder_path = os.environ.get("STATIC_FOLDER_PATH", "static")
app = Flask(__name__, static_folder=static_folder_path)

@app.route("/")
def home():
    return send_from_directory(app.static_folder, "focus-block.html")

if __name__ == "__main__":
    # Port is chosen by the host app and passed via the PORT env var so it can fall
    # back to a free port when 50501 is already in use. Defaults to 50501 if unset.
    port = int(os.environ.get("PORT", "50501"))
    app.run(port=port)
