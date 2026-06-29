#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>
#include <clientprefs>
#include <smlib> 
#include <sdkhooks>

#pragma semicolon 1

new bool:g_Ivisivel[MAXPLAYERS+1] = {false, ...};
new bool:g_Fly[MAXPLAYERS+1] = {false, ...};
new bool:g_Godmode[MAXPLAYERS+1] = {false, ...};
new bool:poison[MAXPLAYERS+1] = {false, ...};
new bool:vampire[MAXPLAYERS+1] = {false, ...};
new bool:super_faca[MAXPLAYERS+1] = {false, ...};
new bool:view[MAXPLAYERS+1] = {false, ...};
new bool:fogo[MAXPLAYERS+1] = {false, ...};
new bool:AWP[MAXPLAYERS+1] = {true,...};
new bool:EAGLE[MAXPLAYERS+1] = {true, ...};


#define VERSION "Private version"

new g_iCreditos[MAXPLAYERS+1];

new iEnt;
new String:EntityList[][] = {
	
	"func_door",
	"func_rotating",
	"func_walltoggle",
    "func_breakable",
	"func_door_rotating",
	"func_movelinear",
	"prop_door",
	"prop_door_rotating",
	"func_tracktrain",
	"func_elevator",
	"\0"
};


new Handle:cvarCreditosMax = INVALID_HANDLE;
new Handle:cvarCreditosKill_CT = INVALID_HANDLE;
new Handle:cvarCreditosKill_T = INVALID_HANDLE;
new Handle:cvarCreditos_LR = INVALID_HANDLE;
new Handle:cvarCreditosSave = INVALID_HANDLE;
new Handle:cvarTronly = INVALID_HANDLE;
new Handle:cvarSpawnMsg = INVALID_HANDLE;
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
new Handle:cvar_13;
new Handle:cvar_14;
new Handle:cvar_15;
new Handle:cvar_16;

//new Handle:cvarRoundCreditos = INVALID_HANDLE;
//new Handle:cvarCrInterval = INVALID_HANDLE;

new Handle:c_GameCreditos = INVALID_HANDLE;

new g_sprite;
new g_HaloSprite;

public Plugin:myinfo =
{
    name = "Shop Jail",
    author = "Dk--",
    description = "Comprar itens no shop jailbreak",
    version = VERSION,
};

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
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);	
	// ======================================================================

	RegConsoleCmd("sm_shop", SHOPMENU);
	RegConsoleCmd("sm_credits", Creditos);
	RegConsoleCmd("sm_revive", Reviver);
	RegConsoleCmd("drop", Utilidade);
	RegAdminCmd("sm_give", SetCreditos, ADMFLAG_ROOT);
	RegAdminCmd("sm_set", SetCreditos2, ADMFLAG_ROOT);
	RegAdminCmd("sm_showcredits", Command_ShowCredits, ADMFLAG_ROOT);

	
	// ======================================================================

	// ======================================================================

	cvarCreditosMax = CreateConVar("shop_creditos_maximo", "50000", "Maxim of credits for player");
	cvarCreditosKill_T = CreateConVar("shop_creditos_por_kill_t", "3", "Amount of credits for kill ( prisioner )");
	cvarCreditosKill_CT = CreateConVar("shop_creditos_por_kill_ct", "1", "Amount of credits for kill ( guard )");
	cvarCreditos_LR = CreateConVar("shop_creditos_por_kill_lr", "300", "Amount of credits for the last player");
	cvarSpawnMsg = CreateConVar("shop_spawnmessages", "1", "Messages on spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCreditosSave = CreateConVar("shop_creditos_save", "1", "Save or not credits on player disconnect", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTronly = CreateConVar("shop_terrorist_only", "1", "Menu for only prisioners", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_1 = CreateConVar("preco_01", "7000", "Price of item (invisible)");
	cvar_2 = CreateConVar("preco_02", "2000", "Price of item (awp)");
	cvar_3 = CreateConVar("preco_03", "7000", "Price of item (imortal)");
	cvar_4 = CreateConVar("preco_04", "800", "Price of item (open jails)");
	cvar_5 = CreateConVar("preco_05", "4000", "Price of item (more fast)");
	cvar_6 = CreateConVar("preco_06", "3500", "Price of item (hp)");
	cvar_7 = CreateConVar("preco_07", "2000", "Price of item (eagle)");
	cvar_8 = CreateConVar("preco_08", "1500", "Price of item (super knife)");
	cvar_9 = CreateConVar("preco_09", "50", "Price of item (healing)");
	cvar_10 = CreateConVar("preco_10", "650", "Price of item (molotov)");
	cvar_11 = CreateConVar("preco_11", "7000", "Price of item (skin)");
	cvar_12 = CreateConVar("preco_12", "1000", "Price of item (poison smoke)");
	cvar_13 = CreateConVar("preco_13", "1600", "Price of item (become a bird)");
	cvar_14 = CreateConVar("preco_14", "8000", "Price of item (smoke teleport)");
	cvar_15 = CreateConVar("preco_15", "8000", "Price of item (respawn)");
	cvar_16 = CreateConVar("preco_16", "2000", "Price of item (he with fire)");
	

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
	
	AutoExecConfig(true, "sm_shopjail");
	
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
	PrecacheModel("models/chicken/chicken.mdl");			
	PrecacheModel("models/player/ctm_gign_variantc.mdl");
}


public Action:MensajesSpawn(Handle:timer, any:client)
{
	if(GetConVarBool(cvarSpawnMsg) && IsClientInGame(client))
	{
		PrintToChat(client, "\x04[ SHOP ] \x05%t","Kill");
		PrintToChat(client, "\x04[ SHOP ] \x05%t","Type");
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(2.0, MensajesMuerte, client);
	
	if (g_Fly[client])
	{
		g_Fly[client] = false;
		SetThirdPersonView(client, false);
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityModel(client, "models/player/tm_phoenix_variantc.mdl");
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			SetEntityModel(client, "models/player/ctm_gign_variantc.mdl");
		}
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	
	if (!attacker)
		return;

	if (attacker == client)
		return;

	if(!GetConVarBool(cvarCreditosKill_CT))
		return;
	
	if(!GetConVarBool(cvarCreditosKill_T))
		return;

	if(GetClientTeam(attacker) == CS_TEAM_CT)
	{
		g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_CT);
	}
	
	if(GetClientTeam(attacker) == CS_TEAM_T)
	{
		g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_T);
	}

	if (g_iCreditos[attacker] < GetConVarInt(cvarCreditosMax))
	{
		if(GetClientTeam(attacker) == CS_TEAM_CT)
		{
			PrintToChat(client, "\x04[ SHOP ] \x05%t","KillCT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_CT));
		}
	
		if(GetClientTeam(attacker) == CS_TEAM_T)
		{
			PrintToChat(client, "\x04[ SHOP ] \x05%t","KillT", g_iCreditos[attacker],GetConVarInt(cvarCreditosKill_T));
		}
		
		
	}
	else
	{
		g_iCreditos[attacker] = GetConVarInt(cvarCreditosMax);
		PrintToChat(client, "\x04[ SHOP ] \x05%t","Maximo", g_iCreditos[attacker]);
	}
}

public Action:MensajesMuerte(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
	PrintToChat(client, "\x04[ SHOP ] \x05%t","Reviver4",GetConVarInt(cvar_15));
 }
}

public Action:Creditos(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
        PrintToChat(client, "\x04[ SHOP ] \x05%t","Creditos", g_iCreditos[client]);
}

public Action:SHOPMENU(client,args)
{
	if(GetConVarBool(cvarTronly))
	{
		if(GetClientTeam(client) != 2)
		{
			 PrintToChat(client, "\x04[ SHOP ] \x05%t","Prisioneiros");
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
	PrintToChat(client, "\x04[ SHOP ] \x05%t","Creditos", g_iCreditos[client]);
}

public Action:Reviver(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
	
	if(GetConVarBool(cvarTronly))
	{
		if(GetClientTeam(client) != 2)
		{
			 PrintToChat(client, "\x04[ SHOP ] \x05%t","Prisioneiros2");
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

					PrintToChatAll("\x04[ SHOP ] \x05O jogador\x03 %s \x05reviveu!", nome); 

				}
				else
				{
					PrintToChat(client, "\x04[ SHOP ] \x05%t","Item reviver", g_iCreditos[client],GetConVarInt(cvar_15));
				}
			}
			else
			{
				PrintToChat(client, "\x04[ SHOP ] \x05%t","Morto");
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

				PrintToChatAll("\x04[ SHOP ] \x05O jogador\x03 %s \x05reviveu!", nome); 

			}
			else
			{
				PrintToChat(client, "\x04[ SHOP ] \x05%t","Item reviver", g_iCreditos[client],GetConVarInt(cvar_15));
			}
		}
		else
		{
			PrintToChat(client, "\x04[ SHOP ] \x05%t","Morto");
		}
	}
}

public Action:Utilidade(client, args)
{
	if(g_Fly[client])
	{
		new MoveType:movetype = GetEntityMoveType(client); 
		if (movetype != MOVETYPE_FLY)
		{
			SetEntityMoveType(client, MOVETYPE_FLY);
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	
	return Plugin_Continue;
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
			IgniteEntity(victim, 5.0);
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

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	poison[client] = false;
	Normalizar(client);
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
		
	Format(opcionmenu, 124, "%T","Jail", clientId,GetConVarInt(cvar_4));
	AddMenuItem(menu, "option9", opcionmenu);
		
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
	
	Format(opcionmenu, 124, "%T","Passaro", clientId,GetConVarInt(cvar_13));
	AddMenuItem(menu, "option19", opcionmenu);
	
	Format(opcionmenu, 124, "%T","Teletransportadora3", clientId,GetConVarInt(cvar_14));
	AddMenuItem(menu, "option20", opcionmenu);
	
	Format(opcionmenu, 124, "%T","HE", clientId,GetConVarInt(cvar_16));
	AddMenuItem(menu, "option21", opcionmenu);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}


public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];

		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option1") == 0 ) 
		{
			{
				DID(client);
				PrintToChat(client,"\x04[ SHOP ] \x05make by dk.");
			}
		}



			else if ( strcmp(info,"option5") == 0 ) 
			{
				{
					DID(client);
					
							
					if (g_iCreditos[client] >= GetConVarInt(cvar_1))
					{
						if (IsPlayerAlive(client))
						{
							decl String:sGame[64];
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
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Invisivel2", g_iCreditos[client],GetConVarInt(cvar_2));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
					}
					else
					{
						PrintToChat(client, "\x04[ SHOP ] \x05%t","Item invisivel", g_iCreditos[client],GetConVarInt(cvar_1));
					}
				}
			
			}

			else if ( strcmp(info,"option6") == 0 ) 
			{
				{
					DID(client);
					if (g_iCreditos[client] >= GetConVarInt(cvar_2))
					{
						if(AWP[client] == false)
						{	
							PrintToChat(client, "\x04[ SHOP ] \x05%t","MaximoAWP");
						}
						else if(AWP[client] == true && IsPlayerAlive(client))
						{	
							GivePlayerItem(client, "weapon_awp");
							AWP[client] = false;
							Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 0, _, 1); 
							g_iCreditos[client] -= GetConVarInt(cvar_2);
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","AWP2", g_iCreditos[client],GetConVarInt(cvar_2));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
					}
					else
					{
						PrintToChat(client, "\x04[ SHOP ] \x05%t","Item awp", g_iCreditos[client],GetConVarInt(cvar_2));
					}
				}
			}
			

			else if ( strcmp(info,"option8") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_3))
					{
						if (IsPlayerAlive(client))
						{

							g_Godmode[client] = true;
							CreateTimer(20.0, OpcionNumero16b, client);

							g_iCreditos[client] -= GetConVarInt(cvar_3);
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Imortal2", g_iCreditos[client],GetConVarInt(cvar_3));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
					}
					else
					{
						PrintToChat(client, "\x04[ SHOP ] \x05%t","Item imortal", g_iCreditos[client],GetConVarInt(cvar_3));
					}
				}

			}

			else if ( strcmp(info,"option9") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_4))
					{
						if (IsPlayerAlive(client))
						{

							abrir();

							g_iCreditos[client] -= GetConVarInt(cvar_4);
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Jails2", g_iCreditos[client],GetConVarInt(cvar_4));
							decl String:nome[32];
							GetClientName(client, nome, sizeof(nome));

							PrintToChatAll("\x04[ SHOP ] \x05O jogador\x03 %s \x05abriu as jails pelo shop!", nome); 
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
					}
					else
					{
						PrintToChat(client, "\x04[ SHOP ] \x05%t","Item jails", g_iCreditos[client],GetConVarInt(cvar_4));
					}
				}

			}

			else if ( strcmp(info,"option10") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_5))
					{
						if (IsPlayerAlive(client))
						{

							SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);

							g_iCreditos[client] -= GetConVarInt(cvar_5);
							vampire[client] = true;
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Rapido2", g_iCreditos[client],GetConVarInt(cvar_5));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
					}
					else
					{
						PrintToChat(client, "\x04[ SHOP ] \x05%t","Item rapido", g_iCreditos[client],GetConVarInt(cvar_5));
					}
				}

			}


			else if ( strcmp(info,"option12") == 0 ) 
			{
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
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","HP2", g_iCreditos[client],GetConVarInt(cvar_6));
						}
							else
							{
								PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
							}
					}
							else
							{
								PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da vida", g_iCreditos[client],GetConVarInt(cvar_6));
							}
				}

			}


			else if ( strcmp(info,"option13") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_7))
					{
						if(EAGLE[client] == false)
						{	
							PrintToChat(client, "\x04[ SHOP ] \x05%t","MaximoEAGLE");
						}
						
						else if(EAGLE[client] == true && IsPlayerAlive(client))
						{
							GivePlayerItem(client, "weapon_deagle");
							EAGLE[client] = false;
							Client_GiveWeaponAndAmmo(client, "weapon_deagle", _, 0, _, 7); 
							
							g_iCreditos[client] -= GetConVarInt(cvar_7);
							

							PrintToChat(client, "\x04[ SHOP ] \x05%t","Eagle2", g_iCreditos[client],GetConVarInt(cvar_7));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da eagle", g_iCreditos[client],GetConVarInt(cvar_7));
						}
				}
			}

			else if ( strcmp(info,"option14") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_8))
					{
						if (IsPlayerAlive(client))
						{
							decl String:sGame[64];
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
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Super2", g_iCreditos[client],GetConVarInt(cvar_8));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da super faca", g_iCreditos[client],GetConVarInt(cvar_8));
						}
				}

			}

			else if ( strcmp(info,"option15") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_9))
					{
						if (IsPlayerAlive(client))
						{
							new health = GetEntProp(client, Prop_Send, "m_iHealth");  
							
							if(health >= 100)
							{
								PrintToChat(client, "\x04[ SHOP ] \x05 Your life already is full '-'");
							}
							else
							{
								SetEntityHealth(client, 100);
								g_iCreditos[client] -= GetConVarInt(cvar_9);
								
								EmitSoundToAll("medicsound/medic.wav");
								PrintToChat(client, "\x04[ SHOP ] \x05%t","Curar2", g_iCreditos[client],GetConVarInt(cvar_9));
							}


						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item de curar", g_iCreditos[client],GetConVarInt(cvar_9));
						}
				}

			}

			else if ( strcmp(info,"option16") == 0 ) 
			{
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
							

							PrintToChat(client, "\x04[ SHOP ] \x05%t","Molotov2", g_iCreditos[client],GetConVarInt(cvar_10));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da molotov", g_iCreditos[client],GetConVarInt(cvar_10));
						}
				}
			}
				
			
			
			else if ( strcmp(info,"option17") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_11))
					{
						if (IsPlayerAlive(client))
						{
							g_iCreditos[client] -= GetConVarInt(cvar_11);
							SetEntityModel(client, "models/player/ctm_gign_variantc.mdl");
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Skin2", g_iCreditos[client],GetConVarInt(cvar_11));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}
							

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da skin", g_iCreditos[client],GetConVarInt(cvar_11));
						}
				}

			}
			
			else if ( strcmp(info,"option18") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_12))
					{
						if (IsPlayerAlive(client))
						{

							GivePlayerItem(client, "weapon_smokegrenade");
							
							
							g_iCreditos[client] -= GetConVarInt(cvar_12);
							
							
							poison[client] = true;
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Smoke2", g_iCreditos[client],GetConVarInt(cvar_12));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da smoke", g_iCreditos[client],GetConVarInt(cvar_12));
						}
				}

			}
			
			else if ( strcmp(info,"option19") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_13))
					{
						if (IsPlayerAlive(client))
						{
							g_iCreditos[client] -= GetConVarInt(cvar_13);				
							
							SetEntityMoveType(client, MOVETYPE_FLY);
							SetThirdPersonView(client, true);
							
							decl String:sGame[64];
							GetGameFolderName(sGame, sizeof(sGame));
							if (StrEqual(sGame, "cstrike"))
							{
								if (GetClientTeam(client) == CS_TEAM_CT)
								{
									SetEntityModel(client, "models/pigeon.mdl");
								}
								else
								{
									SetEntityModel(client, "models/crow.mdl");
								}
							}
							else if (StrEqual(sGame, "csgo"))
							{
								SetEntityModel(client, "models/chicken/chicken.mdl");
							}
							
							g_Fly[client] = true;		
							
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Passaro2", g_iCreditos[client],GetConVarInt(cvar_13));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item do passaro", g_iCreditos[client],GetConVarInt(cvar_13));
						}
				}

			}
			
						
			else if ( strcmp(info,"option20") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_14))
					{
						if (IsPlayerAlive(client))
						{

							GivePlayerItem(client, "weapon_smokegrenade");
							
							
							g_iCreditos[client] -= GetConVarInt(cvar_14);
							
							
							view[client] = true;
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Teletransportadora", g_iCreditos[client],GetConVarInt(cvar_14));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da teletransportadora", g_iCreditos[client],GetConVarInt(cvar_14));
						}
				}

			}
			
			else if ( strcmp(info,"option21") == 0 ) 
			{
				{
					DID(client);
					
					if (g_iCreditos[client] >= GetConVarInt(cvar_16))
					{
						if (IsPlayerAlive(client))
						{

							GivePlayerItem(client, "weapon_hegrenade");
							
							
							g_iCreditos[client] -= GetConVarInt(cvar_16);
							
							
							fogo[client] = true;
							PrintToChat(client, "\x04[ SHOP ] \x05%t","HE2", g_iCreditos[client],GetConVarInt(cvar_16));
						}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Vivo");
						}

					}
						else
						{
							PrintToChat(client, "\x04[ SHOP ] \x05%t","Item da he2", g_iCreditos[client],GetConVarInt(cvar_16));
						}
				}
				
			}
	}
}

bool:SetThirdPersonView(client, bool:third)
{
	if(third)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		return true;
	}
	else if(!third)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		return true;
	}
	return false;
}

public Action:SetCreditos2(client, args)
{
    if(client == 0)
    {
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
    }

    if(args < 2) // Not enough parameters
    {
        ReplyToCommand(client, "[SM] Use: sm_set <#userid|name> [amount]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    //GetCmdArg(1, arg, sizeof(arg));
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);
    //new target;

    //decl String:patt[MAX_NAME]

    //if(args == 1) 
    //{ 
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
              PrintToChat(client, "[ SHOP ] Set \x03%i \x01credits in player: %N", amount, iClient);
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

    if(args < 2) // Not enough parameters
    {
        ReplyToCommand(client, "[SM] Use: sm_give <#userid|name> [amount]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    //GetCmdArg(1, arg, sizeof(arg));
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);
    //new target;

    //decl String:patt[MAX_NAME]

    //if(args == 1) 
    //{ 
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
              PrintToChat(client, "[ SHOP ] Give \x03%i \x01credits for player: %N", amount, iClient);
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
		if(vampire[attacker])
		{
			new recibir = RoundToFloor(damage * 0.5);
			recibir += GetClientHealth(attacker);
			SetEntityHealth(attacker, recibir);
		}
		
		if(super_faca[attacker])
		{
			decl String:weaponName[64];
			GetClientWeapon(attacker, weaponName, sizeof(weaponName));
			decl String:sGame[64];
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

public Action:OnWeaponCanUse(client, weapon)
{
	if (g_Ivisivel[client])
	{
		decl String:sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
		return Plugin_Handled;
	}
	
	if (g_Fly[client])
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
	g_Godmode[client] = false;
	g_Ivisivel[client] = false;
	poison[client] = false;
	vampire[client] = false;
	super_faca[client] = false;
	view[client] = false;
	fogo[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
}

public OnClientPostAdminCheck(client)
{
	g_Godmode[client] = false;
	g_Ivisivel[client] = false;
	fogo[client] = false;
	super_faca[client] = false;
	poison[client] = false;
	vampire[client] = false;
	g_Fly[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
	view[client] = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}

	CreateTimer(1.0, MensajesSpawn, client);
	Normalizar(client);
}

Normalizar(client)
{
	if (g_Fly[client])
	{
		g_Fly[client] = false;
		SetThirdPersonView(client, false);
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityModel(client, "models/player/tm_phoenix_variantc.mdl");
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			SetEntityModel(client, "models/player/ctm_gign_variantc.mdl");
		}
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	if (g_Godmode[client])
	{
		g_Godmode[client] = false;
	}
	if (g_Ivisivel[client])
	{
		g_Ivisivel[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);  
	}

	poison[client] = false;
	vampire[client] = false;
	view[client] = false;
	fogo[client] = false;
	super_faca[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
}


public OnAvailableLR(Announced)
{
	for (new i = 1; i < GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			g_iCreditos[i] += GetConVarInt(cvarCreditos_LR);
			Normalizar(i);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}


public Action:OpcionNumero16b(Handle:timer, any:client)
{
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
	   PrintToChat(client, "\x04[ SHOP ] \x05%t","Mortal3");
	   g_Godmode[client] = false;
	}
  
}

public Action:Invisible(Handle:timer, any:client)
{
 if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
 {
   g_Ivisivel[client] = false;
   PrintToChat(client, "\x04[ SHOP ] \x05%t","Visivel novamente");
   SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);  
 }
}

public Action:Invisible2(Handle:timer, any:client)
{
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
		PrintToChat(client, "\x04[ SHOP ] \x05%t","Visivel novamente");
		SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
		g_Ivisivel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
}

public Action:abrir()
{
    for(new i = 0; i < sizeof(EntityList); i++)
        while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            AcceptEntityInput(iEnt, "Open");
    return Plugin_Handled;
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
	SetMenuTitle(menu, "Players Credits:.");
	
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
