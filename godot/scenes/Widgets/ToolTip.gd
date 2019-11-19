extends Control

var missed_hide = false

# Called when the node enters the scene tree for the first time.
func _ready():
    $Panel/RichTextLabel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    $Panel/RichTextLabel.scroll_active = false # to prevent the scrollbar from briefly appearing (due to the idle_frame yield)
    $Panel/RichTextLabel.scroll_following = false # to avoid a long content to jump as it's waiting for the label height being adjusted

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func show_tooltip(tool_tip):
    missed_hide = false
    $Panel/RichTextLabel.bbcode_text = tool_tip
    yield(get_tree(), "idle_frame")
    if not missed_hide:
        $Panel/RichTextLabel.rect_min_size.y = $Panel/RichTextLabel.get_v_scroll().get_max() + 10
        $Panel/ColorRect.rect_min_size.y = $Panel/RichTextLabel.rect_min_size.y
        self.rect_position = get_global_mouse_position()
        self.show()

func hide_tooltip():
    missed_hide = true
    self.hide()
