// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

//reordering function           
exports.order = functions.database.ref('/users/{uid}/{event_no}/name').onUpdate(event => {	
	return promise = event.data.ref.parent.once('value').then(snap => {
		var data = {}
		var counts = 1
		snap.forEach((childSnapshot) => {
			console.log(childSnapshot.key)
		})
		return null
	})
});