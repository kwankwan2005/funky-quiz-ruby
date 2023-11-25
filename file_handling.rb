# Read questions from a file, takes in a file name
# and return a list of questions
def read_question_from_file(file_name)
    # If the file exist, continue
    if File.exist?(file_name)
        question_file = File.new(file_name, "r") # open for reading
        question_list = read_questions(question_file)
        question_file.close()
        # Return list of questions
        return question_list
    # If not, return with an empty array
    else
        return []
    end
end

# Read all questions from a file descriptor
# and return a list of questions
def read_questions(file_descriptor)
    question_number = file_descriptor.gets().to_i()
    question_recorded = 0
    question_list = []
    # A loop to read each single question
    # Stop when the number of recorded questions has reached limit
    while (question_recorded < question_number)
        question_object = read_single_question(file_descriptor)
        # If question contains all of essential information
        # then put this question into an array
        if(question_object)
            question_list << question_object
        end
        question_recorded = question_recorded + 1
    end
    return question_list
end

# Read a single question from a file
# and return an Question object
def read_single_question(file_descriptor)
    question_text = file_descriptor.gets().to_s().chomp()
    time_allowed = file_descriptor.gets().to_i()
    answer_number = file_descriptor.gets().to_i()
    answer_recorded = 0
    answers = []

    # If there's no answer, then this question is not completed
    if(answer_number == 0)
        return false
    else
        # Loop to read each answer
        # Push the answer onto the possible answers list
        while (answer_recorded < answer_number)
            answers << file_descriptor.gets().to_s().chomp()
            answer_recorded = answer_recorded + 1
        end

        correct_answer = file_descriptor.gets().to_i()

        # Create a new Question object
        # and set the attributes
        question_data = Question.new()     
        question_data.question = question_text
        question_data.answer_list = answers
        question_data.correct_answer = correct_answer
        question_data.time_allowed = time_allowed
        # Return a Question object
        return question_data
    end
end