#include <amxmodx>
#include <rezombie>

public plugin_precache()
{
	register_plugin("Class: Human", "0.1.0", "BRUN0");

	new Class:class = create_class("human", TEAM_HUMAN);
	set_class_var(class, "name", "Human");

	new Props:props = get_class_var(class, "props");
	set_props_var(props, "health", 100);
	set_props_var(props, "speed", 250);
	set_props_var(props, "gravity", 1.0);
}
