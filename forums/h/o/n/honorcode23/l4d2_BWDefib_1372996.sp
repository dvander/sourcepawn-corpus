#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:h_Enabled
new Handle:h_RemainingIncaps
new Handle:h_Health
new Handle:h_TempHealth
new Handle:sdkRevive = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D2] Black and White on Defib",
	author = "Crimson_Fox",
	description = "Defibed survivors are brought back to life with no incaps remaining.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1012022"
}

public OnPluginStart()
{
	//Look up what game we're running,
	decl String:game[16]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	CreateConVar("bwdefib_version", PLUGIN_VERSION, "The version of Black and White on Defib.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	h_Enabled = CreateConVar("l4d2_bwdefib", "1", "Is Black and White on Defib enabled?", FCVAR_PLUGIN)
	h_RemainingIncaps = CreateConVar("l4d2_bwdefib_incaps", "0", "Number of remaining incaps with which a defibed survivor is brought back.", FCVAR_PLUGIN)	
	h_Health = CreateConVar("l4d2_bwdefib_health", "1.0", "Amount of health with which a defibed survivor is brought back.", FCVAR_PLUGIN, true, 1.0, true, 100.0)
	h_TempHealth = CreateConVar("l4d2_bwdefib_temphealth", "30.0", "Amount of temporary health with which a defibed survivor is brought back.", FCVAR_PLUGIN, true, 0.0, true, 100.0)
	AutoExecConfig(true, "l4d2_bwdefib")
	HookEvent("defibrillator_used", Event_PlayerDefibed)
	
	new Handle:config = LoadGameConfigFile("l4d2bwdefib");
	if(config == INVALID_HANDLE)
	{
		SetFailState("Unable to find the gamedata file, check that it is installed correctly!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTerrorPlayer_OnRevived");
	sdkRevive = EndPrepSDKCall();
	if(sdkRevive == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer::OnRevived(void)\" signature, check the file version!");
	}
	CloseHandle(config);
}

//When a player is defibed,
public Action:Event_PlayerDefibed(Handle:event, const String:name[], bool:dontBroadcast)
{
	//and the plugin is enabled,
	if (GetConVarInt(h_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "subject"))
		
		BlackAndWhite(client);
	}
	return Plugin_Continue
}

//Used to set temp health, written by TheDanner.
SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime())
	new Float:newOverheal = hp * 1.0 //prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal)
}

stock BlackAndWhite(target)
{
	if(target > 0 && IsValidEntity(target) && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
	{
		SetEntProp(target, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count"))-1);
		SetEntProp(target, Prop_Send, "m_isIncapacitated", 1);
		SDKCall(sdkRevive, target);
		SetEntityHealth(target, GetConVarInt(h_Health));
		SetTempHealth(target, GetConVarInt(h_TempHealth));
	}
}