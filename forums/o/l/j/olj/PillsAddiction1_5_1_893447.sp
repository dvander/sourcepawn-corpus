
#define PLUGIN_VERSION "1.5"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
new Handle:g_DrugTimersP[MAXPLAYERS+1];
new Float:g_DrugAnglesP[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
new Handle:h_OverdoseTime;
new Handle:h_PillsThreshold;
new Handle:h_LaughVocalizeMode;
new Handle:h_PillsDeathThreshold;
new Float:OverdoseTime;
new PillsThreshold;
new LaughVocalizeMode;
new PillsDeathThreshold;
new bool:Drugged[MAXPLAYERS+1];
new TotalPillsUsed[MAXPLAYERS+1];
new DeathCounter[MAXPLAYERS+1];
new Handle:LaughTimerHandle[MAXPLAYERS+1];
new UserMsg:g_FadeUserMsgIdP;
public Plugin:myinfo = 
{
	name = "Pills Addiction",
	author = "Olj",
	description = "Survivors will get drugged by pills for some time",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
for (new i = 1; i <=MaxClients; i++)
	{
	TotalPillsUsed[i] = 0;
	}
for (new b = 1; b <=MaxClients; b++)
	{
	Drugged[b] = false;
	}
for (new c = 1; c <=MaxClients; c++)
	{
	DeathCounter[c] = 0;
	}
g_FadeUserMsgIdP = GetUserMessageId("Fade");
RegAdminCmd("sm_killdrugs", KillAllDrugsCallback,ADMFLAG_KICK, "Kills all drugs");
CreateConVar("l4d_pa_version", PLUGIN_VERSION, "Version of Pills addiction plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
HookEvent("pills_used", PillsUsed, EventHookMode_Post);
h_OverdoseTime = CreateConVar("l4d_pillsaddiction_overdose_time", "20.00", "How much time user will be drugged", CVAR_FLAGS);
h_PillsThreshold = CreateConVar("l4d_pillsaddiction_threshold", "1", "How many pills can be used before overdose will take place", CVAR_FLAGS);
h_LaughVocalizeMode = CreateConVar("l4d_pillsaddiction_vocalize_mode", "2", "0 disabled, 1 only one-time laugh on taking pills, 2-laughing untill effects wears off", CVAR_FLAGS, true, 0.00, true, 2.00);
h_PillsDeathThreshold = CreateConVar("l4d_pillsaddiction_death_threshold", "0", "How many pills can be used before user will die from overdose (0 to disable)", CVAR_FLAGS);
OverdoseTime = GetConVarFloat(h_OverdoseTime);
PillsThreshold = GetConVarInt(h_PillsThreshold);
LaughVocalizeMode = GetConVarInt(h_LaughVocalizeMode);
PillsDeathThreshold = GetConVarInt(h_PillsDeathThreshold);
HookConVarChange(h_OverdoseTime, OverdoseTimeChanged);
HookConVarChange(h_PillsThreshold, PillsThresholdChanged);
HookConVarChange(h_LaughVocalizeMode, LaughVocalizeModeChanged);
HookConVarChange(h_PillsDeathThreshold, PillsDeathThresholdChanged);
HookEvent("round_end", Event_RoundEndP, EventHookMode_PostNoCopy);
AutoExecConfig(true, "l4d_pills_addiction");
}

public OverdoseTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		OverdoseTime = GetConVarFloat(h_OverdoseTime);
	}

public PillsThresholdChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		PillsThreshold = GetConVarInt(h_PillsThreshold);
	}
	
public LaughVocalizeModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		LaughVocalizeMode = GetConVarInt(h_LaughVocalizeMode);
	}
	
public PillsDeathThresholdChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		PillsDeathThreshold = GetConVarInt(h_PillsDeathThreshold);
		if (strcmp(oldValue,"0", false)==0) for (new c = 1; c <=MaxClients; c++) { DeathCounter[c] = 0;
		}
	}

public Action:Event_RoundEndP(Handle:event,const String:name[],bool:dontBroadcast)
{
	KillAllDrugsP();
}

public OnMapStart()
{
	PrintToChatAll("Pain Pills running");
}
public OnMapEnd()
{
	KillAllDrugsP();
}

public Action:KillAllDrugsCallback(client, args)
	{
		KillAllDrugsP();
	}

public PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
	{
		new userID = GetEventInt(event,"subject");
		new clientID = GetClientOfUserId(userID);
		new String:CLname[MAX_NAME_LENGTH];
		GetClientName(clientID,CLname,MAX_NAME_LENGTH);
		TotalPillsUsed[clientID] += 1;
		DeathCounter[clientID] += 1;
		//PrintToChatAll("Total Pills Used By ClientID %i: %i",clientID, TotalPillsUsed[clientID]);
		if (PillsDeathThreshold>0)
			{
				if ((IsValidClient(clientID))&&(DeathCounter[clientID]>PillsDeathThreshold))
					{
						if (Drugged[clientID]==true) 
							{
								KillDrugP(clientID);
								Drugged[clientID]=false;
							}
						ClientCommand(clientID, "vocalize PlayerDeath");
						CreateTimer(3.00, OverdoseKill, any:clientID, TIMER_FLAG_NO_MAPCHANGE);
						TotalPillsUsed[clientID] = 0;
						DeathCounter[clientID] = 0;
						return;
					}
			}
		if (TotalPillsUsed[clientID]>PillsThreshold)
			{
				if ((!IsValidClient(clientID))||(GetClientTeam(clientID)!=2)) return;
				if (Drugged[clientID]==true) return;
				CreateDrugP(clientID);
				if (LaughVocalizeMode!=0) ClientCommand(clientID, "vocalize PlayerLaugh");
				CreateTimer(OverdoseTime, toggleDrug, any:clientID, TIMER_FLAG_NO_MAPCHANGE);
				if (LaughVocalizeMode==2) LaughTimerHandle[clientID] = CreateTimer(OverdoseTime/5, LaughTimer, any:clientID, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				Drugged[clientID] = true;
				PrintToChat(clientID, "Careful, you have been overdosed by PILLZ!");
				TotalPillsUsed[clientID] = 0;
			}
	}

public Action:toggleDrug(Handle:timer, any:clientID)
	{
		if (!IsValidClient(clientID)) return;
		new String:CLname[MAX_NAME_LENGTH];
		GetClientName(clientID,CLname,MAX_NAME_LENGTH);
		if (Drugged[clientID]==true)
			{
				KillDrugP(clientID);
				if (GetClientTeam(clientID)==2)
					{
						PrintToChat(clientID, "Overdose effect wore off");
					}
				Drugged[clientID]=false;
			}
	}
	
public Action:LaughTimer(Handle:timer, any:clientID)
	{	
		if ((!IsValidClient(clientID))||(Drugged[clientID]==false)||(LaughVocalizeMode!=2))
			{
				if (LaughTimerHandle[clientID] != INVALID_HANDLE) KillTimer(LaughTimerHandle[clientID]);			
			}
		else ClientCommand(clientID, "vocalize PlayerLaugh");
		return Plugin_Continue;
	}
	
public Action:OverdoseKill(Handle:timer, any:clientID)
	{
		if (IsValidClient(clientID)) ForcePlayerSuicide(clientID);
	}
/* Drug.sp code */


CreateDrugP(client)
{
	g_DrugTimersP[client] = CreateTimer(1.0, Timer_DrugP, client, TIMER_REPEAT);	
}

KillDrugP(client)
{
	KillDrugTimerP(client);
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

KillDrugTimerP(client)
{
	KillTimer(g_DrugTimersP[client]);
	g_DrugTimersP[client] = INVALID_HANDLE;
	Drugged[client]=false;
}

KillAllDrugsP()
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_DrugTimersP[i] != INVALID_HANDLE)
		{
			if(IsClientInGame(i))
			{
				KillDrugP(i);
			}
			else
			{
				KillDrugTimerP(i);
			}
		}
	}
}

public Action:Timer_DrugP(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimerP(client);
		
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		KillDrugP(client);
		
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAnglesP[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	
	EndMessage();	
		
	return Plugin_Handled;
}

public IsValidClient (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	return true;
}