#pragma semicolon 1
#pragma newdecls required

#include <sdktools_sound>
#include <sdktools_stringtables>

static const char CLR[][][] =
{//		name		CSGO		CSS			CSSv34
	{"{WHITE}",		"\x01",	"\x07FFFFFF",	""},
	{"{DEFAULT}",	"\x01",	"\x01",			"\x01"},
	{"{RED}",		"\x02",	"\x07FF0000",	""},
	{"{TEAM}",		"\x03",	"\x03",			"\x03"},
	{"{GREEN}",		"\x04",	"\x04",			"\x04"},
	{"{LIME}",		"\x05",	"\x05",			""},
	{"{LIGHTGREEN}","\x06",	"\x0799FF99",	""},
	{"{LIGHTRED}",	"\x07",	"\x07FF4040",	""},
	{"{GRAY}",		"\x08",	"\x07CCCCCC",	""},
	{"{LIGHTOLIVE}","\x09",	"\x07FFBD6B",	""},
	{"{OLIVE}",		"\x10",	"\x07FA8B00",	""},
	{"{BLUEGREY}",	"\x0A",	"\x076699CC",	""},
	{"{LIGHTBLUE}",	"\x0B",	"\x0799CCFF",	""},
	{"{BLUE}",		"\x0C",	"\x073D46FF",	""},
	{"{PURPLE}",	"\x0E",	"\x07FA00FA",	""},
	{"{LIGHTRED2}",	"\x0F",	"\x07FF8080",	""}
};

enum
{
	E_Unknown,
	E_CSGO,
	E_CSS,
	E_Old
};

int
	iEngine,
	iKills[MAXPLAYERS+1],
	iHS[MAXPLAYERS+1];
bool
	bProto,
	bMsg,
	bAllSnipers,
	bSounds;
char
	sPathKill[PLATFORM_MAX_PATH],
	sPathHs[PLATFORM_MAX_PATH],
	sSndKill[PLATFORM_MAX_PATH],
	sSndHs[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "NoScope Detector",
	author		= "Ak0 (rewritten by Grey83)",
	version		= "1.3.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}

public void OnPluginStart()
{
	if(!HookEventEx("player_death", Event_Death)) SetFailState("Can't hook event 'player_death'!");

	switch(GetEngineVersion())
	{
		case Engine_CSGO:
			iEngine = E_CSGO;
		case Engine_CSS:
			iEngine = E_CSS;
		case Engine_SourceSDK2006:
			iEngine = E_Old;
		default: SetFailState("Can't work with this game!");
	}

	bProto = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;

	LoadTranslations("core.phrases");
	LoadTranslations("noscope_detector.phrases");

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

	cvar = CreateConVar("sm_noscope_snd_kill", "quake/ultrakill.mp3", "Sound for common kill (empty string = disabled)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Kill);
	cvar.GetString(sPathKill, sizeof(sPathKill));

	cvar = CreateConVar("sm_noscope_snd_hs", "quake/godlike.mp3", "Sound for headshot (empty string = disabled)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Hs);
	cvar.GetString(sPathHs, sizeof(sPathHs));

	RegConsoleCmd("noscopes", Cmd_NoScopes, "Shows number NoScope iKills and HS");
	RegConsoleCmd("ns", Cmd_NoScopes, "Shows number NoScope iKills and HS");
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

stock void AddKillSound()
{
	FormatEx(sSndKill, sizeof(sSndKill), "sound/%s", sPathKill);
	AddFileToDownloadsTable(sSndKill);
	if(iEngine == E_CSGO)
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

stock void AddHSSound()
{
	FormatEx(sSndHs, sizeof(sSndHs), "sound/%s", sPathHs);
	AddFileToDownloadsTable(sSndHs);
	if(iEngine == E_CSGO)
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

public void OnMapStart()
{
	if(sPathKill[0]) AddKillSound();

	if(!sPathHs[0])
	{
		if(!sPathKill[0]) return;
		else FormatEx(sPathHs, sizeof(sPathHs), sPathKill);
	}

	AddHSSound();
}

public void OnClientConnected(int client)
{
	iKills[client] = iHS[client] = 0;
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	static int attacker, wpn, i, clients[MAXPLAYERS];
	static char weapon[8];
	if(!IsClientValid((attacker = GetClientOfUserId(event.GetInt("attacker"))), false)
	|| !IsClientValid(GetClientOfUserId(event.GetInt("userid"))))
		return;

	event.GetString("weapon", weapon, sizeof(weapon));
	if(weapon[0] && ((!strcmp(weapon, "awp") || !strcmp(weapon, iEngine == E_CSGO ? "ssg08" : "scout"))
	|| (bAllSnipers && (!strcmp(weapon, "g3sg1") || !strcmp(weapon, iEngine == E_CSGO ? "scar20" : "sg550"))))
	&& (wpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")) != -1 && !GetEntProp(wpn, Prop_Send, "m_weaponMode"))
	{
		iKills[attacker]++;
		bool headshot;
		if((headshot = event.GetBool("headshot"))) iHS[attacker]++;

		if(bMsg)
		{
			static char attacker_name[MAX_NAME_LENGTH];
			GetClientName(attacker, attacker_name, sizeof(attacker_name));
			PrintToChatAllClr("%t%t", "TAG", headshot ? "HS2All" : "Kill2All", attacker_name);
			PrintToChatClr(attacker, "%t", "Progress", iHS[attacker], iKills[attacker]);
		}

		if(!bSounds || !sSndKill[0] && (!headshot || !sSndHs[0])) return;

		for(i = 1, wpn = 0; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) clients[wpn++] = i;
		if(wpn) EmitSound(clients, wpn, headshot && sSndHs[0] ? sSndHs : sSndKill, attacker);
	}
}

stock bool IsClientValid(int client, bool allow_bots = true)
{
	return client && (allow_bots || !IsFakeClient(client));
}

public Action Cmd_NoScopes(int client, int args)
{
	if(client && IsClientInGame(client))
	{
		if(!bMsg) ReplyToCommand(client, "[SM] %T", "No Access", client);
		else PrintToChatClr(client, "%t", "Progress", iHS[client], iKills[client]);
	}
	return Plugin_Handled;
}

stock void PrintToChatAllClr(const char[] msg, any ...)
{
	static char buffer[PLATFORM_MAX_PATH];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		VFormat(buffer, sizeof(buffer), msg, 2);
		PrintToChatClr(i, "%s", buffer);
	}
}

stock void PrintToChatClr(int client, const char[] msg, any ...)
{
	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(!hBuffer) return;

	SetGlobalTransTarget(client);
	static char buffer[PLATFORM_MAX_PATH], new_msg[PLATFORM_MAX_PATH];
	if(iEngine != E_Unknown) FormatEx(buffer, sizeof(buffer), "%s\x01%s", iEngine == E_CSGO ? " " : "", msg);
	VFormat(new_msg, sizeof(new_msg), buffer, 3);

	if(iEngine) for(int i; i < 16; i++) ReplaceString(new_msg, sizeof(new_msg), CLR[i][0], CLR[i][iEngine]);
	else for(int i; i < 16; i++) ReplaceString(new_msg, sizeof(new_msg), CLR[i][0], NULL_STRING);

	if(bProto)
	{
		PbSetInt(hBuffer, "ent_idx", 0);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", new_msg);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		BfWriteByte(hBuffer, 0);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, new_msg);
	}
	EndMessage();
}