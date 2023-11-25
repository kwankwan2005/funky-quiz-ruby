# Libraries loading
require "rubygems"
require "gosu"
require "google/cloud/firestore"
require_relative "firebase_connection.rb"
require_relative "draw.rb"
require_relative "file_handling.rb"
require_relative "user_button_handler.rb"

# Define global constants for color, screen size, character array and font
TOP_COLOR = Gosu::Color.new(0xFF_654ea3)
BOTTOM_COLOR = Gosu::Color.new(0xFF_eaafc8)
WIDTH_SCREEN = 800
HEIGHT_SCREEN = 750
CHARACTER = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
QUESTION_FILE_NAME = "question.txt"

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

# Draw leaderboard with limit
def draw_leaderboard(font, leaderboard, limit)
    index = 0
    left_x = 350
    top_y = 570
    # If limit greater than the length of leaderboard, set the limit equal to number of users
    if(limit > leaderboard.length)
        limit = leaderboard.length
    end
    # Loop for each user to draw a leaderboard text on the screen
    # Stop until drew text reached the limit
    while (index < limit)
        color = Gosu::Color::WHITE
        index_shown = index + 1
        font.draw_markup("<b>#{index_shown}. </b> #{leaderboard[index].username} (#{leaderboard[index].score} points)", left_x, top_y, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        index = index + 1
        top_y = top_y + 30
    end
end

# Draw interactable shapes on the screen 
def draw_interactable_objects(font, interactable_objects)
    index = 0
    while (index < interactable_objects.length)
        # Get the position data of each button
        left_x = interactable_objects[index].left_x
        top_y = interactable_objects[index].top_y
        right_x = interactable_objects[index].right_x
        bottom_y = interactable_objects[index].bottom_y

        color = Gosu::Color::BLACK
        
        # Draw each button with text contain in it
        draw_quad(left_x, top_y, color, right_x, top_y, color, left_x, bottom_y, color, right_x, bottom_y, color, ZOrder::IMAGE, mode=:default)
        font.draw_markup(interactable_objects[index].text_contain, left_x + 20, top_y + 20, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        
        index = index + 1
    end
end

class FunkyQuizAdmin < Gosu::Window
    def initialize()
        super WIDTH_SCREEN, HEIGHT_SCREEN
	    self.caption = "FunkyQuiz App - Admin Screen"

        # Establish a connection with the server
        @server_connection = Google::Cloud::Firestore.new

        # Set variables to their default values
        @current_question_for_displaying = 0
        @interactable_objects = []
        @question = []
        @leaderboard = []
        @notification = ""
        @font = Gosu::Font.new(25)

        # Create a button for the "Question Manager" part
        @interactable_objects << create_new_interactable_shape(40, 90, 290, 65, "load_question_from_file", "Load Question From File")
        # Create buttons for the "Room Manager" part
        @interactable_objects << create_new_interactable_shape(40, 210, 160, 65, "open_room", "Open Room")
        @interactable_objects << create_new_interactable_shape(210, 210, 170, 65, "close_room", "Close Room")
        @interactable_objects << create_new_interactable_shape(390, 210, 200, 65, "delete_all_user", "Delete All Users")
        # Create buttons for the "Game Manager" part
        @interactable_objects << create_new_interactable_shape(40, 340, 180, 65, "waiting_screen", "Waiting Screen")
        @interactable_objects << create_new_interactable_shape(230, 340, 180, 65, "result_screen", "Result Screen")
        # Create buttons for the selecting question
        @interactable_objects << create_new_interactable_shape(500, 410, 90, 65, "prev_question", "Prev")
        @interactable_objects << create_new_interactable_shape(600, 410, 90, 65, "next_question", "Next")
        @interactable_objects << create_new_interactable_shape(40, 485, 220, 65, "release_question", "Release Question")
        @interactable_objects << create_new_interactable_shape(270, 485, 220, 65, "reset_all_answers", "Reset All Answers")
        @interactable_objects << create_new_interactable_shape(500, 485, 220, 65, "process_answers", "Process Answers")
        @interactable_objects << create_new_interactable_shape(40, 570, 240, 65, "watch_leaderboard", "Update Leaderboard")
    end

    def draw()
        # Draw background
        draw_background()
        # Draw the app name on the screen 
        @font.draw_markup("<b>Game Controller</b>", 40, 20, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw the notification
        @font.draw_markup("<i>#{@notification}</i>", 250, 20, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw the question manager area
        @font.draw_markup("<i>Question Manager</i>", 40, 60, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw question number
        @font.draw_markup("Number of Questions: <b>#{@question.length}</b>", 350, 110, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw the room manager area
        @font.draw_markup("<i>Room Manager</i>", 40, 180, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw the game manager area
        @font.draw_markup("<i>Game Manager</i>", 40, 310, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        @font.draw_markup("Select the Question to release: <b>Question #{@current_question_for_displaying}</b>", 40, 430, ZOrder::TEXT, 1, 1, Gosu::Color::WHITE)
        # Draw interactable objects on the screen
        draw_interactable_objects(@font, @interactable_objects)
        # Draw top 5 high scores
        draw_leaderboard(@font, @leaderboard, 5)
    end

    def button_down(id)
        case id
        # Left mouse click event handler
        when Gosu::MsLeft
            @notification = ""
            # Check if user has pressed any button on the screen
            pressed_button = interactable_object_clicked(@interactable_objects)
            case pressed_button
            # Execute when user pressed "Load Question From File"
            when "load_question_from_file"
                @question = read_question_from_file(QUESTION_FILE_NAME)
                @current_question_for_displaying = 1
                @notification = "Read in questions successfully."
            # Execute when user pressed "Open Room"
            when "open_room"
                open_room_status = set_room_status(@server_connection, RoomStatus::OPENING)
                if(open_room_status)
                    @notification = "Successfully opened game room."
                end
            # Execute when user pressed "Close Room"
            when "close_room"
                close_room_status = set_room_status(@server_connection, RoomStatus::CLOSED)
                if(close_room_status)
                    @notification = "Successfully closed game room."
                end
            # Execute when user pressed "Waiting Screen"
            when "waiting_screen"
                waiting_screen = set_game_status(@server_connection, GameStatus::WAITING_SCREEN)
                if(waiting_screen)
                    @notification = "Successfully set the game to Waiting Screen."
                end
            # Execute when user pressed "Result Screen"
            when "result_screen"
                result_screen = set_game_status(@server_connection, GameStatus::QUESTION_RESULT)
                if(result_screen)
                    @notification = "Successfully set the game to Result Screen."
                end
            # Execute when user pressed "Previous Question"
            when "prev_question"
                # If there is no questions, set the current question to 0
                if(@question.length == 0)
                    @current_question_for_displaying = 0
                else
                    # Minus the current question index by 1
                    new_question_displaying = @current_question_for_displaying - 1
                    # If it reached 0 or smaller, move to the last question
                    if (new_question_displaying <= 0)
                        @current_question_for_displaying = @question.length
                    else
                        @current_question_for_displaying = new_question_displaying
                    end
                end
            # Execute when user pressed "Next Question"
            when "next_question"
                # If there is no questions, set the current question to 0
                if(@question.length == 0)
                    @current_question_for_displaying = 0
                else
                    # Add the current question index by 1
                    new_question_displaying = @current_question_for_displaying + 1
                    # If the new question displaying is greater than number of questions
                    # move to the first question
                    if (new_question_displaying > @question.length)
                        @current_question_for_displaying = 1
                    else
                        @current_question_for_displaying = new_question_displaying
                    end
                end
            # Execute when user pressed "Release Question"
            when "release_question"
                # Only works if question within the current_question index exist
                if(@question[@current_question_for_displaying - 1] != nil) # Because we are displaying from 1 to the last question, so we need to minus 1 to retrieve correct object
                    release_new_question = release_question(@server_connection, @current_question_for_displaying, @question[@current_question_for_displaying - 1])
                    if(release_new_question)
                        @notification = "Released question #{@current_question_for_displaying} successfully."
                    end
                end
            # Execute when user pressed "Reset All Answers"
            when "reset_all_answers"
                reset_answers = reset_all_answers(@server_connection, @current_question_for_displaying)
                if(reset_answers)
                    @notification = "Reset all submitted answers of question #{@current_question_for_displaying}."
                end
            # Execute when user pressed "Process Answer"
            when "process_answers"
                process_status = process_answers(@server_connection, @current_question_for_displaying, @question[@current_question_for_displaying - 1])
                if(process_status)
                    @notification = "Process answers completed for question #{@current_question_for_displaying}."
                end
            when "delete_all_user"
                delete_status = delete_all_users(@server_connection)
                if(delete_status)
                    @notification = "Delete all users successfully."
                end
            when "watch_leaderboard"
                @leaderboard = watch_leaderboard(@server_connection)
            end
        end
    end
end

FunkyQuizAdmin.new.show if __FILE__ == $0