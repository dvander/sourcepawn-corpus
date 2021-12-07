#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.3"

public Plugin myinfo =
{
	name = "[TF2] MvM Robot stun effect",
	author = "Whai",
	description = "MvM Stun robot team with mannhattan's stun effect'",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] cError, int iErrMax)
{
	char cGameFolder[32];
	GetGameFolderName(cGameFolder, sizeof(cGameFolder));

	if(!StrEqual(cGameFolder, "tf"))
	{
		Format(cError, iErrMax, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

Handle hTimerCount;
ConVar hCritDuration;
bool bRobotStunned, bSoundPlayed, bCanTaunt;
float fCritDuration, fTimerCount;

float fTimerDuration = 22.5;
float fStunDuration = 22.75;
int g_iParticle[MAXPLAYERS+1], iHealth[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegAdminCmd("sm_robostun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_robotstun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_stunrobot", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	
	hCritDuration = CreateConVar("sm_critduration", "10.0", "The crit duration", 0, true, 0.0);
	HookConVarChange(hCritDuration, ConVarChanged);
	
	HookEvent("player_spawn", PlayerSpawned);
	HookEvent("player_death", PlayerDie_ChangeClass_Disconnect, EventHookMode_Pre);
	HookEvent("player_changeclass", PlayerDie_ChangeClass_Disconnect, EventHookMode_Pre);
	HookEvent("player_disconnect", PlayerDie_ChangeClass_Disconnect, EventHookMode_Pre);
	
	AddCommandListener(BlockTaunt, "taunt");
	AddCommandListener(BlockTaunt, "use_action_slot_item");
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	fCritDuration = GetConVarFloat(hCritDuration);
}

public void OnMapStart()
{
	PrecacheSound("misc/cp_harbor_red_whistle.wav", true);
	PrecacheSound("vo/announcer_security_alert.mp3", true);
	PrecacheSound("mvm/mvm_robo_stun.wav", true);
	
	bRobotStunned = false;
	bSoundPlayed = false;
	fTimerCount = 0.0;
}

public void OnMapEnd()
{
	bRobotStunned = false;
	bSoundPlayed = false;
	fTimerCount = 0.0;
}

public Action PlayerSpawned(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(TF2_GetClientTeam(iClient) == TFTeam_Blue)
	{
		if(bRobotStunned)
		{
			if(IsValidClient(iClient))
				CreateTimer(0.1, StunClient, iClient);
				
		}
	}
}

public Action PlayerDie_ChangeClass_Disconnect(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(TF2_GetClientTeam(iClient) == TFTeam_Blue && !IsFakeClient(iClient))
	{
		if(bRobotStunned)
		{
			if(IsValidClient(iClient))
				DeleteParticle(g_iParticle[iClient]);
				
		}
	}
}

public Action BlockTaunt(int client, const char[] command, int argc)
{
	if(IsValidClient(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		if(!bCanTaunt)
			return Plugin_Handled;
			
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int iEntity, const char[] cClassname)
{
	if(StrEqual(cClassname, "tank_boss"))
	{
		if(bRobotStunned)
		{
			SetVariantInt(0); 
			AcceptEntityInput(iEntity, "SetSpeed");
			
			float fTimer = fTimerDuration;
			float FinaleTimer = (fTimer - fTimerCount);
			
			if(FinaleTimer < 0.1)
				CreateTimer(0.1, TankSpeed);
				
			else
				CreateTimer(FinaleTimer, TankSpeed);
			
		}
	}
	if (StrEqual(cClassname, "func_respawnroom", false))
	{
		SDKHook(iEntity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(iEntity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public Action Command_RobotStun(int client, int args)
{
	if(IsMannVsMachineMode())
	{
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: sm_robostun");
			return Plugin_Handled;
		}
		else
		{
			if(!bRobotStunned)
				MVMStunPlayer(client);
			
			else
				ReplyToCommand(client, "[SM] Blu Team already stunned");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Command only in MvM");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void MVMStunPlayer(int client)
{
	for (int iTarget; iTarget <= MaxClients; iTarget++)
	{
		if(IsValidClient(iTarget))
		{
			if(TF2_GetClientTeam(iTarget) == TFTeam_Blue)
			{
				if(IsPlayerAlive(iTarget))
				{
					if(IsFakeClient(iTarget))
						TF2_AddCondition(iTarget, TFCond_MVMBotRadiowave, fStunDuration);
					
					else
					{
						if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged))
							TF2_RemoveCondition(iTarget, TFCond_Ubercharged);
							
						if(TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen))
							TF2_RemoveCondition(iTarget, TFCond_UberchargedCanteen);
							
						if(TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden))
							TF2_RemoveCondition(iTarget, TFCond_UberchargedHidden);
							
						if(TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage))
							TF2_RemoveCondition(iTarget, TFCond_UberchargedOnTakeDamage);
						
						TF2_StunPlayer(iTarget, fStunDuration, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_SOUND);
						AttachParticle(iTarget, "bot_radio_waves");
					}
					
					int iTank = -1;
					
					while((iTank = FindEntityByClassname(iTank, "tank_boss")) != INVALID_ENT_REFERENCE)
					{
						SetVariantInt(0); 
						AcceptEntityInput(iTank, "SetSpeed");
					}
					
					if(bSoundPlayed)
					{
						for (int i = 0; i <= MaxClients; i++)
						{
							StopSound(i, SNDCHAN_AUTO, "misc/cp_harbor_red_whistle.wav");
						}
					}	
					CreateTimer(fTimerDuration, CritConditions, iTarget);
					bRobotStunned = true;
					bCanTaunt = false;
				}
			}
		}
	}
	if(bRobotStunned)
	{
		hTimerCount = CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);
		CreateTimer(fTimerDuration, TankSpeed);
		fTimerCount = 0.0;
		EmitSoundToAll("vo/announcer_security_alert.mp3");
		EmitSoundToAll("mvm/mvm_robo_stun.wav");
		ReplyToCommand(client, "[SM] Blu Team Stunned");
	}
}

public Action SpawnStartTouch(int spawn, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if(TF2_GetClientTeam(client) == TFTeam_Blue)
			TF2_AddCondition(client, TFCond_UberchargedHidden);
	}
}

public Action SpawnEndTouch(int spawn, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if(TF2_GetClientTeam(client) == TFTeam_Blue)
			TF2_RemoveCondition(client, TFCond_UberchargedHidden);
	}
}

void AttachParticle(int iEnt, char[] cParticleType)
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	char cName[128];
	if(IsValidEdict(iParticle))
	{
		float pos[3];
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 10;
		TeleportEntity(iParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(cName, sizeof(cName), "target%i", iEnt);
		DispatchKeyValue(iEnt, "targetname", cName);
		
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", cName);
		DispatchKeyValue(iParticle, "effect_name", cParticleType);
		DispatchSpawn(iParticle);
		SetVariantString(cName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		g_iParticle[iEnt] = iParticle;
	}
}

void DeleteParticle(any iParticle)
{
    if (IsValidEntity(iParticle))
    {
        char cClassname[256];
        GetEdictClassname(iParticle, cClassname, sizeof(cClassname));
        if (StrEqual(cClassname, "info_particle_system", false))
        {
            AcceptEntityInput(iParticle, "Kill");
        }
    }
}

public Action TimerCount(Handle timer)
{
	if(fTimerCount < (fTimerDuration + 0.5))
	{
		fTimerCount++; //= (fTimerCount + 1.0);
		//PrintToChatAll("Float count = %0.f", fTimerCount);
	}
		
	else
		CreateTimer(0.1, ResetTimer);
}

public Action ResetTimer(Handle timer)
{
	fTimerCount = 0.0;
	KillTimer(hTimerCount);
	//PrintToChatAll("Float count = %0.f Should Be Reset", fTimerCount);
}

public Action CritConditions(Handle timer, any target)
{
	TF2_AddCondition(target, TFCond_CritCanteen, fCritDuration);
	TF2_RemoveCondition(target, TFCond_MVMBotRadiowave);
	DeleteParticle(g_iParticle[target]);
	CreateTimer(1.5, WeaponFix, target);
	
	//PrintToChatAll("Crit Condition");
	bCanTaunt = true;
}

public Action WeaponFix(Handle timer, any target)
{
	TF2_RemoveAllWeapons(target);
	iHealth[target] = GetClientHealth(target);
	TF2_RegeneratePlayer(target);
	SetEntityHealth(target, iHealth[target]);
}

public Action StunClient(Handle timer, any client)
{
	float fDuration = fStunDuration;
	float FinalDuration = (fDuration - fTimerCount);
	float fNewTimer;
	
	if(FinalDuration < 0.1)
		fNewTimer = 0.1;
	
	else
		fNewTimer = FinalDuration;
	
	if(IsFakeClient(client))
		TF2_AddCondition(client, TFCond_MVMBotRadiowave, fNewTimer);
				
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
			TF2_RemoveCondition(client, TFCond_Ubercharged);
							
		if(TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))
			TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
							
		if(TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden))
			TF2_RemoveCondition(client, TFCond_UberchargedHidden);
							
		if(TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage))
			TF2_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
			
		TF2_StunPlayer(client, fNewTimer, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_SOUND);
		AttachParticle(client, "bot_radio_waves");
	}
		
	float fStunCrit = fTimerDuration;
	float FinalStunCrit = (fStunCrit - fTimerCount);
	
	if(FinalStunCrit < 0.1)			
		CreateTimer(0.1, LateStun, client);
	
	else
		CreateTimer(FinalStunCrit, LateStun, client);
}

public Action LateStun(Handle timer, any target)
{
	TF2_AddCondition(target, TFCond_CritCanteen, fCritDuration);
	TF2_RemoveCondition(target, TFCond_MVMBotRadiowave);
	DeleteParticle(g_iParticle[target]);
	//PrintToChatAll("Crit Conditions late");
}

public Action TankSpeed(Handle timer)
{
	int tank = -1;
	while((tank = FindEntityByClassname(tank, "tank_boss")) != INVALID_ENT_REFERENCE)
	{
		SetVariantInt(200); 
		AcceptEntityInput(tank, "SetSpeed");
		//PrintToChatAll("Tank Speed Set");
	}
	EmitSoundToAll("misc/cp_harbor_red_whistle.wav");
	bRobotStunned = false;
	bSoundPlayed = true;
	CreateTimer(9.0, SoundNotPlaying);
}

public Action SoundNotPlaying(Handle timer)
{
	bSoundPlayed = false;
	//PrintToChatAll("Sound not playing for now");
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock bool IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}
