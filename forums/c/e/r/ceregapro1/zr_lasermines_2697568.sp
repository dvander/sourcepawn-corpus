#pragma semicolon 1

/*
			I N C L U D E S
	------------------------------------------------
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <zr_lasermines>
#include <colors>
/*
	------------------------------------------------
*/

/*
			D E F I N E S
	------------------------------------------------
*/
#define PLUGIN_VERSION "1.4.3"

#define MDL_LASER "materials/sprites/purplelaser1.vmt"
#define MDL_MINE "models/lasermine/lasermine.mdl"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_BUYMINE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"
/*
	------------------------------------------------
*/


/*
		|G|  |L| |O| |B| |A| |L| |S|
	------------------------------------------------
*/

new Handle:h_enable, bool:b_enable,
	Handle:h_amount, i_amount,
	Handle:h_maxamount, i_maxamount,
	Handle:h_damage, i_damage,
	Handle:h_buy_limit, i_buy_limit,
	Handle:h_explode_damage, i_explode_damage,
	Handle:h_explode_radius, i_explode_radius,
	Handle:h_health, i_health,
	Handle:h_color, String:s_color[16], i_color[3],
	Handle:h_activate_time, Float:f_activate_time,
	Handle:h_use_buy_mode, bool:b_use_buy_mode,
	Handle:h_should_buy_zone, bool:b_should_buy_zone,
	Handle:h_allow_pickup, bool:b_allow_pickup,
	Handle:h_allow_friendly_pickup, bool:b_allow_friendly_pickup,
Handle:h_price, i_price;

/*
		F O R W A R D S
	------------------------------------------------
*/
new Handle:h_fwdOnPlantLasermine,
	Handle:h_fwdOnLaserminePlanted,
	Handle:h_fwdOnPreHitByLasermine,
	Handle:h_fwdOnPostHitByLasermine,
	Handle:h_fwdOnPreBuyLasermine,
	Handle:h_fwdOnPostBuyLasermine,
	Handle:h_fwdOnPrePickupLasermine,
Handle:h_fwdOnPostPickupLasermine;

/*
	------------------------------------------------
*/

new i_clients_amount[MAXPLAYERS+1],
	i_clients_myamount[MAXPLAYERS+1],
	i_clients_maxlimit[MAXPLAYERS+1],
	b_used_by_native[MAXPLAYERS+1],
i_clients_buy[MAXPLAYERS+1];

new gInBuyZone = -1;
new gAccount = -1;

/*
			P L U G I N    I N F O
	------------------------------------------------
*/

public Plugin:myinfo = 
{
	name = "[ZR] Lasermines",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Plants a laser mine",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

new bool:b_late;
/*
	Fires when the plugin is asked to be loaded
	-------------------------------------------------------
*/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ZR_AddClientLasermines", Native_AddMines);
	CreateNative("ZR_SetClientLasermines", Native_SetMines);
	CreateNative("ZR_SubClientLasermines", Native_SubstractMines);
	CreateNative("ZR_GetClientLasermines", Native_GetMines);
	CreateNative("ZR_PlantClientLasermine", Native_PlantMine);
	CreateNative("ZR_ClearMapClientLasermines", Native_ClearMapMines);
	CreateNative("ZR_IsEntityLasermine", Native_IsLasermine);
	CreateNative("ZR_GetClientByLasermine", Native_GetClientByLasermine);
	CreateNative("ZR_SetClientMaxLasermines", Native_SetClientMaxLasermines);
	CreateNative("ZR_GetBeamByLasermine", Native_GetBeamByLasermine);
	CreateNative("ZR_GetLasermineByBeam", Native_GetLasermineByBeam);
	
	h_fwdOnPlantLasermine = CreateGlobalForward("ZR_OnPlantLasermine", ET_Hook, Param_Cell, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);
	h_fwdOnLaserminePlanted = CreateGlobalForward("ZR_OnLaserminePlanted", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Array);
	
	h_fwdOnPreHitByLasermine = CreateGlobalForward("ZR_OnPreHitByLasermine", ET_Hook, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef);
	h_fwdOnPostHitByLasermine = CreateGlobalForward("ZR_OnPostHitByLasermine", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	h_fwdOnPreBuyLasermine = CreateGlobalForward("ZR_OnPreBuyLasermine", ET_Hook, Param_Cell, Param_CellByRef, Param_CellByRef);
	h_fwdOnPostBuyLasermine = CreateGlobalForward("ZR_OnPostBuyLasermine", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	h_fwdOnPrePickupLasermine = CreateGlobalForward("ZR_OnPrePickupLasermine", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnPostPickupLasermine = CreateGlobalForward("ZR_OnPostPickupLasermine", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	RegPluginLibrary("zr_lasermines");
	
	b_late = late;
	
	return APLRes_Success;
}

/*
		Fires when the plugin start
	------------------------------------------------
*/
public OnPluginStart()
{
	// Creates console variable version
	CreateConVar("zr_lasermines_version", PLUGIN_VERSION, "The version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	// Creates console variables
	h_enable = CreateConVar("zr_lasermines_enable", "1", "Enables/Disables the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_amount = CreateConVar("zr_lasermines_amount", "3", "The amount to give laser mines to a player each spawn (if buy mode is disabled, -1 = Infinity)", FCVAR_PLUGIN, true, -1.0);
	h_maxamount = CreateConVar("zr_lasermines_maxamount", "3", "The maximum amount of laser mines a player can carry. (0-Unlimited)", FCVAR_PLUGIN, true, 0.0);
	h_buy_limit = CreateConVar("zr_lasermines_buy_limit", "3", "The maximum amount of laser mines a player can buy per spawn. (0-Unlimited)", FCVAR_PLUGIN, true, 0.0);
	h_damage = CreateConVar("zr_lasermines_damage", "500", "The damage to deal to a player by the laser", FCVAR_PLUGIN, true, 1.0, true, 100000.0);
	h_explode_damage = CreateConVar("zr_lasermines_explode_damage", "100", "The damage to deal to a player when a laser mine breaks", FCVAR_PLUGIN, true, 0.0, true, 100000.0);
	h_explode_radius = CreateConVar("zr_lasermines_explode_radius", "300", "The radius of the explosion", FCVAR_PLUGIN, true, 1.0, true, 100000.0);
	h_health = CreateConVar("zr_lasermines_health", "300", "The laser mines health. 0 = never breaked", FCVAR_PLUGIN, true, 0.0, true, 100000.0);
	h_activate_time = CreateConVar("zr_lasermines_activatetime", "2", "The delay of laser mines' activation", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	h_use_buy_mode = CreateConVar("zr_lasermines_buymode", "1", "Enables buy mode. In this mode you will have to buy mines", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_should_buy_zone = CreateConVar("zr_lasermines_buyzone", "1", "Whether a player have to stay in buy zone to buy mines", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_price = CreateConVar("zr_lasermines_price", "500", "The price of the laser mines", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	h_color = CreateConVar("zr_lasermines_color", "0 0 255", "The laser's color. Set by RGB", FCVAR_PLUGIN);
	h_allow_pickup = CreateConVar("zr_lasermines_allow_pickup", "1", "Allow players to pickup their planted lasermines", FCVAR_PLUGIN);
	h_allow_friendly_pickup = CreateConVar("zr_lasermines_allow_friendly_pickup", "0", "Allow allies to pickup your planted lasermines", FCVAR_PLUGIN);
	
	// Gets them to the global
	b_enable = GetConVarBool(h_enable);
	i_amount = GetConVarInt(h_amount);
	i_maxamount = GetConVarInt(h_maxamount);
	i_buy_limit	= GetConVarInt(h_buy_limit);
	i_damage = GetConVarInt(h_damage);
	i_explode_damage = GetConVarInt(h_explode_damage);
	i_explode_radius = GetConVarInt(h_explode_radius);
	i_health = GetConVarInt(h_health);
	f_activate_time = GetConVarFloat(h_activate_time);
	b_use_buy_mode = GetConVarBool(h_use_buy_mode);
	b_should_buy_zone = GetConVarBool(h_should_buy_zone);
	i_price = GetConVarInt(h_price);
	b_allow_pickup = GetConVarBool(h_allow_pickup);
	b_allow_friendly_pickup = GetConVarBool(h_allow_friendly_pickup);
	
	GetConVarString(h_color, s_color, sizeof(s_color));
	
	StringToColor(s_color, i_color, 255);
	
	// Hooks their change
	HookConVarChange(h_enable, OnConVarChanged);
	HookConVarChange(h_amount, OnConVarChanged);
	HookConVarChange(h_maxamount, OnConVarChanged);
	HookConVarChange(h_buy_limit, OnConVarChanged);
	HookConVarChange(h_damage, OnConVarChanged);
	HookConVarChange(h_explode_damage, OnConVarChanged);
	HookConVarChange(h_explode_radius, OnConVarChanged);
	HookConVarChange(h_health, OnConVarChanged);
	HookConVarChange(h_activate_time, OnConVarChanged);
	HookConVarChange(h_use_buy_mode, OnConVarChanged);
	HookConVarChange(h_should_buy_zone, OnConVarChanged);
	HookConVarChange(h_price, OnConVarChanged);
	HookConVarChange(h_color, OnConVarChanged);
	HookConVarChange(h_allow_pickup, OnConVarChanged);
	HookConVarChange(h_allow_friendly_pickup, OnConVarChanged);
	
	// Hooks event changes
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	//HookEvent("player_death", OnPlayerDeath_Pre, EventHookMode_Pre);
	
	// Registers new console commands
	RegConsoleCmd("sm_laser", Command_PlantMine, "Plant a laser mine");
	RegConsoleCmd("sm_plant", Command_PlantMine, "Plant a laser mine");
	RegConsoleCmd("sm_lm", Command_PlantMine, "Plant a laser mine");
	
	RegConsoleCmd("sm_buylm", Command_BuyMines, "Buy laser mines");
	RegConsoleCmd("sm_blm", Command_BuyMines, "Buy laser mines");
	RegConsoleCmd("sm_bm", Command_BuyMines, "Buy laser mines");
	
	// Hooks entity weapon_shieldgun ouput events
	HookEntityOutput("weapon_shieldgun", "OnTouchedByEntity", OnTouchedByEntity);
	
	// Loads the translation
	LoadTranslations("zr_lasermines");
	
	// Finds offsets
	if ((gInBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone")) == -1)
		SetFailState("Could not find offset \"m_bInBuyZone\"");
	if ((gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")) == -1)
		SetFailState("Could not find offset \"m_iAccount\"");
	
	AutoExecConfig(true, "zombiereloaded/zr_lasermines");
	
	if (b_late)
	{
		b_late = false;
		OnMapStart();
	}
}
/*
	------------------------------------------------
*/

/*
			Cvars changes
	------------------------------------------------
*/
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_enable)
	{
		b_enable = bool:StringToInt(newValue);
	}
	else if (convar == h_amount)
	{
		i_amount = StringToInt(newValue);
		LookupClients();
	}
	else if (convar == h_maxamount)
	{
		i_maxamount = StringToInt(newValue);
		LookupClients();
	}
	else if (convar == h_buy_limit)
	{
		i_buy_limit = StringToInt(newValue);
	}
	else if (convar == h_damage)
	{
		i_damage = StringToInt(newValue);
	}
	else if (convar == h_explode_damage)
	{
		i_explode_damage = StringToInt(newValue);
	}
	else if (convar == h_explode_radius)
	{
		i_explode_radius = StringToInt(newValue);
	}
	else if (convar == h_health)
	{
		i_health = StringToInt(newValue);
	}
	else if (convar == h_activate_time)
	{
		f_activate_time = StringToFloat(newValue);
	}
	else if (convar == h_use_buy_mode)
	{
		b_use_buy_mode = bool:StringToInt(newValue);
	}
	else if (convar == h_should_buy_zone)
	{
		b_should_buy_zone = bool:StringToInt(newValue);
	}
	else if (convar == h_price)
	{
		i_price = StringToInt(newValue);
	}
	else if (convar == h_color)
	{
		strcopy(s_color, sizeof(s_color), newValue);
		StringToColor(s_color, i_color, 255);
	}
	else if (convar == h_allow_pickup)
	{
		b_allow_pickup = bool:StringToInt(newValue);
	}
	else if (convar == h_allow_friendly_pickup)
	{
		b_allow_friendly_pickup = bool:StringToInt(newValue);
	}
}

LookupClients()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		OnClientConnected(i);
	}
}


/*
		Fires when the map starts
	------------------------------------------------
*/
public OnMapStart()
{
	PrecacheModel(MDL_MINE, true);
	PrecacheModel(MDL_LASER, true);

	PrecacheSound(SND_MINEPUT, true);
	PrecacheSound(SND_MINEACT, true);
	PrecacheSound(SND_BUYMINE, true);
	PrecacheSound(SND_CANTBUY, true);
}
/*
	------------------------------------------------
*/

public OnClientConnected(client)
{
	if (!b_used_by_native[client])
	{
		i_clients_maxlimit[client] = i_maxamount;
		i_clients_myamount[client] = i_amount;
		i_clients_buy[client] = 0;
	}
}

/*
	Fires when a client disconnects
	------------------------------------------------
*/
public OnClientDisconnect(client)
{
	for (new index = MaxClients+1; index < 2049; index++)
	{
		if (ZR_GetClientByLasermine(index) == client)
		{
			SDKUnhook(index, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(index, "KillHierarchy");
		}
	}
}

/*
	Fires when a client fully disconnected
	------------------------------------------------
*/
public OnClientDisconnect_Post(client)
{
	i_clients_amount[client] = 0;
	i_clients_buy[client] = 0;
	b_used_by_native[client] = false;
}

/*
			Touch event
	------------------------------------------------
*/
public OnTouchedByEntity(const String:output[], caller, activator, Float:delay)
{
	if (!(0 < activator <= MaxClients))
	{
		return;
	}
	new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
	new lasermine = ZR_GetLasermineByBeam(caller);
	if (owner == -1 || lasermine == -1  || activator == owner || ZR_IsClientHuman(activator))
	{
		return;
	}
	
	decl damage, dummy_caller, dummy_owner, dummy_lasermine;
	damage = i_damage;
	dummy_caller = caller;
	dummy_owner = owner;
	dummy_lasermine = lasermine;
	
	new Action:result = Forward_OnPreHit(activator, dummy_owner, dummy_caller, dummy_lasermine, damage);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
		case Plugin_Continue :
		{
			damage = i_damage;
			dummy_caller = caller;
			dummy_owner = owner;
			dummy_lasermine = lasermine;
		}
	}
	
	//decl Float:m_vecVelocity[3];
	//GetEntPropVector(activator, Prop_Data, "m_vecVelocity", m_vecVelocity);
	
	// Make custom damage to the client
	SDKHooks_TakeDamage(activator, dummy_caller, dummy_owner, float(damage), DMG_ENERGYBEAM);
	
	//TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, m_vecVelocity);
	
	Forward_OnPostHit(activator, dummy_owner, dummy_caller, dummy_lasermine, damage);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		i_clients_buy[i] = i_clients_amount[i];
	}
	
	//CPrintToChatAll("%t", "RoundAnnounce");
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!b_use_buy_mode)
	{
		i_clients_amount[client] = i_clients_myamount[client];
	}
	i_clients_buy[client] = i_clients_amount[client];
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnClientDisconnect(client);
}

/*public Action:OnPlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (1 <= attacker <= MaxClients)
	{
		decl String:g_szWeapon[32];
		GetEventString(event, "weapon", g_szWeapon, sizeof(g_szWeapon));
		if (StrEqual(g_szWeapon, "env_beam"))
		{
			SetEventString(event, "weapon", "shieldgun");
		}
	}
	return Plugin_Continue;
}*/

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	OnClientDisconnect(client);
}

/*
	------------------------------------------------
*/
public Action:Command_BuyMines(client, argc)
{
	// client = 0	or	disabled	or	buy mode disabled	or	unlimited amount	or	client is not in game
	if (!client || !b_enable || !b_use_buy_mode || i_clients_myamount[client] == -1 || !IsClientInGame(client))
	{
		return Plugin_Continue;	// Stop trigger the command
	}
	// client is dead
	if (!IsPlayerAlive(client))
	{
		PrintHintText(client, "%t", "Can't buy, while dead");
		return Plugin_Handled;	// Stop trigger the command
	}
	// client is spectator
	if (!(1 < GetClientTeam(client) < 4))
	{
		PrintHintText(client, "%t", "Can't use, while spec");
		return Plugin_Handled;	// Stop trigger the command
	}
	// client is zombie
	if (ZR_IsClientZombie(client))
	{
		PrintHintText(client, "%t", "Can't buy, while zombie");
		return Plugin_Handled;	// Stop trigger the command
	}
	// If buy zone mode is enabled and player is out of buy zone range
	if (b_should_buy_zone && !bool:GetEntData(client, gInBuyZone, 1))
	{
		PrintHintText(client, "%t", "Out of buy zone");
		return Plugin_Handled;	// Stop trigger the command
	}
	
	new amount = 1;
	if (argc)
	{
		decl String:txt[6];
		GetCmdArg(1, txt, sizeof(txt));
		amount = StringToInt(txt);
		if (bool:i_clients_maxlimit[client])
		{
			if (amount > i_clients_maxlimit[client])
			{
				amount = i_clients_maxlimit[client];
			}
			else if (amount < 1)
			{
				amount = 1;
			}
			if (i_buy_limit > 0 && amount + i_clients_buy[client] > i_buy_limit)
			{
				amount = i_buy_limit - i_clients_buy[client];
				if (amount < 0)
				{
					amount = 0;
				}
			}
		}
	}
	
	decl dummy_amount, cost, boughtamount;
	dummy_amount = amount;
	cost = i_price;
	boughtamount = 0;
	new Action:result = Forward_OnPreBuy(client, dummy_amount, cost);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return result;
		}
		case Plugin_Continue :
		{
			dummy_amount = amount;
			cost = i_price;
		}
	}
	
	new money = GetEntData(client, gAccount);
	do
	{
		if (bool:i_clients_maxlimit[client] && (i_clients_amount[client] >= i_clients_maxlimit[client]) || (i_buy_limit > 0 && i_clients_buy[client] >= i_buy_limit))
		{
			PrintHintText(client, "%t", "Can't buy, max amount", i_clients_maxlimit[client]);
			return Plugin_Handled;
		}
		
		money -= cost;
		
		if (money < 0)
		{
			PrintHintText(client, "%t", "Can't buy, not enough money", i_clients_amount[client]);
			EmitSoundToClient(client, SND_CANTBUY);
			return Plugin_Handled;
		}
		SetEntData(client, gAccount, money);
		i_clients_amount[client]++;
		i_clients_buy[client]++;
		boughtamount++;
	} while (--dummy_amount);
	
	if (boughtamount)
	{
		PrintHintText(client, "%t", "Mines", i_clients_amount[client]);
		EmitSoundToClient(client, SND_BUYMINE);
		Forward_OnPostBuy(client, boughtamount, boughtamount*cost);
	}
	
	return Plugin_Handled;
}

/*
	------------------------------------------------
*/
public Action:Command_PlantMine(client, argc)
{
	if (!client || !b_enable || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	if (!i_clients_amount[client])
	{
		PrintHintText(client, "%t", "Mines", i_clients_amount[client]);
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintHintText(client, "%t", "Can't plant, while dead");
		return Plugin_Handled;
	}
	if (!(1 < GetClientTeam(client) < 4))
	{
		PrintHintText(client, "%t", "Can't use, while spec");
		return Plugin_Handled;
	}
	if (ZR_IsClientZombie(client))
	{
		PrintHintText(client, "%t", "Can't plant, while zombie");
		return Plugin_Handled;
	}
	
	decl Float:delay_time, dummy_damage, dummy_radius, health, dummy_color[3];
	delay_time = f_activate_time;
	dummy_damage = i_explode_damage;
	dummy_radius = i_explode_radius;
	health = i_health;
	dummy_color = i_color;
	
	new Action:result = Forward_OnPlantMine(client, delay_time, dummy_damage, dummy_radius, health, dummy_color);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return result;
		}
		case Plugin_Continue :
		{
			delay_time = f_activate_time;
			dummy_damage = i_explode_damage;
			dummy_radius = i_explode_radius;
			health = i_health;
			dummy_color = i_color;
		}
	}
	
	new mine;
	if ((mine = PlantMine(client, delay_time, dummy_damage, dummy_radius, health, dummy_color)) == -1)
	{
		return Plugin_Handled;
	}
	
	Forward_OnMinePlanted(client, mine, delay_time, dummy_damage, dummy_radius, health, dummy_color);
	
	switch (i_clients_amount[client])
	{
		case -1 :
		{
			PrintHintText(client, "%t", "Infinity mines");
		}
		default :
		{
			i_clients_amount[client]--;
			PrintHintText(client, "%t", "Mines", i_clients_amount[client]);
		}
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static iPrevButtons[MAXPLAYERS+1];

	if (!b_allow_pickup || IsFakeClient(client) || !IsPlayerAlive(client) || ZR_IsClientZombie(client))
	{
		return Plugin_Continue;
	}
	
	if ((buttons & IN_USE) && !(iPrevButtons[client] & IN_USE))
	{
		OnButtonPressed(client);
	}
	
	iPrevButtons[client] = buttons;
	
	return Plugin_Continue;
}

OnButtonPressed(client)
{
	new Handle:trace = TraceRay(client);
	
	new ent = -1;
	if (TR_DidHit(trace) && (ent = TR_GetEntityIndex(trace)) > MaxClients)
	{	
		CloseHandle(trace);
		new owner = ZR_GetClientByLasermine(ent);
		if (owner == -1)
		{
			return;
		}
		if (owner == client)
		{
			PickupLasermine(client, ent, owner);
			return;
		}
		else if (b_allow_friendly_pickup)
		{
			PickupLasermine(client, ent, owner);
		}
	}
	else
		CloseHandle(trace);
}

PickupLasermine(client, lasermine, owner)
{
	if (i_clients_amount[client] >= 0 && i_clients_amount[client] == ZR_AddClientLasermines(client))
	{
		return;
	}
	
	new Action:result = Forward_OnPrePickup(client, lasermine, owner);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
	}
	
	AcceptEntityInput(lasermine, "KillHierarchy");
	if (i_clients_amount[client] >= 0)
	{
		PrintHintText(client, "%t", "Mines", i_clients_amount[client]);
	}
	else
	{
		PrintHintText(client, "%t", "Infinity mines");
	}
	EmitSoundToClient(client, SND_BUYMINE);
	
	Forward_OnPostPickup(client, lasermine, owner);
}

Handle:TraceRay(client)
{
	decl Float:startent[3], Float:angle[3], Float:end[3];
	GetClientEyePosition(client, startent);
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(end, end);

	startent[0] = startent[0] + end[0] * 10.0;
	startent[1] = startent[1] + end[1] * 10.0;
	startent[2] = startent[2] + end[2] * 10.0;

	end[0] = startent[0] + end[0] * 80.0;
	end[1] = startent[1] + end[1] * 80.0;
	end[2] = startent[2] + end[2] * 80.0;
	
	return TR_TraceRayFilterEx(startent, end, CONTENTS_SOLID, RayType_EndPoint, FilterPlayers);
}


/*
	------------------------------------------------
*/

PlantMine(client, Float:activation_delay = 0.0, explode_damage, explode_radius, const health = 0, const color[3] = {255, 255, 255})
{
	if (activation_delay > 10.0)
	{
		activation_delay = 10.0;
	}
	else if (activation_delay < 0.0)
	{
		activation_delay = 0.0;
	}
	
	new Handle:trace = TraceRay(client);
	
	decl Float:end[3], Float:normal[3], Float:beamend[3];
	if (TR_DidHit(trace) && TR_GetEntityIndex(trace) < 1)
	{
		TR_GetEndPosition(end, trace);
		TR_GetPlaneNormal(trace, normal);
		CloseHandle(trace);
		
		GetVectorAngles(normal, normal);
		
		TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll);
		TR_GetEndPosition(beamend, INVALID_HANDLE);
		
		new ent = CreateEntityByName("prop_physics_override");
		if (ent == -1 || !IsValidEdict(ent))
		{
			LogError("Could not create entity \"prop_physics_override\"");
			return -1;
		}
		
		new beament = CreateEntityByName("env_beam");
		if (beament == -1 || !IsValidEdict(beament))
		{
			LogError("Could not create entity \"env_beam\"");
			AcceptEntityInput(ent, "kill");
			return -1;
		}
		DispatchKeyValue(beament, "classname", "weapon_shieldgun");
		
		decl String:start[30], String:tmp[200];
		FormatEx(start, sizeof(start), "Beam%i", beament);
		
		SetEntityModel(ent, MDL_MINE);
		
		decl String:buffer[16];
		IntToString(explode_damage, buffer, sizeof(buffer));
		DispatchKeyValue(ent, "ExplodeDamage", buffer);
		IntToString(explode_radius, buffer, sizeof(buffer));
		DispatchKeyValue(ent, "ExplodeRadius", buffer);
		
		DispatchKeyValue(ent, "spawnflags", "3");
		DispatchSpawn(ent);
		
		AcceptEntityInput(ent, "DisableMotion");
		SetEntityMoveType(ent, MOVETYPE_NONE);
		TeleportEntity(ent, end, normal, NULL_VECTOR);
		
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 11);
		
		if (health)
		{
			SetEntProp(ent, Prop_Data, "m_takedamage", 2);
			SetEntProp(ent, Prop_Data, "m_iHealth", health);
		}
		
		FormatEx(tmp, sizeof(tmp), "%s,Kill,,0,-1", start);
		DispatchKeyValue(ent, "OnBreak", tmp);
		
		EmitSoundToAll(SND_MINEPUT, ent);
		
		
		
		// Set keyvalues on the beam.
		DispatchKeyValue(beament, "targetname", start);
		DispatchKeyValue(beament, "damage", "0");
		DispatchKeyValue(beament, "framestart", "0");
		DispatchKeyValue(beament, "BoltWidth", "4.0");
		DispatchKeyValue(beament, "renderfx", "0");
		DispatchKeyValue(beament, "TouchType", "3"); // 0 = none, 1 = player only, 2 = NPC only, 3 = player or NPC, 4 = player, NPC or physprop
		DispatchKeyValue(beament, "framerate", "0");
		DispatchKeyValue(beament, "decalname", "Bigshot");
		DispatchKeyValue(beament, "TextureScroll", "35");
		DispatchKeyValue(beament, "HDRColorScale", "1.0");
		DispatchKeyValue(beament, "texture", MDL_LASER);
		DispatchKeyValue(beament, "life", "0"); // 0 = infinite, beam life time in seconds
		DispatchKeyValue(beament, "StrikeTime", "1"); // If beam life time not infinite, this repeat it back
		DispatchKeyValue(beament, "LightningStart", start);
		DispatchKeyValue(beament, "spawnflags", "0"); // 0 disable, 1 = start on, etc etc. look from hammer editor
		DispatchKeyValue(beament, "NoiseAmplitude", "0"); // straight beam = 0, other make noise beam
		DispatchKeyValue(beament, "Radius", "256");
		DispatchKeyValue(beament, "renderamt", "100");
		DispatchKeyValue(beament, "rendercolor", "0 0 0");
		
		AcceptEntityInput(beament, "TurnOff");
		
		SetEntityModel(beament, MDL_LASER);
		
		TeleportEntity(beament, beamend, NULL_VECTOR, NULL_VECTOR); // Teleport the beam
		
		SetEntPropVector(beament, Prop_Data, "m_vecEndPos", end);
		SetEntPropFloat(beament, Prop_Data, "m_fWidth", 3.0);
		SetEntPropFloat(beament, Prop_Data, "m_fEndWidth", 3.0);
		
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client); // Sets the owner of the mine
		SetEntPropEnt(beament, Prop_Data, "m_hOwnerEntity", client); // Sets the owner of the beam
		SetEntPropEnt(ent, Prop_Data, "m_hMoveChild", beament);
		SetEntPropEnt(beament, Prop_Data, "m_hEffectEntity", ent);
		
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, EntIndexToEntRef(beament));
		WritePackCell(datapack, EntIndexToEntRef(ent));
		WritePackCell(datapack, color[0]);
		WritePackCell(datapack, color[1]);
		WritePackCell(datapack, color[2]);
		WritePackString(datapack, start);
		CreateTimer(activation_delay, OnActivateLaser, datapack, TIMER_FLAG_NO_MAPCHANGE|TIMER_HNDL_CLOSE);
		
		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);
		
		return ent;
	}
	else
	{
		CloseHandle(trace);
	}
	return -1;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (ZR_IsEntityLasermine(victim))
	{
		if (0 < attacker <= MaxClients)
		{
			new client = ZR_GetClientByLasermine(victim);
			if ((client != -1) && (client != attacker) && IsPlayerAlive(attacker) && ZR_IsClientHuman(attacker))
			{
				return Plugin_Handled;
			}
			return Plugin_Continue;
		}
		else if (!ZR_IsEntityLasermine(inflictor))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/*
	------------------------------------------------
*/

public bool:FilterAll(entity, contentsMask)
{
	return false;
}

public bool:FilterPlayers(entity, contentsMask)
{
	return !(0 < entity <= MaxClients);
}

public Action:OnActivateLaser(Handle:timer, any:hDataPack)
{
	ResetPack(hDataPack);
	decl String:start[30], String:tmp[200], color[3];
	new beament = EntRefToEntIndex(ReadPackCell(hDataPack));
	new ent = EntRefToEntIndex(ReadPackCell(hDataPack));
	color[0] = ReadPackCell(hDataPack);
	color[1] = ReadPackCell(hDataPack);
	color[2] = ReadPackCell(hDataPack);
	ReadPackString(hDataPack, start, sizeof(start));
	
	if (beament == INVALID_ENT_REFERENCE || ent == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	AcceptEntityInput(beament, "TurnOn");
	
	SetEntityRenderColor(beament, color[0], color[1], color[2]);

	FormatEx(tmp, sizeof(tmp), "%s,TurnOff,,0.001,-1", start);
	DispatchKeyValue(beament, "OnTouchedByEntity", tmp);
	FormatEx(tmp, sizeof(tmp), "%s,TurnOn,,0.002,-1", start);
	DispatchKeyValue(beament, "OnTouchedByEntity", tmp);

	EmitSoundToAll(SND_MINEACT, ent);
	
	return Plugin_Stop;
}

/*
			N A T I V E S
	------------------------------------------------
*/

public Native_AddMines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return 0;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return 0;
	}
	
	new amount = GetNativeCell(2);
	new bool:limit = bool:GetNativeCell(3);
	
	if (amount < 1)
	{
		return i_clients_amount[client];
	}
	if (i_clients_amount[client] < 0)
	{
		return -1;
	}
	
	i_clients_amount[client] += amount;
	
	if (limit)
	{
		if (i_clients_amount[client] > i_clients_maxlimit[client])
		{
			i_clients_amount[client] = i_clients_maxlimit[client];
		}
	}
	
	return i_clients_amount[client];
}

public Native_SetMines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return false;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return false;
	}
	
	new amount = GetNativeCell(2);
	new bool:limit = bool:GetNativeCell(3);
	
	if (amount < -1)
	{
		amount = -1;
	}
	
	i_clients_amount[client] = amount;
	
	if (limit)
	{
		if (i_clients_amount[client] > i_clients_maxlimit[client])
		{
			i_clients_amount[client] = i_clients_maxlimit[client];
		}
	}
	
	return true;
}

public Native_SubstractMines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return 0;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return 0;
	}
	
	new amount = GetNativeCell(2);
	
	if (i_clients_amount[client] == -1)
	{
		return i_clients_amount[client];
	}
	
	if (amount <= 0)
	{
		return i_clients_amount[client];
	}
	
	i_clients_amount[client] -= amount;
	if (i_clients_amount[client] < 0)
	{
		i_clients_amount[client] = 0;
	}
	
	return i_clients_amount[client];
}

public Native_GetMines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return 0;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return 0;
	}
	
	return i_clients_amount[client];
}

public Native_ClearMapMines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return;
	}
	
	OnClientDisconnect(client);
}

public Native_PlantMine(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return false;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return false;
	}
	
	new Float:f_delay = GetNativeCell(2);
	new i_exp_damage = GetNativeCell(3);
	new i_exp_radius = GetNativeCell(4);
	new dummy_health = GetNativeCell(5);
	decl color[3]; GetNativeArray(6, color, sizeof(color));
	new bool:hook = bool:GetNativeCell(7);
	
	decl Float:delay_time, dummy_damage, dummy_radius, health, dummy_color[3];
	delay_time = f_delay;
	dummy_damage = i_exp_damage;
	dummy_radius = i_exp_radius;
	health = dummy_health;
	dummy_color = color;
	
	new mine = -1;
	
	if (hook)
	{
		new Action:result = Forward_OnPlantMine(client, delay_time, dummy_damage, dummy_radius, health, dummy_color);
		
		switch (result)
		{
			case Plugin_Handled, Plugin_Stop :
			{
				return mine;
			}
			case Plugin_Continue :
			{
				delay_time = f_delay;
				dummy_damage = i_exp_damage;
				dummy_radius = i_exp_radius;
				health = dummy_health;
				dummy_color = color;
			}
		}
	}
	
	if ((mine = PlantMine(client, delay_time, dummy_damage, dummy_radius, health, dummy_color)) != -1)
	{
		Forward_OnMinePlanted(client, mine, delay_time, dummy_damage, dummy_radius, health, dummy_color);
	}
	
	return mine;
}

public Native_IsLasermine(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	decl String:g_szModel[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", g_szModel, sizeof(g_szModel));
	return (StrEqual(g_szModel, MDL_MINE, false) && GetEntPropEnt(entity, Prop_Data, "m_hMoveChild") != -1);
}

public Native_GetClientByLasermine(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	new beam;
	if ((beam = ZR_GetBeamByLasermine(entity)) == -1)
	{
		return -1;
	}
	return GetEntPropEnt(beam, Prop_Data, "m_hOwnerEntity");
}

public Native_SetClientMaxLasermines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	else if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not authorized", client);
	}
	new amount = GetNativeCell(2);
	if (amount < -1)
	{
		amount = -1;
	}
	i_clients_maxlimit[client] = amount;
	i_clients_myamount[client] = amount;
	b_used_by_native[client] = true;
}

public Native_ResetClientMaxLasermines(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	else if (!IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not connected", client);
	}
	OnClientConnected(client);
}

public Native_GetBeamByLasermine(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	if (ZR_IsEntityLasermine(entity))
	{
		return GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
	}
	return -1;
}

public Native_GetLasermineByBeam(Handle:plugin, numParams)
{
	new mine = GetEntPropEnt(GetNativeCell(1), Prop_Data, "m_hEffectEntity");
	if (mine != -1 && ZR_IsEntityLasermine(mine))
	{
		return mine;
	}
	return -1;
}

/*
		F O R W A R D S
	------------------------------------------------
*/

Action:Forward_OnPlantMine(client, &Float:activate_time, &exp_damage, &exp_radius, &health, color[3])
{
	decl Action:result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnPlantLasermine);
	Call_PushCell(client);
	Call_PushFloatRef(activate_time);
	Call_PushCellRef(exp_damage);
	Call_PushCellRef(exp_radius);
	Call_PushCellRef(health);
	Call_PushArrayEx(color, sizeof(color), SM_PARAM_COPYBACK);
	Call_Finish(result);
	
	return result;
}

Forward_OnMinePlanted(client, mine, Float:activate_time, exp_damage, exp_radius, health, color[3])
{
	Call_StartForward(h_fwdOnLaserminePlanted);
	Call_PushCell(client);
	Call_PushCell(mine);
	Call_PushFloat(activate_time);
	Call_PushCell(exp_damage);
	Call_PushCell(exp_radius);
	Call_PushCell(health);
	Call_PushArray(color, sizeof(color));
	Call_Finish();
}

Action:Forward_OnPreHit(victim, &attacker, &beam, &lasermine, &damage)
{
	decl Action:result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnPreHitByLasermine);
	Call_PushCell(victim);
	Call_PushCellRef(attacker);
	Call_PushCellRef(beam);
	Call_PushCellRef(lasermine);
	Call_PushCellRef(damage);
	Call_Finish(result);
	
	return result;
}

Forward_OnPostHit(victim, attacker, beam, lasermine, damage)
{
	Call_StartForward(h_fwdOnPostHitByLasermine);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(beam);
	Call_PushCell(lasermine);
	Call_PushCell(damage);
	Call_Finish();
}

Action:Forward_OnPreBuy(client, &amount, &price)
{
	decl Action:result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnPreBuyLasermine);
	Call_PushCell(client);
	Call_PushCellRef(amount);
	Call_PushCellRef(price);
	Call_Finish(result);
	
	return result;
}

Forward_OnPostBuy(client, amount, sum)
{
	Call_StartForward(h_fwdOnPostBuyLasermine);
	Call_PushCell(client);
	Call_PushCell(amount);
	Call_PushCell(sum);
	Call_Finish();
}

Action:Forward_OnPrePickup(client, lasermine, owner)
{
	decl Action:result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnPrePickupLasermine);
	Call_PushCell(client);
	Call_PushCell(lasermine);
	Call_PushCell(owner);
	Call_Finish(result);
	
	return result;
}

Forward_OnPostPickup(client, lasermine, owner)
{
	Call_StartForward(h_fwdOnPostPickupLasermine);
	Call_PushCell(client);
	Call_PushCell(lasermine);
	Call_PushCell(owner);
	Call_Finish();
}

/*
			S T O C K S
	------------------------------------------------
*/


stock bool:StringToColor(const String:str[], color[3], const defvalue = -1)
{
	new bool:result = false;
	decl String:Splitter[3][64];
	if (ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) == 3 && String_IsNumeric(Splitter[0]) && String_IsNumeric(Splitter[1]) && String_IsNumeric(Splitter[2]))
	{
		color[0] = StringToInt(Splitter[0]);
		color[1] = StringToInt(Splitter[1]);
		color[2] = StringToInt(Splitter[2]);
		result = true;
	}
	else
	{
		color[0] = defvalue;
		color[1] = defvalue;
		color[2] = defvalue;
	}
	return result;
}

stock bool:String_IsNumeric(const String:str[])
{	
	new x=0;
	new numbersFound=0;

	if (str[x] == '+' || str[x] == '-')
		x++;

	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x]))
			numbersFound++;
		else
			return false;
		x++;
	}
	
	if (!numbersFound)
		return false;
	
	return true;
}