#include "hotspots/drika_element.as"
#include "hotspots/drika_wait.as"
#include "hotspots/drika_wait_level_message.as"
#include "hotspots/drika_set_enabled.as"
#include "hotspots/drika_set_character.as"
#include "hotspots/drika_create_particle.as"
#include "hotspots/drika_play_sound.as"
#include "hotspots/drika_go_to_line.as"
#include "hotspots/drika_on_character_enter.as"
#include "hotspots/drika_on_item_enter.as"
#include "hotspots/drika_send_level_message.as"
#include "hotspots/drika_start_dialogue.as"

bool editor_open = false;
bool editing = false;
bool script_finished = false;
int current_line = 0;
array<DrikaElement@> drika_elements;
array<int> drika_indexes;
bool post_init_done = false;
Object@ this_hotspot = ReadObjectFromID(hotspot.GetID());

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

TextureAssetRef delete_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Delete.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

void Init() {
    level.ReceiveLevelEvents(hotspot.GetID());
}

void Dispose() {
    level.StopReceivingLevelEvents(hotspot.GetID());
}

void SetParameters(){
	params.AddString("Script Data", "");
}

void InterpData(){
	array<string> lines = params.GetString("Script Data").split("\n");
	Log(info, "Data " + params.GetString("Script Data"));

	for(uint index = 0; index < lines.size(); index++){
		array<string> line_elements = lines[index].split(" ");

		if(line_elements[0] == "set_character"){
			int character_id = atoi(line_elements[1]);
			drika_elements.insertLast(DrikaSetCharacter(character_id, line_elements[2]));
		}else if(line_elements[0] == "set_enabled"){
			int object_id = atoi(line_elements[1]);
			bool enabled = line_elements[2] == "true";
			drika_elements.insertLast(DrikaSetEnabled(object_id, enabled));
		}else if(line_elements[0] == "wait"){
			int duration = atoi(line_elements[1]);
			drika_elements.insertLast(DrikaWait(duration));
		}else if(line_elements[0] == "wait_level_message"){
			drika_elements.insertLast(DrikaWaitLevelMessage(line_elements[1]));
		}else if(line_elements[0] == "create_particle"){
			bool use_blood_tint = line_elements[6] == "true";
			drika_elements.insertLast(DrikaCreateParticle(atoi(line_elements[1]), atoi(line_elements[2]), line_elements[3], atof(line_elements[4]), line_elements[5], use_blood_tint));
		}else if(line_elements[0] == "play_sound"){
			drika_elements.insertLast(DrikaPlaySound(atoi(line_elements[1]), line_elements[2]));
		}else if(line_elements[0] == "go_to_line"){
			drika_elements.insertLast(DrikaGoToLine(atoi(line_elements[1])));
		}else if(line_elements[0] == "on_character_enter"){
			drika_elements.insertLast(DrikaOnCharacterEnter(atoi(line_elements[1]), line_elements[2]));
		}else if(line_elements[0] == "on_item_enter"){
			drika_elements.insertLast(DrikaOnItemEnter(atoi(line_elements[1]), line_elements[2]));
		}else if(line_elements[0] == "send_level_message"){
			drika_elements.insertLast(DrikaSendLevelMessage(line_elements[1]));
		}else if(line_elements[0] == "drika_start_dialogue"){
			drika_elements.insertLast(DrikaStartDialogue(line_elements[1]));
		}else{
			//Either an empty line or an unknown command is in the comic.
			continue;
		}
		drika_indexes.insertLast(index);
	}
	ReorderElements();
}

void Update(){
	if(!post_init_done){
		post_init_done = true;
		InterpData();
		return;
	}

	if(EditorModeActive() && editing == false){
		SwitchToEditing();
	}else if(!EditorModeActive() && editing == true){
		SwitchToPlaying();
	}

	if(EditorModeActive()){
		if(this_hotspot.IsSelected() && GetInputPressed(0, "u")){
			editor_open = true;
		}
	}
	if(!script_finished && drika_indexes.size() > 0 && !EditorModeActive()){
		if(GetCurrentElement().Trigger()){
			if(current_line == int(drika_indexes.size() - 1)){
				script_finished = true;
			}else{
				current_line += 1;
			}
		}
	}else if(drika_indexes.size() > 0 && EditorModeActive()){
		GetCurrentElement().Editing();
	}
}

void SwitchToEditing(){
	editing = true;
}

void SwitchToPlaying(){
	Reset();
	editing = false;
}

bool reorded = false;
int display_index = 0;
int drag_target_line = 0;
bool update_scroll = false;

void DrawEditor(){
	if(editor_open){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_Text, text_color);
		ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_CloseButton, background_color);
		ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Drika Hotspot " + "###Drika Hotspot", editor_open, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoCollapse);
		ImGui_PopStyleVar();

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(300.0f, 150.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, ImGui_GetWindowHeight() - 60));
			GetCurrentElement().AddSettings();
			ImGui_EndChild();
			ImGui_BeginChild("Modal Buttons", vec2(-1, 60));
			if(ImGui_Button("Close")){
				GetCurrentElement().ApplySettings();
				ImGui_CloseCurrentPopup();
				Save();
			}
			ImGui_EndChild();
			ImGui_EndPopup();
		}
		ImGui_PopStyleVar();

		if(ImGui_BeginMenuBar()){
			if(ImGui_BeginMenu("Add")){
				if(ImGui_MenuItem("Set Character")){
					DrikaSetCharacter new_set_character();
					InsertElement(@new_set_character);
				}
				if(ImGui_MenuItem("Set Enabled")){
					DrikaSetEnabled new_set_enabled();
					InsertElement(@new_set_enabled);
				}
				if(ImGui_MenuItem("Wait For Level Message")){
					DrikaWaitLevelMessage new_wait_level_message();
					InsertElement(@new_wait_level_message);
				}
				if(ImGui_MenuItem("Wait")){
					DrikaWait new_wait();
					InsertElement(@new_wait);
				}
				if(ImGui_MenuItem("Create Particle")){
					DrikaCreateParticle new_create_particle();
					InsertElement(@new_create_particle);
				}
				if(ImGui_MenuItem("Play Sound")){
					DrikaPlaySound new_play_sound();
					InsertElement(@new_play_sound);
				}
				if(ImGui_MenuItem("Go To Line")){
					DrikaGoToLine new_go_to_line();
					InsertElement(@new_go_to_line);
				}
				if(ImGui_MenuItem("On Character Enter")){
					DrikaOnCharacterEnter new_on_character_enter();
					InsertElement(@new_on_character_enter);
				}
				if(ImGui_MenuItem("On Item Enter")){
					DrikaOnItemEnter new_on_item_enter();
					InsertElement(@new_on_item_enter);
				}
				if(ImGui_MenuItem("Send Level Message")){
					DrikaSendLevelMessage new_send_level_message();
					InsertElement(@new_send_level_message);
				}
				if(ImGui_MenuItem("Start Dialogue")){
					DrikaStartDialogue new_start_dialogue();
					InsertElement(@new_start_dialogue);
				}
				ImGui_EndMenu();
			}
			if(ImGui_ImageButton(delete_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					GetCurrentElement().Delete();
					int current_index = drika_indexes[current_line];
					drika_elements.removeAt(current_index);
					drika_indexes.removeAt(current_line);
					for(uint i = 0; i < drika_indexes.size(); i++){
						if(drika_indexes[i] > current_index){
							drika_indexes[i] -= 1;
						}
					}
					Log(info, "Size " + drika_elements.size());
					Log(info, "Size indexes " + drika_indexes.size());
					// If the last element is deleted then the target needs to be the previous element.
					if(current_line > 0 && current_line == int(drika_elements.size())){
						display_index = drika_indexes[current_line - 1];
						current_line -= 1;
					}else if(drika_elements.size() > 0){
						display_index = drika_indexes[current_line];
					}
					ReorderElements();
				}
			}
			ImGui_EndMenuBar();
		}

		if(!ImGui_IsPopupOpen("Edit")){
			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(current_line > 0){
					display_index = drika_indexes[current_line - 1];
					current_line -= 1;
					update_scroll = true;
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(current_line < int(drika_elements.size() - 1)){
					display_index = drika_indexes[current_line + 1];
					current_line += 1;
					update_scroll = true;
				}
			}
		}

		int line_counter = 0;
		for(uint i = 0; i < drika_indexes.size(); i++){
			int item_no = drika_indexes[i];
			string line_number = drika_elements[item_no].index + ".";
			int initial_length = max(1, (7 - line_number.length()));
			for(int j = 0; j < initial_length; j++){
				line_number += " ";
			}
			vec4 text_color = drika_elements[item_no].display_color;
			text_color.x /= 255;
			text_color.y /= 255;
			text_color.z /= 255;
			ImGui_PushStyleColor(ImGuiCol_Text, text_color);
			if(ImGui_Selectable(line_number + drika_elements[item_no].GetDisplayString(), display_index == int(item_no), ImGuiSelectableFlags_AllowDoubleClick)){
				if(ImGui_IsMouseDoubleClicked(0)){
					if(drika_elements[drika_indexes[i]].has_settings){
						ImGui_OpenPopup("Edit");
					}
				}else{
					GetCurrentElement().EditDone();
					display_index = int(item_no);
					current_line = int(i);
				}
			}
			if(update_scroll && display_index == int(item_no)){
				update_scroll = false;
				ImGui_SetScrollHere(0.5);
			}
			ImGui_PopStyleColor();
			if(ImGui_IsItemActive() && !ImGui_IsItemHovered()){
				float drag_dy = ImGui_GetMouseDragDelta(0).y;
				if(drag_dy < 0.0 && i > 0){
					// Swap
					drika_indexes[i] = drika_indexes[i-1];
            		drika_indexes[i-1] = item_no;
					drag_target_line = i-1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}else if(drag_dy > 0.0 && i < drika_elements.size() - 1){
					drika_indexes[i] = drika_indexes[i+1];
            		drika_indexes[i+1] = item_no;
					drag_target_line = i+1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}
			}
			line_counter += 1;
		}
		ImGui_End();
		ImGui_PopStyleColor(17);
		if(drika_elements.size() > 0){
			GetCurrentElement().DrawEditing();
		}
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
	}
}

DrikaElement@ GetCurrentElement(){
	return drika_elements[drika_indexes[current_line]];
}

void ReorderElements(){
	for(uint index = 0; index < drika_indexes.size(); index++){
		DrikaElement@ current_element = drika_elements[drika_indexes[index]];
		current_element.SetIndex(index);
	}
	Save();
}

void InsertElement(DrikaElement@ new_element){
	if(drika_elements.size() > 0){
		GetCurrentElement().EditDone();
	}
	drika_elements.insertLast(new_element);
	if(drika_indexes.size() < 1){
		drika_indexes.insertAt(current_line, drika_elements.size() - 1);
		display_index = drika_indexes[current_line];
	}else{
		drika_indexes.insertAt(current_line + 1, drika_elements.size() - 1);
		display_index = drika_indexes[current_line + 1];
	}
	ReorderElements();
}

void LaunchCustomGUI(){
	editor_open = true;
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
	if(token == "level_event" and !script_finished && drika_indexes.size() > 0){
		token_iter.FindNextToken(msg);
		string message = token_iter.GetToken(msg);
		GetCurrentElement().ReceiveMessage(message);
	}
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter"){
		if(!script_finished && drika_indexes.size() > 0){
			GetCurrentElement().ReceiveMessage("CharacterEnter", mo.GetID());
			ScriptParams@ char_params = ReadObjectFromID(mo.GetID()).GetScriptParams();
			if(char_params.HasParam("Teams")) {
    			string team = char_params.GetString("Teams");
				GetCurrentElement().ReceiveMessage("CharacterEnter", team);
			}
		}
	}
}

void HandleEventItem(string event, ItemObject @obj){
	Log(info, "on item work!");
	if(event == "enter"){
		if(!script_finished && drika_indexes.size() > 0){
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetID());
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetLabel());
		}
	}
}

void Reset(){
	GetCurrentElement().EditDone();
	current_line = 0;
	script_finished = false;
	for(uint i = 0; i < drika_indexes.size(); i++){
		drika_elements[drika_indexes[i]].Reset();
	}
}

void Save(){
	string data = "";
	for(uint i = 0; i < drika_indexes.size(); i++){
		data += drika_elements[drika_indexes[i]].GetSaveString();
		if(i != drika_elements.size() - 1){
			data += "\n";
		}
	}
	params.SetString("Script Data", data);
}
