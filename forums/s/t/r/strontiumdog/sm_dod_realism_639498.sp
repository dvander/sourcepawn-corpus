//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin is a port of the Realism Mod
// originally compiled or EventScripts by LJFSP, Colster
// but with more controllable features and updated stuff
// Additional testing and fixing by Lebson



#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.202"

#define HIDE  (0x0001 | 0x0010)
#define SHOW (0x0002)

new Handle:Cvar_MinHealth = INVALID_HANDLE;
new Handle:Cvar_Bleeding = INVALID_HANDLE;
new Handle:Cvar_MedicDelay = INVALID_HANDLE;
new Handle:Cvar_Overlay = INVALID_HANDLE;
new Handle:Cvar_Knock = INVALID_HANDLE;
new Handle:Cvar_Drop = INVALID_HANDLE;
new Handle:Cvar_Slow = INVALID_HANDLE;
new Handle:Cvar_Head = INVALID_HANDLE;
new Handle:Cvar_Rocket_Gravity = INVALID_HANDLE;
new Handle:Cvar_Rocket_Speed = INVALID_HANDLE;
new Handle:Cvar_MG_Speed = INVALID_HANDLE;
new Handle:Cvar_MG_Gravity = INVALID_HANDLE;
new Handle:Cvar_Medic_Use = INVALID_HANDLE;
new Handle:Cvar_FTB = INVALID_HANDLE;
new Handle:Cvar_HealFTB = INVALID_HANDLE;
new Handle:Cvar_Freeze = INVALID_HANDLE;
new Handle:Cvar_FreezeTime = INVALID_HANDLE;
new Handle:Cvar_HP = INVALID_HANDLE;
new Handle:Cvar_Msg = INVALID_HANDLE;
new Handle:medic_plugin = INVALID_HANDLE;

new Handle:g_BleedTimers[MAXPLAYERS+1];

new health[MAXPLAYERS+1];
new yell[MAXPLAYERS+1];
new medic_called[MAXPLAYERS+1];
new bleeding[MAXPLAYERS+1];

new Float:round_time_start;
new Float:round_time_end;

	
public Plugin:myinfo = 
{
	name = "sm_dod_realism",
	author = "<eVa>Dog",
	description = "Realism Mod for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

public OnPluginStart()
{
	CreateConVar("sm_dod_realism_version", PLUGIN_VERSION, "Version of sm_dod_realism", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_MinHealth = CreateConVar("sv_realism_health", "25", " The minimum health before healing can take place", FCVAR_PLUGIN);
	Cvar_Bleeding = CreateConVar("sv_realism_bleeding", "20", " The health at which bleeding starts (0 to disable)", FCVAR_PLUGIN);
	Cvar_MedicDelay = CreateConVar("sv_realism_medic_delay", "2.0", " The delay before healing can take place (0.1 to disable)", FCVAR_PLUGIN);
	Cvar_Overlay = CreateConVar("sv_realism_overlay", "1", " When players get hurt, they get an red overlay (0 to disable)", FCVAR_PLUGIN);
	Cvar_Drop = CreateConVar("sv_realism_drop", "1", " When players get hurt in the arm, they drop their weapon (0 to disable)", FCVAR_PLUGIN);
	Cvar_Slow = CreateConVar("sv_realism_slow", "1", " When players get hurt in the leg, they slow down (0 to disable)", FCVAR_PLUGIN);
	Cvar_Head = CreateConVar("sv_realism_headshots", "2", " Display to player(s) if attacker made a headshot (0 to disable 1 for client 2 for all players)", FCVAR_PLUGIN);
	Cvar_Rocket_Gravity = CreateConVar("sv_realism_rocket_gravity", "1.9", " Sets the gravity of players playing the rocket class (1.0 is normal - higher number means heavier)", FCVAR_PLUGIN);
	Cvar_Rocket_Speed = CreateConVar("sv_realism_rocket_speed", "0.7", " Sets the speed of players playing the rocket class (1.0 is normal - small number means slower)", FCVAR_PLUGIN);
	Cvar_MG_Gravity = CreateConVar("sv_realism_mg_gravity", "1.7", " Sets the gravity of players playing the MG class (1.0 is normal - higher number means heavier)", FCVAR_PLUGIN);
	Cvar_MG_Speed = CreateConVar("sv_realism_mg_speed", "0.8", " Sets the speed of players playing the MG class (1.0 is normal - small number means slower)", FCVAR_PLUGIN);
	Cvar_Medic_Use = CreateConVar("sv_realism_medic_max", "10", " Sets the number of times medic can be used (200 to disable)", FCVAR_PLUGIN);
	Cvar_FTB = CreateConVar("sv_realism_ftb", "1", " sets Fade to Black (0 to disable ftb)", FCVAR_PLUGIN);
	Cvar_HealFTB = CreateConVar("sv_realism_healftb", "1", " sets Fade to Black when being Healed (0 to disable Heal ftb)", FCVAR_PLUGIN);
	Cvar_Freeze = CreateConVar("sv_realism_freeze", "1", " freeze player on healing (0 to disable freezing)", FCVAR_PLUGIN);
	Cvar_FreezeTime = CreateConVar("sv_realism_freeze_time", "5.0", " time to freeze player on healing (5.0 default)", FCVAR_PLUGIN);
	Cvar_Knock = CreateConVar("sv_realism_knockback", "1", " throw player backwards on injury (0 to disable knockback)", FCVAR_PLUGIN);
	Cvar_HP = CreateConVar("sv_realism_hp", "100", " set a player's health at respawn", FCVAR_PLUGIN);
	Cvar_Msg = CreateConVar("sv_realism_msg", "1", " enables/disables messages", FCVAR_PLUGIN);
	
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_say", PlayerSayEvent, EventHookMode_Pre);
	HookEvent("player_hurt", PlayerHurtEvent);
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("player_disconnect", PlayerDisconnectEvent);
	HookEvent("dod_round_start", PlayerRoundStartEvent);
	HookEvent("dod_round_win", PlayerRoundWinEvent);
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
	UnhookEvent("player_say", PlayerSayEvent);
	UnhookEvent("player_hurt", PlayerHurtEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
	UnhookEvent("player_disconnect", PlayerDisconnectEvent);
	UnhookEvent("dod_round_start", PlayerRoundStartEvent);
	UnhookEvent("dod_round_win", PlayerRoundWinEvent);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/bandage/bandage.mp3");
	PrecacheSound("bandage/bandage.mp3", true);
	PrecacheSound("player/damage/male/minorpain.wav", true);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			if ( GetConVarInt(Cvar_Overlay) == 1 )
			{
				ScreenFade(client, 0, 0, 0, 0, 5000, HIDE);
			}
			
			yell[client] = 0;
			medic_called[client] = 0;
			
			SetEntityGravity(client, 1.0);
			
			new class = GetEntProp(client, Prop_Send, "m_iPlayerClass");
			
			if (class == 4)
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(Cvar_MG_Speed));
				SetEntityGravity(client, GetConVarFloat(Cvar_MG_Gravity));
			}
			if (class == 5)
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(Cvar_Rocket_Speed));
				SetEntityGravity(client, GetConVarFloat(Cvar_Rocket_Gravity));
			}
			
			SetEntityHealth(client, GetConVarInt(Cvar_HP));
		}
	}
}


public PlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client     = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			new String:weapon[64];
			GetEventString(event, "weapon", weapon, 64);
			
			new hitgroup = GetEventInt(event, "hitgroup");
			new damage   = GetEventInt(event, "damage");
			
			// Hitgroups
			// 1 = Head
			// 2 = Upper Chest
			// 3 = Lower Chest
			// 4 = Left arm
			// 5 = Right arm
			// 6 = Left leg
			// 7 = Right Leg
			  
			  
			if ( GetConVarInt(Cvar_Drop) == 1 )
			{
				if (!(StrEqual(weapon, "bazooka") || StrEqual(weapon, "pschreck") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "riflegren_ger")))
				{
					if ((hitgroup == 4) || (hitgroup == 5))
					{
						if (damage >= 40)
						{
							FakeClientCommandEx(client, "drop");
							
							if (GetConVarBool(Cvar_Msg))
								PrintToChat(client,"\x01\x04[SM] You got shot in the arm - pick up your gun");
						}
					}
					if ( GetConVarInt(Cvar_Knock) == 1 )
					{
						Injure(client, attacker, damage);
					}
				}
			}
			
			if ( GetConVarInt(Cvar_Slow) == 1 )
			{		
				if ((hitgroup == 6) || (hitgroup == 7))
				{
					if (damage >= 40)
					{
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.5);
						SetEntityGravity(client, 1.4);
					}
				}
			}
			
			if (hitgroup == 1)
			{
				if (attacker > 0)
				{
					new String:attacker_name[64]
					GetClientName(attacker, attacker_name, 64)
					
					if ( GetConVarInt(Cvar_Head) == 2 )
					{
						PrintToChatAll("\x01\x04[SM] %s made a headshot", attacker_name);
					}
					else if ( GetConVarInt(Cvar_Head) == 1 )
					{
						PrintToChat(client, "\x01\x04[SM] %s made a headshot", attacker_name);
					}
				}
			}
			
			if ( GetConVarInt(Cvar_Overlay) == 1 )
			{
				ShowHurt(client);
			}
			
			health[client] = GetClientHealth(client);
			
			if ((health[client] < GetConVarInt(Cvar_Bleeding)) && (health[client] >= 3) && (bleeding[client] == 0))
			{
				if (GetConVarBool(Cvar_Msg))
					PrintToChat(client,"\x01\x04[SM] You are bleeding....");
					
				bleeding[client] = 1;
				if (IsPlayerAlive(client))
				{
					g_BleedTimers[client] = CreateTimer(2.0, Bleed, client, TIMER_REPEAT);
				}
			}
		}
	}
}


public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillBleedTimer(client);
	
	if (GetConVarInt(Cvar_FTB) == 1)
	{
		ScreenFade(client, 0, 0, 0, 255, 5000, SHOW);
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillBleedTimer(client);
}

public PlayerRoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_time_start = GetGameTime();
}

public PlayerRoundWinEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_time_end = GetGameTime();
	
	new roundwon, mins, secs;
	roundwon = RoundFloat(round_time_end - round_time_start);
	
	mins = roundwon / 60;
	secs = roundwon % 60;

	new String:message[64];
	Format(message, 64, "Round won in: %d mins : %d secs", mins, secs);
	SendPanelToAll("ROUND OVER", message);
}

public PlayerSayEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	new String:text[200]; 
	GetEventString(event, "text", text, 200);

	medic_plugin = FindConVar("sm_dod_medic_version");
	if (medic_plugin == INVALID_HANDLE )
	{
		if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (StrEqual(text, "!medic") || StrEqual(text, "medic"))
			{
				if (medic_called[client] < GetConVarInt(Cvar_Medic_Use))
				{
					if (yell[client] == 0)
					{
						health[client] = GetClientHealth(client);
						
						if (health[client] < GetConVarInt(Cvar_MinHealth))
						{
							ClientCommand(client, "voice_medic");
							
							if (GetConVarBool(Cvar_Msg))
								PrintToChat(client, "[SM] Roger that - medic coming...");
								
							CreateTimer(GetConVarFloat(Cvar_MedicDelay), Heal, client);
							yell[client] = 1;
							medic_called[client]++;
						}
						else
						{
							if (GetConVarBool(Cvar_Msg))
								PrintToChat(client, "[SM] %d HP? You don't need a medic! Get up on your feet, soldier! Get back in there and fight!", health[client]);
						}
					}
					else
					{
						if (GetConVarBool(Cvar_Msg))
							PrintToChat(client, "[SM] Quit your yelling - I'll be there in a minute");
					}
				}
				else
				{	
					if (GetConVarBool(Cvar_Msg))
						PrintToChat(client, "[SM] I got other soldiers to deal with");
				}
			}
			
		}
	}
}


public Action:Heal(Handle:timer, any:client)
{
	medic_plugin = FindConVar("sm_dod_medic_version");
	if ( medic_plugin == INVALID_HANDLE )
	{
		if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		{													
			new randomnumber = GetRandomInt(30, 50);
			
			if ( GetConVarInt(Cvar_Freeze) == 1 )
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
				CreateTimer(GetConVarFloat(Cvar_FreezeTime), Release, client);
			}
			
			if ( GetConVarInt(Cvar_HealFTB) == 1 )
			{
				ScreenFade(client, 0, 0, 0, 220, 2000, SHOW);
				CreateTimer(GetConVarFloat(Cvar_FreezeTime), UnFade, client);
			}
			
			health[client] = GetClientHealth(client);

			health[client] = health[client] + randomnumber;
			SetEntityHealth(client, health[client]);
			EmitSoundToClient(client, "bandage/bandage.mp3", _, _, _, _, 0.8);
			yell[client] = 0;
			bleeding[client] = 0;
			
			SetEntityGravity(client, 1.0);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			new class = GetEntProp(client, Prop_Send, "m_iPlayerClass");
			
			if (class == 4)
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(Cvar_MG_Speed));
				SetEntityGravity(client, GetConVarFloat(Cvar_MG_Gravity));
			}
			if (class == 5)
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(Cvar_Rocket_Speed));
				SetEntityGravity(client, GetConVarFloat(Cvar_Rocket_Gravity));
			}
		}
	}
}

public Action:Release(Handle:timer, any:client)
{
    if (client)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
    }
}  

public Action:UnFade(Handle:timer, any:client)
{
    if (client)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
			if ( GetConVarInt(Cvar_Overlay) == 1 )
				ShowHurt(client);
			
			ScreenFade(client, 0, 0, 0, 0, 5000, HIDE);
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
			
			if ( GetConVarInt(Cvar_Overlay) == 1 )
				ShowHurt(client);
			
			EmitSoundToClient(client, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
			
			if ((health[client] < GetConVarInt(Cvar_Bleeding)) && (health[client] >= 3))
			{
				health[client] = health[client] - 2;
				SetEntityHealth(client, health[client]);
			}
			else
			{
				KillBleedTimer(client);
				return Plugin_Stop;
			}
			
			if (health[client] <= 2)
			{
				ForcePlayerSuicide(client);
				bleeding[client] = 0;
				KillBleedTimer(client);
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


public Action:Injure(client, attacker, damage)
{
	new Float:vel[3]
	
	if ((client > 0) && (attacker > 0))
	{
		vel = CreateVelocityVector(client, attacker, damage);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	}
	return Plugin_Continue;
} 

KillBleedTimer(client)
{
	if (g_BleedTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_BleedTimers[client]);
		g_BleedTimers[client] = INVALID_HANDLE;
	}
}

//Fade the screen
public ScreenFade(client, red, green, blue, alpha, duration, type)
{
	new Handle:msg;
	
	msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 1500);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public ShowHurt(client)
{
	ClientCommand(client, "r_screenoverlay effects/hurt_red.vmt");
	CreateTimer(2.0, HurtOff, client);
}

public Action:HurtOff(Handle:timer, any:client) 
{
	ClientCommand(client, "r_screenoverlay 0");
	return Plugin_Handled;
}

// Used Fredd's KnockBack stock which is excellent.  Thanks Fredd.
// Modified to work as a DODS stock with a return

stock Float:CreateVelocityVector(client, attacker, damage)
{

	new Float:Velocity[3];
	new Float:VicOrigin[3];
	new Float:AttOrigin[3];

	new Origin;

	Origin = FindSendPropOffs("CDODPlayer", "m_vecOrigin");
	GetEntDataVector(client, Origin, VicOrigin);
	GetEntDataVector(attacker, Origin, AttOrigin);

	new Float:NewOrigin[3];
	NewOrigin[0] = VicOrigin[0] - AttOrigin[0];
	NewOrigin[1] = VicOrigin[1] - AttOrigin[1];

	new Float:LargestNum = 0.0;

	if(FloatAbs(NewOrigin[0])>LargestNum) LargestNum = FloatAbs(NewOrigin[0]);
	if(FloatAbs(NewOrigin[1])>LargestNum) LargestNum = FloatAbs(NewOrigin[1]);

	NewOrigin[0] /= LargestNum;
	NewOrigin[1] /= LargestNum;

	Velocity[0] = ( NewOrigin[0] * (damage * 3000) ) / GetVectorDistance(VicOrigin , AttOrigin);
	Velocity[1] = ( NewOrigin[1] * (damage * 3000) ) / GetVectorDistance(VicOrigin , AttOrigin);
	if(Velocity[0] <= 20.0 || Velocity[1] <= 20.0)
	{
		Velocity[2] = GetRandomFloat(50.0 , 80.0);
	}

	return Velocity;
}


SendPanelToAll(String:name[], String:message[])
{

	decl String:title[100];
	Format(title, 64, "%s", name);
	
	ReplaceString(message, 192, "\\n", "\n");
	
	new Handle:mSayPanel = CreatePanel();
	SetPanelTitle(mSayPanel, title);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
		}
	}

	CloseHandle(mSayPanel);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}
