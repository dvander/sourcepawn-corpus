#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <tf2>
#include <sdktools>
#include <sdkhooks>
#include <attachables>

new Handle:g_hCvarStunDistance;
new Handle:g_hCvarStunTime;

new Handle:g_hStunTimers[MAXPLAYERS];
new bool:g_bIsHorseman[MAXPLAYERS];
new g_iPlayerModel[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "Be the Headless Horseman",
	author = "Afronanny",
	description = "Be the headless horseman!",
	version = PLUGIN_VERSION,
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_horseman_version", PLUGIN_VERSION, "\"Be the Horseman\" version", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_horseman", Cmd_Hatman, ADMFLAG_SLAY);
	RegConsoleCmd("sm_boo", Cmd_Boo);
	
	g_hCvarStunDistance = CreateConVar("sm_horseman_stundistance", "500.0", "Distance to stun enemies", FCVAR_SPONLY);
	g_hCvarStunTime = CreateConVar("sm_horseman_stuntime", "3.0", "Time to keep enemies scared", FCVAR_SPONLY);
}

public OnMapStart()
{
	PrecacheModel("models/bots/headless_hatman.mdl");
}

public Action:Cmd_Boo(client, args)
{
	if (!g_bIsHorseman[client])
	{
		ReplyToCommand(client, "You are not a horseman");
		return Plugin_Continue;
	}
	
	TriggerTimer(g_hStunTimers[client]);
	return Plugin_Handled;
}

public Action:Cmd_Hatman(client, args)
{
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		return Plugin_Handled;
	}


	if (g_bIsHorseman[target])
	{
		ReplyToCommand(client, "That person is already a horsemann!");
	}
	
	g_bIsHorseman[target] = true;
	
	SetEntityRenderMode(target, RENDER_TRANSALPHA);
	SetEntityRenderColor(target, 255, 255, 255, 0);
	
	new playermodel = Attachable_CreateAttachable(target);
	SetEntityModel(playermodel, "models/bots/headless_hatman.mdl");
	
	g_iPlayerModel[target] = playermodel;
	SDKHook(playermodel, SDKHook_SetTransmit, ShouldTransmit);
	
	
	new userid = GetClientUserId(target);
	g_hStunTimers[target] = CreateTimer(60.0, Timer_Terrify, userid, TIMER_REPEAT);
	
	//SUPER FAST :D
	SetEntPropFloat(target, Prop_Send, "m_flMaxspeed", 400.0);
	
	return Plugin_Handled;
}


public Action:Timer_Terrify(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	new Float:HorsemanPosition[3];
	new HorsemanTeam;
	
	GetClientAbsOrigin(client, HorsemanPosition);
	HorsemanTeam = GetClientTeam(client);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || HorsemanTeam == GetClientTeam(i))
			continue;
		
		new Float:pos[3];
		GetClientAbsOrigin(i, pos);
		if (GetVectorDistance(HorsemanPosition, pos) <= GetConVarFloat(g_hCvarStunDistance))
		{
			TF2_StunPlayer(i, GetConVarFloat(g_hCvarStunTime), 0.0, TF_STUNFLAGS_GHOSTSCARE);
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (g_iPlayerModel[client] != 0)
	{
		AcceptEntityInput(g_iPlayerModel[client], "Kill");
		g_iPlayerModel[client] = 0;
	}
	g_bIsHorseman[client] = false;
}

public Action:ShouldTransmit(entity, client)
{
	if (GetEntPropEnt(entity, Prop_Send, "moveparent") == client)
		return Plugin_Handled;
	return Plugin_Continue;
}