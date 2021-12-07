/**
 * File: ThisIsWar.sp
 * Description: Enlist all classes into the war
 * Author(s): Rek
 * Versions:
 * 			0.2 : Makes the resupply cabinet not remove your weapons.
 *          0.1 : Enabled all classes' weapons to be used by soldier/demo (and forces soldier/demo)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "This is War",
    author = "Rek",
    description = "'Enlists' all classes into the soldier demo war.",
    version = "0.2",
    url = "http://sourcemod.net/"
};       


new Handle:PluginEnabled;
new Handle:ClassSelection;

new String:client_string[10];

public OnPluginStart()
{	
	PluginEnabled = CreateConVar("sm_war_enabled", "1", "Enable/Disable war mode", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("player_changeclass", PlayerChangeClass);
	HookEvent("player_spawn", PlayerSpawn);	
}

public OnMapStart() {
	ClassSelection = Handle:CreateTrie();
}

public OnMapEnd() {
	CloseHandle(ClassSelection);
}
public OnClientDisconnect(client) {
	IntToString(client, client_string, 10);
	RemoveFromTrie(ClassSelection, client_string);
}

// --------------------------- RESUPPLY CABINET -----------------
public OnEntityCreated(entity, const String:classname[])
{	
	if (strcmp(classname,"func_regenerate") != 0) 
		return;
		
	SDKHook(entity, SDKHook_StartTouch, PreTouch);
	SDKHook(entity, SDKHook_EndTouch, PostTouch);	
}

public PreTouch(entity, client) {
	if (!GetConVarBool(PluginEnabled))
        return;
	
	// Is this a real player
	if (!CheckBoundries(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
	
	new TFTeam:team = TFTeam:GetClientTeam(client);
	if (team != TFTeam_Red && team != TFTeam_Blue)
		return;	
	
	ChangeToOldClass(client);
	
}
public PostTouch(entity, client) {
	if (!GetConVarBool(PluginEnabled))
		return;

	// Is this a real player
	if (!CheckBoundries(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
		
	new TFTeam:team = TFTeam:GetClientTeam(client);
	if (team != TFTeam_Red && team != TFTeam_Blue)
		return;	
		
	ChangeToWarClass(client, team);
}


// --------------- WEAPON STICKING -------------------------------

public Action:PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!GetConVarBool(PluginEnabled))
		return;
	
	// Save class selection
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IntToString(client, client_string, 10);
	SetTrieValue(ClassSelection, client_string, GetEventInt(event, "class"), true);	
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(PluginEnabled))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	new TFTeam:team = TFTeam:GetClientTeam(client);
	if (team != TFTeam_Red && team != TFTeam_Blue)
		return;	
	
	ChangeToOldClass(client);
	ChangeToWarClass(client, team);
}

// ------------- YAY ------------------------------------------
public ChangeToOldClass(client)
{
	new TFClassType:weapon_class;
	IntToString(client, client_string, 10);
	if (!GetTrieValue(ClassSelection, client_string, weapon_class))
		return;
	
	TF2_SetPlayerClass(client, weapon_class, true, false);
}
public ChangeToWarClass(client, TFTeam:team) 
{
	new TFClassType:class = ( team== TFTeam_Red? TFClass_DemoMan : TFClass_Soldier );
	TF2_SetPlayerClass(client, class, false, false);
	GivePlayerHealth(client, class);
}


static const TFClass_MaxHealth[TFClassType] = {  50, 125, 125, 200, 175, 150, 300, 175, 125, 125 };
stock GivePlayerHealth(client, TFClassType:class)
{
	SetEntityHealth( client, TFClass_MaxHealth[class] );
}

bool:CheckBoundries(i)
{
	return i > 0 && i <= MaxClients;
}
