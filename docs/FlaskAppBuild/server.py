from flask import Flask, send_from_directory
import os

static_folder_path = os.environ.get("STATIC_FOLDER_PATH", "static")
app = Flask(__name__, static_folder=static_folder_path)

@app.route("/")
def home():
    return send_from_directory(app.static_folder, "focus-block.html")

if __name__ == "__main__":
    app.run(port=50501)
