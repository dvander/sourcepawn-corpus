/* sm_shootknife.sp
Name: Don't Shoot-Knife
Author: LumiStance
Date: 2010 - 08/26

Description:
	Suicides a player who shoots, then knifes another player, before either player has died.
	This prevents players from getting easy upgrades when knifepro is enabled for gungame.
	Ignores damage from grenades.

Background:
	This pluging was inspired by complaints on I.P.S.

	Admin Smite by Hipster - http://forums.alliedmods.net/showthread.php?t=118534

Files:
	cstrike/addons/sourcemod/plugins/sm_shootknife.smx

Changelog:
	0.3 <-> 2010 - 08/29 LumiStance
		Modify code to ignore non gun damage
		Add code to forgive shots at round start
	0.2 <-> 2010 - 08/27 LumiStance
		Add PrintToChat's to inform all players about plugin
	0.1 <-> 2010 - 08/26 LumiStance
		Add hook for OnTakeDamage - Note damagetype is not useful
		Add Smite
		Debug
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "0.3-lm"
#define PLUGIN_ANNOUNCE "\x04[Don't Shoot Knife]\x01 v0.3-lm by LumiStance"
public Plugin:myinfo =
{
	name = "Don't Shoot-Knife",
	author = "LumiStance",
	description = "Explodes player who drops bomb",
	version = PLUGIN_VERSION,
	url = "http://srcds.lumistance.com/"
};

// Other Persistant Variables
#define SOUND_THUNDER "ambient/explosions/explode_9.wav"
new g_SmokeSprite;
new g_LightningSprite;
new bool:g_Shot[MAXPLAYERS+1][MAXPLAYERS+1];

public OnPluginStart()
{
	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file - Force correct value
	SetConVarString(
		CreateConVar("sm_shootknife_version", PLUGIN_VERSION, "[SM] Don't Shoot-Knife Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD),
		PLUGIN_VERSION);

	// OnClientPutInServer not called if plugin loads after players connect
	for (new client_index = 1; client_index <= MaxClients; ++client_index)
		if(IsClientInGame(client_index))
			OnClientPutInServer(client_index);

	// Event Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	// No event data needed
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart() {
	PrecacheSound(SOUND_THUNDER, true);
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
}

public OnClientPutInServer(client_index)
{
	PrintToChat(client_index, PLUGIN_ANNOUNCE);
	ForgiveShots(client_index);
	SDKHook(client_index, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	for (new client_index = 1; client_index <= MaxClients; ++client_index)
		ForgiveShots(client_index);
}

public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	//ForgiveShots(GetClientOfUserId(GetEventInt(event, "userid")));
	for (new client_index = 1; client_index <= MaxClients; ++client_index)
		ForgiveShots(client_index);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
//	PrintToServer("\x04[lm]\x01 Attacker: %i  Victim: %i  Inflictor: %i  Damage: %0.0f  Type: %i", attacker, victim, inflictor, damage, damagetype);
	// Make sure victim and attacker are players, and damage from gun or knife (not grenades)
	if ( (victim>=1) && (victim<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor) )
	{
		decl String:WeaponName[64];
		GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
		if (!StrEqual(WeaponName, "weapon_knife", false))
		{
//			PrintToChat(attacker, "\x04[lm]\x01 Voce foi marcado %i %s", inflictor, WeaponName);
			g_Shot[attacker][victim] = true;
		}
		else if (g_Shot[attacker][victim])
		{
			CreateTimer(0.1, Event_Slay, attacker);
			return Plugin_Handled;
		}

	}
	return Plugin_Continue;
}

// Delayed for safety
public Action:Event_Slay(Handle:timer, any:client_index)
{
	decl String:ClientName[256];
	GetClientName(client_index, ClientName, sizeof(ClientName));
	Smite(client_index);
	PrintCenterText(client_index, "Nao atire e va na faca!");
	PrintToChatAll("\x04[lm]\x01 %s foi morto por atirar e esfaquear!", ClientName);
}

// Reset player shots
stock ForgiveShots(client_index)
{
//	PrintToChat(client_index, "\x04[lm]\x01 You're cleared");
	// Forgive player for attacking with a gun
	for (new victim = 1; victim <= MaxClients; ++victim)
		g_Shot[client_index][victim] = false;
	// Forgive players who attacked with a gun
	for (new attacker = 1; attacker <= MaxClients; ++attacker)
		g_Shot[attacker][client_index] = false;
}

// Admin Smite by Hipster - http://forums.alliedmods.net/showthread.php?t=118534
stock Smite(client_index)
{
	// define where the lightning strike ends
	new Float:clientpos[3];
	GetClientAbsOrigin(client_index, clientpos);
	clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground

	// get random numbers for the x and y starting positions
	new randomx = GetRandomInt(-500, 500);
	new randomy = GetRandomInt(-500, 500);

	// define where the lightning strike starts
	new Float:startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 800;

	// define the color of the strike
	new color[4] = {255, 255, 255, 255};

	// define the direction of the sparks
	new Float:dir[3] = {0.0, 0.0, 0.0};

	TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();

	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();

	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();

	TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();

	EmitAmbientSound(SOUND_THUNDER, startpos, client_index, SNDLEVEL_RAIDSIREN);

	ForcePlayerSuicide(client_index);
}
