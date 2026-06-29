#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <steamtools>
#include <morecolors>
#include <smlib>

#define LOGO		"{seagreen}[Murder]{white}"

new bool:inUse[MAXPLAYERS+1];
new bool:canRespawn;
new bool:minPlayer;
new bool:canDeagle[MAXPLAYERS+1];
new bool:nameUse[MAXPLAYERS+1];
new bool:canRound;

new Handle:timerHud[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:timerAimHud[MAXPLAYERS+1] = INVALID_HANDLE;

new String:tempName[MAXPLAYERS+1][64];

new countItem[MAXPLAYERS+1];
new murderer;
new cop;
new count;
new isFrench[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Murder",
	description = "Murder vs innocents.",
	author = "Wana",
	version = "1.0",
	url = "www.clan-family.com"
};

public OnPluginStart()
{
	decl String:gameName[80];
	GetGameFolderName(gameName, 80);
	if(!StrEqual(gameName, "cstrike"))
	{
		SetFailState("Ce plugin est seulement pour Counter-Strike: Source.");
		SetFailState("This plugin is only for Counter-Strike: Source.");
	}
	
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	if(!StrEqual(mapName, "cs_office"))
	{
		new Handle:plugin;
		plugin = GetMyHandle();
		decl String:namePlugin[256];
		GetPluginFilename(plugin, namePlugin, sizeof(namePlugin));
		ServerCommand("sm plugins unload %s", namePlugin); 
		PrintToServer("[ERREUR] Vous devez mettre cs_office pour lancer le mode Murder.");
		PrintToServer("[ERROR] You need cs_office to start the mod Murder.");
	}
	
	decl String:srvDescription[64];
	Format(srvDescription, sizeof(srvDescription), "Murder");
	Steam_SetGameDescription(srvDescription);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	
	RegConsoleCmd("joinclass", Command_Block);
	RegConsoleCmd("jointeam", Command_Block);
	RegConsoleCmd("explode", Command_Block);
	RegConsoleCmd("kill", Command_Block);
	RegConsoleCmd("coverme", Command_Block);
	RegConsoleCmd("takepoint", Command_Block);
	RegConsoleCmd("holdpos", Command_Block);
	RegConsoleCmd("regroup", Command_Block);
	RegConsoleCmd("followme", Command_Block);
	RegConsoleCmd("takingfire", Command_Block);
	RegConsoleCmd("go", Command_Block);
	RegConsoleCmd("fallback", Command_Block);
	RegConsoleCmd("sticktog", Command_Block);
	RegConsoleCmd("getinpos", Command_Block);
	RegConsoleCmd("stormfront", Command_Block);
	RegConsoleCmd("report", Command_Block);
	RegConsoleCmd("roger", Command_Block);
	RegConsoleCmd("enemyspot", Command_Block);
	RegConsoleCmd("needbackup", Command_Block);
	RegConsoleCmd("sectorclear", Command_Block);
	RegConsoleCmd("inposition", Command_Block);
	RegConsoleCmd("reportingin", Command_Block);
	RegConsoleCmd("getout", Command_Block);
	RegConsoleCmd("negative", Command_Block);
	RegConsoleCmd("enemydown", Command_Block);
	
	AddCommandListener(Say, "say_team");
	AddCommandListener(Say, "say");
	
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
	
	SetConVarInt(FindConVar("mp_maxrounds"), 0, true, false);
	SetConVarInt(FindConVar("mp_freezetime"), 0, true, false);
	SetConVarInt(FindConVar("mp_roundtime"), 0, true, false);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0, true, false);
	SetConVarInt(FindConVar("mp_limitteams"), 0, true, false);
	SetConVarInt(FindConVar("sv_hudhint_sound"), 0, true, false);
	SetConVarString(FindConVar("sm_nextmap"), "cs_office", true, false);
	
	PrecacheSound("weapons/deagle/de_clipout.wav", true);
	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
	PrecacheSound("ambient/atmosphere/thunder4.wav", true);
	
	PrecacheModel("models/props/de_tides/vending_turtle.mdl", true);
	PrecacheModel("models/weapons/w_c4_planted.mdl", true);
	PrecacheModel("models/props_c17/suitcase001a.mdl", true);
	PrecacheModel("models/props/de_prodigy/tire2.mdl", true);
	PrecacheModel("models/props_c17/oildrum001.mdl", true);
	PrecacheModel("models/props_c17/canister_propane01a.mdl", true);
	PrecacheModel("models/props_c17/clock01.mdl", true);
	PrecacheModel("models/props_c17/doll01.mdl", true);
	PrecacheModel("models/props/de_inferno/potted_plant2.mdl", true);
	PrecacheModel("models/props/cs_office/phone.mdl", true);
	PrecacheModel("models/props/cs_office/water_bottle.mdl", true);
	PrecacheModel("models/props_junk/watermelon01.mdl", true);
	PrecacheModel("models/props/cs_office/trash_can_p.mdl", true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk05.mdl", true);
	PrecacheModel("models/props_debris/concrete_cynderblock001.mdl", true);
}

public OnMapStart()
{
	CreateTimer(1.0, CountTimer, _, TIMER_REPEAT);
}

public Action:TextMsg(UserMsg:msid, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    decl String:msg[256];
    BfReadString(bf, msg, sizeof(msg), false);

    if(StrContains(msg, "damage", false) != -1 || StrContains(msg, "-------", false) != -1 || StrContains(msg, "attack", false) != -1)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new MaxEntities = GetMaxEntities();
	decl String:className[64], String:entityName[64];
	for(new X = MaxClients; X <= MaxEntities; X++)
	{
		if(IsValidEntity(X))
		{
			Entity_GetClassName(X, className, sizeof(className));
			Entity_GetName(X, entityName, sizeof(entityName));
			if(StrEqual(className, "hostage_entity"))
				AcceptEntityInput(X, "kill");
			else if(StrEqual(className, "func_buyzone"))
				RemoveEdict(X);
			else if(StrEqual(className, "func_hostage_rescue"))
				RemoveEdict(X);
			else if(StrEqual(entityName, "murder_item"))
				RemoveEdict(X);
		}
	}
	
	count = 0;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(IsClientValid(X))
		{
			count ++;
			CreateTimer(0.1, Respawn, X);
			GetName(X);
		}
	}
	
	if(count > 2)
		CreateTimer(15.0, SelectMurderer, _);
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	canRespawn = true;
	canRound = true;
	murderer = -1;
	cop = -1;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(IsClientValid(X))
			countItem[X] = 0;
	}
	for(new X = 0; X <= 63; X++)
	{
		nameUse[X] = false;
	}
	
	new MaxEntities = GetMaxEntities();
	decl String:entityName[64];
	for(new X = MaxClients; X <= MaxEntities; X++)
	{
		if(IsValidEntity(X))
		{
			Entity_GetName(X, entityName, sizeof(entityName));
			if(StrEqual(entityName, "murder_item"))
				RemoveEdict(X);
		}
	}
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(victim != murderer
	&& attacker != murderer
	&& attacker > 0)
	{
		if(attacker == cop
		|| countItem[attacker] >= 3)
		{
			SetEntityMoveType(attacker, MOVETYPE_NONE);
			SetEntityRenderColor(attacker, 0, 128, 255, 192);
			
			ClientCommand(attacker, "r_screenoverlay effects/black.vmt");
			
			EmitSoundToAll("physics/glass/glass_impact_bullet4.wav", attacker, _, _, _, 1.0);
			
			if(isFrench[attacker])
				CPrintToChat(attacker, "%s Vous avez tué un innocent.", LOGO);
			else
				CPrintToChat(attacker, "%s You killed an innocent.", LOGO);
			
			if(isFrench[victim])
				CPrintToChat(victim, "%s Vous avez été tué par un innocent.", LOGO);
			else
				CPrintToChat(victim, "%s You have been killed by an innocent.", LOGO);
			
			CreateTimer(10.0, unFreeze, attacker);
		}
	}
	
	if(attacker > 0)
	{
		ForcePlayerSuicide(victim);
		
		for(new X = 1; X <= MaxClients; X++)
		{
			if(IsClientValid(X))
				EmitSoundToClient(X, "ambient/atmosphere/thunder4.wav", X, _, _, _, 1.0);
		}
		
		if(victim == murderer)
		{
			for(new X = 1; X <= MaxClients; X++)
			{
				if(IsClientValid(X))
				{
					if(isFrench[X])
					{
						if(attacker == cop)
							CPrintToChat(X, "%s Le policier {gold}%N{white} a tué l'assassin {red}%N{white}.", LOGO, cop, murderer);
						else
							CPrintToChat(X, "%s Le survivant {gold}%N{white} a tué l'assassin {red}%N{white}.", LOGO, attacker, murderer);
					}
					else
					{
						if(attacker == cop)
							CPrintToChat(X, "%s The cop {gold}%N{white} killed the murderer {red}%N{white}.", LOGO, cop, murderer);
						else
							CPrintToChat(X, "%s The survivor {gold}%N{white} killed the murderer {red}%N{white}.", LOGO, attacker, murderer);
					}
				}
			}
			CS_TerminateRound(3.0, CSRoundEnd_GameStart);
		}
		
		if(count <= 1)
		{
			CS_TerminateRound(3.0, CSRoundEnd_GameStart);
			
			for(new X = 1; X <= MaxClients; X++)
			{
				if(IsClientValid(X))
				{
					if(isFrench[X])
						CPrintToChat(X, "%s L'assassin {red}%N{white} remporte la victoire !", LOGO, murderer);
					else
						CPrintToChat(X, "%s The murderer {red}%N{white} won !", LOGO, murderer);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new alive;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(IsClientValid(X))
		{
			if(IsPlayerAlive(X))
				alive++;
		}
	}
	
	if(alive <= 1)
		CS_TerminateRound(3.0, CSRoundEnd_GameStart);
	
	SetEventString(event, "attacker", "");
	return Plugin_Changed;
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	isFrench[client] = true;
	canDeagle[client] = true;
}

public OnClientConnected(client)
{
	timerHud[client] = CreateTimer(1.0, SurvivantHud, client, TIMER_REPEAT);
	timerAimHud[client] = CreateTimer(0.1, AimHud, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	KillTimer(timerHud[client]);
	KillTimer(timerAimHud[client]);
	
	if(client == murderer)
		CS_TerminateRound(3.0, CSRoundEnd_GameStart);
}

public Action:OnClientPreAdminCheck(client)
{
	if(client > 0)
	{
		CreateTimer(0.1, Respawn, client);
		
		new Handle:menuLanguage = CreateMenu(Menu_Language);
		SetMenuTitle(menuLanguage, "Language :");
		AddMenuItem(menuLanguage, "fr", "Français");
		AddMenuItem(menuLanguage, "en", "English");
		DisplayMenu(menuLanguage, client, MENU_TIME_FOREVER);
	}
}

public Action:Command_Block(client, args)
{
	return Plugin_Handled;
}

public Action:Say(client, String:command[], args)
{
	if(client > 0)
	{
		if(!IsPlayerAlive(client))
		{
			if(isFrench[client])
				CPrintToChat(client, "%s Vous êtes mort !", LOGO);
			else
				CPrintToChat(client, "%s You are dead !", LOGO);
		}
		else
		{
			decl String:arg[128];
			GetCmdArgString(arg, sizeof(arg));
			StripQuotes(arg);
			TrimString(arg);
			
			if(StrContains(arg, "{", false) != -1)
				return Plugin_Handled;
			else if(arg[0] == '/')
				return Plugin_Handled;
			
			for(new X = 1; X <= MaxClients; X++)
			{
				if(IsClientValid(X))
				{
					CPrintToChat(X, "{orange}%N{grey} : {white}%s", client, arg);
				}
			}
			PrintToServer("[SAY] %N : %s", client, arg);
		}
	}
	return Plugin_Handled;
}

public Menu_Language(Handle:menuLanguage, MenuAction:action, client, param)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menuLanguage, param, info, sizeof(info));
		
		if(StrEqual(info, "fr"))
		{
			CPrintToChat(client, "%s Votre langue : {gold}Français{white}.", LOGO);
			CPrintToChat(client, "%s Plugin réalisé par {orange}Wana{white} pour {gold}www.clan-family.com{white}.", LOGO);
		}
		else
		{
			isFrench[client] = false;
			CPrintToChat(client, "%s Your language : {gold}English{white}.", LOGO);
			CPrintToChat(client, "%s Plugin made by {orange}Wana{white} for {gold}www.clan-family.com{white}.", LOGO);
		}
	}
}

IsClientValid(X)
{
	if(X > 0 && IsClientConnected(X) && IsClientInGame(X) && IsClientAuthorized(X) && !IsFakeClient(X))
		return true;
	else
		return false;
}

ModifySpeed(client, Float:speed)
{
	if(IsClientValid(client) && IsValidEntity(client))
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsPlayerAlive(client))
	{
		if(!inUse[client] && buttons & IN_USE)
		{
			inUse[client] = true;
			
			if(client == murderer)
			{
				decl String:weaponName[64];
				Client_GetActiveWeaponName(client, weaponName, sizeof(weaponName));
				
				if(StrEqual(weaponName, "weapon_knife"))
				{
					Client_RemoveWeapon(client, weaponName);
					ModifySpeed(client, 1.0);
				}
				else
				{
					GivePlayerItem(client, "weapon_knife");
					ModifySpeed(client, 1.15);
				}
			}
			else if(client == cop)
			{
				decl String:weaponName[64];
				Client_GetActiveWeaponName(client, weaponName, sizeof(weaponName));
				
				if(StrEqual(weaponName, "weapon_deagle"))
					Client_RemoveWeapon(client, weaponName);
				else if(canDeagle[client])
				{
					CreateTimer(2.0, GetDeagle, client);
					canDeagle[client] = false;
					
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 2);
				}
			}
			else if(countItem[client] >= 3)
			{
				decl String:weaponName[64];
				Client_GetActiveWeaponName(client, weaponName, sizeof(weaponName));
				
				if(StrEqual(weaponName, "weapon_deagle"))
					Client_RemoveWeapon(client, weaponName);
				else if(canDeagle[client])
				{
					CreateTimer(2.0, GetDeagle, client);
					canDeagle[client] = false;
					
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 2);
				}
			}
			
			new aim = GetClientAimTarget(client, false);
			if(IsValidEntity(aim)
			&& client != murderer
			&& client != cop
			&& countItem[client] < 3)
			{
				decl String:entityName[64];
				Entity_GetName(aim, entityName, sizeof(entityName));
				if(StrEqual(entityName, "murder_item"))
				{
					RemoveEdict(aim);
					countItem[client]++;
					
					EmitSoundToAll("weapons/deagle/de_clipout.wav", client, _, _, _, 1.0);
					
					if(countItem[client] == 2)
					{
						if(isFrench[client])
							CPrintToChat(client, "%s Il vous manque 1 objet pour obtenir une arme.", LOGO);
						else
							CPrintToChat(client, "%s Are you missing 1 item for a weapon.", LOGO);
					}
					else
					{
						if(isFrench[client])
							CPrintToChat(client, "%s Il vous manque %i objets pour obtenir une arme.", LOGO, 3 - countItem[client]);
						else
							CPrintToChat(client, "%s Are you missing %i items for a weapon.", LOGO, 3 - countItem[client]);
					}
				}
			}
		}
		else if(inUse[client] && !(buttons & IN_USE))
			inUse[client] = false;
	}
	return Plugin_Continue;
}

public Action:unFreeze(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client)
		&& GetEntityMoveType(client) == MOVETYPE_NONE)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

public Action:GetDeagle(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client))
		{
			new weapon = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 0, 1, 0);
			Entity_SetOwner(weapon, client);
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		canDeagle[client] = true;
	}
}

public Action:Respawn(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		canDeagle[client] = true;
		
		CS_SwitchTeam(client, 2);
		
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
		
		if(!IsPlayerAlive(client) && canRespawn)
			CS_RespawnPlayer(client);
		
		GetName(client);
		
		if(IsPlayerAlive(client))
		{
			new nombre = GetRandomInt(0, 3);
			switch(nombre)
			{
				case 0:SetEntityModel(client, "models/player/t_arctic.mdl");
				case 1:SetEntityModel(client, "models/player/t_guerilla.mdl");
				case 2:SetEntityModel(client, "models/player/t_leet.mdl");
				case 3:SetEntityModel(client, "models/player/t_phoenix.mdl");
			}
		}
		
		count = 0;
		for(new X = 1; X <= MaxClients; X++)
		{
			if(IsClientValid(X))
			{
				if(IsPlayerAlive(X))
					count++;
			}
		}
		if(count == 0)
		{
			CS_TerminateRound(3.0, CSRoundEnd_GameStart);
		}
		
		ClientCommand(client, "r_screenoverlay 0");
		Client_RemoveAllWeapons(client);
		SetEntData(client, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 1, true);
		
		new nombre = GetRandomInt(0, 12);
		switch(nombre)
		{
			case 0:TeleportEntity(client, Float:{1684.299194, 660.382141, -95.968689}, Float:{0.0, -180.0, 0.0}, NULL_VECTOR);
			case 1:TeleportEntity(client, Float:{657.995117, 959.449707, -95.968689}, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
			case 2:TeleportEntity(client, Float:{1158.417358, 946.876099, -95.968689}, Float:{0.0, 0.0, 0.0}, NULL_VECTOR);
			case 3:TeleportEntity(client, Float:{667.519775, -188.350494, -95.968689}, Float:{0.0, 90.0, 0.0}, NULL_VECTOR);
			case 4:TeleportEntity(client, Float:{-532.219116, 157.147247, -95.968689}, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
			case 5:TeleportEntity(client, Float:{-176.897781, -498.722717, -95.968689}, Float:{0.0, 180.0, 0.0}, NULL_VECTOR);
			case 6:TeleportEntity(client, Float:{-338.840973, -781.718323, -215.968689}, Float:{0.0, 180.0, 0.0}, NULL_VECTOR);
			case 7:TeleportEntity(client, Float:{-703.495178, -53.732670, -303.968689}, Float:{0.0, 90.0, 0.0}, NULL_VECTOR);
			case 8:TeleportEntity(client, Float:{-703.495178, -53.732670, -303.968689}, Float:{0.0, 90.0, 0.0}, NULL_VECTOR);
			case 9:TeleportEntity(client, Float:{-1190.182007, 1182.802612, -334.476105}, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
			case 10:TeleportEntity(client, Float:{-416.270294, -1756.452393, -271.968689}, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
			case 11:TeleportEntity(client, Float:{-416.270294, -1756.452393, -271.968689}, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
			case 12:TeleportEntity(client, Float:{1023.307556, -1703.472656, -246.564636}, Float:{0.0, 90.0, 0.0}, NULL_VECTOR);
		}
	}
}

public Action:SelectMurderer(Handle:timer)
{
	canRespawn = false;
	
	for(new X = 1; X <= MaxClients; X++)
	{
		if(IsClientValid(X))
		{
			if(isFrench[X])
				PrintCenterText(X, "L'ASSASSIN A ÉTÉ SÉLÉCTIONNÉ");
			else
				PrintCenterText(X, "THE MURDERER HAS BEEN SELECTED");
		}
	}
	
	murderer = Client_GetRandom(CLIENTFILTER_ALIVE);
	CreateTimer(0.1, SelectCop, _);
	
	CreateTimer(0.1, SpawnItem, _);
}

public Action:SelectCop(Handle:timer)
{
	cop = Client_GetRandom(CLIENTFILTER_ALIVE);
	if(cop == murderer)
		CreateTimer(0.1, SelectCop, _);
}

public Action:SpawnItem(Handle:timer)
{
	if(IsValidEntity(murderer))
	{
		new MaxEntities = GetMaxEntities();
		decl String:entityName[64];
		for(new X = MaxClients; X <= MaxEntities; X++)
		{
			if(IsValidEntity(X))
			{
				Entity_GetName(X, entityName, sizeof(entityName));
				if(StrEqual(entityName, "murder_item"))
					RemoveEdict(X);
			}
		}
		
		decl String:model[64];
		new Float:teleportOrigin[3];
		new nombre = GetRandomInt(0, 14);
		if(nombre == 0)
		{
			model = "models/props/de_tides/vending_turtle.mdl";
			teleportOrigin = Float:{93.462707, 232.295867, -159.968750};
		}
		else if(nombre == 1)
		{
			model = "models/weapons/w_c4_planted.mdl";
			teleportOrigin = Float:{658.977844, -198.901840, -159.968750};
		}
		else if(nombre == 2)
		{
			model = "models/props_c17/suitcase001a.mdl";
			teleportOrigin = Float:{566.585327, 522.289733, -159.968750};
		}
		else if(nombre == 3)
		{
			model = "models/props/de_prodigy/tire2.mdl";
			teleportOrigin = Float:{1511.660034, 966.556640, -159.968750};
		}
		else if(nombre == 4)
		{
			model = "models/props_c17/oildrum001.mdl";
			teleportOrigin = Float:{1711.975585, 677.544189, -159.968750};
		}
		else if(nombre == 5)
		{
			model = "models/props_c17/canister_propane01a.mdl";
			teleportOrigin = Float:{1497.475952, 337.979370, -159.968750};
		}
		else if(nombre == 6)
		{
			model = "models/props_c17/clock01.mdl";
			teleportOrigin = Float:{1498.054199, -500.358886, -159.968750};
		}
		else if(nombre == 7)
		{
			model = "models/props_c17/doll01.mdl";
			teleportOrigin = Float:{953.549865, -506.516296, -159.968750};
		}
		else if(nombre == 8)
		{
			model = "models/props/de_inferno/potted_plant2.mdl";
			teleportOrigin = Float:{-4.580379, -1096.226928, -223.968750};
		}
		else if(nombre == 9)
		{
			model = "models/props/cs_office/phone.mdl";
			teleportOrigin = Float:{-1170.225097, -774.086547, -328.000000};
		}
		else if(nombre == 10)
		{
			model = "models/props/cs_office/water_bottle.mdl";
			teleportOrigin = Float:{-265.869262, -1991.151977, -335.968750};
		}
		else if(nombre == 11)
		{
			model = "models/props_junk/watermelon01.mdl";
			teleportOrigin = Float:{1086.077270, -1433.484863, -333.733032};
		}
		else if(nombre == 12)
		{
			model = "models/props/cs_office/trash_can_p.mdl";
			teleportOrigin = Float:{309.676330, -1326.657348, -279.968750};
		}
		else if(nombre == 13)
		{
			model = "models/props_junk/wood_crate001a_chunk05.mdl";
			teleportOrigin = Float:{1115.223266, -902.258911, -159.968750};
		}
		else if(nombre == 14)
		{
			model = "models/props_debris/concrete_cynderblock001.mdl";
			teleportOrigin = Float:{-705.912902, 231.611480, -367.968750};
		}
		
		new ent = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(ent, "solid", "1");
		DispatchKeyValue(ent, "model", model);
		DispatchSpawn(ent);
		TeleportEntity(ent, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
		Entity_SetName(ent, "murder_item");
		SetEntityRenderColor(ent, 255, 255, 128, 255);
		
		if(nombre == 0)
			nombre = 1;
		else if(nombre == 14)
			nombre = 13;
		else
			nombre += 1;
		
		if(nombre == 1)
		{
			model = "models/weapons/w_c4_planted.mdl";
			teleportOrigin = Float:{658.977844, -198.901840, -159.968750};
		}
		else if(nombre == 2)
		{
			model = "models/props_c17/suitcase001a.mdl";
			teleportOrigin = Float:{566.585327, 522.289733, -159.968750};
		}
		else if(nombre == 3)
		{
			model = "models/props/de_prodigy/tire2.mdl";
			teleportOrigin = Float:{1511.660034, 966.556640, -159.968750};
		}
		else if(nombre == 4)
		{
			model = "models/props_c17/oildrum001.mdl";
			teleportOrigin = Float:{1711.975585, 677.544189, -159.968750};
		}
		else if(nombre == 5)
		{
			model = "models/props_c17/canister_propane01a.mdl";
			teleportOrigin = Float:{1497.475952, 337.979370, -159.968750};
		}
		else if(nombre == 6)
		{
			model = "models/props_c17/clock01.mdl";
			teleportOrigin = Float:{1498.054199, -500.358886, -159.968750};
		}
		else if(nombre == 7)
		{
			model = "models/props_c17/doll01.mdl";
			teleportOrigin = Float:{953.549865, -506.516296, -159.968750};
		}
		else if(nombre == 8)
		{
			model = "models/props/de_inferno/potted_plant2.mdl";
			teleportOrigin = Float:{-4.580379, -1096.226928, -223.968750};
		}
		else if(nombre == 9)
		{
			model = "models/props/cs_office/phone.mdl";
			teleportOrigin = Float:{-1170.225097, -774.086547, -328.000000};
		}
		else if(nombre == 10)
		{
			model = "models/props/cs_office/water_bottle.mdl";
			teleportOrigin = Float:{-265.869262, -1991.151977, -335.968750};
		}
		else if(nombre == 11)
		{
			model = "models/props_junk/watermelon01.mdl";
			teleportOrigin = Float:{1086.077270, -1433.484863, -333.733032};
		}
		else if(nombre == 12)
		{
			model = "models/props/cs_office/trash_can_p.mdl";
			teleportOrigin = Float:{309.676330, -1326.657348, -279.968750};
		}
		else if(nombre == 13)
		{
			model = "models/props_junk/wood_crate001a_chunk05.mdl";
			teleportOrigin = Float:{1115.223266, -902.258911, -159.968750};
		}
		
		ent = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(ent, "solid", "1");
		DispatchKeyValue(ent, "model", model);
		DispatchSpawn(ent);
		TeleportEntity(ent, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
		Entity_SetName(ent, "murder_item");
		SetEntityRenderColor(ent, 255, 255, 128, 255);
		
		if(count >= 3)
			CreateTimer(30.0, SpawnItem, _);
	}
}

public Action:CountTimer(Handle:timer)
{
	count = 0;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(IsClientValid(X))
		{
			count++;
		}
	}
	
	if(count >= 3)
		minPlayer = true;
	else
		minPlayer = false;
	
	if(minPlayer && canRound)
	{
		CS_TerminateRound(3.0, CSRoundEnd_GameStart);
		canRound = false;
	}
	
	new MaxEntities = GetMaxEntities();
	decl String:className[64];
	for(new X = MaxClients; X <= MaxEntities; X++)
	{
		if(IsValidEntity(X))
		{
			Entity_GetClassName(X, className, sizeof(className));
			if(StrContains(className, "weapon_", false) != -1)
			{
				new owner = Entity_GetOwner(X);
				if(!IsValidEntity(owner))
					RemoveEdict(X);
			}
		}
	}
}

public Action:SurvivantHud(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		CS_SetClientClanTag(client, "Innocent");
		Client_SetScore(client, 0);
		
		if(!IsPlayerAlive(client))
		{
			Client_Mute(client);
			if(isFrench[client])
				PrintCenterText(client, "VOUS ÊTES MORT, ATTENDEZ LA FIN DU ROUND");
			else
				PrintCenterText(client, "YOU ARE DEAD, EXPECT THE END OF ROUND");
		}
		else
			Client_UnMute(client);
		
		if(client == murderer)
		{
			new weapon = GetPlayerWeaponSlot(client, 1);
			if(weapon != -1)
				Client_RemoveWeapon(client, "weapon_deagle");
		}
		
		new survivant = -1;
		for(new X = 1; X <= MaxClients; X++)
		{
			if(IsClientValid(X))
			{
				if(IsPlayerAlive(X))
					survivant++;
			}
		}
		
		decl String:strText[128];
		if(isFrench[client])
		{
			if(survivant <= 1)
				Format(strText, sizeof(strText), "Pseudo : %s", tempName[client]);
			else
				Format(strText, sizeof(strText), "Survivants : %i\nPseudo : %s", survivant, tempName[client]);
		}
		else
		{
			if(survivant <= 1)
				Format(strText, sizeof(strText), "Nickname : %s", tempName[client]);
			else
				Format(strText, sizeof(strText), "Survivors : %i\nNickname : %s", survivant, tempName[client]);
		}
		
		new Handle:hBuffer = StartMessageOne("KeyHintText", client);
		BfWriteByte(hBuffer, 1); 
		BfWriteString(hBuffer, strText); 
		EndMessage();
		
		if(count <= 2)
		{
			if(isFrench[client])
			{
				if(count == 1)
					PrintCenterText(client, "En attente de 2 joueurs ...");
				else if(count == 2)
					PrintCenterText(client, "En attente d'un joueur ...");
			}
			else
			{
				if(count == 1)
					PrintCenterText(client, "Waiting for 2 players ...");
				else if(count == 2)
					PrintCenterText(client, "Waiting for 1 player ...");
			}
			
		}
		
		decl String:strFr[16], String:strEn[16];
		if(IsPlayerAlive(client))
		{
			if(murderer == client)
			{
				decl String:weaponName[64];
				Client_GetActiveWeaponName(client, weaponName, sizeof(weaponName));
				if(StrEqual(weaponName, "weapon_knife"))
				{
					Format(strFr, sizeof(strFr), "ranger");
					Format(strEn, sizeof(strEn), "store");
				}
				else
				{
					Format(strFr, sizeof(strFr), "sortir");
					Format(strEn, sizeof(strEn), "exit");
				}
				
				if(isFrench[client])
					PrintHintText(client, "Vous êtes l'assassin.\nAppuyer sur utiliser pour %s votre couteau.", strFr);
				else
					PrintHintText(client, "You are the murderer.\nPress use to %s your knife.", strEn);
			}
			else if(murderer != -1)
			{
				decl String:weaponName[64];
				Client_GetActiveWeaponName(client, weaponName, sizeof(weaponName));
				if(StrEqual(weaponName, "weapon_deagle"))
				{
					Format(strFr, sizeof(strFr), "ranger");
					Format(strEn, sizeof(strEn), "store");
				}
				else
				{
					Format(strFr, sizeof(strFr), "sortir");
					Format(strEn, sizeof(strEn), "exit");
				}
				
				if(client == cop)
				{
					if(isFrench[client])
						PrintHintText(client, "Vous êtes policier.\nAppuyer sur utiliser pour %s ou recharger votre arme.", strFr);
					else
						PrintHintText(client, "You are a cop.\nPress use to %s or reload your weapon .", strEn);
				}
				else if(countItem[client] >= 3)
				{
					if(isFrench[client])
						PrintHintText(client, "Vous êtes innocent.\nAppuyer sur utiliser pour %s ou recharger votre arme.", strFr);
					else
						PrintHintText(client, "You are innocent.\nPress use to %s or reload your weapon .", strEn);
				}
				else
				{
					if(isFrench[client])
						PrintHintText(client, "Vous êtes innocent.\nChercher les objets pour obtenir une arme.");
					else
						PrintHintText(client, "You are innocent.\nSearch the items to get a weapon.");
				}
			}
		}
		else
			ClientCommand(client, "r_screenoverlay effects/black");
	}
}

public Action:AimHud(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		new aim = GetClientAimTarget(client, true);
		if(IsValidEntity(aim))
		{
			PrintHintText(client, "%s", tempName[aim]);
		}
	}
}

GetName(client)
{
	new nombre = GetRandomInt(0, 63);
	if(nameUse[nombre])
		GetName(client);
	else
	{
		if(nombre == 0)
			tempName[client] = "Aatrox";
		else if(nombre == 1)
			tempName[client] = "Ahri";
		else if(nombre == 2)
			tempName[client] = "Blitzcrank";
		else if(nombre == 3)
			tempName[client] = "Braum";
		else if(nombre == 4)
			tempName[client] = "Cho'Gath";
		else if(nombre == 5)
			tempName[client] = "Darius";
		else if(nombre == 6)
			tempName[client] = "Evelynn";
		else if(nombre == 7)
			tempName[client] = "Fizz";
		else if(nombre == 8)
			tempName[client] = "Fiddlestick";
		else if(nombre == 9)
			tempName[client] = "Galio";
		else if(nombre == 10)
			tempName[client] = "Garen";
		else if(nombre == 11)
			tempName[client] = "Gragas";
		else if(nombre == 12)
			tempName[client] = "Vayne";
		else if(nombre == 13)
			tempName[client] = "Irelia";
		else if(nombre == 14)
			tempName[client] = "Jax";
		else if(nombre == 15)
			tempName[client] = "Kha'Zix";
		else if(nombre == 16)
			tempName[client] = "Lee Sin";
		else if(nombre == 17)
			tempName[client] = "Teemo";
		else if(nombre == 18)
			tempName[client] = "Lucian";
		else if(nombre == 19)
			tempName[client] = "Lux";
		else if(nombre == 20)
			tempName[client] = "Malzahar";
		else if(nombre == 21)
			tempName[client] = "Poppy";
		else if(nombre == 22)
			tempName[client] = "Nautilus";
		else if(nombre == 23)
			tempName[client] = "Nidalee";
		else if(nombre == 24)
			tempName[client] = "Nasus";
		else if(nombre == 25)
			tempName[client] = "Olaf";
		else if(nombre == 26)
			tempName[client] = "Pantheon";
		else if(nombre == 27)
			tempName[client] = "Rammus";
		else if(nombre == 28)
			tempName[client] = "Zilean";
		else if(nombre == 29)
			tempName[client] = "Xerath";
		else if(nombre == 30)
			tempName[client] = "Renekton";
		else if(nombre == 31)
			tempName[client] = "Shen";
		else if(nombre == 32)
			tempName[client] = "Riven";
		else if(nombre == 33)
			tempName[client] = "Tryndamere";
		else if(nombre == 34)
			tempName[client] = "Thresh";
		else if(nombre == 35)
			tempName[client] = "Alistar";
		else if(nombre == 36)
			tempName[client] = "Urgot";
		else if(nombre == 37)
			tempName[client] = "Lulu";
		else if(nombre == 38)
			tempName[client] = "Varus";
		else if(nombre == 39)
			tempName[client] = "Caitlyn";
		else if(nombre == 40)
			tempName[client] = "Ashe";
		else if(nombre == 41)
			tempName[client] = "Draven";
		else if(nombre == 42)
			tempName[client] = "Twisted Fate";
		else if(nombre == 43)
			tempName[client] = "Zed";
		else if(nombre == 44)
			tempName[client] = "Jinx";
		else if(nombre == 45)
			tempName[client] = "Lissandra";
		else if(nombre == 46)
			tempName[client] = "Leona";
		else if(nombre == 47)
			tempName[client] = "Katarina";
		else if(nombre == 48)
			tempName[client] = "LeBlanc";
		else if(nombre == 49)
			tempName[client] = "Shaco";
		else if(nombre == 50)
			tempName[client] = "Kassadin";
		else if(nombre == 51)
			tempName[client] = "Vegar";
		else if(nombre == 52)
			tempName[client] = "Tristana";
		else if(nombre == 53)
			tempName[client] = "Heimerdinger";
		else if(nombre == 54)
			tempName[client] = "Jarvan IV";
		else if(nombre == 55)
			tempName[client] = "Vi";
		else if(nombre == 56)
			tempName[client] = "Karma";
		else if(nombre == 57)
			tempName[client] = "Orianna";
		else if(nombre == 58)
			tempName[client] = "Zac";
		else if(nombre == 59)
			tempName[client] = "Nunu";
		else if(nombre == 60)
			tempName[client] = "Kayle";
		else if(nombre == 61)
			tempName[client] = "Soraka";
		else if(nombre == 62)
			tempName[client] = "Ryze";
		else if(nombre == 63)
			tempName[client] = "Abassi";
		
		nameUse[nombre] = true;
	}
}