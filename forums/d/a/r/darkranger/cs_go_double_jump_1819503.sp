// Original Script from Peagus
// http://forums.alliedmods.net/showthread.php?p=895212

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.3OPRC"

new	g_iJumps[MAXPLAYERS+1]
new	g_iJumpMax
new	g_fLastButtons[MAXPLAYERS+1]
new	g_fLastFlags[MAXPLAYERS+1]
new clientlevel[MAXPLAYERS+1]
new	Handle:g_cvJumpBoost = INVALID_HANDLE
new	Handle:g_cvJumpEnable = INVALID_HANDLE
new	Handle:g_cvJumpMax = INVALID_HANDLE
new Handle:g_cvJumpKnife = INVALID_HANDLE
new	bool:g_bDoubleJump = true
new	Float:g_flBoost	= 250.0

public Plugin:myinfo = 
{
	name = "CS:GO Double Jump",
	author = "Darkranger,(original Script from Peagus)",
	description = "Double Jump for all Players!",
	version = PLUGIN_VERSION,
	url = "http://dark.asmodis.at"
}

public OnPluginStart()
{
	CreateConVar("csgo_doublejump_version", PLUGIN_VERSION, "CS:GO Double Jump Version", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)
	g_cvJumpKnife = CreateConVar("csgo_doublejump_knife", "1",	"disable(0) / enable(1) double-jumping only on Knife Level for AR (GunGame)",FCVAR_PLUGIN, true, 0.0, true, 1.0)
	g_cvJumpEnable = CreateConVar("csgo_doublejump_enabled", "1",	"disable(0) / enable(1) double-jumping",FCVAR_PLUGIN)
	g_cvJumpBoost = CreateConVar("csgo_doublejump_boost", "300.0", "The amount of vertical boost to apply to double jumps",FCVAR_PLUGIN, true, 260.0, true, 500.0)
	g_cvJumpMax = CreateConVar("csgo_doublejump_max", "1", "The maximum number of re-jumps allowed while already jumping",FCVAR_PLUGIN, true, 1.0, true, 5.0)
	AutoExecConfig(true, "csgo_doublejump", "csgo_doublejump")
	
	HookConVarChange(g_cvJumpBoost,		convar_ChangeBoost)
	HookConVarChange(g_cvJumpEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJumpMax,		convar_ChangeMax)
	g_bDoubleJump	= GetConVarBool(g_cvJumpEnable)
	g_flBoost		= GetConVarFloat(g_cvJumpBoost)
	g_iJumpMax		= GetConVarInt(g_cvJumpMax)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost)
	CreateTimer(20.0, Announce, client, TIMER_FLAG_NO_MAPCHANGE)
	CreateTimer(35.0, Announce, client, TIMER_FLAG_NO_MAPCHANGE)
}

public OnWeaponEquipPost(client, weapon)
{
	clientlevel[client] = 0
	if (g_cvJumpKnife) 
	{
		if(LastLevel(client) == true)
		{
			clientlevel[client] = 1
		}
	}	
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	clientlevel[client] = 0
	if (GetConVarInt(g_cvJumpKnife) == 1)
	{
		if(LastLevel(client) == true)
		{
			clientlevel[client] = 1
		}
	}	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_bDoubleJump)
	//if ((g_bDoubleJump) && (buttons & IN_FORWARD))
	{
		if ((g_cvJumpKnife) && ((clientlevel[client]) == 1)) 
		{
			DoubleJump(client)
		}
		if (GetConVarInt(g_cvJumpKnife) == 0)
		{
			DoubleJump(client)
		}
	}
}


stock DoubleJump(const any:client)
{
	new fCurFlags = GetEntityFlags(client), fCurButtons = GetClientButtons(client)
	if (g_fLastFlags[client] & FL_ONGROUND)
	{
		if (!(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
		{
			OriginalJump(client)
		}
	}
	else if (fCurFlags & FL_ONGROUND)
	{
		Landed(client)
	}
	else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
	{
		ReJump(client)
	}
	g_fLastFlags[client]	= fCurFlags
	g_fLastButtons[client]	= fCurButtons
}

stock OriginalJump(const any:client)
{
	g_iJumps[client]++
}

stock Landed(const any:client)
{
	g_iJumps[client] = 0
}

stock ReJump(const any:client)
{
	if ( 1 <= g_iJumps[client] <= g_iJumpMax)
	{
		g_iJumps[client]++
		decl Float:vVel[3]
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel)
		vVel[2] = g_flBoost
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel)
	}
}

public convar_ChangeBoost(Handle:convar, const String:oldVal[], const String:newVal[])
{
	g_flBoost = StringToFloat(newVal)
}

public convar_ChangeEnable(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) >= 1)
	{
		g_bDoubleJump = true
	}
	else
	{
		g_bDoubleJump = false
	}
}

public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[])
{
	g_iJumpMax = StringToInt(newVal)
}

public bool:LastLevel(client)
{
        if(IsValidClient(client) && IsPlayerAlive(client))
        {
                new weapon_count = 0
                for(new i = 0; i <= 4; i++)
                {
                        new wpn = GetPlayerWeaponSlot(client, i)
                        if(wpn != -1)
                        {
                                weapon_count++
                        }
                }
                if(weapon_count == 1)
                {
                        // hat nur das Messer!
						return true
                }
                else
                {
                        // noch weitere Waffen!
                        return false
                }
        }
        return false
}
 
public bool:IsValidClient(client)
{
        if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        {
                return false
        }
        return true
}

public Action:Announce(Handle:timer, any:client)
{
	if (GetConVarInt(g_cvJumpKnife) == 1)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "Double Jump on Knife Level is Enabled!")
	}
	if (GetConVarInt(g_cvJumpKnife) == 0)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "Double Jump is Enabled!")
	}
	return Plugin_Handled
}
