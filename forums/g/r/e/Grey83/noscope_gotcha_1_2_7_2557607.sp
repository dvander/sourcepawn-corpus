#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <multicolors>

static const char TAG[] = "☆";		// Example: "{darkred}[www.FrmAkDaG.Com] "

int kills[MAXPLAYERS+1],
	headshots[MAXPLAYERS+1];
bool bEnabled,
	bAllSnipers,
	bSounds,
	bCSGO;

static const char	SOUND_ULTRAKILL_REL[]		= "*/quake/ultrakill.mp3",
					SOUND_ULTRAKILL_REL_CSS[]	= "quake/ultrakill.mp3",
					SOUND_ULTRAKILL[]			= "sound/quake/ultrakill.mp3",
					SOUND_GODLIKE_REL[]			= "*/quake/godlike.mp3",
					SOUND_GODLIKE_REL_CSS[]		= "quake/godlike.mp3",
					SOUND_GODLIKE[]				= "sound/quake/godlike.mp3";

public Plugin myinfo = 
{
	name		= "[AWP] No-Scope Detector",
	author		= "Ak0 (improved by Grey83 & onehand)",
	description	= "Awp Maping No-Scope Detector",
	version		= "1.2.7",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}


public void OnPluginStart()
{
	if(GetEngineVersion() == Engine_CSGO) bCSGO = true;
	else if(GetEngineVersion() != Engine_CSS)
		SetFailState("Plugin supports CSS and CS:GO only.");

	if(bCSGO)

	LoadTranslations("core.phrases");
	LoadTranslations("noscope_gotcha.phrases");

	ConVar CVar;
	(CVar = CreateConVar("sm_noscope_enable", "1", "0/1 - Disable/Enable messages", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Enabled);
	bEnabled = CVar.BoolValue;
	(CVar = CreateConVar("sm_noscope_allsnipers", "0", "0/1 - Disable/Enable no-scope detection for all weapons w/o crosshairs (g3sg1, scar20, sg550)", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_AllSnipers);
	bAllSnipers = CVar.BoolValue;
	(CVar = CreateConVar("sm_noscope_sounds", "1", "0/1 - Disable/Enable quake announcer sounds on a no-scope kill", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Sounds);
	bSounds = CVar.BoolValue;

	RegConsoleCmd("noscopes", Cmd_NoScopes, "Shows number NoScope kills and HS");

	HookEvent("player_death", OnPlayerDeath);
}

public void OnMapStart()
{
	if(bCSGO)
	{
		AddFileToDownloadsTable(SOUND_ULTRAKILL);
		AddToStringTable(FindStringTable("soundprecache"), SOUND_ULTRAKILL_REL);

		AddFileToDownloadsTable(SOUND_GODLIKE);
		AddToStringTable(FindStringTable("soundprecache"), SOUND_GODLIKE_REL);
	}
	else
	{
		PrecacheSound(SOUND_ULTRAKILL_REL_CSS, true);
		PrecacheSound(SOUND_GODLIKE_REL_CSS, true);
	}
}

public void CVarChanged_Enabled(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnabled = CVar.BoolValue;
}

public void CVarChanged_AllSnipers(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bAllSnipers = CVar.BoolValue;
}

public void CVarChanged_Sounds(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bSounds = CVar.BoolValue;
}

public void OnClientConnected(int client)
{
	kills[client] = headshots[client] = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	static int attacker, victim;
	if(!IsClientValid((attacker = GetClientOfUserId(event.GetInt("attacker"))), false)
	|| !IsClientValid((victim = GetClientOfUserId(event.GetInt("userid")))))
		return;

	static char weapon[16];
	event.GetString("weapon", weapon, sizeof(weapon));
	if(weapon[0] && ((StrContains(weapon, "awp") != -1 || StrContains(weapon, "scout") != -1 || StrContains(weapon, "ssg08") != -1)
	|| (bAllSnipers && (StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, "sg550") != -1 || StrContains(weapon, "scar20") != -1)))
	&& (GetEntProp(attacker, Prop_Data, "m_iFOV") <= 0 || GetEntProp(attacker, Prop_Data, "m_iFOV") == GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		kills[attacker]++;
		static bool headshot;
		if((headshot = event.GetBool("headshot"))) headshots[attacker]++;

		if(bEnabled)
		{
			static char attacker_name[MAX_NAME_LENGTH], victim_name[MAX_NAME_LENGTH];
			GetClientName(attacker, attacker_name, sizeof(attacker_name));
			GetClientName(victim, victim_name, sizeof(victim_name));

			CPrintToChatAll("%t", headshot ? "HS2All" : "Kill2All", TAG, attacker_name, victim_name, weapon);
			if(headshot) CPrintToChat(attacker, "%T", "HS", attacker, headshots[attacker]);

			CPrintToChat(attacker, "%T", "Kill", attacker, kills[attacker]);
		}

		if(bSounds)
		{
			if(bCSGO) playSound(headshot ? SOUND_GODLIKE_REL : SOUND_ULTRAKILL_REL);
			else EmitSoundToAll(headshot ? SOUND_GODLIKE_REL_CSS : SOUND_ULTRAKILL_REL_CSS);
		}
	}
}

public void playSound(const char[] filelocation)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) ClientCommand(i, "playgamesound %s", filelocation);
}

public Action Cmd_NoScopes(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(!bEnabled) ReplyToCommand(client, "[SM] %T", "No Access", client);
		else
		{
			CPrintToChat(client, "%T", "HS", client, headshots[client]);
			CPrintToChat(client, "%T", "Kill", client, kills[client]);
		}
	}
	return Plugin_Handled;
}

stock bool IsClientValid(int client, bool allow_bots = true)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && (allow_bots || !IsFakeClient(client));
}