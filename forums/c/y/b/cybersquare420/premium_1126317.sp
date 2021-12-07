//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define PLUGIN_AUTHOR "noodleboy347"
#define PLUGIN_NAME "[TF2] Premium Members"
#define PLUGIN_URL "http://www.frozencubes.com"
#define PLUGIN_DESCRIPTION "Gives special abilities to donators/premium members"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

new Handle:cvar_enabled;
new Handle:cvar_welcome;
new Handle:cvar_features;
new Handle:cvar_features_interval;
new Handle:cvar_speed;
new Handle:cvar_health;
new Handle:cvar_ammo;
new Handle:cvar_cloak;
new Handle:cvar_cloak_regen;
new Handle:cvar_kill_bonus;
new Handle:cvar_color;
new Handle:cvar_fov;
new Handle:cvar_dark;
new Handle:cvar_glow;
new Handle:cvar_sandman;
new Handle:cvar_jarate;
new Handle:cvar_uber;
new Handle:cvar_respawn;
new Handle:cvar_swap;
new Handle:cvar_fov_default;
new Handle:cvar_all;

new bool:pDark[MAXPLAYERS+1];
new bool:pGlow[MAXPLAYERS+1];
new fovSaved[MAXPLAYERS+1];

new Handle:speedTimer[MAXPLAYERS+1];
new Handle:cloakTimer[MAXPLAYERS+1];
new Handle:cloakHpTimer[MAXPLAYERS+1];
new Handle:glowTimer[MAXPLAYERS+1];

new offsFOV;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	/* Check Game */
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "tf"))
	{
		LogMessage("Premium Members Mod loaded successfully.");
	}
	else
	{
		SetFailState("Team Fortress 2 Only.");
	}
	
	/* Premium Member Commands */
	RegConsoleCmd("premium", Command_Premium);
	RegConsoleCmd("premium_features", Command_Features);
	RegConsoleCmd("premium_fov", Command_Fov);
	RegConsoleCmd("premium_dark", Command_Dark);
	RegConsoleCmd("premium_glow", Command_Glow);
	RegConsoleCmd("premium_swapteam", Command_Swap);
	RegConsoleCmd("features", Command_Features);
	RegConsoleCmd("fov", Command_Fov);
	RegConsoleCmd("dark", Command_Dark);
	RegConsoleCmd("glow", Command_Glow);
	RegConsoleCmd("swapteam", Command_Swap);
	
	/* Admin Commands
	RegAdminCmd("premium_add", Premium_Create, ADMFLAG_ROOT);
	RegAdminCmd("premium_remove", Premium_Remove, ADMFLAG_ROOT);
	RegAdminCmd("premium_reload", Premium_Reload, ADMFLAG_ROOT);*/
	
	/* Console Variables */
	CreateConVar("premium_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	cvar_enabled = CreateConVar("premium_enable", "1", "Enables Premium Members");
	cvar_welcome = CreateConVar("premium_advertisement_welcome", "1", "Displays a welcome message to Premium Members");
	cvar_features = CreateConVar("premium_advertisement_features", "1", "Displays an advertisement for premium features to everyone");
	cvar_features_interval = CreateConVar("premium_advertisement_features_interval", "300", "How often in seconds to display the feature advertisement");
	//cvar_trial = CreateConVar("premium_trial_enable", "1", "Allow users to create trials");
	//cvar_trial_length = CreateConVar("premium_trial_length", "600", "Amount of time in seconds for trials to last");
	cvar_speed = CreateConVar("premium_speed", "1", "Faster movement speed (Scout speed)");
	cvar_health = CreateConVar("premium_health", "150", "Health to buff on spawn");
	cvar_ammo = CreateConVar("premium_ammo", "1", "Increased clip for Soldiers and Demomen");
	cvar_cloak = CreateConVar("premium_cloak", "1", "Infinite cloak for Spies");
	cvar_cloak_regen = CreateConVar("premium_cloak_regen", "1", "Health regeneration while cloaked");
	cvar_kill_bonus = CreateConVar("premium_kill_bonus", "50", "Health to boost on kill");
	cvar_color = CreateConVar("premium_color", "0", "Sets the color Premiums spawn as");
	cvar_fov = CreateConVar("premium_fov_enable", "1", "Ability to alter field of view with premium_fov");
	cvar_dark = CreateConVar("premium_dark_enable", "1", "Ability to turn black with premium_dark");
	cvar_glow = CreateConVar("premium_glow_enable", "1", "Ability to glow with premium_glow");
	cvar_sandman = CreateConVar("premium_sandman", "1", "Extra Sandman baseballs to spawn with");
	cvar_jarate = CreateConVar("premium_jarate", "1", "Extra Jarates to spawn with");
	cvar_uber = CreateConVar("premium_ubercharge_amount", "25", "Percentage of ubercharge to spawn with");
	cvar_respawn = CreateConVar("premium_instant_respawn", "1", "Instantly respawns players when killed");
	cvar_swap = CreateConVar("premium_swapteam_enable", "1", "Ability to switch teams with premium_swapteam");
	cvar_fov_default = CreateConVar("premium_fov_default", "120", "Default FOV upon joining the server");
	cvar_all = CreateConVar("premium_all", "0", "Give all players Premium on connect");
	
	/*Event Hooks*/
	HookEvent("player_death", Player_Death);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_changeclass", Player_Changeclass);
	
	/*Other*/
	AutoExecConfig();
	LoadTranslations("premium.phrases");
	LoadTranslations("common.phrases");
	offsFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	CreateTimer(GetConVarFloat(cvar_features_interval), Advertisement_Features);
}

///////////////////////////////////
//C O N N E C T  T O  S E R V E R//
///////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(cvar_enabled) && GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		CreateTimer(30.0, Advertisement_Welcome, client);
		LogMessage("Premium member %N connected to the server.", client);
		fovSaved[client] = GetConVarInt(cvar_fov_default);
		pGlow[client] = false;
		if(GetConVarInt(cvar_all))
		{
			SetUserFlagBits(client, ADMFLAG_CUSTOM1);
		}
	}
}

////////////////////////////////////////////
//W E L C O M E  A D V E R T I S E M E N T//
////////////////////////////////////////////
public Action:Advertisement_Welcome(Handle:hTimer, any:client)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_welcome) && GetUserFlagBits(client) & ADMFLAG_CUSTOM1 && IsClientInGame(client))
	{
		CPrintToChatEx(client, client, "%t", "welcomeMessage", client);
	}
}

////////////////////////////////////////////
//F E A T U R E  A D V E R T I S E M E N T//
////////////////////////////////////////////
public Action:Advertisement_Features(Handle:hTimer)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_features))
	{
		CPrintToChatAll("%t", "featuresAdvertisement");
	}
	CreateTimer(GetConVarFloat(cvar_features_interval), Advertisement_Features);
}

////////////////////////////////
//P R E M I U M  C O M M A N D//
////////////////////////////////
public Action:Command_Premium(client, args)
{
	if(GetConVarInt(cvar_enabled))
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			DisplayPremiumCommands(client);
		}
		else
		{
			DisplayPremiumFeatures(client);
		}
	}
	return Plugin_Handled;
}

//////////////////////////////////
//F E A T U R E S  C O M M A N D//
//////////////////////////////////
public Action:Command_Features(client, args)
{
	if(GetConVarInt(cvar_enabled))
	{
		DisplayPremiumFeatures(client);
	}
}

//////////////////////////
//P L A Y E R  S P A W N//
//////////////////////////
public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client))
	{
		if(GetConVarInt(cvar_enabled) && GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			PremiumBoost(client);
		}
	}
}

////////////////////////
//S P E E D  T I M E R//
////////////////////////
public Action:Timer_Speed(Handle:timer, any:client)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_speed) && IsClientInGame(client))
	{
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if(!(cond & 1) || !(cond & 17))
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);
		}
	}
	speedTimer[client] = CreateTimer(0.1, Timer_Speed, client);
}

//////////////////////////////
//I N F I N I T E  C L O A K//
//////////////////////////////
public Action:Timer_Cloak(Handle:timer, any:client)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_cloak) && GetEntProp(client, Prop_Send, "m_nPlayerCond") & 16 && IsClientInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
	}
	cloakTimer[client] = CreateTimer(0.1, Timer_Cloak, client);
}

/////////////////////////////////////
//C L O A K  R E G E N  H E A L T H//
/////////////////////////////////////
public Action:Timer_Cloak_Health(Handle:timer, any:client)
{
	if(GetConVarInt(cvar_enabled) && GetEntProp(client, Prop_Send, "m_nPlayerCond") & 16 && IsClientInGame(client))
	{
		new health = GetClientHealth(client);
		if(health < 125)
		{
			SetEntityHealth(client, health + GetConVarInt(cvar_cloak_regen));
		}
	}
	cloakHpTimer[client] = CreateTimer(0.5, Timer_Cloak_Health, client);
}

////////////////////////////
//P L A Y E R  K I L L E D//
////////////////////////////
public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new killed = GetClientOfUserId(GetEventInt(event, "userid"));
	new death_flags = GetEventInt(event, "death_flags");
	new health = GetClientHealth(client);
	if(IsClientInGame(client))
	{
		if(GetConVarInt(cvar_enabled))
		{
			if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 && health <= 400)
			{
				SetEntityHealth(client, health + GetConVarInt(cvar_kill_bonus));
			}
			if(GetConVarInt(cvar_enabled) && GetUserFlagBits(killed) & ADMFLAG_CUSTOM1)
			{
				CloseHandle(Handle:speedTimer[client]);
				CloseHandle(Handle:cloakTimer[client]);
				CloseHandle(Handle:cloakHpTimer[client]);
				if(GetConVarInt(cvar_respawn) && !(death_flags & 32))
				{
					CreateTimer(0.1, Timer_Respawn, killed);
				}
			}
		}
	}
}

public Action:Timer_Respawn(Handle:timer, any:killed)
{
	TF2_RespawnPlayer(killed);
}

//////////////////////////
//C H A N G E  C L A S S//
//////////////////////////
public Player_Changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && client != 0)
	{
		if(GetConVarInt(cvar_enabled) && GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			CloseHandle(Handle:speedTimer[client]);
			CloseHandle(Handle:cloakTimer[client]);
			CloseHandle(Handle:cloakHpTimer[client]);
		}
	}
}

///////////////////////////
//F I E L D  O F  V I E W//
///////////////////////////
public Action:Command_Fov(client, args)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_fov) && GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		decl String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new fov = StringToInt(arg1);
		if(fov >= 20 && fov <= 170)
		{
			SetEntData(client, offsFOV, fov, 1);
			fovSaved[client] = fov;
			CPrintToChat(client, "%t", "setFOV", fov);
		}
		else
		{
			ReplyToCommand(client, "Usage: premium_fov <20-170>");
		}
	}
	else
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			CPrintToChat(client, "%t", "errorDisabled");
		}
		else
		{
			CPrintToChat(client, "%t", "errorAccess");
		}
	}
	return Plugin_Handled;
}

//////////////////////////
//D A R K  C O M M A N D//
//////////////////////////
public Action:Command_Dark(client, args)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_dark))
	{
		if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
		{
			if(pDark[client] == false)
			{
				SetEntityRenderColor(client, 0, 0, 0, 255);
				pDark[client] = true;
				CPrintToChatAllEx(client, "%t", "toggleDark", client);
			}
			else
			{
				SetPremiumColors(client);
				pDark[client] = false;
				CPrintToChatAllEx(client, "%t", "toggleDark", client);
			}
		}
		else
		{
			CPrintToChat(client, "%t", "errorAccess");
		}
	}
	else
	{
		CPrintToChat(client, "%t", "errorDisabled");
	}
}

//////////////////////////
//G L O W  C O M M A N D//
//////////////////////////
public Action:Command_Glow(client, args)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_glow))
	{
		if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
		{
			if(pGlow[client] == false)
			{
				CreateParticle("player_recent_teleport_blue", 300.0, client, ATTACH_NORMAL);
				CreateParticle("player_recent_teleport_red", 300.0, client, ATTACH_NORMAL);
				CreateParticle("critical_grenade_blue", 300.0, client, ATTACH_NORMAL);
				CreateParticle("critical_grenade_red", 300.0, client, ATTACH_NORMAL);
				CPrintToChatAllEx(client, "%t", "toggleGlow", client);
				pGlow[client] = true;
				glowTimer[client] = CreateTimer(300.0, Timer_Glow, client);
			}
			else
			{
				CPrintToChat(client, "%t", "errorGlow");
			}
		}
		else
		{
			CPrintToChat(client, "%t", "errorAccess");
		}
	}
	else
	{
		CPrintToChat(client, "%t", "errorDisabled");
	}
}

//////////////////////
//G L O W  T I M E R//
//////////////////////
public Action:Timer_Glow(Handle:timer, any:client)
{
	pGlow[client] = false;
}

////////////////////
//S W A P  T E A M//
////////////////////
public Action:Command_Swap(client, args)
{
	if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_swap))
	{
		if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
		{
			new team = GetClientTeam(client);
			if(team == 2)
			{
				ChangeClientTeam(client, 3);
				CPrintToChat(client, "%t", "teamswitchBlu");
			}
			if(team == 3)
			{
				ChangeClientTeam(client, 2);
				CPrintToChat(client, "%t", "teamswitchRed");
			}
		}
		else
		{
			CPrintToChat(client, "%t", "errorAccess");
		}
	}
	else
	{
		CPrintToChat(client, "%t", "errorDisabled");
	}
	return Plugin_Handled;
}

/////////////////////
//P A R T I C L E S//
/////////////////////
stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle)) {
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		
			if (attach == ATTACH_HEAD) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		return CreateTimer(time, DeleteParticle, particle);
	} else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}
public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
		}
	}
}

////////////////////////////////
//E X T R A  B A S E B A L L S//
////////////////////////////////
stock SetGrenadeAmmo(client, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 44)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}

//////////////////////////
//E X T R A  J A R A T E//
//////////////////////////
stock SetJarAmmo(client, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}

//////////////////////////
//P R E M I U M  M E N U//
//////////////////////////
stock DisplayPremiumFeatures(client)
{
	new Handle:featurepanel = CreatePanel();
	DrawPanelItem(featurepanel, "Premium Member Features");
	if(GetConVarInt(cvar_health))
	{
		DrawPanelText(featurepanel, "- Buffed health on spawn");
	}
	if(GetConVarInt(cvar_speed))
	{
		DrawPanelText(featurepanel, "- Faster movement speed");
	}
	if(GetConVarInt(cvar_ammo))
	{
		DrawPanelText(featurepanel, "- 2 extra rockets and grenades");
	}
	if(GetConVarInt(cvar_jarate))
	{
		DrawPanelText(featurepanel, "- 10 Jarates for the Sniper");
	}
	if(GetConVarInt(cvar_sandman))
	{
		DrawPanelText(featurepanel, "- 25 Sandman baseballs for the Scout");
	}
	if(GetConVarInt(cvar_cloak))
	{
		DrawPanelText(featurepanel, "- Infinite cloak time");
	}
	if(GetConVarInt(cvar_cloak_regen))
	{
		DrawPanelText(featurepanel, "- Regenerating health when cloaked");
	}
	if(GetConVarInt(cvar_kill_bonus) >= 1)
	{
		DrawPanelText(featurepanel, "- Health buff on kill");
	}
	if(GetConVarInt(cvar_fov))
	{
		DrawPanelText(featurepanel, "- Ability to set your FOV");
	}
	if(GetConVarInt(cvar_color) >= 1)
	{
		DrawPanelText(featurepanel, "- Special player color");
	}
	if(GetConVarInt(cvar_dark))
	{
		DrawPanelText(featurepanel, "- Access to !dark");
	}
	if(GetConVarInt(cvar_glow))
	{
		DrawPanelText(featurepanel, "- Access to !glow");
	}
	if(GetConVarInt(cvar_swap))
	{
		DrawPanelText(featurepanel, "- Ability to swap your team whenever you want");
	}
	if(GetConVarInt(cvar_health))
	{
		DrawPanelText(featurepanel, "- Instant respawn");
	}
	DrawPanelText(featurepanel, "- Much more!");
	DrawPanelText(featurepanel, " ");
	DrawPanelItem(featurepanel, "Exit");
	SendPanelToClient(featurepanel, client, Panel_Features, 30);
	CloseHandle(featurepanel);
}

//////////////////////////////////
//P R E M I U M  C O M M A N D S//
//////////////////////////////////
stock DisplayPremiumCommands(client)
{
	new Handle:premiumpanel = CreatePanel();
	DrawPanelItem(premiumpanel, "Commands");
	if(GetConVarInt(cvar_fov))
	{
		DrawPanelText(premiumpanel, "premium_fov <20-170>");
		DrawPanelText(premiumpanel, "- Changes your field of view.");
		DrawPanelText(premiumpanel, " ");
	}
	if(GetConVarInt(cvar_dark))
	{
		DrawPanelText(premiumpanel, "premium_dark");
		DrawPanelText(premiumpanel, "- Makes your character colored black.");
		DrawPanelText(premiumpanel, " ");
	}
	if(GetConVarInt(cvar_glow))
	{
		DrawPanelText(premiumpanel, "premium_glow");
		DrawPanelText(premiumpanel, "- Gives you a glow for 5 minutes.");
		DrawPanelText(premiumpanel, " ");
	}
	if(GetConVarInt(cvar_fov))
	{
		DrawPanelText(premiumpanel, "premium_swapteam");
		DrawPanelText(premiumpanel, "- Switches you to the other team.");
		DrawPanelText(premiumpanel, " ");
	}
	DrawPanelItem(premiumpanel, "Exit");
	SendPanelToClient(premiumpanel, client, Panel_Premium, 30);
	CloseHandle(premiumpanel);
}

////////////////////////////////////
//P L A Y E R  D I S C O N N E C T//
////////////////////////////////////
public OnClientDisconnect(client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		CloseHandle(Handle:speedTimer[client]);
		CloseHandle(Handle:cloakTimer[client]);
		CloseHandle(Handle:cloakHpTimer[client]);
		CloseHandle(Handle:glowTimer[client]);
	}
}

////////////////////////////
//P R E M I U M  B O O S T//
////////////////////////////
stock PremiumBoost(client)
{
	new health = GetClientHealth(client);
	new weaponIndex = GetPlayerWeaponSlot(client, 0);
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	SetEntData(client, offsFOV, fovSaved[client], 1);
	if(GetConVarInt(cvar_ammo)  && (playerClass == TFClass_DemoMan || playerClass == TFClass_Soldier))
	{
		SetEntProp(weaponIndex, Prop_Send, "m_iClip1", GetEntProp(weaponIndex, Prop_Send, "m_iClip1") + 2);
	}
	if(playerClass == TFClass_Medic)
	{
		new index = GetPlayerWeaponSlot(client, 1);
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", GetConVarInt(cvar_uber) * 0.01);
	}
	SetGrenadeAmmo(client, GetConVarInt(cvar_sandman));
	SetJarAmmo(client, GetConVarInt(cvar_jarate));
	SetPremiumColors(client);
	SetEntityHealth(client, health + GetConVarInt(cvar_health));
	speedTimer[client] = CreateTimer(0.1, Timer_Speed, client);
	cloakTimer[client] = CreateTimer(0.1, Timer_Cloak, client);
	cloakHpTimer[client] = CreateTimer(0.1, Timer_Cloak_Health, client);
}

//////////////////////////////
//P A N E L  H A N D L E R S//
//////////////////////////////
public Panel_Features(Handle:menu, MenuAction:action, param1, param2)
{
	//Nothing
}
public Panel_Premium(Handle:menu, MenuAction:action, param1, param2)
{
	//Nothing
}

////////////////////
//S E T  C O L O R//
////////////////////
stock SetPremiumColors(client)
{
	if(GetConVarInt(cvar_color) == 0)
	{
		//Normal
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	if(GetConVarInt(cvar_color))
	{
		//Green
		SetEntityRenderColor(client, 100, 255, 100, 255);
	}
	if(GetConVarInt(cvar_color) == 2)
	{
		//Red
		SetEntityRenderColor(client, 255, 100, 100, 255);
	}
	if(GetConVarInt(cvar_color) == 3)
	{
		//Blue
		SetEntityRenderColor(client, 100, 100, 255, 255);
	}
	if(GetConVarInt(cvar_color) == 4)
	{
		//Yellow
		SetEntityRenderColor(client, 255, 255, 100, 255);
	}
	if(GetConVarInt(cvar_color) == 5)
	{
		//Cyan
		SetEntityRenderColor(client, 100, 255, 255, 255);
	}
	if(GetConVarInt(cvar_color) == 6)
	{
		//Purple
		SetEntityRenderColor(client, 255, 100, 255, 255);
	}
}