#include <amxmodx>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

public plugin_precache()
{
	register_plugin("Class: Zombie", "0.1.0", "BRUN0");

	new Class:class = create_class("zombie", TEAM_ZOMBIE);
	new Model:model = create_model("rz_source");

	set_class_var(class, "name", "Zombie");
	set_class_var(class, "model", model);

	new Props:props = get_class_var(class, "props");
	set_props_var(props, "health", 500);
	set_props_var(props, "speed", 250);
	set_props_var(props, "gravity", 0.8);
}
