#pragma semicolon 1

#include <csgo_colors>

#pragma newdecls required
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

static const char PATRICLE[] = "particles/snow2020.pcf";

Handle
	g_hCookie;
int
	g_iAura[MAXPLAYERS+1] = {-1, ...};
bool
	bParticle,
	IsOffSnow[MAXPLAYERS+1],
	bIgnoreMap;

public Plugin myinfo = 
{
	name		= "Particle Snow 2020",
	version		= "1.2.0 (rewritten by Grey83)",
	description	= "Снег на сервер",
	author		= "FLASHER",
	url			= "discord: FLASHER#4704"
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_Start, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_Team);

	RegConsoleCmd("sm_snow", Cmd_Snow);

	g_hCookie = RegClientCookie("snow2020", "snow2020", CookieAccess_Private);

	LoadTranslations("snow2020.phrases");
}

public void OnClientCookiesCached(int iClient)
{
	char val[2];
	GetClientCookie(iClient, g_hCookie, val, sizeof(val));
	IsOffSnow[iClient] = val[0] && StringToInt(val);
	g_iAura[iClient] = -1;
}

public void OnMapStart()
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE) table = FindStringTable("ParticleEffectNames");
	bool bSave = LockStringTables(false);
	AddToStringTable(table, "snow2020");
	LockStringTables(bSave);

	bParticle = false;
	int iLength = strlen(PATRICLE) - 4;
	if(iLength < 0 || strcmp(PATRICLE[iLength], ".pcf", false))
	{
		LogError("Invalid particle file extension \"%s\"", PATRICLE);
		return;
	}

	if(StrContains(PATRICLE, "particles/"))
	{
		LogError("Invalid particle file \"%s\"(must start with \"particles/\")", PATRICLE);
		return;
	}

	if(!FileExists(PATRICLE))
	{
		LogError("File \"%s\" not found in server directory", PATRICLE);
		return;
	}

	PrecacheGeneric(PATRICLE, true);
	bParticle = true;

	AddFileToDownloadsTable("materials/sprites/zlo/snowflake.vmt");
	AddFileToDownloadsTable("materials/sprites/zlo/snowflake.vtf");

	AddFileToDownloadsTable(PATRICLE);
	
	bIgnoreMap = false;
	Handle hFile = OpenFile("addons/sourcemod/configs/snow_ignore.txt", "r", false, "GAME");
	if (hFile != null) {
		char mapname[128];
		char buffer[128];
		GetCurrentMap(mapname, 128);
		while (ReadFileLine(hFile, buffer, 128)) {
			TrimString(buffer);
			if (StrEqual(buffer, mapname, true)) {
				bIgnoreMap = true;
				break;
			}
		}
	}
	CloseHandle(hFile);
}

public void OnClientPutInServer(int client)
{
	CreateParticle(client);
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; ++i) if(IsClientInGame(i) && !IsFakeClient(i))
		CreateTimer(0.1, Timer_CreateParticle, GetClientUserId(i));
}

public void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client) CreateParticle(client);
}

public Action Cmd_Snow(int client, int args)
{
	if(!bParticle || bIgnoreMap || !client) return Plugin_Handled;

	if(IsOffSnow[client])
	{
		IsOffSnow[client] = false;
		CreateParticle(client);
		CGOPrintToChat(client, "%t", "SnowOn");
	}
	else
	{
		IsOffSnow[client] = true;
		KillParticle(client);
		CGOPrintToChat(client, "%t", "SnowOff");
	}
	return Plugin_Handled;
}

public Action Timer_CreateParticle(Handle timer, any client)
{
	if((client = GetClientOfUserId(client))) CreateParticle(client);
}

stock void CreateParticle(int client)
{
	if(!bParticle || IsOffSnow[client] || bIgnoreMap || !IsClientInGame(client)) return;

	KillParticle(client);
	int ent = CreateEntityByName("info_particle_system");
	if(ent == -1) return;

	static float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] -= 250;
	DispatchKeyValue(ent, "effect_name", "snow2020");
	if(!DispatchSpawn(ent)) return;

	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent);
	g_iAura[client] = EntIndexToEntRef(ent);
	AcceptEntityInput(ent, "Start", -1, -1, 0);

	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
}

public void PreThink(int client)
{
	int m_unEnt = EntRefToEntIndex(g_iAura[client]);
	if (!IsValidEntity(m_unEnt)) {
		SDKUnhook(client, SDKHook_PreThink, PreThink);
		return;
	}

	static float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] -= 250;
	TeleportEntity(m_unEnt, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action ShouldHide(int entity, int client)
{
	if(GetEdictFlags(entity) & FL_EDICT_ALWAYS) SetEdictFlags(entity,(GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	int m_unEnt = EntRefToEntIndex(g_iAura[client]);
	return entity == m_unEnt ? Plugin_Continue : Plugin_Handled; // показать или скрыть
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client)) return;

	static char val[2];
	FormatEx(val, sizeof(val), "%s", IsOffSnow[client] ? "1" : "0");
	SetClientCookie(client, g_hCookie, val);
	KillParticle(client);
}

public void KillParticle(int client)
{
	int iient = EntRefToEntIndex(g_iAura[client]);
	if (iient > 0) {
		SDKUnhook(client, SDKHook_PreThink, PreThink);
		AcceptEntityInput(g_iAura[client], "Stop", -1, -1, 0);
		AcceptEntityInput(g_iAura[client], "Kill", -1, -1, 0);
	}
	g_iAura[client] = -1;
}