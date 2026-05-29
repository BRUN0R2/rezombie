#include <amxmodx>
#include <rezombie>

new Subclass:ZombieSwarm;

public plugin_precache()
{
	register_plugin("Zombie: Swarm", "0.1.0", "BRUN0");

	new Class:class = RequireClass("zombie");
	new Subclass:subclass = ZombieSwarm = create_subclass("zombie_swarm", class);
	if (ZombieSwarm == Invalid_Subclass)
		set_fail_state("Zombie swarm subclass was not registered.");

	set_subclass_var(subclass, "name", "Zombie Swarm");

	new Props:props = get_subclass_var(subclass, "props");
	set_props_var(props, "health", 700);
	set_props_var(props, "speed", 260);
	set_props_var(props, "gravity", 0.9);
}
