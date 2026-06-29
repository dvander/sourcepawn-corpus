#include <sourcemod>

new bool:BlockConVarCheck;

new Handle:hcv_VotePassDelay = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[CSGO] Mapgroup workaround",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Fixes mapgroup random map bug",
	version = "1.0",
	url = "NULL"
};

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("VotePass"), Message_VotePass, false);
	
	HookConVarChange(FindConVar("nextlevel"), HCV_NextLevel);
	HookEvent("cs_win_panel_match", Event_CSWinPanelMatch, EventHookMode_PostNoCopy);
	
	BlockConVarCheck = true;
	
	hcv_VotePassDelay = FindConVar("sv_vote_command_delay");
}

public HCV_NextLevel(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(BlockConVarCheck)
		return;
	
	else if(!IsMapValid(newValue))
		return;
	new Handle:DP;
	
	CreateDataTimer(4.85, ChangeTheMap, DP, TIMER_FLAG_NO_MAPCHANGE);
	
	WritePackString(DP, newValue);
}

public Action:Event_CSWinPanelMatch(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	BlockConVarCheck = false;
}
public Action:Message_VotePass(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init) 
{
	new type = PbReadInt(msg, "vote_type");
	
	if(type != 1)
		return;
		
	new String:MapName[200];
	PbReadString(msg, "details_str", MapName, sizeof(MapName)); 
	
	new Handle:DP;
	
	CreateDataTimer(GetConVarFloat(hcv_VotePassDelay) - 0.15, ChangeTheMap, DP, TIMER_FLAG_NO_MAPCHANGE);
	
	WritePackString(DP, MapName);
}

public Action:ChangeTheMap(Handle:hTimer, Handle:DP)
{
	ResetPack(DP);
	
	new String:MapName[200];
	
	ReadPackString(DP, MapName, sizeof(MapName));
	
	ForceChangeLevel(MapName, "Vote pass");
}

public OnMapStart()
{
	BlockConVarCheck = true;
}

public OnMapEnd()
{
	BlockConVarCheck = false;
}