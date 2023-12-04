#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define DEBUG 0

#define LEGS_TELEPORTDIST 0.0, 0.0, -3000.0
#define LEGS_VIEWOFFSET 0.0, 0.0, -20.0

#define EFL_DONTBLOCKLOS				(1<<25)

#define PLUGIN_VERSION "1.6.0"

enum
{
	EF_BONEMERGE			= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 			= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 			= 0x004,	// player flashlight
	EF_NOINTERP				= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW				= 0x010,	// Don't cast no shadow
	EF_NODRAW				= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW		= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
};

native int LMC_GetClientOverlayModel(int iClient);// remove this and enable the include to compile with the include this is just here for AM compiler

static int iEntRef[MAXPLAYERS+1];
static int iEntOwner[2048+1];
static int iAttachedRef[2048+1];
static int iAttachedOwner[2048+1];
static bool bThirdPerson[MAXPLAYERS+1];

static bool bLMC_Available = false;
static bool bLMC_Integration = false;

ConVar cvar_LMC_Integration;
ConVar cvar_LimpHP;
ConVar cvar_mp_facefronttime;

float g_fLimpHP;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("LMCCore");
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "LMCCore"))
		bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "LMCCore"))
		bLMC_Available = false;
}

public Plugin myinfo =
{
	name = "[L4D2]Survivor_Legs_Restore",
	author = "Lux",
	description = "Add's Left 4 Dead 1 Style ViewModel Legs",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=299560"
};

public void OnPluginStart()
{
	CreateConVar("survivor_legs_version", PLUGIN_VERSION, "[L4D2]Survivor_Legs_version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", ePlayerSpawn);
	HookEvent("player_team", eTeamChange);
	HookEvent("round_start", eRoundStart);
	
	cvar_mp_facefronttime = FindConVar("mp_facefronttime");
	cvar_mp_facefronttime.AddChangeHook(eConvarChanged);
	
	cvar_LimpHP = FindConVar("survivor_limp_health");
	cvar_LimpHP.AddChangeHook(eConvarChanged);
	
	cvar_LMC_Integration = CreateConVar("lmc_integration", "1", "Copy LMC model to legs model, creates an extra entity for legs, will update on state change for legs", _, true, 0.0, true, 1.0);
	cvar_LMC_Integration.AddChangeHook(eConvarChanged);
	AutoExecConfig(true, "_[L4D2]Survivor_Legs");
	CvarsChanged();
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidEntRef(iEntRef[iClient])) continue;
		
		int iEntity = EntRefToEntIndex(iEntRef[iClient]);
		RemoveEntity(iEntity);
	}
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	cvar_mp_facefronttime.SetFloat(-1.0, true);
	bLMC_Integration = cvar_LMC_Integration.BoolValue;
	g_fLimpHP =	cvar_LimpHP.FloatValue;
}

void AttachLegs(int iClient)
{
	int iEntity;	
	char sModel[PLATFORM_MAX_PATH];
	
	if(IsValidEntRef(iEntRef[iClient]))
	{
		iEntity = EntRefToEntIndex(iEntRef[iClient]);
		GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		SetEntityModel(iEntity, sModel);
		
		if(bLMC_Available)
			AttachOverlayLegs(iClient, true);
		
		return;
	}
		
	
	iEntity = CreateEntityByName("prop_dynamic_override");
	if(iEntity < 0)
		return;
	
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	DispatchKeyValue(iEntity, "model", sModel);
	DispatchKeyValue(iEntity, "solid", "0");
	DispatchKeyValue(iEntity, "spawnflags", "256");
	
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iClient);
	
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	
	int iFlags = GetEntProp(iEntity, Prop_Data, "m_iEFlags");
	iFlags = iFlags |= EFL_DONTBLOCKLOS; //you never know with this game.
	SetEntProp(iEntity, Prop_Data, "m_iEFlags", iFlags);
	
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6, 1);
	
	SetEntProp(iEntity, Prop_Send, "m_bClientSideAnimation", 1, 1);
	AcceptEntityInput(iEntity, "DisableShadow");
	
	float fPos[3];
	float fAng[3];
	GetClientAbsOrigin(iClient, fPos);
	GetClientEyeAngles(iClient, fAng);
	
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(iClient, NULL_VECTOR, view_as<float>({89.0, 0.0, 0.0}), NULL_VECTOR);
	
	TeleportEntity(iEntity, view_as<float>({LEGS_VIEWOFFSET}), view_as<float>({-89.0, 0.0, 0.0}), NULL_VECTOR);
	TeleportEntity(iClient, NULL_VECTOR, fAng, NULL_VECTOR);
	
	iEntRef[iClient] = EntIndexToEntRef(iEntity);
	iEntOwner[iEntity] = GetClientUserId(iClient);
	
	//LMC
	if(bLMC_Available)
		AttachOverlayLegs(iClient, false);
	
	SDKHook(iEntity, SDKHook_SetTransmit, HideModel);
}

//lmcstuff
void AttachOverlayLegs(int iClient, bool bBaseReattach)
{
	int iSurvivorLegs = EntRefToEntIndex(iEntRef[iClient]);
	
	if(!IsValidEntRef(iSurvivorLegs))
		return;
	
	if(!bLMC_Integration)
	{
		if(IsValidEntRef(iAttachedRef[iSurvivorLegs]))
		{
			RemoveEntity(iAttachedRef[iSurvivorLegs]);
		}
		ToggleLegsRender(iSurvivorLegs, true);
		return;
	}
	
	int iOverlayModel = LMC_GetClientOverlayModel(iClient);
	
	if(iOverlayModel == -1)
		return;
		
	int iEnt = EntRefToEntIndex(iAttachedRef[iSurvivorLegs]);
	
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iOverlayModel, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	if(IsValidEntRef(iAttachedRef[iSurvivorLegs]))
	{
		if(!bBaseReattach)
		{
			SetEntityModel(iEnt, sModel);
			return;
		}
		else
			RemoveEntity(iEnt);
	}
	
	iEnt = CreateEntityByName("prop_dynamic_override");
	if(iEnt < 0)
		return;
	
	DispatchKeyValue(iEnt, "model", sModel);
	DispatchKeyValue(iEnt, "solid", "0");
	DispatchKeyValue(iEnt, "spawnflags", "256");
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	
	AcceptEntityInput(iEnt, "DisableShadow");
	 
	SetAttach(iEnt, iSurvivorLegs);
	
	int iFlags = GetEntProp(iEnt, Prop_Data, "m_iEFlags");
	iFlags = iFlags |= EFL_DONTBLOCKLOS; //you never know with this game.
	SetEntProp(iEnt, Prop_Data, "m_iEFlags", iFlags);
	
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6, 1);
	
	ToggleLegsRender(iSurvivorLegs, false);
	
	iAttachedRef[iSurvivorLegs] = EntIndexToEntRef(iEnt);
	iAttachedOwner[iEnt] = GetClientUserId(iClient);
		
	SDKHook(iEnt, SDKHook_SetTransmit, HideOverlayModel);
}

public Action HideModel(int iEntity, int iClient)
{
	if(IsFakeClient(iClient))
		return Plugin_Continue;
	
	static int iOwner;
	iOwner = GetClientOfUserId(iEntOwner[iEntity]);
	
	if(iOwner < 1 || !IsClientInGame(iOwner))
	return Plugin_Continue;
	
	if(iOwner != iClient)
		return Plugin_Handled;
	
	if(ShouldHideLegs(iClient))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action HideOverlayModel(int iEntity, int iClient)
{
	if(IsFakeClient(iClient))
		return Plugin_Continue;
	
	static int iOwner;
	iOwner = GetClientOfUserId(iAttachedOwner[iEntity]);
	
	if(iOwner < 1 || !IsClientInGame(iOwner))
	return Plugin_Continue;
	
	if(iOwner != iClient)
		return Plugin_Handled;
	
	if(ShouldHideLegs(iClient))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

public void ePlayerSpawn(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	if(IsValidEntRef(iEntRef[iClient]))
		return;
	
	RequestFrame(NextFrame, GetClientUserId(iClient));
}

public void NextFrame(any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
		return;
	
	AttachLegs(iClient);
}

public void eTeamChange(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	if(!IsValidEntRef(iEntRef[iClient]))
		return;
	
	RemoveEntity(iEntRef[iClient]);
	iEntRef[iClient] = -1;
}

public void ePlayerDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iVictim < 1 || iVictim > MaxClients)
		return;
	
	if(!IsClientInGame(iVictim) || IsFakeClient(iVictim) || GetClientTeam(iVictim) != 2)
		return;
	
	if(!IsValidEntRef(iEntRef[iVictim]))
		return;
	
	RemoveEntity(iEntRef[iVictim]);
	iEntRef[iVictim] = -1;
}

public void Hook_OnPostThinkPost(int iClient)
{
	if(!IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2) 
		return;
	
	static int iEntity;
	iEntity = EntRefToEntIndex(iEntRef[iClient]);
	
	if(!IsValidEntRef(iEntity))
		return;
	
	static int iModelIndex[MAXPLAYERS+1] = {0, ...};		
	if(iModelIndex[iClient] != GetEntProp(iClient, Prop_Data, "m_nModelIndex", 2))
	{	
		//LMC Reattachbase
		iModelIndex[iClient] = GetEntProp(iClient, Prop_Data, "m_nModelIndex", 2);
		AttachLegs(iClient);
	}
	
	SetEntPropFloat(iEntity, Prop_Send, "m_flPlaybackRate", GetEntPropFloat(iClient, Prop_Send, "m_flPlaybackRate"));
	SetEntProp(iEntity, Prop_Send, "m_nSequence", CheckAnimation(iClient, GetEntProp(iClient, Prop_Send, "m_nSequence", 2)), 2);
	
#if DEBUG
	static int lastanim[MAXPLAYERS+1];
	
	int seq = GetEntProp(iClient, Prop_Send, "m_nSequence", 2);
	if(seq != lastanim[iClient])
	{
		PrintToChat(iClient, "Client(m_nSquence)[%i] Legs(m_nSequence)[%i]", seq, GetEntProp(iEntity, Prop_Send, "m_nSequence", 2));
		lastanim[iClient] = seq;
	}
#endif
	
	SetEntPropFloat(iEntity, Prop_Send, "m_flCycle", GetEntPropFloat(iClient, Prop_Send, "m_flCycle"));
	
	static int i;
	for (i = 0; i < 23; i++)
	{
		switch (i)
		{
			case 0, 2:
				SetEntPropFloat(iEntity, Prop_Send, "m_flPoseParameter", 0.0, i);
			default:
				SetEntPropFloat(iEntity, Prop_Send, "m_flPoseParameter", GetEntPropFloat(iClient, Prop_Send, "m_flPoseParameter", i), i);//credit to death chaos for animating legs
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	SDKHook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

public void OnClientDisconnect(int iClient)
{
	if(!IsFakeClient(iClient))
		SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	
	if(!IsValidEntRef(iEntRef[iClient]))
		return;
	
	RemoveEntity(iEntRef[iClient]);
	iEntRef[iClient] = -1;
}

public void eRoundStart(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		iEntRef[i] = -1;
}

public void LMC_OnClientModelApplied(int iClient, int iEntity, const char sModel[PLATFORM_MAX_PATH], bool bBaseReattach)
{
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	AttachOverlayLegs(iClient, bBaseReattach);
}

public void LMC_OnClientModelChanged(int iClient, int iEntity, const char sModel[PLATFORM_MAX_PATH])
{
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	AttachOverlayLegs(iClient, false);
}

public void LMC_OnClientModelDestroyed(int iClient, int iEntity)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	int iSurvivorLegs = EntRefToEntIndex(iEntRef[iClient]);
	
	if(!IsValidEntRef(iSurvivorLegs))
		return;
	
	int iOverlayLegs = EntRefToEntIndex(iAttachedRef[iSurvivorLegs]);
	
	if(!IsValidEntRef(iOverlayLegs))
		return;
	
	ToggleLegsRender(iSurvivorLegs, true);
	RemoveEntity(iOverlayLegs);
}

void ToggleLegsRender(int iLegs, bool bShow=false)
{
	int iFlags = GetEntProp(iLegs, Prop_Data, "m_fEffects");
	if(bShow)
	{
		iFlags = iFlags &= ~0x020;
	}
	else
	{
		iFlags = iFlags |= 0x020;
	}
	SetEntProp(iLegs, Prop_Send, "m_fEffects", iFlags);
}

static bool IsValidEntRef(int iEnt)
{
	return (iEnt != 0 && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE);
}

static bool ShouldHideLegs(int iClient) 
{
	if(bThirdPerson[iClient])
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hZoomOwner") == iClient)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_isIncapacitated") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
		return true; 
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
		return true;  
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true; 
	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static int iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			
			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 5, 6, 7, 8, 9, 10:
			return true;
	}
	
	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 643, 630, 629, 628, 627, 619, 616, 605, 606:
					return true;
			}
		}
		case 'd', 'w'://rochelle, adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 651, 638, 637, 636, 635, 616, 615, 614:
					return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 637, 630, 629, 628, 627, 615, 607, 606:
					return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 635, 634, 633, 632, 624, 621, 611, 610:
					return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 551, 538, 537, 536, 535, 522, 515, 514:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 554, 547, 546, 545, 544, 572, 514, 515:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 554, 541, 540, 539, 538, 525, 518, 517:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 551, 538, 537, 536, 535, 522, 514, 515:
					return true;
			}
		}
	}
	
	return false;
}

static int CheckAnimation(int iClient, int iSequence)
{
	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	int health = GetClientHealth(iClient);
	float healthBuffer = GetClientHealthBuffer(iClient);
	
	bool isCalm = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_isCalm"));
	bool isLimping = view_as<bool>((health + healthBuffer) < g_fLimpHP);
	
	int buttons = GetClientButtons(iClient);
	
	// detect via netprops or m_nButtons instead of replacing sequences to fix crouching anims being delayed
	// AND reduce shitload of work individually checking for every single sequence
	bool isWalking = view_as<bool>(buttons & IN_SPEED) || GetEntProp(iClient, Prop_Send, "m_isGoingToDie") && health == 1 && healthBuffer == 0.0; 
	
	float vel[3]; GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vel);
	bool isMoving = view_as<bool>(vel[0] != 0.0 || vel[1] != 0.0 || vel[2] != 0.0);
	
	bool duckedVar = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_bDucked"));
	bool duckingVar = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_bDucking"));
	
	if (view_as<bool>(GetEntProp(iClient, Prop_Send, "m_fFlags") & FL_ONGROUND))	// is on ground
	{
		if ((duckedVar && !duckingVar) || (!duckedVar && duckingVar)) // this fix was entirely discovered by accident
		{
			if (isMoving)	// is moving while ducked
			{
				switch (sModel[29])
				{
					case 'b':		{return 190;}		//CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
					case 'd', 'w':	{return 202;}		//CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
					case 'c':		{return 162;}		//CrouchWalk_Sniper				ACT_RUN_CROUCH_SNIPER
					case 'h':		{return 187;}		//CrouchWalk_Sniper				ACT_RUN_CROUCH_SNIPER
					case 'v':		{return 164;}		//CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
					case 'n':		{return 176;}		//CrouchWalk_Elites				ACT_RUN_CROUCH_ELITES
					case 'e':		{return 158;}		//CrouchWalk_Pistol				ACT_RUN_CROUCH_PISTOL
					case 'a':		{return 170;}		//CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
				}
			}
			else	// is NOT moving while ducked
			{
				switch (sModel[29])
				{
					case 'b':		{return 46;}		//Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
					case 'd', 'w':	{return 56;}		//Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
					case 'c':		{return 52;}		//Idle_Crouching_SniperZoomed	ACT_CROUCHIDLE_SNIPER_ZOOMED
					case 'h':		{return 54;}		//Idle_Crouching_SniperZoomed	ACT_CROUCHIDLE_SNIPER_ZOOMED
					case 'v':		{return 43;}		//Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
					case 'n':		{return 69;}		//Idle_Crouching_SMG			ACT_CROUCHIDLE_SMG
					case 'e':		{return 52;}		//Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
					case 'a':		{return 49;}		//Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
				}
			}
		}
		else	// is NOT ducking
		{
			if (isMoving)	// is moving
			{
				if (isLimping)	// is limping
				{
					if (isWalking)	// is walking
					{
						switch (sModel[29])
						{
							case 'b':		{return 306;}	//LimpWalk_Sniper	ACT_WALK_INJURED_SNIPER
							case 'd', 'w':	{return 142;}	//Walk_Elites		ACT_WALK_ELITES
							case 'c':		{return 120;}	//Walk_Elites		ACT_WALK_ELITES
							case 'h':		{return 127;}	//Walk_Elites		ACT_WALK_ELITES
							case 'v':		{return 122;}	//Walk_Elites		ACT_WALK_ELITES
							case 'n':		{return 161;}	//Walk_SMG			ACT_WALK_SMG
							case 'e':		{return 128;}	//Walk_Pistol		ACT_WALK_PISTOL
							case 'a':		{return 125;}	//Walk_Pistol		ACT_WALK_PISTOL
						}
					}
					else	// is NOT walking
					{
						switch (sModel[29])
						{
							case 'b':		{return 319;}	//LimpRun_SMG		ACT_RUN_INJURED_SMG
							case 'd', 'w':	{return 331;}	//LimpRun_SMG		ACT_RUN_INJURED_SMG
							case 'c':		{return 313;}	//LimpRun_Sniper	ACT_RUN_INJURED_SNIPER
							case 'h':		{return 318;}	//LimpRun_Sniper	ACT_RUN_INJURED_SNIPER
							case 'v':		{return 651;}	//LimpRun_Sniper_Military	ACT_RUN_INJURED_SNIPER_MILITARY
							case 'n':		{return 203;}	//Run_Pistol		ACT_RUN_PISTOL
							case 'e':		{return 266;}	//LimpRun_Rifle		ACT_RUN_INJURED_RIFLE
							case 'a':		{return 264;}	//LimpRun_Rifle		ACT_RUN_INJURED_RIFLE
						}
					}
				}
				else	// is NOT limping
				{
					if (isWalking)	// is walking
					{
						switch (sModel[29])
						{
							case 'b':		{return 130;}	//Walk_Pistol		ACT_WALK_PISTOL
							case 'd', 'w':	{return 142;}	//Walk_Elites		ACT_WALK_ELITES
							case 'c':		{return 120;}	//Walk_Elites		ACT_WALK_ELITES
							case 'h':		{return 160;}	//Walk_Sniper		ACT_WALK_SNIPER
							case 'v':		{return 122;}	//Walk_Elites		ACT_WALK_ELITES
							case 'n':		{return 161;}	//Walk_SMG			ACT_WALK_SMG
							case 'e':		{return 128;}	//Walk_Pistol		ACT_WALK_PISTOL
							case 'a':		{return 128;}	//Walk_Elites		ACT_WALK_ELITES
						}
					}
					else	// is NOT walking
					{
						switch (sModel[29])
						{
							case 'b':		{return 214;}	//Run_Pistol		ACT_RUN_PISTOL
							case 'd', 'w':	{return 229;}	//Run_Elites		ACT_RUN_ELITES
							case 'c':		{return 233;}	//Run_PumpShotgun	ACT_RUN_PUMPSHOTGUN
							case 'h':		{return 208;}	//Run_Elites		ACT_RUN_ELITES
							case 'v':		{return 179;}	//Run_Pistol		ACT_RUN_PISTOL
							case 'n':		{return 203;}	//Run_Pistol		ACT_RUN_PISTOL
							case 'e':		{return 188;}	//Run_Pistol		ACT_RUN_PISTOL
							case 'a':		{return 185;}	//Run_Pistol		ACT_RUN_PISTOL
						}
					}
				}
			}
			else	// is NOT moving
			{
				if (isLimping)	// is limping
				{
					switch (sModel[29])
					{
						case 'b':		{return 124;}	//Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
						case 'd', 'w':	{return 132;}	//Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
						case 'c':		{return 110;}	//Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
						case 'h':		{return 107;}	//Idle_Injured_PumpShotgun	ACT_IDLE_INJURED_PUMPSHOTGUN
						case 'v':		{return 84;}	//Idle_Injured_Pistol		ACT_IDLE_INJURED_PISTOL
						case 'n':		{return 132;}	//Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
						case 'e':		{return 99;}	//Idle_Injured_Rifle		ACT_IDLE_INJURED_RIFLE
						case 'a':		{return 93;}	//Idle_Injured_Elites		ACT_IDLE_INJURED_ELITES
					}
				}
				else	// is NOT limping
				{
					switch (sModel[29])
					{
						case 'b':
						{
							switch (iSequence)
							{
								case	18,	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
										21:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 7;}	//Idle_Standing_Pistol			ACT_IDLE_PISTOL
										case false:	// not calm
											{return 30;}	//Idle_Standing_SMG				ACT_IDLE_SMG
									}
								}
							}
						}
						case 'd', 'w':
						{
							switch (iSequence)
							{
								case 23:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return 20;}	//Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
								case 20:	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 7;}	//Idle_Standing_Elites			ACT_IDLE_ELITES
										case false:	// not calm
											{return 32;}	//Idle_Standing_SMG				ACT_IDLE_SMG
									}
								}
							}
						}
						case 'c':
						{
							switch (isCalm)
							{
								case true:	// calm
									{return 16;}	//Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
								case false:	// not calm
									{return 24;}	//Idle_Standing_Sniper_MilitaryZoomed	ACT_IDLE_SNIPER_MILITARYZOOMED
							}
						}
						case 'h':
						{
							switch (iSequence)
							{
								case 39:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return 15;}	//Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
								case 15:	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 12;}	//Idle_Standing_Elites			ACT_IDLE_ELITES
										case false:	// not calm
											{return 30;}	//Idle_Standing_Sniper			ACT_IDLE_SNIPER
									}
								}
							}
						}
						case 'v':
						{
							switch (iSequence)
							{
								case 21:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return 18;}	//Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
								case 18:	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 12;}	//Idle_Standing_Elites			ACT_IDLE_ELITES
										case false:	// not calm
											{return 30;}	//Idle_Standing_SMG				ACT_IDLE_SMG
									}
								}
							}
						}
						case 'n':
						{
							switch (iSequence)
							{
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 9;}	//Idle_Standing_Pistol			ACT_IDLE_PISTOL
										case false:	// not calm
											{return 30;}	//Idle_Standing_SMG				ACT_IDLE_SMG
									}
								}
							}
						}
						case 'e':
						{
							switch (iSequence)
							{
								case 30:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return 27;}	//Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
								case 27:	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								default:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 22;}	//Idle_Standing_Elites			ACT_IDLE_ELITES
										case false:	// not calm
											{return 19;}	//Idle_Standing_Pistol			ACT_IDLE_PISTOL
									}
								}
							}
						}
						case 'a':
						{
							switch (iSequence)
							{
								case 27:	//	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
									{return 24;}	//Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
								case 24:	//	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
									{return iSequence;}			// Shotgun anims look nice, don't replace
								case false:
								{
									switch (isCalm)
									{
										case true:	// calm
											{return 19;}	//Idle_Standing_Elites			ACT_IDLE_ELITES
										case false:	// not calm
											{return 16;}	//Idle_Standing_Pistol			ACT_IDLE_PISTOL
									}
								}
							}
						}
					}
				}
			}
		}
	}
	else // is NOT on ground
	{
		switch (sModel[29])
		{
			case 'b':		{return 593;}	//Jump_SMG_01			ACT_JUMP_SMG
			case 'd', 'w':	{return 606;}	//Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
			case 'c':		{return 576;}	//Jump_Shotgun_01		ACT_JUMP_SHOTGUN
			case 'h':		{return 580;}	//Jump_Shotgun_01		ACT_JUMP_SHOTGUN
			case 'v':		{return 488;}	//Jump_Rifle_01			ACT_JUMP_RIFLE
			case 'n':		{return 494;}	//Jump_Shotgun_01		ACT_JUMP_SHOTGUN
			case 'e':		{return 509;}	//Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
			case 'a':		{return 506;}	//Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
		}
	}
	return iSequence;
}

void SetAttach(int iEntToAttach, int iEntToAttachTo)
{
	SetVariantString("!activator");
	AcceptEntityInput(iEntToAttach, "SetParent", iEntToAttachTo);
	
	SetEntityMoveType(iEntToAttach, MOVETYPE_NONE);
	
	SetEntProp(iEntToAttach, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_PARENT_ANIMATES);
	
	//thanks smlib for flag understanding
	int iFlags = GetEntProp(iEntToAttach, Prop_Data, "m_usSolidFlags", 2);
	iFlags = iFlags |= 0x0004;
	SetEntProp(iEntToAttach, Prop_Data, "m_usSolidFlags", iFlags, 2);
	
	TeleportEntity(iEntToAttach, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
}

// Taken and modified from l4d_stocks.inc
stock float GetClientHealthBuffer(int client)
{
    static ConVar painPillsDecayCvar = null;
    if (painPillsDecayCvar == null)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == null)
        {
            return 0.0;
        }
    }

    float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * painPillsDecayCvar.FloatValue);
    return tempHealth < 0.0 ? 0.0 : tempHealth;
}