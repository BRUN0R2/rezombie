#include <amxmodx>
#include <reapi>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie/api/Players>

#pragma semicolon 1
#pragma compress 1

const SCOREBOARD_CLASS_ID = 0;

enum _:ScoreInfoArg
{
	ScoreInfoArgPlayer = 1,
	ScoreInfoArgFrags,
	ScoreInfoArgDeaths,
	ScoreInfoArgClass,
	ScoreInfoArgTeam
};

enum _:ScoreboardClientTeam
{
	ScoreboardClientTeamUnassigned = 0,
	ScoreboardClientTeamCounterTerrorist,
	ScoreboardClientTeamTerrorist,
	ScoreboardClientTeamSpectator
};

new ScoreInfoMessageId;
new bool:ScoreboardSyncing;

public plugin_init()
{
	register_plugin("HUD: Scoreboard", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	ScoreInfoMessageId = get_user_msgid("ScoreInfo");
	if (!ScoreInfoMessageId)
		set_fail_state("Scoreboard could not find ScoreInfo user message.");

	register_message(ScoreInfoMessageId, "OnScoreInfo");
}

public OnScoreInfo(messageId, destination, receiver)
{
	#pragma unused messageId
	#pragma unused destination
	#pragma unused receiver

	if (ScoreboardSyncing)
		return PLUGIN_CONTINUE;

	new TeamName:gameTeam = TeamName:get_msg_arg_int(ScoreInfoArgTeam);
	set_msg_arg_int(ScoreInfoArgTeam, ARG_SHORT, GetScoreboardClientTeam(gameTeam));
	return PLUGIN_CONTINUE;
}

public @change_class_post(id, Class:class, attacker)
{
	#pragma unused class
	#pragma unused attacker

	if (!is_user_connected(id))
		return;

	SyncPlayerScoreInfo(id);
}

stock SyncPlayerScoreInfo(id)
{
	ScoreboardSyncing = true;
	message_begin(MSG_ALL, ScoreInfoMessageId);
	write_byte(id);
	write_short(get_user_frags(id));
	write_short(get_member(id, m_iDeaths));
	write_short(SCOREBOARD_CLASS_ID);
	write_short(GetScoreboardClientTeam(TeamName:get_member(id, m_iTeam)));
	message_end();
	ScoreboardSyncing = false;
}

stock GetScoreboardClientTeam(TeamName:team)
{
	switch (team)
	{
		case TEAM_CT:
			return ScoreboardClientTeamCounterTerrorist;
		case TEAM_TERRORIST:
			return ScoreboardClientTeamTerrorist;
		case TEAM_SPECTATOR:
			return ScoreboardClientTeamSpectator;
	}

	return ScoreboardClientTeamUnassigned;
}
