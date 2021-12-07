#include <sourcemod>
#include <sdktools>
#include emitsoundany.inc

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = 
{
	name = "Kill streak csgo overlays - edit (nosound) ",
	author = "fs_wTong,TonyBaretta,shanapu",
	description = "Overlays kills",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

enum {
	kill_1,
	kill_2,
	kill_3,
	kill_4,
	kill_5,
	kill_hs,
	kill_knife,
	kill_hegrenade,
	kill_fire,
	kill_taser
};


new String:NAME_OVERLAYS[][] = {"event_overlay/kill_1","event_overlay/kill_2",
"event_overlay/kill_3","event_overlay/kill_4","event_overlay/kill_5","event_overlay/kill_hs",
"event_overlay/kill_knife","event_overlay/kill_hegrenade","event_overlay/kill_fire","event_overlay/kill_taser"};

new Handle:g_taskCountdown[33] = INVALID_HANDLE,Handle:g_taskClean[33] = INVALID_HANDLE;
new g_killCount[33] = 0,g_iMaxClients = 0;


public OnPluginStart()
{
	// Add your own code here...
	CreateConVar("KillStreak_version", PLUGIN_VERSION, "Current Kill Streak version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_round_end,EventHookMode_Post);
}

public OnMapStart()
{
		
	AddFolderToDownloadsTable("materials/event_overlay");
	
	g_iMaxClients = GetMaxClients();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	new String:weapon[32];
	GetEventString(event, "weapon",weapon, sizeof(weapon));
	
	g_killCount[victim] = 0;
	if(g_taskCountdown[victim] !=INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[victim]);
		g_taskCountdown[victim] =INVALID_HANDLE;
	}
	if(attacker <1 || attacker == victim )
		return;
	
	if(IsFakeClient(attacker) || GetEntityTeam(attacker) == GetEntityTeam(victim))
		return;
	
	if(g_killCount[attacker] <5) 
		g_killCount[attacker]++;
	
	g_taskCountdown[attacker] = CreateTimer(3.0,task_Countdown,attacker,1);
	
	if(g_killCount[attacker] == 1)
	{
		if(StrEqual(weapon,"hegrenade"))
			ShowKillMessage(attacker,kill_hegrenade);
		else if(StrEqual(weapon,"knife"))
			ShowKillMessage(attacker,kill_knife);
		else if(StrEqual(weapon,"inferno"))
			ShowKillMessage(attacker,kill_fire);
		else if(StrEqual(weapon,"taser"))
			ShowKillMessage(attacker,kill_taser);
		else if(headshot)
			ShowKillMessage(attacker,kill_hs);
		else
			ShowKillMessage(attacker,kill_1);
	}
	else 
		ShowKillMessage(attacker,g_killCount[attacker]-1);
	if(g_taskClean[attacker] !=INVALID_HANDLE)
	{
		KillTimer(g_taskClean[attacker]);
		g_taskClean[attacker] =INVALID_HANDLE;
	}
	g_taskClean[attacker] = CreateTimer(3.0,task_Clean,attacker);
}

public Event_round_end(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new client=1;client <= g_iMaxClients;client++)
	{
		g_killCount[client] = 0;
		if(g_taskCountdown[client] !=INVALID_HANDLE)
		{
			KillTimer(g_taskCountdown[client]);
			g_taskCountdown[client] =INVALID_HANDLE;
		}
	}
}

public Action:task_Countdown(Handle:Timer, any:client)
{
	if(g_killCount[client]!=0){
		g_killCount[client] --;
	}
	if(!IsPlayerAlive(client) || g_killCount[client]==0)
	{
		KillTimer(Timer);
		g_taskCountdown[client] = INVALID_HANDLE;
	}
}

public Action:task_Clean(Handle:Timer, any:client)
{
	KillTimer(Timer);
	g_taskClean[client] = INVALID_HANDLE;
	//if(!IsPlayerUseZoomWeapon(client)&&IsClientZooming(client))
		//return;
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	ClientCommand(client, "r_screenoverlay \"\"");
}

public ShowKillMessage(client,type)
{
		
		new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	ClientCommand(client, "r_screenoverlay \"%s\"",NAME_OVERLAYS[type]);
}
public OnClientDisconnect_Post(client)
{
	if(g_taskCountdown[client] !=INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[client]);
		g_taskCountdown[client] =INVALID_HANDLE;
	}
	
	if(g_taskClean[client] !=INVALID_HANDLE)
	{
		KillTimer(g_taskClean[client]);
		g_taskClean[client] =INVALID_HANDLE;
	}
}
public ShowKeyHintText(client,String:sMessage[])
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
	if(hBuffer==INVALID_HANDLE)
		return;
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer,sMessage); 
	EndMessage();
}


stock GetEntityTeam(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock AddFolderToDownloadsTable(const String:sDirectory[])
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}