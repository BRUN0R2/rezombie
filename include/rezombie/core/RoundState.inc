#if defined _RoundState_included
	#endinput
#endif

#define _RoundState_included

enum RoundState
{
	RoundStateWaiting = 0,
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
