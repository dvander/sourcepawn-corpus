#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION  "1.0"

#define BRIGHTNESS 6
#define DISTANCE 160.0
#define INTERVAL 0.1

public Plugin:myinfo = {
	name = "Uber Lights",
	author = "MasterOfTheXP",
	description = "I AM BOOLETPROOOOOOOOOOF",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new const String:Colours[][] = {
	"255 0 0",
	"255 255 0",
	"0 255 0",
	"0 255 255",
	"0 0 255",
	"255 0 255"
};
new bool:HasUber[MAXPLAYERS + 1];
new LightEnt[MAXPLAYERS + 1];
new bool:WantsLights[MAXPLAYERS + 1] = {true, ...};
new LightOwner[2049];

public OnPluginStart()
{
	RegConsoleCmd("uberlights", Command_ToggleLights);
	RegConsoleCmd("uberlight", Command_ToggleLights);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!TF2_IsPlayerInCondition(i, TFCond_Ubercharged)) continue;
		HasUber[i] = true;
		GiveLight(i);
		CreateTimer(0.0, Timer_Lights, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!HasUber[i]) continue;
		RemoveLight(i);
	}
}

public Action:Command_ToggleLights(client, args)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Continue;
	}
	if (!CheckCommandAccess(client, "uberlights_override", 0, true))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Continue;
	}
	WantsLights[client] = !WantsLights[client];
	ReplyToCommand(client, "Uber lights %sabled.", WantsLights[client] ? "en" : "dis");
	return Plugin_Handled;
}

public TF2_OnConditionAdded(client, TFCond:cond)
{
	if (!WantsLights[client]) return;
	if (cond != TFCond_Ubercharged) return;
	if (!CheckCommandAccess(client, "uberlights_override", 0, true)) return;
	HasUber[client] = true;
	CreateTimer(0.0, Timer_Lights, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	RemoveLight(client);
	GiveLight(client);
}

public TF2_OnConditionRemoved(client, TFCond:cond)
{
	if (cond != TFCond_Ubercharged) return;
	HasUber[client] = false;
	RemoveLight(client);
}
public OnClientDisconnect(client)
{
	HasUber[client] = false;
	RemoveLight(client);
}
public OnClientConnected(client)
	WantsLights[client] = true;

public Action:Timer_Lights(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (!HasUber[client]) return;
	static currentLight[MAXPLAYERS + 1] = {-1, ...};
	if (++currentLight[client] == sizeof(Colours)) currentLight[client] = 0;
	DispatchKeyValue(LightEnt[client], "_light", Colours[currentLight[client]]);
	ActivateEntity(LightEnt[client]);
	CreateTimer(INTERVAL, Timer_Lights, uid, TIMER_FLAG_NO_MAPCHANGE);
}

stock GiveLight(client)
{
	new Ent = CreateEntityByName("light_dynamic");
	if (!IsValidEntity(Ent)) return; // It shouldn't.
	DispatchKeyValue(Ent, "_light", Colours[0]);
	SetEntProp(Ent, Prop_Send, "m_Exponent", BRIGHTNESS);
	SetEntPropFloat(Ent, Prop_Send, "m_Radius", DISTANCE);
	DispatchSpawn(Ent);
	new Float:Pos[3], Float:Ang[3];
	GetClientEyePosition(client, Pos);
	Ang[1] = 180.0;
	TeleportEntity(Ent, Pos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(Ent, "SetParent", client);
	LightEnt[client] = Ent;
	LightOwner[Ent] = client;
}

stock RemoveLight(client)
{
	if (LightEnt[client] > MaxClients) AcceptEntityInput(LightEnt[client], "Kill");
}

public OnEntityDestroyed(Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	if (LightOwner[Ent])
	{
		LightEnt[LightOwner[Ent]] = 0;
		LightOwner[Ent] = 0;
	}
}