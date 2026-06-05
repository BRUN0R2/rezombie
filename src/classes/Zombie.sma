#include <rezombie>

#pragma semicolon 1
#pragma compress 1

public plugin_precache()
{
	register_plugin("Class: Zombie", "0.1.0", "BRUN0");

	new Class:class = create_class("zombie", TEAM_ZOMBIE);
	set_class_var(class, "name", "Zombie");

	new ModelsPack:models = get_class_var(class, "models");
	models_pack_add_model(models, create_model("models/player/rz_source/rz_source.mdl"));

	new Props:props = get_class_var(class, "props");
	set_props_var(props, "health", 500);
	set_props_var(props, "speed", 250);
	set_props_var(props, "gravity", 1.0);
	//set_props_var(props, "weapons_interaction", false);
	//set_props_var(props, "render_fx", kRenderFxDistort);

	new Weapon:melee = get_class_var(class, "melee");
	set_weapon_var(melee, "view_model", create_model("models/player/rz_source/hand.mdl"));
	/*set_weapon_var(melee, "always_damage", 1000);
	set_weapon_var(melee, "gibs", true);*/
}
