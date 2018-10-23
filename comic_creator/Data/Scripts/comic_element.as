enum comic_element_types { 	none,
							comic_grabber,
							comic_image,
							comic_page,
						 	comic_fade_in,
							comic_move_in,
							comic_font,
							comic_sound,
							comic_text,
							comic_wait_click,
							comic_crawl_in};

class ComicElement{
	comic_element_types comic_element_type = none;
	bool edit_mode = false;
	bool visible;
	bool has_settings = false;
	vec4 display_color = vec4(1.0);
	int index = -1;

	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	ComicGrabber@ GetGrabber(string grabber_name){return null;}
	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void ShowPage(){}
	void HidePage(){}
	void Update(){}
	void SetEdit(bool editing){}
	void SetProgress(int _progress){}
	void AddSettings(){}
	void EditDone(){}
	void SetCurrent(bool _current){}
	void Delete(){}
	void SetIndex(int _index){
		index = _index;
	}
	void SetVisible(bool _visible){
		visible = _visible;
	}
	void SetTarget(ComicElement@ element){}
	void ClearTarget(){}
}
