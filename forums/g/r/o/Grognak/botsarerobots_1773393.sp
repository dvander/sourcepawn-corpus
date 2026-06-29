#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME         "[TF2] Bots are Robots"
#define PLUGIN_AUTHOR       "Grognak"
#define PLUGIN_DESCRIPTION  "PvP bots will use the robot model and voice"
#define PLUGIN_VERSION      "1.1"
#define PLUGIN_CONTACT      "grognak.tf2@gmail.com"

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

new bool:isRobot[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
	CreateConVar("botsarerobots_version", PLUGIN_VERSION, "Bots are Robots Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);

	HookEvent("post_inventory_application", Event_PostInventory, EventHookMode_Post);

	AddNormalSoundHook(SoundHook);
}

public bool:MakeRobot(iClient, bool:bToggle)
{
	if (!IsValidClient(iClient) || !IsPlayerAlive(iClient)) 
		return false;

	if (bToggle)
	{
		if (SetModel(iClient)) 
			isRobot[iClient] = true;
		else 
			return false;
	}
	else
	{
		if (RemoveModel(iClient)) 
			isRobot[iClient] = false;
		else 
			return false;
	}
	
	return true;
}

public OnClientDisconnect(iClient) 
{
	isRobot[iClient] = false;
}

public Action:Event_PostInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.1, tSetRobot, iClient);
}

public Action:tSetRobot(Handle:hTimer, any:iClient)
{
	if (IsFakeClient(iClient)) 
		MakeRobot(iClient, true);
	else
		MakeRobot(iClient, false);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!isRobot[client]) return Plugin_Continue;
	if (StrContains(sound, "player/footsteps/", false) != -1)
	{
		new rand = GetRandomInt(1,18);
		Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
		pitch = GetRandomInt(95, 100);
		EmitSoundToClient(client, sound, _, _, _, _, 0.25, pitch);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
	if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
	ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
	ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false); // yay for valve being smart
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: ReplaceString(sound, sizeof(sound), "scout_", "scout_mvm_", false);
		case TFClass_Soldier: ReplaceString(sound, sizeof(sound), "soldier_", "soldier_mvm_", false);
		case TFClass_Pyro: ReplaceString(sound, sizeof(sound), "pyro_", "pyro_mvm_", false);
		case TFClass_DemoMan: ReplaceString(sound, sizeof(sound), "demoman_", "demoman_mvm_", false);
		case TFClass_Heavy: ReplaceString(sound, sizeof(sound), "heavy_", "heavy_mvm_", false);
		case TFClass_Medic: ReplaceString(sound, sizeof(sound), "medic_", "medic_mvm_", false);
		case TFClass_Sniper: ReplaceString(sound, sizeof(sound), "sniper_", "sniper_mvm_", false);
		case TFClass_Spy: ReplaceString(sound, sizeof(sound), "spy_", "spy_mvm_", false);
	}
	new String:soundchk[PLATFORM_MAX_PATH];
	Format(soundchk, sizeof(soundchk), "sound/%s", sound);
	if (!FileExists(soundchk)) return Plugin_Continue;
	PrecacheSound(sound);
	return Plugin_Changed;
}

stock bool:SetModel(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: return false; // D:
	}
	Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
	PrecacheModel(Mdl);
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
