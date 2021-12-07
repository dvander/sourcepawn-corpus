//
// SourceMod Script
//
// Developed by <eVa>Dog
// August 2008
// http://www.theville.org
//

// Taken from my Realism Mod
// Incorporated features from DoD Medic mod
// Credit to Hell Phoenix and DJ Tsunami for working on the original DoD Medic plugin

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.111"

#define IN  (0x0001 | 0x0010)
#define OUT (0x0002 | 0x0008)

//new health[33]
//new yell[33]
//new kits[33]
//new bleeding[33];

new Handle:Cvar_Enabled			= INVALID_HANDLE
new Handle:Cvar_MinHealth 		= INVALID_HANDLE
new Handle:Cvar_MedicDelay 		= INVALID_HANDLE
new Handle:Cvar_Freeze			= INVALID_HANDLE
new Handle:Cvar_FreezeTime  	= INVALID_HANDLE
new Handle:Cvar_FTB				= INVALID_HANDLE
new Handle:Cvar_HealthMinRefund = INVALID_HANDLE
new Handle:Cvar_HealthMaxRefund = INVALID_HANDLE
new Handle:Cvar_HealthRandom	= INVALID_HANDLE
new Handle:Cvar_MedicKits		= INVALID_HANDLE
new Handle:Cvar_HP 				= INVALID_HANDLE
new Handle:Cvar_Yell			= INVALID_HANDLE
new Handle:Cvar_Alpha			= INVALID_HANDLE
new Handle:Cvar_Red				= INVALID_HANDLE
new Handle:Cvar_Green			= INVALID_HANDLE
new Handle:Cvar_Blue			= INVALID_HANDLE
new Handle:Cvar_Chat			= INVALID_HANDLE
//Add 
new Handle:Cvar_Bleeding = INVALID_HANDLE;
//new Handle:Cvar_Overlay = INVALID_HANDLE;

new Handle:g_BleedTimers[MAXPLAYERS+1];

new health[MAXPLAYERS+1];
new yell[MAXPLAYERS+1];
new kits[MAXPLAYERS+1];
new bleeding[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Medic Mod",
	author = "<eVa>Dog",
	description = "Medic Mod for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_medic_version", PLUGIN_VERSION, "Version of sm_medic", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_Enabled 			= CreateConVar("sm_medic_enable", "1", " enables/disables the Medic mod", FCVAR_PLUGIN)
	Cvar_MinHealth 			= CreateConVar("sm_medic_health", "25", " The minimum health before healing can take place", FCVAR_PLUGIN)
	Cvar_MedicDelay 		= CreateConVar("sm_medic_delay", "1.0", " The delay before healing can take place (0.1 to disable)", FCVAR_PLUGIN)
	Cvar_Yell		 		= CreateConVar("sm_medic_yell", "3.0", " delay allowed between calling for a medic (3.0 default)", FCVAR_PLUGIN)
	Cvar_MedicKits		 	= CreateConVar("sm_medic_kits", "2", " amount of times per life to be able to use !medic (2 default)", FCVAR_PLUGIN)
	Cvar_Freeze		 		= CreateConVar("sm_medic_freeze", "1", " 0 = no freezing 1 = freezing (1 default)", FCVAR_PLUGIN)
	Cvar_FreezeTime 		= CreateConVar("sm_medic_freeze_time", "3.0", " time to freeze player on healing (3.0 default)", FCVAR_PLUGIN)
	Cvar_HealthMinRefund 	= CreateConVar("sm_medic_minhealth", "30", " minimum amount of health to give back to player(30 default)", FCVAR_PLUGIN)
	Cvar_HealthMaxRefund 	= CreateConVar("sm_medic_maxhealth", "50", " maximum amount of health to give back to player(50 default)", FCVAR_PLUGIN)
	Cvar_HealthRandom		= CreateConVar("sm_medic_randomhealth", "0", " 0 = health refund equals sm_medic_maxhealth cvar 1 = random number between sm_medic_minhealth and sm_medic_maxhealth (1 default)", FCVAR_PLUGIN)
	Cvar_HP					= CreateConVar("sm_medic_hp", "100", " set a player's health at respawn", FCVAR_PLUGIN)
	Cvar_FTB				= CreateConVar("sm_medic_ftb", "1", " 0 does not fade the screen, 1 fades the screen (default: 1)", FCVAR_PLUGIN)
	Cvar_Alpha 				= CreateConVar("sm_medic_alpha", "210", " level of alpha to apply to FTB - 255 is completely opaque 0 is transparent (default: 210)", FCVAR_PLUGIN)
	Cvar_Red				= CreateConVar("sm_medic_red", "0", " amount of red color (default: 0)", FCVAR_PLUGIN)
	Cvar_Green				= CreateConVar("sm_medic_green", "0", " amount of green color (default: 0)", FCVAR_PLUGIN)
	Cvar_Blue				= CreateConVar("sm_medic_blue", "0", " amount of blue color (default: 0)", FCVAR_PLUGIN)
	Cvar_Chat				= CreateConVar("sm_medic_chat", "2", " 0=no chat 1=minimal chat 2=full chat", FCVAR_PLUGIN)
	
	//add_Cvar
	Cvar_Bleeding 			= CreateConVar("sm_medic_bleeding", "20", " The health at which bleeding starts (0 to disable)", FCVAR_PLUGIN);
	
	
	RegConsoleCmd("voice_medic", Medack, " -  Calls in the medic")
	
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_say", PlayerSayEvent, EventHookMode_Pre)
	//Add Hooks
	HookEvent("player_hurt", PlayerHurtEvent);
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("player_disconnect", PlayerDisconnectEvent);
	
	
	LoadTranslations("dodmedic.phrases")
	AutoExecConfig(true, "medic");
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_say", PlayerSayEvent)
	//Add Hooks
	UnhookEvent("player_hurt", PlayerHurtEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
	UnhookEvent("player_disconnect", PlayerDisconnectEvent);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/bandage/bandage.mp3")
	PrecacheSound("bandage/bandage.mp3", true)
	//Add
	PrecacheSound("player/damage/male/minorpain.wav", true);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Cvar_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		if (client > 0)
		{
			if (IsClientInGame(client))
			{		
				yell[client] = 0
				kits[client] = GetConVarInt(Cvar_MedicKits)
				SetEntityHealth(client, GetConVarInt(Cvar_HP))
			}
		}
	}
}

public Action:Medack(client, args)
{
	if (GetConVarInt(Cvar_Enabled))
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (yell[client] == 0)
				{
					if (kits[client] > 0)
					{
						health[client] = GetClientHealth(client)
														
						if (health[client] < GetConVarInt(Cvar_MinHealth))
						{	
							if (GetConVarInt(Cvar_FTB) == 1)
							{
								ScreenFade(client, GetConVarInt(Cvar_Red), GetConVarInt(Cvar_Green), GetConVarInt(Cvar_Blue), GetConVarInt(Cvar_Alpha), 5000, OUT)
								CreateTimer(GetConVarFloat(Cvar_FreezeTime), UnFade, client)
							}			
							
							if (GetConVarInt(Cvar_Freeze) == 1)
							{
								SetEntityMoveType(client, MOVETYPE_NONE)
								CreateTimer(GetConVarFloat(Cvar_FreezeTime), Release, client)
							}							
							
							if (GetConVarInt(Cvar_Chat) == 2)
								PrintToChat(client, "[SM] %t", "Roger")
								
							CreateTimer(GetConVarFloat(Cvar_MedicDelay), Heal, client)
							yell[client] = 1
							CreateTimer(GetConVarFloat(Cvar_Yell), ResetYell, client)
							kits[client]--
							
							if (GetConVarInt(Cvar_Chat) >= 1)
							{
								if ((kits[client] > 1) || (kits[client] < 1))
								{
									PrintToChat(client, "[SM] %t %d %t", "YourMedic", kits[client], "HealthKits")
								}
								else
								{
									PrintToChat(client, "[SM] %t %d %t", "YourMedic", kits[client], "HealthKit")
								}
							}
						}
						else
						{
							if (GetConVarInt(Cvar_Chat) >= 1)
								PrintToChat(client, "[SM] %d %t", health[client], "QueryHealth") 
								
							yell[client] = 1
							CreateTimer(GetConVarFloat(Cvar_Yell), ResetYell, client)
						}
					}
					else
					{
						if (GetConVarInt(Cvar_Chat) >= 1)
							PrintToChat(client, "[SM] %t", "NoHealthKits")
					}
				}
			}
		}
	}
}

public PlayerSayEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Cvar_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))	
			
		new String:text[200] 
		GetEventString(event, "text", text, 200)

		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (StrEqual(text, "!medic") || StrEqual(text, "medic"))
				{
					if (yell[client] == 0)
					{
						if (kits[client] > 0)
						{				
							health[client] = GetClientHealth(client)
							
							if (health[client] < GetConVarInt(Cvar_MinHealth))
							{							
								if (GetConVarInt(Cvar_FTB) == 1)
								{
									ScreenFade(client, GetConVarInt(Cvar_Red), GetConVarInt(Cvar_Green), GetConVarInt(Cvar_Blue), GetConVarInt(Cvar_Alpha), 5000, OUT)
									CreateTimer(GetConVarFloat(Cvar_FreezeTime), UnFade, client)
								}
								if (GetConVarInt(Cvar_Freeze) == 1)
								{
									SetEntityMoveType(client, MOVETYPE_NONE)
									CreateTimer(GetConVarFloat(Cvar_FreezeTime), Release, client)
								}
						
								ClientCommand(client, "voice_medic")
								
								if (GetConVarInt(Cvar_Chat) == 2)
									PrintToChat(client, "[SM] %t", "Roger")
									
								CreateTimer(GetConVarFloat(Cvar_MedicDelay), Heal, client)
								yell[client] = 1
								CreateTimer(GetConVarFloat(Cvar_Yell), ResetYell, client)
								kits[client]--
								
								if (GetConVarInt(Cvar_Chat) >= 1)
								{
									if ((kits[client] > 1) || (kits[client] < 1))
									{
										PrintToChat(client, "[SM] %t %d %t", "YourMedic", kits[client], "HealthKits")
									}
									else
									{
										PrintToChat(client, "[SM] %t %d %t", "YourMedic", kits[client], "HealthKit")
									}
								}
							}
							else
							{
								if (GetConVarInt(Cvar_Chat) >= 1)
									PrintToChat(client, "[SM] %d %t", health[client], "QueryHealth") 
									
								yell[client] = 1
								CreateTimer(GetConVarFloat(Cvar_Yell), ResetYell, client)
							}
						}
						else
						{
							if (GetConVarInt(Cvar_Chat) >= 1)
								PrintToChat(client, "[SM] %t", "NoHealthKits")
						}
					}
				}
			}
		}
	}
}

public Action:ResetYell(Handle:timer, any:client)
{
	yell[client] = 0
}

public Action:Heal(Handle:timer, any:client)
{
	if (client > 0)
	{													
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{	
			health[client] = GetClientHealth(client)

			if (GetConVarInt(Cvar_HealthRandom) == 1)
			{
				new randomnumber = GetRandomInt(GetConVarInt(Cvar_HealthMinRefund), GetConVarInt(Cvar_HealthMaxRefund))
				health[client] = health[client] + randomnumber
			}				
			else
			{
				health[client] = health[client] + GetConVarInt(Cvar_HealthMaxRefund)
			}
			
			SetEntityHealth(client, health[client])
			EmitSoundToClient(client, "bandage/bandage.mp3", _, _, _, _, 0.8)
					
			yell[client] = 0
			//Add
			bleeding[client] = 0;
		}
		else
		{
			if (GetConVarInt(Cvar_Chat) == 2)
				PrintToChat(client, "[SM] %t", "RaiseDead")
		}
	}
	
}

public Action:Release(Handle:timer, any:client)
{
    if (client)
    {
        if (IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
				SetEntityMoveType(client, MOVETYPE_WALK)
            }
        }
    }
}  

public Action:UnFade(Handle:timer, any:client)
{
    if (client)
    {
        if (IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
				ScreenFade(client, 0, 0, 0, 0, 2000, IN)
			}
		}
	}
}

//Fade the screen
public ScreenFade(client, red, green, blue, alpha, duration, type)
{
	new Handle:msg
	
	msg = StartMessageOne("Fade", client)
	BfWriteShort(msg, 1500)
	BfWriteShort(msg, duration)
	BfWriteShort(msg, type)
	BfWriteByte(msg, red)
	BfWriteByte(msg, green)
	BfWriteByte(msg, blue)	
	BfWriteByte(msg, alpha)
	EndMessage()
}

//Add_function

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillBleedTimer(client);
}

public PlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client > 0)
	{
		if (IsClientInGame(client))
		{	
			health[client] = GetClientHealth(client);
			
			if ((health[client] < GetConVarInt(Cvar_Bleeding)) && (health[client] >= 3) && (bleeding[client] == 0))
			{
				if (GetConVarInt(Cvar_Chat) >= 1)
					PrintToChat(client,"[SM] %t", "Bleedhard");	
					
				bleeding[client] = 1;
				if (IsPlayerAlive(client))
				{
					g_BleedTimers[client] = CreateTimer(2.0, Bleed, client, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action:Bleed(Handle:Timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillBleedTimer(client);
		return Plugin_Handled;
	}
	if (client > 0 && IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			health[client] = GetClientHealth(client);
			EmitSoundToClient(client, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
		
			if ((health[client] < GetConVarInt(Cvar_Bleeding)) && (health[client] >= 3))
			{
				health[client] = health[client] - 2;
				SetEntityHealth(client, health[client]);
				if (GetConVarInt(Cvar_Chat) >= 1)
				PrintToChat(client,"[SM] %t", "Bleedsay");
				//PrintToChat(client,"[SM] status bledding = %d", bleeding[client]);
			}
			else
			{
				KillBleedTimer(client);
				return Plugin_Stop;
			}
			if (health[client] <= 2)
			{
				//ForcePlayerSuicide(client);
				SlapPlayer(client, health[client]=5, false);
				bleeding[client] = 0;
				KillBleedTimer(client);
				//PrintToChat(client,"[SM] , You are Killing  %d", health[client]);
				if (IsPlayerAlive(client))
				{
					if (GetConVarInt(Cvar_Chat) >= 1)
					PrintToChat(client,"[SM] %t", "Bleedstop");
				}
				return Plugin_Stop;
			}	
		}
		else
		{
			KillBleedTimer(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

KillBleedTimer(client)
{
	if (g_BleedTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_BleedTimers[client]);
		g_BleedTimers[client] = INVALID_HANDLE;
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillBleedTimer(client);
}