#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS 		FCVAR_PLUGIN|FCVAR_NOTIFY
#define HEIGHT 			800.0
#define MAX_BOOMER 		32
#define PLUGIN_VERSION 	"1.0.0"
#define RANGE 			250.0

public Plugin:myinfo = {
	name = "[L4D1&2] Boomer Rain",
	author = "Die Teetasse",
	description = "Spawns a rain of boomers.",
	version = PLUGIN_VERSION,
	url = ""
};

new bool:BoomerIsSpawning = false;
new Float:currentTarget[3];
new Handle:CVarExplosion;
new Handle:CVarSplatRadius;

public OnPluginStart() {
	RegAdminCmd("sm_boomer_rain", Command_BoomerRain, ADMFLAG_KICK, "sm_boomer_rain [count] | Will start a boomer rain above you.");
	RegAdminCmd("sm_boomer_rain_at", Command_BoomerRainAt, ADMFLAG_KICK, "sm_boomer_rain_at <x> <y> <z> [count] | Will start a boomer rain at the position.");
	CVarExplosion = CreateConVar("sm_boomer_rain_explosive", "1", "Should the survivors get biled and stumbled?", CVAR_FLAGS);
	CreateConVar("sm_boomer_rain_version", PLUGIN_VERSION, "Boomer Rain Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	CVarSplatRadius = FindConVar("z_exploding_splat_radius");
	HookEvent("player_spawn", Event_PlayerSpawn);
	SetRandomSeed(GetTime());
}

public Action:Command_BoomerRain(client, args) {
	if (client == 0) client = 1;

	decl Float:clientOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
	
	if (args == 0) BoomerRain(clientOrigin);
	else {
		decl String:tempFloat[16];
		GetCmdArg(1, tempFloat, 16);
		new count = StringToInt(tempFloat);
		BoomerRain(clientOrigin, count);
	}
}

public Action:Command_BoomerRainAt(client, args) {
	if (args != 3 && args != 4) {
		return;
	}
	
	decl Float:entityPosition[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	if (args == 3) BoomerRain(entityPosition);
	else {
		GetCmdArg(4, tempFloat, 16);
		new count = StringToInt(tempFloat);
		BoomerRain(entityPosition, count);
	}
}

BoomerRain(const Float:rainOrigin[3], const boomerCount = 10) {
	if (!GetConVarBool(CVarExplosion)) SetConVarInt(CVarSplatRadius, 0);

	new Handle:data = CreateStack(3);
	PushStackCell(data, 1);
	PushStackCell(data, boomerCount);
	PushStackArray(data, rainOrigin);
	
	CreateTimer(0.1, Timer_RepeatTimer, data);
}

public Action:Timer_RepeatTimer(Handle:timer, any:stack) {
	decl Float:position[3];
	new count, current;
	
	PopStackArray(stack, position);
	PopStackCell(stack, count);
	PopStackCell(stack, current);
	CloseHandle(stack);
	
	CreateBoomer();
	BoomerIsSpawning = true;
	CopyVector(position, currentTarget);
	
	current++;
	if (current > count) {
		if (!GetConVarBool(CVarExplosion)) CreateTimer(5.0, Timer_ResetConVar);
		return;
	}
	
	new Handle:data = CreateStack(3);
	PushStackCell(data, current);
	PushStackCell(data, count);
	PushStackArray(data, position);
	CreateTimer(0.5, Timer_RepeatTimer, data);
}

public Action:Timer_ResetConVar(Handle:timer, any:client) {	
	ResetConVar(CVarSplatRadius);
}

CreateBoomer() {
	new bot = CreateFakeClient("InfBot");
	if (bot == 0) return;
	
	ChangeClientTeam(bot, 3);
	CreateTimer(0.1, Timer_KickFakeClient, bot);
	CheatCommand("z_spawn", "boomer auto");
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!BoomerIsSpawning) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client)) return;
	if (GetClientTeam(client) != 3) return;
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 2) return;
	
	CreateTimer(0.01, Timer_TeleportBoomer, client);
	BoomerIsSpawning = false;
}

public Action:Timer_TeleportBoomer(Handle:timer, any:client) {	
	decl Float:min, Float:max, Float:pos[3];
	min = currentTarget[0] - RANGE;
	max = currentTarget[0] + RANGE;
	pos[0] = GetRandomFloat(min, max);
	min = currentTarget[1] - RANGE;
	max = currentTarget[1] + RANGE;
	pos[1] = GetRandomFloat(min, max);
	pos[2] = currentTarget[2] + HEIGHT;
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action:Timer_KickFakeClient(Handle:timer, any:client) {
	if (!IsClientInGame(client)) return;
	if (!IsFakeClient(client)) return;
	
	KickClient(client);
}

CheatCommand(const String:command[], const String:parameter[] = "", cheatPlayer = -1) {
	if (cheatPlayer == -1) {
		for (new client = 1; client < MaxClients+1; client++) {
			if (!IsClientInGame(client)) continue;
			if (!IsPlayerAlive(client)) continue;
			if (GetClientTeam(client) != 2) continue;
			
			cheatPlayer = client;
			break;
		}
		
		if (cheatPlayer == -1) return;
	}
	else if (!IsClientInGame(cheatPlayer)) return;		
	
	new userFlags = GetUserFlagBits(cheatPlayer);
	SetUserFlagBits(cheatPlayer, ADMFLAG_ROOT);
	new commandFlags = GetCommandFlags(command);
	SetCommandFlags(command, commandFlags & ~FCVAR_CHEAT);
	FakeClientCommand(cheatPlayer, "%s %s", command, parameter);
	SetCommandFlags(command, commandFlags);
	SetUserFlagBits(cheatPlayer, userFlags);	
}

CopyVector(Float:a[3], Float:b[3]) {
	for (new i = 0; i < 3; i++) b[i] = a[i];
}