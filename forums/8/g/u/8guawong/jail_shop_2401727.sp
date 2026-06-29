#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <csgocolors>
#include <hosties>
#include <lastrequest>  
#include <smartjaildoors>
#include <emitsoundany>
#pragma semicolon 1

new bool:g_Ivisivel[MAXPLAYERS+1] = {false, ...};
new bool:g_Godmode[MAXPLAYERS+1] = {false, ...};
new bool:poison[MAXPLAYERS+1] = {false, ...};
new bool:vampire[MAXPLAYERS+1] = {false, ...};
new bool:super_faca[MAXPLAYERS+1] = {false, ...};
new bool:view[MAXPLAYERS+1] = {false, ...};
new bool:fogo[MAXPLAYERS+1] = {false, ...};
new bool:AWP[MAXPLAYERS+1] = {true,...};
new bool:EAGLE[MAXPLAYERS+1] = {true, ...};
new bool:bhop[MAXPLAYERS+1] = {false, ...};
new bool:Spell[MAXPLAYERS+1] = {false, ...};
new bool:abrir_maximo[MAXPLAYERS+1] = {false, ...};
new bool:infinita[MAXPLAYERS+1] = {false, ...};
new Laser = -1;

new g_Kedavra = -1;

#define VERSION "V8"

new g_iCreditos[MAXPLAYERS+1];

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

new Handle:intervalo;
new Handle:timerbala;

new Handle:cvarCreditosMax = INVALID_HANDLE;
new Handle:cvarCreditosKill_CT = INVALID_HANDLE;
new Handle:cvarCreditosKill_T = INVALID_HANDLE;
new Handle:cvarCreditos_LR = INVALID_HANDLE;
new Handle:cvarCreditosKill_CT_VIP = INVALID_HANDLE;
new Handle:cvarCreditosKill_T_VIP = INVALID_HANDLE;
new Handle:cvarCreditos_LR_VIP = INVALID_HANDLE;
new Handle:cvarCreditos_Kedavra = INVALID_HANDLE;
new Handle:cvarCreditosSave = INVALID_HANDLE;
new Handle:cvarTronly = INVALID_HANDLE;
new Handle:cvarEnableRevive = INVALID_HANDLE;
new Handle:cvarSpawnMsg = INVALID_HANDLE;
new Handle:cvarCreditsOnWarmup = INVALID_HANDLE;
new Handle:cvarMinPlayersToGetCredits = INVALID_HANDLE;
new Handle:cvar_1;
new Handle:cvar_2;
new Handle:cvar_3;
new Handle:cvar_4;
new Handle:cvar_5;
new Handle:cvar_6;
new Handle:cvar_7;
new Handle:cvar_8;
new Handle:cvar_9;
new Handle:cvar_10;
new Handle:cvar_11;
new Handle:cvar_12;
new Handle:cvar_14;
new Handle:cvar_15;
new Handle:cvar_16;
new Handle:cvar_17;
new Handle:cvar_18;
new Handle:cvar_19;
new Handle:cvar_20;
new Handle:cvar_21;
new Handle:cvar_22;
new Handle:cvar_23;
new Handle:cvar_24;

new Handle:c_GameCreditos = INVALID_HANDLE;

new g_sprite;
new g_HaloSprite;


public Plugin:myinfo =
{
    name = "Shop Jail",
    author = "Dk--",
    description = "Buy itens on JailBreak Server",
    version = VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	
	CreateNative("jailshop_setcredits", Native_Set);
	
	CreateNative("jailshop_getcredits", Native_Get);
	
	return APLRes_Success;
}

public int Native_Get(Handle:plugin, argc)
{  
	int client = GetNativeCell(1);
	
	return g_iCreditos[client];
}

public int Native_Set(Handle:plugin, argc)
{  
	int client = GetNativeCell(1);
	
	g_iCreditos[client] = GetNativeCell(2);
}

public OnPluginStart()
{

	LoadTranslations("common.phrases");
	LoadTranslations("jail_shop.phrases");
	c_GameCreditos = RegClientCookie("Creditos", "Creditos", CookieAccess_Private);

	// ======================================================================

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate2, EventHookMode_Post);
	HookEvent("player_hurt",EventPlayerHurt, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("weapon_fire", Fire);
	// ======================================================================

	RegConsoleCmd("sm_shop", SHOPMENU);
	RegConsoleCmd("sm_ctshop", SHOPMENU2);
	RegConsoleCmd("sm_credits", Creditos);
	RegConsoleCmd("sm_gift", Command_SendCredits);
	RegConsoleCmd("sm_revive", Reviver);
	RegConsoleCmd("sm_showcredits", Command_ShowCredits);
	
	RegConsoleCmd("sm_give", SetCreditos);
	RegAdminCmd("sm_set", SetCreditos2, ADMFLAG_ROOT);
	RegAdminCmd("sm_removeall", RemoveCredits, ADMFLAG_ROOT);
	// ======================================================================

	// ======================================================================

	cvarCreditosMax = CreateConVar("shop_credits_maximum", "500000", "Maxim of credits for player");
	cvarCreditosKill_T = CreateConVar("shop_credits_per_kill_t", "150", "Amount of credits for kill ( prisioner )");
	cvarCreditosKill_CT = CreateConVar("shop_credits_per_kill_ct", "15", "Amount of credits for kill ( guard )");
	cvarCreditos_LR = CreateConVar("shop_credits_per_kill_lr", "300", "Amount of credits for the last player");
	cvarCreditosKill_T_VIP = CreateConVar("shop_credits_per_kill_t_vip", "150", "Amount of credits for kill ( prisioner ) for VIP (flag a)");
	cvarCreditosKill_CT_VIP = CreateConVar("shop_credits_per_kill_ct_vip", "15", "Amount of credits for kill ( guard ) for VIP (flag a)");
	cvarCreditos_LR_VIP = CreateConVar("shop_credits_per_kill_lr_vip", "300", "Amount of credits for the last player for VIP (flag a)");
	cvarCreditos_Kedavra = CreateConVar("shop_credits_per_kedavra", "300", "Amount of credits for one right avada kedavra");
	cvarSpawnMsg = CreateConVar("shop_spawnmessages", "1", "Messages on spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCreditosSave = CreateConVar("shop_credits_save", "1", "Save or not credits on player disconnect", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTronly = CreateConVar("shop_terrorist_only", "1", "Menu for only prisioners", FCVAR_NONE, true, 0.0, true, 1.0); 
	cvarEnableRevive = CreateConVar("shop_revive_on", "1", "Enable/Disble revive", FCVAR_NONE, true, 0.0, true, 1.0); 
	cvarCreditsOnWarmup = CreateConVar("shop_warmupcredits", "0", "Should players get credits on warmup?");
	cvarMinPlayersToGetCredits = CreateConVar("shop_minplayers", "4", "Minimum players to get credits");
		
	cvar_1 = CreateConVar("price_01", "7000", "Price of item (invisible)");
	cvar_2 = CreateConVar("price_02", "2000", "Price of item (awp)");
	cvar_3 = CreateConVar("price_03", "7000", "Price of item (imortal)");
	cvar_4 = CreateConVar("price_04", "800", "Price of item (open jails)");
	cvar_5 = CreateConVar("price_05", "4000", "Price of item (more fast)");
	cvar_6 = CreateConVar("price_06", "3500", "Price of item (hp)");
	cvar_7 = CreateConVar("price_07", "2000", "Price of item (eagle)");
	cvar_8 = CreateConVar("price_08", "1500", "Price of item (super knife)");
	cvar_9 = CreateConVar("price_09", "50", "Price of item (healing)");
	cvar_10 = CreateConVar("price_10", "650", "Price of item (molotov)");
	cvar_11 = CreateConVar("price_11", "7000", "Price of item (skin)");
	cvar_12 = CreateConVar("price_12", "1000", "Price of item (poison smoke)");
	cvar_14 = CreateConVar("price_14", "8000", "Price of item (smoke teleport)");
	cvar_15 = CreateConVar("price_15", "8000", "Price of item (respawn)");
	cvar_16 = CreateConVar("price_16", "2000", "Price of item (he with fire)");
	cvar_17 = CreateConVar("price_17", "5000", "Price of item (bhop)");
	cvar_18 = CreateConVar("price_18", "2500", "Price of item (low gravity)");
	cvar_19 = CreateConVar("price_19", "1000", "Price of item (taser with 3 bullets)");
	cvar_20 = CreateConVar("price_20", "10000", "Price of item (Kedavra)");
	cvar_21 = CreateConVar("price_21", "5000", "Price of item (Colete)");
	cvar_22 = CreateConVar("price_22", "1500", "Price of item (Curar CT)");
	cvar_23 = CreateConVar("price_23", "12000", "Price of item (InifinteAmmo)");
	cvar_24 = CreateConVar("price_24", "8000", "Price of item (KitGranada)");
	intervalo = CreateConVar("ammo_interval", "1", "How often to reset ammo (in seconds).", _, true, 1.0);

	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
	
	if(GetConVarBool(cvarCreditosSave))
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				if(AreClientCookiesCached(client))
				{
					OnClientCookiesCached(client);
				}
			}
		} 
	}

	AutoExecConfig(true, "shop_jail_v8");
}


public OnPluginEnd()
{
	if(!GetConVarBool(cvarCreditosSave))
		return;

	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}


public OnClientCookiesCached(client)
{
	if(!GetConVarBool(cvarCreditosSave))
		return;

	new String:CreditosString[12];
	GetClientCookie(client, c_GameCreditos, CreditosString, sizeof(CreditosString));
	g_iCreditos[client]  = StringToInt(CreditosString);
}  

public OnClientDisconnect(client)
{	
	if(!GetConVarBool(cvarCreditosSave))
	{
		g_iCreditos[client] = 0;
		return;
	}
	
	if(AreClientCookiesCached(client))
	{
		new String:CreditosString[12];
		Format(CreditosString, sizeof(CreditosString), "%i", g_iCreditos[client]);
		SetClientCookie(client, c_GameCreditos, CreditosString);
	} 
	
}


public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt", true);
	PrecacheModel("models/player/ctm_fbi_varianta.mdl", true); 
	AddFileToDownloadsTable("sound/music/spells/kedavra.mp3");
	PrecacheSoundAny("sound/music/spells/kedavra.mp3"); 
	Laser = PrecacheModel("materials/sprites/laserbeam.vmt"); 
}


public Action:MensajesSpawn(Handle:timer, any:client)
{
	if(GetConVarBool(cvarSpawnMsg) && IsClientInGame(client))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Kill");
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Type");
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(2.0, Morte, client);
	
	
	if (!attacker)
		return;

	if (attacker == client)
		return;

	if(!GetConVarBool(cvarCreditosKill_CT))
		return;
	
	if(!GetConVarBool(cvarCreditosKill_T))
		return;
	
	if(GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1) ) 
	{
		if(GetClientTeam(attacker) == CS_TEAM_CT)
		{
			if (IsPlayerReservationAdmin(attacker))
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_CT_VIP);
			else 
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_CT);
		}
		
		if(GetClientTeam(attacker) == CS_TEAM_T)
		{
			if (IsPlayerReservationAdmin(attacker)) 
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_T_VIP);
			else 
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_T);
		}
	}
	if(GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1) ) 
	{
		if (g_iCreditos[attacker] < GetConVarInt(cvarCreditosMax))
		{
			if(GetClientTeam(attacker) == CS_TEAM_CT)
			{
				if (IsPlayerReservationAdmin(attacker))
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t","KillCT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_CT_VIP));
				else
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t","KillCT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_CT));
			}
		
			if(GetClientTeam(attacker) == CS_TEAM_T)
			{
				if (IsPlayerReservationAdmin(attacker))
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t","KillT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_T_VIP));
				else
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t","KillT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_T));
			}
			
			
		}
		else
		{
			CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t","Maximo", g_iCreditos[attacker]);
			g_iCreditos[attacker] = GetConVarInt(cvarCreditosMax);
		}
	}
}

public Action:Morte(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
	CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Reviver4",GetConVarInt(cvar_15));
 }
}

public Action:Creditos(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
        CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Creditos", g_iCreditos[client]);
}

public Action:SHOPMENU2(client,args)
{

	if(GetClientTeam(client) == 2)
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t","GuardsOnly");
		return;
	}
	else
	{
		CTSHOP(client);
	}
}

public Action:SHOPMENU(client,args)
{
	if(GetConVarBool(cvarTronly))
	{
		if(GetClientTeam(client) != 2)
		{
			 CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Prisioneiros");
			 return;
		}
		else
		{
			DID(client);
		}
	}
	else
	{
		DID(client);
	}
}

public Action:Reviver(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
	
	if(!GetConVarBool(cvarEnableRevive))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Ativado");
		return;
	}
	
	if(GetConVarBool(cvarTronly))
	{
		if(GetClientTeam(client) != 2)
		{
			 CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Prisioneiros2");
			 return;
		}
		else
		{
			if (IsClientInGame(client) && !IsPlayerAlive(client))
			{
				if (g_iCreditos[client] >= GetConVarInt(cvar_15))
				{

					CS_RespawnPlayer(client);

					g_iCreditos[client] -= GetConVarInt(cvar_15);

					decl String:nome[32];
					GetClientName(client, nome, sizeof(nome));
					
					CPrintToChatAll("\x0E[ SHOP ] \x04The player\x03 %s \x04has respawned by shop!", nome); 

				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item reviver", g_iCreditos[client],GetConVarInt(cvar_15));
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Morto");
			}
		}
	}
	else
	{
		if (!IsPlayerAlive(client))
		{
			if (g_iCreditos[client] >= GetConVarInt(cvar_15))
			{

				CS_RespawnPlayer(client);

				g_iCreditos[client] -= GetConVarInt(cvar_15);

				decl String:nome[32];
				GetClientName(client, nome, sizeof(nome));
				
				
				CPrintToChatAll("\x0E[ SHOP ] \x04The player\x03 %s \x04has respawned by shop!", nome); 

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item reviver", g_iCreditos[client],GetConVarInt(cvar_15));
			}
		}
		else
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Morto");
		}
	}
}

public OnConfigsExecuted()
{

	if (timerbala != INVALID_HANDLE) {
		KillTimer(timerbala);
	}
	new Float:interval = GetConVarFloat(intervalo);
	timerbala = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);
}

public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker == 0 || !fogo[attacker]) 
		return;

	if(victim != attacker && attacker !=0 && attacker <MAXPLAYERS){
		new String:sWeaponUsed[50];
		GetEventString(event,"weapon",sWeaponUsed,sizeof(sWeaponUsed));
		if(StrEqual(sWeaponUsed,"hegrenade"))
		{
			IgniteEntity(victim, 15.0);
			fogo[victim] = false;
		}
		
	}
}

public Action:Event_SmokeGrenadeDetonate2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(view[client] == true)
	{
		view[client] = false;
		if(IsClientInGame(client))
		SetClientViewEntity(client, client);
		new Float:origin[3];

		// Dest. location
		origin[0] = float(GetEventInt(event, "x"));
		origin[1] = float(GetEventInt(event, "y"));
		origin[2] = float(GetEventInt(event, "z"));
		
		//TELEPORT TO PLACE WHERE THE GRENADE WILL EXPLODE!
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Event_SmokeGrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z");

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!poison[client])
		return;

	new iEntity = CreateEntityByName("light_dynamic");

	if (iEntity == -1)
	{
		return;
	}
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "5");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 96.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "6");
	DispatchKeyValue(iEntity, "_light", "0 255 0");
	DispatchKeyValueFloat(iEntity, "distance", 256.0);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
	CreateTimer(20.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);

	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_sprite, g_HaloSprite, 0, 15, 20.0, 10.0, 220.0, {50, 255, 50, 255}, 10, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_sprite, g_HaloSprite, 0, 15, 20.0, 10.0, 220.0, {50, 50, 255, 255}, 10, 0);
	TE_SendToAll();

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");

	CreateTimer(1.0, Timer_CheckDamage, iEntity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		
	poison[client] = false;
}

public OnEntityCreated(iEntity, const String:classname[]) 
{
	if(StrEqual(classname, "smokegrenade_projectile"))
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
}

public OnEntitySpawned(iGrenade)
{
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if(view[client] && IsClientInGame(client))
	{
		SetClientViewEntity(client, iGrenade);
	}
}

public Action:Fire(Handle:event, const String:name[], bool:dB)	
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(Spell[client])
	{
		decl String:weapon[64];
		
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		if(StrContains(weapon,"knife") != -1)
		{
			new target = GetClientAimTarget(client);
			
			if(0 < target < MaxClients && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
			{
				CreateTimer(0.5, Timer_Slap, any:target);
				CreateTimer(1.2, Timer_Kill, any:target);
				Ray(client);
				g_Kedavra = client;
				new Float:pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				
				EmitSoundToAllAny("music/spells/kedavra.mp3");  
				
		
				g_iCreditos[client] += GetConVarInt(cvarCreditos_Kedavra);
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Ganhou", GetConVarInt(cvarCreditos_Kedavra));
				Spell[client] = false;
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x07%t","Errou");
				Spell[client] = false;
				
			}
		}
		else
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x07 Use a faca para lançar o poder");
		}
	}
}

public Action:Timer_Slap(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		Slap(client, 5);
	}
}

public Action:Timer_Kill(Handle:timer, any:client)	
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		DealDamage(client,100000,g_Kedavra,DMG_BULLET,"weapon_knife");
		SetEntProp(g_Kedavra, Prop_Data, "m_iFrags", GetClientFrags(g_Kedavra) + 2);
	}
}
public Action:Delete(Handle:timer, any:entity)
{
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:Delete2(Handle:timer, any:entity)
{
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:Timer_CheckDamage(Handle:timer, any:iEntity)
{

	if(!IsValidEdict(iEntity))
		return Plugin_Stop;

        new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");


        if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;


	new Float:fSmokeOrigin[3], Float:fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fSmokeOrigin);

	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
		{
			GetClientAbsOrigin(i, fOrigin);
			if(GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
				//SDKHooks_TakeDamage(i, iGrenade, client, GetConVarFloat(g_hCVDamage), DMG_POISON, -1, NULL_VECTOR, fSmokeOrigin);
                                DealDamage(i,75,client,DMG_POISON,"weapon_smokegrenade");
		}
	}
        return Plugin_Continue;
}

stock Ray(client)
{
	decl Float:clientpos[3];
	decl Float:position[3];
	GetPlayerEye(client, position);
	GetClientEyePosition(client, clientpos);
	TE_SetupBeamPoints(clientpos, position, Laser, 0, 0, 0, 0.3, 3.0, 3.0, 10, 0.0, {21, 178, 57, 255}, 30);
	TE_SendToAll(0.0);
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
/* ~~~~~~~~~~~~~~~~~ */

/* ~ Stocks > Slap ~ */
stock Slap(client, slaps)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 1; i <= slaps; i++)
		{
			SlapPlayer(client, 0);
		}
	}
}

stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
// ----------------------------------------------------------------------------
{
	// taken from: http://forums.alliedmods.net/showthread.php?t=111684
	// thanks to the authors!
	if(	nClientVictim > 0 &&
			IsValidEdict(nClientVictim) &&
			IsClientInGame(nClientVictim) &&
			IsPlayerAlive(nClientVictim) &&
			nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));

			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));

			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
				DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");

			RemoveEdict(EntityPointHurt);
		}
	}
} 

public Action:CTSHOP(clientId) 
{
	new Handle:ctmenu = CreateMenu(CTSHOPHANDLER);
	SetMenuTitle(ctmenu, "%t","Shop2", g_iCreditos[clientId]);
	decl String:opcionmenu2[124];
	
	Format(opcionmenu2, 124, "%T","Colete", clientId,GetConVarInt(cvar_21));
	AddMenuItem(ctmenu, "option1", opcionmenu2);	
	
	Format(opcionmenu2, 124, "%T","SeCurar", clientId,GetConVarInt(cvar_22));
	AddMenuItem(ctmenu, "option2", opcionmenu2);
	
	Format(opcionmenu2, 124, "%T","InifinteAmmo", clientId,GetConVarInt(cvar_23));
	AddMenuItem(ctmenu, "option3", opcionmenu2);
	
	Format(opcionmenu2, 124, "%T","KitGranada", clientId,GetConVarInt(cvar_23));
	AddMenuItem(ctmenu, "option4", opcionmenu2);
	
	SetMenuExitButton(ctmenu, true);
	DisplayMenu(ctmenu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "%t","Shop", g_iCreditos[clientId]);
	decl String:opcionmenu[124];
	
	Format(opcionmenu, 124, "%T","Invisivel", clientId,GetConVarInt(cvar_1));
	AddMenuItem(menu, "option5", opcionmenu);	
	
	Format(opcionmenu, 124, "%T","AWP", clientId,GetConVarInt(cvar_2));
	AddMenuItem(menu, "option6", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Imortal", clientId,GetConVarInt(cvar_3));
	AddMenuItem(menu, "option8", opcionmenu);
		
	//Format(opcionmenu, 124, "%T","Jail", clientId,GetConVarInt(cvar_4));
	//AddMenuItem(menu, "option9", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Rapido", clientId,GetConVarInt(cvar_5));
	AddMenuItem(menu, "option10", opcionmenu);
		
	Format(opcionmenu, 124, "%T","HP", clientId,GetConVarInt(cvar_6));
	AddMenuItem(menu, "option12", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Eagle", clientId,GetConVarInt(cvar_7));
	AddMenuItem(menu, "option13", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Super", clientId,GetConVarInt(cvar_8));
	AddMenuItem(menu, "option14", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Cura", clientId,GetConVarInt(cvar_9));
	AddMenuItem(menu, "option15", opcionmenu);
		
	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "cstrike"))
	{
		Format(opcionmenu, 124, "%T","2flash", clientId,GetConVarInt(cvar_10));
		AddMenuItem(menu, "option16", opcionmenu);
	}
	else if (StrEqual(sGame, "csgo"))
	{
		Format(opcionmenu, 124, "%T","Molotov", clientId,GetConVarInt(cvar_10));
		AddMenuItem(menu, "option16", opcionmenu);
	}
	
	Format(opcionmenu, 124, "%T","Skin", clientId,GetConVarInt(cvar_11));
	AddMenuItem(menu, "option17", opcionmenu);
		
	Format(opcionmenu, 124, "%T","Smoke", clientId,GetConVarInt(cvar_12));
	AddMenuItem(menu, "option18", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Teletransportadora3", clientId,GetConVarInt(cvar_14));
	AddMenuItem(menu, "option20", opcionmenu);
	
	Format(opcionmenu, 124, "%T","HE", clientId,GetConVarInt(cvar_16));
	AddMenuItem(menu, "option21", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Bhop", clientId,GetConVarInt(cvar_17));
	AddMenuItem(menu, "option22", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Gravity", clientId,GetConVarInt(cvar_18));
	AddMenuItem(menu, "option23", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Taser", clientId,GetConVarInt(cvar_19));
	AddMenuItem(menu, "option24", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Kedavra", clientId,GetConVarInt(cvar_20));
	AddMenuItem(menu, "option25", opcionmenu);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public CTSHOPHANDLER(Handle:ctmenu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];

		GetMenuItem(ctmenu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option1") == 0 ) 
		{
			CTSHOP(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_21))
			{
				if (IsPlayerAlive(client))
				{

					GivePlayerItem( client, "item_assaultsuit"); // Give Kevlar Suit and a Helmet
					SetEntProp( client, Prop_Send, "m_ArmorValue", 100, 1 ); // Set kevlar armour
					g_iCreditos[client] -= GetConVarInt(cvar_21);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Colete2", g_iCreditos[client],GetConVarInt(cvar_21));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item Colete", g_iCreditos[client],GetConVarInt(cvar_21));
			}
		}

		else if ( strcmp(info,"option2") == 0 ) 
		{
			CTSHOP(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_22))
			{
				if (IsPlayerAlive(client))
				{
					new health = GetEntProp(client, Prop_Send, "m_iHealth");  
					
					if(health >= 100)
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t","LifeFull");
						
					}
					else
					{
						SetEntityHealth(client, 100);
						g_iCreditos[client] -= GetConVarInt(cvar_22);
						EmitSoundToAllAny("medicsound/medic.wav");  	
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t","CurarCT", g_iCreditos[client],GetConVarInt(cvar_22));
					}
					g_iCreditos[client] -= GetConVarInt(cvar_22);		
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item CurarCT", g_iCreditos[client],GetConVarInt(cvar_22));
			}
		}
		
		else if ( strcmp(info,"option3") == 0 ) 
		{
			CTSHOP(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_23))
			{
				if (IsPlayerAlive(client))
				{
					infinita[client] = true;
					SetEntityHealth(client, 100);
					g_iCreditos[client] -= GetConVarInt(cvar_23);
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Infinito", g_iCreditos[client],GetConVarInt(cvar_23));
					g_iCreditos[client] -= GetConVarInt(cvar_23);		
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item Infinito", g_iCreditos[client],GetConVarInt(cvar_23));
			}
		}
		
		else if ( strcmp(info,"option4") == 0 ) 
		{
			CTSHOP(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_24))
			{
				if (IsPlayerAlive(client))
				{
					GivePlayerItem(client, "weapon_hegrenade");
					GivePlayerItem(client, "weapon_smokegrenade");
					GivePlayerItem(client, "weapon_flashbang");
					GivePlayerItem(client, "weapon_flashbang");
					GivePlayerItem(client, "weapon_incgrenade");
					GivePlayerItem(client, "weapon_taser");
					g_iCreditos[client] -= GetConVarInt(cvar_24);
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","KitGranada2", g_iCreditos[client],GetConVarInt(cvar_24));
					g_iCreditos[client] -= GetConVarInt(cvar_24);		
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item KitGranada", g_iCreditos[client],GetConVarInt(cvar_22));
			}
		}
	}
}
public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];

		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option1") == 0 ) 
		{
			DID(client);
			CPrintToChat(client,"\x0E[ SHOP ] \x04make by dk.");
		}

		else if ( strcmp(info,"option5") == 0 ) 
		{
			DID(client);		
			if (g_iCreditos[client] >= GetConVarInt(cvar_1))
			{
				if (IsPlayerAlive(client))
				{
					decl String:sGame[255];
					GetGameFolderName(sGame, sizeof(sGame));
					if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
					{
						SetEntityRenderMode(client, RENDER_TRANSCOLOR);
						SetEntityRenderColor(client, 255, 255, 255, 0);
						g_Ivisivel[client] = true;		
						CreateTimer(10.0, Invisible2, client);
					}
					else if (StrEqual(sGame, "csgo"))
					{
						SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
						g_Ivisivel[client] = true;		
						CreateTimer(10.0, Invisible, client);
					}

					new wepIdx;

					// strip all weapons
					for (new s = 0; s < 4; s++)
					{
						if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
						{
							RemovePlayerItem(client, wepIdx);
							RemoveEdict(wepIdx);
						}
					}

					GivePlayerItem(client, "weapon_knife");
					

					g_iCreditos[client] -= GetConVarInt(cvar_1);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Invisivel2", g_iCreditos[client],GetConVarInt(cvar_2));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item invisivel", g_iCreditos[client],GetConVarInt(cvar_1));
			}
		
		}

		else if ( strcmp(info,"option6") == 0 ) 
		{
			DID(client);
			if (g_iCreditos[client] >= GetConVarInt(cvar_2))
			{
				if(!AWP[client])
				{	
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","MaximoAWP");
				}
				else if(AWP[client] && IsPlayerAlive(client))
				{	
					new Weapon_Awp;
					Weapon_Awp = GivePlayerItem(client, "weapon_awp");
					SetEntProp(Weapon_Awp, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					SetEntProp(Weapon_Awp, Prop_Send, "m_iClip1", 1);
					AWP[client] = false;
	
					g_iCreditos[client] -= GetConVarInt(cvar_2);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","AWP2", g_iCreditos[client],GetConVarInt(cvar_2));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item awp", g_iCreditos[client],GetConVarInt(cvar_2));
			}
		}
		

		else if ( strcmp(info,"option8") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_3))
			{
				if (IsPlayerAlive(client))
				{

					g_Godmode[client] = true;
					CreateTimer(20.0, OpcionNumero16b, client);

					g_iCreditos[client] -= GetConVarInt(cvar_3);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Imortal2", g_iCreditos[client],GetConVarInt(cvar_3));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item imortal", g_iCreditos[client],GetConVarInt(cvar_3));
			}

		}

		else if ( strcmp(info,"option9") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_4))
			{
				if(!abrir_maximo[client])
				{	
					CPrintToChat(client, "\x0E[ SHOP ] \x04 Você só pode usar este item uma vez por mapa");
				}
				else if(abrir_maximo[client] && IsPlayerAlive(client))
				{

					abrir();
					abrir_maximo[client] = true;
					g_iCreditos[client] -= GetConVarInt(cvar_4);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Jails2", g_iCreditos[client],GetConVarInt(cvar_4));
					decl String:nome[32];
					GetClientName(client, nome, sizeof(nome));

					CPrintToChatAll("\x0E[ SHOP ] \x04O jogador\x03 %s \x04abriu as jails pelo shop!", nome); 
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item jails", g_iCreditos[client],GetConVarInt(cvar_4));
			}
		}

		else if ( strcmp(info,"option10") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_5))
			{
				if (IsPlayerAlive(client))
				{

					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);

					g_iCreditos[client] -= GetConVarInt(cvar_5);
					vampire[client] = true;
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Rapido2", g_iCreditos[client],GetConVarInt(cvar_5));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item rapido", g_iCreditos[client],GetConVarInt(cvar_5));
			}

		}


		else if ( strcmp(info,"option12") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_6))
			{
				if (IsPlayerAlive(client))
				{
					
					g_iCreditos[client] -= GetConVarInt(cvar_6);
					
					new vida = (GetClientHealth(client) + 150);

					SetEntityHealth(client, vida);
					GivePlayerItem( client, "item_assaultsuit"); // Give Kevlar Suit and a Helmet
					SetEntProp( client, Prop_Send, "m_ArmorValue", 100, 1 ); // Set kevlar armour
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","HP2", g_iCreditos[client],GetConVarInt(cvar_6));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da vida", g_iCreditos[client],GetConVarInt(cvar_6));
			}
		}


		else if ( strcmp(info,"option13") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_7))
			{
				if(!EAGLE[client])
				{	
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","MaximoEAGLE");
				}
				
				else if(EAGLE[client] && IsPlayerAlive(client))
				{
					new Pistol_Eagle;
					Pistol_Eagle = GivePlayerItem(client, "weapon_deagle");
					SetEntProp(Pistol_Eagle, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					SetEntProp(Pistol_Eagle, Prop_Send, "m_iClip1", 7);
					EAGLE[client] = false;
					
					
					g_iCreditos[client] -= GetConVarInt(cvar_7);
					

					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Eagle2", g_iCreditos[client],GetConVarInt(cvar_7));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da eagle", g_iCreditos[client],GetConVarInt(cvar_7));
			}
		}

		else if ( strcmp(info,"option14") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_8))
			{
				if (IsPlayerAlive(client))
				{
					decl String:sGame[255];
					GetGameFolderName(sGame, sizeof(sGame));
					if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knife");	
						EquipPlayerWeapon(client, knife);
						
						super_faca[client] = true;
					}
					
					else if (StrEqual(sGame, "csgo"))
					{
						new currentknife = GetPlayerWeaponSlot(client, 2);
						if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
						{
							RemovePlayerItem(client, currentknife);
							RemoveEdict(currentknife);
						}
						
						new knife = GivePlayerItem(client, "weapon_knifegg");	
						EquipPlayerWeapon(client, knife);
						
						super_faca[client] = true;
					}
					
				
					g_iCreditos[client] -= GetConVarInt(cvar_8);
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Super2", g_iCreditos[client],GetConVarInt(cvar_8));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da super faca", g_iCreditos[client],GetConVarInt(cvar_8));
			}
		}

		else if ( strcmp(info,"option15") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_9))
			{
				if (IsPlayerAlive(client))
				{
					new health = GetEntProp(client, Prop_Send, "m_iHealth");  
					
					if(health >= 100)
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04 Mas sua vida ja esta cheia '-'");
					}
					else
					{
						SetEntityHealth(client, 100);
						g_iCreditos[client] -= GetConVarInt(cvar_9);
						
						EmitSoundToAllAny("medicsound/medic.wav");  
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Curar2", g_iCreditos[client],GetConVarInt(cvar_9));
					}


				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item de curar", g_iCreditos[client],GetConVarInt(cvar_9));
			}
		}

		else if ( strcmp(info,"option16") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_10))
			{
				if (IsPlayerAlive(client))
				{

					GivePlayerItem(client, "weapon_molotov");
					GivePlayerItem(client, "weapon_flashbang");
					GivePlayerItem(client, "weapon_flashbang");

					g_iCreditos[client] -= GetConVarInt(cvar_10);
					

					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Molotov2", g_iCreditos[client],GetConVarInt(cvar_10));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da molotov", g_iCreditos[client],GetConVarInt(cvar_10));
			}
		}
			
		
		else if ( strcmp(info,"option17") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_11))
			{
				if (IsPlayerAlive(client))
				{
					g_iCreditos[client] -= GetConVarInt(cvar_11);
					SetEntityModel(client, "models/player/ctm_fbi_varianta.mdl");
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Skin2", g_iCreditos[client],GetConVarInt(cvar_11));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}
					

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da skin", g_iCreditos[client],GetConVarInt(cvar_11));
			}
		}
		
		else if ( strcmp(info,"option18") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_12))
			{
				if (IsPlayerAlive(client))
				{

					GivePlayerItem(client, "weapon_smokegrenade");
					
					
					g_iCreditos[client] -= GetConVarInt(cvar_12);
					
					
					poison[client] = true;
					
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Smoke2", g_iCreditos[client],GetConVarInt(cvar_12));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da smoke", g_iCreditos[client],GetConVarInt(cvar_12));
			}

		}
		
		
					
		else if ( strcmp(info,"option20") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_14))
			{
				if (IsPlayerAlive(client))
				{

					GivePlayerItem(client, "weapon_smokegrenade");
					
					
					g_iCreditos[client] -= GetConVarInt(cvar_14);
					
					
					view[client] = true;
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Teletransportadora", g_iCreditos[client],GetConVarInt(cvar_14));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da teletransportadora", g_iCreditos[client],GetConVarInt(cvar_14));
			}

		}
		
		else if ( strcmp(info,"option21") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_16))
			{
				if (IsPlayerAlive(client))
				{

					GivePlayerItem(client, "weapon_hegrenade");
					
					
					g_iCreditos[client] -= GetConVarInt(cvar_16);
					
					
					fogo[client] = true;
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","HE2", g_iCreditos[client],GetConVarInt(cvar_16));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da he2", g_iCreditos[client],GetConVarInt(cvar_16));
			}	
		}
		
		else if ( strcmp(info,"option22") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_17))
			{
				if (IsPlayerAlive(client))
				{

					g_iCreditos[client] -= GetConVarInt(cvar_17);
					
					
					bhop[client] = true;
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Bhop2", g_iCreditos[client],GetConVarInt(cvar_17));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item do bhop", g_iCreditos[client],GetConVarInt(cvar_17));
			}	
		}
		
		else if ( strcmp(info,"option23") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_18))
			{
				if (IsPlayerAlive(client))
				{

					g_iCreditos[client] -= GetConVarInt(cvar_18);
					
					
					SetEntityGravity(client, 0.6);
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Gravity2", g_iCreditos[client],GetConVarInt(cvar_18));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da gravidade", g_iCreditos[client],GetConVarInt(cvar_18));
			}
			
		}
		
		else if ( strcmp(info,"option24") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_19))
			{
				if (IsPlayerAlive(client))
				{
					new Taser;
					Taser = GivePlayerItem(client, "weapon_taser");
					SetEntProp(Taser, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					SetEntProp(Taser, Prop_Send, "m_iClip1", 3);
					
					g_iCreditos[client] -= GetConVarInt(cvar_19);
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Taser2", g_iCreditos[client],GetConVarInt(cvar_19));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item da taser", g_iCreditos[client],GetConVarInt(cvar_19));
			}
			
		}
		
		else if ( strcmp(info,"option25") == 0 ) 
		{
			DID(client);
			
			if (g_iCreditos[client] >= GetConVarInt(cvar_20))
			{
				if (IsPlayerAlive(client))
				{
					Spell[client] = true;
					g_iCreditos[client] -= GetConVarInt(cvar_20);
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Kedavra2", g_iCreditos[client],GetConVarInt(cvar_20));
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Vivo");
				}

			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Item do poder", g_iCreditos[client],GetConVarInt(cvar_20));
			}
		}
	}
}


public Action:SetCreditos2(client, args)
{
    if(client == 0)
    {
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
    }

    if(args < 2) 
    {
        ReplyToCommand(client, "[SM] Use: sm_set <#userid|name> [amount]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);

    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 

   
    decl String:strTargetName[MAX_TARGET_LENGTH]; 
    decl TargetList[MAXPLAYERS], TargetCount; 
    decl bool:TargetTranslate; 

    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
    { 
          ReplyToTargetError(client, TargetCount); 
          return Plugin_Handled; 
    } 

   
    for (new i = 0; i < TargetCount; i++) 
    { 
        new iClient = TargetList[i]; 
        if (IsClientInGame(iClient)) 
        { 
            g_iCreditos[iClient] = amount;
            CPrintToChat(iClient, "[ SHOP ] Set \x03%i \x01credits in the player: %N", amount, iClient);
        } 
    } 

    return Plugin_Continue;
}

public Action:RemoveCredits(client, args)
{
    if(client == 0)
    {
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
    }
   
    for (new i = 1; i <= GetMaxClients(); i++)
	{	
        if(IsClientInGame(i))
		{	
			g_iCreditos[i] = 0;		  
			CPrintToChat(i, "[ SHOP ] \x04 REMOVED ALL PLAYERS CREDITS");
		}
	}

    return Plugin_Continue;
}

public Action:SetCreditos(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}

	if(args < 2) 
	{
		ReplyToCommand(client, "[SM] Use: sm_give <#userid|name> [amount]");
		return Plugin_Handled;
	}

	decl String:arg2[10];

	GetCmdArg(2, arg2, sizeof(arg2));

	new amount = StringToInt(arg2);

	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 


	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
										   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		  ReplyToTargetError(client, TargetCount); 
		  return Plugin_Handled; 
	} 


	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{ 
			  g_iCreditos[iClient] += amount;
			  
			  CPrintToChat(iClient, "[ SHOP ] Give \x03%i \x01credits in the player: %N", amount, iClient);

		} 
	} 

	return Plugin_Continue;
}

public Action:Command_SendCredits(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}

	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Use: sm_gift <#userid|name> [amount]");
		return Plugin_Handled;
	}

	decl String:arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));

	new amount = StringToInt(arg2);

	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
		strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < TargetCount; i++)
	{
		new iClient = TargetList[i];
		if (IsClientInGame(iClient) && amount > 0)
		{
			if (g_iCreditos[client] < amount)
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t","NoCredits");
			else
			{
				g_iCreditos[client] -= amount;
				g_iCreditos[iClient] += amount;
			
				CPrintToChat(client, "[ SHOP ] You give \x03%i \x01credits for player: %N", amount, iClient);
				CPrintToChat(iClient, "[ SHOP ] You get \x03%i \x01credits from player: %N", amount, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_Godmode[victim] == true)
	{
	   damage = 0.0;
	   return Plugin_Changed;
	}
	else if(IsValidClient(attacker))
	{
		if((vampire[attacker] && GetClientTeam(attacker) != GetClientTeam(victim) && super_faca[attacker] == false))
		{
			new recibir = RoundToFloor(damage * 0.5);
			recibir += GetClientHealth(attacker);
			SetEntityHealth(attacker, recibir);
		}
		
		if(super_faca[attacker])
		{
			decl String:weaponName[255];
			GetClientWeapon(attacker, weaponName, sizeof(weaponName));
			decl String:sGame[255];
			GetGameFolderName(sGame, sizeof(sGame));
			if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
			{
				if(StrEqual(weaponName, "weapon_knife"))
				{
					DealDamage(victim,100,attacker,DMG_BULLET,weaponName);
				}
			}
			else if (StrEqual(sGame, "csgo"))
			{
				if(StrEqual(weaponName, "weapon_knifegg"))
				{
					DealDamage(victim,100,attacker,DMG_BULLET,weaponName);
				}
			}
			
		}
		
	}

	return Plugin_Continue;
}


stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false; 
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	if (IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (water <= 1)
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if(bhop[client] == true)
						{
							buttons &= ~IN_JUMP;	
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}



public Action:OnWeaponCanUse(client, weapon)
{
	if (g_Ivisivel[client])
	{
		decl String:sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientPostAdminCheck(client)
{
	g_Godmode[client] = false;
	g_Ivisivel[client] = false;
	fogo[client] = false;
	super_faca[client] = false;
	poison[client] = false;
	Spell[client] = false;
	vampire[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
	view[client] = false;
	infinita[client] = false;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
		{
			poison[i] = false;
			vampire[i] = false;
			view[i] = false;
			Spell[i] = false;
			fogo[i] = false;
			super_faca[i] = false;
			bhop[i] = false;
			AWP[i] = true;
			EAGLE[i] = true;
			infinita[i] = false;
		}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}
	Normalizar(client);
	CreateTimer(1.0, MensajesSpawn, client);
	
}

Normalizar(client)
{
	if (g_Godmode[client])
	{
		g_Godmode[client] = false;
	}
	if (g_Ivisivel[client])
	{
		g_Ivisivel[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);  
	}
	if (infinita[client])
	{
		infinita[client] = false;
	}
	poison[client] = false;
	vampire[client] = false;
	view[client] = false;
	fogo[client] = false;
	Spell[client] = false;
	super_faca[client] = false;
	bhop[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;	
}


public OnAvailableLR(Announced)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			
			if(GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1) ) 
				if (IsPlayerReservationAdmin(i))
					g_iCreditos[i] += GetConVarInt(cvarCreditos_LR_VIP);
				else 
					g_iCreditos[i] += GetConVarInt(cvarCreditos_LR);
			SetEntityGravity(i, 1.0);
			Normalizar(i);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}


public Action:OpcionNumero16b(Handle:timer, any:client)
{
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
	   CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Mortal3");
	   g_Godmode[client] = false;
	}
  
}

public Action:Invisible(Handle:timer, any:client)
{
 if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
 {
   g_Ivisivel[client] = false;
   CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Visivel novamente");
   SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);  
 }
}

public Action:Invisible2(Handle:timer, any:client)
{
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t","Visivel novamente");
		SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
		g_Ivisivel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
}

public Action:abrir()
{
    SJD_OpenDoors(); 
}


public Action:Hook_SetTransmit(entity, client)  
{  
    if (entity != client)  
        return Plugin_Handled; 
      
    return Plugin_Continue;  
} 


public Action:Command_ShowCredits(client, args) 
{
	decl String:sName[MAX_NAME_LENGTH], String:sUserId[10];
	
	new Handle:menu = CreateMenu(MenuHandlerShowCredits);
	SetMenuTitle(menu, "%t","Players Credits");
	
	for(new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, sName, sizeof(sName));
			IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s: %d", sName, g_iCreditos[i]);
			AddMenuItem(menu, sUserId, buffer, ITEMDRAW_DISABLED );			//sUserID to id_usera, a sName to nick ktory sie wyswietla w Menu
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerShowCredits(Handle:menu, MenuAction:action, param1, param2)
{
	
}

GetAllPlayersCount()
{
  decl iCount, i; iCount = 0;

  for( i = 1; i <= MaxClients; i++ )
    if( IsClientInGame( i ) && !IsFakeClient(i) )
      iCount++;
  return iCount;
} 

bool:IsPlayerReservationAdmin(client)
{
    if (CheckCommandAccess(client, "Admin_Reservation", ADMFLAG_RESERVATION, false))
    {
        return true;
    }
    return false;
}

public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && (infinita[client]))
		{
			Client_ResetAmmo(client);
		}
	}
}

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
		SetEntData(zomg, clip1Offset, 200, 4, true);
	if (clip2Offset != -1 && zomg != -1)
		SetEntData(zomg, clip2Offset, 200, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, priAmmoTypeOffset, 200, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, secAmmoTypeOffset, 200, 4, true);
}