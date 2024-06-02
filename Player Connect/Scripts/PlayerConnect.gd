extends Control
class_name PlayerConnect

## Create webhook of your discord channel and paste in the url here
const WEBHOOK_URL: String = "https://discord.com/api/webhooks/1243572131430666292/f2LCUOvEmTVwpgXQpgQ7R6mhlaXsd5EOkh4IpwKAGMxCG01SGO_aw5uua5vGYnX6f1Ug"

## Add your game's name here, this will be your webhook's username
const GAME_NAME: String = "The Void Project"

## Calling game version from Project Setttings.. change your game version from there..
var gameVer = ProjectSettings.get("application/config/version")

## Use this website to find discord embed color codes (copy int value)
## https://gist.github.com/thomasbnt/b6f455e2c7d743b796917fa3c205f812?permalink_comment_id=3546054
## If you wish to add your own or contribute, please describe colors here for other options
const BUG_REPORT_EMBED_COLOR: int = 15548997 # RED
const PLAYER_FEEDBACK_EMBED_COLOR: int = 15844367 #YELLOW
const FEATURE_REQUEST_EMBED_COLOR: int = 5763719 #GREEN

@export var webhookCreator : WebhookCreator

@export_group("Fields")
@export var nameLineEdit: LineEdit
@export var emailLineEdit: LineEdit
@export var typeOptions: OptionButton
@export var messageTextEdit: TextEdit

@export_group("Button")
@export var submitButton: Button

@export_group("Misc")
@export var animator: AnimationPlayer

var isOpened: bool

func _ready() -> void:
	## Setting Submit Button Pivot to Center
	submitButton.pivot_offset = submitButton.size / 2
	webhookCreator.SendingMessageFinished.connect(submitButton.set.bind("disabled", false))

func _process(_delta: float) -> void:
	## Checking Empty fields and if there are any, disabling submit button
	## You can remove it or add exception if you want to make any lineEdit optional
	CheckingEmptyFields()

func _input(event: InputEvent) -> void:
	## Add Input key in your project settings for Report and Escape if u want
	if Input.is_action_pressed("Report") and not isOpened:
		OpenAnimation()
	elif event.is_action_pressed("Report") or event.is_action_pressed("Escape") and isOpened:
		CloseAnimation()

func OpenAnimation() -> void:
	animator.play("Open")
	get_tree().paused = true
	await animator.animation_finished
	isOpened = true

func CloseAnimation() -> void:
	animator.play("Close")
	await animator.animation_finished
	isOpened = false
	get_tree().paused = false

func CheckingEmptyFields() -> void:
	if nameLineEdit.text.is_empty() or emailLineEdit.text.is_empty() or typeOptions.text.is_empty() or messageTextEdit.text.is_empty():
		submitButton.disabled = true
		submitButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if not nameLineEdit.text.is_empty() and not emailLineEdit.text.is_empty() and not typeOptions.text.is_empty() and not messageTextEdit.text.is_empty():
		submitButton.disabled = false
		submitButton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

#region Submit Button

func OnSubmitButtonHoverEnter() -> void:
	if submitButton.disabled: return
	ParallelTweening(submitButton, "scale", Vector2.ONE * 1.1, 0.15)

func OnSubmitButtonHoverExit() -> void:
	if submitButton.disabled: return
	ParallelTweening(submitButton, "scale", Vector2.ONE, 0.1)

func OnSubmitButtonPressed() -> void:
	NonParallelTweening(submitButton, "scale", Vector2.ONE * 0.95, Vector2.ONE, 0.1)
	
	if webhookCreator.StartMessage() == OK:
		SendReport()

func SendReport():
	## Setting Webhook Name
	webhookCreator.SetUsername(GAME_NAME)
	
	## Setting up Embed
	webhookCreator.StartEmbed()
	webhookCreator.SetEmbedTitle("%s by %s" % [typeOptions.text, nameLineEdit.text])
	
	## Setting embed color based on what type of option is selected based on their item ids from options button node
	match typeOptions.get_selected_id():
		0: webhookCreator.SetEmbedColor(BUG_REPORT_EMBED_COLOR)  # Bug Report
		1: webhookCreator.SetEmbedColor(FEATURE_REQUEST_EMBED_COLOR)  # Feature Request
		2: webhookCreator.SetEmbedColor(PLAYER_FEEDBACK_EMBED_COLOR)  # Feedback
	
	## Adding Email to Embed
	var contactInfo := emailLineEdit.text
	if !contactInfo.is_empty():
		webhookCreator.AddField("Email Address: ", contactInfo)
	
	## Adding Scene Name to Embed
	var sceneName = get_tree().current_scene.name
	if !sceneName.is_empty():
		webhookCreator.AddField("Scene: ", sceneName)
	
	## Adding Message to Embed
	var message = messageTextEdit.text.replace("```", "")
	if !message.is_empty():
		webhookCreator.AddField("Message: ", message)
	
	## Adding footer with game version
	webhookCreator.SetEmbedFooter("Game Version", gameVer)
	
	webhookCreator.SendMessage(WEBHOOK_URL)
	
	## FOR DEBUGGING, YOU CAN REMOVE THIS
	print_rich(
		"[b][color=green]REPORT SENT[/color][/b]", "\n",
		"[b]Name:[/b] ", nameLineEdit.text, "\n",
		"[b]Email:[/b] ", emailLineEdit.text, "\n",
		"[b]Report Type:[/b] ", typeOptions.text, "\n",
		"[b]Scene:[/b] ", sceneName, "\n",
		"[b]Detailed Report:[/b] ", messageTextEdit.text, "\n",
		"[b]Game Version:[/b] v", gameVer, "\n",
		)
	
	## Closing after submit
	CloseAnimation()

#endregion

#region Misc Functions

## FOR ANIMATIONS
func ParallelTweening(object: Object, property: String, finalValue: Variant, duration: float) -> void:
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	tween.tween_property(object, property, finalValue, duration)

func NonParallelTweening(object: Object, property: String, firstValue: Variant, finalValue: Variant, duration: float) -> void:
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(false)
	tween.tween_property(object, property, firstValue, duration)
	tween.tween_property(object, property, finalValue, duration)

#endregion
