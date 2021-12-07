#pragma semicolon 1

#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_stringtables>
#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR < 9
	#include <sdktools_entinput>
#else
	#include <sdktools_variant_t>
#endif

static const char
	PL_NAME[]	= "Server WH",
	PL_VER[]	= "1.0.2",

	MARK[]	="materials/sprites/wh_frame.vmt";
static const int
	MARK_CLR_T	= 0xff3f1f,
	MARK_CLR_CT	= 0x1f3fff;
static const float
	MARK_SIZE	= 0.5;	// размер меток

bool
	bLate,
	bAdmin[MAXPLAYERS+1],
	bVisible;
int
	iMode[2],
	iColorT,
	iColorCT,
	iFlags,
	iTeam[MAXPLAYERS+1],
	iMarkRef[MAXPLAYERS+1] = {-1, ...};

public Plugin myinfo =
{
	name	= PL_NAME,
	version = PL_VER,
	author	= "Grey83",
	url		= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_server_wh_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("sm_swh_mode", "3", "Show marks to the common players: 0 - don't show, 1 - to the Spec, 2 - to the dead allies, 4 - to the dead enemies", _, true, _, true, 7.0);
	cvar.AddChangeHook(CVarChanged_CMode);
	ChangeVisibility(cvar, 0);

	cvar = CreateConVar("sm_swh_adm_mode", "7", "Show marks to the admins: 0 - don't show, 1 - to the Spec, 2 - to the dead allies, 4 - to the dead enemies", _, true, _, true, 7.0);
	cvar.AddChangeHook(CVarChanged_AMode);
	ChangeVisibility(cvar, 1);

	cvar = CreateConVar("sm_swh_access", "", "Flags for access to WH as admin (Root have access if string contain any correct flag)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Access);
	CVarChanged_Access(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_swh_color_t", "ff3f1f", "T mark color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = red", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_ColorT);
	SetColor(cvar, iColorT, MARK_CLR_T);

	cvar = CreateConVar("sm_swh_color_ct", "1f3fff", "CT mark color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = blue", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_ColorCT);
	SetColor(cvar, iColorCT, MARK_CLR_CT);

	HookEvent("player_team",	Event_Team);
	HookEvent("player_spawn",	Event_Spawn);
	HookEvent("player_death",	Event_Death);

	AutoExecConfig(true, "server_wh");

	if(!bLate) return;

	for(int i = 1, t; i <= MaxClients; i++) if(IsClientInGame(i) && !IsClientSourceTV(i) && (t = GetClientTeam(i)) > 1)
	{
		iTeam[i] = t;
		CreateMark(i);
	}
}

public void CVarChanged_CMode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	ChangeVisibility(cvar, 0);
}

public void CVarChanged_AMode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	ChangeVisibility(cvar, 1);
}

stock void ChangeVisibility(ConVar cvar, int type)
{
	bVisible = IsMarkNeeded();
	iMode[type] = cvar.IntValue;
	if(IsMarkNeeded() != bVisible) ProcessMarks();
}

public void CVarChanged_Access(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bVisible = IsMarkNeeded();
	char flags[24];
	cvar.GetString(flags, sizeof(flags));
	iFlags = ReadFlagString(flags);
	if(iFlags) iFlags |= ADMFLAG_ROOT;
	if(IsMarkNeeded() != bVisible) ProcessMarks();
	for(int i = 1; i <= MaxClients; i++)
		bAdmin[i] = iFlags && IsClientInGame(i) && !IsFakeClient(i) && iFlags & GetUserFlagBits(i);
}

stock void ProcessMarks()
{
	if(bVisible) OnPluginEnd();
	else for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsClientSourceTV(i)) CreateMark(i);
}

public void CVarChanged_ColorT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, iColorT, MARK_CLR_T);
	if(IsMarkNeeded()) for(int i = 1; i <= MaxClients; i++) if(IsMarkExist(i) && GetClientTeam(i) == 2) SetMarkColor(i);
}

public void CVarChanged_ColorCT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, iColorCT, MARK_CLR_CT);
	if(IsMarkNeeded()) for(int i = 1; i <= MaxClients; i++) if(IsMarkExist(i) && GetClientTeam(i) == 3) SetMarkColor(i);
}

stock bool IsMarkNeeded()
{
	return iMode[0] || iMode[1] && iFlags;
}

stock void SetColor(ConVar cvar, int& color, int def_clr)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;	// чтобы проверялось максимум 7 первых символов

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{	// не HEX-число
			color = def_clr;
			LogError("HEX color '%s' isn't valid!\nHUD color is 0x%x (%d %d %d)!\n", clr, color, (color & 0xFF0000) >> 16, (color & 0xFF00) >> 8, color & 0xFF);
			return;
		}
		i++;
	}

	clr[6] = 0;
	if(i == 3)	// короткая форма => полная форма
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	if(i != 6) color = def_clr;	// невалидный цвет
	else StringToIntEx(clr, color , 16);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) RemoveMark(i);
}

public void OnMapStart()
{
	AddFileToDownloadsTable(MARK);
	static char buffer[PLATFORM_MAX_PATH];
	if(!buffer[0])
	{
		buffer = MARK;
		ReplaceString(buffer, sizeof(buffer), ".vmt", ".vtf");
	}
	AddFileToDownloadsTable(buffer);
	PrecacheModel(MARK, true);
}

public void OnClientPostAdminCheck(int client)
{
	bAdmin[client] = iFlags && !IsFakeClient(client) && iFlags & GetUserFlagBits(client);
}

public void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	static int client, team;
	if(!(client = GetClientOfUserId(event.GetInt("userid"))))
		return;

	iTeam[client] = (team = event.GetInt("team")) < 2 ? 0 : team;
	if(team < 2)
	{
		RemoveMark(client);
		return;
	}

	if(!IsMarkExist(client))
		CreateMark(client);
	else if(team != event.GetInt("oldteam"))
	{
		SetMarkColor(client);
		SDKUnhook(GetMarkId(client), SDKHook_SetTransmit, iTeam[client] == 3 ? Hook_TransmitT : Hook_TransmitCT);
		SDKHook(GetMarkId(client), SDKHook_SetTransmit, iTeam[client] == 2 ? Hook_TransmitT : Hook_TransmitCT);
	}
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if((client = GetClientOfUserId(event.GetInt("userid")))) CreateMark(client);
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if((client = GetClientOfUserId(event.GetInt("userid")))) RemoveMark(client);
}

public void OnClientDisconnect(int client)
{
	bAdmin[client] = false;
	iTeam[client] = 0;
	RemoveMark(client);
}

stock void CreateMark(int client)
{
	CreateTimer(0.2, Timer_Mark, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Mark(Handle timer, any client)
{
	if(!IsMarkNeeded() || !(client = GetClientOfUserId(client)) || !iTeam[client] || IsMarkExist(client)
	|| !IsPlayerAlive(client))
		return Plugin_Stop;

	static int ent;
	if((ent = CreateEntityByName("env_sprite")) == -1)
	{
		PrintToServer("Can't create entity 'env_sprite'!");
		return Plugin_Stop;
	}

	static float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 35;
	DispatchKeyValueVector(ent, "origin", pos);
	DispatchKeyValue(ent, "model", MARK[10]);
	DispatchKeyValue(ent, "classname", "wh_mark");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchKeyValueFloat(ent, "scale", MARK_SIZE);
	DispatchKeyValue(ent, "rendermode", "5");
	if(!DispatchSpawn(ent))
	{
		PrintToServer("Can't spawn entity 'env_sprite' (%i)!", ent);
		return Plugin_Stop;
	}

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);

	iMarkRef[client] = EntIndexToEntRef(ent);
	SetMarkColor(client);
	SDKHook(ent, SDKHook_SetTransmit, iTeam[client] == 2 ? Hook_TransmitT : Hook_TransmitCT);
	return Plugin_Stop;
}

public Action Hook_TransmitT(int entity, int client)
{
	return CanSee(client, 2) ? Plugin_Continue : Plugin_Handled;
}

public Action Hook_TransmitCT(int entity, int client)
{
	return CanSee(client, 3) ? Plugin_Continue : Plugin_Handled;
}

stock bool CanSee(int client, int team)
{
	return  IsVisible(client, 1) && !iTeam[client] || (!IsPlayerAlive(client)
		&& (IsVisible(client, 2) && iTeam[client] == team
		||  IsVisible(client, 4) && iTeam[client] == 5-team));
}

stock bool IsVisible(int client, int type)
{
	return (iMode[0] & type) || bAdmin[client] && (iMode[1] & type);
}

stock void SetMarkColor(const int client)
{
	static int clr;
	clr = iTeam[client] == 2 ? iColorT : iColorCT;

	SetVariantInt(((clr & 0xFF0000) >> 16));
	AcceptEntityInput(iMarkRef[client], "ColorRedValue");
	SetVariantInt(((clr & 0xFF00) >> 8));
	AcceptEntityInput(iMarkRef[client], "ColorGreenValue");
	SetVariantInt((clr & 0xFF));
	AcceptEntityInput(iMarkRef[client], "ColorBlueValue");
}

stock void RemoveMark(const int client)
{
	if(IsMarkExist(client)) AcceptEntityInput(iMarkRef[client], "Kill");
	iMarkRef[client] = -1;
}

stock bool IsMarkExist(int client)
{
	return iMarkRef[client] != -1 && GetMarkId(client) != -1;
}

stock int GetMarkId(int client)
{
	return EntRefToEntIndex(iMarkRef[client]);
}