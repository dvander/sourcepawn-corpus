/*----------------------------------
			Functions
		- 100% Armor each Round
		- Colored Skin with Disco-Mode
		- Join-Message
		- Player-Trail
		- More Money
		- Reserve Slot
		- Grenade-Trail
		- More Ammo 
		- Colored Smoke
		- No FallDamage
		- Model
		- Chat-Tag
		- Player Trail w/ custom colors
--------------------------------*/
/*
	To-Do-List:
	Admin Menu
	Weapon-Color	
	Play as Chicken,Zombie, whatever you want
	No damage by own HE grenades
	Custom Nicknames
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <morecolors>
#include <clientprefs>
#include <smlib>

#define REQUIRE_PLUGIN
#include <ccc>
#include <scp>

#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "2.1-Beta"


//Grenate trail-Color in RRGGBBAA
#define HEColor 	{225,0,0,225}
#define FlashColor 	{255,255,0,225}
#define SmokeColor	{0,225,0,225}
//---------------------------
#define DMG_FALL   (1 << 5)

//Cookies
new Handle:g_Cookie_Joinmessage;
new Handle:g_Cookie_CSkin;
new Handle:g_Cookie_PTrail;
new Handle:g_Cookie_gTrail;
new Handle:g_Cookie_CSmoke;
new Handle:g_Cookie_PSkin;
new Handle:g_Cookie_TrailColor;
new Handle:g_Cookie_CTag;
new Handle:g_Cookie_WColor;

//Database-Handle
new Handle:g_hDbhandelFVIP;

//Handles
new Handle:g_isenabled = INVALID_HANDLE;
new Handle:g_gueldendskin = INVALID_HANDLE;
new Handle:g_nametag = INVALID_HANDLE;
new Handle:g_viptrail = INVALID_HANDLE;
new Handle:g_vipchat = INVALID_HANDLE;
new Handle:c_cash = INVALID_HANDLE;
new Handle:g_JoinMessageOn = INVALID_HANDLE;
new Handle:g_VipSkinEnabled = INVALID_HANDLE;
new Handle:g_VipFalldamage = INVALID_HANDLE;
new Handle:g_Armor = INVALID_HANDLE;
new Handle:g_CTSkin = INVALID_HANDLE;
new Handle:g_TSkin = INVALID_HANDLE;
new Handle:g_WeaponColor = INVALID_HANDLE;
new Handle:g_TagFarbe = INVALID_HANDLE;
new Handle:g_lifeTime = INVALID_HANDLE;
new Handle:g_material = INVALID_HANDLE;
new Handle:g_let_free = INVALID_HANDLE;
new Handle:g_vip_slots = INVALID_HANDLE;
new Handle:g_ammo = INVALID_HANDLE;
new Handle:thetimer = INVALID_HANDLE;

new Float:lifetime;

new String:materialnew[PLATFORM_MAX_PATH + 1];
new String:g_vipmenuCommands[32][32];
new String:g_premiuminfoCommands[32][32];
new String:g_trailCommands[32][32]; 
new String:g_viponlinelistCommands[32][32];
new String:g_weaponcolorCommands[32][32];
	
new bool:WeaponEdit[MAXPLAYERS + 1][2024];
new bool:lateLoad;

new let_free ,vip_slots, cash ,BeamSprite, ammo;
new maxm = 1;
new IsGameTf2 = 0;

new isVip[MAXPLAYERS+1];
new EndDate[MAXPLAYERS+1];

//Plugin Info
public Plugin:myinfo = 
{
	name = "VIP-Plugin",
	author = "tooti",
	description = "A VIP-Plugin for CS:S/TF2",
	version = PLUGIN_VERSION,
	url = "http://fractal-gaming.de"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoad = late;
}

public OnPluginStart()
{

	new Handle:kv = CreateKeyValues("Vip");
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/vip.cfg");
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	decl String:vipmenuCommands[255];
	decl String:premiuminfoCommands[255];
	decl String:trailCommands[255];
	decl String:viponlinelistCommands[255];
	decl String:weaponcolorCommands[255];
	
	KvGetString(kv, "vipmenu_commands", vipmenuCommands, sizeof(vipmenuCommands));
	KvGetString(kv, "premiuminfo_commands", premiuminfoCommands, sizeof(premiuminfoCommands));
	KvGetString(kv, "trail_commands", trailCommands, sizeof(trailCommands));
	KvGetString(kv, "showvips_commands", viponlinelistCommands, sizeof(viponlinelistCommands));
	KvGetString(kv, "weaponcolor_commands", weaponcolorCommands, sizeof(weaponcolorCommands));
	
	ExplodeString(vipmenuCommands, " ", g_vipmenuCommands, sizeof(g_vipmenuCommands), sizeof(g_vipmenuCommands[]));
	ExplodeString(premiuminfoCommands, " ", g_premiuminfoCommands, sizeof(g_premiuminfoCommands), sizeof(g_premiuminfoCommands[]));
	ExplodeString(trailCommands, " ", g_trailCommands, sizeof(g_trailCommands), sizeof(g_trailCommands[]));
	ExplodeString(viponlinelistCommands, " ", g_viponlinelistCommands, sizeof(g_viponlinelistCommands), sizeof(g_viponlinelistCommands[]));
	ExplodeString(weaponcolorCommands, " ", g_weaponcolorCommands, sizeof(g_weaponcolorCommands), sizeof(g_weaponcolorCommands[]));
	
	CloseHandle(kv);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	/*------------------------------------------------------------------------------*/
	
	new String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "cstrike") || StrEqual(GameName, "tf"))
	{
		if (StrEqual(GameName, "cstrike"))
		{
			HookEvent("weapon_fire", eventWeaponFire);
			HookEvent("smokegrenade_detonate", eventHeDetonate);
		}
		else if (StrEqual(GameName, "tf"))
		{
			IsGameTf2 = 1;
		}		
	}
	else
	{
		LogError("%s is not Supportet, only CS:S/TF2 is currently supportet", GameName);
		SetFailState("%s is not Supportet, only CS:S/TF2 is currently supportet", GameName);
	}
	
	
	CreateConVar("sm_vip_version", PLUGIN_VERSION, "Vip-Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_isenabled = CreateConVar("sm_vip_enabled", "1", "Can this Plugin do his work? ", FCVAR_NOTIFY);
	g_gueldendskin = CreateConVar("sm_gueldenskin_enabled", "1", "User have a  golden skin? ", FCVAR_NOTIFY);
	g_viptrail = CreateConVar("sm_vip_trail", "1", "Can user have a Player Trail?", FCVAR_NOTIFY);
	g_vipchat = CreateConVar("sm_vip_chat", "1", "Can user have a Chat-Tag?", FCVAR_NOTIFY);
	g_JoinMessageOn = CreateConVar("sm_vip_join", "1", "JoinMessage enabled?", FCVAR_NOTIFY);
	g_VipSkinEnabled = CreateConVar("sm_vip_skin", "1", "Vip-Skin enabled?", FCVAR_NOTIFY);
	g_VipFalldamage = CreateConVar("sm_vip_falldamage", "1", "NoFallDamage enabled?", FCVAR_NOTIFY);
	g_WeaponColor = CreateConVar("sm_vip_weaponcolor", "1", "WeaponColor enabled?", FCVAR_NOTIFY);
	
	g_nametag = CreateConVar("sm_vip_tag", "[VIP]", "The Chat tag when he writes a vip message? ");
	g_TagFarbe = CreateConVar("sm_vip_tagfarbe", "FFFF00", "The Tag-Color in Hexdezimal (without #)");
	g_lifeTime = CreateConVar("sm_vip_trail_lifetime", "2.0", "Lifetime of each trail element");
	g_material = CreateConVar("sm_vip_trail_material", "sprites/laserbeam.vmt", "Material to use, start after materials/ ");
	g_let_free = CreateConVar("sm_vip_let_free", "1", "1 = Let a Slot always free and kick a random Player ");
	g_vip_slots = CreateConVar("sm_vip_slots", "5", "How many Reserve Slots should there be ?");
	c_cash = CreateConVar("vip_money_amount", "12000", "x = Cash, what a VIP gets, when he spawns", 0, true, 0.0, true, 16000.0);
	g_ammo = CreateConVar("vip_ammo_amount", "20", "Ammo increase in percent each block!", 0, true, 0.0, true, 100.0);
	g_Armor = CreateConVar("vip_armor", "1", "100% Armor each Spawn? ");
	g_CTSkin = CreateConVar("vip_ctskin", "models/player/slow/masterchief_pack/slow_masterchief_blue.mdl", "CT-Model Path");
	g_TSkin = CreateConVar("vip_tskin", "models/player/slow/masterchief_pack/slow_masterchief_red.mdl", "T-Model Path");
	
	
	AutoExecConfig(true, "plugin.vip");
	LoadTranslations("vip.phrases");
//--------------------------------------------------------------------------------------------------------------------------------------------	
	g_Cookie_Joinmessage = RegClientCookie("sm_vip_join-message", "VIP Join-Message", CookieAccess_Private);
	g_Cookie_CSkin = RegClientCookie("sm_vip_cskin", "VIP cskin", CookieAccess_Private);
	g_Cookie_PTrail = RegClientCookie("sm_vip_ptrail", "VIP Player trail", CookieAccess_Private);
	g_Cookie_gTrail = RegClientCookie("sm_vip_gTrail", "VIP Grenate Trail", CookieAccess_Private);
	g_Cookie_CSmoke = RegClientCookie("sm_vip_CSmoke", "VIP Colored-Smoke", CookieAccess_Private);
	g_Cookie_PSkin = RegClientCookie("sm_vip_pSkin", "VIP Player-Skin", CookieAccess_Private);
	g_Cookie_CTag = RegClientCookie("sm_vip_cTag", "VIP Chat-tag", CookieAccess_Private);
	g_Cookie_TrailColor = RegClientCookie("sm_vip_TrailColor", "VIP Trail-Color", CookieAccess_Private);
	g_Cookie_WColor = RegClientCookie("g_Cookie_WColor", "VIP Weapon-Color", CookieAccess_Private);
//--------------------------------------------------------------------------------------------------------------------------------------------
	
	SQL_TConnect(ConnectToDatabase, "vip");		
	
	//Event-Hooks
	HookEvent("round_start",  Event_RoundStart);
	HookEvent("player_spawn", Event_SpawnEvent);
	HookEvent("player_death", Event_PlayerDeath);
		
	
	if (lateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}		
	
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientVip(i))
		{
			CCC_SetTag(i, ""); 
			DeleteTrail(i);
		}
	}
}

public Action:Command_Say(client, const String:command[], args)
{
	if (0 < client <= MaxClients && !IsClientInGame(client)) 
		return Plugin_Continue;   

	decl String:text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	for (new index = 0; index < 32; index++) 
	{
		if (StrEqual(g_vipmenuCommands[index], text))
		{
			Command_Vip(client);
			
			if (text[0] == 0x2F)
				return Plugin_Handled;
				
			return Plugin_Continue;
		}  		
		if (StrEqual(g_premiuminfoCommands[index], text))
		{
			Command_VipInfo(client);
			
			if (text[0] == 0x2F)
				return Plugin_Handled;
				
			return Plugin_Continue;
		}    		
		if (StrEqual(g_trailCommands[index], text))
		{
			Command_Trail(client);
			
			if (text[0] == 0x2F)
				return Plugin_Handled;
				
			return Plugin_Continue;
		}
		if (StrEqual(g_viponlinelistCommands[index], text))
		{
			Command_Vlist(client);
			
			if (text[0] == 0x2F)
				return Plugin_Handled;
				
			return Plugin_Continue;
		}        
		/*if (StrEqual(g_weaponcolorCommands[index], text))
		{
			Command_WeaponColor(client);
			
			if (text[0] == 0x2F)
				return Plugin_Handled;
				
			return Plugin_Continue;
		} */
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	decl String:materialPrecache[PLATFORM_MAX_PATH + 1];
	GetConVarString(g_material, materialPrecache, sizeof(materialPrecache));
	
	Format(materialnew, sizeof(materialnew), "materials/%s", materialPrecache);
	if (FileExists(materialnew))
	{
		AddFileToDownloadsTable(materialnew);
		strcopy(materialPrecache, sizeof(materialPrecache), materialnew);
		ReplaceString(materialPrecache, sizeof(materialPrecache), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(materialPrecache);
	}

	
	let_free = GetConVarInt(g_let_free);
	vip_slots = GetConVarInt(g_vip_slots);
	cash = GetConVarInt(c_cash);
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		DeleteTrail(i);
	}
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	
	if (thetimer != INVALID_HANDLE) 
	{
		KillTimer(thetimer);
	}
	thetimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
	
	new String:CTModel[PLATFORM_MAX_PATH];
	new String:TModel[PLATFORM_MAX_PATH];
	GetConVarString(g_CTSkin, CTModel, sizeof(CTModel));
	GetConVarString(g_TSkin, TModel, sizeof(TModel));
	PrecacheModel(CTModel);
	PrecacheModel(TModel);
}

public OnClientDisconnect(client)
{	
	if(IsClientValid(client))
	{
		CCC_SetTag(client, ""); 
		DeleteTrail(client);
	}
}

/*--------------------------------------------Stocks---------------------------------------------*/
stock bool:IsClientValid(id)
{
    if(Client_IsValid(id) && !IsFakeClient(id) && IsClientConnected(id))
    {
        return true;
    }
    
    return false;
}

public ConnectToDatabase(Handle:owner, Handle:hndl, const String:error[], any:Data)
{
	if(hndl == INVALID_HANDLE)
	{
		PrintToServer("Connection failed || Error: %s",error);
		LogError("Error connecting to the database: %s", error);
	}
	else 
	{
		g_hDbhandelFVIP = hndl;
		CreateDatabase();
		PrintToServer("Connection successful, Vip-Plugin Loaded");
	}
}

public CreateDatabase(){
		new String:Query[255];
		Format(Query, sizeof(Query), "CREATE TABLE IF NOT EXISTS `donations` (`id` INT(255) NOT NULL AUTO_INCREMENT,`steamid` VARCHAR(32) NOT NULL,`expire` VARCHAR(50) NULL DEFAULT NULL,`IngameName` VARCHAR(64) NULL DEFAULT NULL,PRIMARY KEY (`id`),UNIQUE INDEX `steamid`(`steamid`))");
		SQL_FastQuery(g_hDbhandelFVIP, Query);
}

public GotOutputFVIP(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:steamid[32];
	new String:expire[32];
	
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
		SQL_FetchString(hndl, 1, expire, sizeof(expire));
	}
	
	new time = GetTime();
	new szTime = StringToInt(expire);
	for (new i = 1;i <MaxClients;i++)
	{
		new String:auth[32];
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientAuthString(i, auth, sizeof(auth));
		}
		if(StrEqual(auth, steamid))
		{
			if(time == szTime || time <= szTime || szTime == 0)
			{
				isVip[i] = 1;
				EndDate[i] = szTime;
			}
			else
			{
				isVip[i] = 0;
			}
		}
	}	
} 

stock bool:IsClientVip(v_id)
{
	new String:auth[32];
	GetClientAuthString(v_id, auth, sizeof(auth));
	static String:query[256];
	Format(query, sizeof(query), "SELECT steamid, expire FROM donations WHERE steamid='%s';", auth);
	SQL_TQuery(g_hDbhandelFVIP, GotOutputFVIP, query);
	if(isVip[v_id] == 1)
	{
		return true;
	}
	return false;
}

stock bool:IsClientAdmin(a_id)
{
	new AdminId:adminId = GetUserAdmin(a_id);
	if(adminId != INVALID_ADMIN_ID && GetAdminFlag(adminId, Admin_Chat))
    {
		return true;
    }
	return false;
}

/*----------------------------------------------------------------------------------------------*/

public OnClientPostAdminCheck(client)
{
	CreateTimer(0.5, Function_OnPost, client);
}

public Action:Function_OnPost(Handle:timer, any:client) 
{
	decl String:sCookieValue[11];
	GetClientCookie(client, g_Cookie_Joinmessage, sCookieValue, sizeof(sCookieValue));
	new cookieValue = StringToInt(sCookieValue);
	new isOn = GetConVarBool(g_JoinMessageOn);
	
	if(IsClientValid(client))
	{
		if(IsClientVip(client))
		{
			if(IsClientValid(client) && cookieValue == 0 && (isOn) == 1)
			{
				new String:name[64];
				GetClientName(client, name, sizeof(name));
				CPrintToChatAll("%t","JoinMessage",name);
			}
			
			if(IsClientValid(client))
			{
				GetClientCookie(client, g_Cookie_CTag, sCookieValue, sizeof(sCookieValue));
				new cookieValue2 = StringToInt(sCookieValue);
				
				new isOn2 = GetConVarBool(g_vipchat);
				if((isOn2) == 1 && cookieValue2 == 0)
				{
					new String:tagformat[64];
					new String:tagbuffer[64];
					new String:tagcolor[64];
					GetConVarString(g_nametag, tagbuffer, sizeof(tagbuffer));
					GetConVarString(g_TagFarbe, tagcolor, sizeof(tagcolor));
					Format(tagformat, sizeof(tagformat), "%s ", tagbuffer);
					CCC_SetTag(client, tagformat); 
					CCC_SetColor(client, CCC_TagColor, StringToInt(tagcolor,16), false);
				}	
			}	
			CreateTimer(5.0, Function_UpdatePlayerName, client);
		}	
	}	
}

public Action:Function_UpdatePlayerName(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		if(IsClientVip(client))
		{
			new String:query[1024];
			new String:name[64];
			new String:auth[64];
			GetClientName(client, name, sizeof(name));
			GetClientAuthString(client, auth, sizeof(auth));
			Format(query, sizeof(query), "UPDATE `donations` SET `IngameName`='%s' WHERE `steamid`='%s';",name,auth);
			
			SQL_LockDatabase(g_hDbhandelFVIP);
			new Handle:hQuery = SQL_Query(g_hDbhandelFVIP, query);
			if (hQuery == INVALID_HANDLE)
			{
				SQL_UnlockDatabase(g_hDbhandelFVIP);
			}
			SQL_UnlockDatabase(g_hDbhandelFVIP);
			CloseHandle(hQuery);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
//Main-Menu
public Action:Command_Vip(client)
{
	if(IsClientValid(client))
	{
		if(IsClientVip(client))
		{
			new isOn = GetConVarBool(g_isenabled);
			if ((isOn) == 1)
			{
				new Handle:menu = CreateMenu(MenuHandler1);
				if(EndDate[client] == 0)
				{
					SetMenuTitle(menu, "[VIP]-Menu \n: -Never- ");
				}
				else
				{
					new String:buffer[1024];
					FormatTime(buffer, sizeof(buffer), "%d.%m.%Y", EndDate[client]);
					SetMenuTitle(menu, "[VIP]-Menu \nVip ends: %s",buffer);
				}
				if (AreClientCookiesCached(client))
				{
					decl String:sCookieValueJM[11];
					decl String:sCookieValueCS[11];
					decl String:sCookieValuePT[11];
					decl String:sCookieValueGT[11];
					decl String:sCookieValueCSM[11];
					decl String:sCookieValuePS[11];
					decl String:sCookieValueCT[11];
					GetClientCookie(client, g_Cookie_Joinmessage, sCookieValueJM, sizeof(sCookieValueJM));
					GetClientCookie(client, g_Cookie_CSkin, sCookieValueCS, sizeof(sCookieValueCS));
					GetClientCookie(client, g_Cookie_PTrail, sCookieValuePT, sizeof(sCookieValuePT));
					GetClientCookie(client, g_Cookie_gTrail, sCookieValueGT, sizeof(sCookieValueGT));
					GetClientCookie(client, g_Cookie_CSmoke, sCookieValueCSM, sizeof(sCookieValueCSM));
					GetClientCookie(client, g_Cookie_PSkin, sCookieValuePS, sizeof(sCookieValuePS));
					GetClientCookie(client, g_Cookie_CTag, sCookieValueCT, sizeof(sCookieValueCT));
					new cookieValueJM = StringToInt(sCookieValueJM);
					new cookieValueCS = StringToInt(sCookieValueCS);
					new cookieValuePT = StringToInt(sCookieValuePT);
					new cookieValueGT = StringToInt(sCookieValueGT);
					new cookieValueCSM = StringToInt(sCookieValueCSM);
					new cookieValuePS = StringToInt(sCookieValuePS);
					new cookieValueCT = StringToInt(sCookieValueCT);
					
					new isJMOn = GetConVarBool(g_JoinMessageOn);
					if((isJMOn) == 1)
					{
						if(cookieValueJM == 0)
						{
							AddMenuItem(menu, "JoinMessageOn", "Join Message: On");
						}	
						else
						{
							AddMenuItem(menu, "JoinMessageOff", "Join Message: Off");
						}
					}
					else
					{
						AddMenuItem(menu, "JoinMessageOn", "Join Message: Off", ITEMDRAW_DISABLED);
					}
					
					new isGSOn = GetConVarBool(g_gueldendskin);
					if((isGSOn) == 1)
					{
						if(cookieValueCS == 0)
						{
							AddMenuItem(menu, "ColoredSkinOn", "Colored Skin: On");
						}	
						else
						{
							AddMenuItem(menu, "ColoredSkinOff", "Colored Skin: Off");
						}
					}
					else
					{
						AddMenuItem(menu, "ColoredSkinOn", "Colored Skin: Off", ITEMDRAW_DISABLED);
					}	
					
					new isPTOn = GetConVarBool(g_viptrail);
					if((isPTOn) == 1)
					{
						if(cookieValuePT == 0)
						{
							AddMenuItem(menu, "PlayerTrailOn", "Player Trail: On");
						}	
						else
						{
							AddMenuItem(menu, "PlayerTrailOnCC", "Player Trail: Off");
						}
					}
					else
					{
						AddMenuItem(menu, "PlayerTrailOn", "Player Trail: Off", ITEMDRAW_DISABLED);
					}		
					
					if(IsGameTf2 == 0)
					{
						if(cookieValueGT == 0)
						{
							AddMenuItem(menu, "GrenadeTrailOn", "Grenade Trail: On");
						}	
						else
						{
							AddMenuItem(menu, "GrenadeTrailOff", "Grenade Trail: Off");
						}
						
						if(cookieValueCSM == 0)
						{
							AddMenuItem(menu, "ColoredSmokeOn", "Colored Smoke: On");
						}	
						else
						{
							AddMenuItem(menu, "ColoredSmokeOff", "Colored Smoke: Off");
						}
					
						new isVKOn = GetConVarBool(g_VipSkinEnabled);
						if((isVKOn) == 1)
						{
							if(cookieValuePS == 0)
							{
								AddMenuItem(menu, "PlayerSkinOn", "Player Skin: On");
							}	
							else
							{
								AddMenuItem(menu, "PlayerSkinOff", "Player Skin: Off");
							}
						}
						else
						{
							AddMenuItem(menu, "PlayerSkinOff", "Player Skin: Off", ITEMDRAW_DISABLED);
						}
					}
					else
					{
						AddMenuItem(menu, "GrenadeTrailOff", "Grenade Trail: Off", ITEMDRAW_DISABLED);
						AddMenuItem(menu, "ColoredSmokeOff", "Colored Smoke: Off", ITEMDRAW_DISABLED);
						AddMenuItem(menu, "PlayerSkinOff", "Player Skin: Off", ITEMDRAW_DISABLED);
					}
					
					new isCTOn = GetConVarBool(g_vipchat);
					if((isCTOn) == 1)
					{
						if(cookieValueCT == 0)
						{
							AddMenuItem(menu, "ChatTagOn", "Chat Tag: On");
						}	
						else
						{
							AddMenuItem(menu, "ChatTagOff", "Chat Tag: Off");
						}
					}	
					else
					{
						AddMenuItem(menu, "ChatTagOff", "Chat Tag: Off", ITEMDRAW_DISABLED);
					}	
				}					
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 0);
			}	
			else
			{
				CPrintToChat(client, "%t", "VipDisabled");
			}	
		}
		else
		{
			CPrintToChat(client, "%t", "NotaVip");
		}
	}
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		switch (param2) 
        { 
			case 0:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_Joinmessage, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_Joinmessage, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_Joinmessage, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
			}
			case 1:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_CSkin, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CSkin, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CSkin, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}			
			}
			case 2:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_PTrail, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_PTrail, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else 
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_PTrail, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
			}
			case 3:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_gTrail, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_gTrail, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_gTrail, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
			}
			case 4:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_CSmoke, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CSmoke, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CSmoke, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
			}
			case 5:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_PSkin, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_PSkin, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_PSkin, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
			}	
			case 6:
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_CTag, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				if(cookieValue == 0)
				{	
					CCC_SetTag(client, ""); 
					cookieValue++;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CTag, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}
				else
				{
					new String:tagformat[64];
					new String:tagbuffer[64];
					GetConVarString(g_nametag, tagbuffer, sizeof(tagbuffer));
					Format(tagformat, sizeof(tagformat), "%s ", tagbuffer);
					CCC_SetTag(client, tagformat); 
					CCC_SetColor(client, CCC_TagColor, COLOR_GREEN, false);
					cookieValue--;
					IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));
					SetClientCookie(client, g_Cookie_CTag, sCookieValue);
					FakeClientCommandEx(client, "say %s", g_vipmenuCommands[1]);
				}	
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
}

//--------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------------
//Premium Info ^^_
public Action:Command_VipInfo(client)
{
	if(IsClientValid(client))
	{
			new Handle:menuf = CreateMenu(MenuHandler1f);
			SetMenuTitle(menuf, "VIP-Features");
			decl String:path[PLATFORM_MAX_PATH];
			BuildPath(Path_SM,path,sizeof(path),"configs/vipinfo.txt");
			new Handle:VipInfo = OpenFile(path, "r"); 
			new Handle:stringArray = CreateArray(256); 
			new String:lineBuf[256]; 
			while(ReadFileLine(VipInfo, lineBuf, sizeof(lineBuf))) 
			{ 
				ReplaceString(lineBuf, sizeof(lineBuf), "\n", "", false); 
				PushArrayString(stringArray, lineBuf); 
			} 
			CloseHandle(VipInfo); 
			new stringArraySize = GetArraySize(stringArray); 
			for(new i = 0; i < stringArraySize; i++) 
			{ 
				GetArrayString(stringArray, i, lineBuf, sizeof(lineBuf));
				new String:buffer[1024];
				Format(buffer, sizeof(buffer), "%s", lineBuf);
				AddMenuItem(menuf, buffer, buffer);
			} 
			
			SetMenuExitButton(menuf, true);
			DisplayMenu(menuf, client, 10);
		}	
	return Plugin_Handled;
}

public MenuHandler1f(Handle:menuf, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		CloseHandle(menuf);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuf);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
}

//---------------------------------------------------------------------------------
//----------------------------Events-------------------------------------------
//---------------------------------------------------------------------------------

public Action:Event_SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientVip(client))
	{
		CreateTimer(0.2, GiveEquipment, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(6.0, PlayerColor, client, TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(1.0, WeaponColorTimer, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT)
	}	
		
	if (IsClientValid(client))
	{
		DeleteTrail(client);
		if (IsClientVip(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
			{
				CreateTimer(2.5, SetupTrail, client);
			}
		}
	}
	
	if(IsGameTf2 == 0)
	{
		if (IsClientValid(client) && IsClientVip(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
			{
				new OldMoney = GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"));
				new NewMoney = cash + OldMoney;
				if (NewMoney > 16000 && maxm) 
				{
					NewMoney = 16000;
				}
				SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"), NewMoney);
			}
		}	
		
		if(IsClientValid(client))
		{
			if (IsClientVip(client))
			{
				decl String:sCookieValue[11];
				GetClientCookie(client, g_Cookie_PSkin, sCookieValue, sizeof(sCookieValue));
				new cookieValue = StringToInt(sCookieValue);
				new isOn = GetConVarBool(g_VipSkinEnabled);
				new String:CTModel[PLATFORM_MAX_PATH];
				new String:TModel[PLATFORM_MAX_PATH];
				GetConVarString(g_CTSkin, CTModel, sizeof(CTModel));
				GetConVarString(g_TSkin, TModel, sizeof(TModel));
				
				if((isOn) == 1 && cookieValue == 0)
				{
					if (GetClientTeam(client) == 2)
					{
					  SetEntityModel(client, TModel);
					} 
					
					if(GetClientTeam(client) == 3)
					{
					  SetEntityModel(client, CTModel);
					} 
				}	
			}
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	for (new x=0; x < 2024; x++) 
	{
		WeaponEdit[client][x] = false;
	}
	DeleteTrail(client);
}

public Action:GiveEquipment(Handle:timer, any:client)
{
	new isOn = GetConVarBool(g_Armor);
	if((isOn) == 1)
	{
		set_100armor(client);
	}	
	return Plugin_Handled;
}

public Action:PlayerColor(Handle:timer, any:client)
{
	guelden_skin(client);
	return Plugin_Handled;
}

public Action:WeaponColorTimer(Handle:timer, any:client)
{
	decl String:sCookieValue[11];
	GetClientCookie(client, g_Cookie_WColor, sCookieValue, sizeof(sCookieValue));
	
	new iWeaponEnt = -1; 
	new iSlot;
	iWeaponEnt = GetPlayerWeaponSlot(client, iSlot);
	if (IsValidEntity(iWeaponEnt))
	{
		SetEntityRenderColor(iWeaponEnt, 0,0,0,255);
		SetEntityRenderFx(iWeaponEnt, RENDERFX_NONE);
		SetEntityRenderMode(iWeaponEnt, RENDER_TRANSCOLOR);
	}
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x < 2024; x++)
	{
		for (new i=0; i <= MaxClients; i++) 
		{
			WeaponEdit[i][x] = false;
		}
	}
}

/*--------------------------------------------------------------------------------------------------*/
/*--------------------------------------------FUNCTIONS---------------------------------------------*/
/*--------------------------------------------------------------------------------------------------*/

public set_100armor(a_id)
{
	new armor = Client_GetArmor(a_id);
	if(armor != 100)
	{
		Client_SetArmor(a_id, 100);
	}
}

/*--------------------------------------------Golden-Skin---------------------------------------------*/
public guelden_skin(s_id)
{
	decl String:sCookieValue[11];
	GetClientCookie(s_id, g_Cookie_CSkin, sCookieValue, sizeof(sCookieValue));
	new cookieValue = StringToInt(sCookieValue);
	
	new isOn = GetConVarBool(g_gueldendskin);
	if((isOn) == 1)
	{
		if(IsClientValid(s_id) && IsClientVip(s_id))
		{
			if(cookieValue == 0)
			{
				if(IsClientVip(s_id))
				{
					new g_client = s_id;
					SetEntityRenderMode(g_client, RENDER_TRANSCOLOR);
					SetEntityRenderColor(g_client, 255, 215, 0, 255);
				}	
			}	
		}
	}	
}
 
/*-------------------------------------------Player Trail---------------------------------------------*/
new Handle:beamTimer[MAXPLAYERS+1];
new haveBeam[MAXPLAYERS+1];

public Action:SetupTrail(Handle:timer, any:client)
{
	decl String:sCookieValue[11];
	GetClientCookie(client, g_Cookie_PTrail, sCookieValue, sizeof(sCookieValue));
	new cookieValue = StringToInt(sCookieValue);
	
	new isOn = GetConVarBool(g_viptrail);
	if((isOn) == 1)
	{
		if (IsClientValid(client))
		{
			if(cookieValue == 0)
			{
				if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
				{
					CreateTrail2(client);
				}
			}
		}
	}
}

public CreateTrail2(client)
{
	if (IsClientValid(client) && haveBeam[client] == -1)
	{
		DeleteTrail(client);
		new ent = CreateEntityByName("env_spritetrail");

		if (ent != -1 && IsValidEntity(ent))
		{
			new Float:Orig[3];
			decl String:name[MAX_NAME_LENGTH + 1];
			GetClientName(client, name, sizeof(name));
			lifetime = GetConVarFloat(g_lifeTime);
			
			DispatchKeyValue(client, "targetname", name);
			DispatchKeyValue(ent, "parentname", name);
			DispatchKeyValueFloat(ent, "endwidth", 2.0);
			DispatchKeyValueFloat(ent, "startwidth", 3.0);
			DispatchKeyValueFloat(ent, "lifetime", lifetime);
			DispatchKeyValue(ent, "renderamt", "255");
			DispatchKeyValue(ent, "spritename", materialnew);			
			
			decl String:sCookieValue[20];
			GetClientCookie(client, g_Cookie_TrailColor, sCookieValue, sizeof(sCookieValue));
			if(strlen(sCookieValue) == 0)
			{
				SetClientCookie(client, g_Cookie_TrailColor, "111 111 111 255");
			} 
			
			DispatchKeyValue(ent, "rendercolor", sCookieValue);
				
			DispatchKeyValue(ent, "rendermode", "5");

			DispatchSpawn(ent);

			GetClientAbsOrigin(client, Orig);
			
			Orig[2] += 10.0;

			
			TeleportEntity(ent, Orig, NULL_VECTOR, NULL_VECTOR);
			
			SetVariantString(name);
			AcceptEntityInput(ent, "SetParent"); 
			SetEntPropFloat(ent, Prop_Send, "m_flTextureRes", 0.05);
			haveBeam[client] = ent;
		}
	}
}

public DeleteTrail(client)
{
	if (beamTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(beamTimer[client]);
	}

	beamTimer[client] = INVALID_HANDLE;

	new ent = haveBeam[client];

	if (ent != -1 && IsValidEntity(ent))
	{
		decl String:class[128];
		GetEdictClassname(ent, class, sizeof(class));
		if (StrEqual(class, "env_spritetrail")) 
		{
			RemoveEdict(ent);
		}
	}

	haveBeam[client] = -1;
}

public Action:Command_Trail(client)
{
	new IsOn = GetConVarInt(g_viptrail);
	if(IsClientValid(client) && IsOn == 1)
	{
		new Handle:menuTC = CreateMenu(MenuHandlerTC);
		if(IsClientVip(client))
		{
			SetMenuTitle(menuTC, "Trail Color");
			AddMenuItem(menuTC, "BLUE", "Blue");
			AddMenuItem(menuTC, "RED", "Red");
			AddMenuItem(menuTC, "GREEN", "Green");
			AddMenuItem(menuTC, "BURLYWOOD", "Burlywood");
			AddMenuItem(menuTC, "LILA", "Purple");
			AddMenuItem(menuTC, "PINK", "Pink");
			AddMenuItem(menuTC, "Paleturquoise", "Paleturquoise");
			//2-Seite
			AddMenuItem(menuTC, "YELLOW", "Yellow");
			AddMenuItem(menuTC, "ORANGE", "Orange");
			AddMenuItem(menuTC, "TUERKIS", "Turquoise");
			AddMenuItem(menuTC, "GOLD", "Gold");
			AddMenuItem(menuTC, "GREY", "Grey");			
			AddMenuItem(menuTC, "SILVER", "Silver");
			AddMenuItem(menuTC, "BROWN", "Brown");
			
			SetMenuExitButton(menuTC, true);
			DisplayMenu(menuTC, client, 0);
		}
		else
		{
			CPrintToChat(client, "%t", "NotaVip");
		}
	}	
	else
	{
		CPrintToChat(client, "%t", "FunctionDisabled");
	}	
	return Plugin_Handled;
}

public MenuHandlerTC(Handle:menuTC, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "000 000 255 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 1:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "255 000 000 255 ");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 2:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "000 255 000 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 3:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "222 184 135 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 4:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "150 000 255 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);			
			}
			case 5:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "255 020 147 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 6:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "187 255 255 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			//--Seite 2
			case 7:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "255 255 000 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 8:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "255 165 000 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 9:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "064 224 208 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 10:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "255 215 000 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 11:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "105 105 105 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 12:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "166 166 166 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 13:
			{
				SetClientCookie(client, g_Cookie_TrailColor, "139 069 019 255");
				DeleteTrail(client);
				CreateTimer(2.5, SetupTrail, client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuTC);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
}

/*--------------------------------------------Vip-Slot---------------------------------------------*/
public VipSlotCheck(client)
{
	new max_players = MaxClients;
	new current_players = GetClientCount(false);
	new max_slots = max_players - current_players;

	if (vip_slots > max_slots)
	{
		if (IsClientVip(client)) 
		{
			KickClient(client, "%t","ReservedSlotCheck");
		}
	}
	
	current_players = GetClientCount(false);
	max_slots = max_players - current_players;
	
	if (let_free)
	{
		if (!max_slots)
		{
			new bool:playeringame = false;
			while(!playeringame)
			{
				new RandPlayer = GetRandomInt(1, MaxClients);
				if (IsClientValid(RandPlayer))
				{
					if (!IsClientVip(RandPlayer) && !IsClientAdmin(RandPlayer))
					{
						KickClient(RandPlayer, "%t", "ReservedSlotFree");
						playeringame = true;
					}
				}
			}
		}
	}
}


//----Grenade Trail!
public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sCookieValue[11];
	GetClientCookie(client, g_Cookie_gTrail, sCookieValue, sizeof(sCookieValue));
	new cookieValue = StringToInt(sCookieValue);
	
	decl String:weapon[64];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (IsClientValid(client))
	{
		if (IsClientVip(client))
		{
			if(cookieValue == 0)
			{
				if (StrEqual(weapon, "hegrenade"))
				{
					CreateTimer(0.15, SetupHE, client);
				}

				else if (StrEqual(weapon, "flashbang"))
				{
					CreateTimer(0.15, SetupFlash, client);
				}

				else if (StrEqual(weapon, "smokegrenade"))
				{
					CreateTimer(0.15, SetupSmoke, client);
				}
			}	
		}
	}
}

public Action:SetupHE(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "hegrenade_projectile");
	
	AddTrail(client, ent, HEColor);
}

public Action:SetupFlash(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "flashbang_projectile");
	
	AddTrail(client, ent, FlashColor);
}

public Action:SetupSmoke(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "smokegrenade_projectile");
	
	AddTrail(client, ent, SmokeColor);
}

public AddTrail(client, ent, tcolor[4])
{
	if (ent != -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		if (IsValidEntity(ent) && owner == client)
		{
			TE_SetupBeamFollow(ent, BeamSprite,	0, 5.0, 3.0, 3.0, 1, tcolor);
			TE_SendToAll();
		}
	}
}

//--Colored Smoke!
public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sCookieValue[11];
	GetClientCookie(client, g_Cookie_CSmoke, sCookieValue, sizeof(sCookieValue));
	new cookieValue = StringToInt(sCookieValue);
	
	
	if (IsClientValid(client))
	{
		if (IsClientVip(client))
		{
			if(cookieValue == 0)
			{
				new Float:origin[3];
				
				origin[0] = GetEventFloat(event, "x");
				origin[1] = GetEventFloat(event, "y");
				origin[2] = GetEventFloat(event, "z");
				
				new ent_light = CreateEntityByName("light_dynamic");
				if (ent_light != -1)
				{
					CreateTimer(0.2, ColoredSmoke, ent_light, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					DispatchKeyValue(ent_light, "pitch", "-90");
					DispatchKeyValue(ent_light, "distance", "256");
					DispatchKeyValue(ent_light, "spotlight_radius", "96");
					DispatchKeyValue(ent_light, "brightness", "3");
					DispatchKeyValue(ent_light, "style", "6");
					DispatchKeyValue(ent_light, "spawnflags", "1");
					DispatchSpawn(ent_light);
					
					AcceptEntityInput(ent_light, "DisableShadow");
					AcceptEntityInput(ent_light, "TurnOn");
					
					TeleportEntity(ent_light, origin, NULL_VECTOR, NULL_VECTOR);
					CreateTimer(20.0, delete, ent_light, TIMER_FLAG_NO_MAPCHANGE);
				}
			}	
		}
	}
}

public Action:ColoredSmoke(Handle:timer, any:light)
{
	if (!IsValidEntity(light)) 
	{
		return Plugin_Handled;
	}

	new String:sBuffer[64] = "255 215 000 200";
	DispatchKeyValue(light, "_light", sBuffer);
	
	return Plugin_Continue;
}

public Action:delete(Handle:timer, any:light)
{
	if (IsValidEntity(light))
	{
		decl String:class[128];
		
		GetEdictClassname(light, class, sizeof(class));
		
		if (StrEqual(class, "light_dynamic")) 
		{
			RemoveEdict(light);
		}
	}
} 


//---More Ammo
public Action:CheckWeapons(Handle:timer, any:data)
{
	ammo = GetConVarInt(g_ammo);
	for (new i = 1; i <= MaxClients; i++)
	{
		new client = i;
		if(IsClientValid(client) && Client_IsIngameAuthorized(client) && IsClientConnected(client))
		{
			if (IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
			{
				if(IsClientVip(client) && Client_IsIngameAuthorized(client) && IsClientConnected(client) && IsClientValid(client))
				{
					for (new x=0; x < 2; x++)
					{
						new weapon = GetPlayerWeaponSlot(client, x);
						if (weapon != -1 && !WeaponEdit[client][weapon])
						{
							new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
							if (ammotype != -1)
							{
								new cAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
								if (cAmmo > 0 && cAmmo <= 1000)
								{
									new newAmmo;
									newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * (3 * ammo)));
									if(newAmmo >= 900) 
									{
										SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
										WeaponEdit[client][weapon] = true;
									}
								}
							}
						}
					}						
				}
			}
		}	
	}
	return Plugin_Continue;
}

//---NoFallDamage
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new isOn = GetConVarBool(g_VipFalldamage);
	if((isOn) == 1 && IsClientValid(client))
	{
		if (damagetype & DMG_FALL)
		{
			if(IsClientVip(client))
			{
				return Plugin_Handled;
			}	
			else
			{
				return Plugin_Continue;
			}
		}
	}	
	return Plugin_Continue;
}

//--VIP's Online List-----------
public Action:Command_Vlist(client)
{
	decl String:VipName[MAX_NAME_LENGTH];
	new Handle:viplistmenu = CreateMenu(viplist);
	SetMenuTitle(viplistmenu, "Vip's online are:"); 
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i))
		{
			if(IsClientVip(i))
			{
				GetClientName(i, VipName, sizeof(VipName));
				AddMenuItem(viplistmenu, VipName, VipName);
			}
		}
	}
	SetMenuExitButton(viplistmenu, true);
	DisplayMenu(viplistmenu, client, 20);
}

public viplist(Handle:viplistmenu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		CloseHandle(viplistmenu);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(viplistmenu);
	}
}

//-Weapon-Color
public Action:Command_WeaponColor(client)
{
	new IsOn = GetConVarInt(g_WeaponColor);
	if(IsClientValid(client) && IsOn == 1)
	{
		new Handle:menuWC = CreateMenu(MenuHandlerWC);
		if(IsClientVip(client))
		{
			SetMenuTitle(menuWC, "Weapon Color");
			AddMenuItem(menuWC, "NORMAL", "Normal");
			AddMenuItem(menuWC, "BLUE", "Blue");
			AddMenuItem(menuWC, "RED", "Red");
			AddMenuItem(menuWC, "GREEN", "Green");
			AddMenuItem(menuWC, "BURLYWOOD", "Burlywood");
			AddMenuItem(menuWC, "LILA", "Purple");
			AddMenuItem(menuWC, "PINK", "Pink");
			//2-Seite
			AddMenuItem(menuWC, "YELLOW", "Yellow");
			AddMenuItem(menuWC, "ORANGE", "Orange");
			AddMenuItem(menuWC, "TUERKIS", "Turquoise");
			AddMenuItem(menuWC, "GOLD", "Gold");
			AddMenuItem(menuWC, "GREY", "Grey");			
			AddMenuItem(menuWC, "SILVER", "Silver");
			AddMenuItem(menuWC, "BROWN", "Brown");
			
			SetMenuExitButton(menuWC, true);
			DisplayMenu(menuWC, client, 0);
		}
		else
		{
			CPrintToChat(client, "%t", "NotaVip");
		}
	}	
	else
	{
		CPrintToChat(client, "%t", "FunctionDisabled");
	}	
	return Plugin_Handled;
}

public MenuHandlerWC(Handle:menuWC, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SetClientCookie(client, g_Cookie_WColor, "000 ,000 ,000 ,255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 1:
			{
				SetClientCookie(client, g_Cookie_WColor, "000 ,000 ,255 ,255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 2:
			{
				SetClientCookie(client, g_Cookie_WColor, "255 ,000 ,000 ,255 ");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 3:
			{
				SetClientCookie(client, g_Cookie_WColor, "000 255 000 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 4:
			{
				SetClientCookie(client, g_Cookie_WColor, "222 184 135 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 5:
			{
				SetClientCookie(client, g_Cookie_WColor, "150 000 255 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);			
			}
			case 6:
			{
				SetClientCookie(client, g_Cookie_WColor, "255 020 147 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			//--Seite 2
			case 7:
			{
				SetClientCookie(client, g_Cookie_WColor, "255 255 000 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 8:
			{
				SetClientCookie(client, g_Cookie_WColor, "255 165 000 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 9:
			{
				SetClientCookie(client, g_Cookie_WColor, "064 224 208 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 10:
			{
				SetClientCookie(client, g_Cookie_WColor, "255 215 000 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 11:
			{
				SetClientCookie(client, g_Cookie_WColor, "105 105 105 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 12:
			{
				SetClientCookie(client, g_Cookie_WColor, "166 166 166 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			case 13:
			{
				SetClientCookie(client, g_Cookie_WColor, "139 069 019 255");
				DeleteTrail(client);
				FakeClientCommandEx(client, "say %s", g_trailCommands[1]);
			}
			
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuWC);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
}