#include <sourcemod>
#include <clients>
#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdkhooks>
#include <adt_array>

public Plugin myinfo = {
	name = "Molotov rain",
	author = "Piotr Kąkol",
	description = "One of the events to be used in Hunger Games mod in CS:GO.",
	url = "http://cs-placzabaw.pl"
};

// globals
Handle start_timer = INVALID_HANDLE;
Handle molotov_timer = INVALID_HANDLE;
Handle h_MP_RESTARTGAME = INVALID_HANDLE;
Handle alivePlayerArray;
bool molotovsFalling = false;
int molotovs = 0;

// ConVars
Handle h_molotovNumber = INVALID_HANDLE;
Handle h_molotovGravity = INVALID_HANDLE;
Handle h_molotovHeight = INVALID_HANDLE;
Handle h_molotovInterval = INVALID_HANDLE;
Handle h_molotovRadius = INVALID_HANDLE;
Handle h_molotovTimerStart = INVALID_HANDLE;
Handle h_molotovTimerEnd = INVALID_HANDLE;
Handle h_molotovEnable = INVALID_HANDLE;

public OnPluginStart() {
	h_molotovNumber = CreateConVar("sm_molotovnumber", "15", "Set number of molotovs falling from the sky.", 0, true, 1.0, true, 30.0);
	h_molotovGravity = CreateConVar("sm_molotovgravity", "100", "Set the gravity of molotovs.", 0, true, 1.0, true, 1000.0);
	h_molotovHeight = CreateConVar("sm_molotovheight", "400", "Set the height from which molotovs will fall.", 0, true, 100.0, true, 1000.0);
	h_molotovInterval = CreateConVar("sm_molotovinterval", "1.0", "Set the interval between falling molotovs.", 0, true, 0.0, true, 10.0);
	h_molotovRadius = CreateConVar("sm_molotovradius", "200.0", "Set the radius of falling molotovs.", 0, true, 0.0, true, 500.0);
	h_molotovTimerStart = CreateConVar("sm_molotovtimerstart", "90", "Set the minimal time after which the molotovs will fall.", 0, true, 30.0);
	h_molotovTimerEnd = CreateConVar("sm_molotovtimerend", "30", "Set the minimal time before the end of the round before which the molotovs will fall.", 0, true, 0.0);
	h_molotovEnable = CreateConVar("sm_molotovenable", "1", "Enables or disables the plugin.", 0, true, 0.0, true, 1.0);

	RegAdminCmd("sm_molotovstart", StartMolotovRain, ADMFLAG_CONVARS, "Starts the molotov rain.");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	h_MP_RESTARTGAME = FindConVar("mp_restartgame");
	if(h_MP_RESTARTGAME != INVALID_HANDLE)
		HookConVarChange(h_MP_RESTARTGAME, ConvarChanged);
}

public Action StartMolotovRain(int client, int args) {
	TimerCallBack(null);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	// calculate interval in which molotovs can fall
	ConVar roundtime = FindConVar("mp_roundtime");
	int time_end = RoundToFloor(roundtime.FloatValue*60.0), time_start = GetConVarInt(h_molotovTimerStart);
	if(time_end-GetConVarInt(h_molotovTimerEnd)-time_start >= 0)
		time_end -= GetConVarInt(h_molotovTimerEnd);

	int time = GetRandomInt(time_start, time_end);
	start_timer = CreateTimer(float(time), TimerCallBack);
	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
	CloseHandle(molotov_timer);
	CloseHandle(start_timer);
	molotovsFalling = false;
	molotovs = 0;
}

public ConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if(StrEqual(newVal, "1")) {
		CloseHandle(molotov_timer);
		CloseHandle(start_timer);
		molotovsFalling = false;
		molotovs = 0;
	}
}

stock bool IsValidPlayer(client)
{
    return client > 0 && client <= MAXPLAYERS && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client);
}

public Action TimerCallBack(Handle timer) {
	if(molotovsFalling)
		return Plugin_Continue;
	molotovsFalling = true;
	start_timer = INVALID_HANDLE;
	molotov_timer = INVALID_HANDLE;

	// choose random player
	alivePlayerArray = CreateArray(1);
	for(int i = 1; i < MaxClients; i++)
		if(IsValidPlayer(i))
			PushArrayCell(alivePlayerArray, i);
	int random_player = GetArrayCell(alivePlayerArray, GetRandomInt(1, GetArraySize(alivePlayerArray)) - 1);
	int player = GetClientOfUserId(GetClientUserId(random_player));

	if(GetConVarInt(h_molotovEnable) != 1)
		return Plugin_Continue;
	
	molotov_timer = CreateTimer(GetConVarFloat(h_molotovInterval), DropMolly, player, TIMER_REPEAT);
	return Plugin_Continue;
}

float pos[3];

public Action DropMolly(Handle timer, any player) {
	if(++molotovs > GetConVarInt(h_molotovNumber) || !IsValidPlayer(player)) {
		molotovs = 0;
		molotovsFalling = false;
		return Plugin_Stop;
	}

	// create molotov
	int molly = CreateEntityByName("molotov_projectile");
	if(molly == -1)
		return Plugin_Continue;

	// set molotov's position
	float rad_x = GetRandomFloat(0.0, GetConVarFloat(h_molotovRadius)), rad_y = GetRandomFloat(0.0, GetConVarFloat(h_molotovRadius));
	if(GetRandomInt(0, 1) > 0)
		rad_x = -rad_x;
	if(GetRandomInt(0, 1) > 0)
		rad_y = -rad_y;
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", pos);
	pos[0] += rad_x;
	pos[1] += rad_y;
	pos[2] += GetConVarFloat(h_molotovHeight);

	DispatchSpawn(molly);
	TeleportEntity(molly, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityGravity(molly, GetConVarFloat(h_molotovGravity)/100.0);
	SDKHook(molly, SDKHook_Touch, StartTouch);
	return Plugin_Continue;
}

public Action StartTouch(int molly, int other) {
	// explode molotov by setting and giving it damage
	SetEntProp(molly, Prop_Data, "m_takedamage", 2);
	SetEntProp(molly, Prop_Data, "m_iHealth", 1);
	SDKHooks_TakeDamage(molly, molly, 1, 1.0, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR);
}