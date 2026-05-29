#include <amxmodx>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

new Subclass:Fleshpound;

public plugin_precache()
{
	register_plugin("Zombie: Fleshpound", "0.1.0", "BRUN0");

	new Class:class = RequireClass("zombie");
	new Model:model = create_model("rz_fleshpound");
	new Subclass:subclass = Fleshpound = create_subclass("fleshpound", class);
	if (Fleshpound == Invalid_Subclass)
		set_fail_state("Fleshpound subclass was not registered.");

	set_subclass_var(subclass, "name", "Fleshpound");
	set_subclass_var(subclass, "model", model);

	new Props:props = get_subclass_var(subclass, "props");
	set_props_var(props, "health", 700);
	set_props_var(props, "speed", 260);
	set_props_var(props, "gravity", 0.9);
}
