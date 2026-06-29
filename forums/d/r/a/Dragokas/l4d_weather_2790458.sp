#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D] Weather on Bloody Witch //^_^\\",
    author = "Dragokas",
    description = "Beautiful weather",
    version = "1.0",
    url = "https://dragokas.com/"
}

#define DEBUG 1
#define DEBUG_CHAT 0
#define ENABLE_SOUND 0

const int MAX_PARTICLE_LIGHTS = 10;

/*
	ChangeLog:
	
	1.0
	 - First release
*/

int g_iParticleLight = 0;

char g_sMap[64];

bool g_bRoundStart;
bool g_bFirstMap;

public void OnPluginStart()
{
	RegAdminCmd("sm_xmas", Cmd_XMAS, ADMFLAG_ROOT, "Xmas menu.");
	
	//HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
	
	HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", 		Event_RoundFreezeEnd);

	SetRandomSeed(GetTime());
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRoundStart)
		return;
	
	g_bRoundStart = true;
	
	char sBeamColor[32];
	
	switch (GetRandomInt(1, 5)) {
		case 1: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), 0, 0);
		case 2: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), 0);
		case 3: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, 0, GetRandomInt(200, 255));
		case 4: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), GetRandomInt(200, 255), 0);
		case 5: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), GetRandomInt(200, 255));
	}
	
	SetBeamLight(sBeamColor);
	
	if (!IsFirstMap())
		return;
	
	g_iParticleLight = 0;
	//CreateTimer(15.0, Timer_LoadParticles, _, TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(75.0, Timer_LoadParticles, _, TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(135.0, Timer_LoadParticles, _, TIMER_FLAG_NO_MAPCHANGE);
	
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	if (StrEqual(g_sMap, "l4d_garage01_alleys", false)) {
		ServerCommand("sm_no_si 1");
		CreateTimer(120.0, Timer_EnableSI); // 2 min
	}
	else {
		ServerCommand("sm_no_si 1");
		CreateTimer(60.0, Timer_EnableSI); // 2 min
	}
	
	//CreateTimer(2.0, Timer_WeatherDelayed, 0, TIMER_FLAG_NO_MAPCHANGE);
	
	//CreateTimer(300.0, Timer_LoadFireFly, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Cmd_XMAS(int client, int args)
{
	
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
}

stock bool IsFinalMap()
{
	return( FindEntityByClassname(-1, "info_changelevel") == -1
		&& FindEntityByClassname(-1, "trigger_changelevel") == -1 );
}

stock bool IsStartOrEndMap()
{
    int iCount;
    int i = -1;
    while( (i = FindEntityByClassname(i, "info_landmark")) != -1 ) {
        iCount++;
    }

    return (iCount == 1);
}


bool IsFirstMap()
{
	//return (IsStartOrEndMap() && !IsFinalMap());

	
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (StrEqual(sMap, "l4d_hospital01_apartment", false) ||
		StrEqual(sMap, "l4d_garage01_alleys", false) ||
		StrEqual(sMap, "l4d_smalltown01_caves", false) ||
		StrEqual(sMap, "l4d_airport01_greenhouse", false) ||
		StrEqual(sMap, "l4d_farm01_hilltop", false) ||
		StrEqual(sMap, "l4d_river01_docks", false)) {
	
		return true;
	}
	return false;
	
}

public Action Timer_WeatherDelayed(Handle timer)
{
	switch(GetRandomInt(1, 3)) {
		case 1: DoPrecip("0");
		case 2: DoPrecip("1");
		case 3: DoPrecip("3");
		
	
	}
	
	//ServerCommand("sm_rains");
	//ServerCommand("sm_snows");
	//ServerCommand("sm_wind");
	//ServerCommand("sm_startdisco %f %f %f", vec1[0], vec1[1], vec1[2]);
	CreateTimer(30.0, Timer_ManageWind, 0, TIMER_FLAG_NO_MAPCHANGE);
}

void StartFog()
{
	static int r,g,b;
	static char sBeamColor[32];
	
	switch(GetRandomInt(1, 6))
	{
		case 1, 2, 3: {
			ServerCommand("sm_fog 0 0 50");
			ServerCommand("sm_sun 0 0 50");
			r = 0;
			g = GetRandomInt(0, 200);
			b = GetRandomInt(50, 250);
			ServerCommand("sm_background %i %i %i", r, g, b);
			
			switch (GetRandomInt(0, 5)) {
				case 0: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, g / 200 * 128, (b-50) / 200 * 128 + 128 - 1);
				case 1: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), 0, 0);
				case 2: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), 0);
				case 3: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, 0, GetRandomInt(200, 255));
				case 4: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), GetRandomInt(200, 255), 0);
				case 5: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), GetRandomInt(200, 255));
			}
			
			//SetBeamLight(sBeamColor);
		}
		case 4: {
			ServerCommand("sm_fog 0 50 50");
			ServerCommand("sm_sun 0 50 50");
			r = 0;
			g = GetRandomInt(0, 200);
			b = GetRandomInt(50, 250);
			ServerCommand("sm_background %i %i %i", r, g, b);
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, g / 200 * 128 + 128 - 1, (b-50) / 200 * 128);
			//SetBeamLight(sBeamColor);
		}
		case 5: {
			ServerCommand("sm_fog 50 0 0");
			ServerCommand("sm_sun 50 0 0");
			r = GetRandomInt(0, 100);
			g = GetRandomInt(0, 15);
			b = GetRandomInt(0, r / 2);
			ServerCommand("sm_background %i %i %i", r, g ,b);
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", r / 100 * 55 + 200, b, g); // not mistake!
			//SetBeamLight(sBeamColor);
		}
		case 6: {
			ServerCommand("sm_fog 50 0 50");
			ServerCommand("sm_sun 50 0 50");
			r = GetRandomInt(0, 150);
			g = GetRandomInt(0, r / 2);
			b = r;
			ServerCommand("sm_background %i %i %i", r, g ,b);
			r = r / 150 * 128 + 128 - 1;
			g = r;
			b = 0;
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", r, g, b);
			//SetBeamLight(sBeamColor);
		}
	}
}

public Action Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	g_bRoundStart = false;
}
public void OnMapEnd()
{
	g_bRoundStart = false;
	g_bFirstMap = false;
}

stock int GetHumanClientCount(bool bInGame)
{
	int cnt = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			if (bInGame)
			{
				if (IsClientInGame(i) && GetClientTeam(i) != 3) {
					cnt++;
				}
			}
			else {
				cnt++;
			}
		}
	}
	return cnt;
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

public Action Timer_LoadParticles(Handle timer)
{
	int cnt = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			if (g_iParticleLight <= MAX_PARTICLE_LIGHTS)
				SpawnEffect(i, "runway_lights");
			g_iParticleLight++;
			cnt++;
			if (cnt >= 4) break;
		}
	}
}

public Action Timer_LoadFireFly(Handle timer, int UserId)
{
	static int iTimes = 0;
	CreateTimer(1.0, Timer_LoadFireFlySeveral, UserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	iTimes += 1;
	if (iTimes % 10 == 0) return Plugin_Stop;
	return Plugin_Continue;
}

public Action Timer_LoadFireFlySeveral(Handle timer, int UserId)
{
	static int iTimes = 0;
	
	int client = GetClientOfUserId(UserId);
	if (client == 0 || !IsClientInGame(client))
		client = GetAnyValidClient();
	
	if (client != 0)
		SpawnEffect(client, "Fireflies_cornfield");
		
	iTimes += 1;
	if (iTimes % 5 == 0) return Plugin_Stop;
	return Plugin_Continue;
}

int GetAnyValidClient()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			return i;
	}
	return 0;
}

void SpawnEffect(int client, char[] sParticleName)
{
	float pos[3];
//	GetClientAbsOrigin(client, pos);
	GetClientEyePosition(client, pos);
	int iEntity = CreateEntityByName("info_particle_system", -1);
	if (iEntity != -1)
	{
		DispatchKeyValue(iEntity, "effect_name", sParticleName);
		DispatchKeyValueVector(iEntity, "origin", pos);
		DispatchSpawn(iEntity);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		SetVariantString("OnUser1 !self:kill::1.5:1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

stock void PrecacheEffect(const char[] sEffectName) // thanks to _GamerX
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName) // thanks to _GamerX
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}  

public void OnMapStart()
{
	/*
	PrecacheEffect("ParticleEffect");
	PrecacheGeneric("particles/environmental_fx.pcf", true);
	PrecacheParticleEffect("runway_lights");
	PrecacheParticleEffect("Fireflies_cornfield");
	*/
	
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	g_bFirstMap = IsFirstMap();
	
	/*
	if (g_bFirstMap)
	{
		StartFog();
	}
	*/
}

public Action Timer_ManageWind(Handle timer, int iAction)
{
	ServerCommand("sm_wind");
	
	if (iAction == 0) {
		CreateTimer(GetRandomFloat(5.0, 60.0), Timer_ManageWind, 1, TIMER_FLAG_NO_MAPCHANGE);
	}
	else {
		CreateTimer(GetRandomFloat(40.0, 60.0), Timer_ManageWind, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_EnableSI(Handle timer, int UserId)
{
	ServerCommand("sm_no_si 0");
}

stock void StringToLog(const char[] format, any ...)
{
	#if (DEBUG || DEBUG_CHAT)
	char buf2[500];
	
	VFormat(buf2, sizeof(buf2), format, 2);
	
	//char sLine[100], buffer[500];
	//VFormat(buffer, sizeof(buffer), format, 2);
	//FormatTime(sLine, sizeof(sLine), "%F, %X", GetTime());
	//Format(buf2, sizeof(buf2), "[%s] [XMAS]: %s", sLine, buffer);
	#endif
	
	#if (DEBUG)
	File g_hLog;
	g_hLog = OpenFile("addons/sourcemod/logs/XMAS.log", "a");
	g_hLog.WriteLine(buf2);
	FlushFile(g_hLog);
	g_hLog.Close();
	#endif
	
	#if (DEBUG_CHAT)
	PrintToChatAll(buf2);
	#endif
}

void SetBeamLight(char[] sColor)
{
	static int ent;
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "beam_spotlight")) != -1)
	{
		SetVariantString(sColor);
		AcceptEntityInput(ent, "Color");
	}
}

void DoPrecip(char[] sType)
{
	char sMap[64];
	float vMins[3], vMax[3], vBuff[3];
	int iEnt = -1;

	while ((iEnt = FindEntityByClassname(iEnt , "func_precipitation")) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(iEnt, "Kill");
	while ((iEnt = FindEntityByClassname(iEnt , "func_precipitation_blocker")) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(iEnt, "Kill");

	iEnt = -1;
	iEnt = CreateEntityByName("func_precipitation");
	
	if (iEnt != -1) {	
		GetCurrentMap(sMap, 64);
		Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
		PrecacheModel(sMap, true);

		DispatchKeyValue(iEnt, "density", "100");
		DispatchKeyValue(iEnt, "color", "255 255 255");

		DispatchKeyValue(iEnt, "model", sMap);
		DispatchKeyValue(iEnt, "preciptype", sType);

		/*
		0 - hard rain
		1 - middle rain
		2 
		3 - snow
		*/
		
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

		SetEntPropVector(iEnt, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", vMax);

		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];

		TeleportEntity(iEnt, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}
}