#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.0";

public Plugin:myinfo = 
{
	name = "Breaking Point",
	author = "Eyal282",
	description = "When both teams have equal scores on the final round, increases the max rounds by 2.",
	version = PLUGIN_VERSION,
	url = "None."
}

new Handle:hcv_Enabled = INVALID_HANDLE;
new Handle:hcv_MaxRounds = INVALID_HANDLE;

new CurrentMaxRounds, RealMaxRounds;

new bool:ChangeBack;
public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	hcv_Enabled = CreateConVar("breaking_point_enabled", "1", "Set to 1 to enable the breaking point plugin, 0 to disable", FCVAR_NOTIFY);
	
	SetConVarString(CreateConVar("breaking_point_version", PLUGIN_VERSION), PLUGIN_VERSION);
	
	HookConVarChange(hcv_MaxRounds = FindConVar("mp_maxrounds"), cvChange_MaxRounds);
	
	ChangeBack = true;
	
	GetMaxRounds();
}

public OnMapEnd()
{
	if(ChangeBack)
		SetConVarInt(hcv_MaxRounds, RealMaxRounds);
}

public cvChange_MaxRounds(Handle:convar, String:oldValue[], String:newValue[])
{
	new nextValue = StringToInt(newValue);
	if(nextValue != CurrentMaxRounds)
	{
		ChangeBack = true;
		GetMaxRounds();
	}
}

public GetMaxRounds()
{
	if(!GetConVarBool(hcv_Enabled))
	{
		ChangeBack = false;
		return;
	}
	RealMaxRounds = GetConVarInt(hcv_MaxRounds);
	CurrentMaxRounds = RealMaxRounds;
}
public Action:Event_RoundEnd(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new TerrorScore = GetTeamScore(CS_TEAM_T);
	new CTScore = GetTeamScore(CS_TEAM_CT);
	
	if(TerrorScore + CTScore + 1 == CurrentMaxRounds && TerrorScore == CTScore) // Final Round is up ahead and both teams have equal scores
	{
		CurrentMaxRounds += 2;
		
		SetConVarInt(hcv_MaxRounds, CurrentMaxRounds);
		
		PrintToChatAll("\x05Breaking point!\x04 To win the match you need to win 2 more rounds!");
	}
}