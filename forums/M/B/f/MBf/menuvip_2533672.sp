/*

 * ===================================

 * -------- VIP MENU BY KRIAX --------

 * ===================================

 *

 * ------ VERSION 1.1 ------

 * - HEALTH

 * - ARMOR

 * - SPEED

 * - MONEY

 * - USP

 * - GRENADE

 * - FLASH

 *

 * ------------ VERSION 1.2  ------------

 * - EUPLOADING GRAVITY

 * - EUPLOADING CLAN TAG

 * 

 * ------------ VERSION 1.3 ------------

 * - ADDING CVAR FOR ENABLE / DESABLE

 * - FIXED BUG GRAVITY

 * - ADDING REGENERATION

 * - ADDING 3 ADVERTS

 * - ADDING DE PREFIX

 * - ADDING CVAR FOR CLAN TAG

 *

 * ------------ VERSION 1.4 ------------

 * - CHOICE OF OPPENING --> 1X - 2X - 3X - 4X - ... <--

 * - CHANGE COLOR

 * - ADDING VIP NAME

 * - ADDING THIRDPERSON

 * - ADDING TRANSPARENCY

 * - ADDING RESPAWN

 *

 * ===================================

 * ------------- CERDITS -------------

 * ===================================

 *

 * - THANX INEX FOR VERSION 1.1

 * - THANX RAIDEN FOR VERSION 1.2

 * - THANX GHOST FOR ALL THE ASSISTANCE

 */

 

#pragma semicolon 1



#include <sourcemod>

#include <sdktools>

#include <cstrike>

#include <playername>

#include <smlib>

#include <morecolors>



#define INFO_VERSION "1.4"



public Plugin:myinfo = 

{

    name = "*~ Menu Vip ~*",

    author = "*~ Kriax ~*",

    description = "Advantage Menu -Flag O-",

    version = INFO_VERSION,

}



new Handle:g_iHealth = INVALID_HANDLE;

new Handle:g_iArmor = INVALID_HANDLE;

new Handle:g_iSpeed = INVALID_HANDLE;

new Handle:g_iMoney = INVALID_HANDLE;

new Handle:g_iGravity = INVALID_HANDLE;

new Handle:Active_Vie = INVALID_HANDLE;

new Handle:Active_Armure = INVALID_HANDLE;

new Handle:Active_Usp = INVALID_HANDLE;

new Handle:Active_Grenade = INVALID_HANDLE;

new Handle:Active_Smoke = INVALID_HANDLE;

new Handle:Active_Vitesse = INVALID_HANDLE;

new Handle:Active_Argent = INVALID_HANDLE;

new Handle:Active_Gravite = INVALID_HANDLE;

new Handle:Active_Regeneration = INVALID_HANDLE;

new Handle:Active_Rien = INVALID_HANDLE;

new Handle:Active_Advert = INVALID_HANDLE;

new Handle:Active_Clan_Tag = INVALID_HANDLE;

new Handle:Active_Vip_Name = INVALID_HANDLE;

new Handle:Active_Transparance = INVALID_HANDLE;

new Handle:Active_ThirdPerson = INVALID_HANDLE;

new Handle:Active_Respawn = INVALID_HANDLE;

new Handle:adverts_info = INVALID_HANDLE;

new Handle:adverts_info2 = INVALID_HANDLE;

new Handle:g_tagteam = INVALID_HANDLE;

new Handle:g_menu = INVALID_HANDLE; 

new Handle:g_hRegenTimer[MAXPLAYERS + 1];

new Handle:g_Interval;

new Handle:g_MaxHP;

new Handle:g_Inc;

new Handle:g_hVip;



new String:g_sVip[64];

new String:TagTeam[64];

new String:info[64];

new String:steamid[64];



new Float:iGravity = 1.0;

new Float:iSpeed = 0.5;



new bool:IsValideRegen[MAXPLAYERS+1] = false;

new bool:HasMenu[MAXPLAYERS] = false;

new bool:HasUseMenu[MAXPLAYERS] = false;



new Vie = 0;

new Armure = 0;

new Usp = 0;

new Grenade = 0;

new Smoke = 0;

new Vitesse = 0;

new Argent = 0;

new Gravite = 0;

new Regeneration = 0;

new Rien = 0;

new Advert = 0;

new Clan_Tag = 0;

new Vip_Name = 0;

new Transparance = 0;

new iHealth = 0;

new iArmor = 0;

new iMoney = 0;

new menuv = 0;  

new ThirdPerson = 0;

new Respawn = 0;

new menu_times[MAXPLAYERS] = 0;

new PlayerRespawn[MAXPLAYERS+1];



public OnMapStart()

{

	CreateTimer(120.0, advert, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(240.0, advert2, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

}



public OnPluginStart()

{

	HookEvent("round_start", OnRoundStart);

	HookEvent("player_spawn", OnPlayerSpawn);

	HookEvent("player_hurt", OnPlayerHurt);



	RegConsoleCmd("sm_vipmenu", menuvip, "Affiche les avantages VIP");

	RegConsoleCmd("sm_vipspawn", VipRespawn, "Commande de respawn");



	g_menu = CreateConVar("sm_vip_menu", "1", "How many times you can use the menu");

	Active_Vie = CreateConVar( "sm_vip_active_vie", "1", "Enable advantage of life");

	Active_Armure = CreateConVar( "sm_vip_active_armure", "1", "Enable advantage of armor");

	Active_Usp = CreateConVar( "sm_vip_active_usp", "1", "Enable advantage of usp");

	Active_Grenade = CreateConVar( "sm_vip_active_grenade", "1", "Enable advantage of grenade");

	Active_Smoke = CreateConVar( "sm_vip_active_smoke", "1", "Enable advantage of smoke");

	Active_Vitesse = CreateConVar( "sm_vip_active_vitesse", "1", "Enable advantage of speed");

	Active_Argent = CreateConVar( "sm_vip_active_argent", "1", "Enable advantage of money");

	Active_Gravite = CreateConVar( "sm_vip_active_gravite", "1", "Enable advantage of gravity");

	Active_Regeneration = CreateConVar( "sm_vip_active_regeneration", "1", "Enable advantage of regeneration");

	Active_Rien = CreateConVar( "sm_vip_active_rien", "1", "Enable the option to leave the menu");

	Active_Clan_Tag = CreateConVar( "sm_vip_active_clant_tag", "1", "Enable clan tag vip / / Preferable without Vip Name");

	Active_Vip_Name = CreateConVar( "sm_vip_active_vipname", "1", "Enable Vipname [VIP] // Preferable without Clan Tag");

	Active_Advert = CreateConVar( "sm_vip_active_advert", "1", "Enable advert - Benefits you and become a VIP now !");

	Active_Transparance = CreateConVar( "sm_vip_active_transparance", "1", "Enable transparency");

	Active_ThirdPerson = CreateConVar( "sm_vip_active_thirdperson", "1", "Enable ThirdPerson");

	Active_Respawn = CreateConVar( "sm_vip_active_respawn", "1", "Enable respawn");



	g_iHealth = CreateConVar( "sm_vip_health", "120", "Quantity of life");

	g_iArmor = CreateConVar( "sm_vip_armor", "120", "Quantity of armor");

	g_iSpeed = CreateConVar( "sm_vip_speed", "1.3", "QQuantity of speed");

	g_iMoney = CreateConVar( "sm_vip_money", "16000", "Quantity of money");

	g_iGravity = CreateConVar( "sm_vip_gravity", "0.5", "Quantity of gravity");

	g_tagteam = CreateConVar( "sm_vip_tagteam", "[VIP]", "Prefix that will appear in your automatic sentences");

	g_Interval = CreateConVar("sm_vip_regen_interval", "1.0", "After how long HP regenerated in second");

	g_MaxHP = CreateConVar("sm_vip_regen_maxhp", "100", "Max d'HP regen");

	g_Inc = CreateConVar("sm_vip_regen_inc", "5", "How much HP will be added to the regeneration");

	g_hVip = CreateConVar("sm_vip_tag", ".::VIP::.", "Clan Tag");



	adverts_info = CreateConVar("sm_vip_adverts", "1", "Enables advert Information not forget to open the menu.");

	adverts_info2 = CreateConVar("sm_vip_adverts2", "1", "Enables the advert information to become vip.");



	GetConVarString(g_hVip, g_sVip, sizeof(g_sVip)); 

	menuv = GetConVarInt(g_menu);



	AutoExecConfig(true, "vip_menu");

}



public OnConfigsExecuted()

{

	iHealth = GetConVarInt(g_iHealth);

	iArmor = GetConVarInt(g_iArmor);

	iMoney = GetConVarInt(g_iMoney);

	iSpeed = GetConVarFloat(g_iSpeed);

	iGravity = GetConVarFloat(g_iGravity);



	Vie = GetConVarInt(Active_Vie);

	Armure = GetConVarInt(Active_Armure);

	Usp = GetConVarInt(Active_Usp);

	Grenade = GetConVarInt(Active_Grenade);

	Smoke = GetConVarInt(Active_Smoke);

	Vitesse = GetConVarInt(Active_Vitesse);

	Argent = GetConVarInt(Active_Argent);

	Gravite = GetConVarInt(Active_Gravite);

	Regeneration = GetConVarInt(Active_Regeneration);

	Rien = GetConVarInt(Active_Rien);

	Advert = GetConVarInt(Active_Advert);

	Clan_Tag = GetConVarInt(Active_Clan_Tag);

	Vip_Name = GetConVarInt(Active_Vip_Name);

	Transparance = GetConVarInt(Active_Transparance);

	ThirdPerson = GetConVarInt(Active_ThirdPerson);

	Respawn = GetConVarInt(Active_Respawn);

	GetConVarString(g_tagteam, TagTeam, sizeof(TagTeam));

}



public OnClientSettingsChanged(client)

{

	change_tag(client);

	change_name(client);

}



public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)

{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	change_tag(GetClientOfUserId(GetEventInt(event, "userid")));

	IsValideRegen[client] = false;



	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)	

	{

		SetEntityGravity(client, 1.0);

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

		SetEntityRenderColor(client, 255, 255, 255, 255);

	}

	

	PlayerRespawn[client] = 0;



	return Plugin_Handled;

}



public change_tag(client)

{

	if (IsClientInGame(client) && Clan_Tag == 1)

	{

		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)	

		{

			CS_SetClientClanTag(client, g_sVip);

		}

		else	

		{

			CS_SetClientClanTag(client, "");

		}

	}

}



public OnClientPutInServer(client)

{

	change_name(GetClientOfUserId(client));

}



public change_name(client)

{

	decl String:name[32];

	GetClientName(client, name, sizeof(name));  

	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1 && Vip_Name == 1 && StrContains(name, "[VIP]") == -1)

	{

		new String:new_name[64];

		Format(new_name, 64 ,"[VIP] %s", name);

		CS_SetClientName(client, new_name,true);

	}

}



public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)

{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	for(new i = 1; i <= MaxClients; i++)

	{

		HasMenu[i] = false;

		HasUseMenu[i] = false;

		menu_times[i] = 0;

    }

	if(GetClientTeam(client) > 1)

	{

		CPrintToChatAll("[ArenaLLgRo] Type !vipmenu to open your menu VIP", TagTeam);

	}

}



public Action:menuvip(client, args)

{

	GetClientAuthString(client, steamid, sizeof(steamid));

	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)

	{

		if(client == 0)

		{

			CPrintToChat(client, "Command not available", TagTeam);

			return Plugin_Handled;

		}

		if(menuv <= 0)

		{

			CPrintToChat(client, "The command is disabled", TagTeam);

			return Plugin_Handled;

		}

		if(GetClientTeam(client) == 1)

		{

			CPrintToChat(client, "You can not use this command Spectator", TagTeam);

			return Plugin_Handled;

		}

		if(!IsPlayerAlive(client))

		{

			CPrintToChat(client, "Trebuie sa fii viu", TagTeam);

			return Plugin_Handled;		

		}

		if(HasMenu[client])

		{

			CPrintToChat(client, menu_times[client] >= menuv ? "Ai folosit toate beneficiile":"Nu mai poti deschide meniul", TagTeam);

			return Plugin_Handled;

		}

		else

		{

			HasUseMenu[client] = true;

			new Handle:menu = CreateMenu(vipmenu);

			SetMenuTitle(menu, ".:: Menu Vip ::.");

			if (Vie == 1)

			{

				AddMenuItem(menu, "Vie", "Mai multa viata");

			}

			if(Armure == 1)

			{

				AddMenuItem(menu, "Armure", "Mai multa armura");

			}

			if (Usp == 1)

			{

				AddMenuItem(menu, "Usp", "Primesti un USP");

			}

			if (Grenade == 1)

			{

				AddMenuItem(menu, "Grenade", "Primesti o Grenada");

			}

			if (Smoke == 1)

			{

				AddMenuItem(menu, "Smoke", "Primesti un Smoke");

			}

			if (Vitesse == 1)

			{

				AddMenuItem(menu, "Vitesse", "Mai multa viteza");

			}

			if (Argent == 1)

			{

				AddMenuItem(menu, "Argent", "Mai multi bani");

			}

			if (Gravite == 1)

			{

				AddMenuItem(menu, "Gravite", "Gravitatie mai mare");

			}

			if (Regeneration == 1)

			{

				AddMenuItem(menu, "Regeneration", "Primesti viata default");

			}

			if (Transparance == 1)

			{

				AddMenuItem(menu, "Transparance", "Pe jumate invizibil");

			}

			if (ThirdPerson == 1)

			{

				AddMenuItem(menu, "ThirdPerson", "Te vezi a treia persoana");

			}

			if (Respawn == 1)

			{

				AddMenuItem(menu, "Respawn", "Ai 1 respawn");

			}

			SetMenuExitButton(menu, (Rien == 1 ? true : false));

			DisplayMenu(menu, client, MENU_TIME_FOREVER);

			menu_times[client]++;

			if(menu_times[client] >= menuv) 

			{

				HasMenu[client] = true;

			}

			CPrintToChat(client, "ARENA.LALEAGANE.RO RulzzZ", TagTeam, menu_times[client], menuv);

		}

		return Plugin_Continue;

	}

	else

	{

		CPrintToChat( client, "Trebuie sa fii VIP." , TagTeam);

	}

	return Plugin_Continue;

}



public vipmenu(Handle:menu, MenuAction:action, client, param2)

{

	if ( action == MenuAction_Select )

	{

		GetMenuItem(menu, param2, info, sizeof(info));

		if(StrEqual(info, "Vie"))

		{

			CPrintToChat( client, "Ai ales bonusul : Viata extra." , TagTeam);

			if (g_iHealth != INVALID_HANDLE)

			SetEntProp(client, Prop_Send, "m_iHealth", iHealth);

		}

		if(StrEqual(info, "Armure"))

		{

			CPrintToChat( client, "Ai ales bonusul : Armura.", TagTeam);

			if (g_iArmor != INVALID_HANDLE)

			SetEntProp(client, Prop_Send, "m_ArmorValue", iArmor);

		}

		if(StrEqual(info, "Usp"))

		{

			CPrintToChat( client, "Ai ales bonusul : USP.", TagTeam);

			GivePlayerItem(client, "weapon_usp");

		}

		if(StrEqual(info, "Grenade"))

		{

			CPrintToChat( client, "Ai ales bonusul : Grenada.", TagTeam);

			GivePlayerItem(client, "weapon_hegrenade");

		}

		if(StrEqual(info, "Smoke"))

		{

			CPrintToChat( client, "Ai ales bonusul : Smoke.", TagTeam);

			GivePlayerItem(client, "weapon_smokegrenade");	

		}

		if(StrEqual(info, "Vitesse"))

		{

			CPrintToChat( client, "Ai ales bonusul : Viteza.", TagTeam);

			if (g_iSpeed != INVALID_HANDLE)

			SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", iSpeed);

		}

		if(StrEqual(info, "Argent"))

		{

			CPrintToChat( client, "Ai ales bonusul : Bani extra.", TagTeam);

			if (g_iMoney != INVALID_HANDLE)

			SetEntProp(client, Prop_Send, "m_iAccount", iMoney);

		}

		if(StrEqual(info, "Gravite"))

		{

			CPrintToChat( client, "Ai ales bonusul : Gravitatie.", TagTeam);

			if (g_iGravity != INVALID_HANDLE)

			SetEntPropFloat( client, Prop_Data, "m_flGravity", iGravity);

		}

		if(StrEqual(info, "Regeneration"))

		{

			CPrintToChat( client, "Ai ales bonusul : Regenerare viata.", TagTeam);

			IsValideRegen[client] = true;

		}

		if(StrEqual(info, "Transparance"))

		{

			CPrintToChat( client, "Ai ales bonusul : Transparenta.", TagTeam);

			SetEntityRenderMode(client, RENDER_TRANSCOLOR);

			SetEntityRenderColor(client, 255, 255, 255, 100);

		}

		if(StrEqual(info, "ThirdPerson"))

		{

			CPrintToChat( client, "Ai ales bonusul : ThirdPerson.", TagTeam);

			Client_SetThirdPersonMode(client, true);

		}

		if(StrEqual(info, "Respawn"))

		{

			CPrintToChat( client, "Ai ales bonusul : Respawn.", TagTeam);

			CPrintToChat( client, "Tasteaza : !vipspawn pentru respawn", TagTeam);

			PlayerRespawn[client] = 1;

		}

	}

	else if (action == MenuAction_End )

    {

		CloseHandle(menu);

    }  

}



public Action:VipRespawn(client, args)

{

    if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)

    {

		if(StrEqual(info, "Respawn"))

		{

			if (PlayerRespawn[client] > 0)

			{

				CS_RespawnPlayer(client);

				CPrintToChat(client, "Ti-ai folosit respawnul", TagTeam);

				PlayerRespawn[client]--;

			}

			else

			{

				CPrintToChat(client, "Ai folosit !vipspawn pentru aceasta runda.", TagTeam);

			}

		}

		else

		{

			CPrintToChat(client, "Nu poti alege runda bonus la Respawn.", TagTeam);

		}

    }

    else

    {

        CPrintToChat(client, "NU esti VIP.", TagTeam);

    }

}



public Action:advert(Handle:timer)

{

	for(new client = 1; client <= MaxClients;client++)

	{

		if (GetConVarInt(adverts_info) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && ADMFLAG_CUSTOM1)

		{

			CPrintToChat( client, "[Arena.LLg.Ro] Pentru preturi si beneficii VIP tasteaza in chat !vip.", TagTeam);

		}

	}

}



public Action:advert2(Handle:timer)

{

	if (Advert == 1)

	{

		if(GetConVarInt(adverts_info2))

		{

			CPrintToChatAll( "Benefits you and become VIP now !", TagTeam);

		}

	}

}



public OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)

{

	new iUserId = GetEventInt(event, "userid");

	new client = GetClientOfUserId(iUserId);



	if(g_hRegenTimer[client] == INVALID_HANDLE && GetUserFlagBits(client) & ADMFLAG_CUSTOM1 && IsValideRegen[client] == true)

	{

		g_hRegenTimer[client] = CreateTimer(GetConVarFloat(g_Interval), Regenerate, client, TIMER_REPEAT);

	}

}



public Action:Regenerate(Handle:timer, any:client)

{

	if (IsClientInGame(client))

	{

		new ClientHealth = GetClientHealth(client);

		if(ClientHealth < GetConVarInt(g_MaxHP))

		{

			SetClientHealth(client, ClientHealth + GetConVarInt(g_Inc));

		}

		else

		{

			SetClientHealth(client, GetConVarInt(g_MaxHP));

			KillTimer(timer);

			g_hRegenTimer[client] = INVALID_HANDLE;

		}

	}

}



SetClientHealth(client, amount)

{

	new HealthOffs = FindDataMapOffs(client, "m_iHealth");

	SetEntData(client, HealthOffs, amount, true);

}



public OnClientDisconnect_Post(client)

{

    HasMenu[client] = true;

    menu_times[client] = 0;

}



public bool:TraceEntityFilterPlayer(entity, contentsMask) 

{

 	return entity > GetMaxClients();

}
