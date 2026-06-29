
#define PLUGIN_VERSION "1.6.9"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#undef REQUIRE_PLUGIN
#include <KrX_surup>
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
new Handle:g_DrugTimersP[MAXPLAYERS+1];
new Float:g_DrugAnglesP[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
new Handle:h_OverdoseTime;
new Handle:h_PillsThreshold;
new Handle:h_LaughVocalizeMode;
new Handle:h_PillsDeathThreshold;
new Handle:h_GivePillsEnabled;
new Handle:h_GivePillsAdminOnly;
new Handle:h_AdrenalineBoostEnabled;
new Handle:h_AdrenalineSpeedFactor;
new Handle:h_GivePillsTimeout;
new Float:GivePillsTimeout;
new Float:Speedfactor;
new bool:AdrenalineEnabled;
new bool:GivePillsEnabled;
new bool:GivePillsAdminOnly;
new Float:OverdoseTime;
new PillsThreshold;
new LaughVocalizeMode;
new PillsDeathThreshold;
new bool:Drugged[MAXPLAYERS+1];
new TotalPillsUsed[MAXPLAYERS+1];
new DeathCounter[MAXPLAYERS+1];
new Handle:LaughTimerHandle[MAXPLAYERS+1];
new UserMsg:g_FadeUserMsgIdP;
new speedOffset = -1;
new bool:UpgradesOn = false;
new Float:AdrenalineUpgradeMultiplier;

public Plugin:myinfo = 

// SetEntDataFloat(
{
	name = "Pills Addiction",
	author = "Olj",
	description = "Survivors will get drugged by pills for some time",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("KrXsurupHasUpgrade");
	return true;
}

public OnPluginStart()
{
		//ResetCounters//
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

		//CVARS, CMDS//
RegAdminCmd("sm_killdrugs", KillAllDrugsCallback,ADMFLAG_KICK, "Kills all drugs");
CreateConVar("l4d_pa_version", PLUGIN_VERSION, "Version of Pills addiction plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
h_OverdoseTime = CreateConVar("l4d_pillsaddiction_overdose_time", "20.00", "How much time user will be drugged", CVAR_FLAGS);
h_PillsThreshold = CreateConVar("l4d_pillsaddiction_threshold", "1", "How many pills can be used before overdose will take place", CVAR_FLAGS);
h_LaughVocalizeMode = CreateConVar("l4d_pillsaddiction_vocalize_mode", "2", "0 disabled, 1 only one-time laugh on taking pills, 2-laughing untill effects wears off", CVAR_FLAGS, true, 0.00, true, 2.00);
h_PillsDeathThreshold = CreateConVar("l4d_pillsaddiction_death_threshold", "0", "How many pills can be used before user will die from overdose (0 to disable)", CVAR_FLAGS);
h_GivePillsEnabled = CreateConVar("l4d_pillsaddiction_givepills_enabled", "0", "Should we give pills at round start?", CVAR_FLAGS);
h_GivePillsAdminOnly = CreateConVar("l4d_pillsaddiction_givepills_adminonly", "0", "If 1, only admins will get pills on round start.", CVAR_FLAGS);
h_AdrenalineBoostEnabled = CreateConVar("l4d_pillsaddiction_adrenaline_boost_enabled", "1", "If 1, you will get adrenaline speed boost while overdosed.", CVAR_FLAGS);
h_AdrenalineSpeedFactor = CreateConVar("l4d_pillsaddiction_adrenaline_speedfactor", "1.45", "Speed factor of adrenaline boost, 1.0 means no changes, 2.0 means double speed. Use 0.x to decrease speed.", CVAR_FLAGS);
h_GivePillsTimeout = CreateConVar("l4d_pillsaddiction_givepills_timeout", "30.0", "Time which will pass before giving pills at round start.", CVAR_FLAGS);
		//Variables//
g_FadeUserMsgIdP = GetUserMessageId("Fade");
GivePillsEnabled = GetConVarBool(h_GivePillsEnabled);
GivePillsAdminOnly = GetConVarBool(h_GivePillsAdminOnly);
OverdoseTime = GetConVarFloat(h_OverdoseTime);
PillsThreshold = GetConVarInt(h_PillsThreshold);
LaughVocalizeMode = GetConVarInt(h_LaughVocalizeMode);
PillsDeathThreshold = GetConVarInt(h_PillsDeathThreshold);
AdrenalineEnabled = GetConVarBool(h_AdrenalineBoostEnabled);
Speedfactor = GetConVarFloat(h_AdrenalineSpeedFactor);
GivePillsTimeout = GetConVarFloat(h_GivePillsTimeout);
speedOffset = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
		//Hooks//
HookEvent("pills_used", PillsUsed, EventHookMode_Post);
HookConVarChange(h_OverdoseTime, OverdoseTimeChanged);
HookConVarChange(h_PillsThreshold, PillsThresholdChanged);
HookConVarChange(h_LaughVocalizeMode, LaughVocalizeModeChanged);
HookConVarChange(h_PillsDeathThreshold, PillsDeathThresholdChanged);
HookConVarChange(h_GivePillsEnabled, GivePillsEnabledChanged);
HookConVarChange(h_GivePillsAdminOnly, GivePillsAdminOnlyChanged);
HookConVarChange(h_AdrenalineBoostEnabled, AdrenalineBoostEnabledChanged);
HookConVarChange(h_AdrenalineSpeedFactor, AdrenalineSpeedFactorChanged);
HookConVarChange(h_GivePillsTimeout, GivePillsTimeoutChanged);
HookEvent("round_end", Event_RoundEndP, EventHookMode_PostNoCopy);
HookEvent("round_start", RoundStartPills, EventHookMode_Post);
		//ExecConfig//
AutoExecConfig(true, "l4d_pills_addiction");
}
		//CVAR Changes callbacks//

public OnConfigsExecuted()
	{	
		if ((LibraryExists("KrX_surup"))&&(RunningUpgrades()==true))
			{
				UpgradesOn = true;
				AdrenalineUpgradeMultiplier = GetConVarFloat(FindConVar("surup_upgrade_adrenaline_multiplier"));
				LogMessage("Upgrades detected: Adrenaline Multiplier %f ", AdrenalineUpgradeMultiplier);
			}
	}
		
public GivePillsTimeoutChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		GivePillsTimeout = GetConVarFloat(h_GivePillsTimeout);
	}			
			
public AdrenalineSpeedFactorChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		Speedfactor = GetConVarFloat(h_AdrenalineSpeedFactor);
	}			
		
public AdrenalineBoostEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		AdrenalineEnabled = GetConVarBool(h_AdrenalineBoostEnabled);
	}	
				
public OverdoseTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		OverdoseTime = GetConVarFloat(h_OverdoseTime);
	}

public PillsThresholdChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		PillsThreshold = GetConVarInt(h_PillsThreshold);
	}
	
public PillsDeathThresholdChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		PillsDeathThreshold = GetConVarInt(h_PillsDeathThreshold);
		if (strcmp(oldValue,"0", false)==0) for (new c = 1; c <=MaxClients; c++) { DeathCounter[c] = 0;
		}
	}
	
public LaughVocalizeModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		LaughVocalizeMode = GetConVarInt(h_LaughVocalizeMode);
	}
	
public GivePillsEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		GivePillsEnabled = GetConVarBool(h_GivePillsEnabled);
	}

public GivePillsAdminOnlyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		GivePillsAdminOnly = GetConVarBool(h_GivePillsAdminOnly);
	}
	
		//Killing drugs on Round End and Map End//
public Action:Event_RoundEndP(Handle:event,const String:name[],bool:dontBroadcast)
{
	KillAllDrugsP();
	ResetCounters();
}

public OnMapStart()
{
	PrintToChatAll("Pain Pills running");
}
public OnMapEnd()
{
	ResetCounters();
	KillAllDrugsP();
}

		//Giving Pills at round start//
public RoundStartPills(Handle:event, const String:name[], bool:dontBroadcast)
	{
			{
				new Flags = GetCommandFlags("give");
				CreateTimer(GivePillsTimeout, GivePillsTimer, any:Flags);
			}
	}
		//KillDrugs Callback//
public Action:KillAllDrugsCallback(client, args)
	{
		KillAllDrugsP();
	}
		//Pills Used callback//
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
								SetEntDataFloat(clientID, speedOffset, 1.0, true);
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
				PrintToChat(clientID, "Careful, you have been overdosed by \x03PILLZ!");
				TotalPillsUsed[clientID] = 0;
				if (AdrenalineEnabled) 
					{
						if (LibraryExists("KrX_surup"))
							{
								if ((UpgradesOn)&&(KrXsurupHasUpgrade(clientID, 15))&&(AdrenalineUpgradeMultiplier>Speedfactor)) 
									{
										//LogMessage("Adrenaline value : %f",AdrenalineUpgradeMultiplier);
										//if (AdrenalineUpgradeMultiplier>Speedfactor) LogMessage("AdrenalineUpgradeMultiplier>Speedfactor");
										//if (UpgradesOn) LogMessage("UpgradesOn");
										//if (KrXsurupHasUpgrade(clientID, 15)) LogMessage("Client %i has boost", clientID);
										return;
									}
							}
						SetEntDataFloat(clientID, speedOffset, Speedfactor, true);
					}
			}
	}
		//We kill drug after overdose duration expired//
public Action:toggleDrug(Handle:timer, any:clientID)
	{
		if (!IsValidClient(clientID)) return;
		new String:CLname[MAX_NAME_LENGTH];
		GetClientName(clientID,CLname,MAX_NAME_LENGTH);
		if (Drugged[clientID]==true)
			{
				KillDrugP(clientID);
				if (LibraryExists("KrX_surup"))
					{
						if ((UpgradesOn)&&(KrXsurupHasUpgrade(clientID, 15)))
							{
								//LogMessage("Line 252 Client has adrenaline boost");
								SetEntDataFloat(clientID, speedOffset, AdrenalineUpgradeMultiplier, true);
							}
						else
							{
								SetEntDataFloat(clientID, speedOffset, 1.0, true);
							}
					}
				else
					{
						//LogMessage("Line 257 CLient dont have adrenaline boost");
						SetEntDataFloat(clientID, speedOffset, 1.0, true);
					}
				if (GetClientTeam(clientID)==2)
					{
						PrintToChat(clientID, "Overdose effect wore off");
					}
				Drugged[clientID]=false;
			}
	}
		//Laughing is nice, doesnt it?//
public Action:LaughTimer(Handle:timer, any:clientID)
	{	
		if ((!IsValidClient(clientID))||(Drugged[clientID]==false)||(LaughVocalizeMode!=2))
			{
				if (LaughTimerHandle[clientID] != INVALID_HANDLE) KillTimer(LaughTimerHandle[clientID]);			
			}
		else ClientCommand(clientID, "vocalize PlayerLaugh");
		return Plugin_Continue;
	}
		//Too many pills?//
public Action:OverdoseKill(Handle:timer, any:clientID)
	{
		if (IsValidClient(clientID))
			{
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(clientID, name, MAX_NAME_LENGTH);
				ForcePlayerSuicide(clientID);
				PrintToChatAll("\05%s died from overdose", name);
			}
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
	Drugged[client]=false; // Client is no more drugged
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
		// Valid client check function //
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
		// Give Pills Function //
ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
    if (Client==0) return;
    new Flags = GetCommandFlags(strCommand);
    SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", strCommand, strParam1);
    //SetCommandFlags(strCommand, Flags);
}
		// Is Admin Check //
bool:IsClientAdmin (client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id == INVALID_ADMIN_ID)
		return false;
	
	if (GetAdminFlag(id, Admin_Reservation)||GetAdminFlag(id, Admin_Root)||GetAdminFlag(id, Admin_Kick))
		return true;
	else
	return false;
}

bool:RunningUpgrades()
	{
		if (FindConVar("survivorupgradeskrx_version")!=INVALID_HANDLE)
		return true;
		
		else
		return false;
	}


ResetCounters()
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
for (new d = 1; d <=MaxClients; d++)
	{
		if (LibraryExists("KrX_surup"))
			{
				if ((IsValidClient(d))&&(!KrXsurupHasUpgrade(d, 15))&&(GetClientTeam(d)==2)) SetEntDataFloat(d, speedOffset, 1.0, true);
			}
		else
			{
				if ((IsValidClient(d))&&(GetClientTeam(d)==2)) SetEntDataFloat(d, speedOffset, 1.0, true);
			}
	}
}



public Action:GivePillsTimer(Handle:timer, any:Flags)
{
	if (GivePillsEnabled)
		{
			switch (GivePillsAdminOnly)
				{
					case 0:
						{
							for (new i = 1; i <=MaxClients; i++)
								{
									if ((IsClientInGame(i))&&(IsPlayerAlive(i))&&(GetClientTeam(i)==2)&&(i>0)) ExecuteCommand(i, "give", "pain_pills");
									if (i==MaxClients)
										{
											SetCommandFlags("give", Flags);
											PrintToChatAll("\x03PILLZ!\x01 was granted to survivors by God.");
										}
								}
						}
					case 1:
						{
							for (new i = 1; i <=MaxClients; i++)
								{
									if ((IsClientInGame(i))&&(IsPlayerAlive(i))&&(GetClientTeam(i)==2)&&(i>0)&&(IsClientAdmin(i))) ExecuteCommand(i, "give", "pain_pills");
									if (i==MaxClients)
										{
											SetCommandFlags("give", Flags);
											PrintToChatAll("\x03PILLZ!\x01 was granted to admins by God.");
										}
								}
						}
				}
		}
}