extends Node

@onready var tree : SceneTree = get_tree()

const MAX_TIMES : int = 60 # 6 secs

var pending : PackedStringArray = []
var finished : Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func load_resource(path : String):
	print_debug("Loading: ", path)
	
	if not _queue_resource(path):
		print_debug("Failed to load resource.")
		return null
	
	var times : int = 0
	var historic_progress : Array = []
	var progress : Array = []
	var last_status : ResourceLoader.ThreadLoadStatus
	var resource : Resource = null
	
	while not resource:
		times += 1
		
		if times < MAX_TIMES:
			await tree.create_timer(0.1).timeout
			resource = _get_resource(path)
			if not resource:
				progress.clear()
				last_status = ResourceLoader.load_threaded_get_status(path, progress)
				historic_progress.append_array(progress)
		else:
			break
	
	if times == MAX_TIMES:
		
		if last_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var same_count : int = 0
			for progress_ind in range(historic_progress.size()-1, 0, -1):
				if is_equal_approx(historic_progress[progress_ind], historic_progress[progress_ind-1]):
					same_count += 1
					
					if same_count == 5:
						break
				
			if same_count < 5:
				print_debug("Maximum time reached. Waiting a bit more.")
				times = 25
				
				while not resource:
					times += 1
					
					if times < MAX_TIMES:
						await tree.create_timer(0.1).timeout
						resource = _get_resource(path)
					else:
						print_debug("Unable to load: ", path)
						break
			else:
				print_debug("Resource seems to be stuck...")
	
	return resource

func _queue_resource(path : String, use_threads : bool = false) -> bool:
	if pending.has(path):
		return true
	
	pending.push_back(path)
	
	var loader_response = ResourceLoader.load_threaded_request(path, "", use_threads)
	
	if loader_response == OK:
		if not is_processing():
			set_process(true)
		
		return true
	else:
		print_debug("ERROR: Failed to load resource with path: {r_path}".format({ r_path = path }))
		return false

func _get_resource(path : String):
	for resource_ind in range(finished.size()-1, -1, -1):
		if finished[resource_ind].path == path:

			var response = finished[resource_ind].resource
			finished.remove_at(resource_ind)

			return response
	
	return null


func _process(_delta : float) -> void:
	if pending.size() > 0:
		
		for path_ind in range(pending.size()-1, -1, -1):
			
			var loader_status = ResourceLoader.load_threaded_get_status(pending[path_ind])
			
			if loader_status == ResourceLoader.THREAD_LOAD_LOADED:
				finished.push_back({
					"path": pending[path_ind],
					"resource": ResourceLoader.load_threaded_get(pending[path_ind])
				})
				pending.remove_at(path_ind)
	
	else:
		set_process(false)
