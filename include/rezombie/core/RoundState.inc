#if defined _RoundState_included
	#endinput
#endif

#define _RoundState_included

enum RoundState
{
	RoundStateFreezing = 0,
	RoundStateWaiting,
	RoundStatePreparing,
	RoundStatePlaying,
	RoundStateEnding
};

enum RoundEndReason
{
	RoundEndReasonNone = 0,
	RoundEndReasonHumans,
	RoundEndReasonZombies,
	RoundEndReasonDraw
};
