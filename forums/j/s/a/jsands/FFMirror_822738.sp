#include <sourcemod>
#include <sdktools>

new bool:g_ffSpamDelay = false;

new Handle:g_mirrorNotify = INVALID_HANDLE;
new Handle:g_mirrorFFEnabled = INVALID_HANDLE;
new Handle:g_mirrorDamageCap = INVALID_HANDLE;
new Handle:g_mirrorPluginEnabled = INVALID_HANDLE;
 
public Plugin:myinfo =
{
	name = "Left 4 Dead FF Punisher",
	author = "Joshua Coffey",
	description = "Mirrors FF Damage",
	version = "2.0.0.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_mirrorFFEnabled 		= 	CreateConVar("sm_mirror_ff_enabled", 	"1", 	"Sets whether FF is enabled.", 											FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_mirrorPluginEnabled 	= 	CreateConVar("sm_mirror_enabled", 		"1", 	"Sets whether the plugin is enabled.", 									FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_mirrorDamageCap 		= 	CreateConVar("sm_mirror_damage_cap",	"2", 	"Lowest value to set attacker health to after mirroring FF damage.", 	FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_mirrorNotify 			= 	CreateConVar("sm_mirror_notify", 		"1", 	"Sets whether a warning is displayed when mirrored damage is taken.", 	FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);	
	AutoExecConfig(true, "ff_mirror");												//Execute CFG file: ff_mirror.cfg
}

public OnMapStart()
{
	g_ffSpamDelay = false;															//Reset the spam protection on Map Start.
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new postHealth = GetEventInt(event, "health");									//Amount of health victim has left after FF  damage.
	new damageDone = GetEventInt(event, "dmg_health");								//Amount of FF damage.
	new mirrorDamageCap = GetConVarInt(g_mirrorDamageCap);							//Lowest amount of health the attacker will be dropped to.
	new originalHealthVictim = (postHealth + damageDone);							//Determines and stores the orignal health of the victim.
	
	new victimID = GetClientOfUserId(GetEventInt(event, "userid"));					//User ID: Victim
	new attackerID = GetClientOfUserId(GetEventInt(event, "attacker"));				//User ID: Attacker
	
	if (attackerID != 0)															//Is the attacker not "World"?
	{
		if (GetConVarInt(g_mirrorPluginEnabled) == 1)								//Is mirrored FF damage enabled?
		{
			new currentHealthAttacker = GetClientHealth(attackerID);				//Finds the current health of the attacker.
			new healthFinal = (currentHealthAttacker - damageDone);					//Sets the amount of health the attacker will be left with.
		
			if (GetClientTeam(attackerID) == 2 && GetClientTeam(victimID) == 2)		//Are both the attacker and the victim SURVIVORS?
			{
				if (currentHealthAttacker > mirrorDamageCap)						//Is the attacker's health above the damage cap?
				{																	
					if (damageDone < currentHealthAttacker) 						//If mirrored FF damage will not incap or kill the attacker,
					{																//
						SetEntityHealth(attackerID, healthFinal);					//Mirror the FF damage towards the attacker.
						
						if ((GetConVarInt(g_mirrorNotify) == 1)	&& (!g_ffSpamDelay))//If Notify is active and the spam protection is not active,
						{															//
							g_ffSpamDelay = true;									//Send a message to the attacker, and set a timer so that this message is not spammed.
							PrintToChat(attackerID, "\x04[WARNING] \x01Friendly Fire Is Mirrored On This Server. Use Caution.");
							CreateTimer(5.0, TimerDelay);
						}
					}
				}
			}
		}
		
		if (GetConVarInt(g_mirrorFFEnabled) != 1)									//If FF is disabled,
		{																			//
			SetEntityHealth(victimID, originalHealthVictim);						//Reset the victim's health to its original value to prevent FF damage.
			return Plugin_Handled
		}
	}
	return Plugin_Continue;
}

public Action:TimerDelay(Handle:timer)
{
	g_ffSpamDelay = false;															//Reset the spam protection.
}