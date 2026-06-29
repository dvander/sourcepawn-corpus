#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.4.0.0"

new Handle:BeltsTimer[MAXPLAYERS+1] = { INVALID_HANDLE , ... };
new Handle:Cvar_Magniture = INVALID_HANDLE;
new Handle:Cvar_Radius = INVALID_HANDLE;
new Handle:Cvar_Timer = INVALID_HANDLE;
new bool:RoundEnds = false;

public Plugin:myinfo = {
	name 		= "Terrorist's Belt",
	author 		= "Leonardo",
	description = "Terrorist can detonate his the 'Belt'",
	version 	= VERSION,
	url 		= "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_terbelt", VERSION, "[TerBelt] Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Cvar_Magniture = CreateConVar("sm_terbelt_magniture", "1000", "[TerBelt] Magniture of explosion", FCVAR_PLUGIN, true, 15.0, true, 10000.0);
	Cvar_Radius = CreateConVar("sm_terbelt_radius", "500", "[TerBelt] Radius of explosion", FCVAR_PLUGIN, true, 15.0, true, 1000.0);
	Cvar_Timer = CreateConVar("sm_terbelt_time", "1.0", "[TerBelt] Time after a belt will detonate", FCVAR_PLUGIN, true, 0.5, true, 1.5);
	
	RegConsoleCmd("detonate", Cmd_detonate, "Detonate yourself (if you're terrosist, sure)");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public OnEventShutdown()
{
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("round_start", OnRoundStart);
	UnhookEvent("round_end", OnRoundEnd);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	Abort_detonation(client);
}

public OnClientDisconnect(client)
	Abort_detonation(client);

public OnMapStart()
{
	AddFileToDownloadsTable("sound/player/alalala.wav");
	PrecacheSound("player/alalala.wav", true);
}

public OnMapEnd()
	Abort_detonations();

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	Abort_detonations();
	RoundEnds = true;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	RoundEnds = false;

public Action:Cmd_detonate(client, args)
{
	if (client)	{
		if (IsClientConnected(client) && IsClientInGame(client))
			if (IsPlayerAlive(client) && GetClientTeam(client)==2)
				if (BeltsTimer[client]==INVALID_HANDLE && !RoundEnds)
				{
					EmitSoundToAll("player/alalala.wav", client, _, _, _, 1.0);
					CreateTimer(1.0, Stop_sound, client);
					BeltsTimer[client] = CreateTimer(GetConVarFloat(Cvar_Timer), Belt_detonate, client);
				}
	}
	
	return Plugin_Handled;
}

public Action:Stop_sound(Handle:timer, any:client)
	StopSound(client, SNDCHAN_AUTO, "player/alalala.wav"); 

public Action:Belt_detonate(Handle:timer, any:client)
{
	new String:clientname[64];
	GetClientName(client,clientname,sizeof(clientname));
	
	new Float:location[3];
	GetClientAbsOrigin(client, location);
	
	new g_ent = CreateEntityByName("env_explosion");
	SetEntPropEnt(g_ent, Prop_Send, "m_hOwnerEntity", client);
	
	new String:textstring[8];
	IntToString(GetConVarInt(Cvar_Radius), textstring, sizeof(textstring));
	DispatchKeyValue(g_ent, "iMagnitude", textstring);
	IntToString(GetConVarInt(Cvar_Magniture), textstring, sizeof(textstring));
	DispatchKeyValue(g_ent, "iRadiusOverride", textstring);
	DispatchSpawn(g_ent);
	
	TeleportEntity(g_ent, location, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(g_ent, "Explode");
	RemoveEdict(g_ent);
	
	for(new xclient=1; xclient <= MaxClients; xclient++)
		if(IsClientConnected(xclient) && IsClientInGame(xclient))
			PrintToConsole(xclient, "%s detonated yourself!", clientname);
	
	KillTimer(timer);
	BeltsTimer[client] = INVALID_HANDLE;
}

public Abort_detonations()
	for(new client=1; client <= MAXPLAYERS; client++)
		if(BeltsTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(BeltsTimer[client]);
			BeltsTimer[client] = INVALID_HANDLE;
		}

public Abort_detonation(client)
	if(BeltsTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(BeltsTimer[client]);
		BeltsTimer[client] = INVALID_HANDLE;
	}