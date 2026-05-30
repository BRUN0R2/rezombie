#if defined _RoundState_included
	#endinput
#endif

#define _RoundState_included

enum GameState
{
	GameStateWarmup = 0,
	GameStateNeedPlayers,
	GameStatePlaying,
	GameStateOver
};

enum RoundState
{
	RoundStateNone = 0,
	RoundStatePrepare,
	RoundStatePlaying,
	RoundStateTerminate
};

enum RoundEndReason
{
	RoundEndReasonNone = 0,
	RoundEndReasonHumans,
	RoundEndReasonZombies,
	RoundEndReasonDraw
};
