#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.4"

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

Handle hTimerCount, hTimerEnd;
ConVar hCritDuration, hTankSpeed;
bool bRobotStunned, bSoundPlayed, bCanTaunt;
float fCritDuration, fTimerCount;

float fTimerDuration = 22.5;
float fStunDuration = 22.75;
int iParticle[MAXPLAYERS+1];
static int iTankNormalSpeed[2048];
int iTankSpeedMult;

public void OnPluginStart()
{		
	RegAdminCmd("sm_robostun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_robotstun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_stunrobot", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	
	hCritDuration = CreateConVar("sm_critduration", "10.0", "The crit duration", 0, true, 0.0);
	HookConVarChange(hCritDuration, ConVarChanged);
	hTankSpeed = CreateConVar("sm_tankspeed", "3.0", "Tank Speed Multiplier");
	HookConVarChange(hTankSpeed, ConVarChanged);
	
	HookEvent("player_spawn", PlayerSpawned_ChangeClass);
	HookEvent("player_changeclass", PlayerSpawned_ChangeClass);
	HookEvent("player_death", PlayerDie_Disconnect, EventHookMode_Pre);
	HookEvent("player_disconnect", PlayerDie_Disconnect, EventHookMode_Pre);
	
	AddCommandListener(BlockTaunt, "taunt");
	AddCommandListener(BlockTaunt, "use_action_slot_item");
	
	hTimerEnd = null;
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	fCritDuration = GetConVarFloat(hCritDuration);
	iTankSpeedMult = GetConVarInt(hTankSpeed);
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

public Action PlayerSpawned_ChangeClass(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iUserID = hEvent.GetInt("userid");
	int iClient = GetClientOfUserId(iUserID);
	
	if(TF2_GetClientTeam(iClient) == TFTeam_Blue)
	{
		if(bRobotStunned)
		{
			if(IsValidClient(iClient))
			{
				DeleteParticle(iParticle[iClient]);
				CreateTimer(0.1, StunClient, iUserID);
			}	
		}
	}
}

public Action PlayerDie_Disconnect(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(TF2_GetClientTeam(iClient) == TFTeam_Blue && !IsFakeClient(iClient))
	{
		if(bRobotStunned)
		{
			if(IsValidClient(iClient))
				DeleteParticle(iParticle[iClient]);
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
			int iTankSpeed = FindDataMapInfo(iEntity, "m_speed");
			
			iTankNormalSpeed[iEntity] = GetEntData(iEntity, iTankSpeed);
			SetEntData(iEntity, iTankSpeed, 0);
			
			float fTimer = fTimerDuration;
			float FinaleTimer = (fTimer - fTimerCount);
			
			if(FinaleTimer < 0.1)
				CreateTimer(0.1, TankSpeed, EntIndexToEntRef(iEntity));
				
			else
				CreateTimer(FinaleTimer, TankSpeed, EntIndexToEntRef(iEntity));
			
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
	int iTank = -1;
	while((iTank = FindEntityByClassname(iTank, "tank_boss")) != INVALID_ENT_REFERENCE)
	{	
		int iTankSpeed = FindDataMapInfo(iTank, "m_speed");
		
		iTankNormalSpeed[iTank] = GetEntData(iTank, iTankSpeed);
		SetEntData(iTank, iTankSpeed, 0);
		//PrintToChatAll("%i Tank Speed", iTankSpeed);
		CreateTimer(fTimerDuration, TankSpeed, EntIndexToEntRef(iTank));
		bRobotStunned = true;
		bCanTaunt = false;
	}
	if(bRobotStunned)
	{
		hTimerCount = CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);
		fTimerCount = 0.0;
		EmitSoundToAll("vo/announcer_security_alert.mp3");
		EmitSoundToAll("mvm/mvm_robo_stun.wav");
		ReplyToCommand(client, "[SM] Blu Team Stunned");
		hTimerEnd = CreateTimer(fTimerDuration, SoundEnd);
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	for(int i = 0; i <= MaxClients; i++)
	{
		StopSound(i, SNDCHAN_AUTO, "misc/cp_harbor_red_whistle.wav");
		StopSound(i, SNDCHAN_AUTO, "mvm/mvm_robo_stun.wav");
		StopSound(i, SNDCHAN_AUTO, "vo/announcer_security_alert.mp3");
		bSoundPlayed = false;
	}
	if(hTimerEnd != null)
	{
		KillTimer(hTimerEnd);
		hTimerEnd = null;
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

void AttachParticle(int iEntity, char[] cParticleType)
{
	int iParticleSystem = CreateEntityByName("info_particle_system");
	
	char cName[128];
	if(IsValidEdict(iParticleSystem))
	{
		float pos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 10;
		TeleportEntity(iParticleSystem, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(cName, sizeof(cName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", cName);
		
		DispatchKeyValue(iParticleSystem, "targetname", "tf2particle");
		DispatchKeyValue(iParticleSystem, "parentname", cName);
		DispatchKeyValue(iParticleSystem, "effect_name", cParticleType);
		DispatchSpawn(iParticleSystem);
		SetVariantString(cName);
		AcceptEntityInput(iParticleSystem, "SetParent", iParticleSystem, iParticleSystem, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticleSystem, "SetParentAttachment", iParticleSystem, iParticleSystem, 0);
		ActivateEntity(iParticleSystem);
		AcceptEntityInput(iParticleSystem, "start");
		
		iParticle[iEntity] = iParticleSystem;
	}
}

void DeleteParticle(any iParticleSysteme)
{
    if (IsValidEntity(iParticleSysteme))
    {
        char cClassname[256];
        GetEdictClassname(iParticleSysteme, cClassname, sizeof(cClassname));
        if (StrEqual(cClassname, "info_particle_system", false))
        {
            AcceptEntityInput(iParticleSysteme, "Kill");
        }
    }
}

public Action TimerCount(Handle timer)
{
	if(fTimerCount < (fTimerDuration + 0.5))
	{
		fTimerCount++;
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
	DeleteParticle(iParticle[target]);
	//PrintToChatAll("Crit Condition");
	bCanTaunt = true;
}

public Action StunClient(Handle timer, any iClient)
{
	int client = GetClientOfUserId(iClient);
	
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
		CreateTimer(0.1, LateStun, iClient);
	
	else
		CreateTimer(FinalStunCrit, LateStun, iClient);
}

public Action LateStun(Handle timer, any iTarget)
{
	int target = GetClientOfUserId(iTarget);
	TF2_AddCondition(target, TFCond_CritCanteen, fCritDuration);
	TF2_RemoveCondition(target, TFCond_MVMBotRadiowave);
	DeleteParticle(iParticle[target]);
	//PrintToChatAll("Crit Conditions late");
}

public Action TankSpeed(Handle timer, any iRefTank)
{
	int tank = EntRefToEntIndex(iRefTank);
	
	if(IsValidEntity(tank))
	{
		int iTankSpeed = FindDataMapInfo(tank, "m_speed");
		
		SetEntData(tank, iTankSpeed, (iTankNormalSpeed[tank] * iTankSpeedMult));
		CreateTimer(fCritDuration, ResetTankSpeed, iRefTank);
		//PrintToChatAll("Tank Speed multiplied : %i by %i = %i", iTankNormalSpeed[tank], iTankSpeedMult, (iTankNormalSpeed[tank] * iTankSpeedMult));
	}
}

public Action SoundEnd(Handle timer)
{
	EmitSoundToAll("misc/cp_harbor_red_whistle.wav");
	bRobotStunned = false;
	bSoundPlayed = true;
	CreateTimer(9.0, SoundNotPlaying);
	hTimerEnd = null;
}

public Action ResetTankSpeed(Handle timer, any iRefTank)
{
	int tank = EntRefToEntIndex(iRefTank);
	if(IsValidEntity(tank))
	{
		int iTankSpeed = FindDataMapInfo(tank, "m_speed");
		SetEntData(tank, iTankSpeed, (iTankNormalSpeed[tank] * 1));
		//PrintToChatAll("Tank Speed Reset to normal : %i", iTankNormalSpeed[tank]);
	}
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
