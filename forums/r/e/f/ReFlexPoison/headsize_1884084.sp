#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <tf2items>
#include <tf2itemsinfo>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION			"1.0.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarMaxSize;
new Handle:cvarHeadInterval;
new Handle:g_hCookieHeadSize;

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new Float:g_fMaxSize;
new Float:g_fSizeInterval;
new bool:g_bLoadoutChanged		[MAXPLAYERS + 1];
new Float:g_fHeadSize			[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Head Size (TF2Items)",
	author = "ReFlexPoison",
	description = "Change your head size via menu",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_headsize_version", PLUGIN_VERSION, "Head Size Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_headsize_enabled", "1", "Enable Head Size\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(cvarEnabled);

	cvarMaxSize = CreateConVar("sm_headsize_maxsize", "2.0", "Set max head size setting", FCVAR_PLUGIN, true, 1.0);
	g_fMaxSize = GetConVarFloat(cvarMaxSize);

	cvarHeadInterval = CreateConVar("sm_headsize_interval", "0.25", "Interval between settings in head size menu", FCVAR_PLUGIN, true, 0.25);
	g_fSizeInterval = GetConVarFloat(cvarHeadInterval);

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarMaxSize, CVarChange);
	HookConVarChange(cvarHeadInterval, CVarChange);

	RegAdminCmd("sm_headsize", HeadSizeCmd, ADMFLAG_GENERIC, "Open Head Size Menu");

	HookEvent("player_death", OnPlayerDeath);

	g_hCookieHeadSize = RegClientCookie("headsize", "", CookieAccess_Private);
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarMaxSize)
		g_fMaxSize = GetConVarFloat(cvarMaxSize);
	if(hConvar == cvarHeadInterval)
		g_fSizeInterval = GetConVarFloat(cvarHeadInterval);
}

// ====[ EVENTS ]==============================================================
public OnClientCookiesCached(iClient)
{
	decl String:strCookie[32];
	GetClientCookie(iClient, g_hCookieHeadSize, strCookie, sizeof(strCookie));
	g_fHeadSize[iClient] = StringToFloat(strCookie);
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:strClassname[], iIndex, &Handle:hItem)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	if(!IsValidClient(iClient) || !CheckCommandAccess(iClient, "sm_headsize", ADMFLAG_GENERIC) || g_fHeadSize[iClient] == 0.0 || g_fHeadSize[iClient] == 1.0)
		return Plugin_Continue;

	decl String:strSlot[32];
	TF2II_GetItemSlotName(iIndex, strSlot, sizeof(strSlot));
	if(StrEqual(strSlot, "head"))
	{
		decl String:strAtts[32];
		Format(strAtts, sizeof(strAtts), "444 ; %f", g_fHeadSize[iClient]);

		new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, _, strAtts);
		if(hItemOverride != INVALID_HANDLE)
		{
			hItem = hItemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(g_bLoadoutChanged[iClient])
	{
		TF2II_RemoveItemSlot(iClient, TF2ItemSlot_Hat);
		g_bLoadoutChanged[iClient] = false;
	}
	return Plugin_Continue;
}

// ====[ COMMANDS | MENUS ]====================================================
public Action:HeadSizeCmd(iClient, iArgs)
{
	if(!IsValidClient(iClient) || !g_bEnabled)
		return Plugin_Continue;

	new Handle:hMenu = CreateMenu(HeadSizeH);
	SetMenuTitle(hMenu, "Head Size:");
	AddMenuItem(hMenu, "1.0", "Normal");
	for(new Float:f; f <= g_fMaxSize; f += g_fSizeInterval)
	{
		if(f != 0.0 && f != 1.0)
		{
			decl String:strFloat[32];
			FloatToString(f, strFloat, sizeof(strFloat));
			AddMenuItem(hMenu, strFloat, strFloat);
		}
	}
	return Plugin_Handled;
}

public HeadSizeH(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);

	if(!IsValidClient(iParam1))
		return;

	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[32];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		SetClientCookie(iParam1, g_hCookieHeadSize, strInfo);
		g_fHeadSize[iParam1] = StringToFloat(strInfo);

		g_bLoadoutChanged[iParam1] = true;
		PrintToChat(iParam1, "\x01[SM] You have set your head size to \x05%f\x01.", g_fHeadSize[iParam1]);
	}
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsValidEnt(iEntity)
{
	if(iEntity <= MaxClients || !IsValidEntity(iEntity))
		return false;
	return true;
}

stock TF2II_RemoveItemSlot(iClient, TF2ItemSlot:iSlot)
{
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
	{
		if(IsValidEnt(iEntity))
		{
			if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient && _:TF2II_GetItemSlot(GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex")) == _:iSlot)
				AcceptEntityInput(iEntity, "Kill");
		}
	}
}

stock Handle:PrepareItemHandle(Handle:hItem, String:strName[] = "", iIndex = -1, iQuality = -1, const String:strAtts[] = "", bool:bPreserve = true)
{
	static Handle:hWeapon;
	new iAddAtts;

	new String:strAtts2[32][32];
	new iAttsCount = ExplodeString(strAtts, " ; ", strAtts2, 32, 32);

	new iFlags = OVERRIDE_ATTRIBUTES;
	if(bPreserve)
		iFlags |= PRESERVE_ATTRIBUTES;

	if(hWeapon == INVALID_HANDLE)
		hWeapon = TF2Items_CreateItem(iFlags);
	else
		TF2Items_SetFlags(hWeapon, iFlags);

	if(hItem != INVALID_HANDLE)
	{
		iAddAtts = TF2Items_GetNumAttributes(hItem);
		if(iAddAtts > 0)
		{
			for(new i = 0; i < 2 * iAddAtts; i += 2)
			{
				new bool:bDontAdd;
				new iAttIndex = TF2Items_GetAttributeId(hItem, i);
				for(new z = 0; z < iAttsCount + i; z += 2)
				{
					if(StringToInt(strAtts2[z]) == iAttIndex)
					{
						bDontAdd = true;
						break;
					}
				}
				if(!bDontAdd)
				{
					IntToString(iAttIndex, strAtts2[i + iAttsCount], 32);
					FloatToString(TF2Items_GetAttributeValue(hItem, i), strAtts2[i + 1 + iAttsCount], 32);
				}
			}
			iAttsCount += 2 * iAddAtts;
		}
		CloseHandle(hItem);
	}

	if(strName[0] != '\0')
	{
		iFlags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, strName);
	}
	if(iIndex != -1)
	{
		iFlags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, iIndex);
	}
	if(iQuality != -1)
	{
		iFlags |= OVERRIDE_ITEM_QUALITY;
		TF2Items_SetQuality(hWeapon, iQuality);
	}
	if(iAttsCount > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, (iAttsCount / 2));
		new z;
		for(new i = 0; i < iAttsCount && i < 32; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, z, StringToInt(strAtts2[i]), StringToFloat(strAtts2[i + 1]));
			z++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	TF2Items_SetFlags(hWeapon, iFlags);
	return hWeapon;
}