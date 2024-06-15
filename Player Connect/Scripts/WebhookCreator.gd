class_name WebhookCreator
extends HTTPRequest

## Defining signals for different outcomes
signal SendingMessageFinished
signal SendingMessageFailed
signal SendingMessageSuccess

var requestBody := []           ## List to store entire message/embed body
var jsonPayload := {}           ## Dictionary to store JSON data
var isEmbedding := false        ## Flag to check if an embed is currently being created
var lastEmbed := {}             ## Dictionary to store the current embed data
var lastEmbedFields := []       ## List to store fields for the current embed

## Starts constructing a new message
func StartMessage():
	## Checking if the HTTP client is currently connected
	if get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return ERR_BUSY          ## Returns error if the client is busy

	## Clearing previous (if any) request data
	requestBody.clear()
	jsonPayload.clear()
	requestBody.push_back(jsonPayload)
	lastEmbed.clear()
	lastEmbedFields.clear()
	return OK                    ## Returns OK to indicate success

## Setting the player's username to indicate who made the report
func SetUsername(username:String):
	jsonPayload["username"] = username

## Function to start creating an embed
func StartEmbed():
	if isEmbedding:
		FinishEmbed()
	isEmbedding = true            ## Setting the flag to indicate that embedding has started

## Function to finish and add the current embed to the message
func FinishEmbed():
	if isEmbedding:
		lastEmbed["fields"] = lastEmbedFields  ## Adding fields to the current embed
		if jsonPayload.get("embeds") is Array:
			jsonPayload["embeds"].push_back(lastEmbed)  ## Adding the embed to the list of embeds
		else:
			jsonPayload["embeds"] = [lastEmbed]  ## Creating a new list with the embed
		isEmbedding = false          ## Reset the embedding flag

## Function to add a field to the current embed
func AddField(field_name:String, field_value:String, field_inline:=false):
	lastEmbedFields.push_back({"name": field_name, "value": field_value, "inline": field_inline})

## Function to set the color of the current embed
func SetEmbedColor(color:int):
	lastEmbed["color"] = color

## Function to set the title of the current embed (Report Types)
func SetEmbedTitle(title:String):
	lastEmbed["title"] = title

## Function to set the footer of the current embed with game version
func SetEmbedFooter(footer_text:String, version:String):
	lastEmbed["footer"] = {"text": "%s: v%s" % [footer_text, version]}

## Function to convert an array of variants into multipart form data
func ArrayToFormData(array: Array, boundary := "boundary")->String:
	var file_counter := 0
	var output = ""

	for element in array:
		output += "--%s\n" % boundary  # Start boundary for each part

		if element is Dictionary:
			# Same handling of dictionaries as in version 1
			output += 'Content-Disposition: form-data; name="payload_json"\nContent-Type: application/json\n\n'
			output += JSON.stringify(element, "    ") + "\n"
		elif element is String:
			# Checks if the string element is both an absolute path and file exists
			if element.is_absolute_path() and FileAccess.file_exists(element):
				var file := FileAccess.open(element, FileAccess.READ)
				# Checks if file object is successfully created
				if file != null:
					var file_content := file.get_buffer(file.get_length())
					file.close()

					# Sets up headers for file upload and adds binary file content
					output += 'Content-Disposition: form-data; name="files[%s]"; filename="%s"\n' % [file_counter, element.get_file()]
					output += "Content-Type: application/octet-stream\n\n"
					output += file_content.get_string_from_utf8()  # Converts binary to string assuming UTF-8 encoding
					output += "\n"
				else:
					# Error handling if file cannot be opened
					printerr("Reporter could not attach File %s to Message, Reason: Failed to open file" % element)
			else:
				# Error handling if file does not exist
				printerr("Reporter could not attach File %s to Message, Reason: File does not exist" % element)
			file_counter += 1

	output += "--%s--" % boundary  # Closing boundary
	return output

## Function to send the constructed message
func SendMessage(url:String):
	FinishEmbed()  ## Ensure any current embed is finished
	var boundary := "b%s" % hash(str(Time.get_unix_time_from_system(), jsonPayload))
	var payload := ArrayToFormData(requestBody, boundary)  # Convert request body to multipart form data

	## Requesting HTTPClient
	request(url,
			PackedStringArray(["connection: keep-alive", "Content-type: multipart/form-data; boundary=%s" % boundary]),
			HTTPClient.METHOD_POST,
			payload
	)

## Function called when the request is completed
func OnRequestCompleted(result, _response_code, _headers, _body):
	if result == RESULT_SUCCESS:
		SendingMessageSuccess.emit()
	else:
		SendingMessageFailed.emit()
	SendingMessageFinished.emit()

func AddFile(file_path: String, file_name: String):
	if file_path.is_absolute_path() and FileAccess.file_exists(file_path):
		requestBody.push_back(file_path)
	else:
		printerr("Reporter could not attach File %s to Message, Reason: File does not exist" % file_path)

func AddScreenshot(screenshot_url: String):
	if not screenshot_url.begins_with("https://") and not screenshot_url.begins_with("http://"):
		screenshot_url = "https://" + screenshot_url
		var http_request = HTTPRequest.new()
		add_child(http_request)
		var error = http_request.request(screenshot_url)

		if not error:
			lastEmbed["image"] = {
				"url": screenshot_url
			}
		http_request.queue_free()
	else:
		lastEmbed["image"] = {
			"url": screenshot_url
		}
