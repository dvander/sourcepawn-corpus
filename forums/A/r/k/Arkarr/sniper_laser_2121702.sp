#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#undef REQUIRE_PLUGIN
#include <updater>
#include <clientprefs>

#define UPDATE_URL    "http://tf2serverofarkarr.net63.net/plugins/tf2_sniperlaser/updatefile.upd"
#define TF_TEAM_RED 2
#define TF_TEAM_BLU 3

new g_modelLaser;
new g_modelHalo; 
new amount_r[MAXPLAYERS+1] = 0;
new amount_g[MAXPLAYERS+1] = 0;
new amount_b[MAXPLAYERS+1] = 0;
new amount_a[MAXPLAYERS+1] = 0;

new String:plugin_tag[60] = "{green}[SniperLaser]{default}";
new String:laser_mount[150] = "weapons/sniper_bolt_forward.wav";
new String:laser_unmount[150] = "weapons/sniper_bolt_back.wav";

new bool:HaveLaser[MAXPLAYERS+1];
new bool:scopping[MAXPLAYERS+1];
new bool:reloading[MAXPLAYERS+1];
new bool:changed_color[MAXPLAYERS+1] = false;
new bool:UsePresetColor;

new Handle:CVAR_PluginEnabled;
new Handle:CVAR_DefaultStatus;
new Handle:CVAR_LaserMountSound;
new Handle:CVAR_LaserUnmountSound;
new Handle:CVAR_ViewLaserFlag;
new Handle:ARRAY_LaserColor;
new Handle:COOKIE_LaserColor;

public Plugin:myinfo =
{
	name		=	"[TF2] Sniper Laser",
	author		=	"Arkarr",
	description	=	"Draw a simple laser from the sniper of player to where he is looking at",
	version		=	"1.7",
	url			=	"http://www.sourcemod.net"
};

public OnPluginStart()
{
	RegAdminCmd("sm_sniperlaser", CMD_ActivateLaser, ADMFLAG_CHEATS, "Put a laser on your sniper.");
	RegAdminCmd("sm_lasercolor", CMD_ChangeLaserColor, ADMFLAG_CHEATS, "Change the color of the laser.");
	RegAdminCmd("sm_reloadlaser", CMD_ReloadLaser, ADMFLAG_ROOT, "Reload the preset laser list.");
	
	CVAR_PluginEnabled = CreateConVar("sm_tf2sniperlaser_enable", "1", "Enable (1) or disable (0) [TF2] Sniper Laser.", _, true, 0.0, true, 1.0);
	CVAR_DefaultStatus = CreateConVar("sm_tf2sniperlaser_default_status", "0", "By default, player have sniper laser actived ? 0=no 1=yes", _, true, 0.0, true, 1.0);
	CVAR_LaserMountSound = CreateConVar("sm_tf2sniperlaser_mount_sound", "DEFAULT", "What should be the sound to play when a player mount a laser on his sniper ? Leave 'DEFAULT' to use the default plugin sound.", _, false, 0.0, false, 0.0);
	CVAR_LaserUnmountSound = CreateConVar("sm_tf2sniperlaser_unmount_sound", "DEFAULT", "What should be the sound to play when a player unmount a laser on his sniper ? Leave 'DEFAULT' to use the default plugin sound.", _, false, 0.0, false, 0.0);
	CVAR_ViewLaserFlag = CreateConVar("sm_tf2sniperlaser_view_laser_flag", "", "All user who have access to this flag will be able to see lasers.", _, false, 0.0, false, 0.0);
	
	COOKIE_LaserColor = RegClientCookie("sm_tf2sniperlaser_color", "Store if player have a laser or not.", CookieAccess_Private);
	
	AutoExecConfig(true, "tf2_sniperlaser");
	
	HookConVarChange(CVAR_LaserMountSound, CheckForCustomSound);
	HookConVarChange(CVAR_LaserUnmountSound, CheckForCustomSound);
	
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL)
	
	ARRAY_LaserColor = CreateArray(15, 0);
	
	UsePresetColor = ReadLaserColorFile();
	
	if(UsePresetColor == false)
		PrintToServer("[SniperLaser] WARNING: file 'sniperlaser_color.txt' not found or empty. Preset laser color disabled.");
	else
		PrintToServer("[SniperLaser] SUCCESS: loaded %i preset laser color.", GetArraySize(ARRAY_LaserColor));
		
	for(new i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
            continue;
        OnClientCookiesCached(i);
    }
}

public CheckForCustomSound(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CheckSounds();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public Updater_OnPluginUpdated() 
{
	ReloadPlugin();
	PrintToServer("[SniperLaser] The plugin as been updated ! All news : goo.gl/mgaEcg");
}

public OnClientCookiesCached(client)
{
    decl String:sValue[8];
    GetClientCookie(client, COOKIE_LaserColor, sValue, sizeof(sValue));
    
    if(StringToInt(sValue) != -1)
	{
		decl String:colors[4][5];
		ExplodeString(sValue, "-", colors, sizeof(colors), sizeof(colors[]));
		amount_r[client] = StringToInt(colors[0]);
		amount_g[client] = StringToInt(colors[1]);
		amount_b[client] = StringToInt(colors[2]);
		amount_a[client] = StringToInt(colors[3]);
		HaveLaser[client] = true;
	}
}

public OnMapStart()
{
	g_modelLaser = PrecacheModel("sprites/laser.vmt");
	g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt");
	
	CheckSounds();
	
	PrecacheSound(laser_mount);
	PrecacheSound(laser_unmount);
}

public OnClientConnected(client)
{
	if(GetConVarBool(CVAR_DefaultStatus))
		HaveLaser[client] = true;
	else
		HaveLaser[client] = false;
}

public OnClientDisconnected(client)
{
	decl String:colors[100];
	Format(colors, sizeof(colors), "-1");
	if(HaveLaser[client])
		Format(colors, sizeof(colors), "%i-%i-%i-%i", amount_r[client], amount_g[client], amount_b[client], amount_a[client]);
	SetClientCookie(client, COOKIE_LaserColor, colors);
}

public OnGameFrame()
{
	if(GetConVarBool(CVAR_PluginEnabled) == true)
	{
		for (new i = MaxClients; i > 0; --i)
		{
			if(IsValidClient(i) && HaveLaser[i] && TF2_GetPlayerClass(i) == TFClass_Sniper && scopping[i])
			{
				//friagram code, thanks ! :
				decl Float:origin[3],Float:angles[3],Float:fwd[3],Float:rt[3],Float:up[3];
				
				GetClientEyePosition(i, origin);
				GetClientEyeAngles(i, angles);
				
				angles[0] += angles[0];
				angles[1] += angles[1];
				angles[2] += angles[2];
				
				GetAngleVectors(angles, fwd, rt, up);
				
				CheckLaserColorChange(i);
				
				new player_color[4];
				player_color[0] = amount_r[i];
				player_color[1] = amount_g[i];
				player_color[2] = amount_b[i];
				player_color[3] = amount_a[i];
				
				TE_SetupBeamPoints(origin, GetEndPosition(i), g_modelLaser, g_modelHalo, 0, 1, 0.1, 2.0, 2.0, 1, 1.0, player_color, 1)

				decl String:view_flag_STR[100];
				GetConVarString(CVAR_ViewLaserFlag,view_flag_STR, sizeof(view_flag_STR));
				
				new view_flag = ReadFlagString(view_flag_STR);
				
				new iClients[MaxClients], nClients;
				for(new j = 1; j <= MaxClients; j++)
				{
					if(IsValidClient(j) && CheckCommandAccess(j, "view_laser", view_flag, true))
						iClients[nClients++] = j;
				}
				TE_Send( iClients, nClients );
				
			}
		}
	}
}

public Action:CMD_ActivateLaser(client, args)
{
	if(GetConVarBool(CVAR_PluginEnabled) == false)
	{
		CPrintToChat(client, "%s Plugin disabled.", plugin_tag);
		return Plugin_Handled;
	}
	
	if(!IsValidClient(client))
	{
		PrintToServer("[SniperLaser] This command can be used only ingame ! Or client invalid ?");
		return Plugin_Handled;
	}
	
	if(HaveLaser[client])
		HaveLaser[client] = false;
	else
		HaveLaser[client] = true;
		
	decl String:chat_se[100];
	Format(chat_se, sizeof(chat_se), "%s Sniper laser is now %s {default}!", plugin_tag, (HaveLaser[client] ? "{green}on" : "{fullred}off"));
	CPrintToChat(client, chat_se);
	
	return Plugin_Handled;
}

public Action:CMD_ChangeLaserColor(client, args)
{
	if(GetConVarBool(CVAR_PluginEnabled) == false)
	{
		CPrintToChat(client, "%s Plugin disabled.", plugin_tag);
		return Plugin_Handled;
	}
	
	if(!IsValidClient(client))
	{
		PrintToServer("[SniperLaser] This command can be used only ingame ! Or client invalid ?");
		return Plugin_Handled;
	}
	
	CheckLaserColorChange(client);
	
	DisplayColorEditMenu(client);
	
	return Plugin_Handled;
}

public Action:CMD_ReloadLaser(client, args)
{
	if(GetConVarBool(CVAR_PluginEnabled) == false)
	{
		CPrintToChat(client, "%s Plugin disabled.", plugin_tag);
		return Plugin_Handled;
	}
	
	UsePresetColor = ReadLaserColorFile();
	
	if(UsePresetColor == false)
	{
		if(!IsValidClient(client))
			PrintToServer("[SniperLaser] WARNING: file 'sniperlaser_color.txt' not found or empty. Preset laser color disabled.");
		else
			CPrintToChat(client, "%s {yellow}WARNING{default}: file 'sniperlaser_color.txt' not found or empty. Preset laser color disabled.", plugin_tag, GetArraySize(ARRAY_LaserColor));
	}
	else
	{
		if(!IsValidClient(client))
			PrintToServer("[SniperLaser] SUCCESS : Loaded %i preset laser color.", GetArraySize(ARRAY_LaserColor));
		else
			CPrintToChat(client, "%s SUCCESS : Loaded %i preset laser color.", plugin_tag, GetArraySize(ARRAY_LaserColor));
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;
	
	decl String:wep_class[100];
	GetClientWeapon(client, wep_class, sizeof(wep_class));
	
	if(TF2_GetPlayerClass(client) == TFClass_Sniper && StrContains(wep_class, "sniper") != -1)
	{
		if(buttons & IN_RELOAD)
		{
			if(reloading[client] == false && CheckCommandAccess(client, "sm_sniperlaser", ADMFLAG_CHEATS, false) )
			{
				if(HaveLaser[client])
				{
					EmitSoundToClient(client, laser_unmount);
					HaveLaser[client] = false;
				}
				else
				{
					EmitSoundToClient(client, laser_mount);
					HaveLaser[client] = true;
				}
			}
			reloading[client] = true;
		}
		else
		{
			reloading[client] = false;
		}
	}
	
	return Plugin_Continue;
}


public Menu_UsePresetColor(Handle:menu, MenuAction:action, client, param2)  
{  
	new String:info[32];  
	GetMenuItem(menu, param2, info, sizeof(info));  
	
	if(action == MenuAction_Select)  
	{
		amount_r[client] = GetColorFromArray(ARRAY_LaserColor, param2, 0);
		amount_g[client] = GetColorFromArray(ARRAY_LaserColor, param2, 1);
		amount_b[client] = GetColorFromArray(ARRAY_LaserColor, param2, 2);
		amount_a[client] = GetColorFromArray(ARRAY_LaserColor, param2, 3);
		changed_color[client] = true;
		
		DisplayPresetColor(client);
	}
	else
	{  
		DisplayColorEditMenu(client);
	} 
}

public Menu_ManuallyAdjust(Handle:menu, MenuAction:action, client, param2)  
{  
	new String:info[32];  
	GetMenuItem(menu, param2, info, sizeof(info));  
	
	if(action == MenuAction_Select)  
	{
		if(StrEqual(info, "EDIT_RED", true)) 
		{  
			amount_r[client]++;
			if(amount_r[client] > 255)
			{
				amount_r[client] = 0;
			}
		}  
		else if(StrEqual(info, "EDIT_BLUE", true)) 
		{  
			amount_g[client]++;
			if(amount_g[client] > 255)
			{
				amount_g[client] = 0;
			}
		}  
		else if(StrEqual(info, "EDIT_GREEN", true)) 
		{  
			amount_b[client]++;
			if(amount_b[client] > 255)
			{
				amount_b[client] = 0;
			}
		}  
		else if(StrEqual(info, "EDIT_ALPHA", true)) 
		{  
			amount_a[client]++;
			if(amount_a[client] > 255)
			{
				amount_a[client] = 0;
			}
		}
		changed_color[client] = true;
		DisplayManuallyColorEditMenu(client);
	}
	else  
	{  
		DisplayColorEditMenu(client); 
	} 
}

public Menu_LaserEditMethode(Handle:menu, MenuAction:action, client, param2)  
{
	new String:info[32];  
	GetMenuItem(menu, param2, info, sizeof(info));  
	
	if(action == MenuAction_Select)  
	{
		if(StrEqual(info, "USE_PRESET", true)) 
		{
			DisplayPresetColor(client);
		}
		else if(StrEqual(info, "MANUALLY_ADJUST", true)) 
		{
			DisplayManuallyColorEditMenu(client);
		}
		else if(StrEqual(info, "RESET_DEFAULT", true)) 
		{
			changed_color[client] = false;
			CPrintToChat(client, "%s Laser color success fully reset.", plugin_tag);
		}
	}
	else if(action == MenuAction_End)  
	{
		CloseHandle(menu);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(condition == TFCond_Zoomed)
	{
		scopping[client] = true;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(condition == TFCond_Zoomed)
	{
		scopping[client] = false;
	}
}

stock CheckSounds()
{
	decl String:mount_sound[150];
	decl String:unmount_sound[150];
	
	GetConVarString(CVAR_LaserMountSound, mount_sound, sizeof(mount_sound));
	GetConVarString(CVAR_LaserUnmountSound, unmount_sound, sizeof(unmount_sound));
	
	if(StrEqual("DEFAULT", mount_sound, true))
	{
		Format(laser_mount, sizeof(laser_mount), "weapons/sniper_bolt_forward.wav");
	}
	else
	{
		AddFileToDownloadsTable(mount_sound);
		Format(laser_mount, sizeof(laser_mount), mount_sound);
	}
	
	if(StrEqual("DEFAULT", unmount_sound, true))
	{
		Format(laser_unmount, sizeof(laser_unmount), "weapons/sniper_bolt_back.wav");
	}
	else
	{
		AddFileToDownloadsTable(unmount_sound);
		Format(laser_unmount, sizeof(laser_unmount), unmount_sound);
	}
}

stock DisplayColorEditMenu(client)
{
	new Handle:menu = CreateMenu(Menu_LaserEditMethode); 
	SetMenuTitle(menu, "Edit laser color :"); 
	if(UsePresetColor) AddMenuItem(menu, "USE_PRESET", "Use a preset laser");
	AddMenuItem(menu, "MANUALLY_ADJUST", "Adjust color manually"); 
	AddMenuItem(menu, "RESET_DEFAULT", "Reset to default");  
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, 30);
}

stock DisplayManuallyColorEditMenu(client)
{
	decl String:item_1[50];
	decl String:item_2[50];
	decl String:item_3[50];
	decl String:item_4[50];
	
	Format(item_1, sizeof(item_1), "Amount of red (%i)", amount_r[client]);
	Format(item_2, sizeof(item_2), "Amount of green (%i)", amount_g[client]);
	Format(item_3, sizeof(item_3), "Amount of blue (%i)", amount_b[client]);
	Format(item_4, sizeof(item_4), "Amount of alpha (%i)", amount_a[client]);
	
	new Handle:menu = CreateMenu(Menu_ManuallyAdjust); 
	SetMenuTitle(menu, "Edit laser color :"); 
	AddMenuItem(menu, "EDIT_RED", item_1); 
	AddMenuItem(menu, "EDIT_BLUE", item_2); 
	AddMenuItem(menu, "EDIT_GREEN", item_3); 
	AddMenuItem(menu, "EDIT_ALPHA", item_4); 
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

stock DisplayPresetColor(client)
{
	
	new Handle:menu = CreateMenu(Menu_UsePresetColor); 
	SetMenuTitle(menu, "Choose a laser color :"); 
	
	for(new i = 0; i < GetArraySize(ARRAY_LaserColor); i++)
	{
		new R = GetColorFromArray(ARRAY_LaserColor, i, 0);
		new G = GetColorFromArray(ARRAY_LaserColor, i, 1);
		new B = GetColorFromArray(ARRAY_LaserColor, i, 2);
		new A = GetColorFromArray(ARRAY_LaserColor, i, 3);
		
		decl String:item[50];
		decl String:item_index[10];
		IntToString(i, item_index, sizeof(item_index));
		Format(item, sizeof(item), "Laser %i: %i %i %i %i", (i+1), R, G, B, A);
		AddMenuItem(menu, item_index, item);
	}
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

stock GetColorFromArray(Handle:ARRAY_Color, index, color_case)
{
	decl String:preset_color[16];
	decl String:rgba[4][4];
	
	GetArrayString(ARRAY_Color, index, preset_color, sizeof(preset_color));
	ExplodeString(preset_color, "-", rgba, sizeof(rgba), sizeof(rgba[]));
	
	return StringToInt(rgba[color_case]);
}

stock CheckLaserColorChange(client)
{
	if(GetClientTeam(client) == TF_TEAM_RED)
	{
		if(changed_color[client] == false)
		{
			amount_r[client] = 255;
			amount_b[client] = 0;
			amount_g[client] = 0;
			amount_a[client] = 200;
		}
	}
	else if(GetClientTeam(client) == TF_TEAM_BLU)
	{
		if(changed_color[client] == false)
		{
			amount_r[client] = 0;
			amount_b[client] = 255;
			amount_g[client] = 0;
			amount_a[client] = 200;
		}
	}
}

stock bool:ReadLaserColorFile()
{
	decl String:path[PLATFORM_MAX_PATH]
	decl String:line_color[16];
	
	ClearArray(ARRAY_LaserColor);
	
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/tf2_sniperlaser_color.txt");
	new Handle:fileHandle = OpenFile(path,"r");
	
	if(FileExists(path) == false)
	{
		return false;
	}
	
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line_color,sizeof(line_color)))
	{
		if(strlen(line_color) == 15)
			PushArrayString(ARRAY_LaserColor, line_color);
	}
	
	CloseHandle(fileHandle);
	
	if(GetArraySize(ARRAY_LaserColor) != 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock Float:GetEndPosition(client) 
{ 
	decl Float:start[3], Float:angle[3], Float:end[3]; 
	GetClientEyePosition(client, start); 
	GetClientEyeAngles(client, angle); 
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client); 
	if (TR_DidHit(INVALID_HANDLE)) 
	{ 
		TR_GetEndPosition(end, INVALID_HANDLE); 
	} 
	return end;
} 

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)  
{ 
	return entity > MaxClients; 
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}