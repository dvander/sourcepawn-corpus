////////////////////////
// Table of contents: //
/////// Commands ///////
//////// Events ////////
//////// Stocks ////////
////////////////////////

/*
*	CREDITS, for sto-erm... borrowed code
*	ReFlexPoison: For the idea from his autoreflect plugin, and for his "GetClosestClient" stock, and the heavy modification of the OnPlayerRunCmd he used.
*	friagram: Used and modified his "CanSeeTarget" stock to make sure it doesn't aim across the map, as it made it hard to know where I was going. And projectile interception code that works fairly well
*	javalia: Found some code from a homing projectiles plugin of his that made arrows aim for the head, modified this to make players aim for the head or not.
*	Mitchell: He helped alot and handed over some excellent code to improve the aim.
*	KitoRifty: Angle difference checking for FoV and a bit of aim smoothing code.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_NAME	 "Auto Aim"
#define PLUGIN_VERSION	"2.0"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Deathreus",
	description = "Long story short, it's an aimbot",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=238529"
}

new Handle:g_hCvarEnabled;
new bool:g_bCvarEnabled;
new Handle:g_hCvarReflect;
new bool:g_bCvarReflect;
new Handle:g_hCvarAimKey;
new g_iCvarAimKey;
new Handle:g_hCvarBackstab;
new bool:g_bCvarBackstab;
new Handle:g_hCvarSmoothAmount;
new Float:g_flCvarSmoothAmount;
new Handle:g_hGravity;
new Float:g_flGravity;

new bool:g_bAutoAiming[MAXPLAYERS+1], bool:g_bAimAndShoot[MAXPLAYERS+1], bool:g_bAimFoV[MAXPLAYERS+1],
	bool:g_bAimMode[MAXPLAYERS+1], bool:g_bSmoothAim[MAXPLAYERS+1], bool:g_bSilentAim[MAXPLAYERS+1] = {false, ...};
new Handle:g_hLookupBone, Handle:g_hGetBonePosition;
new bool:g_bToHead[MAXPLAYERS+1];
new ClientEyes[MAXPLAYERS+1];
new ActiveWeapon[MAXPLAYERS+1];
new Float:FOISpeed[MAXPLAYERS+1] = 100000.0;
new g_iPlayerDesiredFOV[MAXPLAYERS+1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:disGaem[32];
	GetGameFolderName(disGaem, sizeof(disGaem));
	if(!StrEqual(disGaem, "tf"))
	{
		Format(error, err_max, "This plugin only works for Trade Fashion 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_autoaim_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_autoaim_enabled", "1", "Enable Aimbot?(As if you'd want if off)\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarAimKey = CreateConVar("sm_autoaim_aimkey", "2", "What key needs to be pressed to enable the bot?\n\n 1 = Secondary Attack\n2 = Special Attack\n3 = Reload\n4 = Primary Attack", FCVAR_NONE, true, 1.0, true, 4.0);
	g_iCvarAimKey = GetConVarInt(g_hCvarAimKey);
	HookConVarChange(g_hCvarAimKey, OnConVarChange);
	
	g_hCvarReflect = CreateConVar("sm_autoaim_reflect", "1", "Reflect the nearest projectile?\n\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarReflect = GetConVarBool(g_hCvarReflect);
	HookConVarChange(g_hCvarReflect, OnConVarChange);
	
	g_hCvarBackstab = CreateConVar("sm_autoaim_backstab", "1", "Automatically backstab if available?\n\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarBackstab = GetConVarBool(g_hCvarBackstab);
	HookConVarChange(g_hCvarBackstab, OnConVarChange);
	
	g_hCvarSmoothAmount = CreateConVar("sm_autoaim_smoothamount", "8.0", "Amount of smoothing to apply\nThe higher this is the faster it is but may overshoot.", FCVAR_NONE, true, 1.0, true, 20.0);
	g_flCvarSmoothAmount = GetConVarFloat(g_hCvarSmoothAmount);
	HookConVarChange(g_hCvarSmoothAmount, OnConVarChange);
	
	g_hGravity = FindConVar("sv_gravity");
	g_flGravity = GetConVarFloat(g_hGravity);
	HookConVarChange(g_hGravity, OnConVarChange);

	RegAdminCmd("sm_autoaim", AutoAimCmd, ADMFLAG_GENERIC, "Turns on aimbot");
	RegAdminCmd("sm_aim", AutoAimCmd, ADMFLAG_GENERIC, "Turns on aimbot");		// Convenience purposes only
	
	RegAdminCmd("sm_aimmode", AimKeyCmd, ADMFLAG_GENERIC, "Toggle aim key");
	RegAdminCmd("sm_aiminfov", AimInFOVCmd, ADMFLAG_GENERIC, "Toggle FoV aiming");
	RegAdminCmd("sm_aimandshoot", AutoFireCmd, ADMFLAG_GENERIC, "Toggle auto fire");
	RegAdminCmd("sm_aimsmooth", SmoothAimCmd, ADMFLAG_GENERIC, "Toggle smoothing");
	RegAdminCmd("sm_aimsilent", SilentAimCmd, ADMFLAG_GENERIC, "Toggle silent aim");

	for(new iClient = 1; iClient <= MaxClients; iClient++) if(IsValidClient(iClient))
		OnClientPutInServer(iClient);
	
	new Handle:hGameConf = LoadGameConfigFile("aimbot.games");
	if (hGameConf == INVALID_HANDLE) SetFailState("Could not locate gamedata file aimbot.games.txt, pausing plugin");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::LookupBone");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if(!(g_hLookupBone=EndPrepSDKCall())) SetFailState("Could not initialize SDK call CBaseAnimating::LookupBone");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::GetBonePosition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if(!(g_hGetBonePosition=EndPrepSDKCall())) SetFailState("Could not initialize SDK call CBaseAnimating::GetBonePosition");
	
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("post_inventory_application", Event_Inventory);
	
	AutoExecConfig(true);
}

public OnPluginEnd()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	{
		SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
		SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	}
}


/////////////////////////////////////
// Commands start below this point //
/////////////////////////////////////

public Action:AutoAimCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bAutoAiming[iClient])
		{
			PrintToChat(iClient, "[SM] Auto aiming enabled.");
			SDKHook(iClient, SDKHook_PreThink, OnPreThink);
			SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			g_bAutoAiming[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Auto aiming disabled.");
			SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
			SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			g_bAutoAiming[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Auto aiming disabled.");
				SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
				SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
				g_bAutoAiming[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Auto aiming enabled.");
				SDKHook(iClient, SDKHook_PreThink, OnPreThink);
				SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
				g_bAutoAiming[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

public Action:AimKeyCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bAimMode[iClient])
		{
			PrintToChat(iClient, "[SM] Aim key enabled.");
			g_bAimMode[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Aim key disabled.");
			g_bAimMode[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Aim key disabled.");
				g_bAimMode[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Aim key enabled.");
				g_bAimMode[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

public Action:AimInFOVCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bAimFoV[iClient])
		{
			PrintToChat(iClient, "[SM] Aim within FoV enabled.");
			g_bAimFoV[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Aim within FoV disabled.");
			g_bAimFoV[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Aim within FoV disabled.");
				g_bAimFoV[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Aim within FoV enabled.");
				g_bAimMode[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

public Action:AutoFireCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bAimAndShoot[iClient])
		{
			PrintToChat(iClient, "[SM] Auto fire enabled.");
			g_bAimAndShoot[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Auto fire disabled.");
			g_bAimAndShoot[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Auto fire disabled.");
				g_bAimAndShoot[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Auto fire enabled.");
				g_bAimAndShoot[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

public Action:SmoothAimCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bSmoothAim[iClient])
		{
			PrintToChat(iClient, "[SM] Aim smoothing enabled.");
			g_bSmoothAim[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Aim smoothing disabled.");
			g_bSmoothAim[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Aim smoothing disabled.");
				g_bSmoothAim[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Aim smoothing enabled.");
				g_bSmoothAim[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

public Action:SilentAimCmd(iClient, nArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(nArgs > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
		return Plugin_Handled;
	}

	if(nArgs == 0)
	{
		if(!g_bSilentAim[iClient])
		{
			PrintToChat(iClient, "[SM] Silent aim enabled.");
			g_bSilentAim[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Silent aim disabled.");
			g_bSilentAim[iClient] = false;
		}
		return Plugin_Handled;
	}
	else
	{
		decl String:arg1[2];
		GetCmdArg(1, arg1, sizeof(arg1));

		new value = StringToInt(arg1);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoaim [0/1]");
			return Plugin_Handled;
		}

		switch(value)
		{
			case 0:
			{
				PrintToChat(iClient, "[SM] Silent aim disabled.");
				g_bSilentAim[iClient] = false;
			}
			case 1:
			{
				PrintToChat(iClient, "[SM] Silent aim enabled.");
				g_bSilentAim[iClient] = true;
			}
		}
	}

	return Plugin_Handled;
}

/////////////////////////////////////
//	Events start below this point  //
/////////////////////////////////////

public OnConVarChange(Handle:hConvar, const String:oldValue[], const String:newValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_bCvarEnabled = bool:StringToInt(newValue);

	if(hConvar == g_hCvarAimKey)
		g_iCvarAimKey = StringToInt(newValue);

	if(hConvar == g_hCvarReflect)
		g_bCvarReflect = bool:StringToInt(newValue);
	
	if(hConvar == g_hCvarBackstab)
		g_bCvarBackstab = bool:StringToInt(newValue);
	
	if(hConvar == g_hCvarSmoothAmount)
		g_flCvarSmoothAmount = StringToFloat(newValue);
	
	if(hConvar == g_hGravity)
		g_flGravity = StringToFloat(newValue);
}

public OnClientPutInServer(iClient)
{
	g_iPlayerDesiredFOV[iClient] = 90;
	
	if (!IsFakeClient(iClient))
		QueryClientConVar(iClient, "fov_desired", OnClientGetDesiredFOV);
}

public OnClientDisconnect(iClient)
{
	g_bAutoAiming[iClient] = g_bAimAndShoot[iClient] = g_bAimFoV[iClient] =
	g_bAimMode[iClient] = g_bSmoothAim[iClient] = g_bSilentAim[iClient] = false;
	
	SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
	SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public OnClientGetDesiredFOV(QueryCookie:cookie, iClient, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsValidClient(iClient)) return;
	
	g_iPlayerDesiredFOV[iClient] = StringToInt(cvarValue);
}

public Action:Event_Spawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsPlayerAlive(iClient))
	{
		new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(iCurrentWeapon == -1)
			return Plugin_Continue;
		
		ActiveWeapon[iClient] = GetEntProp(iCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex");
		UpdateFirstOrderIntercept(iClient);
	}
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsPlayerAlive(iClient))
	{
		new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(iCurrentWeapon == -1)
			return Plugin_Continue;
		
		ActiveWeapon[iClient] = GetEntProp(iCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex");
		UpdateFirstOrderIntercept(iClient);
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:vVelocity[3], Float:vAngle[3], &iWeapon)
{
	if(!g_bCvarEnabled || !g_bAutoAiming[iClient])
		return Plugin_Continue;
	if(!IsPlayerAlive(iClient) || !IsValidClient(iClient))
		return Plugin_Continue;

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	decl String:sWeapon[64];
	GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));

	// Check for, and disable aiming for sapper's, medigun's, and wrench's
	if(StrEqual(sWeapon, "tf_weapon_sapper", false) || StrEqual(sWeapon, "tf_weapon_builder", false) || StrEqual(sWeapon, "tf_weapon_medigun", false) || StrEqual(sWeapon, "tf_weapon_wrench", false))
		return Plugin_Continue;

	g_bToHead[iClient] = ShouldAimToHead(iClass, sWeapon, ActiveWeapon[iClient]);
	
	if(g_bCvarBackstab && TF2_GetPlayerClass(iClient) == TFClass_Spy)
		if(GetEntProp(GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
			iButtons |= IN_ATTACK;
	
	if(g_bCvarReflect && TF2_GetPlayerClass(iClient) == TFClass_Pyro)
	{
		decl Float:vEntityOrigin[3], Float:vClientEyes[3], Float:vCamAngle[3];
		if(GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary))
		{
			new iEntity = -1;
			while((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != -1 && GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1) != GetClientTeam(iClient) && CanBeDeflected(iEntity))
			{
				GetClientEyePosition(iClient, vClientEyes);
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vEntityOrigin);

				GetVectorAnglesTwoPoints(vClientEyes, vEntityOrigin, vCamAngle);
				AnglesNormalize(vCamAngle);
				
				if(GetVectorDistance(vClientEyes, vEntityOrigin) < 165.0)
				{
					TeleportEntity(iClient, NULL_VECTOR, vCamAngle, NULL_VECTOR);
					CopyVector(vCamAngle, vAngle);
					iButtons |= IN_ATTACK2;
				}
			}
		}
	}

	if(g_bAimMode[iClient])
	{
		new mButton;

		switch(g_iCvarAimKey)
		{
			case 1: mButton = IN_ATTACK2; // Secondary Attack
			case 2: mButton = IN_ATTACK3; // Special Attack
			case 3: mButton = IN_RELOAD;
			case 4: mButton = IN_ATTACK;
		}

		if(iButtons & mButton)
		{
			AimTick(iClient, iButtons, vAngle, vVelocity);
		}
	}
	else
	{
		AimTick(iClient, iButtons, vAngle, vVelocity);
	}

	return Plugin_Changed;
}

public OnPreThink(iClient)
{	// Predict speed changes based on charge
	if(ActiveWeapon[iClient] == 56 || ActiveWeapon[iClient] == 1005 || ActiveWeapon[iClient] == 1092)
	{
		new Float:flCharge = GetEntPropFloat(GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"), Prop_Data, "m_fFireDuration");
		FOISpeed[iClient] = 1800.0 + MAX(flCharge, 1.0) * 8.0;
	}
}

public OnWeaponSwitch(iClient, iWeapon)
{
	if(!IsValidEdict(iWeapon))
		return;
	
	ActiveWeapon[iClient] = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	UpdateFirstOrderIntercept(iClient);
}


/////////////////////////////////////
//	Stocks start below this point  //
/////////////////////////////////////

public AimTick(iClient, &iButtons, Float:vAngle[3], Float:vVelocity[3])
{
	static Float:flNextTargetTime[MAXPLAYERS+1];
	static iTarget[MAXPLAYERS+1];
	static iBone[MAXPLAYERS+1];
	
	decl Float:vClientEyes[3], Float:vCamAngle[3], 
	Float:vTargetEyes[3], Float:vTargetVel[3];
	
	GetClientEyePosition(iClient, vClientEyes);
	
	new iTeam = GetClientTeam(iClient);
	
	// Thanks Mitchell for this awesome code
	if(flNextTargetTime[iClient] <= GetEngineTime())
	{
		iTarget[iClient] = GetClosestClient(iClient);
		flNextTargetTime[iClient] = GetEngineTime() + 5.0;
	}
	if(!IsValidClient(iTarget[iClient]) || !IsPlayerAlive(iTarget[iClient]))
	{
		iTarget[iClient] = GetClosestClient(iClient);
		flNextTargetTime[iClient] = GetEngineTime() + 5.0;
		return;
	}
	else
	{
		GetClientEyePosition(iTarget[iClient], vTargetEyes);
		if(!CanSeeTarget(iClient, iTarget[iClient],	iTeam, g_bAimFoV[iClient]))
		{
			iTarget[iClient] = GetClosestClient(iClient);
			flNextTargetTime[iClient] = GetEngineTime() + 5.0;
			return;
		}
	}

	//GetClientEyePosition(iTarget[iClient], vTargetEyes);
	//vTargetEyes[0] += 1.5;
	GetEntPropVector(iTarget[iClient], Prop_Data, "m_vecAbsVelocity", vTargetVel);

	decl Float:vBoneAngle[3];
	iBone[iTarget[iClient]] = SDKCall(g_hLookupBone, iTarget[iClient], (g_bToHead[iClient]) ? "bip_head" : "bip_pelvis");
	SDKCall(g_hGetBonePosition, iTarget[iClient], iBone[iTarget[iClient]], vTargetEyes, vBoneAngle);
	
	FirstOrderIntercept(vClientEyes, Float:{0.0, 0.0, 0.0}, FOISpeed[iClient], vTargetEyes, vTargetVel, iTarget[iClient]);
	InterpolateVector(iClient, vTargetVel, vTargetEyes);
	
	switch(ActiveWeapon[iClient])
	{	// Calculate the dropoff
		case 39, 56, 351, 595, 740, 1005, 1081, 1092, 19, 206, 308, 
		996, 1007, 1151, 15077, 15079, 15091, 15092, 15116, 15117, 15142, 15158:
		{
			if(GetVectorDistance(vClientEyes, vTargetEyes) > 512.0)
				vTargetEyes[2] += GetGrenadeZ(vClientEyes, vTargetEyes, FOISpeed[iClient]);
		}
	}
	
	GetVectorAnglesTwoPoints(vClientEyes, vTargetEyes, vCamAngle);
	AnglesNormalize(vCamAngle);
	
	if(g_bSmoothAim[iClient])
	{
		vCamAngle[0] = ChangeAngle(iClient, vCamAngle[0], vAngle[0]);
		vCamAngle[1] = ChangeAngle(iClient, vCamAngle[1], vAngle[1]);
		AnglesNormalize(vCamAngle);
	}
	
	if(!g_bSilentAim[iClient])
	{
		TeleportEntity(iClient, NULL_VECTOR, vCamAngle, NULL_VECTOR);
		CopyVector(vCamAngle, vAngle);
	}
	else
	{
		decl Float:vMoveAng[3];
		GetVectorAngles(vVelocity, vMoveAng);
		
		new Float:flYaw = DegToRad(vCamAngle[1] - vAngle[1] + vMoveAng[1]);
		new Float:flSpeed = SquareRoot((vVelocity[0] * vVelocity[0]) + (vVelocity[1] * vVelocity[1]));
		vVelocity[0] = Cosine(flYaw) * flSpeed;
		vVelocity[1] = Sine(flYaw) * flSpeed;
		
		CopyVector(vCamAngle, vAngle);
	}
	
	if(g_bAimAndShoot[iClient] && IsLooking(iClient, iTarget[iClient])) // If the player is looking at the target
		iButtons |= IN_ATTACK;
}

stock GetClosestClient(iClient)
{
	decl Float:vPos1[3], Float:vPos2[3];
	GetClientEyePosition(iClient, vPos1);

	new iTeam = GetClientTeam(iClient);
	new iClosestEntity = -1;
	new Float:flClosestDistance = -1.0;
	new Float:flEntityDistance;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != iTeam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientEyePosition(i, vPos2);
			flEntityDistance = GetVectorDistance(vPos1, vPos2);
			if((flEntityDistance < flClosestDistance) || flClosestDistance == -1.0)
			{
				if(CanSeeTarget(iClient, i, iTeam, g_bAimFoV[iClient]))
				{
					flClosestDistance = flEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	return iClosestEntity;
}

stock bool:IsValidClient(iClient, bool:bAlive = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;

	return true;
}

public CopyVector(float vIn[3], float vOut[3])
{
	vOut[0] = vIn[0];
	vOut[1] = vIn[1];
	vOut[2] = vIn[2];
}

bool CanSeeTarget(iClient, iTarget, iTeam, bool:bCheckFOV)
{
	decl Float:flStart[3], Float:flEnd[3];
	GetClientEyePosition(iClient, flStart);
	GetClientEyePosition(iTarget, flEnd);
	
	TR_TraceRayFilter(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_GetEntityIndex() == iTarget)
	{
		if(TF2_GetPlayerClass(iTarget) == TFClass_Spy)
		{
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked) || TF2_IsPlayerInCondition(iTarget, TFCond_Disguised))
			{
				if(TF2_IsPlayerInCondition(iTarget, TFCond_CloakFlicker)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_OnFire)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Jarated)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Milked)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Bleeding))
				{
					return true;
				}

				return false;
			}
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && GetEntProp(iTarget, Prop_Send, "m_nDisguiseTeam") == iTeam)
			{
				return false;
			}

			return true;
		}
		
		if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_PreventDeath)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_Bonked))
		{
			return false;
		}
		
		if(bCheckFOV)
		{
			decl Float:eyeAng[3], Float:reqVisibleAng[3];
			new Float:flFOV = float(g_iPlayerDesiredFOV[iClient]);
			
			GetClientEyeAngles(iClient, eyeAng);
			
			SubtractVectors(flEnd, flStart, reqVisibleAng);
			GetVectorAngles(reqVisibleAng, reqVisibleAng);
			
			new Float:flDiff = FloatAbs(reqVisibleAng[0] - eyeAng[0]) + FloatAbs(reqVisibleAng[1] - eyeAng[1]);
			if (flDiff > ((flFOV * 0.5) + 10.0)) 
				return false;
		}

		return true;
	}

	return false;
}

bool:IsLooking(iClient, iTarget)
{
	if(GetClientAimTarget(iClient, true) == iTarget)
		return true;
	
	return false;
}

public bool:TraceRayFilterClients(iEntity, iMask, any:hData)
{
	if(iEntity > 0 && iEntity <=MaxClients)
	{
		if(iEntity == hData)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

bool:ShouldAimToHead(TFClassType:iClass, const String:strWeapon[], iWeapon)
{
	// These checks are probably mostly redundant, but just want to be sure I make certain classes aim at certain points of the body to be effective
		
	if(StrEqual(strWeapon, "tf_weapon_crossbow", false)
	|| StrEqual(strWeapon, "tf_weapon_syringegun_medic", false)
	|| StrEqual(strWeapon, "tf_weapon_flaregun", false))
		return true;
	
	switch(iWeapon)			// Any revolver other than Ambassador
	{
		case 24,161,210,224,460,535,1142,15011,15027,15042,15051:
			return false;
	}
	
	if (iClass == TFClass_Sniper || (iClass == TFClass_Spy && !StrEqual(strWeapon, "tf_weapon_knife", false)))
		return true;
		
	return false;
}

bool:CanBeDeflected(iEntity)
{
	if(IsValidEntity(iEntity))
	{
		new String:sBuffer[32];
		GetEntityClassname(iEntity, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "tf_projectile_arrow", false) 
		|| StrEqual(sBuffer, "tf_projectile_ornament", false) 
		|| StrEqual(sBuffer, "tf_projectile_cleaver", false) 
		|| StrEqual(sBuffer, "tf_projectile_energy_ball", false)
		|| StrEqual(sBuffer, "tf_projectile_flare", false)
		|| StrEqual(sBuffer, "tf_projectile_jar", false)
		|| StrEqual(sBuffer, "tf_projectile_jar_milk", false)
		|| StrEqual(sBuffer, "tf_projectile_pipe", false)
		|| StrEqual(sBuffer, "tf_projectile_pipe_remote", false)
		|| StrEqual(sBuffer, "tf_projectile_rocket", false)
		|| StrEqual(sBuffer, "tf_projectile_sentryrocket", false)
		|| StrEqual(sBuffer, "tf_projectile_stun_ball", false))
			return true;
	}
	return false;
}

UpdateFirstOrderIntercept(iClient)
{
	switch(ActiveWeapon[iClient])
	{
		case 812,833,44,648,595: FOISpeed[iClient] = 3000.0;
		case 49,351,740,1081: FOISpeed[iClient] = 2000.0;
		case 442,588: FOISpeed[iClient] = 1200.0;
		case 997,305,1079: FOISpeed[iClient] = 2400.0;
		case 414: FOISpeed[iClient] = 1540.0;
		case 127: FOISpeed[iClient] = 1980.0;
		case 222,1121,58,1083,1105: FOISpeed[iClient] = 925.0;
		case 996: FOISpeed[iClient] = 1811.0;
		case 56,1005,1092: FOISpeed[iClient] = 1800.0;
		case 308: FOISpeed[iClient] = 1510.0;
		case 19,206,1007,1151: FOISpeed[iClient] = 1215.0;
		case 18,205,228,441,513,658,730,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057: FOISpeed[iClient] = 1100.0;
		case 17,204,36,412,20,207,130,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15045,15048: FOISpeed[iClient] = 1000.0;
		default: FOISpeed[iClient] = 1000000.0;		// Arbitrary value for hitscan
	}
}

// sarysa plz
stock Float:GetVectorAnglesTwoPoints(const Float:vStartPos[3], const Float:vEndPos[3], Float:vAngles[3])
{
	static Float:tmpVec[3];
	tmpVec[0] = vEndPos[0] - vStartPos[0];
	tmpVec[1] = vEndPos[1] - vStartPos[1];
	tmpVec[2] = vEndPos[2] - vStartPos[2];
	GetVectorAngles(tmpVec, vAngles);
}

public AnglesNormalize(Float:vAngles[3])
{
	while(vAngles[0] >  89.0) vAngles[0]-=360.0;
	while(vAngles[0] < -89.0) vAngles[0]+=360.0;
	while(vAngles[1] > 180.0) vAngles[1]-=360.0;
	while(vAngles[1] <-180.0) vAngles[1]+=360.0;
}

public AngleNormalize(&Float:flAngle)
{
	if(flAngle > 180.0) flAngle-=360.0;
	if(flAngle <-180.0) flAngle+=360.0;
}

stock Float:ChangeAngle(iClient, Float:flIdeal, Float:flCurrent)
{
	static Float:flAimMoment[MAXPLAYERS+1], Float:flAlphaSpeed, Float:flAlpha;
	new Float:flDiff, Float:flDelta;
	
	flAlphaSpeed = g_flCvarSmoothAmount / 20.0;
	flAlpha = flAlphaSpeed * 0.21;
	
	flDiff = flIdeal - flCurrent;
	AngleNormalize(flDiff);
	
	flDelta = (flDiff * flAlpha) + (flAimMoment[iClient] * flAlphaSpeed);
	if(flDelta < 0.0)
		flDelta *= -1.0;
	
	flAimMoment[iClient] = (flAimMoment[iClient] * flAlphaSpeed) + (flDelta * (1.0 - flAlphaSpeed));
	if(flAimMoment[iClient] < 0.0)
		flAimMoment[iClient] *= -1.0;
	
	return flCurrent + flDelta;
}

InterpolateVector(iClient, Float:vVelocity[3], Float:vVector[3])
{
	if(IsFakeClient(iClient))
		return;
	
	new Float:flLatency = GetClientLatency(iClient, NetFlow_Both);
	for(new x = 0; x < 3; x++)
		vVector[x] -= (vVelocity[x] * flLatency);
}

// Props to Friagram
//first-order intercept using absolute target position (http://wiki.unity3d.com/index.php/Calculating_Lead_For_Projectiles)
FirstOrderIntercept(Float:shooterPosition[3], Float:shooterVelocity[3], Float:shotSpeed, Float:targetPosition[3], Float:targetVelocity[3], iTarget)
{
	new Float:originalPosition[3];
	CopyVector(targetPosition, originalPosition);
	
	decl Float:targetRelativePosition[3];
	SubtractVectors(targetPosition, shooterPosition, targetRelativePosition);
	decl Float:targetRelativeVelocity[3];
	SubtractVectors(targetVelocity, shooterVelocity, targetRelativeVelocity);
	new Float:t = FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity);

	ScaleVector(targetRelativeVelocity, t);
	AddVectors(targetPosition, targetRelativeVelocity, targetPosition);
	
	// Check if we are going to shoot a wall or the floor
	TR_TraceRayFilter(shooterPosition, targetPosition, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_DidHit())
	{
		new Float:vEndPos[3];
		new Float:fDist1 = GetVectorDistance(shooterPosition, vEndPos);
		new Float:fDist2 = GetVectorDistance(shooterPosition, targetPosition);
		if(fDist1 < fDist2 || TR_GetFraction() != 1.0)
			CopyVector(originalPosition, targetPosition);
	}
}

//first-order intercept using relative target position
Float:FirstOrderInterceptTime(Float:shotSpeed, Float:targetRelativePosition[3], Float:targetRelativeVelocity[3])
{
	new Float:velocitySquared = GetVectorLength(targetRelativeVelocity, true);
	if(velocitySquared < 0.001)
	{
		return 0.0;
	}

	new Float:a = velocitySquared - shotSpeed*shotSpeed;
	if (FloatAbs(a) < 0.001)  //handle similar velocities
	{
		new Float:t = -GetVectorLength(targetRelativePosition, true)/(2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition));

		return t > 0.0 ? t : 0.0; //don't shoot back in time
	}

	new Float:b = 2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition);
	new Float:c = GetVectorLength(targetRelativePosition, true);
	new Float:determinant = b*b - 4.0*a*c;

	if (determinant > 0.0)	//determinant > 0; two intercept paths (most common)
	{ 
		new Float:t1 = (-b + SquareRoot(determinant))/(2.0*a);
		new Float:t2 = (-b - SquareRoot(determinant))/(2.0*a);
		if (t1 > 0.0)
		{
			if (t2 > 0.0) 
			{
				return t2 < t2 ? t1 : t2; //both are positive
			}
			else
			{
				return t1; //only t1 is positive
			}
		}
		else
		{
			return t2 > 0.0 ? t2 : 0.0; //don't shoot back in time
		}
	}
	else if (determinant < 0.0) //determinant < 0; no intercept path
	{
		return 0.0;
	}
	else //determinant = 0; one intercept path, pretty much never happen
	{
		determinant = -b/(2.0*a);		// temp
		return determinant > 0.0 ? determinant : 0.0; //don't shoot back in time
	}
}

stock Float:GetGrenadeZ(const Float:vOrigin[3], const Float:vTarget[3], Float:flSpeed)
{
	new Float:flDist = GetVectorDistance(vOrigin, vTarget);
	new Float:flTime = flDist / (flSpeed * 0.707);
	
	return MIN(0.0, ((Pow(2.0, flTime) - 1.0) * (g_flGravity * 0.1)));
}

stock Float:MAX(Float:a, Float:b) {
	return (a < b) ? a : b;
}

stock Float:MIN(Float:a, Float:b) {
	return (a > b) ? a : b;
}
