#pragma semicolon 1
#define PLUGIN_VERSION "4.10"
#include <sourcemod>
#include <sdktools>
// Don't have colors include file? get it here: http://forums.alliedmods.net/showthread.php?t=96831 (This version only works on 2007 Engine!!)
#include <colors>

/* Author notice
	-- By slaping the player, they can also abuse it. (If they jump in the same time as the slap command gets in effect.
	-- We should probably use anoter methor of 'punishing' the player so they can't fly away.
	-- Thank you for reading this,
	-- Jonny
*/

/*ChangeLog
1.00	Release
1.10	Totals for Admin
1.20	Reset Options
1.30	Punish option
2.00	Updated Punishment to a more serious matter
2.10	Inserted Punish sound
2.20	Inserted timer for Punish sound
3.00	Fixed not playing right sound
3.10	Sound emit code redone
3.20	Added "Colors"
4.00	Owners don't get punished
4.10	Can see who planted the barricade
*/

// Temp fix for server crashing if no team were found
#define NULL		0
#define NULL2		1

// Define the teams
#define SURVIVOR	2
#define ZOMBIE		3
#define READY		4

public Plugin:myinfo =
{
	name = "ZPS Barricade Killer",
	author = "Will2Tango, Edited by JonnyBoy0719",
	description = "Notification when a Survivor Kills a Barricade. And also haves a punish system.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=218159"
}

//Cvars
new Handle:hEnabled = INVALID_HANDLE;
new Handle:hPunish = INVALID_HANDLE;
new Handle:hPunishscale = INVALID_HANDLE;
new Handle:hPunishSound = INVALID_HANDLE;
new Handle:hPunishmultiply = INVALID_HANDLE;
new Handle:hPunishTotal = INVALID_HANDLE;
new Handle:hPunishOwner = INVALID_HANDLE;
new Handle:hPunishOwnerText = INVALID_HANDLE;
new Handle:hReset = INVALID_HANDLE;

new bool:gEnabled = true;
new gReset = 1;
new gPunish = 0;
new gPunishscale = 1;
new gPunishSound = 1;
new gPunishmultiply = 2;
new gPunishTotal = 5;
new gPunishOwner = 1;
new gPunishOwnerText = 1;
// handles the timer, so we don't make some sound spam.
new punish_sound_timer = 1;

//Player Vars
new cadeKillCount[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{
	//Cvars
	CreateConVar("zps_barricadekiller_version", PLUGIN_VERSION, "ZPS Barricade Killer Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnabled = CreateConVar("sm_barricadekiller_enabled", "1", "Turns Barricade Killer Off/On. (1/0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hPunish = CreateConVar("sm_barricadekiller_punish", "0", "Punish the person who broke it, 0=disabled, 1=slap.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hPunishSound = CreateConVar("sm_barricadekiller_punish_sound", "1", "Enables the punishment sound for the client, 0=disabled, 1=enabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hPunishscale = CreateConVar("sm_barricadekiller_punish_scale", "1", "Set the slap damage, 1=min, 99=max.", FCVAR_PLUGIN, true, 1.0, true, 99.0);
	hPunishmultiply = CreateConVar("sm_barricadekiller_punish_multiply", "2", "Set the slap damage multiplier, 1=min, 99=max.", FCVAR_PLUGIN, true, 0.0, true, 99.0);
	hPunishTotal = CreateConVar("sm_barricadekiller_punish_total", "5", "How many times they need to break a barricade until punishment takes effect, 1=min, 15=max.", FCVAR_PLUGIN, true, 1.0, true, 15.0);
	hPunishOwner = CreateConVar("sm_barricadekiller_punish_owner", "1", "Don't punish the owner, 0=disabled, 1=enabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hPunishOwnerText = CreateConVar("sm_barricadekiller_punish_owner_text", "1", "Show who planted the barricade (Survivor only), 0=disabled, 1=enabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hReset = CreateConVar("sm_barricadekiller_reset", "2", "When to reset Running Totals, 0=never, 1=map, 2=round.", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	HookConVarChange(hEnabled, ConVarChange);
	HookConVarChange(hPunish, ConVarChange);
	HookConVarChange(hPunishscale, ConVarChange);
	HookConVarChange(hPunishSound, ConVarChange);
	HookConVarChange(hPunishmultiply, ConVarChange);
	HookConVarChange(hPunishTotal, ConVarChange);
	HookConVarChange(hPunishOwner, ConVarChange);
	HookConVarChange(hPunishOwnerText, ConVarChange);
	HookConVarChange(hReset, ConVarChange);
	
	//Hooks
	HookEvent("break_prop", SomethingBroke);
	HookEvent("player_spawn", PlayerSpawn);
	
	//Translations
	LoadTranslations("barricadekiller.phrases");
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	gEnabled = GetConVarBool(hEnabled);
	gPunish = GetConVarBool(hPunish);
	gPunishscale = GetConVarBool(hPunishscale);
	gPunishSound = GetConVarBool(hPunishSound);
	gPunishmultiply = GetConVarBool(hPunishmultiply);
	gPunishTotal = GetConVarBool(hPunishTotal);
	gPunishOwner = GetConVarBool(hPunishOwner);
	gPunishOwnerText = GetConVarBool(hPunishOwnerText);
	gReset = GetConVarInt(hReset);
}

public OnMapEnd()
{
	if (gEnabled && gReset == 1)
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				cadeKillCount[i] = 0;
			}
		}
	}
	
	punish_sound_timer = 1;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gEnabled && gReset == 2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetClientTeam(client);
		
		if (team == READY)
		{
			cadeKillCount[client] = 0;
		}
	}
	
	punish_sound_timer = 1;
}

public Action:SomethingBroke(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (!gEnabled)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	// Server keeps crashing if there is no team, hope this fixes it.
	if (team == NULL || team == NULL2)
	{
		// This will disable the plugin if there is no players, This should probably be edited that it checks for players, if non is found, its disable. Or checks after each round etc.
		return;
	}
	
	if (team == SURVIVOR)
	{
		new ent = GetEventInt(event, "entindex");
		
		decl String:model[128];
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
		
		if (StrContains(model, "/barricades/", false) != -1)
		{
			cadeKillCount[client]++;
			
			new String:killerName[MAX_NAME_LENGTH];
			GetClientName(client, killerName, sizeof(killerName));
			
			new total = cadeKillCount[client];
			new total_goal = gPunishTotal;
			new flags;
			
			for (new i = 1; i < MaxClients; i++)
			{
				flags = GetUserFlagBits(i);
				
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
				
					// Removed some lines, so it counts the scale, total and punish multiply all the time.
					if (gPunish == 1)
					{
						// Needs to be recoded, since it doesn't want to work correctly.
						if (total > total_goal)
						{
							// Now more serious, and makes sure it doesn't get abused (IF SLAP).
							SlapPlayer(client, gPunishscale+total*gPunishmultiply*gPunishTotal);
							// DEBUG test
							//CPrintToChat(i, "{green}Debug #2: {olive}gPunishscale+total*gPunishmultiply*gPunishTotal");
						}
						else
						{
							// Currently abuseable (IF SLAP).
							SlapPlayer(client, gPunishscale+total*gPunishmultiply);
							// DEBUG test
							//CPrintToChat(i, "{green}Debug #1: {olive}gPunishscale+total*gPunishmultiply");
						}
						
						if (gPunishOwnerText == 1)
						{
							/* TODO: Show the barricade Owner/The person who placed it */
						}
						
						if (gPunishOwner == 1)
						{
							/* TODO: We don't wanna punish the owner of the barricade, or shall we do it?*/
						}
						
						// More simpler code to just emit the sound.
						if (gPunishSound && gPunish == 1 || total > total_goal)
						{
							if (punish_sound_timer == 1)
							{
								// A fun little sound that plays if he keeps breaking barricades. Still need to make sure the volume ain't so loud. 25% volume will work.
								// Should be custimizeable? So the owner can set the sound.
								EmitSoundToClient(client, "Humans/HumanPunk/Taunts/Taunt-07.wav");
								// Ditto
								punish_sound_timer = 0;
								// Lets make a delay so it doesn't spam the sound after each barricade breaks.
								CreateTimer(5.0, DelayPunishSound);
							}
						}
					}
				
					if (i == client)
					{
						if (gPunish == 1)
						{
							CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "You_Punish");
						}
						else
						{
							CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "You");
						}
					}
					else
					{
						
						if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC)
						{
							if (gPunish == 1)
							{
								CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "Admin_Punish", killerName, total);
							}
							else
							{
								CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "Admin", killerName, total);
							}
						}
						else if (GetClientTeam(i) == SURVIVOR)
						{
							if (gPunish == 1)
							{
								CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "All_Punish", killerName);
							}
							else
							{
								CPrintToChat(i, "[{green}Barricade Killer{default}] {olive}%t", "All", killerName);
							}
						}
					}
				}
			}
			
			LogMessage("%L Broke a Barricade! (%i)", client, total);
		}
	}
}

// Enable the sound again.
public Action:DelayPunishSound(Handle:timer)
{
	// AFter the delay, we enable the sound again, so it doesn't play over itself.
	punish_sound_timer = 1;
}