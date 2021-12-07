#include <sourcemod> 
#include <sdkhooks> 
#include <sdktools> 

float sbDamageMult = 0.0;
float sbDamageCommonMult = 0.0;
float sbDamageSpecialMult = 0.0;

bool Lead = false;
bool Hold = false;
bool shove[MAXPLAYERS + 1] = false;

public Plugin:myinfo =  
{ 
    name = "Tougher And Better Survivor Bots", 
    author = "xQd, TBK Duy", 
    description = "Makes the survivor bots deal more damage against SI and commons and be more resistant to damage", 
    version = "1.4", 
    url = "https://forums.alliedmods.net/showpost.php?s=8f51d2d92e7765a708d8df2d4d4ceb85&p=2716112&postcount=21" 
}; 

ConVar g_hDifficulty;
ConVar g_cvTsbEnable;
ConVar g_cvBwsEnable;
ConVar Huntercounter;
ConVar Jockeycounter;

public OnPluginStart()
{ 
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("weapon_reload", Event_BotReload);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("weapon_fire", Event_FireStart);
	HookEvent("jockey_ride", JockeyDeadStop);
	
	RegConsoleCmd("sm_come", BotCome, "Tell bots to come here");
	RegConsoleCmd("sm_lead", BotLead, "Tell bots to lead the way");
	RegConsoleCmd("sm_hold", BotHold, "Tell bots to hold position");
	
	g_hDifficulty = FindConVar("z_difficulty");
	if (g_hDifficulty != null)
	{
		g_hDifficulty.AddChangeHook(OnDifficultyCvarChange);
	}
	g_cvTsbEnable = CreateConVar("l4d2_tsb_enable", "1", "1 = Enable Tougher Survivor Bots plugin effects, 0 = Disable the plugin's effects", _, true, 0.0, true, 1.0);
	g_cvBwsEnable = CreateConVar("l4d2_bws_enable", "1", "1 = Enable Bots can kill Witch fast effects, 0 = Disable the plugin's effects", _, true, 0.0, true, 1.0);
	Huntercounter = CreateConVar("l4d2_hunter_counter_chance", "50", "Chance bots can deadstopped the Hunter", FCVAR_NOTIFY);
	Jockeycounter = CreateConVar("l4d2_jockey_counter_chance", "50", "Chance bots can deadstopped the Jockey", FCVAR_NOTIFY);
	
	SetMultipliersBasedOnDifficulty();	
	AutoExecConfig(true, "l4d2_tougher_better_bots");
} 

public OnMapStart()
{
	SetMultipliersBasedOnDifficulty();
}

public OnClientPutInServer(client)
{ 
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
	SDKHook(client, SDKHook_StartTouchPost, OnEntityTouch);
} 

public OnEntityTouch(Touched_ent, client)
{
	if (1 <= client <= MaxClients && IsFakeClient(client))
	{
		if (1 <= Touched_ent <= MaxClients && GetEntProp(Touched_ent, Prop_Send, "m_zombieClass") == 3 && IsFakeClient(client) && IsPlayerAlive(client) && !IsClientPinned(client) && !IsClientIncapacitated(client))
		{
			if (GetRandomInt(0,100) <= GetConVarInt(Huntercounter))
			{
				shove[client] = true;
				float vPos[3];
				GetClientAbsOrigin(client, vPos);
				StaggerClient(GetClientUserId(Touched_ent), vPos);
				RequestFrame(SetTypewalk, Touched_ent);
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_cvTsbEnable.IntValue > 0)
	{
		if(attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
		{
			damage *= sbDamageSpecialMult; 
			return Plugin_Changed; 
		}
		if (victim > 0 && victim <= MaxClients && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsFakeClient(victim) && !IsClientIncapacitated(victim)) 
		{
			if (damagetype & DMG_BURN)
				damage /= 0;
			if (damagetype & DMG_FALL)
				damage /= 0;
			if (damagetype & DMG_BLAST)
				damage /= 0;
			if (damagetype & DMG_BULLET)
				damage /= 1.5;
			
			damage *= sbDamageMult;
			return Plugin_Changed;
		}
	}	
	return Plugin_Continue; 
}  

public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvBwsEnable.IntValue > 0)
	{
		int attackerId = event.GetInt("attacker");
		int attacker = GetClientOfUserId(attackerId);
		if(attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
		{
			int amount = event.GetInt("amount");
			int client = event.GetInt("entityid");
			int cur_health = GetEntProp(client, Prop_Data, "m_iHealth");
			int dmg_health = RoundToNearest(cur_health - amount*sbDamageCommonMult);	
			if(cur_health > 0)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", dmg_health);
				if(IsValidWitch(client) && g_cvBwsEnable.IntValue > 0)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(cur_health - ((amount*3.0) + (GetConVarInt(FindConVar("z_witch_health"))*0.25))));
				}
				return Plugin_Handled;
			}
		}
	}	
	return Plugin_Continue;
}

public Action JockeyDeadStop(Event event, const char[] name, bool dontBroadcast)
{
	int jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsFakeClient(victim))
	{
		if (GetRandomInt(0,100) <= GetConVarInt(Jockeycounter))
		{
			shove[victim] = true;
			float vPos[3];
			GetClientAbsOrigin(victim, vPos);			
			vPos[2] += 15.0;
			TeleportEntity(jockey, vPos, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(jockey, MOVETYPE_WALK);
			StaggerClient(GetClientUserId(jockey), vPos);
		}
	}
	return Plugin_Continue;
}

public Action Event_FireStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(weapon == -1)
	return;

	static char sWeapon[16];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	if(IsFakeClient(client))
	{
		switch(sWeapon[0])
		{
			case 'p':
			{
				if (StrEqual(sWeapon, "pumpshotgun"))
					shove[client] = true;
			}
			case 's':
			{
				if (StrEqual(sWeapon, "shotgun_chrome"))
					shove[client] = true;
				else if (StrEqual(sWeapon, "sniper_awp"))
					shove[client] = true;
				else if (StrEqual(sWeapon, "sniper_scout"))
					shove[client] = true;				
			}
		}
	}
}

public Action Event_BotReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 4) && IsFakeClient(client) && !IsClientIncapacitated(client))
	{
		int giveFlags = GetCommandFlags("give");
		SetCommandFlags("give", giveFlags ^ FCVAR_CHEAT);
		char giveCommand[128];
		Format(giveCommand, sizeof(giveCommand), "give %s", "ammo");
		FakeClientCommand(client, giveCommand);
		char sWeapon[64];
		int Weapon = GetPlayerWeaponSlot(client, 0);
		if(Weapon != -1)
		{
			GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));
		}
		SetCommandFlags("give", giveFlags | FCVAR_CHEAT);
		if(StrEqual(sWeapon, "weapon_grenade_launcher")) 
		{
			int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo");
			if(GetEntProp(Weapon, Prop_Data, "m_iClip1") < 1)
			SetEntData(client, iAmmoOffset + 68, GetConVarInt(FindConVar("ammo_grenadelauncher_max")) + 1);
			else
			SetEntData(client, iAmmoOffset + 68, GetConVarInt(FindConVar("ammo_grenadelauncher_max")));
		}
		char classname[64];
		giveFlags = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", giveFlags & ~FCVAR_CHEAT);
		if(GetPlayerWeaponSlot(client, 3) != -1 && GetPlayerWeaponSlot(client, 0) != -1)
		{
			GetEntityClassname(GetPlayerWeaponSlot(client, 3), classname, sizeof(classname));				
			if( StrEqual(classname, "weapon_upgradepack_explosive", false))
			{
				Format(giveCommand, sizeof(giveCommand), "upgrade_add %s", "EXPLOSIVE_AMMO");
			}
			else if( StrEqual(classname, "weapon_upgradepack_incendiary", false))
			{
				Format(giveCommand, sizeof(giveCommand), "upgrade_add %s", "INCENDIARY_AMMO");
			}
			FakeClientCommand(client, giveCommand);
			SetCommandFlags("give", giveFlags | FCVAR_CHEAT);
		}
	}
}

public Action OnPlayerRunCmd(client, &buttons)
{
	if (GetClientTeam(client) == 2 && IsFakeClient(client))
	{
		if (shove[client] == true && GetEntProp(client, Prop_Send, "m_reviveTarget") < 1) 
		{
			buttons += IN_ATTACK2;
			shove[client] = false;
			return Plugin_Continue;
		}
		if(GetClientTeam(client) == 2 && IsFakeClient(client))
		{
			int target = GetClientAimTarget(client, true);
			if(target != -1)
			{
				if(GetClientTeam(target) == 3)
				{
					buttons |= IN_ATTACK;
				}
			}
		}
		if (GetClientTeam(client) == 2 && IsFakeClient(client) && IsPlayerAlive(client) && !IsClientIncapacitated(client) && !IsClientPinned(client))
		{
			for (int i = 1; i <= GetEntityCount(); i++)
			{
				if (IsValidCommon(i))
				{
					float pos1[3],pos2[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
					if(GetVectorDistance(pos1,pos2) <= 40)
					{
						PushCommonInfected(client, i, pos1, "0", "0");
					}
				}
			}
		}
	}	
	return Plugin_Continue;
}	

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetMultipliersBasedOnDifficulty();
	
	return Plugin_Continue;
}

public void OnDifficultyCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{	
	SetMultipliersBasedOnDifficulty();
}	

public void SetMultipliersBasedOnDifficulty()
{
	char sDifficulty[128];
 
	g_hDifficulty.GetString(sDifficulty, 128);
 
	if (strcmp(sDifficulty, "easy", false) == 0)
	{
		sbDamageMult = 1.0
		sbDamageSpecialMult = 1.0
		sbDamageCommonMult = 1.25
	}
	else if (strcmp(sDifficulty, "normal", false) == 0)
	{
		sbDamageMult = 0.75
		sbDamageSpecialMult = 1.10
		sbDamageCommonMult = 1.50
	}
	else if (strcmp(sDifficulty, "hard", false) == 0)
	{
		sbDamageMult = 0.50
		sbDamageSpecialMult = 1.20
		sbDamageCommonMult = 1.75
	}
	else if (strcmp(sDifficulty, "impossible", false) == 0)
	{
		sbDamageMult = 0.25
		sbDamageSpecialMult = 1.30
		sbDamageCommonMult = 2.0
	}
	else
	{
		sbDamageMult = 0.75
		sbDamageSpecialMult = 1.10
		sbDamageCommonMult = 1.50
	}
}

public Action:BotLead(client, args)
{
	if (!Lead)
	{
		Lead = !Lead;
		PrintHintTextToAll("Bot Leading - ON");
		SetConVarInt(FindConVar("sb_escort"), 0);
		SetConVarInt(FindConVar("sb_allow_leading"), 1);
	}
	else
	{
		Lead = !Lead;
		PrintHintTextToAll("Bot Leading - OFF");
		SetConVarInt(FindConVar("sb_escort"), 1);
		SetConVarInt(FindConVar("sb_allow_leading"), 0);
	}
	return Plugin_Handled;
}

public Action:BotHold(client, args)
{
	if (!Hold)
	{
		Hold = !Hold;
		PrintHintTextToAll("Bot Hold Position - ON");
		SetConVarInt(FindConVar("sb_hold_position"), 1);
		SetConVarInt(FindConVar("sb_crouch"), 1);
	}
	else
	{
		Hold = !Hold;
		PrintHintTextToAll("Bot Hold Position - OFF");
		SetConVarInt(FindConVar("sb_hold_position"), 0);
		SetConVarInt(FindConVar("sb_crouch"), 0);
	}
	return Plugin_Handled;
}

public Action:BotCome(int client, int args)
{
	float newang[3];
	GetClientAbsOrigin(client, newang);
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (GetClientHealth(target) > 0	&& GetClientTeam(target) == 2 && IsFakeClient(target) && !(IsClientIncapacitated(target)))
			{
				L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", newang[0], newang[1], newang[2], GetClientUserId(target));
			}
		}
	}
	return Plugin_Handled;
}

public bool:IsClientIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

stock IsClientPinned(client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 && client != GetEntPropEnt(client, Prop_Send, "m_pummelAttacker"))
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 && client != GetEntPropEnt(client, Prop_Send, "m_carryAttacker"))
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 && client != GetEntPropEnt(client, Prop_Send, "m_pounceAttacker"))
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 && client != GetEntPropEnt(client, Prop_Send, "m_tongueOwner"))
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 && client != GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker"))
		return true;

	return false;
}

stock IsValidWitch(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}	
	return false;
}

stock IsValidCommon(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "infected"))
		{
			return true;
		}
	}	
	return false;
}

stock PushCommonInfected(client, target, Float:vPos[3], String:dam[128], String:damtype[128])
{
	int entity = CreateEntityByName("point_hurt", -1);
	DispatchKeyValue(target, "targetname", "silvershot");
	DispatchKeyValue(entity, "DamageTarget", "silvershot");
	DispatchKeyValue(entity, "Damage", dam);
	DispatchKeyValue(entity, "DamageType", damtype);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "Hurt", client);
	RemoveEdict(entity);
}

stock L4D2_RunScript(const String:sCode[], any:...)
{
    static iScriptLogic = INVALID_ENT_REFERENCE;
    if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
        if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
            SetFailState("Could not create 'logic_script'");
        
        DispatchSpawn(iScriptLogic);
    }
    
    static String:sBuffer[512];
    VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
    
    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
} 

stock StaggerClient(iUserID, const Float:fPos[3])
{
	static iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			LogError("Could not create 'logic_script");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static String:sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer); 	
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	AcceptEntityInput(iScriptLogic, "Kill");
}

SetTypewalk(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk2, client);
}

SetTypewalk2(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk3, client);
}

SetTypewalk3(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk4, client);
}

SetTypewalk4(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk5, client);
}

SetTypewalk5(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk6, client);
}

SetTypewalk6(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk7, client);
}

SetTypewalk7(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk8, client);
}

SetTypewalk8(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk9, client);
}

SetTypewalk9(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	RequestFrame(SetTypewalk10, client);
}

SetTypewalk10(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
}
