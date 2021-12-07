#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <tf2items>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#include <autoexecconfig>
#include <clientprefs>
#include <tf2attributes>
#include <fc>
#include <tf2items_giveweapon>

#undef REQUIRE_PLUGIN
#include <freak_fortress_2>

#define PLUGIN_NAME     "[Dynamic] VIP Perks"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "1.0.0"
#define PLUGIN_DESCRIPTION	"Perks created for VIP/VIP+ members."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

#define VIP "{green}[{lightgreen}VIP{green}]{default}"
#define VIPPLUS "{green}[{lightgreen}VIP +{green}]{default}"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

new bool:g_bLateLoad = false;

new bool:pGlow[MAXPLAYERS+1] = false;
new bool:pFireArrows[MAXPLAYERS+1] = false;
new bool:pFrogToggled[MAXPLAYERS+1] = false;
new bool:pGoldWeapons[MAXPLAYERS+1] = false;
new bool:pDonorTauntSprites[MAXPLAYERS+1] = false;

new Handle:g_hGoldenItem = INVALID_HANDLE;

new g_EntList[MAXPLAYERS + 1];
new bool:g_HasSprite[MAXPLAYERS+1];
new gVelocityOffset;

new Handle:g_hPref_glow;
new Handle:g_hPref_firearrows;
new Handle:g_hPref_froggy;
new Handle:g_hPref_golden;
new Handle:g_hPref_donorsprite;

new g_iColorsSkins[22][4] = 
{
	{255, 255, 255, 255}, 
	{0, 0, 0, 192},
	{0, 255, 0, 192},
	{255, 255, 0, 192}, 
	{255, 0, 255, 192}, 
	{0, 255, 255, 192}, 
	{255, 128, 0, 192}, 
	{255, 0, 128, 192}, 
	{128, 255, 0, 192}, 
	{0, 255, 128, 192}, 
	{128, 0, 255, 192}, 
	{192, 192, 192, 255}, 
	{210, 105, 30, 255}, 
	{139, 69, 19, 255}, 
	{75, 0, 130, 255}, 
	{248, 248, 255, 255}, 
	{216, 191, 216, 255}, 
	{240, 248, 255, 255}, 
	{70, 130, 180, 255}, 
	{0, 128, 128, 255},    
	{255, 215, 0, 255}, 
	{210, 180, 140, 255}
};

new g_iColorsHats[22][4] = 
{
	{255, 255, 255, 255}, 
	{0, 0, 0, 255},
	{0, 255, 0, 255},
	{255, 255, 0, 255}, 
	{255, 0, 255, 255}, 
	{0, 255, 255, 255}, 
	{255, 128, 0, 255}, 
	{255, 0, 128, 255}, 
	{128, 255, 0, 255}, 
	{0, 255, 128, 255}, 
	{128, 0, 255, 255}, 
	{192, 192, 192, 255}, 
	{210, 105, 30, 255}, 
	{139, 69, 19, 255}, 
	{75, 0, 130, 255}, 
	{248, 248, 255, 255}, 
	{216, 191, 216, 255}, 
	{240, 248, 255, 255}, 
	{70, 130, 180, 255}, 
	{0, 128, 128, 255},    
	{255, 215, 0, 255}, 
	{210, 180, 140, 255}
};

new String:g_strColorNames[22][] =
{
	"normal",
	"black",
	"green",
	"yellow",
	"purple",
	"cyan",
	"orange",
	"pink",
	"olive",
	"lime",
	"violet",
	"silver",
	"chocolate",
	"saddlebrown",
	"indigo",
	"ghostwhite",
	"thistle",
	"aliceblue",
	"steelblue",
	"teal",
	"gold",
	"tan"
};

new Float:FootprintID[MAXPLAYERS+1] = 0.0;
new bool:bRandomFootprints[MAXPLAYERS + 1];

new bool:e_FF2;

new bool:bLiveRound = false;
new iModelID[MAXPLAYERS + 1] = 0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	File_LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_changeclass", ChangeClass, EventHookMode_Pre);
	HookEvent("player_death", Player_Death);
	HookEvent("arena_round_start", ArenaRoundStart);
	HookEvent("teamplay_round_win", RoundEnd);
	
	RegConsoleCmd("sm_vip", VIPMenu);
	RegConsoleCmd("sm_resizemenu", ResizeMenu);
	RegAdminCmd("sm_taunts", TauntsMenu, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_glow", GlowPlayer, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_firearrows", FireArrows, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_froggy", FroggyDeath, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_weaponsize", WeaponSizeMenu, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_setstreak", SetKillStreak, ADMFLAG_CUSTOM1);
	RegConsoleCmd("sm_bhop", BunnyHop);
	RegAdminCmd("sm_golden", GoldenRagdolls, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_donorsprite", DonorSprite, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_skincolor", SkinColors, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_hatcolor", HatColors, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_givesaxxy", GiveSaxxy, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_footprints", FootPrints, ADMFLAG_RESERVATION);
	
	RegAdminCmd("sm_setws", SetWeaponSize, ADMFLAG_ROOT);
	
	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");
	
	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	g_hGoldenItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetNumAttributes(g_hGoldenItem, 1);
	TF2Items_SetAttribute(g_hGoldenItem, 0, 150, 1.0);
	
	g_hPref_glow = RegClientCookie("VIPPerk_Glow", "Does you want glow?", CookieAccess_Private);
	g_hPref_firearrows = RegClientCookie("VIPPerk_FireArrows", "Does you want fire arrows?", CookieAccess_Private);
	g_hPref_froggy = RegClientCookie("VIPPerk_Froggy", "Does you want to turn players into frogs?", CookieAccess_Private);
	g_hPref_golden = RegClientCookie("VIPPerk_Golden", "Does you want to turn players into golden statues?", CookieAccess_Private);
	g_hPref_donorsprite = RegClientCookie("VIPPerk_DonorSprite", "Does you want to taunt and have a sprite appear over your head?", CookieAccess_Private);
}

public OnAllPluginsLoaded()
{
	e_FF2 = LibraryExists("freak_fortress_2");
}

public OnLibraryAdded(const String:name[])
{
	e_FF2 = StrEqual(name, "freak_fortress_2", false);
}

public OnLibraryRemoved(const String:name[])
{
	e_FF2 = StrEqual(name, "freak_fortress_2", false);
}

public OnConfigsExecuted()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
			
			if (!AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
		g_bLateLoad = false;
	}
}

public OnMapStart()
{
	PrecacheModel("models/props_2fort/frog.mdl", true);
	PrecacheModel("models/props_junk/wood_crate001a.mdl", true);
	
	PrecacheGeneric("materials/custom/donator.vmt", true);
	AddFileToDownloadsTable("materials/custom/donator.vmt");
	PrecacheGeneric("materials/custom/donator.vtf", true);
	AddFileToDownloadsTable("materials/custom/donator.vtf");
	
	PrecacheModel("models/custom/taunts/medic_popit/medic.mdl", true);
	PrecacheModel("models/custom/taunts/medic_popit/medic_hi5.mdl", true);
	PrecacheModel("models/custom/taunts/medic_popit/heavy.mdl", true);
	PrecacheModel("models/custom/taunts/medic_popit/heavy_hi5.mdl", true);
	PrecacheModel("models/custom/taunts/medic_popit/spy.mdl", true);
	
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.dx80.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.dx90.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.phy");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.sw.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy.vvd");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.dx80.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.dx90.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.phy");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.sw.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/heavy_hi5.vvd");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/meavy_animat_hi5.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/meavy_animations.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.dx80.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.dx90.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.phy");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.sw.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic.vvd");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.dx80.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.dx90.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.phy");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.sw.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/medic_hi5.vvd");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/mydic_animat_hi5.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/mydic_animations.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.dx80.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.dx90.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.mdl");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.phy");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.sw.vtx");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/spy.vvd");
	AddFileToDownloadsTable("models/custom/taunts/medic_popit/smy_animations.mdl");
}

public OnClientPutInServer(client)
{
	if (IsClientInGame(client))
	{
		pGlow[client] = false;
		pFireArrows[client] = false;
		pFrogToggled[client] = false;
		pGoldWeapons[client] = false;
		pDonorTauntSprites[client] = false;
		bRandomFootprints[client] = false;
		SDKHook(client, SDKHook_PostThink, OnPostThink);
		
		iModelID[client] = 0;
	}
}

public OnPostThink(client)
{
	if (bRandomFootprints[client])
	{
		switch(GetRandomInt(0,16))
		{
		case 0: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 1.0);
		case 1: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 7777.0);
		case 2: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 933333.0);
		case 3: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8421376.0);
		case 4: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 4552221.0);
		case 5: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3100495.0);
		case 6: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 51234123.0);
		case 7: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 5322826.0);
		case 8: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8355220.0);
		case 9: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 13595446.0);
		case 10: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8208497.0);
		case 11: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 41234123.0);
		case 12: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 300000.0);
		case 13: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 2.0);
		case 14: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3.0);
		case 15: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 83552.0);
		case 16: TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 9335510.0);
		}
	}
}

public OnClientCookiesCached(client)
{
	if (IsClientInGame(client))
	{
		decl String:value[8];

		GetClientCookie(client, g_hPref_glow, value, sizeof(value));
		if (IsVIP(client, true))
		{
			pGlow[client] = (value[0] != '\0' && StringToInt(value));
		}
		else
		{
			pGlow[client] = false;
		}
		
		if(StrEqual(value, ""))
		{
			SetClientCookie(client, g_hPref_glow, "0");
		}
		
		GetClientCookie(client, g_hPref_firearrows, value, sizeof(value));
		if (IsVIP(client, true))
		{
			pFireArrows[client] = (value[0] != '\0' && StringToInt(value));
		}
		else
		{
			pFireArrows[client] = false;
		}
		
		if(StrEqual(value, ""))
		{
			SetClientCookie(client, g_hPref_firearrows, "0");
		}
		
		GetClientCookie(client, g_hPref_froggy, value, sizeof(value));
		if (IsVIP(client))
		{
			pFrogToggled[client] = (value[0] != '\0' && StringToInt(value));
		}
		else
		{
			pFrogToggled[client] = false;
		}
		
		if(StrEqual(value, ""))
		{
			SetClientCookie(client, g_hPref_froggy, "0");
		}
		
		GetClientCookie(client, g_hPref_golden, value, sizeof(value));
		if (IsVIP(client, true))
		{
			pGoldWeapons[client] = (value[0] != '\0' && StringToInt(value));
		}
		else
		{
			pGoldWeapons[client] = false;
		}
		
		if(StrEqual(value, ""))
		{
			SetClientCookie(client, g_hPref_golden, "0");
		}
		
		GetClientCookie(client, g_hPref_donorsprite, value, sizeof(value));
		if (IsVIP(client))
		{
			pDonorTauntSprites[client] = (value[0] != '\0' && StringToInt(value));
		}
		else
		{
			pDonorTauntSprites[client] = false;
		}
		
		if(StrEqual(value, ""))
		{
			SetClientCookie(client, g_hPref_donorsprite, "0");
		}
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		pGlow[client] = false;
		pFireArrows[client] = false;
		pFrogToggled[client] = false;
		pGoldWeapons[client] = false;
		pDonorTauntSprites[client] = false;
		
		if (FC_BhopStatus(client))
		{
			FC_SetBhop(client, false, false, 1.0, 1.0);
		}
		
		FootprintID[client] = 0.0;
		iModelID[client] = 0;
	}
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client))
	{
		if (pGlow[client])
		{
			Glow(client);
		}
		
		if (FootprintID[client] > 0.0)
		{
			TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
		}
		
		if (!bLiveRound)
		{
			EquipModelViaStruct(client);
		}
	}
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_HasSprite[client])
	{
		KillSprite(client);
		g_HasSprite[client] = false;
	}
	if (!bLiveRound)
	{
		EquipModelViaStruct(client);
	}
	return Plugin_Continue;
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damagetype = GetEventInt(event, "damagebits");
	
	if (IsClientInGame(client) && IsClientInGame(killer) && (damagetype & DMG_ACID))
	{
		new weapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		
		if (!IsValidEntity(weapon)) return;

		switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
		case 38, 142, 416, 457, 813, 834, 1000: return;
		}
		
		if (pFrogToggled[killer])
		{
			RequestFrame(RemoveRagdoll, GetClientUserId(client));
			
			new Float:Pos[3], Float:Ang[3];
			GetClientEyePosition(client, Pos);
			GetClientAbsAngles(client, Ang);
			
			TE_Start("breakmodel");
			TE_WriteNum("m_nModelIndex", PrecacheModel("models/props_2fort/frog.mdl"));
			TE_WriteFloat("m_fTime", 10.0);
			TE_WriteVector("m_vecOrigin", Pos);
			TE_WriteFloat("m_angRotation[0]", Ang[0]);
			TE_WriteFloat("m_angRotation[1]", Ang[1]);
			TE_WriteFloat("m_angRotation[2]", Ang[2]);
			TE_WriteVector("m_vecSize", Float:{1.0, 1.0, 1.0});
			TE_WriteNum("m_nCount", 1);
			TE_SendToAll();
			
			CreateParticle("bday_confetti", 0.5, client, ATTACH_NORMAL);
		}
	}
	
	EquipModelViaStruct(client, false);
	
	if (g_HasSprite[client])
	{
		KillSprite(client);
		g_HasSprite[client] = false;
	}
}


public Action:ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bLiveRound = true;
}

public Action:RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	bLiveRound = false;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (pFireArrows[client] && IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 56)
		{ 
			SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1);
		} 
	}
}

public Action:TauntCmd(client, const String:strCommand[], args)
{
	if (!g_HasSprite[client] && IsPlayerAlive(client) && GetEntityFlags(client) & FL_ONGROUND)
	{
		if (pDonorTauntSprites[client])
		{
			CreateSprite(client, "materials/custom/donator.vmt", 25.0);
			g_HasSprite[client] = true;
			CreateTimer(3.5, RemoveSprite, client);
		}
	}
}

/******************************************************/
//Menus

public Action:VIPMenu(client, args)
{
	BuildVIPMenu(client);
	return Plugin_Handled;
}

public Action:ResizeMenu(client, args)
{
	if (!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(mH_ResizeMenu);
		SetMenuTitle(menu, "Resize Commands:");
		
		AddMenuItem(menu, "Self", "Resize Self");
		AddMenuItem(menu, "Head", "Resize Head");
		AddMenuItem(menu, "Torso", "Resize Torso");
		AddMenuItem(menu, "Hands", "Resize Hands");
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	return Plugin_Handled;
}

public mH_ResizeMenu(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			
			if (StrEqual(info, "Self"))
			{
				FakeClientCommandEx(client, "say !resize");
			}
			else if (StrEqual(info, "Head"))
			{
				FakeClientCommandEx(client, "say !resizehead");
			}
			else if (StrEqual(info, "Torso"))
			{
				FakeClientCommandEx(client, "say !resizetorso");
			}
			else if (StrEqual(info, "Hands"))
			{
				FakeClientCommandEx(client, "say !resizehands");
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:TauntsMenu(client, args)
{
	if(IsVoteInProgress()) return Plugin_Handled;

	new Handle:menu = CreateMenu(TauntsMenu_Handle);
	SetMenuTitle(menu, "VIP Taunts:");
	
	AddMenuItem(menu, "1", "Default");
	AddMenuItem(menu, "2", "[Medic] Pop It (Meet the Medic)");
	AddMenuItem(menu, "3", "[Medic] Pop It (High Five)");
	AddMenuItem(menu, "4", "[Heavy] Crotch Chop (Schadenfreude)");
	AddMenuItem(menu, "5", "[Heavy] Crotch Chop (High Five)");
	AddMenuItem(menu, "6", "[Spy] Spy Shuffle (Schadenfreude)");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	return Plugin_Handled;
}

public TauntsMenu_Handle(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
					{
						iModelID[client] = 0;
						RemoveModel(client);
					}
				case 1:
					{
						iModelID[client] = 1;
						if (!bLiveRound)
						{
							TF2_SetPlayerClass(client, TFClass_Medic);
							SetModel(client, "models/custom/taunts/medic_popit/medic.mdl");
						}
					}
				case 2:
					{
						iModelID[client] = 2;
						if (!bLiveRound)
						{
							TF2_SetPlayerClass(client, TFClass_Medic);
							SetModel(client, "models/custom/taunts/medic_popit/medic_hi5.mdl");
						}
					}
				case 3:
					{
						iModelID[client] = 3;
						if (!bLiveRound)
						{
							TF2_SetPlayerClass(client, TFClass_Heavy);
							SetModel(client, "models/custom/taunts/medic_popit/heavy.mdl");
						}
					}
				case 4:
					{
						iModelID[client] = 4;
						if (!bLiveRound)
						{
							TF2_SetPlayerClass(client, TFClass_Heavy);
							SetModel(client, "models/custom/taunts/medic_popit/heavy_hi5.mdl");
						}
					}
				case 5:
					{
						iModelID[client] = 5;
						if (!bLiveRound)
						{
							TF2_SetPlayerClass(client, TFClass_Spy);
							SetModel(client, "models/custom/taunts/medic_popit/spy.mdl");
						}
					}
			}
			if (bLiveRound)	PrintToChat(client, "You will be set to this model next respawn.");
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:FroggyDeath(client, args)
{
	if (IsClientInGame(client))
	{
		if (!pFrogToggled[client])
		{
			pFrogToggled[client] = true;
			SetClientCookie(client, g_hPref_froggy, "1");
			CPrintToChatAll("%s %N{default} has toggled Froggy Death. HE TURNS PEOPLE INTO FROGS!", VIP, client);
		}
		else
		{
			pFrogToggled[client] = false;
			SetClientCookie(client, g_hPref_froggy, "0");
			CPrintToChat(client, "%s You no longer turn players into frogs.", VIP);
		}
	}
	return Plugin_Handled;
}

public Action:GlowPlayer(client, args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (!pGlow[client])
		{
			Glow(client);
			SetClientCookie(client, g_hPref_glow, "1");
			CPrintToChatAll("%s %N{default} has given themself a glow.", VIPPLUS, client);
		}
		else
		{
			pGlow[client] = false;
			SetClientCookie(client, g_hPref_glow, "0");
			CPrintToChat(client, "%s Your glow will be removed on death or end round.", VIPPLUS);
		}
	}
	return Plugin_Handled;
}

public Action:FireArrows(client, args)
{
	if (IsClientInGame(client))
	{
		if (!pFireArrows[client])
		{
			pFireArrows[client] = true;
			SetClientCookie(client, g_hPref_firearrows, "1");
			CPrintToChatAll("%s %N{default} has toggled fire arrows.", VIPPLUS, client);
		}
		else
		{
			pFireArrows[client] = false;
			SetClientCookie(client, g_hPref_firearrows, "0");
			CPrintToChat(client, "%s You will no longer shoot fire arrows.", VIPPLUS);
		}
	}
	return Plugin_Handled;
}

public Action:WeaponSizeMenu(client, args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%s You must be alive to use this command", VIP);
		return Plugin_Handled;
	}
	
	if (!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(MenuHandle);
		SetMenuTitle(menu, "Set Weapon Size:");
		AddMenuItem(menu, "", "WARNING: Some weapons don't work.", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "---", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "1.0", "Normal");
		AddMenuItem(menu, "2.0", "Large");
		
		decl String:sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Extra Large" : "Extra Large (+)");
		AddMenuItem(menu, "3.0", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);
	}	
	return Plugin_Handled;
}

public MenuHandle(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			
			new Float:fArg = StringToFloat(info);
			
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEntity(weapon))
			{
				CReplyToCommand(client, "%s Unable to find active weapon. Please equip an active weapon!", VIP);
				return;
			}
			
			SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", fArg);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:SetWeaponSize(client, args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));
		
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEntity(weapon))
		{
			CReplyToCommand(client, "%s Unable to find active weapon. Please equip an active weapon!", VIP);
			return Plugin_Handled;
		}
		
		new Float:fArg = StringToFloat(arg1);
		SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", fArg);
	}
	return Plugin_Handled;
}

public Action:SetKillStreak(client, args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%s You must be alive to use this command", VIP);
		return Plugin_Handled;
	}
	
	if (!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(MenuHandle_KillStreaks);
		SetMenuTitle(menu, "Set KillStreak Amount:");
		AddMenuItem(menu, "25", "25 Kills");
		AddMenuItem(menu, "50", "50 Kills");
		AddMenuItem(menu, "75", "75 Kills");
		AddMenuItem(menu, "100", "100 Kills");
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);
	}	
	return Plugin_Handled;
}

public MenuHandle_KillStreaks(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			
			new iArg = StringToInt(info);
			
			SetEntProp(client, Prop_Send, "m_iKillStreak", iArg);
			CPrintToChat(client, "%s You have set your Killstreak to %i.", VIPPLUS, iArg);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:BunnyHop(client, args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (IsVIP(client, true))
	{
		if (!FC_BhopStatus(client))
		{
			FC_SetBhop(client, true, false, 1.06, 1.0);
			CPrintToChat(client, "%s BHOP has been enabled for VIP+.", VIPPLUS);
		}
		else
		{
			FC_SetBhop(client, false, false, 1.0, 1.0);
			CPrintToChat(client, "%s BHOP has been disabled.", VIPPLUS);
		}
	}
	else if (IsVIP(client))
	{
		if (!FC_BhopStatus(client))
		{
			FC_SetBhop(client, true, false, 1.04, 1.0);
			CPrintToChat(client, "%s BHOP has been enabled for VIP.", VIP);
		}
		else
		{
			FC_SetBhop(client, false, false, 1.0, 1.0);
			CPrintToChat(client, "%s BHOP has been disabled.", VIP);
		}
	}
	else
	{
		CPrintToChat(client, "%s You do not have access to this command.", VIP);
	}
	return Plugin_Handled;
}

public Action:GoldenRagdolls(client, args)
{
	if (IsClientInGame(client))
	{
		if (e_FF2 && FF2_GetBossIndex(client) != -1)
		{
			CPrintToChat(client, "%s You cannot enable golden rag dolls while as the boss.", VIPPLUS);
			return Plugin_Handled;
		}
		
		if (!pGoldWeapons[client])
		{
			pGoldWeapons[client] = true;
			SetClientCookie(client, g_hPref_golden, "1");
			CPrintToChatAll("%s %N{default} has toggled GOLDEN RAGDOLLS! Next time you receive weapons, you shall be equipped.", VIPPLUS, client);
		}
		else
		{
			pGoldWeapons[client] = false;
			SetClientCookie(client, g_hPref_golden, "0");
			CPrintToChat(client, "%s You will no longer turn players into GOLDEN RAGDOLLS!", VIPPLUS);
		}
	}
	return Plugin_Handled;
}

public Action:DonorSprite(client, args)
{
	if (IsClientInGame(client))
	{
		if (!pDonorTauntSprites[client])
		{
			pDonorTauntSprites[client] = true;
			SetClientCookie(client, g_hPref_donorsprite, "1");
			CPrintToChatAll("%s %N{default} has toggled Donor Sprites on taunts.", VIPPLUS, client);
		}
		else
		{
			pDonorTauntSprites[client] = false;
			SetClientCookie(client, g_hPref_donorsprite, "0");
			CPrintToChat(client, "%s You will no longer have a sprite over your head when you Taunt.", VIPPLUS);
		}
	}
	return Plugin_Handled;
}

public Action:SkinColors(client, args)
{
	if (IsClientInGame(client))
	{
		if (!IsPlayerAlive(client))
		{
			CReplyToCommand(client, "%t", "Target must be alive");
			return Plugin_Handled;
		}
		
		new Handle:menu = CreateMenu(MenuHandler_ColorizeSkin);
		
		SetMenuTitle(menu, "VIP Skin Colors");
		SetMenuExitBackButton(menu, true);
		
		decl String:num[8];
		for (new i = 0; i < sizeof(g_strColorNames); i++)
		{
			IntToString(i, num, sizeof(num));
			AddMenuItem(menu, num, g_strColorNames[i]);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public MenuHandler_ColorizeSkin(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:num[32];
			GetMenuItem(menu, param2, num, sizeof(num));
			new c = StringToInt(num);
			SetEntityRenderColor(param1, g_iColorsSkins[c][0], g_iColorsSkins[c][1], g_iColorsSkins[c][2], g_iColorsSkins[c][3]);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:HatColors(client, args)
{
	if (IsClientInGame(client))
	{
		if (!IsPlayerAlive(client))
		{
			CReplyToCommand(client, "%t", "Target must be alive");
			return Plugin_Handled;
		}
		
		new Handle:menu = CreateMenu(MenuHandler_ColorizeHat);
		
		SetMenuTitle(menu, "VIP Hat Colors");
		SetMenuExitBackButton(menu, true);
		
		decl String:num[8];
		for (new i = 0; i < sizeof(g_strColorNames); i++)
		{
			IntToString(i, num, sizeof(num));
			AddMenuItem(menu, num, g_strColorNames[i]);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public MenuHandler_ColorizeHat(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:num[32];
			GetMenuItem(menu, param2, num, sizeof(num));
			new c = StringToInt(num);
			
			new ent = -1;
			while ((ent = FindEntityByClassname( ent, "tf_wearable*")) != -1)
			{
				new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");

				if (owner == param1)
				{
					SetEntityRenderColor(ent, g_iColorsHats[c][0], g_iColorsHats[c][1], g_iColorsHats[c][2], g_iColorsHats[c][3]);
				}
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

public Action:GiveSaxxy(client, args)
{
	if (IsClientInGame(client))
	{
		if (!IsPlayerAlive(client))
		{
			CReplyToCommand(client, "%t", "Target must be alive");
			return Plugin_Handled;
		}
		
		TF2_RemoveWeaponSlot(client, 2);
		TF2Items_GiveWeapon(client, 423);
	}
	else
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action:FootPrints(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_FootSteps);
	SetMenuTitle(menu, "Footprint Effects:");

	AddMenuItem(menu, "0", "No Effect");
	AddMenuItem(menu, "X", "----------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "1", "Team Based");
	AddMenuItem(menu, "7777", "Blue");
	AddMenuItem(menu, "933333", "Light Blue");
	AddMenuItem(menu, "8421376", "Yellow");
	AddMenuItem(menu, "4552221", "Corrupted Green");
	AddMenuItem(menu, "3100495", "Dark Green");
	AddMenuItem(menu, "51234123", "Lime");
	AddMenuItem(menu, "5322826", "Brown");
	AddMenuItem(menu, "8355220", "Oak Tree Brown");
	AddMenuItem(menu, "13595446", "Flames");
	AddMenuItem(menu, "8208497", "Cream");
	AddMenuItem(menu, "41234123", "Pink");
	AddMenuItem(menu, "300000", "Satan's Blue");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "4 8 15 16 23 42");
	AddMenuItem(menu, "83552", "Ghost In The Machine");
	AddMenuItem(menu, "9335510", "Holy Flame");
	AddMenuItem(menu, "Rainbow", "[Random] (VIP + Only)", (CheckCommandAccess(client, "random_footsteps", ADMFLAG_CUSTOM1 , true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_FootSteps(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:info[12];
			GetMenuItem(menu, item, info, sizeof(info));
			
			FootprintID[client] = StringToFloat(info);
			
			if (!StrEqual(info, "Rainbow"))
			{
				if (FootprintID[client] == 0.0)
				{
					TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
				}
				else
				{
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
				}
			}
			else
			{
				if (!bRandomFootprints[client])
				{
					bRandomFootprints[client] = true;
				}
				else
				{
					bRandomFootprints[client] = false;
				}
			}
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

BuildVIPMenu(client)
{
	if (!Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
	{
		CPrintToChat(client, "%s You do not have access to this menu.", VIP);
		return;
	}
	
	if (!IsVoteInProgress())
	{
		new Handle:menu = CreateMenu(mH_VIPMenu);
		SetMenuTitle(menu, "Available Commands:");
		
		decl String:sBuffer[32];
		
		AddMenuItem(menu, "Froggy", "Froggy");
		
		AddMenuItem(menu, "TauntSpeed", "TauntSpeed");
		
		AddMenuItem(menu, "WeaponSizes", "Weapon Sizes");
		
		AddMenuItem(menu, "RocketYourself", "Rocket Yourself");
		
		AddMenuItem(menu, "DSPEffects", "Convert your Voice");
		
		AddMenuItem(menu, "BuildingColors", "Building Colors");
		
		AddMenuItem(menu, "DonorSprites", "Toggle Donor Sprites");
		
		AddMenuItem(menu, "SkinColors", "Skin Colors");
		
		AddMenuItem(menu, "DoTheThriller", "Do The Thriller!!!");
		
		AddMenuItem(menu, "Footprints", "Set Footprints");
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Hat Colors" : "Hat Colors (+)");
		AddMenuItem(menu, "HatColors", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Custom Taunts" : "Custom Taunts (+)");
		AddMenuItem(menu, "CustomTaunts", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Fire Arrows" : "Fire Arrows (+)");
		AddMenuItem(menu, "FireArrows", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Glow" : "Glow (+)");
		AddMenuItem(menu, "Glow", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "KillStreaks" : "KillStreaks (+)");
		AddMenuItem(menu, "KillStreaks", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "BunnyHop" : "BunnyHop (+)");
		AddMenuItem(menu, "BunnyHop", sBuffer, ITEMDRAW_DEFAULT);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Golden Ragdolls" : "Golden Ragdolls (+)");
		AddMenuItem(menu, "GoldenRagdolls", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		Format(sBuffer, sizeof(sBuffer), "%s", IsPlus(client) ? "Give Saxxy" : "Give Saxxy (+)");
		AddMenuItem(menu, "GiveSaxxy", sBuffer, IsPlus(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
}

public mH_VIPMenu(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			
			if (StrEqual(info, "Froggy"))
			{
				FakeClientCommandEx(client, "say !froggy");
			}
			else if (StrEqual(info, "TauntSpeed"))
			{
				FakeClientCommandEx(client, "say !tauntspeed");
			}
			else if (StrEqual(info, "WeaponSizes"))
			{
				FakeClientCommandEx(client, "say !weaponsize");
			}
			else if (StrEqual(info, "RocketYourself"))
			{
				FakeClientCommandEx(client, "say !rocket");
			}
			else if (StrEqual(info, "FireArrows"))
			{
				FakeClientCommandEx(client, "say !firearrows");
			}
			else if (StrEqual(info, "Glow"))
			{
				FakeClientCommandEx(client, "say !glow");
			}
			else if (StrEqual(info, "Footprints"))
			{
				FakeClientCommandEx(client, "say !footprints");
			}
			else if (StrEqual(info, "KillStreaks"))
			{
				FakeClientCommandEx(client, "say !setstreak");
			}
			else if (StrEqual(info, "BunnyHop"))
			{
				FakeClientCommandEx(client, "say !bhop");
			}
			else if (StrEqual(info, "GoldenRagdolls"))
			{
				FakeClientCommandEx(client, "say !golden");
			}
			else if (StrEqual(info, "GiveSaxxy"))
			{
				FakeClientCommandEx(client, "say !givesaxxy");
			}
			else if (StrEqual(info, "DSPEffects"))
			{
				FakeClientCommandEx(client, "say !dsp");
			}
			else if (StrEqual(info, "BuildingColors"))
			{
				FakeClientCommandEx(client, "say !buildingcolors");
			}
			else if (StrEqual(info, "DonorSprites"))
			{
				FakeClientCommandEx(client, "say !donorsprite");
			}
			else if (StrEqual(info, "SkinColors"))
			{
				FakeClientCommandEx(client, "say !skincolor");
			}
			else if (StrEqual(info, "HatColors"))
			{
				FakeClientCommandEx(client, "say !hatcolor");
			}
			else if (StrEqual(info, "DoTheThriller"))
			{
				FakeClientCommandEx(client, "say !thriller");
			}
			else if (StrEqual(info, "CustomTaunts"))
			{
				FakeClientCommandEx(client, "say !taunts");
			}
			BuildVIPMenu(client);
		}
	case MenuAction_End: CloseHandle(menu);
	}
}

/******************************************************/
//Functions

Glow(client)
{
	pGlow[client] = true;
	CreateTimer(5.0, CheckPlayerStatus, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CheckPlayerStatus(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	if (IsClientInGame(client))
	{
		if (!IsPlayerAlive(client))
		{
			pGlow[client] = false;
			return Plugin_Stop;
		}
		
		CreateParticle("player_recent_teleport_blue", 5.0, client, ATTACH_NORMAL);
		CreateParticle("player_recent_teleport_red", 1.0, client, ATTACH_NORMAL);
		CreateParticle("critical_grenade_blue", 5.0, client, ATTACH_NORMAL);
		CreateParticle("critical_grenade_red", 5.0, client, ATTACH_NORMAL);
	}
	else
	{
		pGlow[client] = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public RemoveRagdoll(any:data)
{
	new client = GetClientOfUserId(data);
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (ragdoll > MaxClients)
	{
		AcceptEntityInput(ragdoll, "Kill");
	}
}

bool:IsPlus(client)
{
	return Client_HasAdminFlags(client, ADMFLAG_CUSTOM1);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if (pGoldWeapons[client])
	{
		hItem = g_hGoldenItem;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnGameFrame()
{
	new ent, Float:vOrigin[3], Float:vVelocity[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if ((ent = g_EntList[i]) > 0)
		{
			if (!IsValidEntity(ent))
			g_EntList[i] = 0;
			else
			if ((ent = EntRefToEntIndex(ent)) > 0)
			{
				GetClientEyePosition(i, vOrigin);
				vOrigin[2] += 25.0;
				GetEntDataVector(i, gVelocityOffset, vVelocity);
				TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
			}
		}
	}
}

public Action:RemoveSprite(Handle:hTimer, any:client)
{
	if (g_HasSprite[client] && IsClientInGame(client))
	{
		KillSprite(client);
		g_HasSprite[client] = false;
	}
	return Plugin_Continue;
}

CreateSprite(iClient, String:sprite[], Float:offset)
{
	new String:szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);

	new Float:vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchKeyValue(ent, "parentname", szTemp);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		g_EntList[iClient] = ent;
	}
}

KillSprite(iClient)
{
	if (g_EntList[iClient] > 0 && IsValidEntity(g_EntList[iClient]))
	{
		AcceptEntityInput(g_EntList[iClient], "kill");
		g_EntList[iClient] = 0;
	}
}

IsVIP(client, bool:plus = false)
{
	if (plus) return CheckCommandAccess(client, "VIPPlus", ADMFLAG_CUSTOM1);
	return CheckCommandAccess(client, "VIP", ADMFLAG_RESERVATION);
}


EquipModelViaStruct(client, bool:add = true)
{
	if (add)
	{
		switch (iModelID[client])
		{
			case 1:
				{
					TF2_SetPlayerClass(client, TFClass_Medic);
					SetModel(client, "models/custom/taunts/medic_popit/medic.mdl");
				}
			case 2:
				{
					TF2_SetPlayerClass(client, TFClass_Medic);
					SetModel(client, "models/custom/taunts/medic_popit/medic_hi5.mdl");
				}
			case 3:
				{
					TF2_SetPlayerClass(client, TFClass_Heavy);
					SetModel(client, "models/custom/taunts/medic_popit/heavy.mdl");
				}
			case 4:
				{
					TF2_SetPlayerClass(client, TFClass_Heavy);
					SetModel(client, "models/custom/taunts/medic_popit/heavy_hi5.mdl");
				}
			case 5:
				{
					TF2_SetPlayerClass(client, TFClass_Spy);
					SetModel(client, "models/custom/taunts/medic_popit/spy.mdl");
				}
		}
	}
	else
	{
		RemoveModel(client);
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		SetEntityHealth(client, 25);
		TF2_RegeneratePlayer(client);
	}
}

public Action:RemoveModel(client)
{
	if (IsPlayerAlive(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEntity(particle))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		if (attach != NO_ATTACH)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
			if (attach == ATTACH_HEAD)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		if (time != 0.0)
		{
			CreateTimer(time, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		LogError("Error creating 'info_particle_system'. [%s]", type);
	}
}

public Action:DeleteParticle(Handle:timer, any:Edict)
{	
	if (IsValidEdict(Edict))
	{
		RemoveEdict(Edict);
	}
}
/******************************************************/