#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <smac>

/* Plugin Info */
public Plugin:myinfo =
{
	name = "SMAC AutoTrigger Detector",
	author = "GoD-Tony",
	description = "Detects cheats that automatically press buttons for players",
	version = SMAC_VERSION,
	url = SMAC_URL
};

/* Globals */
#define UPDATE_URL	"http://godtony.mooo.com/smac/smac_autotrigger.txt"

#define TRIGGER_DETECTIONS	12 // Amount of detections needed to perform action.

// Detection methods.
#define METHOD_BUNNYHOP		0
#define METHOD_AUTOFIRE1	1
#define METHOD_AUTOFIRE2	2
#define METHOD_MAX			3

new Handle:g_hCvarBan = INVALID_HANDLE;
new g_iDetections[METHOD_MAX][MAXPLAYERS+1];
new g_iPrevButtons[MAXPLAYERS+1];
new bool:g_bCheckNextJump[MAXPLAYERS+1];
new bool:g_bCheckNextShot[MAXPLAYERS+1];

new g_iAttackAmt[MAXPLAYERS+1];
new g_iAttackMax = 66;

/* Plugin Functions */
public OnPluginStart()
{
	LoadTranslations("smac.phrases");
	
	// Convars.
	g_hCvarBan = SMAC_CreateConVar("smac_autotrigger_ban", "0", "Automatically ban players on auto-trigger detections.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_iAttackMax = RoundToNearest(1.0 / GetTickInterval() / 1.75);
	CreateTimer(4.0, Timer_DecreaseCount, _, TIMER_REPEAT);
}

public OnClientDisconnect_Post(client)
{
	for (new i = 0; i < METHOD_MAX; i++)
	{
		g_iDetections[i][client] = 0;
	}
		
	g_iAttackAmt[client] = 0;
	g_iPrevButtons[client] = 0;
	g_bCheckNextJump[client] = false;
	g_bCheckNextShot[client] = false;
}

public Action:Timer_DecreaseCount(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new j = 0; j < METHOD_MAX; j++)
		{
			if (g_iDetections[j][i])
			{
				g_iDetections[j][i]--;
			}
		}
		
		g_iAttackAmt[i] = 0;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Player didn't jump immediately after the last jump.
	if (g_bCheckNextJump[client] && !(buttons & IN_JUMP) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		g_bCheckNextJump[client] = false;
	}
	
	if ((buttons & IN_JUMP) && !(g_iPrevButtons[client] & IN_JUMP))
	{
		// Player is on the ground and about to trigger a jump.
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			// Player jumped on the exact frame that allowed it.
			if (g_bCheckNextJump[client])
			{
				AutoTrigger_Detected(client, METHOD_BUNNYHOP);
				g_bCheckNextJump[client] = false;
			}
			else
			{
				g_bCheckNextJump[client] = true;
			}
		}
		else
		{
			g_bCheckNextJump[client] = false;
		}
	}
	
	// Player didn't shoot immediately after the last shot.
	if (g_bCheckNextShot[client] && !(buttons & IN_ATTACK) && CanShootWeapon(client))
	{
		g_bCheckNextShot[client] = false;
	}
	
	if ((buttons & IN_ATTACK) && !(g_iPrevButtons[client] & IN_ATTACK))
	{
		// Player is about to shoot.
		if (CanShootWeapon(client))
		{
			// Player shot on the exact frame that allowed it.
			if (g_bCheckNextShot[client])
			{
				AutoTrigger_Detected(client, METHOD_AUTOFIRE1);
				g_bCheckNextShot[client] = false;
			}
			else
			{
				g_bCheckNextShot[client] = true;
			}
		}
		else
		{
			g_bCheckNextShot[client] = false;
		}
	}
	
	// Some hacks will alternate IN_ATTACK between frames.
	if (((buttons & IN_ATTACK) && !(g_iPrevButtons[client] & IN_ATTACK)) || 
		(!(buttons & IN_ATTACK) && (g_iPrevButtons[client] & IN_ATTACK)))
	{
		if (++g_iAttackAmt[client] >= g_iAttackMax)
		{
			AutoTrigger_Detected(client, METHOD_AUTOFIRE2);
			g_iAttackAmt[client] = 0;
		}
	}

	g_iPrevButtons[client] = buttons;

	return Plugin_Continue;
}

bool:CanShootWeapon(client)
{
	/* Check if this client's weapon can be fired. */
	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (weapon != -1 && IsValidEntity(weapon))
	{
		decl String:sNetClass[64];
		
		if (GetEntityNetClass(weapon, sNetClass, sizeof(sNetClass)))
		{
			new offset = FindSendPropOffs(sNetClass, "m_flNextPrimaryAttack");
			
			if (offset != -1 && GetGameTime() >= GetEntDataFloat(weapon, offset))
			{
				return true;
			}
		}
	}
	
	return false;
}

AutoTrigger_Detected(client, method)
{
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	SMAC_LogAction(client, "DEBUG - Detection #%i - Method %i - Weapon: %s", g_iDetections[method][client], method, sWeapon);
	
	if (!IsFakeClient(client) && IsPlayerAlive(client) && ++g_iDetections[method][client] >= TRIGGER_DETECTIONS)
	{
		if (SMAC_CheatDetected(client) == Plugin_Continue)
		{
			decl String:sMethod[32], String:sName[MAX_NAME_LENGTH];

			switch (method)
			{
				case METHOD_BUNNYHOP:
				{
					strcopy(sMethod, sizeof(sMethod), "BunnyHop");
				}
				case METHOD_AUTOFIRE1:
				{
					strcopy(sMethod, sizeof(sMethod), "Auto-Fire (1)");
				}
				case METHOD_AUTOFIRE2:
				{
					strcopy(sMethod, sizeof(sMethod), "Auto-Fire (2)");
				}
			}
			
			GetClientName(client, sName, sizeof(sName));
			SMAC_PrintAdminNotice("%t", "SMAC_AutoTriggerDetected", sName, sMethod);
			
			if (GetConVarBool(g_hCvarBan))
			{
				SMAC_LogAction(client, "was banned for using auto-trigger cheat: %s", sMethod);
				SMAC_Ban(client, "AutoTrigger Detection: %s", sMethod);
			}
			else
			{
				SMAC_LogAction(client, "is suspected of using auto-trigger cheat: %s", sMethod);
			}
		}
		
		g_iDetections[method][client] = 0;
	}
}
