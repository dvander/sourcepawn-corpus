#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colorvariables>

public Plugin myinfo = 
{
	name = "[CSGO] NOSCOPE ROUND", 
	author = "OneT0uch", 
	description = "NoScope round every x rounds", 
	version = "1.1", 
	url = "http://steamcommunity.com/id/OneT0uch/"
};

ConVar g_cvInterval;
ConVar g_cvPathToSound;
ConVar g_cvEnableSound;
ConVar g_cvEnableText;
ConVar g_cvWarmup;
int g_nb_round;
int m_flNextSecondaryAttack = -1;
bool isNoscopeRound;
public OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
	
	g_cvPathToSound = CreateConVar("noscope_sound_path", "noscope/noscope.mp3", "Path of the sound played when Noscope round");
	g_cvEnableSound = CreateConVar("noscope_sound_enabled", "1", "Enable (1)/Disable (0) the sound played when Noscope round");
	g_cvEnableText = CreateConVar("noscope_message_enabled", "1", "Enable (1)/Disable (0) the alert message when Noscope round");
	g_cvWarmup = CreateConVar("noscope_warmup_enabled", "0", "Enable (1)/Disable (0) the NoScope round during warmup");
	g_cvInterval = CreateConVar("noscope_interval", "3", "Set number of rounds between an unscope round", FCVAR_NOTIFY, true, 0.0);
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	HookEvent("round_prestart", OnPreRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	char soundBase[PLATFORM_MAX_PATH] = "sound/";
	char soundpath[PLATFORM_MAX_PATH];
	GetConVarString(g_cvPathToSound, soundpath, sizeof(soundpath));
	StrCat(soundBase, sizeof(soundBase), soundpath)
	PrecacheSound(soundBase, true);
	AddFileToDownloadsTable(soundBase);
}
public OnMapStart() {
	g_nb_round = -1;
}
public OnPreRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isNoscopeRound = false;
	if (GameRules_GetProp("m_bWarmupPeriod") == 1 && !g_cvWarmup.BoolValue) {
		if(g_cvInterval.IntValue == 0)CPrintToChatAll("{darkred} NOSCOPE DISABLE DURING WARMUP");
		return false;
	} 
	g_nb_round++;
	if (g_nb_round == g_cvInterval.IntValue)
	{
		isNoscopeRound = true;
		g_nb_round = -1;
	} 
	return true;
}
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	if(isNoscopeRound) {
		if (IsClientInGame(client)) {
			if (g_cvEnableText.BoolValue && g_cvInterval.IntValue > 0)CPrintToChat(client, "{green} NOSCOPE ROUND");PrintCenterTextAll("NOSCOPE ROUND");

			char commandBase[PLATFORM_MAX_PATH] = "play *";
			char soundpath[PLATFORM_MAX_PATH];
			GetConVarString(g_cvPathToSound, soundpath, sizeof(soundpath));
			StrCat(commandBase, sizeof(commandBase), soundpath);
			if (g_cvEnableSound.BoolValue && g_cvInterval.IntValue > 0)ClientCommand(client, commandBase);
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		}
	} else {
		if (IsClientInGame(client))SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	}
}


public Action:OnPreThink(client)
{
	SetNoScope(GetPlayerWeaponSlot(client, 0));
}

stock SetNoScope(weapon)
{
	if (IsValidEdict(weapon))
	{
		decl String:classname[MAX_NAME_LENGTH];
		if (GetEdictClassname(weapon, classname, sizeof(classname))
			 || StrEqual(classname[7], "ssg08") || StrEqual(classname[7], "aug")
			 || StrEqual(classname[7], "sg550") || StrEqual(classname[7], "sg552")
			 || StrEqual(classname[7], "sg556") || StrEqual(classname[7], "awp")
			 || StrEqual(classname[7], "scar20") || StrEqual(classname[7], "g3sg1"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 1.0);
		}
	}
}
