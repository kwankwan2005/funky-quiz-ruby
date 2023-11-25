# ============ PLAYER SCREEN BUTTON =================
# Checks if user has clicked on a specified area
def area_clicked(left_x, top_y, right_x, bottom_y)
    if(mouse_x >= left_x && mouse_x <= right_x && mouse_y >= top_y && mouse_y <= bottom_y)
        true
    else
        false
    end
end

# Check if user has clicked on an interactable object (answer button...)
def interactable_object_clicked(interactable_lists)
    # Return false if there is not any interactable objects
    if(interactable_lists.length == 0)
        return false
    else
        index = 0
        # Loop for each interactable object
        while (index < interactable_lists.length)
            # Get the position of a interactable object
            left_x = interactable_lists[index].left_x
            right_x = interactable_lists[index].right_x
            top_y = interactable_lists[index].top_y
            bottom_y = interactable_lists[index].bottom_y

            # Pass these positions into area_clicked function
            # to check if user has clicked to that interactable object
            clicked = area_clicked(left_x, top_y, right_x, bottom_y)

            # If yes, return the name of that interactable object
            if(clicked) 
                return interactable_lists[index].name
            end
            index = index + 1
        end
        # If there are no objects clicked, return false
        return false
    end
end

# Login user to the game room
# Takes in a server connection and the username
def login(server_connection, username)
    # Get the reference of user on the server
    user_query = server_connection.col("users").doc(username)
    # Make a query to the server to check if that username has existed before
    query_result = user_query.get()
    # If the username has existed before
    # return true - login successfully
    if(query_result.exists?)
        return true
    else
        # If the username has NOT existed before
        # create a new record on the user database
        add_user_query = server_connection.col("users").doc(username)
        data = {
            username: username,
            score: 0.00
        }
        add_user_query.set(data)
        # return true - login successfully
        return true
    end
    # login failed
    return false
end

# Submit user's answer to the game room
# Takes in a server connection, username, question number and answer
def submit_answer(server_connection, username, question_id, answer)
    # Get the reference of user's answer on the server
    user_answer_query = server_connection.col("submitted_answers").doc("#{question_id}").col("#{username}").doc("answer")
    # Make a query to the server to check if user has answered a specified question before
    query_result = user_answer_query.get()
    # If yes, return false as users have already submitted their answer
    if(query_result.exists?)
        return false
    else
        # Make a query that add user's answer to the database
        submit_answer_query = server_connection.col("submitted_answers").doc("#{question_id}").col("#{username}").doc("answer")
        data = {
            submit_answer: answer,
            timestamp: Time.now.to_i()
        }
        submit_answer_query.set(data)
        # Return true as users have submitted their answer successfully
        return true
    end
    # Return false as answer cannot be sent
    return false
end

# Check the game room status
# Takes in a server connection
def check_room_status(server_connection)
    # Get the reference of game status on the server
    room_status_query = server_connection.col("game").doc("game_status")
    # Query and get data
    query_result = room_status_query.get()
    if(query_result.exists? && query_result.data[:room_status] == RoomStatus::OPENING)
        # Return true as the room has opened
        return true 
    end
    # Return false as the room has NOT opened
    return false
end

# ============ ADMIN SCREEN BUTTON =================

# Update new room status
# Takes in a server connection
def set_room_status(server_connection, status)
    # Get the reference of room status on the server
    room_query = server_connection.col("game").doc("game_status")
    data = {
        room_status: status
    }
    # Update new room status
    # "merge: true" to merge with existed data
    room_query.set(data, merge: true) 
    return true
end

# Update new game status
# Takes in a server connection
def set_game_status(server_connection, status)
    # Get the reference of game status on the server
    game_status_query = server_connection.col("game").doc("game_status")
    data = {
        game_status: status
    }
    # Update new game status
    # "merge: true" to merge with existed data
    game_status_query.set(data, merge: true) 
    return true
end

# Release a new question to the server
# Takes in a server connection, question number and question data
def release_question(server_connection, question_number, question_data)
    # Get the question data
    question_text = question_data.question
    answers = question_data.answer_list
    correct_answer = question_data.correct_answer
    time_allowed = question_data.time_allowed
    # Calculate the timestamp, used for calculate timer in Player screen
    server_timestamp = Time.now.to_i() + time_allowed
    # Get the reference of game status on the server
    new_question_release_query = server_connection.col("game").doc("game_status")
    data = {
        question: question_text,
        question_number: question_number,
        answers: answers,
        answer_count: [0, 0, 0],
        time_allowed: time_allowed,
        server_timestamp: server_timestamp,
        correct_answer: correct_answer,
        game_status: GameStatus::QUESTION_RELEASED
    }
    # Update new game status and new question to the server
    new_question_release_query.set(data, merge: true)
    return true
end

# Get list of players
# Takes in a server connection and return a list of players
def get_all_users(server_connection)
    users = []
    # Get the reference of user list on the server
    user_query = server_connection.col("users")
    # Query and loop for each user (snapshot)
    user_query.get() do |snapshot|
        # Create a User object
        user_info = User.new()
        # Set attributes for this object
        user_info.username = snapshot[:username]
        user_info.score = snapshot[:score]
        # Push back into the array
        users << user_info
    end
    # Return a list of players
    return users
end

# Get current server timestamp
def get_server_timestamp(server_connection)
    # Get the reference of game status on the server
    room_status_query = server_connection.col("game").doc("game_status")
    # Query and get data
    query_result = room_status_query.get()
    if(query_result.exists?)
        return query_result.data[:server_timestamp] # Return timestamp
    end
    # Return 0 if game status data doesn't exist
    return 0
end

# Reset all submitted answers of a specified question
# Takes in a server connection and question number
def reset_all_answers(server_connection, question_number)
    # Get all users
    user_list = get_all_users(server_connection)
    index = 0
    # Loop for each user
    while (index < user_list.length)
        # Get the username
        username = user_list[index].username
        # Get user's answer reference and then delete data on that reference
        user_answer_query = server_connection.col("submitted_answers").doc("#{question_number}").col("#{username}").doc("answer")
        user_answer_query.delete()
        index = index + 1
    end
    return true
end

# Delete all users from the game
# Takes in a server connection
def delete_all_users(server_connection)
    # Get all users
    user_list = get_all_users(server_connection)
    index = 0
    # Loop for each user
    while (index < user_list.length)
        # Get the username
        username = user_list[index].username
        # Get user's reference and then delete data on that reference
        user_query = server_connection.col("users").doc(username)
        user_query.delete()
        index = index + 1
    end
    return true
end

# Process submitted answers of a specified question
# If users answered correctly, add score for them
def process_answers(server_connection, question_number, question_data)
    # Get the correct answer
    correct_answer = question_data.correct_answer
    # Get all users
    user_list = get_all_users(server_connection)
    # Answer count array initialize
    answer_count = Array.new(question_data.answer_list.length, 0)
    # Get current timestamp of the server
    server_timestamp = get_server_timestamp(server_connection)
    index = 0
    # Loop for each user to get their answer and compare with the correct answer
    while (index < user_list.length)
        # Get username
        username = user_list[index].username
        # Get user's answer
        user_answer_query = server_connection.col("submitted_answers").doc("#{question_number}").col("#{username}").doc("answer")
        query_result = user_answer_query.get()
        # Check if that user has submitted their answer (1st step)
        if(query_result.exists?)
            user_answer = query_result.data[:submit_answer]
            # Check if that user has submitted their answer (2nd step)
            if(user_answer != nil)
                # Add 1 to the answer count
                # e.g: If user answered A (0), the item #0 in the array will be incremented by 1
                answer_count[user_answer] = answer_count[user_answer] + 1
                # Check if user's answer is correct or not
                # If yes, add score for them
                if(user_answer == correct_answer)
                    # Calculate user's score
                    # Answer faster, get more score
                    score = server_timestamp - query_result.data[:timestamp]
                    # Reassign score to user object 
                    user_list[index].score = user_list[index].score + score
                    # Update user's new information to the server
                    update_user(server_connection, user_list[index])
                end
            end
        end
        index = index + 1
    end
    # Update answer statistics to the server
    update_answer_count(server_connection, answer_count)
    return true
end

# Update answer statistics to the server
# Takes in a server connection and answer_count
def update_answer_count(server_connection, answer_count)
    # Get the reference of game_status
    update_game_data = server_connection.col("game").doc("game_status")
    data = {
        answer_count: answer_count
    }
    # Update answer statistics
    # "merge: true" to merge with existed data
    update_game_data.set(data, merge: true) 
    return true
end

# Update user information to the server
# Takes in a server connection and an User object
def update_user(server_connection, user_info)
    # Get info from the User object
    username = user_info.username
    score = user_info.score
    # Get the reference of the user by using username
    update_user_query = server_connection.col("users").doc(username)
    data = {
        username: username,
        score: score
    }
    # Update new user information
    # "merge: true" to merge with existed data
    update_user_query.set(data, merge: true)
    return true
end

# Get the current leaderboard
# Takes in a server connection and return a sorted list of users (score descending)
# I have modified the "Bubble Sort" code from "Week 9 - Sorting, Complexity and Recursion" lecture ("An Example - Sorting" slide)
# on Ed Lessons to sort elements in descending order. 
# Swinburne University of Technology (n.d.). Week 9 - Sorting, Complexity and Recursion, ‘An Example - Sorting’ slide. [online] COS10009 - Ed Lessons. Available at: https://edstem.org/au/courses/13602/lessons/41250/slides/285957 [Accessed 24 Nov. 2023].
def watch_leaderboard(server_connection)
    # Get all users
    user_list = get_all_users(server_connection)
    index = 0
    # Bubble sort (descending order)
    while (index < user_list.length - 1)
        # Check from the user_list[index + 1] to the end of user_list
        new_index = index + 1
        while (new_index < user_list.length)
            puts "Current sort index: #{index} / Our partner in pair: #{new_index}"
            # If the first score is less than the second score, swap two User objects
            if (user_list[index].score < user_list[new_index].score)
                puts "Swap pair: #{index} (#{user_list[index].score} scores) /  #{new_index} (#{user_list[new_index].score} scores)"
                swap_element(user_list, index, new_index)
            end
            new_index = new_index + 1
        end
        index = index + 1
    end
    # Return sorted user array
    return user_list
end

# Swap two elements in the array
def swap_element(array, a, b)
    temp = array[b]
    array[b] = array[a]
    array[a] = temp
end