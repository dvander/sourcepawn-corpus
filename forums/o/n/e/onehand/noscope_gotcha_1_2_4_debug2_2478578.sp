#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>

static char TAG[] = "☆";		// Example: "{darkred}[www.FrmAkDaG.Com] "

int kills[MAXPLAYERS+1], headshots[MAXPLAYERS+1];
bool enabled, debugmsg, allcsgo;

#define SOUND_ULTRAKILL_REL "*/quake/ultrakill.mp3"
#define SOUND_ULTRAKILL "sound/quake/ultrakill.mp3"
#define SOUND_GODLIKE_REL "*/quake/godlike.mp3"
#define SOUND_GODLIKE "sound/quake/godlike.mp3"

public Plugin myinfo = 
{
	name		= "[AWP] No-Scope Detector",
	author		= "Ak0 (improved by Grey83 & onehand)",
	description	= "Awp Maping No-Scope Detector",
	version		= "1.2.3_debug2",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) SetFailState("Plugin supports CSS and CS:GO only.");

	LoadTranslations("core.phrases");
	LoadTranslations("noscope_gotcha.phrases");

	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_noscope_enable", "1", "0/1 - Disable/Enable messages", FCVAR_NOTIFY, true, 0.0, true, 1.0)), CVarChange);
	enabled = CVar.BoolValue;
	HookConVarChange((CVar = CreateConVar("sm_noscope_debug", "1", "0/1 - Disable/Enable debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0)), CVarChangeDebug);
	debugmsg = CVar.BoolValue;
	HookConVarChange((CVar = CreateConVar("sm_noscope_allcsgoguns", "0", "0/1 - Disable/Enable no-scope detection for all CS:GO weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0)), CVarChangeCsgo);
	allcsgo = CVar.BoolValue;

	RegConsoleCmd("noscopes", Cmd_NoScopes, "Shows number NoScope kills and HS");

	HookEvent("player_death", OnPlayerDeath);
}

public void OnMapStart()
{
	AddFileToDownloadsTable(SOUND_ULTRAKILL);
	FakePrecacheSound(SOUND_ULTRAKILL_REL);
	
	AddFileToDownloadsTable(SOUND_GODLIKE);
	FakePrecacheSound(SOUND_GODLIKE_REL);
}

public void CVarChange(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	enabled = CVar.BoolValue;
}

public void CVarChangeDebug(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	debugmsg = CVar.BoolValue;
}

public void CVarChangeCsgo(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	allcsgo = CVar.BoolValue;
}

public void OnClientConnected(int client)
{
	kills[client] = headshots[client] = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(debugmsg) PrintToServer("	Attacker: %i", attacker);
	if(!(0 < attacker <= MaxClients && IsClientInGame(attacker))) return;

	char weapon[16];
	event.GetString("weapon", weapon, sizeof(weapon));
	ReplaceString(weapon, 16, "weapon_", "");
	if(debugmsg) PrintToServer("	Weapon: %s\n	FOV: %i", weapon, GetEntProp(attacker, Prop_Data, "m_iFOV"));
	if(debugmsg) PrintToServer("	DefFOV: %i", GetEntProp(attacker, Prop_Data, "m_iDefaultFOV"));

	if(((StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1) ||
		(allcsgo && (StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, "scar20") != -1))) &&
		(GetEntProp(attacker, Prop_Data, "m_iFOV") <= 0 || GetEntProp(attacker, Prop_Data, "m_iFOV") == GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(attacker, sName, sizeof(sName));
		kills[attacker]++;
		static bool bHS;
		if((bHS = event.GetBool("headshot"))) headshots[attacker]++;

		if(enabled)
		{
			if(bHS)
			{
				CPrintToChatAll("%t", "HS2All", TAG, TAG, TAG, sName, weapon, TAG, TAG, TAG);
				CPrintToChat(attacker, "%t", "HS", headshots[attacker]);
				playSound(SOUND_GODLIKE_REL);
			}
			else 
			{
				CPrintToChatAll("%t", "Kill2All", TAG, TAG, TAG, sName, weapon, TAG, TAG, TAG);
				playSound(SOUND_ULTRAKILL_REL);
			}
			CPrintToChat(attacker, "%t", "Kill", kills[attacker]);
		}
		if(debugmsg) PrintToServer("	Name: %s\n	Kills: %i\n HS: %s (%i)", sName, kills[attacker], bHS ? "true" : "false", headshots[attacker]);
	}
}

public Action Cmd_NoScopes(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(debugmsg) PrintToServer("	%L (%i)\n	Kills: %i\n HS: %i", client, kills[client], headshots[client]);
		if(!enabled) ReplyToCommand(client, "[SM] %t", "No Access");
		else
		{
			PrintToChat(client, "%t", "HS", headshots[client]);
			PrintToChat(client, "%t", "Kill", kills[client]);
		}
	}
	return Plugin_Handled;
}

public void playSound(const char[] filelocation)
{
	char target_soundPath[200];
		
	Format(target_soundPath, sizeof(target_soundPath), "playgamesound %s", filelocation);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			ClientCommand(i, target_soundPath);
		}
	}
}

stock void FakePrecacheSound( const char[] szPath )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}