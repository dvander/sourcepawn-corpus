#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>

new g_ModelIndex[2049];
new Float:g_flZOffset[2049];
new Float:g_flModelScale[2049];
new String:g_strParticle[2049][36];
new bool:g_bWantsTheH[MAXPLAYERS+1];

new g_hatEnt[2049] = {INVALID_ENT_REFERENCE, ... };
new g_particleEnt[2049] = {INVALID_ENT_REFERENCE, ... };

new stringTable;
new Handle:hHatInfo = INVALID_HANDLE;

new Float:RollCooldown[MAXPLAYERS+1];

new const String:g_sParticleList[][] =
{
	{"superrare_confetti_green"},
	{"superrare_confetti_purple"},
	{"superrare_ghosts"},
	{"superrare_greenenergy"},
	{"superrare_purpleenergy"},
	{"superrare_flies"},
	{"superrare_burning1"},
	{"superrare_burning2"},
	{"superrare_plasma1"},
	{"superrare_beams1"},
	{"unusual_storm"},
	{"unusual_blizzard"},
	{"unusual_orbit_nutsnbolts"},
	{"unusual_orbit_fire"},
	{"unusual_bubbles"},
	{"unusual_smoking"},
	{"unusual_steaming"},
	{"unusual_bubbles_green"},
	{"unusual_orbit_fire_dark"},
	{"unusual_storm_knives"},
	{"unusual_storm_spooky"},
	{"unusual_zap_yellow"},
	{"unusual_zap_green"},
	{"unusual_hearts_bubbling"},
	{"unusual_crisp_spotlights"},
	{"unusual_spotlights"},
	{"unusual_robot_holo_glow_green"},
	{"unusual_robot_holo_glow_orange"},
	{"unusual_robot_orbit_binary"},
	{"unusual_robot_orbit_binary2"},
	{"unusual_robot_orbiting_sparks"},
	{"unusual_robot_orbiting_sparks2"},
	{"unusual_robot_radioactive"},
	{"unusual_robot_time_warp"},
	{"unusual_robot_time_warp2"},
	{"unusual_robot_radioactive2"},
	{"unusual_spellbook_circle_purple"},
	{"unusual_spellbook_circle_green"},
	{"unusual_souls_purple_parent"},
	{"unusual_souls_green_parent"}
}

new Handle:g_hCvarVersion;
new Handle:g_hCvarEnabled,			bool:g_bCvarEnabled;
new Handle:g_hCvarUnusualChance,	Float:g_flCvarUnusualChance;
new Handle:g_hCvarRerollCooldown,	g_CvarRerollCooldown;

new Handle:g_hParticleMenu = INVALID_HANDLE;
new Handle:g_hClientCookie = INVALID_HANDLE;

#define PLUGIN_VERSION 		"2.0"

public Plugin:myinfo = 
{
	name		= "[TF2] Building Hats",
	author		= "Pelipoika",
	description	= "Ain't that a cute little gun?",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2164412#post2164412"
};

public OnPluginStart()
{
	g_hCvarVersion = CreateConVar("sm_bhats_version", PLUGIN_VERSION, "Current Building Hats Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(g_hCvarEnabled = CreateConVar("sm_bhats_enabled", "1.0", "Enable Hats on Buildings \n 0 = Disabled \n 1 = Enabled", _, true, 0.0, true, 1.0), OnConVarChange);
	HookConVarChange(g_hCvarUnusualChance = CreateConVar("sm_bhats_unusualchance", "0.1", "Chance for a building to get an unusual effect on it's hat upon being built. 0.1 = 10%", _, true, 0.0), OnConVarChange);
	HookConVarChange(g_hCvarRerollCooldown = CreateConVar("sm_bhats_rollcooldown", "30", "Hat reroll cooldown (in seconds)", _, true, 0.0), OnConVarChange);
	
	HookEvent("player_builtobject",		Event_PlayerBuiltObject);
	HookEvent("player_upgradedobject",	Event_UpgradeObject);
	HookEvent("player_dropobject", 		Event_DropObject);
	HookEvent("player_carryobject",		Event_PickupObject);
	
	stringTable = FindStringTable("modelprecache");
	hHatInfo = CreateArray(PLATFORM_MAX_PATH, 1);
	
	g_hClientCookie = RegClientCookie("BuildingHats", "sm_bhats_enabled", CookieAccess_Private);
	
	RegAdminCmd("sm_buildinghats",		 Command_iDontWantHatsOnMyThings, 0);
	RegAdminCmd("sm_bhats_reloadconfig", Command_Parse, ADMFLAG_ROOT);
	RegAdminCmd("sm_rerollhat", 		 Command_RerollHats, 0);
	RegAdminCmd("sm_buildinghateffect",  Command_ChooseBuildingEffect, ADMFLAG_ROOT);
	
	AutoExecConfig(true);
	
	for(new i = 0; i <= MaxClients; i++)
	{
		if(i > 0 && i <= MaxClients && IsClientInGame(i))
			g_bWantsTheH[i] = true;
	}
}

public OnConfigsExecuted()
{
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
	g_bCvarEnabled  = GetConVarBool(g_hCvarEnabled);
	g_flCvarUnusualChance = GetConVarFloat(g_hCvarUnusualChance);
	g_CvarRerollCooldown = GetConVarInt(g_hCvarRerollCooldown);
	ParseConfigurations();
	
	g_hParticleMenu = CreateMenu(Menu_SetEffect);
	SetMenuTitle(g_hParticleMenu, "[Building Hats] Hat Effects");
	for(new i = 0; i < sizeof(g_sParticleList); i++)
	{
		decl String:info[128], String:display[128];
		Format(info, sizeof(info), "%s", g_sParticleList[i][0]);
		Format(display, sizeof(display), "%s", g_sParticleList[i][0]);
		AddMenuItem(g_hParticleMenu, info, display);
	}
	SetMenuExitBackButton(g_hParticleMenu, false); 
}

public OnClientAuthorized(client)
{
	g_bWantsTheH[client] = true;
	RollCooldown[client] = 0.0;
}

public OnClientCookiesCached(client)
{
	decl String:sValue[8];
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
    
	if(sValue[0] == '\0')
		g_bWantsTheH[client] = true;
	else
		g_bWantsTheH[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public OnMapEnd()
{
	if(g_hParticleMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hParticleMenu);
		g_hParticleMenu = INVALID_HANDLE;
	}
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	g_flCvarUnusualChance = GetConVarFloat(g_hCvarUnusualChance);
	g_CvarRerollCooldown = GetConVarInt(g_hCvarRerollCooldown);
}

public Action:Command_ChooseBuildingEffect(client, args)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		DisplayMenuSafely(g_hParticleMenu, client);
		
	return Plugin_Handled;
}

public Menu_SetEffect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new iBuilding = -1;
		while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1) 
		{
			if(GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == param1 && GetEntProp(iBuilding, Prop_Send, "m_bPlacing") == 0 && GetEntProp(iBuilding, Prop_Send, "m_bCarried") == 0)
			{
				if(IsValidEntity(g_particleEnt[iBuilding]))
				{
					new particle = EntRefToEntIndex(g_particleEnt[iBuilding]);
					AcceptEntityInput(particle, "Stop");
					AcceptEntityInput(particle, "Kill");
				}
				
				new iParticle = CreateEntityByName("info_particle_system"); 
				if(IsValidEdict(iParticle))
				{
					new Float:flPos[3]; 

					DispatchKeyValue(iParticle, "effect_name", info); 
					DispatchSpawn(iParticle); 
					
					SetVariantString("!activator"); 
					AcceptEntityInput(iParticle, "SetParent", iBuilding); 
					ActivateEntity(iParticle); 

					new TFObjectType:objectT = TFObjectType:TF2_GetObjectType(iBuilding);
					if(objectT == TFObject_Dispenser)
					{
						SetVariantString("build_point_0");
					}
					else if(objectT == TFObject_Sentry)
					{
						if(GetEntProp(iBuilding, Prop_Send, "m_iUpgradeLevel") < 3)
							SetVariantString("build_point_0");
						else
							SetVariantString("rocket_r");
					}
					AcceptEntityInput(iParticle, "SetParentAttachment", iBuilding);
					
					GetEntPropVector(iParticle, Prop_Send, "m_vecOrigin", flPos);
					
					if(objectT == TFObject_Dispenser)
					{
						flPos[2] += 13.0;	//Make sure the effect is on top of the dispenser
						
						if(GetEntProp(iBuilding, Prop_Send, "m_iUpgradeLevel") == 3)
							flPos[2] += 8.0;	//Account for level 3 dispenser
					}
					
					if(GetEntProp(iBuilding, Prop_Send, "m_iUpgradeLevel") == 3 && objectT != TFObject_Dispenser)
					{
						flPos[2] += 6.5;	//Level 3 sentry offsets
						flPos[0] -= 11.0;	//Gotta get that effect on top of the missile thing
					}
					
					SetEntPropVector(iParticle, Prop_Send, "m_vecOrigin", flPos);
					AcceptEntityInput(iParticle, "start"); 
					
					g_particleEnt[iBuilding] = EntIndexToEntRef(iParticle);
					Format(g_strParticle[iBuilding], sizeof(g_strParticle), "%s", info);
				}
			}
		}
		
		DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER); 
	}
}

public Action:Command_RerollHats(client, args)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(CheckCommandAccess(client, "sm_buildinghats_access", 0))
		{
			if(RollCooldown[client] >= GetTickedTime())
			{
				ReplyToCommand(client, "Please wait %.1f seconds!", RollCooldown[client] - GetTickedTime());
				return Plugin_Handled;
			}
			else
			{
				new iBuilding = -1;
				while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1) 
				{
					if(GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == client
					&& GetEntProp(iBuilding, Prop_Send, "m_bPlacing") == 0
					&& GetEntProp(iBuilding, Prop_Send, "m_bCarried") == 0)
					{
						g_ModelIndex[iBuilding]  = INVALID_STRING_INDEX;
						g_flZOffset[iBuilding]   = 0.0;
						g_flModelScale[iBuilding]= 0.0;
						Format(g_strParticle[iBuilding], sizeof(g_strParticle), "");

						if (IsValidEntity(g_hatEnt[iBuilding]))
						{
							AcceptEntityInput(g_hatEnt[iBuilding], "Kill");
						}
						
						if(IsValidEntity(g_particleEnt[iBuilding]))
						{
							AcceptEntityInput(g_particleEnt[iBuilding], "Stop");
							AcceptEntityInput(g_particleEnt[iBuilding], "Kill");
						}
						
						g_particleEnt[iBuilding] = INVALID_ENT_REFERENCE;
						g_hatEnt[iBuilding] = INVALID_ENT_REFERENCE;
						
						CreateTimer(0.1, Timer_ReHat, iBuilding);
					}
				}
				
				RollCooldown[client] = GetTickedTime() + float(g_CvarRerollCooldown);
			}
		}
		else
			ReplyToCommand(client, "[SM] You do not have acces to this command.");
	}
	
	return Plugin_Handled;
}

public Action:Command_iDontWantHatsOnMyThings(client, args)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(CheckCommandAccess(client, "sm_buildinghats_access", 0))
		{
			if(!g_bWantsTheH[client])
			{
				SetClientCookie(client, g_hClientCookie, "1");
				OnClientCookiesCached(client);
				g_bWantsTheH[client] = true;
				PrintToChat(client, "[Building Hats] On");
			}
			else
			{
				SetClientCookie(client, g_hClientCookie, "0");
				OnClientCookiesCached(client);
			
				g_bWantsTheH[client] = false;
				PrintToChat(client, "[Building Hats] Off");
				
				new iBuilding = -1;
				while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1) 
				{
					if(GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == client)
					{
						if (IsValidEntity(g_hatEnt[iBuilding]))
						{
							AcceptEntityInput(g_hatEnt[iBuilding], "Kill");
							g_hatEnt[iBuilding] = INVALID_ENT_REFERENCE;
						}
						if(IsValidEntity(g_particleEnt[iBuilding]))
						{
							AcceptEntityInput(g_particleEnt[iBuilding], "Stop");
							AcceptEntityInput(g_particleEnt[iBuilding], "Kill");
							g_particleEnt[iBuilding] = INVALID_ENT_REFERENCE;
						}
						
						if (GetEntProp(iBuilding, Prop_Send, "m_bMiniBuilding"))
						{
							SetVariantInt(0);
							AcceptEntityInput(iBuilding, "SetBodyGroup");
						}
					}
				}
			}
		}
		else
			ReplyToCommand(client, "[SM] You do not have acces to this command.");
	}
	
	return Plugin_Handled;
}

public Action:Command_Parse(client, args)
{
	ResizeArray(hHatInfo, 1);
	ReplyToCommand(client, "[Building Hats] Reloading config...");
	ParseConfigurations();
	return Plugin_Handled;
}

public Action:Event_PickupObject(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			if (IsValidEntity(g_hatEnt[iBuilding]))
			{
				AcceptEntityInput(g_hatEnt[iBuilding], "TurnOff");
			}
			if(IsValidEntity(g_particleEnt[iBuilding]))
			{
				AcceptEntityInput(g_particleEnt[iBuilding], "Stop");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_DropObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bCvarEnabled) 
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFObjectType:objectT = TFObjectType:GetEventInt(event, "object");
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_bWantsTheH[client])
	{
		if(!CheckCommandAccess(client, "sm_buildinghats_access", 0))
			return Plugin_Handled;
	
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			if(objectT == TFObject_Sentry && GetEntProp(iBuilding, Prop_Send, "m_bMiniBuilding"))
			{
				SetVariantInt(2);
				AcceptEntityInput(iBuilding, "SetBodyGroup");
				CreateTimer(2.0, Timer_TurnTheLightsOff, iBuilding);
			}
			
			if (IsValidEntity(g_hatEnt[iBuilding]))
			{
				AcceptEntityInput(g_hatEnt[iBuilding], "TurnOn");
			}

			if(IsValidEntity(g_particleEnt[iBuilding]))
			{
				AcceptEntityInput(g_particleEnt[iBuilding], "Start");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_UpgradeObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bCvarEnabled) 
		return Plugin_Continue;

	new TFObjectType:objectT = TFObjectType:GetEventInt(event, "object");
	
	new iBuilding = GetEventInt(event, "index");
	if(iBuilding > MaxClients && IsValidEntity(iBuilding))
	{
		new builder = GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder");
		if(builder >= 1 && builder <= MaxClients && IsClientInGame(builder) && !g_bWantsTheH[builder] || !CheckCommandAccess(builder, "sm_buildinghats_access", 0))
			return Plugin_Handled;
		
		if(objectT == TFObject_Sentry)
		{
			if (IsValidEntity(g_hatEnt[iBuilding]))
			{
				AcceptEntityInput(g_hatEnt[iBuilding], "Kill");
				g_hatEnt[iBuilding] = INVALID_ENT_REFERENCE;
			}
			
			if(IsValidEntity(g_particleEnt[iBuilding]))
			{
				AcceptEntityInput(g_particleEnt[iBuilding], "Stop");
				AcceptEntityInput(g_particleEnt[iBuilding], "Kill");
				g_particleEnt[iBuilding] = INVALID_ENT_REFERENCE;
			}
			
			CreateTimer(2.0, Timer_ReHat, iBuilding);
		}
		if(objectT == TFObject_Dispenser && GetEntProp(iBuilding, Prop_Send, "m_iUpgradeLevel") == 2)
		{
			if (IsValidEntity(g_hatEnt[iBuilding]))
			{
				AcceptEntityInput(g_hatEnt[iBuilding], "Kill");
				g_hatEnt[iBuilding] = INVALID_ENT_REFERENCE;
			}
			
			if(IsValidEntity(g_particleEnt[iBuilding]))
			{
				AcceptEntityInput(g_particleEnt[iBuilding], "Stop");
				AcceptEntityInput(g_particleEnt[iBuilding], "Kill");
				g_particleEnt[iBuilding] = INVALID_ENT_REFERENCE;
			}
			
			CreateTimer(2.0, Timer_ReHat, iBuilding);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_ReHat(Handle:timer, any:iBuilding)
{
	if(!g_bCvarEnabled) 
		return Plugin_Continue;

	if(iBuilding > MaxClients && IsValidEntity(iBuilding))
	{
		decl String:strPath[PLATFORM_MAX_PATH], String:strOffz[16], String:strScale[16], String:strAnima[128];
		new row = (GetArraySize(hHatInfo) / 4) - 1;
		new index = (GetRandomInt(0, row)) * 4;

		GetArrayString(hHatInfo, index+1, strPath, sizeof(strPath));
		GetArrayString(hHatInfo, index+2, strOffz, sizeof(strOffz));
		GetArrayString(hHatInfo, index+3, strScale, sizeof(strScale));
		GetArrayString(hHatInfo, index+4, strAnima, sizeof(strAnima));
		
		new TFObjectType:objectT = TFObjectType:TF2_GetObjectType(iBuilding)
		
		if(objectT == TFObject_Sentry)
			ParentHatEntity(iBuilding, strPath, StringToFloat(strOffz), StringToFloat(strScale), TFObject_Sentry, strAnima);
		else if(objectT == TFObject_Dispenser)
			ParentHatEntity(iBuilding, strPath, StringToFloat(strOffz), StringToFloat(strScale), TFObject_Dispenser, strAnima);
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bCvarEnabled) 
		return Plugin_Continue;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFObjectType:objectT = TFObjectType:GetEventInt(event, "object");
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_bWantsTheH[client])
	{
		if(!CheckCommandAccess(client, "sm_buildinghats_access", 0))
			return Plugin_Handled;
		
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding))
		{
			if(!GetEntProp(iBuilding, Prop_Send, "m_bCarryDeploy"))
			{
				g_ModelIndex[iBuilding]  = INVALID_STRING_INDEX;
				g_flZOffset[iBuilding]   = 0.0;
				g_flModelScale[iBuilding]= 0.0;
				Format(g_strParticle[iBuilding], sizeof(g_strParticle), "");
				
				decl String:strPath[PLATFORM_MAX_PATH], String:strOffz[16], String:strScale[16], String:strAnima[128];
				new row = (GetArraySize(hHatInfo) / 4) - 1;
				new index = (GetRandomInt(0, row)) * 4;

				GetArrayString(hHatInfo, index+1, strPath, sizeof(strPath));
				GetArrayString(hHatInfo, index+2, strOffz, sizeof(strOffz));
				GetArrayString(hHatInfo, index+3, strScale, sizeof(strScale));
				GetArrayString(hHatInfo, index+4, strAnima, sizeof(strAnima));
			
				if(objectT == TFObject_Sentry)
				{
					if(GetEntProp(iBuilding, Prop_Send, "m_bMiniBuilding"))
					{
						SetVariantInt(2);
						AcceptEntityInput(iBuilding, "SetBodyGroup");
						CreateTimer(3.0, Timer_TurnTheLightsOff, iBuilding);
					}

					ParentHatEntity(iBuilding, strPath, StringToFloat(strOffz), StringToFloat(strScale), TFObject_Sentry, strAnima);
				//	PrintToChatAll("%s", strPath);
				}
				else if(objectT == TFObject_Dispenser)
				{
					ParentHatEntity(iBuilding, strPath, StringToFloat(strOffz), StringToFloat(strScale), TFObject_Dispenser, strAnima);
				//	PrintToChatAll("%s", strPath);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_TurnTheLightsOff(Handle:timer, any:iBuilding)
{
	if(!g_bCvarEnabled) 
		return Plugin_Continue;

	if(iBuilding > MaxClients && IsValidEntity(iBuilding))
	{
		SetVariantInt(2);
		AcceptEntityInput(iBuilding, "SetBodyGroup");
	}
	
	return Plugin_Continue;
}

//Avert your eyes children.
ParentHatEntity(entity, const String:smodel[], Float:flZOffset = 0.0, Float:flModelScale, TFObjectType:objectT, const String:strAnimation[])
{
	new Float:pPos[3], Float:pAng[3];
	new builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	new prop = CreateEntityByName("prop_dynamic_override");

	new String:strModelPath[PLATFORM_MAX_PATH];
	
	if(g_ModelIndex[entity] != INVALID_STRING_INDEX)
		ReadStringTable(stringTable, g_ModelIndex[entity], strModelPath, PLATFORM_MAX_PATH);  
	
	if(StrEqual(strModelPath, "", false))
		g_ModelIndex[entity] = PrecacheModel(smodel);
	
	if(IsValidEntity(prop))
	{
		if(!StrEqual(strModelPath, "", false))
			DispatchKeyValue(prop, "model", strModelPath); 
		else
			DispatchKeyValue(prop, "model", smodel); 
			
		if(g_flModelScale[entity] != 0.0)
			SetEntPropFloat(prop, Prop_Send, "m_flModelScale", g_flModelScale[entity]);
		else
			SetEntPropFloat(prop, Prop_Send, "m_flModelScale", flModelScale);

		DispatchSpawn(prop);
		AcceptEntityInput(prop, "Enable");
		SetEntProp(prop, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity);
		
		if(objectT == TFObject_Dispenser)
		{
			SetVariantString("build_point_0");
		}
		else if(objectT == TFObject_Sentry)
		{
			if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") < 3)
				SetVariantString("build_point_0");
			else
				SetVariantString("rocket_r");
		}
			
		AcceptEntityInput(prop, "SetParentAttachment", entity);
		
		GetEntPropVector(prop, Prop_Send, "m_vecOrigin", pPos);
		GetEntPropVector(prop, Prop_Send, "m_angRotation", pAng);
		
		if(!StrEqual(strAnimation, "default", false))
		{
			SetVariantString(strAnimation);
			AcceptEntityInput(prop, "SetAnimation");  
			SetVariantString(strAnimation);
			AcceptEntityInput(prop, "SetDefaultAnimation");
		}
		
		if(g_flZOffset[entity] != 0.0)
			pPos[2] += g_flZOffset[entity];
		else
			pPos[2] += flZOffset;
			
		if(objectT == TFObject_Dispenser)
		{
			pPos[2] += 13.0;	//Make sure the hat is on top of the dispenser
			pAng[1] += 180.0;	//Make hat face builder
			
			if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3)
			{
				pPos[2] += 8.0;	//Account for level 3 dispenser
			}
		}
		
		if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3 && objectT != TFObject_Dispenser)
		{
			pPos[2] += 6.5;		//Level 3 sentry offsets
			pPos[0] -= 11.0;	//Gotta get that hat on top of the missile thing
		}
		
		SetEntPropVector(prop, Prop_Send, "m_vecOrigin", pPos);
		SetEntPropVector(prop, Prop_Send, "m_angRotation", pAng);
		
		g_hatEnt[entity] = EntIndexToEntRef(prop);
		
		if(g_flZOffset[entity] == 0.0)
			g_flZOffset[entity] = flZOffset;
			
		if(g_flModelScale[entity] == 0.0)
			g_flModelScale[entity] = flModelScale;

		if(g_particleEnt[entity] == INVALID_ENT_REFERENCE && CheckCommandAccess(builder, "sm_buildinghats_unusuals", 0))
		{
			new iParticle = CreateEntityByName("info_particle_system"); 
			if(IsValidEdict(iParticle))
			{
				new Float:flPos[3]; 
				new bool:kill = false;
				
				if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") > 1 && StrEqual(g_strParticle[entity], "", false))
					kill = true;
				
				new sParticle = GetRandomInt(0, sizeof(g_sParticleList)-1);
				
				if(!StrEqual(g_strParticle[entity], "", false))
					DispatchKeyValue(iParticle, "effect_name", g_strParticle[entity]); 
				else
				{
					if(g_flCvarUnusualChance == 1.0)	//100% Unusual chance fix?
						DispatchKeyValue(iParticle, "effect_name", g_sParticleList[sParticle][0]); 
					else if(GetRandomFloat(0.0, 1.0) <= g_flCvarUnusualChance)
						DispatchKeyValue(iParticle, "effect_name", g_sParticleList[sParticle][0]); 
					else
						kill = true;
				}

				if(!kill)
				{
					DispatchSpawn(iParticle); 
					
					SetVariantString("!activator"); 
					AcceptEntityInput(iParticle, "SetParent", entity); 
					ActivateEntity(iParticle); 

					if(objectT == TFObject_Dispenser)
					{
						SetVariantString("build_point_0");
					}
					else if(objectT == TFObject_Sentry)
					{
						if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") < 3)
							SetVariantString("build_point_0");
						else
							SetVariantString("rocket_r");
					}
					AcceptEntityInput(iParticle, "SetParentAttachment", entity);
					
					GetEntPropVector(iParticle, Prop_Send, "m_vecOrigin", flPos);
					
					if(objectT == TFObject_Dispenser)
					{
						flPos[2] += 13.0;	//Make sure the effect is on top of the dispenser
						
						if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3)
							flPos[2] += 8.0;	//Account for level 3 dispenser
					}
					
					if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3 && objectT != TFObject_Dispenser)
					{
						flPos[2] += 6.5;	//Level 3 sentry offsets
						flPos[0] -= 11.0;	//Gotta get that effect on top of the missile thing
					}
					
					SetEntPropVector(iParticle, Prop_Send, "m_vecOrigin", flPos);

					AcceptEntityInput(iParticle, "start"); 
					
					g_particleEnt[entity] = EntIndexToEntRef(iParticle);
					
					if(StrEqual(g_strParticle[entity], "", false))
						Format(g_strParticle[entity], sizeof(g_strParticle), "%s", g_sParticleList[sParticle][0]);
				}
				else
					AcceptEntityInput(iParticle, "Kill");
			}
		}
	}
}

bool:ParseConfigurations()
{
	decl String:strPath[PLATFORM_MAX_PATH];
	decl String:strFileName[PLATFORM_MAX_PATH];
	Format(strFileName, sizeof(strFileName), "configs/buildinghats.cfg");
	BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);

	LogMessage("[Building Hats] Executing configuration file %s", strPath);    
	
	if (FileExists(strPath, true))
	{
		new Handle:kvConfig = CreateKeyValues("TF2_Buildinghats");
		if (FileToKeyValues(kvConfig, strPath) == false) SetFailState("[Building Hats] Error while parsing the configuration file.");
		KvGotoFirstSubKey(kvConfig);
		
		do
		{
			decl String:strMpath[PLATFORM_MAX_PATH], String:strOffz[16], String:strScale[16], String:strAnima[128]; 

			KvGetString(kvConfig, "modelpath",	strMpath, sizeof(strMpath));
			KvGetString(kvConfig, "offset", 	strOffz,  sizeof(strOffz));
			KvGetString(kvConfig, "modelscale", strScale, sizeof(strScale));
			KvGetString(kvConfig, "animation",  strAnima, sizeof(strAnima));
			
			PrecacheModel(strMpath);
			
			PushArrayString(hHatInfo, strMpath);
			PushArrayString(hHatInfo, strOffz);
			PushArrayString(hHatInfo, strScale);
			PushArrayString(hHatInfo, strAnima);
		}
		while (KvGotoNextKey(kvConfig));

		CloseHandle(kvConfig);
	}
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if(client >= 1 && client <= MaxClients && IsClientInGame(client))
    {
        if(menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}