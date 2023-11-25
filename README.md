
# FunkyQuiz - Live Trivia Game Show on Ruby

This custom program is a part of COS10009 - Introduction to Programming D/HD submission, written in Ruby programming language.

FunkyQuiz app allows you to organize a simple live trivia game show (Kahoot, HQ Trivia, etc.) for your family and friends, your class, or even your company.

This program has two main parts:
- Player app: join the game room, listen events from server and answer questions
- Admin app: control the game room and process data, send data to server
## 👨‍💻 Author

- Author: Nguyen Anh Quan - 104850254, from Swinburne University of Technology.
- If you have any troubles when running/editing the code, or there are bugs/errors, you can contact me via email: [Personal Email](kwankwan.study@gmail.com) or [School Email](104850254@student.swin.edu.au), or via [Facebook](https://www.facebook.com/kwankwan2005/).


## 😇 Libraries and code used
- GOSU library (for drawing GUI): [Documentation](https://github.com/gosu/gosu)
- google-cloud-firestore library (for online database and real-time listeners): [Documentation](https://cloud.google.com/ruby/docs/reference/google-cloud-firestore/latest)
- Bubble Sort algorithm in Ruby (with some modifications) of COS10009 - Ed Lessons, "Week 9 - Sorting, Complexity and Recursion" lecture, "An Example - Sorting" slide: [Code](https://edstem.org/au/courses/13602/lessons/41250/slides/285957). 
Reference: 

*Swinburne University of Technology (n.d.). Week 9 - Sorting, Complexity and Recursion, ‘An Example - Sorting’ slide. [online] COS10009 - Ed Lessons. Available at: https://edstem.org/au/courses/13602/lessons/41250/slides/285957 [Accessed 24 Nov. 2023].*
## 💻 Getting Started

**IMPORTANT:** To run this program, you **MUST** install the `google-cloud-firestore`  gem and `Gosu` library.

You can install these gems by typing  commands on the terminal: 
- `gem install google-cloud-firestore`
- `gem install gosu`
    
## ✨ Usage

### For players
Run the Player app by typing this command on the terminal: `ruby quiz_app_player.rb`.

A login screen will be displayed.

![FunkyQuiz - Player Login Screen](https://i.imgur.com/hiMsfSJ.png)

**Press the white input box** to type in your username. The username length must be from **1 - 15 characters**, and accepts **A-Z characters and 0-9 numbers** only. 

Then press the **Login** button to join the game room. The app will establish a connection with the Firebase Cloud Firestore server and check the room status.

If the game room has **not opened** yet, you will receive a notification.
If the game room has **opened**, you are all set for playing!

Below is the waiting screen. You do not need to do anything, just wait for a new question to be released!
- On the left side of the screen is **your username**. 
- On the right side of the screen is your **current scores** (in real-time).

![FunkyQuiz - Waiting Screen](https://i.imgur.com/7FwgHmH.png)

When a question is released, you will see the timer, question content and possible answers. To answer a question, **simply press on the answer that you think it is correct**. The selected answer button will be changed to another color, which means **your answer has been submitted.**

If you have already participated in a question, you will **NOT** be able to submit another answer. You will also **NOT** be able to answer when the time runs out, so act fast! The faster you answer, the more points you get.

![FunkyQuiz - Question Screen](https://i.imgur.com/7hs9DB3.png)

After a question has been finished, it will take some time to process your answer and calculate the score. Keep waiting and you will get your result soon. You will know whether your answer is correct or not, how many people shares the same opinion with you and so on.

![FunkyQuiz - Answer Stats Screen](https://i.imgur.com/lNXoFER.png)

When the game ends, you will be automatically kicked out from the room and the app will stopped working.

### For hosts
Run the Admin app by typing this command on the terminal: `ruby quiz_app_admin.rb`.

A window will be shown here:
![FunkyQuiz - Admin Screen](https://i.imgur.com/AYxwfpI.png)

There are three main areas in the Admin screen:
- Question Manager
- Room Manager
- Game Manager

*Question Manager*

- Press the **Load Question From File** button to get the question list, from file `question.txt`. You can change the `question.txt` file to customize questions.

![FunkyQuiz - question.txt](https://i.imgur.com/xmTseWD.png)

- The first line: number of questions.
- A question contains five parts: question content (1 line), allowed time to answer (1 line), number of answers (1 line), possible answers (1 answer = 1 line) and the correct answer (0 - A, 1 - B, 2 - C, 3 - D, 1 line). The program supports a question with **2, 3, or 4 answers**.

- When you press the **Load Question From File** button, the program will automatically read `question.txt` file and update the number of questions to the screen.

*Room Manager*

- Press the **Open Room** button to open a game room. Players will be able to join.
- Press the **Close Room** button to close a game room. Players will not be able to join, or will be kicked if they are in the room.
- Press the **Delete All Users** button to delete all players' data from the game room.

*Game Manager*

- Press the **Waiting Screen** button to change user's screen to Waiting Screen.
- Press the **Result Screen** button to show the statistics.
- Press the **Prev/Next** button to change the current question index. The program will release a new question or process the answer based on the current question index.
- Press the **Release Question** button to release a new question.
- Press the **Reset All Answers** button to delete all user' submitted answers of a question.
- Press the **Process Answers** button to process answers and calculate the score of a question.
- Press the **Update Leaderboard** button to display current leaderboard (maximum 5 players) on the screen.

### For developers
You can change the default Firebase Cloud Firestore config to your own config by following these steps:

*I. Setup the Service Account file*
- **Step 1**: Create a Firebase account. You can access via [this link](https://console.firebase.google.com/).
- **Step 2**: Create a new project. Activate the Firestore Database feature by pressing **Create a database** button. Select the location of the database, then set the **test mode** rules for our database. Create `game` collection as the following:
![FunkyQuiz - Game Collection](https://i.imgur.com/8XTpikd.png)
- **Step 3**: Go to [Google Cloud Console](https://console.cloud.google.com/apis/dashboard), select your project and go to **APIs & Services** menu. 
- **Step 4**: Select **Credentials**. Find the **Create Credentials** button and select **Service account**. Enter the service account name, ID, description, then press **Done**.
- **Step 5**: Select your **service account**, go to **Keys** tab and press **Add key > Create new key**, then choose **JSON key type** and press **Create**. A JSON file will be downloaded to your computer.

*II. Change the environment variables in the config file*
- **Step 6**: Move your JSON file that you got at the **Step 5** to the code folder.
- **Step 7**: Use any text editor and edit `firebase_connection.rb` file. You will see the following lines of code. Edit your Firebase project ID *(Firebase > Project Settings > Project ID)* at *EDIT YOUR PROJECT ID HERE*. Then edit your location to JSON key file at *EDIT YOUR JSON'S KEY FILE LOCATION*.

![FunkyQuiz - Edit Code](https://i.imgur.com/J7uTpkr.png)

And you're all set for hosting the game on your own server!
