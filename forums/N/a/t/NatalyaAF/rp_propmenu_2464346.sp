//	Natalya's RP !propmenu Plugin
//	Script by Natalya[AF]
//
//	This script will allow players to spawn props by typing !propmenu in game.
//
//	www.n00bunlimited.net
//	www.s-low.info
//	www.4chan.org
#pragma semicolon 1
#include <roleplay>
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <vphysics>

#define CREDS_NULL		 "0"
#define PLUGIN_VERSION "1.04"
#define	MAXCATEGORIES 20
#define	MAXPROPS 2048

new String:authid[MAXPLAYERS+1][35];
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_PropMenu = INVALID_HANDLE;

new prop_category = 0;
new prop_quantity = 0;
new String:category_name[MAXPROPS+1][35];
new String:prop_name[MAXPROPS+1][35];
new Float:prop_rotation[MAXPROPS+1];
new Float:prop_offset[MAXPROPS+1];
new String:prop_model[MAXPROPS+1][128];
new prop_cat[MAXPROPS+1];
new prop_override[MAXPROPS+1];
new prop_flags[MAXPROPS+1];
new prop_dmgscale[MAXPROPS+1];
new prop_skin[MAXPROPS+1];
new prop_owner[MAXPROPS+1];
new props_spawned[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "RP Prop Menu",
	author = "Natalya[AF]",
	description = "Natalya's RP !propmenu Plugin",
	version = PLUGIN_VERSION,
	url = "http://www.n00bunlimited.net"
}

public OnPluginStart()
{
	// Load Plugin Requirements
	LoadTranslations("plugin.propmenu");
	
	RegConsoleCmd("sm_propmenu", Command_Propmenu, "Open the !propmenu Menu");
	RegConsoleCmd("sm_prop_freeze", Command_Freeze, "Freeze a Prop");
	RegConsoleCmd("sm_prop_unfreeze", Command_Unfreeze, "Unfreeze a Prop");
	RegAdminCmd("sm_prop_freeze2", Command_Freeze2, ADMFLAG_CUSTOM3, "Freeze a Prop");
	RegAdminCmd("sm_prop_unfreeze2", Command_Unfreeze2, ADMFLAG_CUSTOM3, "Unfreeze a Prop");
	RegConsoleCmd("sm_prop_delete", Command_Delete, "Delete one of your props.");
	RegAdminCmd("sm_prop_delete2", Command_Delete2, ADMFLAG_CUSTOM3, "Delete one of your props.");
	CreateConVar("rp_propmenu_version", PLUGIN_VERSION, "Version of Natalya's !propmenu Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Enable = CreateConVar("sm_propmenu_enabled", "1", "Enables or Disables !propmenu", FCVAR_PLUGIN);

	// Prop File
	ReadPropFile();
	
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			props_spawned[client] = 0;
			props_spawned[client] = 0;
		}
	}
}
public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		g_PropMenu = BuildPropMenu();
	}
}
public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		props_spawned[client] = 0;
		GetClientAuthString(client, authid[client], sizeof(authid[]));
	}
}
Handle:BuildPropMenu()
{
	if (prop_category == 0)
	{
		PrintToServer("[RP Props] No Prop Categories were detected.");
		return g_PropMenu;
	}
	if (prop_quantity == 0)
	{
		PrintToServer("[RP Props] No Props were detected.");
		return g_PropMenu;
	}
	new Handle:props = CreateMenu(Menu_Props);
	SetMenuTitle(props, "Prop Menu:");	

	decl String:cat_str[4];
	for (new i = 0; i < prop_category; i++)
	{
		Format(cat_str, sizeof(cat_str), "%i", i);
		AddMenuItem(props,cat_str,category_name[i]);
	}

	AddMenuItem(props,"delete","Delete a Prop");
	
	return props;
}
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}
public Menu_Props(Handle:props, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(props, param2, info, sizeof(info));
		if (StrEqual(info,"delete"))
		{
			Delete(param1);
			DisplayMenu(g_PropMenu, param1, 0);
			return;
		}
		new cat_num = StringToInt(info);
		if (cat_num < prop_category)
		{
			new Handle:tempmenu = CreateMenu(Menu_Spawn);

			decl String:buffer[4];
			decl String:prop_str[32];
			for (new i = 0; i < prop_quantity; i++)
			{
				if (prop_cat[i] == cat_num)
				{
					Format(buffer, sizeof(buffer), "%i", i);
					Format(prop_str, sizeof(prop_str), "%s", prop_name[i]);
					AddMenuItem(tempmenu, buffer, prop_str);
				}
			}

			SetMenuTitle(tempmenu, category_name[cat_num]);		
			DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER); 
			return;
		} 
	}
	return; 
}
public Menu_Spawn(Handle:tempmenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new AdminId:admin = GetUserAdmin(param1);
		if (!IsPlayerAlive(param1))
		{
			return;
		}
		if (IsClientHandcuffed(param1))
		{
			return;
		}
		if (admin == INVALID_ADMIN_ID)
		{		
			if (props_spawned[param1] > 9)
			{
				PrintToChat(param1, "\x03[RP Props] %T", "Spawned_10", param1);
				return;
			}
		}
		if (admin != INVALID_ADMIN_ID)
		{
			if (props_spawned[param1] > 14)
			{
				PrintToChat(param1, "\x03[RP Props] %T", "Spawned_15", param1);
				return;
			}		
		}
		decl Float:_origin[3], Float:_angles[3];
		GetClientEyePosition( param1, _origin );
		GetClientEyeAngles( param1, _angles );

		new String:info[32];
		GetMenuItem(tempmenu, param2, info, sizeof(info));
		new i = StringToInt(info);
		if (i < prop_quantity)
		{
    		new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
    		if( !TR_DidHit( trace ) )
    		{
				PrintToChat(param1, "\x03[RP Props] %T", "Error_L", param1);
				return;
    		}
    		else
    		{
				decl Float:VecAngles[3], Float:position[3], VecOrigin[3], Float:VecDirection[3];
				TR_GetEndPosition(position, trace);

				if(StrEqual(prop_model[i], "FUCK_YOURSELF", false))
				{
					PrintToChat(param1, "\x03[RP Props] %T", "Error_P", param1, prop_name[i]);
					PrintToChat(param1, "\x03[RP Props] %T", "Error_No_Spawn", param1);
					return;
				}
				else
				{
					if (!IsModelPrecached(prop_model[i]))
					{
						PrecacheModel(prop_model[i]);
					}
				}
				decl prop;
				if (prop_override[i] == 0)
				{
					prop = CreateEntityByName("prop_physics_multiplayer");
				}
				else if (prop_override[i] == 1)
				{
					prop = CreateEntityByName("prop_physics_override");
				}
				else if (prop_override[i] == 2)
				{
					prop = SpawnChair(prop_model[i], prop_skin[i], param1);
					if (prop > 0)
					{
						props_spawned[param1] += 1;
						prop_owner[prop] = param1;
						Phys_EnableMotion(prop, false);
				
						if (admin != INVALID_ADMIN_ID)
						{
							DisplayMenu(g_PropMenu, param1, 0);
							return;
						}
						else DisplayMenu(g_PropMenu, param1, 0);
						return;
					}
					else PrintToChat(param1, "\x03[RP Props] %T", "Error_No_Spawn", param1);
					return;
				}
					
					
					
				new String:skin[4];
				Format(skin, sizeof(skin), "%i", prop_skin[i]);
										


				GetClientEyeAngles(param1, VecAngles);
				GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
				VecOrigin[0] += VecDirection[0] * 32;
				VecOrigin[1] += VecDirection[1] * 32;
				VecOrigin[2] += VecDirection[2] * 1;
				VecAngles[0] = 0.0;
				VecAngles[1] += prop_rotation[i];
				VecAngles[2] = 0.0;
				position[2] += prop_offset[i];

				new String:Prop_Name[64];
				Format(Prop_Name, sizeof(Prop_Name), "prop_%i", prop);			
					
				DispatchKeyValue(prop, "targetname", Prop_Name);
				DispatchKeyValue(prop, "skin", skin);
				DispatchKeyValue(prop, "model", prop_model[i]);
				
				// Set Spawn Flags
				if (prop_flags[i] > -1)
				{
					new String:flag_str[16];
					Format(flag_str, sizeof(flag_str), "%i", prop_flags[i]);
					DispatchKeyValue(prop, "spawnflags", flag_str);
				}
				// Set Spawn Flags
				if (prop_dmgscale[i] > -1)
				{
					new String:dmg_str[16];
					Format(dmg_str, sizeof(dmg_str), "%i", prop_dmgscale[i]);
					DispatchKeyValue(prop, "physdamagescale", dmg_str);
				}
					
				DispatchSpawn(prop);
//				ActivateEntity(prop);
				TeleportEntity(prop, position, VecAngles, NULL_VECTOR);

				PrintToChat(param1, "\x03[RP Props] %s", prop_model[i]);
				props_spawned[param1] += 1;
				prop_owner[prop] = param1;
				HookSingleEntityOutput(prop, "OnBreak", EntityOutput:OnPropPhysBreak);
					
				if (admin != INVALID_ADMIN_ID)
				{
					DisplayMenu(g_PropMenu, param1, 0);
					return;
				}
				else DisplayMenu(g_PropMenu, param1, 0);
				return;
			}
		}
	}
	return;
}
public OnPropPhysBreak(const String:output[], caller, activator, Float:delay)
{
	new owner = prop_owner[caller];

	if (owner > 0)
	{
		if (IsClientConnected(owner))
		{
			props_spawned[owner] -= 1;
		}
		else props_spawned[owner] = 0;
	}

	prop_owner[caller] = 0;
	return;
}
public OnMapEnd()
{
	if (g_PropMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PropMenu);
		g_PropMenu = INVALID_HANDLE;
	}
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			props_spawned[client] = 0;
		}
	}
}
public OnClientDisconnect(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new maxents = GetMaxEntities();
		if (props_spawned[client] != 0)
		{
			for (new i = 1; i < maxents; i++)
			{
				if (IsValidEntity(i))
				{
					if(prop_owner[i] == client)
					{
						decl String:ClassName[255];
						GetEdictClassname(i, ClassName, 255);
						if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || StrEqual(ClassName, "prop_physics_multiplayer"))
						{
							prop_owner[i] = -1;
							AcceptEntityInput(i,"Kill");
							props_spawned[client] -= 1;
						}
						else if (StrEqual(ClassName, "prop_vehicle_driveable"))
						{
							new driver = GetEntPropEnt(i, Prop_Send, "m_hPlayer");
							if (driver == -1)
							{
								prop_owner[i] = -1;
								AcceptEntityInput(i,"Kill");
								props_spawned[client] -= 1;
							}
						}
					}
				}
				else prop_owner[i] = -1;
			}
		}
		props_spawned[client] = 0;
	}
}
public ReadPropFile()
{
	new Handle:propkv;
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/rp_props.txt");
	propkv = CreateKeyValues("Props");
	FileToKeyValues(propkv, sPath);
	
	if (!KvGotoFirstSubKey(propkv))
	{
		PrintToServer("[RP DEBUG] There are no props listed in rp_props.txt, or there is an error with the file.");
		return;
	}
	
	// Index the categories first.
	do
	{
		KvGetSectionName(propkv, category_name[prop_category], 35);
		prop_category += 1;

	} while ((KvGotoNextKey(propkv)) && (prop_category < 21));
	KvRewind(propkv);
	
	// Now let's index all of the props.
	new lol = 0;
	new prop_index = 0;
	
	
	do
	{
		KvJumpToKey(propkv, category_name[lol]);
		KvGotoFirstSubKey(propkv);
		do
		{
			KvGetSectionName(propkv, prop_name[prop_index], 35);
			KvGetString(propkv, "model", prop_model[prop_index], 128, "FUCK_YOURSELF");
			PrecacheModel(prop_model[prop_index]);
			prop_rotation[prop_index] = KvGetFloat(propkv, "rotation", 0.0);
			prop_offset[prop_index] = KvGetFloat(propkv, "offset", 0.0);
			prop_flags[prop_index] = KvGetNum(propkv, "flags", -1);
			prop_dmgscale[prop_index] = KvGetNum(propkv, "physdamagescale", -1);
			prop_override[prop_index] = KvGetNum(propkv, "override", 0);
			prop_skin[prop_index] = KvGetNum(propkv, "skin", 0);
			prop_cat[prop_index] = lol;
			PrintToServer("[RP Props] %s %s", prop_name[prop_index], prop_model[prop_index]);
			prop_index += 1;		

		} while ((KvGotoNextKey(propkv)) && (prop_index <= 256));
		lol += 1;
		KvRewind(propkv);
		
	} while ((lol <= 20) && (lol <= prop_category));
	
	new i = 0;
	do
	{
		PrintToServer("%s", prop_model[i]);
		i += 1;
		
	} while (i <= prop_index);

	KvRewind(propkv);	

	
	
	PrintToServer("[RP Props] Props Loaded");
	PrintToServer("[RP Props] %i categories were detected. [Max 20]", prop_category);
	PrintToServer("[RP Props] %i props were detected. [Max 256]", prop_index);
	prop_quantity = prop_index;
	
	KvRewind(propkv);
	CloseHandle(propkv);
}
public Action:Command_Delete(client, args)
{
	Delete(client);
	return Plugin_Handled;
}
public Action:Command_Delete2(client, args)
{
	Delete2(client);
	return Plugin_Handled;
}
public Delete(client)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{	
		new owner = prop_owner[prop];
		if (owner == client)
		{
			decl String:ClassName[255];
			GetEdictClassname(prop, ClassName, 255);
			if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || StrEqual(ClassName, "prop_physics_multiplayer"))
			{
				prop_owner[prop] = -1;
				AcceptEntityInput(prop,"Kill");
				props_spawned[client] -= 1;
				PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
			}
			else if (StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				new driver = GetEntPropEnt(prop, Prop_Send, "m_hPlayer");
				if (driver == -1)
				{
					prop_owner[prop] = -1;
					AcceptEntityInput(prop,"Kill");
					props_spawned[client] -= 1;
					PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
				}
			}
		}
	}
}
public Delete2(client)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{
		new AdminId:admin = GetUserAdmin(client);
		
		new owner = prop_owner[prop];
		if (owner == client)
		{
			decl String:ClassName[255];
			GetEdictClassname(prop, ClassName, 255);
			if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || StrEqual(ClassName, "prop_physics_multiplayer"))
			{
				prop_owner[prop] = -1;
				AcceptEntityInput(prop,"Kill");
				props_spawned[client] -= 1;
				PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
			}
			else if (StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				new driver = GetEntPropEnt(prop, Prop_Send, "m_hPlayer");
				if (driver == -1)
				{
					prop_owner[prop] = -1;
					AcceptEntityInput(prop,"Kill");
					props_spawned[client] -= 1;
					PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
				}
			}
		}
		else if (admin != INVALID_ADMIN_ID)
		{
			decl String:ClassName[255];
			GetEdictClassname(prop, ClassName, 255);
			if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || StrEqual(ClassName, "prop_physics_multiplayer"))
			{
				prop_owner[prop] = -1;
				AcceptEntityInput(prop,"Kill");
				if (owner > -1)
				{
					props_spawned[owner] -= 1;
				}
				PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
			}
			else if (prop_owner[prop] > 0)
			{
				if(StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new driver = GetEntPropEnt(prop, Prop_Send, "m_hPlayer");
					if (driver == -1)
					{
						prop_owner[prop] = -1;
						AcceptEntityInput(prop,"Kill");
						props_spawned[owner] -= 1;
						PrintToChat(client, "\x03[RP Props] %T", "Deleted", client, prop);
						LogMessage("[RP Props] Admin %N Deleted Prop #%i which was owned by Player %N", client, prop, prop_owner[prop]);
					}
				}
			}
		}
	}
}
public Action:Command_Freeze(client, args)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{
		new owner = prop_owner[prop];
		if (owner == client)
		{
			decl String:ClassName[255];
			GetEdictClassname(prop, ClassName, 255);
			if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || ((IsEntityChair(prop)) == 2) || StrEqual(ClassName, "prop_physics_multiplayer"))
			{
				Phys_EnableMotion(prop, false);
				SetEntProp(prop, Prop_Data, "m_nSolidType", 1);
				PrintToChat(client, "\x03[RP Props] %T", "Frozen", client, prop);
			}
		}
	}			
	return Plugin_Handled;
}
public Action:Command_Freeze2(client, args)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{
		decl String:ClassName[255];
		GetEdictClassname(prop, ClassName, 255);
		if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || ((IsEntityChair(prop)) == 2) || StrEqual(ClassName, "prop_physics_multiplayer"))
		{
			Phys_EnableMotion(prop, false);
			SetEntProp(prop, Prop_Data, "m_nSolidType", 1);
			PrintToChat(client, "\x03[RP Props] %T", "Unfroze", client, prop);
		}
	}			
	return Plugin_Handled;
}
public Action:Command_Unfreeze2(client, args)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{
		decl String:ClassName[255];
		GetEdictClassname(prop, ClassName, 255);
		if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || ((IsEntityChair(prop)) == 2) || StrEqual(ClassName, "prop_physics_multiplayer"))
		{
			Phys_EnableMotion(prop, true);
			SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
			PrintToChat(client, "\x03[RP Props] %T", "Unfroze", client, prop);
		}
	}			
	return Plugin_Handled;
}
public Action:Command_Unfreeze(client, args)
{
	decl prop;
	prop = GetClientAimTarget(client, false);
	if (prop != -1)
	{	
		new owner = prop_owner[prop];
		if (owner == client)
		{
			decl String:ClassName[255];
			GetEdictClassname(prop, ClassName, 255);
			if(StrEqual(ClassName, "prop_physics") || StrEqual(ClassName, "prop_physics_override") || ((IsEntityChair(prop)) == 2) || StrEqual(ClassName, "prop_physics_multiplayer"))
			{
				Phys_EnableMotion(prop, true);
				SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
				PrintToChat(client, "\x03[RP Props] %T", "Unfroze", client, prop);
			}
		}
	}			
	return Plugin_Handled;
}
public Action:Command_Propmenu(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new AdminId:admin = GetUserAdmin(client);
			if (admin != INVALID_ADMIN_ID)
			{
				DisplayMenu(g_PropMenu, client, 20);
				if (props_spawned[client] == 1)
				{
					PrintToChat(client, "\x03[RP Props] %T", "Spawned_1_Allowed", client, 15);
				}
				else PrintToChat(client, "\x03[RP Props] %T", "Spawned_Allowed", client, props_spawned[client], 15);
			}
			else
            {
				DisplayMenu(g_PropMenu, client, 0);
				if (props_spawned[client] == 1)				
				{
					PrintToChat(client, "\x03[RP Props] %T", "Spawned_1_Allowed", client, 10);
				}
				else PrintToChat(client, "\x03[RP Props] %T", "Spawned_Allowed", client, props_spawned[client], 10);
			}
		}
	}
	else PrintToChat(client, "\x03[RP Props] %T", "Disabled", client);
	return Plugin_Handled;
}
stock GetTargetName(entity, String:buf[], len)
{
	// Thanks to Joe Maley for this.
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}