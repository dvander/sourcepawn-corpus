#pragma semicolon 1

/*
 *	HP Regeneration
 *	by MaTTe (mateo10)
 */

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "HP Regeneration",
	author = "MaTTe",
	description = "As the title says, this plugin regenerates your hp to maximum",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_hRegenTimer[MAXPLAYERS + 1];

new Handle:g_Interval;
new Handle:g_MaxHP;
new Handle:g_Inc;

public OnPluginStart()
{
	CreateConVar("hpregeneration_version", VERSION, "HP Regeneration Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Interval = CreateConVar("hpregen_interval", "1.0");
	g_MaxHP = CreateConVar("hpregen_maxhp", "100");
	g_Inc = CreateConVar("hpregen_inc", "10");

	HookEvent("player_hurt", HookPlayerHurt);
}

public HookPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);

	if(g_hRegenTimer[client] == INVALID_HANDLE)
	{
		g_hRegenTimer[client] = CreateTimer(GetConVarFloat(g_Interval), Regenerate, client, TIMER_REPEAT);
	}
}

public Action:Regenerate(Handle:timer, any:client)
{
	new ClientHealth = GetClientHealth(client);

	if(ClientHealth < GetConVarInt(g_MaxHP))
	{
		SetClientHealth(client, ClientHealth + GetConVarInt(g_Inc));
	}
	else
	{
		SetClientHealth(client, GetConVarInt(g_MaxHP));
		g_hRegenTimer[client] = INVALID_HANDLE;
		KillTimer(timer);
	}
}

SetClientHealth(client, amount)
{
	new HealthOffs = FindDataMapOffs(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}