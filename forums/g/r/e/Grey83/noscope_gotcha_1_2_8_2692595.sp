#pragma semicolon 1
#pragma newdecls required

#include <sdktools_sound>
#include <sdktools_stringtables>
#include <multicolors>

static const char TAG[] = "☆";	// Example: "{darkred}[www.FrmAkDaG.Com] "

int
	kills[MAXPLAYERS+1],
	headshots[MAXPLAYERS+1];
bool
	bMsg,
	bAllSnipers,
	bSounds,
	bCSGO;
char
	sPathKill[PLATFORM_MAX_PATH],
	sPathHs[PLATFORM_MAX_PATH],
	sSndKill[PLATFORM_MAX_PATH],
	sSndHs[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "[AWP] No-Scope Detector",
	author		= "Ak0 (improved by Grey83 & onehand)",
	description	= "Awp Maping No-Scope Detector",
	version		= "1.2.8",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}

public void OnPluginStart()
{
	if(GetEngineVersion() == Engine_CSGO) bCSGO = true;
	else if(GetEngineVersion() != Engine_CSS)
		SetFailState("Plugin supports CSS and CS:GO only.");

	LoadTranslations("core.phrases");
	LoadTranslations("noscope_gotcha.phrases");

	ConVar cvar;
	cvar = CreateConVar("sm_noscope_enable", "1", "0/1 - Disable/Enable messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Msg);
	bMsg = cvar.BoolValue;

	cvar = CreateConVar("sm_noscope_allsnipers", "0", "0/1 - Disable/Enable no-scope detection for all weapons w/o crosshairs (g3sg1, scar20, sg550)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_AllSnipers);
	bAllSnipers = cvar.BoolValue;

	cvar = CreateConVar("sm_noscope_sounds", "1", "0/1 - Disable/Enable quake announcer sounds on a no-scope kill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Sounds);
	bSounds = cvar.BoolValue;

	cvar = CreateConVar("sm_noscope_snd_kill", "quake/ultrakill.mp3", "Sound for common kill (empty string = disabled)", FCVAR_PRINTABLEONLY, true);
	cvar.AddChangeHook(CVarChanged_Kill);
	cvar.GetString(sPathKill, sizeof(sPathKill));

	cvar = CreateConVar("sm_noscope_snd_hs", "quake/godlike.mp3", "Sound for headshot (empty string = disabled)", FCVAR_PRINTABLEONLY, true);
	cvar.AddChangeHook(CVarChanged_Hs);
	cvar.GetString(sPathHs, sizeof(sPathHs));

	RegConsoleCmd("noscopes", Cmd_NoScopes, "Shows number NoScope kills and HS");

	HookEvent("player_death", OnPlayerDeath);
}

public void CVarChanged_Msg(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bMsg = cvar.BoolValue;
}

public void CVarChanged_AllSnipers(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bAllSnipers = cvar.BoolValue;
}

public void CVarChanged_Sounds(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSounds = cvar.BoolValue;
}

public void CVarChanged_Kill(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	cvar.GetString(sPathKill, sizeof(sPathKill));

	int len = strlen(sPathKill) - 4;
	if(len < 4 || strcmp(sPathKill[len], ".mp3", false) && strcmp(sPathKill[len], ".wav", false))
		sPathKill[0] = 0;
}

public void CVarChanged_Hs(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	cvar.GetString(sPathHs, sizeof(sPathHs));

	int len = strlen(sPathHs) - 4;
	if(len < 1 || strcmp(sPathHs[len], ".mp3", false) && strcmp(sPathHs[len], ".wav", false))
		sPathHs[0] = 0;
}

public void OnMapStart()
{
	if(sPathKill[0])
	{
		FormatEx(sSndKill, sizeof(sSndKill), "sound/%s", sPathKill);
		AddFileToDownloadsTable(sSndKill);
		if(bCSGO)
		{
			FormatEx(sSndKill, sizeof(sSndKill), "*%s", sPathKill);
			AddToStringTable(FindStringTable("soundprecache"), sSndKill);
		}
		else
		{
			FormatEx(sSndKill, sizeof(sSndKill), "%s", sPathKill);
			PrecacheSound(sSndKill, true);
		}
	}

	if(!sPathHs[0])
	{
		if(!sPathKill[0]) return;
		else FormatEx(sPathHs, sizeof(sPathHs), sPathKill);
	}

	FormatEx(sSndHs, sizeof(sSndHs), "sound/%s", sPathHs);
	AddFileToDownloadsTable(sSndHs);
	if(bCSGO)
	{
		FormatEx(sSndHs, sizeof(sSndHs), "*%s", sPathHs);
		AddToStringTable(FindStringTable("soundprecache"), sSndHs);
	}
	else
	{
		FormatEx(sSndHs, sizeof(sSndHs), "%s", sPathHs);
		PrecacheSound(sSndHs, true);
	}
}

public void OnClientConnected(int client)
{
	kills[client] = headshots[client] = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	static int attacker, victim, fov;
	if(!IsClientValid((attacker = GetClientOfUserId(event.GetInt("attacker"))), false)
	|| !IsClientValid((victim = GetClientOfUserId(event.GetInt("userid")))))
		return;

	static char weapon[16];
	event.GetString("weapon", weapon, sizeof(weapon));
	if(weapon[0] && ((StrContains(weapon, "awp") != -1 || StrContains(weapon, bCSGO ? "ssg08" : "scout") != -1)
	|| (bAllSnipers && (StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, bCSGO ? "scar20" : "sg550") != -1)))
	&& ((fov = GetEntProp(attacker, Prop_Data, "m_iFOV")) <= 0 || fov == GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		kills[attacker]++;
		bool headshot;
		if((headshot = event.GetBool("headshot"))) headshots[attacker]++;

		if(bMsg)
		{
			static char attacker_name[MAX_NAME_LENGTH]/*, victim_name[MAX_NAME_LENGTH]*/;
			GetClientName(attacker, attacker_name, sizeof(attacker_name));
//			GetClientName(victim, victim_name, sizeof(victim_name));

//			CPrintToChatAll("%t", headshot ? "HS2All" : "Kill2All", TAG, attacker_name, victim_name, weapon);
			CPrintToChatAll("%t", headshot ? "HS2All" : "Kill2All", TAG, attacker_name);
			if(headshot) CPrintToChat(attacker, "%T", "HS", attacker, headshots[attacker]);

			CPrintToChat(attacker, "%T", "Kill", attacker, kills[attacker]);
		}

		if(!bSounds || !sSndKill[0] && (!headshot || !sSndHs[0])) return;

		if(!bCSGO) EmitSoundToAll(headshot && sSndHs[0] ? sSndHs : sSndKill);
		else for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) ClientCommand(i, "playgamesound %s", headshot ? sSndHs : sSndKill);
	}
}

public Action Cmd_NoScopes(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(!bMsg) ReplyToCommand(client, "[SM] %T", "No Access", client);
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
	return client && (allow_bots || !IsFakeClient(client));
}