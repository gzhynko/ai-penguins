class_name InferenceStatsChartsContainer
extends PanelContainer

var feed_prompt_fn: Function
var predict_fn: Function
var per_token_fn: Function

@onready var feed_prompt_dur_chart: Chart = $VBoxContainer/FeedPromptDurChart
@onready var predict_dur_chart: Chart = $VBoxContainer/PredictDurChart
@onready var per_token_dur_chart: Chart = $VBoxContainer/PerTokenDurChart


func _ready():
	_init_charts()
	
	# connect signals
	ConsoleWindowManager.received_inference_stats.connect(_on_received_inference_stats)


func _init_charts():
	var base_props = ChartProperties.new()
	base_props.colors.frame = Color.TRANSPARENT
	base_props.colors.background = Color.TRANSPARENT
	base_props.colors.grid = Color("#283442")
	base_props.colors.ticks = Color("#283442")
	base_props.colors.text = Color.WHITE_SMOKE
	base_props.draw_bounding_box = false
	base_props.show_x_label = false
	base_props.show_y_label = false
	base_props.x_scale = 5
	base_props.draw_vertical_grid = false
	base_props.interactive = true
	
	var fn_params = { 
		color = Color("#36a2eb"),
		marker = Function.Marker.CIRCLE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.LINEAR
	}
	feed_prompt_fn = Function.new([0, 0], [0, 0], "", fn_params)
	predict_fn = Function.new([0, 0], [0, 0], "", fn_params)
	per_token_fn = Function.new([0, 0], [0, 0], "", fn_params)
	
	base_props.title = "Avg feed prompt duration, ms/#"
	feed_prompt_dur_chart.plot([feed_prompt_fn], base_props)
	base_props.title = "Avg predict duration, ms/#"
	predict_dur_chart.plot([predict_fn], base_props)
	base_props.title = "Avg per token duration, ms/#"
	per_token_dur_chart.plot([per_token_fn], base_props)


func _on_received_inference_stats(stats_array: Array[float]):
	var topics_gen = stats_array[0]
	var avg_feed_prompt_duration = stats_array[1]
	var avg_predict_duration = stats_array[2]
	var avg_per_token_duration = stats_array[3]
	
	feed_prompt_fn.add_point(topics_gen, avg_feed_prompt_duration)
	predict_fn.add_point(topics_gen, avg_predict_duration)
	per_token_fn.add_point(topics_gen, avg_per_token_duration)
	
	feed_prompt_dur_chart.queue_redraw()
	predict_dur_chart.queue_redraw()
	per_token_dur_chart.queue_redraw()


func _process(_delta: float):
	pass
	#feed_prompt_fn.add_point(0, cos(0) * 20)
	#feed_prompt_dur_chart.queue_redraw()
