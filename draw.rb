require "gosu"

# Draw a gradient background using TOP_COLOR, BOTTOM_COLOR, WIDTH_SCREEN and HEIGHT_SCREEN
def draw_background()
    draw_quad(0, 0, TOP_COLOR, WIDTH_SCREEN, 0, TOP_COLOR, 0, HEIGHT_SCREEN, BOTTOM_COLOR, WIDTH_SCREEN, HEIGHT_SCREEN, BOTTOM_COLOR, ZOrder::BACKGROUND, mode=:default)
end

# Get the width of a text on the screen
# Takes in a font and text content
def get_text_width(font, title)
    return font.text_width(title)
end

# Create a new interactable picture on the screen
def create_new_interactable_picture(image_location, x_position, y_position, scale_x, scale_y, z_order, description)
    # Takes in image location for creating an Image object
    image_object = Image.new(image_location)
    
    # Get the Gosu::Image object from the Image object
    gosu_image = image_object.gosu_image

    # Calculate the width and height of the picture
    width = gosu_image.width * scale_x
    height = gosu_image.height * scale_y

    # Calculate the position on the screen
    left_x = x_position
    top_y = y_position
    right_x = x_position + width # picture width
    bottom_y = y_position + height # picture height

    # Create a new Dim to store image position and label
    image_object.position = Dim.new(left_x, top_y, right_x, bottom_y, description)
    image_object.z_order = z_order

    # Return an Image object
    return image_object
end

# Create a new interactable shape on the screen
def create_new_interactable_shape(x_position, y_position, width, height, description, text_contain = "")
    # Calculate the width and height of a shape
    left_x = x_position
    top_y = y_position
    right_x = x_position + width
    bottom_y = y_position + height
    # Create a new Dim to store shape position and label
    shape_position = Dim.new(left_x, top_y, right_x, bottom_y, description)
    shape_position.text_contain = text_contain
    # Return a Dim object
    return shape_position
end

# Get the picture width and height when drawing on Gosu
def get_picture_width_and_height(gosu_picture, scale_x = 1, scale_y = 1)
    width = gosu_picture.width * scale_x
    height = gosu_picture.height * scale_y
    return [width, height]
end

# Draw image on Gosu with 4 coordinates (left_x, top_y, right_x and bottom_y)
def draw_image(image_object)
    gosu_image = image_object.gosu_image

    left_x = image_object.position.left_x
    top_y = image_object.position.top_y
    right_x = image_object.position.right_x
    bottom_y = image_object.position.bottom_y

    gosu_image.draw_as_quad(left_x, top_y, 0xffffffff, right_x, top_y, 0xffffffff, left_x, bottom_y, 0xffffffff, right_x, bottom_y, 0xffffffff, z = 0)
end

# Draw image on Gosu with 2 coordinates (left_x - x_position, top_y - y_positio)
def draw_picture_with_file_descriptor(image, x_position, y_position, z_order, scale_x = 1, scale_y = 1)
    width = image.width * scale_x
    height = image.height * scale_y

    image.draw(x_position, y_position, z_order, scale_x, scale_y, color = 0xff_ffffff, mode=:default)
end

# Draw a text on Gosu but it can automatically break lines when screen-overflow
# Returns an Image
def draw_multiple_lines_of_text(text, width_text, line_height, line_spacing, align)
    # Get the options: width of the paragraph, line spacing and text alignment
    options = {
        width: width_text,
        spacing: line_spacing,
        align: align
    }
     
    # Create a picture containing text with many lines
    final_picture = Gosu::Image.from_text(text, line_height, options)
    # Return final picture
    return final_picture
end