#include <sourcemod>
#include <cstrike>

public Plugin myinfo = 
{
	name = "No Draws",
	description = "No Draws",
	version = "1.0.0"
};

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason) 
{ 
	if(reason == CSRoundEnd_Draw) 
	{ 
		return Plugin_Handled; 
	}
	return Plugin_Continue; 
}