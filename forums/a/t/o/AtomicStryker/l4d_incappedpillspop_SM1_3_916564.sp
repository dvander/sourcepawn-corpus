#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

new bool:buttondelay[MAXPLAYERS+1];
new bool:IsBeingPwnt[MAXPLAYERS+1];
new bool:IsBeingRevived[MAXPLAYERS+1];
new bool:IncapDelay[MAXPLAYERS+1];
new bool:CanUsePills;

new Handle:DelaySetting = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Incapped Pills Pop SM 1.3",
	author = "AtomicStryker",
	description = "You can press USE while incapped to pop your pills and revive yourself SM 1.3 ONLY",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=916564"
}

public OnPluginStart()
{
	CreateConVar("l4d_incappedpillspop_version", PLUGIN_VERSION, " Version of L4D Incapped Pills Pop on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	DelaySetting = CreateConVar("l4d_incappedpillspop_delaytime", "2.0", " How long before an Incapped Survivor can use pills ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_incappedpillspop");

	HookEvent("player_incapacitated", Event_Incap);
	
	HookEvent("lunge_pounce", Event_StartPwn);
	HookEvent("pounce_stopped", Event_EndPwn);
	HookEvent("tongue_grab", Event_StartPwn);
	HookEvent("tongue_release", Event_EndPwn);
	
	HookEvent("revive_begin", Event_StartRevive);
	HookEvent("revive_end", Event_EndRevive);
	HookEvent("revive_success", Event_EndRevive);
	
	HookEvent("round_start", UnPwnAll);
	HookEvent("round_end", UnPwnAll);
	
	HookEvent("player_spawn", UnPwnUserid);
	HookEvent("player_death", UnPwnUserid);
	HookEvent("player_connect_full", UnPwnUserid);
	HookEvent("player_disconnect", UnPwnUserid);
	
	HookEvent("round_end", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	
	HookEvent("round_start", RoundStart);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE && buttondelay[client] == false)
	{
		if (!IsClientInGame(client)) return Plugin_Continue;
		if (GetClientTeam(client)!=2) return Plugin_Continue;
		if (!IsPlayerIncapped(client)) return Plugin_Continue;
		if (!CanUsePills) return Plugin_Continue;
		if (IncapDelay[client]) return Plugin_Continue;
		
		// Whoever pressed USE must be valid, connected, ingame, Survivor and Incapped
		// a little buttondelay because the cmd fires too fast.
		buttondelay[client] = true;
		CreateTimer(1.0, ResetDelay, client);
		
		// Check for an Infected making love to you first.
		if (IsBeingPwnt[client])
		{
			PrintToChat(client, "\x04Get that Infected off you first.");
			return Plugin_Continue;
		}
		
		// Check for the Survivor Pendant
		if (IsBeingRevived[client])
		{
			PrintToChat(client, "\x04You're being revived already.");
			return Plugin_Continue;
		}
		
		// Check the Pills Slot. Revive. Remove Pills.
		
		new PillSlot = GetPlayerWeaponSlot(client, 4); // Slots start at 0. Slot Five equals 4 here.
		if (PillSlot == -1) // this gets returned if you got no Pillz.
		{
			PrintToChat(client, "\x04You aint got no Pills.");
			return Plugin_Continue;
		}
		else //if you DONT have NO PILLs ... you must have some :P
		{
			RemovePlayerItem(client, PillSlot);
			
			PrintToChatAll("\x04%N\x01 used his pills and revived himself!", client); //whom are we kidding. theyll cry wolf, eh, cheater
			
			//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0); //get him back up
			//SetEntityMoveType(client, MOVETYPE_WALK); //dont leave him immobile. that would be cruel :P
			EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
			
			new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
			new count = GetEntData(client, propincapcounter, 1);
			count++;
			
			new userflags = GetUserFlagBits(client);
			SetUserFlagBits(client, ADMFLAG_ROOT);
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(client,"give health");
			SetCommandFlags("give", iflags);
			SetUserFlagBits(client, userflags);
			
			SetEntData(client, propincapcounter, count, 1);
			
			new Handle:revivehealth = FindConVar("survivor_revive_health"); // set health nicely according to convar.
			//SetEntProp(client, Prop_Send, "m_iHealth", 1); //hard health is always 1 after incap, unless healed
			CreateTimer(0.1, SetHP1, client); // set it delayed, like tPoncho in Perkmod
			new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
			SetEntDataFloat(client, temphpoffset, GetConVarFloat(revivehealth), true);
		}
	}
	return Plugin_Continue;
}

public Action:ResetDelay(Handle:timer, Handle:client)
{
	buttondelay[client] = false;
}

public Action:SetHP1(Handle:timer, any:client)
{
	SetEntityHealth(client, 1);
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

public Event_Incap (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapDelay[client] = true;
	CreateTimer(GetConVarFloat(DelaySetting), AdvertisePills, client);
}

public Action:AdvertisePills(Handle:timer, any:client)
{
	IncapDelay[client] = false;
	if (!client) return;
	if (!IsClientInGame(client)) return;
	
	new PillSlot = GetPlayerWeaponSlot(client, 4); // Slots start at 0. Slot Five equals 4 here.
	if (PillSlot != -1) // this means he has anything but NO Pills xD
		PrintToChat(client, "\x01You have Pills, you can now press \x04USE \x01to pop them and stand back up by yourself");
}

public Event_StartPwn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	IsBeingPwnt[victim] = true;
}

public Event_StartRevive (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!client) return;
	IsBeingRevived[client] = true;
}

public Event_EndPwn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	IsBeingPwnt[victim] = false;
}

public Event_EndRevive (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!client) return;
	IsBeingRevived[client] = false;
}

public UnPwnAll (Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1 ; i<=MaxClients ; i++)
	{
		IsBeingPwnt[i] = false;
	}
}

public UnPwnUserid (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	IsBeingPwnt[client] = false;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CanUsePills = false;
	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CanUsePills = true;
	return Plugin_Continue;
}

public OnMapStart() { CanUsePills = true; }