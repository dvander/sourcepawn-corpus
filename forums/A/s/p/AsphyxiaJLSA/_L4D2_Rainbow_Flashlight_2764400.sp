#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

#define BRIGHTNESS 3
#define DISTANCE 255.0
#define INTERVAL 0.1

static currentLight[MAXPLAYERS + 1] = {-1, ...};
int LightEnt[MAXPLAYERS + 1];
int LightOwner[2049];

new const String:Colours[][] = {
	"255 0 0",
	"0 255 0",
	"0 0 255",
	"155 0 255",
	"0 255 255",
	"255 155 0",
	"-1 -1 -1",
	"255 0 150",
	"128 255 0",
	"128 0 0",
	"0 128 128",
	"255 255 0",
	"50 50 50"
};

public Plugin myinfo =
{
	name = "[L4D2]Rainbow Flashlight",
	author = "King",
	description = "",
	version = "3.0.0",
	url = "www.sourcemod.net"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_lightrainbow", Rainbow, "rainbow light for players");
	RegConsoleCmd("sm_rainbow", Rainbow, "rainbow light for players");
	RegConsoleCmd("sm_disco", Rainbow, "rainbow light for players");
	RegConsoleCmd("sm_bts", Rainbow, "rainbow light for players");
    RegConsoleCmd("sm_rainbowoff", RainbowOff, "rainbow light off  for players");
	RegConsoleCmd("sm_off", RainbowOff, "rainbow light off  for players");
}

public Action Rainbow(int client, int args)
{
	GiveLight(client);
	CreateTimer(0.0, Timer_Lights, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action Timer_Lights(Handle timer, client)
{
	if (++currentLight[client] == sizeof(Colours)) currentLight[client] = 0;
	DispatchKeyValue(LightEnt[client], "_light", Colours[currentLight[client]]);
	ActivateEntity(LightEnt[client]);
	CreateTimer(INTERVAL, Timer_Lights, client, TIMER_FLAG_NO_MAPCHANGE);
}

stock GiveLight(client)
{
	new Ent = CreateEntityByName("light_dynamic");
	if (!IsValidEntity(Ent))
	DispatchKeyValue(Ent, "_light", Colours[0]);
	SetEntProp(Ent, Prop_Send, "m_Exponent", BRIGHTNESS);
	SetEntPropFloat(Ent, Prop_Send, "m_Radius", DISTANCE);
	DispatchKeyValue(Ent, "style", "0");
	DispatchSpawn(Ent);
	AcceptEntityInput(Ent, "TurnOn");
	new Float:Pos[3], Float:Ang[3];
	GetClientEyePosition(client, Pos);
	Ang[1] = 180.0;
	TeleportEntity(Ent, Pos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(Ent, "SetParent", client);
	LightEnt[client] = Ent;
	LightOwner[Ent] = client;
}

public Action RainbowOff(int client, int args)
{
	if (LightEnt[client] > MaxClients) AcceptEntityInput(LightEnt[client], "Kill");
}

public OnEntityDestroyed(int Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	if (LightOwner[Ent])
	{
		LightEnt[LightOwner[Ent]] = 0;
		LightOwner[Ent] = 0;
	}
}