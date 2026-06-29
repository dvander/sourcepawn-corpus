#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define VERSION 		"1.0"
#define TAG			"[SM]"
#define MODEL_CAKE_LARGE	"models/items/medkit_large_bday.mdl"
#define MODEL_CAKE_MEDIUM	"models/items/medkit_medium_bday.mdl"

new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;

new cake[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name 		= "[TF2] Cakevich",
	author 		= "FlaminSarge",
	description = "Dropping a Sandvich makes a cake",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_cakevich_version", VERSION, "Turns dropped sandviches into cake.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_cakevich_enable", "1", "Enable Cakevich", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_cakevich", Cakevich, "Throw cakes");
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
}
public Action:Cakevich(client, args)
{
	decl String:arg1[32];
	if (!IsValidClient(client)) return Plugin_Continue;
	new launchon;
	if (args >= 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		launchon = StringToInt(arg1);
		if (launchon > 2) launchon = 2;
		if (launchon < 0) launchon = 0;
	}
	else launchon = (cake[client] ? 0 : 1);
	cake[client] = launchon;
	if (g_bEnabled)
		PrintToChat(client, "%s You will %s drop %scakes.", TAG, launchon ? "now" : "not", launchon == 2 ? "large " : "");
	else
		PrintToChat(client, "%s Cakevich is disabled right now, but when it is enabled, you will %sdrop cakes.", TAG, launchon ? "" : "not ");
	return Plugin_Handled;
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}
public OnMapStart()
{
	PrecacheModel(MODEL_CAKE_LARGE, true);
	PrecacheModel(MODEL_CAKE_MEDIUM, true);

	for (new i = 0; i <= MaxClients; i++)
	{
		OnClientPutInServer(i);
	}	
}
public OnClientPutInServer(client) cake[client] = 0;
public OnClientDisconnect_Post(client) OnClientPutInServer(client);
public OnEntityCreated(entity, const String:classname[]) {
	if(!g_bEnabled)return;

	// Only hook medium sized medkits (medkits, steak, sandvich...)
	// This could be extended to small medkits to block scouts from picking
	// up medkits created by their Candy Cane.
	if(strcmp(classname, "item_healthkit_medium", false) == 0) {
    	SDKHook(entity, SDKHook_SpawnPost, OnHealthKitSpawned);
    }
}
stock IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
public OnHealthKitSpawned(entity)
{
	new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if(IsValidClient(iOwner) && cake[iOwner])
	{
		if (cake[iOwner] == 2) CreateTimer(0.0, Timer_SetLarge, entity, TIMER_FLAG_NO_MAPCHANGE);
		else CreateTimer(0.0, Timer_SetMedium, entity, TIMER_FLAG_NO_MAPCHANGE);
		//SetEntityModel(entity, (cake[iOwner] == 2 ? MODEL_CAKE_LARGE : MODEL_CAKE_MEDIUM));
	}
}
public Action:Timer_SetLarge(Handle:timer, any:entity)
{
	if (IsModelPrecached(MODEL_CAKE_LARGE) && IsValidEntity(entity))
	{
		SetEntityModel(entity, MODEL_CAKE_LARGE);
	}
}
public Action:Timer_SetMedium(Handle:timer, any:entity)
{
	if (IsModelPrecached(MODEL_CAKE_MEDIUM) && IsValidEntity(entity))
	{
		SetEntityModel(entity, MODEL_CAKE_MEDIUM);
	}
}