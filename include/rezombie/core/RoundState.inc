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

enum EndRoundEvent
{
	EndRoundEventNone = 0,
	EndRoundEventWarmupEnd,
	EndRoundEventGameCommence,
	EndRoundEventGameRestart,
	EndRoundEventGameOver,
	EndRoundEventHumansWin,
	EndRoundEventZombiesWin,
	EndRoundEventEndDraw
};
