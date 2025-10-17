# situp

SitUp is a posture monitoring application that uses your camera and a backend computer vision model to analyze posture in real time. 
It integrates with an automated standing desk, adjusting desk height dynamically to optimize your posture without feeling disruptive.
I think possible ideas we could explore are: detailed session analysis; saving historical session results; interactive graph that shows the change in posture score across a single session; gamification such as leaderboard, posture score over time, badges, etc. for better user experience. Of course this depends on the time we have (at the moment uncertain). 


## Getting Started

Make sure you have the Flutter SDK installed. SitUp works with either a mobile camera or a webcam. However, this app was originally designed with a mobile camera in mind, because it forces you to forgo a work/study distraction.

After cloning the repository, fetch Flutter dependencies with "flutter pub get". 
Run for Android/iOS with "flutter run". Run for web with "flutter run -d chrome".