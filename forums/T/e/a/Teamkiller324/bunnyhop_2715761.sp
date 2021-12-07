/***************************************************************\
*	BunnyHop													*
*	Author: Soccerdude											*
*	Updated by Tk /id/Teamkiller32 to new syntax & declarations	*
*	Description: Gives players the ability to jump higher		*
\***************************************************************/
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// Declare offsets
int	VelocityOffset_0,
	VelocityOffset_1,
	BaseVelocityOffset;

// Declare convars
ConVar	hPush,
		hHeight;

Plugin	myinfo	=	{
	name			=	"BunnyHop",
	author			=	"Soccerdude, Updated by Tk /id/Teamkiller324",
	description		=	"Gives players the ability to jump higher",
	version			=	"1.0.2",
	url				=	"http://sourcemod.net/"
};

public void OnPluginStart()	{
	PrintToServer("----------------|         BunnyHop Loading        |---------------");
	//Hook Events
	HookEvent("player_jump",	PlayerJumpEvent);
	
	//Find Offsets
	if(VelocityOffset_0 == -1)
		SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
	if(VelocityOffset_1 == -1)
		SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
	if(BaseVelocityOffset == -1)
		SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
	
	//Velocity Offets
	VelocityOffset_0	=	FindSendPropInfo("CBasePlayer",	"m_vecVelocity[0]");
	VelocityOffset_1	=	FindSendPropInfo("CBasePlayer",	"m_vecVelocity[1]");
	BaseVelocityOffset	=	FindSendPropInfo("CBasePlayer",	"m_vecBaseVelocity");
	
	//Create CVars
	hPush		=	CreateConVar("bunnyhop_push",	"1.0",	"The forward push when you jump");
	hHeight		=	CreateConVar("bunnyhop_height",	"1.0",	"The upward push when you jump");
	
	//Create Config If It Doesn't Exist
	AutoExecConfig(true, "plugin.bunnyhop");
	
	//Public CVar
	CreateConVar("bunnyhop_version",		"1.0.2",	"[BunnyHop] Current version of this plugin",	FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	PrintToServer("----------------|         BunnyHop Loaded         |---------------");
}

Action PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)	{
	int index=GetClientOfUserId(GetEventInt(event,"userid"));
	float finalvec[3];
	finalvec[0]	=	GetEntDataFloat(index, VelocityOffset_0)*GetConVarFloat(hPush)/2.0;
	finalvec[1]	=	GetEntDataFloat(index, VelocityOffset_1)*GetConVarFloat(hPush)/2.0;
	finalvec[2]	=	GetConVarFloat(hHeight)*50.0;
	SetEntDataVector(index, BaseVelocityOffset, finalvec, true);
}