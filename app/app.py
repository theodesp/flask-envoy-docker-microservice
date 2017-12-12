from flask import Flask
import settings


def init():
    """ Create a Flask app. """
    server = Flask(__name__)

    return server


app = init()


@app.route('/')
def index():
    return 'My awesome micro-service'


if __name__ == "__main__":
    app.run(
        host=settings.API_BIND_HOST,
        port=settings.API_BIND_PORT,
        debug=settings.DEBUG)
