#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>

#define PLUGIN_VERSION "1.4"

new Handle:cvarEnable, Handle:cvarDamageAmount, Handle:cvarTeam, Handle:cvarBoss, Handle:cvarClass, Handle:cvarMaxClimbs, Handle:cvarCooldown, Handle:cvarNextClimb;
new Handle:cClimbScout, Handle:cClimbSoldier, Handle:cClimbPyro, Handle:cClimbDemo, Handle:cClimbHeavy, Handle:cClimbEngie, Handle:cClimbMedic, Handle:cClimbSniper, Handle:cClimbSpy;
new maxClimbs[MAXPLAYERS+1] = {0, ...};
new bool:gClimb[MAXPLAYERS+1][9];
new bool:isClientBoss[MAXPLAYERS+1] = {false, ...};
new bool:justClimbed[MAXPLAYERS+1] = {false, ...};
new bool:blockClimb[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = {
	name		= "Player Climb",
	author		= "Nanochip",
	description = "Climb walls with melee attack.",
	version		= PLUGIN_VERSION,
	url			= "http://thecubeserver.org/"
};

public OnPluginStart()
{
	CreateConVar("sm_playerclimb_version", PLUGIN_VERSION, "Player Climb Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_playerclimb_enable", "1", "Enable the plugin? 1 = Yes, 0 = No.", _, true, 0.0, true, 1.0);
	cvarDamageAmount = CreateConVar("sm_playerclimb_damageamount", "15.0", "How much damage should a player take on each melee climb?");
	cvarTeam = CreateConVar("sm_playerclimb_team", "0", "Restrict climbing to X team only. 0 = No restriction, 1 = BLU, 2 = RED.", _, true, 0.0, true, 2.0);
	cvarBoss = CreateConVar("sm_playerclimb_boss", "0", "Should bosses (VSH/FF2) be allowed to climb? 0 = No, 1 = Yes.", _, true, 0.0, true, 1.0);
	cvarClass = CreateConVar("sm_playerclimb_class", "sniper", "Which classes should be allowed to climb? You can add multiple classes by separating them with a comma (EX: scout,sniper,spy,heavy,soldier,demo,medic,pyro,engineer). For all classes, just put \"all\" (no quotes).");
	cvarMaxClimbs = CreateConVar("sm_playerclimb_maxclimbs", "0", "The maximum amount of times the player can melee the wall (climb) while being in the air before they have to touch the ground again. 0 = Disabled, 1 = 1 Climb... 23 = 23 Climbs.");
	cvarCooldown = CreateConVar("sm_playerclimb_cooldown", "0.0", "Time in seconds before the player may climb the wall again, this cooldown starts when the player touches the ground after climbing.");
	cvarNextClimb = CreateConVar("sm_playerclimb_nextclimb", "1.56", "Time in seconds in between melee climbs", _, true, 0.1);
	
	cClimbScout =	RegClientCookie("sm_playerclimb_cookie_scout", "", CookieAccess_Private);
	cClimbSoldier =	RegClientCookie("sm_playerclimb_cookie_soldier", "", CookieAccess_Private);
	cClimbPyro =	RegClientCookie("sm_playerclimb_cookie_pyro", "", CookieAccess_Private);
	cClimbDemo =	RegClientCookie("sm_playerclimb_cookie_demo", "", CookieAccess_Private);
	cClimbHeavy =	RegClientCookie("sm_playerclimb_cookie_heavy", "", CookieAccess_Private);
	cClimbEngie =	RegClientCookie("sm_playerclimb_cookie_engie", "", CookieAccess_Private);
	cClimbMedic =	RegClientCookie("sm_playerclimb_cookie_medic", "", CookieAccess_Private);
	cClimbSniper =	RegClientCookie("sm_playerclimb_cookie_sniper", "", CookieAccess_Private);
	cClimbSpy =		RegClientCookie("sm_playerclimb_cookie_spy", "", CookieAccess_Private);
	
	AutoExecConfig(true, "PlayerClimb");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new col = 0; col < 9; col++)
		{
			gClimb[i][col] = true;
		}
		if(IsClientInGame(i) && AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
	
	RegConsoleCmd("sm_playerclimb", Cmd_PlayerClimb, "Set your Player Climb preferences.");
	
	SetCookieMenuItem(PlayerClimbHandler, 0, "Player Climb Toggle");
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_RoundEnd);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientHealth(i) >= 600) isClientBoss[i] = true;
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		isClientBoss[i] = false;
	}
}

public OnClientDisconnect(client)
{
	isClientBoss[client] = false;
	justClimbed[client] = false;
	blockClimb[client] = false;
	maxClimbs[client] = 0;
}

public Action:Cmd_PlayerClimb(client, args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	CreatePlayerClimbMenu(client);
	return Plugin_Handled;
}

public PlayerClimbHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		CreatePlayerClimbMenu(client);
	}
}

CreatePlayerClimbMenu(client)
{
	new Handle:menu = CreateMenu(CreatePlayerClimbMenuCallback);
	SetMenuTitle(menu, "Player Climb Class Preferences: [x] Enabled - [ ] Disabled");
	
	new String:cvClass[255];
	GetConVarString(cvarClass, cvClass, sizeof(cvClass));
	
	new bool:allClasses;
	if (StrContains(cvClass, "all", false) != -1) allClasses = true;
	else allClasses = false;
	
	if ((StrContains(cvClass, "scout", false) != -1) || allClasses)
	{
		if (gClimb[client][0])
			AddMenuItem(menu, "scout_false", "[x] Scout");
		else
			AddMenuItem(menu, "scout_true", "[ ] Scout");
	}
	if ((StrContains(cvClass, "soldier", false) != -1) || allClasses)
	{
		if (gClimb[client][1])
			AddMenuItem(menu, "soldier_false", "[x] Soldier");
		else
			AddMenuItem(menu, "soldier_true", "[ ] Soldier");
	}
	if ((StrContains(cvClass, "pyro", false) != -1) || allClasses)
	{
		if (gClimb[client][2])
			AddMenuItem(menu, "pyro_false", "[x] Pryo");
		else
			AddMenuItem(menu, "pyro_true", "[ ] Pryo");
	}
	if ((StrContains(cvClass, "demo", false) != -1) || allClasses)
	{
		if (gClimb[client][3])
			AddMenuItem(menu, "demoman_false", "[x] Demo Man");
		else
			AddMenuItem(menu, "demoman_true", "[ ] Demo Man");
	}
	if ((StrContains(cvClass, "heavy", false) != -1) || allClasses)
	{
		if (gClimb[client][4])
			AddMenuItem(menu, "heavy_false", "[x] Heavy");
		else
			AddMenuItem(menu, "heavy_true", "[ ] Heavy");
	}
	if ((StrContains(cvClass, "engineer", false) != -1) || allClasses)
	{
		if (gClimb[client][5])
			AddMenuItem(menu, "engineer_false", "[x] Engineer");
		else
			AddMenuItem(menu, "engineer_true", "[ ] Engineer");
	}
	if ((StrContains(cvClass, "medic", false) != -1) || allClasses)
	{
		if (gClimb[client][6])
			AddMenuItem(menu, "medic_false", "[x] Medic");
		else
			AddMenuItem(menu, "medic_true", "[ ] Medic");
	}
	if ((StrContains(cvClass, "sniper", false) != -1) || allClasses)
	{
		if (gClimb[client][7])
			AddMenuItem(menu, "sniper_false", "[x] Sniper");
		else
			AddMenuItem(menu, "sniper_true", "[ ] Sniper");
	}
	if ((StrContains(cvClass, "spy", false) != -1) || allClasses)
	{
		if (gClimb[client][8])
			AddMenuItem(menu, "spy_false", "[x] Spy");
		else
			AddMenuItem(menu, "spy_true", "[ ] Spy");
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	// debug
	// for (new col = 0; col < 9; col++)
	// {
		// new String:derp[32];
		// if (gClimb[client][col])
			// Format(derp, sizeof(derp), "%i. true", col);
		// else
			// Format(derp, sizeof(derp), "%i. false", col);
		
		// PrintToConsole(client, derp);
	// }
	// PrintToConsole(client, "=============");
}

public CreatePlayerClimbMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "scout_true")) {		gClimb[client][0] = true;		SetClientCookie(client, cClimbScout, info);		}
		if (StrEqual(info, "scout_false")) {	gClimb[client][0] = false;		SetClientCookie(client, cClimbScout, info);		}
		if (StrEqual(info, "soldier_true"))	{	gClimb[client][1] = true;		SetClientCookie(client, cClimbSoldier, info);	}
		if (StrEqual(info, "soldier_false")) {	gClimb[client][1] = false;		SetClientCookie(client, cClimbSoldier, info);	}
		if (StrEqual(info, "pyro_true")) {		gClimb[client][2] = true;		SetClientCookie(client, cClimbPyro, info);		}
		if (StrEqual(info, "pyro_false")) {		gClimb[client][2] = false;		SetClientCookie(client, cClimbPyro, info);		}
		if (StrEqual(info, "demoman_true")) {	gClimb[client][3] = true;		SetClientCookie(client, cClimbDemo, info);		}
		if (StrEqual(info, "demoman_false")) {	gClimb[client][3] = false;		SetClientCookie(client, cClimbDemo, info);		}
		if (StrEqual(info, "heavy_true")) {		gClimb[client][4] = true;		SetClientCookie(client, cClimbHeavy, info);		}
		if (StrEqual(info, "heavy_false")) {	gClimb[client][4] = false;		SetClientCookie(client, cClimbHeavy, info);		}
		if (StrEqual(info, "engineer_true")) {	gClimb[client][5] = true;		SetClientCookie(client, cClimbEngie, info);		}
		if (StrEqual(info, "engineer_false")) {	gClimb[client][5] = false;		SetClientCookie(client, cClimbEngie, info);		}
		if (StrEqual(info, "medic_true")) {		gClimb[client][6] = true;		SetClientCookie(client, cClimbMedic, info);		}
		if (StrEqual(info, "medic_false")) {	gClimb[client][6] = false;		SetClientCookie(client, cClimbMedic, info);		}
		if (StrEqual(info, "sniper_true")) {	gClimb[client][7] = true;		SetClientCookie(client, cClimbSniper, info);	}
		if (StrEqual(info, "sniper_false")) {	gClimb[client][7] = false;		SetClientCookie(client, cClimbSniper, info);	}
		if (StrEqual(info, "spy_true"))	{		gClimb[client][8] = true;		SetClientCookie(client, cClimbSpy, info);		}
		if (StrEqual(info, "spy_false")) {		gClimb[client][8] = false;		SetClientCookie(client, cClimbSpy, info);		}
		
		CreatePlayerClimbMenu(client);
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (!GetConVarBool(cvarEnable)) return;
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new col = 0; col < 9; col++)
		{
			gClimb[i][col] = true;
		}
	}
}

public OnClientCookiesCached(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	decl String:info[32];
	
	GetClientCookie(client, cClimbScout, info, sizeof(info));
	if (StrEqual(info, "scout_true"))		gClimb[client][0] = true;
	if (StrEqual(info, "scout_false"))		gClimb[client][0] = false;
	
	GetClientCookie(client, cClimbSoldier, info, sizeof(info));
	if (StrEqual(info, "soldier_true"))		gClimb[client][1] = true;
	if (StrEqual(info, "soldier_false"))	gClimb[client][1] = false;
	
	GetClientCookie(client, cClimbPyro, info, sizeof(info));
	if (StrEqual(info, "pyro_true"))		gClimb[client][2] = true;
	if (StrEqual(info, "pyro_false"))		gClimb[client][2] = false;
	
	GetClientCookie(client, cClimbDemo, info, sizeof(info));
	if (StrEqual(info, "demoman_true"))		gClimb[client][3] = true;
	if (StrEqual(info, "demoman_false"))	gClimb[client][3] = false;
	
	GetClientCookie(client, cClimbHeavy, info, sizeof(info));
	if (StrEqual(info, "heavy_true"))		gClimb[client][4] = true;
	if (StrEqual(info, "heavy_false"))		gClimb[client][4] = false;
	
	GetClientCookie(client, cClimbEngie, info, sizeof(info));
	if (StrEqual(info, "engineer_true"))	gClimb[client][5] = true;
	if (StrEqual(info, "engineer_false"))	gClimb[client][5] = false;
	
	GetClientCookie(client, cClimbMedic, info, sizeof(info));
	if (StrEqual(info, "medic_true"))		gClimb[client][6] = true;
	if (StrEqual(info, "medic_false"))		gClimb[client][6] = false;
	
	GetClientCookie(client, cClimbSniper, info, sizeof(info));
	if (StrEqual(info, "sniper_true"))		gClimb[client][7] = true;
	if (StrEqual(info, "sniper_false"))		gClimb[client][7] = false;
	
	GetClientCookie(client, cClimbSpy, info, sizeof(info));
	if (StrEqual(info, "spy_true"))			gClimb[client][8] = true;
	if (StrEqual(info, "spy_false"))		gClimb[client][8] = false;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!GetConVarBool(cvarEnable) || !IsValidClient(client)) return Plugin_Continue;
	
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:		if (!gClimb[client][0]) return Plugin_Continue;
		case TFClass_Soldier:		if (!gClimb[client][1]) return Plugin_Continue;
		case TFClass_Pyro:		if (!gClimb[client][2]) return Plugin_Continue;
		case TFClass_DemoMan:		if (!gClimb[client][3]) return Plugin_Continue;
		case TFClass_Heavy:		if (!gClimb[client][4]) return Plugin_Continue;
		case TFClass_Engineer:	if (!gClimb[client][5]) return Plugin_Continue;
		case TFClass_Medic:		if (!gClimb[client][6]) return Plugin_Continue;
		case TFClass_Sniper:		if (!gClimb[client][7]) return Plugin_Continue;
		case TFClass_Spy:		if (!gClimb[client][8]) return Plugin_Continue;
	}
	
	if (!CheckCommandAccess(client, "sm_playerclimb_override", 0, true)) return Plugin_Continue;
	
	new bool:iBoss = false;
	if (!GetConVarBool(cvarBoss))
	{
		if (isClientBoss[client]) return Plugin_Continue;
	} else {
		iBoss = isClientBoss[client];
	}
	
	if (GetConVarInt(cvarTeam) != 0)
	{
		new team;
		if (GetConVarInt(cvarTeam) == 1) team = 3;
		if (GetConVarInt(cvarTeam) == 2) team = 2;
		if (GetClientTeam(client) != team) return Plugin_Continue;
	}
	
	if (IsValidEntity(weapon))
	{
		if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && (IsClassAllowed(client) || iBoss))
		{
			SickleClimbWalls(client, weapon);
		}
	}
	return Plugin_Continue;
}

public Timer_NoAttacking(any:ref)
{
	new weapon = EntRefToEntIndex(ref);
	SetNextAttack(weapon, GetConVarFloat(cvarNextClimb));
}

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetEntityFlags(i) & FL_ONGROUND)) 
		{
			maxClimbs[i] = 0;
			if (GetConVarFloat(cvarCooldown) != 0.0 && justClimbed[i])
			{
				justClimbed[i] = false;
				blockClimb[i] = true;
				CreateTimer(GetConVarFloat(cvarCooldown), Timer_ClimbCooldown, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:Timer_ClimbCooldown(Handle:timer, any:client)
{
	blockClimb[client] = false;
}

SickleClimbWalls(client, weapon)	 //Credit to Mecha the Slag
{
	if (!GetConVarBool(cvarEnable) || !IsValidClient(client) || (GetClientHealth(client) <= GetConVarFloat(cvarDamageAmount))) return;
	
	decl String:classname[64];
	decl Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);	 // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking
	
	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (!TR_DidHit(INVALID_HANDLE)) return;
	
	new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if (!((StrStarts(classname, "prop_") && classname[5] != 'p') || StrEqual(classname, "worldspawn"))) return;
	
	decl Float:fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);
	
	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return;
	if (fNormal[0] <= -30.0) return;
	
	decl Float:pos[3];
	TR_GetEndPosition(pos);
	new Float:distance = GetVectorDistance(vecClientEyePos, pos);
	
	if (distance >= 100.0) return;
	
	if (blockClimb[client])
	{
		PrintToChat(client, "[SM] Climbing is currently on cool-down, please wait.");
		return;
	}
	
	new maxNumClimbs = GetConVarInt(cvarMaxClimbs);
	
	if (maxNumClimbs != 0 && maxClimbs[client] >= maxNumClimbs && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		PrintToChat(client, "[SM] You need to touch the ground before you can climb again.");
		return;
	}
	
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	fVelocity[2] = 600.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	
	SDKHooks_TakeDamage(client, client, client, GetConVarFloat(cvarDamageAmount), DMG_CLUB, 0);
	
	//ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
	EmitAmbientSound("player/taunt_clip_spin.wav", vecClientEyePos);
	
	RequestFrame(Timer_NoAttacking, EntIndexToEntRef(weapon));
	maxClimbs[client]++;
	justClimbed[client] = true;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}

stock bool:IsClassAllowed(client)
{
	decl String:cvClass[255];
	GetConVarString(cvarClass, cvClass, sizeof(cvClass));
	if (StrEqual(cvClass, "all", false)) return true;
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:		if (StrContains(cvClass, "scout", false) != -1) return true;
		case TFClass_Sniper:		if (StrContains(cvClass, "sniper", false) != -1) return true;
		case TFClass_Soldier:		if (StrContains(cvClass, "soldier", false) != -1) return true;
		case TFClass_DemoMan:		if (StrContains(cvClass, "demo", false) != -1) return true;
		case TFClass_Medic:		if (StrContains(cvClass, "medic", false) != -1) return true;
		case TFClass_Heavy:		if (StrContains(cvClass, "heavy", false) != -1) return true;
		case TFClass_Pyro:		if (StrContains(cvClass, "pyro", false) != -1) return true;
		case TFClass_Spy:		if (StrContains(cvClass, "spy", false) != -1) return true;
		case TFClass_Engineer:	if (StrContains(cvClass, "engineer", false) != -1) return true;
	}
	return false;
}

stock SetNextAttack(weapon, Float:duration = 0.0)
{
	if (weapon <= MaxClients || !IsValidEntity(weapon)) return;
	new Float:next = GetGameTime() + duration;
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}

stock bool:IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

stock bool:StrStarts(const String:szStr[], const String:szSubStr[], bool:bCaseSensitive = true) 
{
	return !StrContains(szStr, szSubStr, bCaseSensitive);
}