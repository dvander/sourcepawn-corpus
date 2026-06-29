#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_PLUGIN
#define VERSION_ "1.0"

new bool:g_bIsTankInPlay = false;
new bool:CheckJump = false;
new bool:Eligible[MAXPLAYERS+1];
new bool:elig;

new Handle:Jump_Throw;

//new g_iTankClient = 0;
new PropVelocity;

static  const ZOMBIECLASS_TANK  = 5;

public Plugin:myinfo =
{
	name = "[L4D] Tank Jump Rock",
	author = "GozarD (GZD)",
	description = "This plugin makes the tank have to ability to throw rocks and jump at the same time like L4D2.",
	version = VERSION_,
	url = ""
};

public OnPluginStart()
{
	g_bIsTankInPlay = false;
	//g_iTankClient = 0;
	PropVelocity    = FindSendPropOffs("CBasePlayer",   "m_vecVelocity[0]");
	Jump_Throw = CreateConVar("l4d_jump_rock", "1", "Turn on/off the ability.",CVAR_FLAGS,true,0.0,true,1.0);
	
	CreateConVar("tankjumprock_version", VERSION_, "[L4D] Tank Jump Rock Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("ability_use", Event_Ability);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarBool(Jump_Throw))
	{
	
		elig = isEligible(client);
	
		Eligible[client] = elig;

		if (elig)
		{
			if(buttons & IN_RELOAD)
			{		
				CheckJump = true;
			}
			else
			{
				CheckJump = false;
			}	
		}
		else
		{
			CheckJump = false;
		}
	
	}
}

bool:isEligible(client)
{
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client)!=3) return false;
	//if (GetUserAdmin(client) == INVALID_ADMIN_ID) return false;
	if (!g_bIsTankInPlay) return false;
	
	return true;
}

public Action:Event_Ability(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:velocity[3];
	new TANK_CLIENT = FindTankClient();
	
	if((client==TANK_CLIENT) && (CheckJump==true))
	{
		GetEntDataVector(TANK_CLIENT, PropVelocity, velocity);
		velocity[0] += 0;/* x coord */
		velocity[1] += 0;/* y coord */
		velocity[2] += 350;/* z coord */
		TeleportEntity(TANK_CLIENT, NULL_VECTOR, NULL_VECTOR, velocity);
	}
	return Plugin_Continue;
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//g_iTankClient = client;
	if(g_bIsTankInPlay) return;
	g_bIsTankInPlay = true;
	PrintToChat(client,"Keep pressing Reload Button (R) to throw rocks jumping.");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
        g_bIsTankInPlay = false;
        //g_iTankClient = 0;
}
/*
GetTankClient()
{
		if (!g_bIsTankInPlay) return 0;
		
        new tankclient = g_iTankClient;
		
        if (!IsClientInGame(tankclient))
        {
			tankclient = FindTankClient();
			if (!tankclient) return 0;
				g_iTankClient = tankclient;
        }
		return tankclient;
}
*/
FindTankClient()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) ||
			GetClientTeam(client) != 3 ||
			!IsPlayerAlive(client) ||
			GetEntProp(client, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
			continue;
			
		return client;
	}
	return 0;
}