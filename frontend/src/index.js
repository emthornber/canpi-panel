// Start the Elm application
import { Elm } from "./Main.elm";
var app = Elm.Main.init({ node: document.getElementById('panel') });

// Create your websocket
var socket = new WebSocket('wss://echo.websocket.org');

// When a comand goes to the 'sendMessage' port, we pass the message
// along to the WebSocket.
app.ports.sendMessage.subscribe(function(message) {
	socket.send(message);
});

// When a message comes into our WebSocket, we pass the message along
// to the 'messageReceiver' port.
socket.addEventListener("message", function(event) {
	app.ports.messageReceiver.send(event.data);
});
