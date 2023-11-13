# Cloud Measurements

The app is a client, that sends requests to a server running on an **ESP32** controller. The server, in turn, is a simulator of some hypothetical medical device that allows to obtain several medical parameters. In addition to the measurement request, the application receives a set of measured parameters and visualizes them in the app. The application is first registered on the server by executing login and after by press the button "Request Measurement" send serquest to server start measurements.

## Toitware components

The application uses the **toit_api 1.0.0** library, which allows to log into the user's account registered on the toitware website, and also, using pubsub technology, subscribe to receive data from the **ESP32** via the **cloud:demo/ping** topic, and send commands to the server via the **cloud:demo/ping** channel.

Naturally, the toit- application must be installed on the ESP32. It's located in the measurements repository. The application is installed (via deployment) with the command **toit -d=nuc deploy measurements2.yaml** (on ESP32 **nuc**, you controller may have other names) and uninstalled with the command **toit device -d=nuc uninstall "Measurements"**.
