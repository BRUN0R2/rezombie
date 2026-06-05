#include <rezombie>

#pragma semicolon 1
#pragma compress 1

public plugin_precache()
{
	register_plugin("Zombie: Fleshpound", "0.1.0", "BRUN0");

	new Class:class = RequireClass("zombie");
	new Subclass:subclass = create_subclass("fleshpound", class);
	set_subclass_var(subclass, "name", "Fleshpound");
	set_subclass_var(subclass, "model", create_model("models/player/rz_fleshpound/rz_fleshpound.mdl"));

	new Props:props = get_subclass_var(subclass, "props");
	set_props_var(props, "health", 2000);
	set_props_var(props, "speed", 260);
	set_props_var(props, "gravity", 1.0);
	//set_props_var(props, "weapons_interaction", false);
	//set_props_var(props, "render_fx", kRenderFxDistort);

	new Weapon:melee = get_subclass_var(subclass, "melee");
	set_weapon_var(melee, "view_model", create_model("models/player/rz_fleshpound/hand.mdl"));
	/*set_weapon_var(melee, "always_damage", 1000);
	set_weapon_var(melee, "gibs", true);*/
}
