# Libraries loading
require "rubygems"
require "gosu"
require "google/cloud/firestore"
require_relative "firebase_connection.rb"
require_relative "draw.rb"
require_relative "user_button_handler.rb"

# Define global constants for color, screen size, character array and font
TOP_COLOR = Gosu::Color.new(0xFF_654ea3)
BOTTOM_COLOR = Gosu::Color.new(0xFF_eaafc8)
WIDTH_SCREEN = 800
HEIGHT_SCREEN = 750
CHARACTER = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

# Define enumerations for Z-Order
module ZOrder
    BACKGROUND, IMAGE, TEXT = *0..2
end

# Define enumerations for room status
# 0 = Room closed, 1 = Room opening
module RoomStatus
    CLOSED, OPENING = *0..1
end

# Define enumerations for game status
# 0 = Waiting screen, 1 = Question released, 2 = Question result
module GameStatus
    WAITING_SCREEN, QUESTION_RELEASED, QUESTION_RESULT = *0..2
end    

# Define Image class for drawing image
class Image
    attr_accessor :url, :position, :z_order, :gosu_image

    def initialize(url)
        @gosu_image = Gosu::Image.new(url)
    end
end

# Define Dim class for storing coordinates of interactable objects
class Dim
    attr_accessor :left_x, :top_y, :right_x, :bottom_y, :name, :text_contain
    
    def initialize(left_x, top_y, right_x, bottom_y, name)
        @left_x = left_x
        @top_y = top_y
        @right_x = right_x
        @bottom_y = bottom_y
        @name = name
    end
end

# Define User class for storing user's info
class User
    attr_accessor :username, :score
end

# Define Question class for storing question data
class Question
    attr_accessor :question, :answer_list, :correct_answer, :time_allowed, :question_number
end

# Display the result of a question
# Takes in a font to draw text, question_data to get information
# object_position for drawing answer list on the screen
def display_result(font, question_data, object_position)
    # If there is no question/no answers recorded, stop display to avoid errors
    if(question_data == nil || question_data.answer_list == nil || question_data.answer_list.length == 0)
        return
    end
    # Get the answer list and the correct answer
    answers = question_data.answer_list
    correct_answer = question_data.correct_answer
    index = 0
    # Loop for each answer in the array
    while (index < answers.length)
        # Get the position data of each answer button
        left_x = object_position[index].left_x
        top_y = object_position[index].top_y
        right_x = object_position[index].right_x
        bottom_y = object_position[index].bottom_y

        # Compare each answer index with the correct answer
        # if yes, set the color of answer button to green
        # if not, set the color of answer button to red
        if(correct_answer == index)
            color = Gosu::Color::GREEN
        else
            color = Gosu::Color.argb(0xff_f78888)
        end

        # Display each answer button on the screen
        display_possible_answer(font, answers[index], left_x, top_y, right_x, bottom_y, color)
        index = index + 1
    end
end

# Display answer list on the screen
# Takes in a font to draw text, question_data to get information
# object_position for drawing answer button
# submitted_answer for drawing answer button in violet color (represents for selected)
# locked for drawing answer button in gray (locked)/white (opened)
def display_possible_answers(font, question_data, object_position, submitted_answer, locked = false)
    # If there is no question/no answers recorded, stop display to avoid errors
    if(question_data == nil || question_data.answer_list == nil || question_data.answer_list.length == 0)
        return
    end
    # Get the answer list
    answers = question_data.answer_list
    index = 0
    # Loop for each answer in the array
    while (index < answers.length)
        # Get the position data of each answer button
        left_x = object_position[index].left_x
        top_y = object_position[index].top_y
        right_x = object_position[index].right_x
        bottom_y = object_position[index].bottom_y

        # Compare each answer index with the submitted answer
        # if yes, set the color of answer button to violet
        # if not, check if answers are locked. if yes, set the color to gray, if not set the color to white.
        if(submitted_answer == index)
            color = Gosu::Color.argb(0xff_c2bfff)
        elsif(locked)
            color = Gosu::Color::GRAY
        else
            color = Gosu::Color::WHITE
        end

        # Display each answer button on the screen
        display_possible_answer(font, answers[index], left_x, top_y, right_x, bottom_y, color)
        index = index + 1
    end
end

# Display a single answer button on the screen
# Takes in font to draw answer content (text)
# Takes in 4 coordinates to draw answer button and text
# Takes in color to set a color for an answer button
def display_possible_answer(font, text, left_x, top_y, right_x, bottom_y, color)
    draw_quad(left_x, top_y, color, right_x, top_y, color, left_x, bottom_y, color, right_x, bottom_y, color, ZOrder::IMAGE, mode=:default)
    font.draw_markup(text, left_x + 20, top_y + 20, ZOrder::TEXT, 1, 1, Gosu::Color::BLACK)
end

# Display question in text on the screen
def display_question(text)
    # Draw a text but it can break lines automatically
    # however, it returns an image
    question_text_image = draw_multiple_lines_of_text(text, 750, 40, 10, :left)
    # Draw question text image to the screen
    question_text_image.draw(20, 230, ZOrder::TEXT, 1, 1, color = 0xff_ffffff, mode=:default)
end

# Calculate the position of answer buttons on the screen
# Return an array of answer buttons' position
def get_answer_buttons(answers, left_x, top_y, button_distance, button_width, button_height)
    index = 0
    interactable_answers = Array.new()
    # Loop for each answer
    while (index < answers.length)
        # Calculate the width of the button (right_x coordinate)
        right_x = left_x + button_width
        # Calculate the height of the button (bottom_y coordinate)
        bottom_y = top_y + button_height
        # Create a Dim object store the coordinate of answer button
        answer_button_dim = Dim.new(left_x, top_y, right_x, bottom_y, "answer_#{index}")
        # Put the object to an array
        interactable_answers << answer_button_dim

        # After drawing a button, move the next starting top_y of a button
        # for a distance of button_distance
        top_y = top_y + button_distance
        index = index + 1
    end
    return interactable_answers
end

# Calculate remaining time for a question
# If the remaining time smaller than 0, return 0
def calculate_timer(start_time, current_time)
    remaining_time = start_time - current_time
    if(remaining_time < 0)
        timer = 0
    else
        timer = remaining_time
    end
    return timer
end

# Return a timer text for display in 2 digits
def display_timer(timer)
    # If the remaining time greater than or equal to 0, and lower than 10
    # add a "0" before the remaining time
    if(timer >= 0 and timer < 10)
        timer = "0" + timer.to_s
    # If the remaining time smaller than 0
    # return the timer with "00"
    elsif(timer < 0)
        timer = "00"
    end
    return timer
end

# Play a sound effect
# Takes in sound location
def play_sound(sound_location)
    song = Gosu::Song.new(sound_location)
    song.play(false)
end

class FunkyQuizPlayer < Gosu::Window
    def initialize()
        super WIDTH_SCREEN, HEIGHT_SCREEN
	    self.caption = "FunkyQuiz App - Player Screen"

        # Create a new User object to store user data
        @user_data = User.new()

        # Set the variable to their default values
        @question_data = nil
        @allow_answer = true
        @game_status = nil
        @submitted_answer = ""
        @server_timestamp = 0

        @logo_img = Gosu::Image.new("images/Logo.png")
        @user_icon = Gosu::Image.new("images/User.png")
        @score_icon = Gosu::Image.new("images/Score.png")
        @countdown_icon = Gosu::Image.new("images/Countdown.png")

        @correct_icon = Gosu::Image.new("images/Correct.png")
        @wrong_icon = Gosu::Image.new("images/Wrong.png")

        @user_info_font = Gosu::Font.new(30)
        @waiting_screen_font = Gosu::Font.new(53)
        @timer_font = Gosu::Font.new(45)
        @question_info_font = Gosu::Font.new(35)

        # Create a new Array that contains interactable objects
        @interactable_objects = Array.new()

        # Establish a connection with Firebase Cloud Firestore
        @server_connection = Google::Cloud::Firestore.new

        # Server event listener
        @game_listener = nil
        @query_listener = nil
    end

    # Subscribe and listen events from the Cloud Firestore servers
    def subscribe_event(username)
        @user_data.username = username

        # Make a query to the server to get user info
        user_query = @server_connection.col("users").doc(@user_data.username)
        # Listen to changes in that query and update new score
        @query_listener = user_query.listen do |snapshot|
            puts "New score: #{snapshot[:score]}"
            @user_data.score = snapshot[:score]
        end

        # Make a game query to the server to get user info
        game_query = @server_connection.col("game").doc("game_status")
        # Listen to changes in that query and update game status, question data, ...
        @game_listener = game_query.listen do |snapshot|

            # Update game status, room status and set the question data to nil
            @game_status = snapshot[:game_status]
            @question_data = nil
            room_status = snapshot[:room_status]

            # Waiting screen event handler
            if(@game_status == GameStatus::WAITING_SCREEN)
                puts "Waiting screen"
                # Set the question data to nil and interactable_objects array to an empty array
                @question_data = nil
                @interactable_objects = []
            end

            # Question released event handler
            if(@game_status == GameStatus::QUESTION_RELEASED)
                
                puts "Question released: #{snapshot[:question]}"
                # Allow user to select answer
                @allow_answer = true
                # Create a new Question object to store question data
                @question_data = Question.new()     
                @question_data.question = snapshot[:question]
                @question_data.question_number = snapshot[:question_number]
                @question_data.answer_list = snapshot[:answers]
                @question_data.correct_answer = snapshot[:correct_answer]
                @question_data.time_allowed = snapshot[:time_allowed]

                # Store the server timestamp,
                # which will be used for calculating timer
                @server_timestamp = snapshot[:server_timestamp]

                # Set the submitted answer to -1 (as new question has been released)
                @submitted_answer = -1

                # Get an array of answer buttons position (for drawing and clicked checking)
                @interactable_objects = get_answer_buttons(snapshot[:answers], 20, 385, 85, 760, 75)

                # Play a popup question sound
                play_sound("sounds/popup.ogg")
            end

            # Question result released event handler
            if(@game_status == GameStatus::QUESTION_RESULT)
                puts "Result released: #{snapshot[:question]}"
                # Prevent user from selecting answer
                @allow_answer = false

                # Get the answer statistic
                answer_count = snapshot[:answer_count]
                # Get the answer list
                answer_list = snapshot[:answers]
                index = 0
                # Loop for each answer and get the information of
                # how many players selected that answer
                # then re-assign the value in the answer_list for display
                while (index < answer_list.length)
                    answer_list[index] = "#{answer_list[index]} (#{answer_count[index]})"
                    index = index + 1
                end

                # Create a new Question object to store question data
                @question_data = Question.new()     
                @question_data.question = snapshot[:question]
                @question_data.question_number = snapshot[:question_number]
                @question_data.answer_list = answer_list
                @question_data.correct_answer = snapshot[:correct_answer]
                @question_data.time_allowed = snapshot[:time_allowed]

                # Get an array of answer buttons position (for drawing)
                @interactable_objects = get_answer_buttons(snapshot[:answers], 20, 385, 85, 760, 75)

                # Play sound if user answer correctly/incorrectly
                if(@submitted_answer == @question_data.correct_answer)
                    puts "Playing correct"
                    play_sound("sounds/correct.ogg")
                else
                    puts "Playing wrong"
                    play_sound("sounds/wrong.ogg")
                end

            end

            # Room closed event handling
            # Stop subscribe events from the server
            # End program
            if(room_status == RoomStatus::CLOSED)
                puts "Game closed"
                @query_listener.stop()
                @game_listener.stop()
                exit()
            end
        end

    end

    # Override this function for
    # exit the app when user closes the game window
    def close()
        exit()
    end

    def draw()
        # Draw the background
        draw_background()

        # Draw user's info
        draw_picture_with_file_descriptor(@user_icon, 20, 20, ZOrder::IMAGE, 0.25, 0.25)
        @user_info_font.draw_markup("<b>#{@user_data.username}</b>", 60, 20, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        draw_picture_with_file_descriptor(@score_icon, 665, 20, ZOrder::IMAGE, 0.25, 0.25)
        @user_info_font.draw_markup("<b>#{@user_data.score}</b>", 710, 20, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)

        # Draw waiting screen
        if(@game_status == GameStatus::WAITING_SCREEN)
            # Draw logo
            draw_picture_with_file_descriptor(@logo_img, 65, 200, ZOrder::IMAGE, 1, 1)
            # Draw the waiting text
            @waiting_screen_font.draw_markup("<b>Be patient!</b>", 270, 370, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
            @waiting_screen_font.draw_markup("Get ready for a new question!", 90, 430, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        end

        # Draw question and answers screen
        if(@game_status == GameStatus::QUESTION_RELEASED && @question_data != nil)
            # Get the remaining time of a question
            remaining_time = calculate_timer(@server_timestamp, Time.now.to_i)
            # Draw the countdown icon
            draw_picture_with_file_descriptor(@countdown_icon, 340, 65, ZOrder::IMAGE, 0.1, 0.1)
            # Draw question number text
            @question_info_font.draw_markup("<b>Question #{@question_data.question_number}</b>", 20, 180, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
            # Display question and check if there is time for users to answer
            # If yes, display unlocked answer buttons
            if(remaining_time > 0)
                display_question(@question_data.question)
                display_possible_answers(@question_info_font, @question_data, @interactable_objects, @submitted_answer, false)
            # If not, display locked answer buttons
            # and blocked user from answering
            else
                @allow_answer = false
                display_question(@question_data.question) 
                display_possible_answers(@question_info_font, @question_data, @interactable_objects, @submitted_answer, true)
            end
            # Display the timer on the screen
            timer = display_timer(remaining_time)
            @timer_font.draw_markup("<b>#{timer}</b>", 365, 90, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        end

        # Draw question result
        if(@game_status == GameStatus::QUESTION_RESULT && @question_data != nil)
            # Compare the submitted answer with the correct answer
            # If it is the same, draw the correct icon. If not, draw the wrong icon.
            if(@submitted_answer == @question_data.correct_answer)
                draw_picture_with_file_descriptor(@correct_icon, 340, 65, ZOrder::IMAGE, 0.1, 0.1)
            else
                draw_picture_with_file_descriptor(@wrong_icon, 340, 65, ZOrder::IMAGE, 0.1, 0.1)
            end
            # Draw question number text
            @question_info_font.draw_markup("<b>Question #{@question_data.question_number}</b>", 20, 180, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
            # Draw the question text
            display_question(@question_data.question)
            # Display answer list with correct/wrong color
            display_result(@question_info_font, @question_data, @interactable_objects)
        end
    end

    def needs_cursor?()
        true
    end

    def button_down(id)
        case id
        # Left-click event handling
        when Gosu::MsLeft
            # Check if user has clicked on any answer button
            answer_label_clicked = interactable_object_clicked(@interactable_objects)
            # Check if question has released, allow to answer state and user clicked on button
            if(@game_status == GameStatus::QUESTION_RELEASED && @allow_answer && answer_label_clicked)
                # Get the answer number
                answer_button_clicked_number = answer_label_clicked.split("_")[1].to_i()
                # Submit answer to the surver
                submit_status = submit_answer(@server_connection, @user_data.username, @question_data.question_number, answer_button_clicked_number)
                # If submit successfully,
                # set the submitted answer to user's answer
                # block user from sending answer again
                # play sound
                if(submit_status)
                    @submitted_answer = answer_button_clicked_number
                    @allow_answer = false
                    play_sound("sounds/answer_choose.ogg")
                end
            end
        end
    end
end

# Login screen
class FunkyQuizLogin < Gosu::Window
    def initialize()
        super WIDTH_SCREEN, HEIGHT_SCREEN
	    self.caption = "FunkyQuiz App - Login Screen"

        # Set the variables to their default value
        @username_input = ""
        @background_input = Gosu::Color::WHITE

        @allowed_input = false
        @temporarily_disabled = false

        @notification = ""

        @logo_img = Gosu::Image.new("images/Logo.png")
        @font = Gosu::Font.new(40)
        @font_smaller = Gosu::Font.new(25)

        # Establish a connection with Firebase Cloud Firestore
        @server_connection = Google::Cloud::Firestore.new
        
        # Create an interactable input box
        @interactable_input_box = create_new_interactable_shape(65, 400, 685, 100, "input")
        # Create an interactable "join_room" button
        @interactable_join_button = create_new_interactable_picture("images/Login_btn.png", 230, 550, 0.45, 0.45, ZOrder::IMAGE, "login_button")
    end

    # Change the color of the input box into yellow
    # if user hover their mouse on it
    def update()
        hover_input_box_check = area_clicked(@interactable_input_box.left_x, @interactable_input_box.top_y, @interactable_input_box.right_x, @interactable_input_box.bottom_y)
        if (hover_input_box_check)
            @background_input = Gosu::Color::YELLOW
        else
            @background_input = Gosu::Color::WHITE
        end
    end

    def draw()
        # Draw the gradient background
        draw_background()
        # Draw the logo on the screen
        draw_picture_with_file_descriptor(@logo_img, 65, 100, ZOrder::IMAGE, 1, 1)
        # Draw the input label
        @font.draw_markup("Username", 65, 350, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw the input box (interactable)
        draw_quad(@interactable_input_box.left_x, @interactable_input_box.top_y, @background_input, @interactable_input_box.right_x, @interactable_input_box.top_y, @background_input, @interactable_input_box.left_x, @interactable_input_box.bottom_y, @background_input, @interactable_input_box.right_x, @interactable_input_box.bottom_y, @background_input, ZOrder::IMAGE, mode=:default)
        # Draw the input value
        @font.draw_markup(@username_input, 80, 430, ZOrder::TEXT, 1, 1, Gosu::Color::BLACK)
        # Draw the join button (interactable)
        draw_image(@interactable_join_button)
        # Draw the notification
        @font_smaller.draw_markup(@notification, 65, 700, ZOrder::TEXT, 1, 1, Gosu::Color::BLACK)
    end

    def needs_cursor?()
        true
    end

    def button_down(id)
        # Get the username length
        username_length = @username_input.length
        # Keyboard handler - For A-Z characters
        if (@allowed_input && !@temporarily_disabled && username_length < 15 && id >= 4 && id <= 29)
            @username_input = @username_input + CHARACTER[id - 4]
        end
        # Keyboard handler - For 1 - 9 characters
        if (@allowed_input && !@temporarily_disabled && username_length < 15 && id >= 89 && id <= 97)
            @username_input = @username_input + (id - 88).to_s
        end
        # Keyboard handler - For 0 character
        if (@allowed_input && !@temporarily_disabled && username_length < 15 && id == 98)
            @username_input = @username_input + "0"
        end

        case id
        # Left mouse click event handler
        when Gosu::MsLeft
            # Check if user has clicked on join button
            join_button_clicked = area_clicked(@interactable_join_button.position.left_x, @interactable_join_button.position.top_y, @interactable_join_button.position.right_x, @interactable_join_button.position.bottom_y)
            
            # Check if user has clicked on input button, if yes, unlocked the input box
            # User can only type when the input box is unlocked
            @allowed_input = area_clicked(@interactable_input_box.left_x, @interactable_input_box.top_y, @interactable_input_box.right_x, @interactable_input_box.bottom_y)

            if(join_button_clicked && username_length == 0)
                @notification = "The username length MUST BETWEEN 1-15 characters."
            end

            # If user clicked the button
            # And the app are not making a connection with the server
            # And the username length greater than 0 and smaller than 15
            # Then check the game room status
            if(join_button_clicked && !@temporarily_disabled && username_length > 0 && username_length < 15)
                @notification = "Connecting to game server. Please wait..."
                @temporarily_disabled = true

                room_status = check_room_status(@server_connection)
                # If the game room is opened,
                # change to the game window, update username
                # and subscribe to events from the server
                if(room_status)
                    @notification = "Game room is open!"
                    login_status = login(@server_connection, @username_input)

                    if(login_status)
                        new_window = FunkyQuizPlayer.new
                        new_window.subscribe_event(@username_input)
                        new_window.show
                    end
                else
                # If the game room is closed,
                # tell user and unlocked the button/input
                    @notification = "The game has begun! You cannot join the game."
                    @temporarily_disabled = false
                end
            end
        # Backspace button event handler
        when Gosu::KB_BACKSPACE
            # If input is unlocked and username length is greater than 0
            # then delete the last character of the username
            if(@allowed_input && username_length > 0 && !@temporarily_disabled)
                @username_input = @username_input.chop()
            end
        end
    end

end

FunkyQuizLogin.new.show if __FILE__ == $0