/*
* [TF2] Horseless Headless Horsemann
* Author(s): Geit (edited by: retsam)
* File: horsemann.sp
* Description: Allows admins to spawn Horseless Headless Horsemann where youre looking and also allows public voting.
*
* 
* 1.1r - Added public voting and cvars to the plugin. Fixed precache crashing issues.
* 1.0	- Initial release. 
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1r"

new Handle:Cvar_Horseman_AllowPublic = INVALID_HANDLE;
new Handle:Cvar_Horseman_Votesneeded = INVALID_HANDLE;
new Handle:Cvar_Horseman_VoteDelay = INVALID_HANDLE;

new Float:g_pos[3];
new Float:g_fVotesNeeded;

new g_iVotes = 0;
new g_Voters = 0;
new g_VotesNeeded = 0;
new g_voteDelayTime;

new bool:g_bIsEnabled = true;
new bool:g_bVotesStarted = false;
new bool:g_bHasVoted[MAXPLAYERS + 1] = { false, ... };

public Plugin:myinfo = 
{
	name = "[TF2] Horseless Headless Horsemann",
	author = "Geit (edited by: retsam)",
	description = "Allows admins to spawn Horseless Headless Horsemann where youre looking and also allows public voting.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_horsemann_version", PL_VERSION, "Horsemann Spaner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Horseman_AllowPublic = CreateConVar("sm_horsemann_allowvoting", "1", "Allow public horsemann voting?(1/0 = yes/no)");
	Cvar_Horseman_Votesneeded = CreateConVar("sm_horsemann_votesneeded", "0.50", "Percent of votes required for successful horseman vote. (0.50 = 50%)", _, true, 0.10, true, 1.0);
	Cvar_Horseman_VoteDelay = CreateConVar("sm_horsemann_votedelay", "120.0", "Delay time in seconds between calling votes.");

	RegAdminCmd("sm_horsemann", Command_Spawn, ADMFLAG_BAN);
	RegConsoleCmd("votehorsemann", Command_VoteSpawnHorseman, "Trigger to vote to spawn headless horsemann.");
	RegConsoleCmd("votehhh", Command_VoteSpawnHorseman, "Trigger to vote to spawn headless horsemann.");

	HookConVarChange(Cvar_Horseman_AllowPublic, Cvars_Changed);
	HookConVarChange(Cvar_Horseman_Votesneeded, Cvars_Changed);

	AutoExecConfig(true, "plugin.votehorsemann");
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
	return;
  
  g_bHasVoted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
	return;
  
  if(g_bHasVoted[client])
	{
    g_iVotes--;
    g_bHasVoted[client] = false;
  }

	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Horseman_AllowPublic);
	g_fVotesNeeded = GetConVarFloat(Cvar_Horseman_Votesneeded);
}

public OnMapStart()
{
	g_bVotesStarted = false;
	g_iVotes = 0;
	g_Voters = 0;
	g_VotesNeeded = 0;
	
	PrecacheModel("models/bots/headless_hatman.mdl"); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("vo/halloween_boss/knight_alert.wav");
	PrecacheSound("vo/halloween_boss/knight_alert01.wav");
	PrecacheSound("vo/halloween_boss/knight_alert02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack01.wav");
	PrecacheSound("vo/halloween_boss/knight_attack02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack03.wav");
	PrecacheSound("vo/halloween_boss/knight_attack04.wav");
	PrecacheSound("vo/halloween_boss/knight_death01.wav");
	PrecacheSound("vo/halloween_boss/knight_death02.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
	PrecacheSound("vo/halloween_boss/knight_pain01.wav");
	PrecacheSound("vo/halloween_boss/knight_pain02.wav");
	PrecacheSound("vo/halloween_boss/knight_pain03.wav");
	PrecacheSound("vo/halloween_boss/knight_spawn.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
}

public Action:Command_VoteSpawnHorseman(client, args)
{
	if(client < 1 || !IsClientInGame(client))
	return Plugin_Handled;

	if(!g_bIsEnabled)
	{
		PrintToChat(client, "\x01[SM] This vote trigger has been disabled by the server.");
		return Plugin_Handled;
	}
	
	if(g_voteDelayTime > GetTime())
	{
		new timeleft = g_voteDelayTime - GetTime();
		
		PrintToChat(client, "\x01[SM] There are %d seconds remaining before another horsemann vote is allowed.", timeleft);
		return Plugin_Handled;
	}
	
	if(g_bHasVoted[client])
	{
		PrintToChat(client, "\x01[SM] You have already voted, you FOOL!");
		return Plugin_Handled;
	}
	
	if(!g_bVotesStarted)
	{
		g_bVotesStarted = true;
		CreateTimer(90.0, Timer_ResetVotes, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
  g_iVotes++;
  g_bHasVoted[client] = true;
  
  if(g_iVotes >= g_VotesNeeded)
	{
		PrintToChatAll("[SM] Vote to spawn Horsemann was successful! [%d/%d]", g_iVotes, g_VotesNeeded);
		AttemptSpawnHorsemann(client);
	}
	else
	{
		PrintToChatAll("\x01[SM] \x03%N \x01has voted to spawn Headless Horsemann: Type \x04!votehhh \x01/ \x04!votehorsemann \x01to vote YES. [%d/%d]", client, g_iVotes, g_VotesNeeded);
	}
	
	return Plugin_Handled;
}

public AttemptSpawnHorsemann(client)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Horsemann could not be spawned. Could not find spawn point.");
		ResetAllVotes();
		return;
	}

	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChatAll("[SM] Horsemann could not be spawned due to entity limit reached. Change maps!");
		ResetAllVotes();
		return;
	}
	
	new entity = CreateEntityByName("headless_hatman");
	
	if(IsValidEntity(entity))
	{		
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		g_voteDelayTime = GetTime() + GetConVarInt(Cvar_Horseman_VoteDelay);
		ResetAllVotes();
	}
}

public Action:Command_Spawn(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore entities. Change maps.");
		return Plugin_Handled;
	}
	
	new entity = CreateEntityByName("headless_hatman");
	
	if(IsValidEntity(entity))
	{		
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public Action:Timer_ResetVotes(Handle:timer)
{
	if(g_bVotesStarted)
	{
		PrintToChatAll("[SM] Vote to spawn Horsemann FAILED! [%d/%d]", g_iVotes, g_VotesNeeded);
    g_bVotesStarted = false;
		ResetAllVotes();
	}
}

ResetAllVotes()
{
	g_bVotesStarted = false;
	g_iVotes = 0;
	
	for(new x = 1; x <= MaxClients; x++) 
	{
		if(!IsClientInGame(x))
		{
			continue;
		}
		
		if(g_bHasVoted[x])
		{
			g_bHasVoted[x] = false;
		}
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Horseman_AllowPublic)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_Horseman_Votesneeded)
	{
		g_fVotesNeeded = StringToFloat(newValue);
	}
}