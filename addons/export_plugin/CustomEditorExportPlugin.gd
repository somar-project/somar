@tool
extends EditorExportPlugin


func _get_name() -> String:
    return "CustomEditorExportPlugin"


func _supports_platform(platform : EditorExportPlatform) -> bool:
    if platform.get_os_name() == "Android":
        return true
    
    return false


func _get_android_manifest_application_element_contents(platform : EditorExportPlatform, _debug : bool) -> String:
    var contents : String = ""

    if platform.get_os_name() == "Android":
        contents = "        <meta-data tools:node=\"replace\" android:name=\"com.oculus.supportedDevices\" android:value=\"quest2|questpro|quest3\"/>\n"
    
    return contents
