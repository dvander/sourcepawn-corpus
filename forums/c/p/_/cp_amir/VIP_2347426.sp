public PlVers:__version =
{
	version = 5,
	filevers = "1.4.7",
	date = "03/21/2013",
	time = "05:35:32"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_cstrike =
{
	name = "cstrike",
	file = "games/game.cstrike.ext",
	autoload = 0,
	required = 1,
};
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public SharedPlugin:__pl_vip =
{
	name = "VipBuild_001",
	file = "vip.smx",
	required = 1,
};
public Extension:__ext_smsock =
{
	name = "Socket",
	file = "socket.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "sdkhooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 0,
};
public Extension:__ext_topmenus =
{
	name = "TopMenus",
	file = "topmenus.ext",
	autoload = 1,
	required = 0,
};
public SharedPlugin:__pl_adminmenu =
{
	name = "adminmenu",
	file = "adminmenu.smx",
	required = 0,
};
public Plugin:myinfo =
{
	name = "Very Important Person [rc2]",
	description = "Very Important Person [SourceMod]",
	author = "GoDtm666",
	version = "beta_0.0.5",
	url = "www.SourceTM.com"
};
new GameType:g_iGame;
new String:g_sUsersPath[3][256];
new String:g_sSettings[256];
new String:g_sAdminsPath[3][256];
new String:g_sUsersModelsPath[256];
new String:g_sTriggerChatPath[256];
new String:g_sDownloadsPath[256];
new String:g_sVipFlags[66][4][64];
new bool:g_bIsAdmin[66];
new bool:g_bMapsNoGiveWeapons;
new Handle:g_hKvUsers;
new Handle:g_hKvUsersGroups;
new Handle:g_hKvUsersSettings;
new Handle:g_hKvAdmins;
new Handle:g_hKvAdminsGroups;
new Handle:g_hKvUsersModels;
new Handle:g_hUsersExpiresTimer;
new Handle:g_hArrayUsersExpires;
new Handle:g_hUsersTrie;
new Handle:g_hUsersGroupsTrie;
new Handle:g_hAdminsTrie[3];
new Handle:g_hAdminFlagsTrie;
new Handle:g_hUsersFlagsTrie;
new Handle:g_hUsersDeleteTrie;
new Handle:g_hChatTrie;
new Handle:g_hWeaponTrie;
new Handle:g_hWeaponAmmoTrie;
new Handle:g_hModelsTrie[2];
new Handle:g_hUsersJoinCache;
new TopMenuObject:obj_vipcmds;
new Handle:g_hTopMenu;
new Handle:g_hTimerChat[66];
new Handle:g_hArrayModels[2];
new g_iUsersMenuPosition[66];
new String:g_sAdminProtected[128];
new g_iTarget[66];
new g_iTargetTime[66];
new Handle:g_hTimerRegeneration[66][2];
new Handle:g_hTimerMedic[66][2];
new Float:g_fRegenTime[4];
new String:g_sSoundHeartBeat[256];
new g_iRegenHP[2] =
{
	1, 35
};
new Handle:g_hKvSettings;
new String:g_sMap[64];
new g_iPlayerVip[66][19];
new bool:g_bUsersStatus[66][5];
new bool:g_bPlayerVip[66][19];
new String:g_sWeapon[66][13][64];
new bool:g_bReloadAmmo;
new String:g_sClientAuth[66][2][32];
new g_iClientAuth[66];
new bool:g_bPlayerVipEdit[66][19];
new bool:g_bIsDeMap;
new String:g_sLogPath[256];
new String:g_sUsersModels[66][2][256];
new bool:g_bUsersModels[66][2];
new String:g_sUsersClanTag[66][256];
new String:g_sUsersExpires[66][32];
new g_iCoutModels[2];
new bool:g_bModels[2];
new g_iAccountOffset = -1;
new g_iWeaponParentOffset = -1;
new g_iSpeedOffset = -1;
new g_iHealthOffset = -1;
new g_iWaterLevelOffset = -1;
new g_iFlashOffset[2] =
{
	-1, ...
};
new g_iNightVisionOffset = -1;
new g_iArmorOffset = -1;
new g_iDefuserOffset = -1;
new g_iSilencerOffset[4] =
{
	-1, ...
};
new g_iActiveWeaponOffset = -1;
new g_iClip1Offset = -1;
new g_iGrenadeThrowerOffset = -1;
new g_iArmsModelOffset = -1;
new g_iMaxClients;
new g_iClientTeam[66];
new bool:g_bPlayerAlive[66];
new bool:g_bWelcome[66];
new g_iMaxHealth = 115;
new g_iMaxSpeed = 10;
new g_iSetupBeam[2];
new bool:g_bSettingsChanged[66];
new bool:g_bSDKHooksLoaded;
new SocketStatus:EnumSocket;
new Handle:g_hSocketTimer;
new String:sSocketBuffer[2][256];
new bool:bReceive;
new Handle:g_hArrayList;
new g_iCountFile[2];
new bool:g_bJoinClass;
new bool:g_bFriendLyFire;
new Float:g_fIncreaseDamage = 1068289229;
new Float:g_fTeamKill[66][3];
new bool:g_bHeartBeat;
new bool:g_bClientWeaponEquip[66];
new bool:g_bBetaTest;
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:operator+(Float:,_:)(Float:oper1, oper2)
{
	return oper1 + float(oper2);
}

bool:operator!=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) != 0;
}

bool:operator!=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) != 0;
}

bool:operator<=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) <= 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength, bool:copyRemainder)
{
	new reloc_idx;
	new idx;
	new total;
	new var1;
	if (maxStrings < 1 || !split[0])
	{
		return 0;
	}
	while ((idx = SplitString(text[reloc_idx], split, buffers[total], maxStringLength)) != -1)
	{
		reloc_idx = idx + reloc_idx;
		total++;
		if (maxStrings == total)
		{
			if (copyRemainder)
			{
				strcopy(buffers[total + -1], maxStringLength, text[reloc_idx - idx]);
			}
			return total;
		}
	}
	total++;
	strcopy(buffers[total], maxStringLength, text[reloc_idx]);
	return total;
}

bool:WriteFileCell(Handle:hndl, data, size)
{
	new array[1];
	array[0] = data;
	return WriteFile(hndl, array, 1, size);
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

bool:GetEntityClassname(entity, String:clsname[], maxlength)
{
	return !!GetEntPropString(entity, PropType:1, "m_iClassname", clsname, maxlength, 0);
}

MoveType:GetEntityMoveType(entity)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_MoveType");
		}
		gotconfig = true;
	}
	return GetEntProp(entity, PropType:1, datamap, 4, 0);
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[1];
	clients[0] = client;
	new var1;
	if (entity == -2)
	{
		var1 = client;
	}
	else
	{
		var1 = entity;
	}
	entity = var1;
	EmitSound(clients, 1, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

AddFileToDownloadsTable(String:filename[])
{
	static table = -1;
	if (table == -1)
	{
		table = FindStringTable("downloadables");
	}
	new bool:save = LockStringTables(false);
	AddToStringTable(table, filename, "", -1);
	LockStringTables(save);
	return 0;
}

TE_WriteEncodedEnt(String:prop[], value)
{
	new encvalue = value & 4095 | 4096;
	return TE_WriteNum(prop, encvalue);
}

TE_SendToAll(Float:delay)
{
	new total;
	new clients[MaxClients];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			total++;
			clients[total] = i;
		}
		i++;
	}
	return TE_Send(clients, total, delay);
}

TE_SetupBeamPoints(Float:start[3], Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, Color[4], Speed)
{
	TE_Start("BeamPoints");
	TE_WriteVector("m_vecStartPoint", start);
	TE_WriteVector("m_vecEndPoint", end);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", StartFrame);
	TE_WriteNum("m_nFrameRate", FrameRate);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", EndWidth);
	TE_WriteFloat("m_fAmplitude", Amplitude);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	TE_WriteNum("m_nSpeed", Speed);
	TE_WriteNum("m_nFadeLength", FadeLength);
	return 0;
}

TE_SetupBeamFollow(EntIndex, ModelIndex, HaloIndex, Float:Life, Float:Width, Float:EndWidth, FadeLength, Color[4])
{
	TE_Start("BeamFollow");
	TE_WriteEncodedEnt("m_iEntIndex", EntIndex);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", EndWidth);
	TE_WriteNum("m_nFadeLength", FadeLength);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	return 0;
}

public __ext_sdkhooks_SetNTVOptional()
{
	MarkNativeAsOptional("SDKHook");
	MarkNativeAsOptional("SDKHookEx");
	MarkNativeAsOptional("SDKUnhook");
	MarkNativeAsOptional("SDKHooks_TakeDamage");
	MarkNativeAsOptional("SDKHooks_DropWeapon");
	return 0;
}

public __ext_topmenus_SetNTVOptional()
{
	MarkNativeAsOptional("CreateTopMenu");
	MarkNativeAsOptional("LoadTopMenuConfig");
	MarkNativeAsOptional("AddToTopMenu");
	MarkNativeAsOptional("RemoveFromTopMenu");
	MarkNativeAsOptional("DisplayTopMenu");
	MarkNativeAsOptional("FindTopMenuCategory");
	return 0;
}

public __pl_adminmenu_SetNTVOptional()
{
	MarkNativeAsOptional("GetAdminTopMenu");
	MarkNativeAsOptional("AddTargetsToMenu");
	MarkNativeAsOptional("AddTargetsToMenu2");
	return 0;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGame[64];
	BuildPath(PathType:0, g_sLogPath, 256, "logs/vip_log.log");
	CreateNative("Vip_Log", Native_Log);
	CreateNative("IsClientVip", Native_IsClientVip);
	CreateNative("IsClientVipStatus", Native_IsClientVipStatus);
	CreateNative("VipStatus_AddPlugin", Native_StatusAddPlugin);
	CreateNative("VipPrint", Native_VipPrint);
	CreateNative("VipPrintError", Native_VipPrintError);
	GetGameFolderName(sGame, 64);
	if (StrEqual(sGame, "cstrike", false))
	{
		if (GuessSDKVersion() < 34)
		{
			MarkNativeAsOptional("CS_GetClientClanTag");
			MarkNativeAsOptional("CS_SetClientClanTag");
			g_iGame = MissingTAG:2;
		}
		else
		{
			g_iGame = MissingTAG:1;
		}
		MarkNativeAsOptional("PbSetInt");
		MarkNativeAsOptional("PbSetBool");
		MarkNativeAsOptional("PbSetString");
		MarkNativeAsOptional("PbAddString");
	}
	else
	{
		if (StrEqual(sGame, "csgo", false))
		{
			g_iGame = MissingTAG:3;
			MarkNativeAsOptional("BfWriteByte");
			MarkNativeAsOptional("BfWriteString");
		}
		g_iGame = MissingTAG:0;
		return APLRes:1;
	}
	RegPluginLibrary("VipBuild_001");
	return APLRes:0;
}

public Admins_OnPluginStart()
{
	RegAdminCmd("vip_users_add", Cmd_UsersAdd, 16384, "???????? ?????? VIP ??????.", "", 0);
	RegAdminCmd("vip_users_groups", Cmd_UsersGroups, 16384, "???? ???? VIP.", "", 0);
	RegAdminCmd("vip_users_del", Cmd_UsersDelete, 16384, "??????? VIP ??????.", "", 0);
	return 0;
}

public AdminsScan()
{
	new String:sBuffer[256];
	if (g_hKvAdmins)
	{
		CloseHandle(g_hKvAdmins);
		g_hKvAdmins = MissingTAG:0;
	}
	g_hKvAdmins = CreateKeyValues("Admins", "", "");
	new var1 = g_sAdminsPath;
	if (!FileToKeyValues(g_hKvAdmins, var1[0][var1]))
	{
		g_bBetaTest = false;
		CloseHandle(g_hKvAdmins);
		new var2 = g_sAdminsPath;
		Vip_Log("File '%s' not found!", var2[0][var2]);
		return 0;
	}
	if (g_hAdminsTrie[0])
	{
		ClearTrie(g_hAdminsTrie[0]);
	}
	KvRewind(g_hKvAdmins);
	if (KvGotoFirstSubKey(g_hKvAdmins, false))
	{
		do {
			KvGetSectionName(g_hKvAdmins, sBuffer, 256);
			SetTrieValue(g_hAdminsTrie[0], sBuffer, any:1, true);
		} while (KvGotoNextKey(g_hKvAdmins, false));
	}
	if (g_hKvAdminsGroups)
	{
		CloseHandle(g_hKvAdminsGroups);
		g_hKvAdminsGroups = MissingTAG:0;
	}
	g_hKvAdminsGroups = CreateKeyValues("AdminsGroups", "", "");
	if (!FileToKeyValues(g_hKvAdminsGroups, g_sAdminsPath[1]))
	{
		g_bBetaTest = false;
		CloseHandle(g_hKvAdminsGroups);
		Vip_Log("File '%s' not found!", g_sAdminsPath[1]);
		return 0;
	}
	if (g_hAdminsTrie[1])
	{
		ClearTrie(g_hAdminsTrie[1]);
	}
	KvRewind(g_hKvAdminsGroups);
	if (KvGotoFirstSubKey(g_hKvAdminsGroups, false))
	{
		do {
			KvGetSectionName(g_hKvAdminsGroups, sBuffer, 256);
			SetTrieValue(g_hAdminsTrie[1], sBuffer, any:1, true);
		} while (KvGotoNextKey(g_hKvAdminsGroups, false));
	}
	return 0;
}

public Action:Cmd_UsersAdd(client, args)
{
	new String:sBuffer[5][128] = "";
	decl iTemp[2];
	new var1;
	if (client > 0 && GetTrieSize(g_hAdminsTrie[2]) && !GetTrieValue(g_hAdminsTrie[2], g_sClientAuth[client][0], iTemp))
	{
		VipPrintError(client, "? ??? ??? ???????!");
		return Action:3;
	}
	new var2;
	if (!g_bBetaTest || args < 3)
	{
		VipPrintError(client, "Usage: vip_users_add \"NameUser\" \"SteamID|Name|IP\" \"Flags|Group\" \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
		return Action:3;
	}
	GetCmdArg(1, sBuffer[0][sBuffer], 128);
	GetCmdArg(2, sBuffer[1], 128);
	GetCmdArg(3, sBuffer[2], 128);
	GetCmdArg(4, sBuffer[3], 128);
	GetCmdArg(5, sBuffer[4], 128);
	if (StrEqual(sBuffer[0][sBuffer], "", false))
	{
		ReplyToCommand(client, "Usage: vip_users_add <NameUser> \"SteamID|Name|IP\" \"Flags|Group\" \"CountFlags|GroupName\"");
		return Action:3;
	}
	if (strlen(sBuffer[1]) <= 1)
	{
		ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" <SteamID|name|ip> \"Flags|Group\" \"CountFlags|GroupName\"");
		return Action:3;
	}
	if (StrEqual(sBuffer[2], "Flags", false))
	{
		iTemp[0] = 1;
	}
	else
	{
		if (StrEqual(sBuffer[2], "Group", false))
		{
			iTemp[0] = 2;
		}
		ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" \"SteamID|Name|IP\" <Flags|Group> \"CountFlags|GroupName\"");
		return Action:3;
	}
	if (iTemp[0] == 2)
	{
		GetTrieValue(g_hUsersGroupsTrie, sBuffer[3], iTemp[1]);
		if (iTemp[1] != 1)
		{
			ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" \"SteamID|Name|IP\" \"Group\" <?????? \"%s\" ?? ???????!>", sBuffer[3]);
			return Action:3;
		}
	}
	KvRewind(g_hKvUsers);
	if (KvJumpToKey(g_hKvUsers, sBuffer[1], false))
	{
		ReplyToCommand(client, "??????! ???????????? %s ??? ???????? ? [VIP] ???? ??????!", sBuffer[0][sBuffer]);
	}
	else
	{
		if (KvJumpToKey(g_hKvUsers, sBuffer[1], true))
		{
			KvSetString(g_hKvUsers, "name", sBuffer[0][sBuffer]);
			new var3;
			if (StrEqual(sBuffer[4], "", false) || StrEqual(sBuffer[4], "never", false))
			{
				KvSetString(g_hKvUsers, "expires", "never");
			}
			else
			{
				KvSetString(g_hKvUsers, "expires", sBuffer[4]);
			}
			if (iTemp[0] == 1)
			{
				KvSetString(g_hKvUsers, "flags", sBuffer[3]);
			}
			else
			{
				if (iTemp[0] == 2)
				{
					KvSetString(g_hKvUsers, "group", sBuffer[3]);
				}
			}
			KvRewind(g_hKvUsers);
			new var4 = g_sUsersPath;
			KeyValuesToFile(g_hKvUsers, var4[0][var4]);
			SetTrieValue(g_hUsersTrie, sBuffer[1], any:1, true);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				if (IsClientInGame(i))
				{
					if (StrEqual(sBuffer[1], g_sClientAuth[i][0], false))
					{
						OnClientPutInServer(i);
					}
				}
				i++;
			}
		}
		ReplyToCommand(client, "???????????? %s ??????? ???????? ? [VIP] ????.", sBuffer[0][sBuffer]);
		Vip_Log("????? %N ?????? ??????? ?????? ???????????? %s ? [VIP] ????.", client, sBuffer[0][sBuffer]);
	}
	return Action:3;
}

public Action:Cmd_UsersGroups(client, args)
{
	decl String:sBuffer[128];
	KvRewind(g_hKvUsersGroups);
	new var1;
	if (g_bBetaTest && KvGotoFirstSubKey(g_hKvUsersGroups, false))
	{
		ReplyToCommand(client, "User Groups");
		do {
			KvGetSectionName(g_hKvUsersGroups, sBuffer, 128);
			ReplyToCommand(client, "Group Name: \"%s\"", sBuffer);
		} while (KvGotoNextKey(g_hKvUsersGroups, false));
	}
	else
	{
		ReplyToCommand(client, "No Groups!");
	}
	return Action:3;
}

public Action:Cmd_UsersDelete(client, args)
{
	new var1;
	if (!g_bBetaTest || args < 1)
	{
		VipPrintError(client, "Usage: vip_users_del \"SteamID|name|ip\"");
		return Action:3;
	}
	new String:sBuffer[2][128] = "\x08";
	decl iTemp;
	new var2;
	if (client > 0 && GetTrieSize(g_hAdminsTrie[2]) && !GetTrieValue(g_hAdminsTrie[2], g_sClientAuth[client][0], iTemp))
	{
		VipPrintError(client, "? ??? ??? ???????!");
		return Action:3;
	}
	GetCmdArgString(sBuffer[0][sBuffer], 128);
	StripQuotes(sBuffer[0][sBuffer]);
	if (GetTrieValue(g_hUsersTrie, sBuffer[0][sBuffer], iTemp))
	{
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, sBuffer[0][sBuffer], false))
		{
			KvDeleteThis(g_hKvUsers);
		}
		KvRewind(g_hKvUsers);
		new var3 = g_sUsersPath;
		KeyValuesToFile(g_hKvUsers, var3[0][var3]);
		RemoveFromTrie(g_hUsersTrie, sBuffer[0][sBuffer]);
		DeleteUserSettings(sBuffer[0][sBuffer]);
		ResettingTheFlags(sBuffer[0][sBuffer]);
		ReplyToCommand(client, "%s ??????? ?????? ?? [VIP] ????.", sBuffer[0][sBuffer]);
		Vip_Log("????? %N ?????? ?????? %s ?? [VIP] ????.", client, sBuffer[0][sBuffer]);
	}
	else
	{
		ReplyToCommand(client, "??????! %s ?? ?????? ? [VIP] ????!", sBuffer[0][sBuffer]);
	}
	return Action:3;
}

public AdminAuth_Post(client)
{
	new String:sBuffer[3][128] = "";
	decl temp;
	if (GetTrieValue(g_hAdminsTrie[0], g_sClientAuth[client][0], temp))
	{
		KvRewind(g_hKvAdmins);
		if (KvJumpToKey(g_hKvAdmins, g_sClientAuth[client][0], false))
		{
			KvGetString(g_hKvAdmins, "name", sBuffer[1], 128, "unnamed");
			KvGetString(g_hKvAdmins, "password", sBuffer[0][sBuffer], 128, "none");
			KvGetString(g_hKvAdmins, "group", sBuffer[2], 128, "none");
			new var1;
			if (StrEqual(sBuffer[0][sBuffer], "none", false) || StrEqual(sBuffer[0][sBuffer], "", false))
			{
				if (GetTrieValue(g_hAdminsTrie[1], sBuffer[2], temp))
				{
					KvRewind(g_hKvAdminsGroups);
					if (KvJumpToKey(g_hKvAdminsGroups, sBuffer[2], false))
					{
						SetAdminFlags(g_hKvAdminsGroups, client, sBuffer[1]);
					}
				}
				else
				{
					SetAdminFlags(g_hKvAdmins, client, sBuffer[1]);
				}
			}
			new Handle:hDataPack = CreateDataPack();
			WritePackString(hDataPack, sBuffer[0][sBuffer]);
			WritePackString(hDataPack, sBuffer[1]);
			WritePackString(hDataPack, sBuffer[2]);
			QueryClientConVar(client, g_sAdminProtected, CVar_QueryCallBack, hDataPack);
		}
	}
	return 0;
}

public CVar_QueryCallBack(QueryCookie:cookie, client, ConVarQueryResult:result, String:cvarName[], String:cvarValue[], any:hDataPack)
{
	new String:sBuffer[2][128] = "\x08";
	decl temp;
	ResetPack(hDataPack, false);
	ReadPackString(hDataPack, sBuffer[0][sBuffer], 128);
	ReadPackString(hDataPack, sBuffer[1], 128);
	if (IsClientConnected(client))
	{
		if (result)
		{
			KickClient(client, "?????????? ????????????? ????????\n?????????????? ????!");
		}
		if (StrEqual(sBuffer[0][sBuffer], cvarValue, false))
		{
			ReadPackString(hDataPack, sBuffer[0][sBuffer], 128);
			if (GetTrieValue(g_hAdminsTrie[1], sBuffer[0][sBuffer], temp))
			{
				KvRewind(g_hKvAdminsGroups);
				if (KvJumpToKey(g_hKvAdminsGroups, sBuffer[0][sBuffer], false))
				{
					SetAdminFlags(g_hKvAdminsGroups, client, sBuffer[1]);
				}
			}
			else
			{
				SetAdminFlags(g_hKvAdmins, client, sBuffer[1]);
			}
		}
		else
		{
			Vip_Log("?????? ???????????! ?????? ?? ?????????! ?????? ??????? %N (%s) %s = %s ?????? ? ???? %s", client, g_sClientAuth[client][0], cvarName, cvarValue, sBuffer[0][sBuffer]);
			KickClient(client, "?????? ???????????! ?????????? ? ?????????????? ???????..");
		}
	}
	CloseHandle(hDataPack);
	return 0;
}

public SetAdminFlags(Handle:hKV, client, String:name[])
{
	new String:sBuffer[2][128] = "\x08";
	decl iBuffer[2];
	new AdminId:id = GetUserAdmin(client);
	if (id == AdminId:-1)
	{
		id = CreateAdmin(name);
		SetUserAdmin(client, id, true);
	}
	KvGetString(hKV, "flags", sBuffer[0][sBuffer], 128, "");
	iBuffer[0] = strlen(sBuffer[0][sBuffer]);
	if (iBuffer[0] > 0)
	{
		new i;
		while (iBuffer[0] + -1 >= i)
		{
			Format(sBuffer[1], 128, "%c", sBuffer[0][sBuffer][i]);
			if (GetTrieValue(g_hAdminFlagsTrie, sBuffer[1], iBuffer[1]))
			{
				SetAdminFlag(id, iBuffer[1], true);
				g_bIsAdmin[client] = 1;
			}
			i++;
		}
		if (g_bIsAdmin[client])
		{
			iBuffer[0] = KvGetNum(hKV, "immunity", 0);
			SetAdminImmunityLevel(id, iBuffer[0]);
			Vip_Log("??????? ??????????? ??? %N (%s)", client, g_sClientAuth[client][0]);
		}
	}
	return 0;
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if (part == AdminCachePart:2)
	{
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var1;
			if (IsClientInGame(i) && g_bBetaTest)
			{
				g_bIsAdmin[i] = 0;
				AdminAuth_Post(i);
			}
			i++;
		}
	}
	return 0;
}

public Chat_OnPluginStart()
{
	AddCommandListener(ClientChat_Cmd, "say");
	AddCommandListener(ClientChat_Cmd, "say_team");
	return 0;
}

public Action:ClientChat_Cmd(client, String:command[], args)
{
	new var1;
	if (client && g_bPlayerVip[client][0] && g_iPlayerVip[client][0])
	{
		if (!g_hTimerChat[client])
		{
			decl String:sBuffer[256];
			decl iBuffer;
			GetCmdArgString(sBuffer, 256);
			StripQuotes(sBuffer);
			new var2;
			if (CheckCommandAccess(client, "sm_say", 512, false) && sBuffer[0] == '@')
			{
				return Action:0;
			}
			if (!GetTrieValue(g_hChatTrie, sBuffer, iBuffer))
			{
				decl String:sName[32];
				decl String:sAlive[64];
				g_iClientTeam[client] = GetClientTeam(client);
				if (GetClientName(client, sName, 32))
				{
					new var3;
					if (sBuffer[0] == '!' && sBuffer[0] == '!' && strlen(sBuffer) >= 3)
					{
						strcopy(sBuffer, 256, sBuffer[0]);
						if (g_bPlayerAlive[client])
						{
							strcopy(sAlive, 64, "\x04[VIP|???]");
						}
						else
						{
							strcopy(sAlive, 64, "\x01*????* \x04[VIP|???]");
						}
						iBuffer = 3;
					}
					else
					{
						if (StrEqual(command, "say", false))
						{
							new var4;
							if (!g_iClientTeam[client] || g_iClientTeam[client] == 1)
							{
								strcopy(sAlive, 64, "\x01*???????????* \x04[VIP]");
							}
							else
							{
								if (g_bPlayerAlive[client])
								{
									strcopy(sAlive, 64, "\x04[VIP]");
								}
								strcopy(sAlive, 64, "\x01*????* \x04[VIP]");
							}
							iBuffer = 1;
						}
						if (StrEqual(command, "say_team", false))
						{
							if (g_iClientTeam[client] == 2)
							{
								if (g_bPlayerAlive[client])
								{
									strcopy(sAlive, 64, "\x04[VIP]\x01 (?????????)");
								}
								else
								{
									strcopy(sAlive, 64, "\x01*????* \x04[VIP]\x01 (?????????)");
								}
							}
							else
							{
								if (g_iClientTeam[client] == 3)
								{
									if (g_bPlayerAlive[client])
									{
										strcopy(sAlive, 64, "\x04[VIP]\x01 (???????????)");
									}
									else
									{
										strcopy(sAlive, 64, "\x01*????* \x04[VIP]\x01 (???????????)");
									}
								}
								strcopy(sAlive, 64, "\x04[VIP]\x01 (???????????)");
							}
							iBuffer = 2;
						}
					}
					new i = 1;
					while (i <= g_iMaxClients)
					{
						if (IsClientInGame(i))
						{
							if (iBuffer == 1)
							{
								if (g_bPlayerAlive[client])
								{
									Users_SayChat(i, client, sAlive, sName, sBuffer);
								}
								else
								{
									if (!g_bPlayerAlive[i])
									{
										Users_SayChat(i, client, sAlive, sName, sBuffer);
									}
								}
							}
							if (iBuffer == 2)
							{
								g_iClientTeam[i] = GetClientTeam(i);
								if (g_iClientTeam[client] == g_iClientTeam[i])
								{
									if (g_bPlayerAlive[client])
									{
										Users_SayChat(i, client, sAlive, sName, sBuffer);
									}
									if (!g_bPlayerAlive[i])
									{
										Users_SayChat(i, client, sAlive, sName, sBuffer);
									}
								}
							}
							new var5;
							if (g_bPlayerVip[i][0] && g_iPlayerVip[i][0])
							{
								if (g_iPlayerVip[i][0] == 2)
								{
									if (i != client)
									{
										EmitSoundToClient(i, "buttons/blip2.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
									}
									EmitSoundToClient(client, "ui/buttonclick.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								Users_SayChat(i, client, sAlive, sName, sBuffer);
							}
						}
						i++;
					}
				}
				g_hTimerChat[client] = CreateTimer(0.5, Timer_ClientSay, client, 0);
			}
			return Action:0;
		}
		return Action:3;
	}
	return Action:0;
}

public Users_SayChat(client, author, String:tag[], String:name[], String:text[])
{
	decl Handle:hBuffer;
	decl String:sBuffer[256];
	hBuffer = StartMessageOne("SayText2", client, 132);
	if (g_iGame == GameType:3)
	{
		Format(sBuffer, 256, "\x01%s \x03%s\x01 : %s", tag, name, text);
		PbSetInt(hBuffer, "ent_idx", author);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", sBuffer);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		Format(sBuffer, 256, "%s \x03%s\x01 : %s", tag, name, text);
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, sBuffer);
	}
	EndMessage();
	return 0;
}

public Action:Timer_ClientSay(Handle:timer, any:client)
{
	g_hTimerChat[client] = 0;
	return Action:4;
}

public Display_VipChat(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_VipChat, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "[VIP] ???: ?????????", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "disable", "???: [?????????]", 0);
	if (g_iPlayerVip[client][0] == 2)
	{
		Format(sBuffer, 100, "????? ?????????: [????????]", client);
	}
	else
	{
		Format(sBuffer, 100, "????? ?????????: [?????????]", client);
	}
	AddMenuItem(hMenu, "sound", sBuffer, 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_VipChat(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (StrEqual(sInfo, "disable", false))
			{
				g_iPlayerVip[client][0] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, "???: [?????????]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
			else
			{
				if (g_iPlayerVip[client][0] == 2)
				{
					g_iPlayerVip[client][0] = 1;
					VipPrint(client, "????? ?????????: [?????????]");
				}
				else
				{
					g_iPlayerVip[client][0] = 2;
					VipPrint(client, "????? ?????????: [????????]");
				}
				g_bSettingsChanged[client] = 1;
				Display_VipChat(client);
			}
		}
	}
	return 0;
}

public Events_OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode:2);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode:1);
	HookEvent("bomb_planted", Event_PlayerBomb, EventHookMode:1);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode:1);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode:1);
	HookEvent("player_falldamage", Event_PlayerFallDamage, EventHookMode:1);
	HookEvent("flashbang_detonate", Event_FlashBang, EventHookMode:1);
	HookEvent("weapon_reload", Event_WeaponReload, EventHookMode:1);
	HookEvent("weapon_fire_on_empty", Event_WeaponReload, EventHookMode:1);
	return 0;
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if (g_bJoinClass)
	{
		ClearTrie(g_hUsersJoinCache);
		g_bJoinClass = false;
	}
	return 0;
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_PlayerSpawn, GetEventInt(event, "userid"), 0);
	return 0;
}

public Action:Timer_PlayerSpawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client)
	{
		g_iClientTeam[client] = GetClientTeam(client);
		g_bPlayerAlive[client] = IsPlayerAlive(client);
		new var1;
		if (g_iClientTeam[client] && g_bPlayerAlive[client])
		{
			new var2;
			if (g_bPlayerVip[client][1] && g_iPlayerVip[client][1])
			{
				PlayerSpawn_Models(client);
			}
			new var3;
			if (g_bIsDeMap && g_bPlayerVip[client][9] && g_iPlayerVip[client][9] && g_iClientTeam[client] == 2)
			{
				PlayerSpawn_C4(client);
			}
			new var4;
			if (!g_bMapsNoGiveWeapons && g_bPlayerVip[client][4] && g_iPlayerVip[client][4])
			{
				PlayerSpawn_Weapon(client);
			}
			new var5;
			if (g_bPlayerVip[client][3] && g_iPlayerVip[client][3])
			{
				PlayerSpawn_Cash(client);
			}
			new var6;
			if (g_bPlayerVip[client][14] && g_iPlayerVip[client][14] != 100)
			{
				PlayerSpawn_Health(client);
			}
			new var7;
			if (g_bPlayerVip[client][15] && g_iPlayerVip[client][15] != 1)
			{
				PlayerSpawn_Speed(client);
			}
		}
	}
	return Action:4;
}

public Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client)
	{
		new var1;
		if (g_bPlayerVip[client][11] && g_iPlayerVip[client][11])
		{
			Player_Regeneration(client);
		}
		if (g_hTimerMedic[client][1])
		{
			KillTimer(g_hTimerMedic[client][1], false);
			g_hTimerMedic[client][1] = MissingTAG:0;
		}
		new var2;
		if (attacker && g_bPlayerVip[attacker][5] && g_iPlayerVip[attacker][5] && attacker != client)
		{
			PrintCenterText(attacker, "-%i HP", GetEventInt(event, "dmg_health"));
		}
	}
	return 0;
}

public Event_PlayerBomb(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_RemoveBomb, any:0, 0);
	return 0;
}

public Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client)
	{
		g_bPlayerAlive[client] = 0;
		new var1;
		if (g_bPlayerVip[client][15] && g_iPlayerVip[client][15] != 1)
		{
			Player_SpeedDead(client);
		}
		new var2;
		if (g_bPlayerVip[client][2] && g_iPlayerVip[client][2])
		{
			new var3;
			if (attacker && attacker != client && g_iClientTeam[attacker] == g_iClientTeam[client] && g_hTopMenu)
			{
				GetClientAbsOrigin(client, g_fTeamKill[client]);
				g_iTarget[client] = attacker;
				CreateTimer(1.15, Timer_TeamKill, client, 0);
			}
			SetTrieValue(g_hUsersJoinCache, g_sClientAuth[client][0], any:1, true);
			g_bJoinClass = true;
		}
	}
	return 0;
}

public Event_PlayerFallDamage(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (client && g_bPlayerVip[client][11] && g_iPlayerVip[client][11])
	{
		Player_Regeneration(client);
	}
	return 0;
}

public Event_FlashBang(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		new Float:fOrigin[2][3] = {3.85186E-34,2.5243549E-29};
		fOrigin[0][fOrigin] = GetEventFloat(event, "x");
		fOrigin[0][fOrigin][1] = GetEventFloat(event, "y");
		fOrigin[0][fOrigin][2] = GetEventFloat(event, "z");
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var1;
			if (g_bPlayerVip[i][6] && g_iPlayerVip[i][6] && g_iClientTeam[client] == g_iClientTeam[i] && i != client && IsClientInGame(i))
			{
				GetClientEyePosition(i, fOrigin[1]);
				if (GetVectorDistance(fOrigin[0][fOrigin], fOrigin[1], false) <= 1152729088)
				{
					SetPlayerAlphaBlind(i);
				}
			}
			i++;
		}
	}
	return 0;
}

public Event_WeaponReload(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (g_bReloadAmmo && !g_bMapsNoGiveWeapons && client && g_bPlayerVip[client][4] && g_iPlayerVip[client][4] && g_bPlayerAlive[client] && !StrEqual(g_sWeapon[client][12], "no", false))
	{
		Player_WeaponReload(client);
	}
	return 0;
}

public Health_OnPluginStart()
{
	RegConsoleCmd("vip_health", SetHealth_Cmd, "vip_health 115", 0);
	RegConsoleCmd("vip_hp", SetHealth_Cmd, "vip_hp 115", 0);
	return 0;
}

public PlayerSpawn_Health(client)
{
	SetPlayerHealth(client, g_iPlayerVip[client][14]);
	return 0;
}

public Action:SetHealth_Cmd(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][14])
		{
			if (0 < args)
			{
				decl String:sBuffer[8];
				decl iHealth;
				GetCmdArgString(sBuffer, 5);
				iHealth = StringToInt(sBuffer, 10);
				new var1;
				if (iHealth > 0 && g_iMaxHealth >= iHealth)
				{
					if (g_bPlayerAlive[client])
					{
						if (GetPlayerHealth(client) != iHealth)
						{
							if (iHealth >= g_iMaxHealth)
							{
								SetPlayerHealth(client, g_iMaxHealth);
								SetPlayerArmor(client, g_iMaxHealth);
							}
							SetPlayerHealth(client, iHealth);
							SetPlayerArmor(client, iHealth);
						}
					}
					if (iHealth != g_iPlayerVip[client][14])
					{
						g_iPlayerVip[client][14] = iHealth;
						g_bSettingsChanged[client] = 1;
					}
				}
				else
				{
					ReplyToCommand(client, "\x04[VIP]\x01 ????????? ????? %s HP ???????????!", sBuffer);
				}
			}
			else
			{
				ReplyToCommand(client, "\x04[VIP]\x01 ????????? HP \"vip_health 115\" ??? \"vip_hp 115\"");
			}
		}
		VipPrintError(client, "??? ?? ???????? ????????? HP!");
	}
	return Action:3;
}

public Display_SpawnHeatlthSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_SpawnHeatlthSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "HP ??? ??????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "100", "HP ??? ??????: [????????]", 0);
	AddMenuItem(hMenu, "10", "?????????????: [10 HP]", 0);
	AddMenuItem(hMenu, "35", "?????????????: [35 HP]", 0);
	AddMenuItem(hMenu, "50", "?????????????: [50 HP]", 0);
	AddMenuItem(hMenu, "75", "?????????????: [75 HP]", 0);
	if (g_iMaxHealth >= 115)
	{
		AddMenuItem(hMenu, "115", "?????????????: [115 HP]", 0);
	}
	if (g_iMaxHealth >= 150)
	{
		AddMenuItem(hMenu, "150", "?????????????: [150 HP]", 0);
	}
	if (g_iMaxHealth >= 200)
	{
		AddMenuItem(hMenu, "200", "?????????????: [200 HP]", 0);
	}
	if (g_iMaxHealth >= 250)
	{
		AddMenuItem(hMenu, "250", "?????????????: [250 HP]", 0);
	}
	if (g_iMaxHealth >= 300)
	{
		AddMenuItem(hMenu, "300", "?????????????: [300 HP]", 0);
	}
	if (g_iMaxHealth >= 350)
	{
		AddMenuItem(hMenu, "350", "?????????????: [350 HP]", 0);
	}
	if (g_iMaxHealth >= 400)
	{
		AddMenuItem(hMenu, "400", "?????????????: [400 HP]", 0);
	}
	if (g_iMaxHealth >= 450)
	{
		AddMenuItem(hMenu, "450", "?????????????: [450 HP]", 0);
	}
	if (g_iMaxHealth >= 500)
	{
		AddMenuItem(hMenu, "500", "?????????????: [500 HP]", 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_SpawnHeatlthSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			g_iPlayerVip[client][14] = StringToInt(sInfo, 10);
			g_bSettingsChanged[client] = 1;
			VipPrint(client, "??????????? ??????????? ? HP [%s]", sInfo);
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
	}
	return 0;
}

public Speed_OnPluginStart()
{
	RegConsoleCmd("vip_speed", SetSpeed_Cmd, "vip_speed 5 | vip_speed 21", 0);
	return 0;
}

public Action:SetSpeed_Cmd(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][15])
		{
			if (0 < args)
			{
				decl String:sBuffer[4];
				decl iSpeed;
				decl Float:fSpeed;
				GetCmdArgString(sBuffer, 3);
				iSpeed = StringToInt(sBuffer, 10);
				new var1;
				if (iSpeed >= 1 && g_iMaxSpeed >= iSpeed)
				{
					if (g_bPlayerAlive[client])
					{
						fSpeed = 1091567616 + iSpeed / 10.0;
						if (GetPlayerSpeed(client) != fSpeed)
						{
							SetPlayerSpeed(client, fSpeed);
						}
					}
					g_iPlayerVip[client][15] = iSpeed;
					g_bSettingsChanged[client] = 1;
				}
				else
				{
					VipPrintError(client, "?????? ???????? %i!", g_iMaxSpeed);
				}
			}
			else
			{
				ReplyToCommand(client, "\x04[VIP]\x01 ????????? ???????? \"vip_speed 5\"");
			}
		}
		VipPrintError(client, "??? ?? ???????? ????????? ????????!");
	}
	return Action:3;
}

public PlayerSpawn_Speed(client)
{
	SetPlayerSpeed(client, g_iPlayerVip[client][15][1091567616] / 10);
	return 0;
}

public Player_SpeedDead(client)
{
	SetPlayerSpeed(client, 1.0);
	return 0;
}

public Display_SpawnSpeedSettings(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnSpeedSettings, MenuAction:28);
	new String:sBuffer[2][128] = "\x08";
	Format(sBuffer[0][sBuffer], 128, "???????? ???????????: [?????????]", client);
	SetMenuTitle(menu, sBuffer[0][sBuffer]);
	AddMenuItem(menu, "1", "??????????? ???????? [x1]", 0);
	new s = 2;
	while (s <= g_iMaxSpeed)
	{
		Format(sBuffer[0][sBuffer], 128, "%i", s);
		Format(sBuffer[1], 128, "????????: [x%i]", s, client);
		AddMenuItem(menu, sBuffer[0][sBuffer], sBuffer[1], 0);
		s++;
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public MenuHandler_SpawnSpeedSettings(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(menu, param, sInfo, 32, 0, "", 0);
			g_iPlayerVip[client][15] = StringToInt(sInfo, 10);
			if (g_iPlayerVip[client][15] == 1)
			{
				if (g_bPlayerAlive[client])
				{
					SetPlayerSpeed(client, g_iPlayerVip[client][15][1091567616] / 10);
				}
			}
			g_bSettingsChanged[client] = 1;
			PlayerSpawn_Speed(client);
			VipPrint(client, "??????????? ???????? [x%s]", sInfo);
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
	}
	return 0;
}

public PlayerSpawn_C4(client)
{
	if (GetPlayerWeaponSlot(client, 4) < 1)
	{
		GivePlayerItem(client, "weapon_c4", 0);
	}
	return 0;
}

public Action:Timer_RemoveBomb(Handle:timer)
{
	decl iBuffer[2];
	decl String:sWeapon[64];
	iBuffer[0] = GetMaxEntities();
	new ent = g_iMaxClients;
	while (iBuffer[0] > ent)
	{
		new var1;
		if (IsValidEdict(ent) && IsValidEntity(ent) && GetEntDataEnt2(ent, g_iWeaponParentOffset) == -1)
		{
			GetEdictClassname(ent, sWeapon, 64);
			if (StrEqual(sWeapon, "weapon_c4", false))
			{
				RemoveEdict(ent);
			}
		}
		ent++;
	}
	new i = 1;
	while (i <= g_iMaxClients)
	{
		if (IsClientInGame(i))
		{
			iBuffer[1] = GetPlayerWeaponSlot(i, 4);
			if (iBuffer[1] > 1)
			{
				if (GetEntDataEnt2(i, g_iActiveWeaponOffset) == iBuffer[1])
				{
					RemovePlayerItem(i, iBuffer[1]);
					RemoveEdict(iBuffer[1]);
					if ((iBuffer[0] = GetPlayerWeaponSlot(i, 0)) > 1)
					{
						EquipPlayerWeapon(i, iBuffer[0]);
					}
					else
					{
						if ((iBuffer[0] = GetPlayerWeaponSlot(i, 1)) > 1)
						{
							EquipPlayerWeapon(i, iBuffer[0]);
						}
						if ((iBuffer[0] = GetPlayerWeaponSlot(i, 2)) > 1)
						{
							EquipPlayerWeapon(i, iBuffer[0]);
						}
						if ((iBuffer[0] = GetPlayerWeaponSlot(i, 3)) > 1)
						{
							EquipPlayerWeapon(i, iBuffer[0]);
						}
					}
				}
				RemovePlayerItem(i, iBuffer[1]);
				RemoveEdict(iBuffer[1]);
			}
		}
		i++;
	}
	return Action:4;
}

public Player_Regeneration(client)
{
	if (g_hTimerRegeneration[client][0])
	{
		KillTimer(g_hTimerRegeneration[client][0], false);
	}
	if (g_hTimerRegeneration[client][1])
	{
		KillTimer(g_hTimerRegeneration[client][1], false);
		g_hTimerRegeneration[client][1] = MissingTAG:0;
	}
	g_hTimerRegeneration[client][0] = CreateTimer(g_fRegenTime[0], Timer_Regeneration, client, 0);
	new var1;
	if (g_bHeartBeat && g_iPlayerVip[client][11] == 2 && g_iRegenHP[1] >= GetPlayerHealth(client))
	{
		g_hTimerRegeneration[client][1] = CreateTimer(0.1, Timer_SoundHeartBeat, client, 0);
	}
	return 0;
}

public Action:Timer_Regeneration(Handle:timer, any:client)
{
	g_hTimerRegeneration[client][0] = MissingTAG:0;
	new var1;
	if (g_bPlayerAlive[client] && IsClientInGame(client))
	{
		decl iBuffer[2];
		new var2;
		if (g_bPlayerVip[client][14] && g_iPlayerVip[client][14])
		{
			iBuffer[1] = g_iPlayerVip[client][14];
		}
		else
		{
			iBuffer[1] = 100;
		}
		iBuffer[0] = GetPlayerHealth(client) + g_iRegenHP[0];
		if (iBuffer[0] <= iBuffer[1])
		{
			SetPlayerHealth(client, iBuffer[0]);
			if (iBuffer[1] == iBuffer[0])
			{
				if (iBuffer[1] < 100)
				{
					iBuffer[1] = 100;
				}
				PlayerReArmor(client, iBuffer[1]);
			}
			else
			{
				g_hTimerRegeneration[client][0] = CreateTimer(g_fRegenTime[1], Timer_Regeneration, client, 0);
			}
		}
		else
		{
			if (iBuffer[1] < 100)
			{
				iBuffer[1] = 100;
			}
			PlayerReArmor(client, iBuffer[1]);
		}
	}
	return Action:4;
}

public Action:Timer_SoundHeartBeat(Handle:timer, any:client)
{
	g_hTimerRegeneration[client][1] = MissingTAG:0;
	new var1;
	if (g_bPlayerAlive[client] && IsClientInGame(client) && g_iRegenHP[1] >= GetPlayerHealth(client))
	{
		EmitSoundToClient(client, g_sSoundHeartBeat, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		g_hTimerRegeneration[client][1] = CreateTimer(GetRandomFloat(g_fRegenTime[2], g_fRegenTime[3]), Timer_SoundHeartBeat, client, 0);
	}
	return Action:4;
}

public Display_Regeneration(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Regeneration, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "??????????? HP: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "??????????? HP: [?????????]", client);
	AddMenuItem(hMenu, "disable", sBuffer, 0);
	if (g_bHeartBeat)
	{
		if (g_iPlayerVip[client][11] == 2)
		{
			Format(sBuffer, 100, "???? ????????????: [????????]", client);
			AddMenuItem(hMenu, "sound", sBuffer, 0);
			AddMenuItem(hMenu, "play", "?????????? ???? ????????????", 0);
		}
		else
		{
			if (g_iPlayerVip[client][11] == 1)
			{
				Format(sBuffer, 100, "???? ????????????: [?????????]", client);
				AddMenuItem(hMenu, "sound", sBuffer, 0);
				AddMenuItem(hMenu, "play", "?????????? ???? ????????????", 0);
			}
			Format(sBuffer, 100, "???? ????????????: [??????????!]", client);
			AddMenuItem(hMenu, "", sBuffer, 1);
			Format(sBuffer, 100, "?????????? ???? ????????????: [??????????!]", client);
			AddMenuItem(hMenu, "", sBuffer, 1);
		}
	}
	else
	{
		Format(sBuffer, 100, "???? ????????????: [???? ????? ?? ??????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
		Format(sBuffer, 100, "?????????? ???? ????????????: [???? ????? ?? ??????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_Regeneration(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (StrEqual(sInfo, "disable", false))
			{
				g_iPlayerVip[client][11] = 0;
				VipPrint(client, "??????????? HP: [?????????]");
				g_bSettingsChanged[client] = 1;
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				return 0;
			}
			if (StrEqual(sInfo, "sound", false))
			{
				if (g_iPlayerVip[client][11] == 2)
				{
					g_iPlayerVip[client][11] = 1;
					VipPrint(client, "???? ????????????: [????????]");
				}
				else
				{
					g_iPlayerVip[client][11] = 2;
					VipPrint(client, "???? ????????????: [???????]");
				}
				g_bSettingsChanged[client] = 1;
			}
			else
			{
				if (StrEqual(sInfo, "play", false))
				{
					EmitSoundToClient(client, "vip/heartbeat.mp3", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
			}
			Display_Regeneration(client);
		}
	}
	return 0;
}

public Action:Users_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new var1;
	if (!attacker || attacker > g_iMaxClients)
	{
		return Action:0;
	}
	new var2;
	if (g_bPlayerVip[attacker][13] && g_iPlayerVip[attacker][13] && victim == attacker)
	{
		return Action:3;
	}
	if (g_bFriendLyFire)
	{
		new var3;
		if (g_bPlayerVip[attacker][12] && g_iPlayerVip[attacker][12] && attacker != victim && g_iClientTeam[attacker] == g_iClientTeam[victim])
		{
			decl iBuffer[2];
			iBuffer[0] = GetPlayerHealth(victim);
			if (g_bPlayerVip[victim][14])
			{
				iBuffer[1] = g_iPlayerVip[victim][14];
			}
			else
			{
				iBuffer[1] = 100;
			}
			if (iBuffer[1] != iBuffer[0])
			{
				if (!g_hTimerMedic[attacker][0])
				{
					g_hTimerMedic[attacker][0] = CreateTimer(5.0, Timer_Medic, attacker, 0);
					g_hTimerMedic[victim][1] = CreateTimer(0.009, Timer_ClientHealthRecovery, victim, 0);
				}
				return Action:3;
			}
		}
		if (g_bPlayerVip[attacker][7])
		{
			new var4;
			if (g_bPlayerVip[victim][7] && g_iPlayerVip[victim][7] >= 1 && victim != attacker && g_iClientTeam[victim] == g_iClientTeam[attacker])
			{
				return Action:3;
			}
			new var5;
			if (g_iPlayerVip[attacker][7] == 2 && victim != attacker && g_iClientTeam[victim] == g_iClientTeam[attacker])
			{
				return Action:3;
			}
		}
		if (g_bPlayerVip[victim][7])
		{
			new var6;
			if (g_iPlayerVip[victim][7] >= 1 && attacker != victim && g_iClientTeam[attacker] == g_iClientTeam[victim])
			{
				return Action:3;
			}
		}
	}
	new var7;
	if (g_bPlayerVip[attacker][10] && g_iPlayerVip[attacker][10])
	{
		damage = damage * g_fIncreaseDamage;
		return Action:1;
	}
	return Action:0;
}

public Action:Timer_Medic(Handle:timer, any:attacker)
{
	g_hTimerMedic[attacker][0] = MissingTAG:0;
	return Action:4;
}

public Action:Timer_ClientHealthRecovery(Handle:timer, any:victim)
{
	new var1;
	if (IsClientInGame(victim) && g_bPlayerAlive[victim])
	{
		decl iBuffer[2];
		iBuffer[0] = GetPlayerHealth(victim);
		if (g_bPlayerVip[victim][14])
		{
			iBuffer[1] = g_iPlayerVip[victim][14];
		}
		else
		{
			iBuffer[1] = 100;
		}
		if (iBuffer[1] != iBuffer[0])
		{
			iBuffer[0] = iBuffer[0] + 1;
			if (iBuffer[1] <= iBuffer[0])
			{
				SetPlayerHealth(victim, iBuffer[1]);
				PlayerReArmor(victim, iBuffer[1]);
			}
			SetPlayerHealth(victim, iBuffer[0]);
			g_hTimerMedic[victim][1] = CreateTimer(0.009, Timer_ClientHealthRecovery, victim, 0);
			return Action:0;
		}
	}
	g_hTimerMedic[victim][1] = MissingTAG:0;
	return Action:4;
}

public Display_NoFriendLyFire(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_NoFriendLyFire, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "??????????? ?? ???????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "??????????? ?? ???????: [????????]", client);
	AddMenuItem(hMenu, "enable", sBuffer, 0);
	if (g_iPlayerVip[client][7] == 1)
	{
		Format(sBuffer, 100, "??????????? ??????????? ?? ?????: [X]", client);
		AddMenuItem(hMenu, "fire", sBuffer, 1);
		Format(sBuffer, 100, "??????????? ??? ???????????: [ ]", client);
		AddMenuItem(hMenu, "fire", sBuffer, 0);
	}
	else
	{
		if (g_iPlayerVip[client][7] == 2)
		{
			Format(sBuffer, 100, "??????????? ??????????? ?? ?????: [ ]", client);
			AddMenuItem(hMenu, "fire", sBuffer, 0);
			Format(sBuffer, 100, "??????????? ??? ???????????: [X]", client);
			AddMenuItem(hMenu, "fire", sBuffer, 1);
		}
		Format(sBuffer, 100, "??????????? ??????????? ?? ?????: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
		Format(sBuffer, 100, "??????????? ??? ???????????: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_NoFriendLyFire(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			g_bSettingsChanged[client] = 1;
			if (StrEqual(sInfo, "enable", false))
			{
				g_iPlayerVip[client][7] = 0;
				VipPrint(client, "??????????? ?? ???????: [????????]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
			else
			{
				if (StrEqual(sInfo, "fire", false))
				{
					if (g_iPlayerVip[client][7] == 2)
					{
						g_iPlayerVip[client][7] = 1;
						VipPrint(client, "??????????? ??????????? ?? ?????: [????????]");
					}
					else
					{
						g_iPlayerVip[client][7] = 2;
						VipPrint(client, "??????????? ??? ???????????: [????????]");
					}
					Display_NoFriendLyFire(client);
				}
			}
		}
	}
	return 0;
}

public Weapon_OnPluginStart()
{
	RegConsoleCmd("vip_weapon", GiveWeapon_Cmd, "vip_weapon ak47", 0);
	RegConsoleCmd("vip_giveweapon", GiveWeapon_Cmd, "vip_giveweapon ak47", 0);
	RegConsoleCmd("vip_give", GiveWeapon_Cmd, "vip_give ak47", 0);
	AddCommandListener(DropWeapon_Cmd, "drop");
	return 0;
}

public Action:GiveWeapon_Cmd(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][4])
		{
			if (!g_bMapsNoGiveWeapons)
			{
				if (args)
				{
					new String:sBuffer[2][64] = "\x08";
					decl iBuffer[3];
					iBuffer[2] = GetClientTeam(client);
					GetCmdArgString(sBuffer[0][sBuffer], 64);
					if (GetTrieValue(g_hWeaponTrie, sBuffer[0][sBuffer], iBuffer))
					{
						if (g_bPlayerAlive[client])
						{
							Format(sBuffer[0][sBuffer], 64, "weapon_%s", sBuffer[0][sBuffer]);
							switch (iBuffer[0])
							{
								case 3:
								{
									if (StrEqual("weapon_hegrenade", sBuffer[0][sBuffer], false))
									{
										if (!GetPlayerGrenade(client, 11))
										{
											GivePlayerItem(client, sBuffer[0][sBuffer], 0);
										}
									}
									else
									{
										if (StrEqual("weapon_flashbang", sBuffer[0][sBuffer], false))
										{
											iBuffer[1] = GetPlayerGrenade(client, 12);
											if (!iBuffer[1])
											{
												GivePlayerItem(client, sBuffer[0][sBuffer], 0);
											}
											else
											{
												if (iBuffer[1] == 1)
												{
													SetPlayerGrenade(client, 2, 12);
												}
											}
										}
										if (StrEqual("weapon_smokegrenade", sBuffer[0][sBuffer], false))
										{
											if (!GetPlayerGrenade(client, 13))
											{
												GivePlayerItem(client, sBuffer[0][sBuffer], 0);
											}
										}
									}
								}
								case 4:
								{
									if (iBuffer[2] == 2)
									{
										if (GetPlayerWeaponSlot(client, iBuffer[0]) < 1)
										{
											GivePlayerItem(client, sBuffer[0][sBuffer], 0);
										}
									}
									else
									{
										VipPrint(client, "????? ??????? ?????????? ?4!");
									}
								}
								default:
								{
									iBuffer[1] = GetPlayerWeaponSlot(client, iBuffer[0]);
									if (iBuffer[1] > 1)
									{
										GetEdictClassname(iBuffer[1], sBuffer[1], 64);
										if (!StrEqual(sBuffer[0][sBuffer], sBuffer[1], false))
										{
											RemovePlayerItem(client, iBuffer[1]);
											GivePlayerItem(client, sBuffer[0][sBuffer], 0);
										}
									}
									else
									{
										GivePlayerItem(client, sBuffer[0][sBuffer], 0);
									}
								}
							}
							ReplaceString(sBuffer[0][sBuffer], 64, "weapon_", "", true);
						}
						switch (iBuffer[0])
						{
							case 0:
							{
								if (iBuffer[2] == 2)
								{
									Format(g_sWeapon[client][0], 64, sBuffer[0][sBuffer]);
									g_bSettingsChanged[client] = 1;
								}
								else
								{
									if (iBuffer[2] == 3)
									{
										Format(g_sWeapon[client][1], 64, sBuffer[0][sBuffer]);
										g_bSettingsChanged[client] = 1;
									}
								}
							}
							case 1:
							{
								if (iBuffer[2] == 2)
								{
									Format(g_sWeapon[client][2], 64, sBuffer[0][sBuffer]);
									g_bSettingsChanged[client] = 1;
								}
								else
								{
									if (iBuffer[2] == 3)
									{
										Format(g_sWeapon[client][3], 64, sBuffer[0][sBuffer]);
										g_bSettingsChanged[client] = 1;
									}
								}
							}
							default:
							{
							}
						}
						if (!g_iPlayerVip[client][4])
						{
							g_iPlayerVip[client][4] = 1;
						}
					}
					else
					{
						VipPrintError(client, "?? ????????? ??????!");
					}
				}
				else
				{
					VipPrint(client, "??????: vip_give m4a1");
				}
			}
			else
			{
				VipPrintError(client, "?? ???? ????? ????????? ????????? ??????!");
			}
		}
		else
		{
			VipPrintError(client, "??? ?? ???????? ??? ???????!");
		}
	}
	else
	{
		ReplyToCommand(client, "[VIP] Available only to players!");
	}
	return Action:3;
}

public Action:DropWeapon_Cmd(client, String:command[], args)
{
	new var1;
	if (client && g_bPlayerVip[client][4] && g_iPlayerVip[client][4] && g_bPlayerAlive[client] && !StrEqual(g_sWeapon[client][11], "no", false))
	{
		decl iBuffer[2];
		decl String:sBuffer[24];
		iBuffer[0] = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		new var2;
		if (iBuffer[0] > 0 && GetEntityClassname(iBuffer[0], sBuffer, 22))
		{
			new var3;
			if (StrEqual(sBuffer, "weapon_hegrenade", false) || StrEqual(sBuffer, "weapon_smokegrenade", false) || StrEqual(sBuffer, "weapon_knife", false))
			{
				CS_DropWeapon(client, iBuffer[0], true, false);
				return Action:3;
			}
			if (StrEqual(sBuffer, "weapon_flashbang", false))
			{
				iBuffer[1] = GetPlayerGrenade(client, 12);
				CS_DropWeapon(client, iBuffer[0], true, false);
				if (iBuffer[1] == 2)
				{
					GivePlayerItem(client, sBuffer, 0);
				}
				return Action:3;
			}
			if (g_iGame == GameType:3)
			{
				new var4;
				if (StrEqual(sBuffer, "weapon_taser", false) || StrEqual(sBuffer, "weapon_molotov", false) || StrEqual(sBuffer, "weapon_incgrenade", false) || StrEqual(sBuffer, "weapon_decoy", false))
				{
					CS_DropWeapon(client, iBuffer[0], true, false);
					return Action:3;
				}
			}
		}
	}
	return Action:0;
}

public PlayerSpawn_Weapon(client)
{
	decl iBuffer;
	if (g_iClientTeam[client])
	{
		if (g_iClientTeam[client] == 2)
		{
			if (!StrEqual(g_sWeapon[client][0], "none", false))
			{
				GivePlayerItem_Weapon(client, 0, g_sWeapon[client][0]);
			}
			if (!StrEqual(g_sWeapon[client][2], "none", false))
			{
				GivePlayerItem_Weapon(client, 1, g_sWeapon[client][2]);
			}
		}
		else
		{
			if (g_iClientTeam[client] == 3)
			{
				if (!StrEqual(g_sWeapon[client][1], "none", false))
				{
					GivePlayerItem_Weapon(client, 0, g_sWeapon[client][1]);
				}
				if (!StrEqual(g_sWeapon[client][3], "none", false))
				{
					GivePlayerItem_Weapon(client, 1, g_sWeapon[client][3]);
				}
			}
		}
		if (StrEqual(g_sWeapon[client][4], "setup", false))
		{
			if (GetPlayerWeaponSlot(client, 2) < 1)
			{
				GivePlayerItem(client, "weapon_knife", 0);
			}
		}
		if (StrEqual(g_sWeapon[client][5], "grenades", false))
		{
			if (!GetPlayerGrenade(client, 11))
			{
				GivePlayerItem(client, "weapon_hegrenade", 0);
			}
			iBuffer = GetPlayerGrenade(client, 12);
			if (g_iGame == GameType:3)
			{
				if (!iBuffer)
				{
					GivePlayerItem(client, "weapon_flashbang", 0);
				}
			}
			else
			{
				if (!iBuffer)
				{
					GivePlayerItem(client, "weapon_flashbang", 0);
					SetPlayerGrenade(client, 2, 12);
				}
				if (iBuffer == 1)
				{
					SetPlayerGrenade(client, 2, 12);
				}
			}
			if (!GetPlayerGrenade(client, 13))
			{
				GivePlayerItem(client, "weapon_smokegrenade", 0);
			}
		}
		if (StrEqual(g_sWeapon[client][6], "vesthelm", false))
		{
			iBuffer = GetPlayerArmor(client);
			if (!iBuffer)
			{
				GivePlayerItem(client, "item_assaultsuit", 0);
			}
			if (g_bPlayerVip[client][14])
			{
				if (iBuffer != g_iPlayerVip[client][14])
				{
					SetPlayerArmor(client, g_iPlayerVip[client][14]);
				}
			}
			if (iBuffer != 100)
			{
				SetPlayerArmor(client, 100);
			}
		}
		if (g_iClientTeam[client] == 3)
		{
			if (StrEqual(g_sWeapon[client][7], "defuser", false))
			{
				if (!GetPlayerDefuser(client))
				{
					SetPlayerDefuser(client);
				}
			}
		}
		if (StrEqual(g_sWeapon[client][8], "nvgs", false))
		{
			if (!GetPlayerNightVision(client))
			{
				SetPlayerNightVision(client);
			}
		}
	}
	return 0;
}

public GivePlayerItem_Weapon(client, slot, String:buffer[])
{
	decl iBuffer;
	new String:sBuffer[2][64] = "\x08";
	iBuffer = GetPlayerWeaponSlot(client, slot);
	Format(sBuffer[0][sBuffer], 64, "weapon_%s", buffer);
	if (iBuffer > 1)
	{
		GetEdictClassname(iBuffer, sBuffer[1], 64);
		if (!StrEqual(sBuffer[0][sBuffer], sBuffer[1], false))
		{
			RemovePlayerItem(client, iBuffer);
			GivePlayerItem(client, sBuffer[0][sBuffer], 0);
		}
	}
	else
	{
		GivePlayerItem(client, sBuffer[0][sBuffer], 0);
	}
	return 0;
}

public Player_WeaponReload(client)
{
	decl String:sBuffer[24];
	decl iBuffer[3];
	iBuffer[0] = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	if (GetEntityClassname(iBuffer[0], sBuffer, 22))
	{
		if (GetTrieValue(g_hWeaponAmmoTrie, sBuffer, iBuffer[1]))
		{
			iBuffer[2] = GetEntData(iBuffer[0], g_iClip1Offset, 4);
			if (0 < iBuffer[2])
			{
				iBuffer[1] -= iBuffer[2];
			}
			SetEntData(client, GetEntProp(iBuffer[0], PropType:1, "m_iPrimaryAmmoType", 4, 0) * 4 + FindDataMapOffs(client, "m_iAmmo", 0, 0), iBuffer[1], 4, true);
		}
	}
	return 0;
}

public Action:Users_WeaponEquipPost(client, weapon)
{
	decl String:sBuffer[64];
	if (GetEdictClassname(weapon, sBuffer, 64))
	{
		new var1;
		if (StrEqual(sBuffer, "weapon_m4a1", false) && StrEqual(g_sWeapon[client][9], "auto", false) && !GetWeaponSilencer(client, 0))
		{
			SetWeaponSilencer(client, 0);
		}
		new var2;
		if (StrEqual(sBuffer, "weapon_usp", false) && StrEqual(g_sWeapon[client][10], "auto", false) && !GetWeaponSilencer(client, 1))
		{
			SetWeaponSilencer(client, 1);
		}
	}
	return Action:0;
}

public Display_WeaponSettings(client, position)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "????????? ??????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	if (g_iPlayerVip[client][4])
	{
		Format(sBuffer, 100, "??? ?????????: [?????????]", client);
	}
	AddMenuItem(hMenu, "disable", sBuffer, 0);
	Format(sBuffer, 100, "???????? T: [%s]", g_sWeapon[client][2], client);
	AddMenuItem(hMenu, "pistols_t", sBuffer, 0);
	Format(sBuffer, 100, "???????? CT: [%s]", g_sWeapon[client][3], client);
	AddMenuItem(hMenu, "pistols_ct", sBuffer, 0);
	Format(sBuffer, 100, "????????-????????? T: [%s]", g_sWeapon[client][0], client);
	AddMenuItem(hMenu, "machinesshotguns_t", sBuffer, 0);
	Format(sBuffer, 100, "????????-????????? CT: [%s]", g_sWeapon[client][1], client);
	AddMenuItem(hMenu, "machinesshotguns_ct", sBuffer, 0);
	if (StrEqual(g_sWeapon[client][4], "setup", false))
	{
		Format(sBuffer, 100, "???: [??????]", client);
	}
	else
	{
		Format(sBuffer, 100, "???: [????????]", client);
	}
	AddMenuItem(hMenu, "knife", sBuffer, 0);
	AddMenuItem(hMenu, "equipment", "??????????", 0);
	new var1;
	if (g_iGame != GameType:3 && g_bSDKHooksLoaded)
	{
		new var2;
		if (StrEqual(g_sWeapon[client][9], "auto", false) && StrEqual(g_sWeapon[client][10], "auto", false))
		{
			Format(sBuffer, 100, "????????? [m4a1|usp]: [?????????]", client);
		}
		else
		{
			if (StrEqual(g_sWeapon[client][9], "auto", false))
			{
				Format(sBuffer, 100, "????????? [m4a1]: [?????????]", client);
			}
			if (StrEqual(g_sWeapon[client][10], "auto", false))
			{
				Format(sBuffer, 100, "????????? [usp]: [?????????]", client);
			}
			Format(sBuffer, 100, "?????????: [???????]", client);
		}
		AddMenuItem(hMenu, "silencer", sBuffer, 0);
	}
	else
	{
		Format(sBuffer, 100, "????????? [m4a1|usp]: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	if (StrEqual(g_sWeapon[client][11], "drop", false))
	{
		Format(sBuffer, 100, "??????? ??? ??????: [????????]", client);
	}
	else
	{
		Format(sBuffer, 100, "??????? ??? ??????: [?????????]", client);
	}
	AddMenuItem(hMenu, "drop", sBuffer, 0);
	if (g_bReloadAmmo)
	{
		if (StrEqual(g_sWeapon[client][12], "reload", false))
		{
			Format(sBuffer, 100, "??????????? ???????: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "??????????? ???????: [?????????]", client);
		}
		AddMenuItem(hMenu, "reloadammo", sBuffer, 0);
	}
	else
	{
		Format(sBuffer, 100, "??????????? ???????: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenuAtItem(hMenu, client, position, 0);
	return 0;
}

public MenuHandler_WeaponSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (StrEqual(sInfo, "disable", false))
			{
				g_iPlayerVip[client][4] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, "????????? ??????: [?????????]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
			else
			{
				if (StrEqual(sInfo, "pistols_t", false))
				{
					Display_WeaponPistolsSettings(client, sInfo, 2);
				}
				if (StrEqual(sInfo, "pistols_ct", false))
				{
					Display_WeaponPistolsSettings(client, sInfo, 3);
				}
				if (StrEqual(sInfo, "machinesshotguns_t", false))
				{
					Display_WeaponMachinesShotgunsSettings(client, sInfo, 2);
				}
				if (StrEqual(sInfo, "machinesshotguns_ct", false))
				{
					Display_WeaponMachinesShotgunsSettings(client, sInfo, 3);
				}
				if (StrEqual(sInfo, "knife", false))
				{
					if (StrEqual(g_sWeapon[client][4], "setup", false))
					{
						strcopy(g_sWeapon[client][4], 64, "none");
						VipPrint(client, "????????? ????: [????????]");
					}
					else
					{
						strcopy(g_sWeapon[client][4], 64, "setup");
						VipPrint(client, "????????? ????: [??????]");
					}
					g_bSettingsChanged[client] = 1;
					Display_WeaponSettings(client, 0);
				}
				if (StrEqual(sInfo, "equipment", false))
				{
					Display_WeaponEquipMentSettings(client);
				}
				if (StrEqual(sInfo, "silencer", false))
				{
					Display_WeaponSilencerSettings(client);
				}
				if (StrEqual(sInfo, "drop", false))
				{
					if (StrEqual(g_sWeapon[client][11], "drop", false))
					{
						strcopy(g_sWeapon[client][11], 64, "no");
						VipPrint(client, "??????? ??? ??????: [?????????]");
					}
					else
					{
						strcopy(g_sWeapon[client][11], 64, "drop");
						VipPrint(client, "??????? ??? ??????: [????????]");
					}
					g_bSettingsChanged[client] = 1;
					Display_WeaponSettings(client, GetMenuSelectionPosition());
				}
				if (StrEqual(sInfo, "reloadammo", false))
				{
					if (StrEqual(g_sWeapon[client][12], "reload", false))
					{
						strcopy(g_sWeapon[client][12], 64, "no");
						VipPrint(client, "??????????? ???????: [?????????]");
					}
					else
					{
						strcopy(g_sWeapon[client][12], 64, "reload");
						VipPrint(client, "??????????? ???????: [????????]");
					}
					g_bSettingsChanged[client] = 1;
					Display_WeaponSettings(client, GetMenuSelectionPosition());
				}
			}
		}
	}
	return 0;
}

public Display_WeaponPistolsSettings(client, String:sTeam[], iTeam)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponPistolsSettings, MenuAction:28);
	decl String:sBuffer[100];
	if (iTeam == 2)
	{
		Format(sBuffer, 100, "????????? ?????? T: [?????????]", client);
	}
	else
	{
		if (iTeam == 3)
		{
			Format(sBuffer, 100, "????????? ?????? CT: [?????????]", client);
		}
	}
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "%s_none", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [?? ?????????????]", 0);
	Format(sBuffer, 100, "%s_glock", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [glock]", 0);
	Format(sBuffer, 100, "%s_usp", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [usp]", 0);
	Format(sBuffer, 100, "%s_p228", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [p228]", 0);
	Format(sBuffer, 100, "%s_deagle", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [deagle]", 0);
	Format(sBuffer, 100, "%s_elite", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [elite]", 0);
	Format(sBuffer, 100, "%s_fiveseven", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [fiveseven]", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_WeaponPistolsSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_WeaponSettings(client, 0);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (StrContains(sBuffer, "pistols_t_", false) != -1)
			{
				ReplaceString(sBuffer, 128, "pistols_t_", "", true);
				strcopy(g_sWeapon[client][2], 64, sBuffer);
				VipPrint(client, "??????????? ?????? [%s] ??? ??????? '?????????'", g_sWeapon[client][2]);
			}
			else
			{
				if (StrContains(sBuffer, "pistols_ct_", false) != -1)
				{
					ReplaceString(sBuffer, 128, "pistols_ct_", "", true);
					strcopy(g_sWeapon[client][3], 64, sBuffer);
					VipPrint(client, "??????????? ?????? [%s] ??? ??????? '???????'", g_sWeapon[client][3]);
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_WeaponSettings(client, 0);
		}
	}
	return 0;
}

public Display_WeaponMachinesShotgunsSettings(client, String:sTeam[], iTeam)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponMachinesShotgunsSettings, MenuAction:28);
	decl String:sBuffer[100];
	if (iTeam == 2)
	{
		Format(sBuffer, 100, "????????? ?????? T: [????????-?????????]", client);
	}
	else
	{
		if (iTeam == 3)
		{
			Format(sBuffer, 100, "????????? ?????? CT: [????????-?????????]", client);
		}
	}
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "%s_none", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????-?????????: [?? ?????????????]", 0);
	Format(sBuffer, 100, "%s_ak47", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [ak47]", 0);
	Format(sBuffer, 100, "%s_m4a1", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [m4a1]", 0);
	Format(sBuffer, 100, "%s_galil", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [galil]", 0);
	Format(sBuffer, 100, "%s_sg552", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [sg552]", 0);
	Format(sBuffer, 100, "%s_aug", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [aug]", 0);
	Format(sBuffer, 100, "%s_awp", sTeam);
	AddMenuItem(hMenu, sBuffer, "?????????: [awp]", 0);
	Format(sBuffer, 100, "%s_g3sg1", sTeam);
	AddMenuItem(hMenu, sBuffer, "?????????: [g3sg1]", 0);
	Format(sBuffer, 100, "%s_sg550", sTeam);
	AddMenuItem(hMenu, sBuffer, "?????????: [sg550]", 0);
	Format(sBuffer, 100, "%s_mac10", sTeam);
	AddMenuItem(hMenu, sBuffer, "????-????????: [mac10]", 0);
	Format(sBuffer, 100, "%s_tmp", sTeam);
	AddMenuItem(hMenu, sBuffer, "????-????????: [tmp]", 0);
	Format(sBuffer, 100, "%s_mp5navy", sTeam);
	AddMenuItem(hMenu, sBuffer, "????-????????: [mp5navy]", 0);
	Format(sBuffer, 100, "%s_ump45", sTeam);
	AddMenuItem(hMenu, sBuffer, "????-????????: [ump45]", 0);
	Format(sBuffer, 100, "%s_p90", sTeam);
	AddMenuItem(hMenu, sBuffer, "????-????????: [p90]", 0);
	Format(sBuffer, 100, "%s_m249", sTeam);
	AddMenuItem(hMenu, sBuffer, "???????: [m249]", 0);
	Format(sBuffer, 100, "%s_m3", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [m3]", 0);
	Format(sBuffer, 100, "%s_xm1014", sTeam);
	AddMenuItem(hMenu, sBuffer, "????????: [xm1014]", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_WeaponMachinesShotgunsSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_WeaponSettings(client, 0);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (StrContains(sBuffer, "machinesshotguns_t_", false) != -1)
			{
				ReplaceString(sBuffer, 128, "machinesshotguns_t_", "", true);
				strcopy(g_sWeapon[client][0], 64, sBuffer);
				VipPrint(client, "??????????? ?????? [%s] ??? ??????? '?????????'", g_sWeapon[client][0]);
			}
			else
			{
				if (StrContains(sBuffer, "machinesshotguns_ct_", false) != -1)
				{
					ReplaceString(sBuffer, 128, "machinesshotguns_ct_", "", true);
					strcopy(g_sWeapon[client][1], 64, sBuffer);
					VipPrint(client, "??????????? ?????? [%s] ??? ??????? '???????'", g_sWeapon[client][1]);
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_WeaponSettings(client, 0);
		}
	}
	return 0;
}

public Display_WeaponEquipMentSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponEquipMentSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "??????????: [?c?a?o??a]", client);
	SetMenuTitle(hMenu, sBuffer);
	if (StrEqual(g_sWeapon[client][5], "none", false))
	{
		Format(sBuffer, 100, "???????: [?????????]", client);
	}
	else
	{
		Format(sBuffer, 100, "???????: [????????]", client);
	}
	AddMenuItem(hMenu, "grenades", sBuffer, 0);
	if (StrEqual(g_sWeapon[client][6], "none", false))
	{
		Format(sBuffer, 100, "??????????: [?????????]", client);
	}
	else
	{
		Format(sBuffer, 100, "??????????: [????????]", client);
	}
	AddMenuItem(hMenu, "vesthelm", sBuffer, 0);
	if (StrEqual(g_sWeapon[client][7], "none", false))
	{
		Format(sBuffer, 100, "?????? ???: [?????????]", client);
	}
	else
	{
		Format(sBuffer, 100, "?????? ???: [????????]", client);
	}
	AddMenuItem(hMenu, "defuser", sBuffer, 0);
	if (StrEqual(g_sWeapon[client][8], "none", false))
	{
		Format(sBuffer, 100, "O??? Ho??o?o ?pe???: [B?????e?o]", client);
	}
	else
	{
		Format(sBuffer, 100, "O??? Ho??o?o ?pe???: [B????e?o]", client);
	}
	AddMenuItem(hMenu, "nvgs", sBuffer, 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_WeaponEquipMentSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_WeaponSettings(client, 0);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[100];
			GetMenuItem(hMenu, param, sBuffer, 100, 0, "", 0);
			if (StrEqual(sBuffer, "grenades", false))
			{
				if (StrEqual(g_sWeapon[client][5], "grenades", false))
				{
					strcopy(g_sWeapon[client][5], 64, "none");
					VipPrint(client, "????????? ??????: [?????????]");
				}
				else
				{
					strcopy(g_sWeapon[client][5], 64, "grenades");
					VipPrint(client, "????????? ??????: [????????]");
				}
			}
			else
			{
				if (StrEqual(sBuffer, "vesthelm", false))
				{
					if (StrEqual(g_sWeapon[client][6], "vesthelm", false))
					{
						strcopy(g_sWeapon[client][6], 64, "none");
						VipPrint(client, "????????? ??????????: [?????????]");
					}
					else
					{
						strcopy(g_sWeapon[client][6], 64, "vesthelm");
						VipPrint(client, "????????? ??????????: [????????]");
					}
				}
				if (StrEqual(sBuffer, "defuser", false))
				{
					if (StrEqual(g_sWeapon[client][7], "defuser", false))
					{
						strcopy(g_sWeapon[client][7], 64, "none");
						VipPrint(client, "????????? ????????: [?????????]");
					}
					else
					{
						strcopy(g_sWeapon[client][7], 64, "defuser");
						VipPrint(client, "????????? ????????: [????????]");
					}
				}
				if (StrEqual(sBuffer, "nvgs", false))
				{
					if (StrEqual(g_sWeapon[client][8], "nvgs", false))
					{
						strcopy(g_sWeapon[client][8], 64, "none");
						VipPrint(client, "????????? ????? ??????? ???????: [?????????]");
					}
					strcopy(g_sWeapon[client][8], 64, "nvgs");
					VipPrint(client, "????????? ????? ??????? ???????: [????????]");
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_WeaponSettings(client, 0);
		}
	}
	return 0;
}

public Display_WeaponSilencerSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponSilencerSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "????????? [m4a1|usp]: [?c?a?o??a]", client);
	SetMenuTitle(hMenu, sBuffer);
	if (StrEqual(g_sWeapon[client][9], "auto", false))
	{
		Format(sBuffer, 100, "???? ????????? [m4a1]: [????????]", client);
		AddMenuItem(hMenu, "m4a1_manually", sBuffer, 0);
	}
	else
	{
		Format(sBuffer, 100, "???? ????????? [m4a1]: [?????????]", client);
		AddMenuItem(hMenu, "m4a1_auto", sBuffer, 0);
	}
	if (StrEqual(g_sWeapon[client][10], "auto", false))
	{
		Format(sBuffer, 100, "???? ????????? [usp]: [????????]", client);
		AddMenuItem(hMenu, "usp_manually", sBuffer, 0);
	}
	else
	{
		Format(sBuffer, 100, "???? ????????? [usp]: [?????????]", client);
		AddMenuItem(hMenu, "usp_auto", sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_WeaponSilencerSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_WeaponSettings(client, 0);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[100];
			GetMenuItem(hMenu, param, sBuffer, 100, 0, "", 0);
			if (StrEqual(sBuffer, "m4a1_auto", false))
			{
				strcopy(g_sWeapon[client][9], 64, "auto");
				if (!g_bClientWeaponEquip[client])
				{
					SDKHook(client, SDKHookType:32, Users_WeaponEquipPost);
					g_bClientWeaponEquip[client] = 1;
				}
				VipPrint(client, "????????? ????????? ??? [m4a1]: [?????????????]");
			}
			else
			{
				if (StrEqual(sBuffer, "m4a1_manually", false))
				{
					strcopy(g_sWeapon[client][9], 64, "manually");
					new var1;
					if (g_bClientWeaponEquip[client] && StrEqual(g_sWeapon[client][10], "manually", false))
					{
						SDKUnhook(client, SDKHookType:32, Users_WeaponEquipPost);
						g_bClientWeaponEquip[client] = 0;
					}
					VipPrint(client, "????????? ????????? ??? [m4a1]: [???????]");
				}
				if (StrEqual(sBuffer, "usp_auto", false))
				{
					strcopy(g_sWeapon[client][10], 64, "auto");
					new var2;
					if (!g_bClientWeaponEquip[client] && StrEqual(g_sWeapon[client][9], "manually", false))
					{
						SDKHook(client, SDKHookType:32, Users_WeaponEquipPost);
						g_bClientWeaponEquip[client] = 1;
					}
					VipPrint(client, "????????? ????????? ??? [usp]: [?????????????]");
				}
				if (StrEqual(sBuffer, "usp_manually", false))
				{
					strcopy(g_sWeapon[client][10], 64, "manually");
					new var3;
					if (g_bClientWeaponEquip[client] && StrEqual(g_sWeapon[client][9], "manually", false))
					{
						SDKUnhook(client, SDKHookType:32, Users_WeaponEquipPost);
						g_bClientWeaponEquip[client] = 0;
					}
					VipPrint(client, "????????? ?????????? ??? [usp]: [???????]");
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_WeaponSilencerSettings(client);
		}
	}
	return 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new var1;
	if (g_bPlayerVip[client][8] && g_iPlayerVip[client][8] && g_bPlayerAlive[client] && buttons & 2 && !GetEntityFlags(client) & 1 && GetEntData(client, g_iWaterLevelOffset, 4) < 2 && !GetEntityMoveType(client) & 9)
	{
		buttons = buttons & -3;
	}
	return Action:0;
}

public Cash_OnPluginStart()
{
	RegConsoleCmd("vip_cash", SetCash_Cmd, "vip_cash 16000", 0);
	return 0;
}

public Action:SetCash_Cmd(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][3])
		{
			decl String:sBuffer[8];
			decl iAmount;
			GetCmdArgString(sBuffer, 8);
			iAmount = StringToInt(sBuffer, 10);
			new var1;
			if (args > 0 && iAmount > 0)
			{
				if (iAmount != GetPlayerMoney(client))
				{
					if (iAmount > 16000)
					{
						SetPlayerMoney(client, 16000);
					}
					SetPlayerMoney(client, iAmount);
				}
				g_iPlayerVip[client][3] = iAmount;
				g_bSettingsChanged[client] = 1;
			}
			else
			{
				ReplyToCommand(client, "\x04[VIP]\x01 ????????? ????? \"vip_cash 16000\"");
			}
		}
		VipPrintError(client, "??? ?? ???????? ????????? ?????!");
	}
	return Action:3;
}

public PlayerSpawn_Cash(client)
{
	if (GetPlayerMoney(client) < g_iPlayerVip[client][3])
	{
		SetPlayerMoney(client, g_iPlayerVip[client][3]);
	}
	return 0;
}

public Display_SpawnCashSettings(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnCashSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "?????? ??? ??????: [?????????]", client);
	SetMenuTitle(menu, sBuffer);
	AddMenuItem(menu, "0", "?????? ??? ??????: [?????????]", 0);
	AddMenuItem(menu, "16000", "??????: [16000$]", 0);
	AddMenuItem(menu, "15000", "??????: [15000$]", 0);
	AddMenuItem(menu, "14000", "??????: [14000$]", 0);
	AddMenuItem(menu, "13000", "??????: [13000$]", 0);
	AddMenuItem(menu, "12000", "??????: [12000$]", 0);
	AddMenuItem(menu, "11000", "??????: [11000$]", 0);
	AddMenuItem(menu, "10000", "??????: [10000$]", 0);
	AddMenuItem(menu, "9000", "??????: [9000$]", 0);
	AddMenuItem(menu, "8000", "??????: [8000$]", 0);
	AddMenuItem(menu, "7000", "??????: [7000$]", 0);
	AddMenuItem(menu, "6000", "??????: [6000$]", 0);
	AddMenuItem(menu, "5000", "??????: [5000$]", 0);
	AddMenuItem(menu, "4000", "??????: [4000$]", 0);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public MenuHandler_SpawnCashSettings(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(menu, param, sInfo, 32, 0, "", 0);
			g_iPlayerVip[client][3] = StringToInt(sInfo, 10);
			g_bSettingsChanged[client] = 1;
			if (StrEqual(sInfo, "0", false))
			{
				VipPrint(client, "?????? ??? ??????: [?????????]");
			}
			else
			{
				VipPrint(client, "?????? ??? ??????: [%s$]", sInfo);
			}
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
	}
	return 0;
}

ParsFile(String:file[], Handle:Trie, option)
{
	new String:sLine[256];
	new String:sBuffer[256];
	new Handle:hFile = OpenFile(file, "r");
	if (hFile)
	{
		while (!IsEndOfFile(hFile))
		{
			if (ReadFileLine(hFile, sLine, 256))
			{
				new iPos = StrContains(sLine, "//", true);
				if (iPos != -1)
				{
					sLine[iPos] = MissingTAG:0;
				}
				iPos = StrContains(sLine, "#", true);
				if (iPos != -1)
				{
					sLine[iPos] = MissingTAG:0;
				}
				iPos = StrContains(sLine, ";", true);
				if (iPos != -1)
				{
					sLine[iPos] = MissingTAG:0;
				}
				TrimString(sLine);
				if (sLine[0])
				{
					if (option == 1)
					{
						SetTrieValue(Trie, sLine, any:1, true);
					}
					else
					{
						if (option == 2)
						{
							if (FileExists(sLine, false))
							{
								AddFileToDownloadsTable(sLine);
							}
							else
							{
								if (DirExists(sLine))
								{
									new Handle:hDir = OpenDirectory(sLine);
									while (ReadDirEntry(hDir, sBuffer, 256, 0))
									{
										new var1;
										if (!(StrEqual(sBuffer, ".", false) || StrEqual(sBuffer, "..", false) || StrContains(sLine, ".ztmp", true) == -1))
										{
											Format(sBuffer, 256, "%s/%s", sLine, sBuffer);
											if (FileExists(sBuffer, false))
											{
												AddFileToDownloadsTable(sBuffer);
											}
											else
											{
												Vip_Log("File '%s' not found!", sBuffer);
											}
										}
									}
									CloseHandle(hDir);
								}
							}
						}
						new var2;
						if (option == 3 && StrEqual(g_sMap, sLine, false))
						{
							g_bMapsNoGiveWeapons = true;
							CloseHandle(hFile);
						}
					}
				}
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		g_bBetaTest = false;
		Vip_Log("%s not parsed... file doesn't exist!", file);
	}
	return 0;
}

public Action:Timer_TeamKill(Handle:timer, any:client)
{
	new var1;
	if (IsClientInGame(client) && IsClientInGame(g_iTarget[client]))
	{
		new Handle:menu = CreateMenu(MenuHandler_TeamKill, MenuAction:28);
		decl String:sBuffer[100];
		Format(sBuffer, 100, "????????? %N.", g_iTarget[client], client);
		SetMenuTitle(menu, sBuffer);
		SetMenuExitBackButton(menu, true);
		AddMenuItem(menu, "kill", "?????", 0);
		AddMenuItem(menu, "killrespawn", "????? ? ???????????", 0);
		AddMenuItem(menu, "msg", "???????? ??? \"?????!\"", 0);
		DisplayMenu(menu, client, 0);
	}
	return Action:4;
}

public MenuHandler_TeamKill(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				return 0;
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			new Float:fPos[2][3] = {3.85186E-34,2.5243549E-29};
			GetMenuItem(menu, param, sInfo, 32, 0, "", 0);
			if (IsClientInGame(g_iTarget[client]))
			{
				if (StrEqual(sInfo, "kill", false))
				{
					if (g_bPlayerAlive[g_iTarget[client]])
					{
						ForcePlayerSuicide(g_iTarget[client]);
						VipPrint(client, "????? %N ????.", g_iTarget[client]);
					}
					else
					{
						VipPrint(client, "????? %N ??? ?????!", g_iTarget[client]);
					}
				}
				else
				{
					if (StrEqual(sInfo, "killrespawn", false))
					{
						if (g_bPlayerAlive[g_iTarget[client]])
						{
							GetClientAbsOrigin(g_iTarget[client], fPos[1]);
							fPos[0][fPos] = fPos[1];
							fPos[0][fPos][1] = fPos[1][1];
							fPos[0][fPos][2] = fPos[1][2] + 1000.0;
							TE_SetupBeamPoints(fPos[0][fPos], fPos[1], g_iSetupBeam[1], g_iSetupBeam[1], 0, 20, 0.5, 40.0, 10.0, 1, 20.0, 178920, 250);
							TE_SendToAll(0.0);
							EmitAmbientSound("ambient/explosions/explode_8.wav", fPos[1], 0, 75, 0, 1.0, 100, 0.0);
							ForcePlayerSuicide(g_iTarget[client]);
							VipPrint(client, "????? %N ????.", g_iTarget[client]);
						}
						else
						{
							VipPrint(client, "????? %N ??? ?????!", g_iTarget[client]);
						}
						CS_RespawnPlayer(client);
						CreateTimer(0.18, TeleportTimer, client, 0);
					}
					if (StrEqual(sInfo, "msg", false))
					{
						VipPrintError(g_iTarget[client], "?????????????????????????????????????????!");
					}
				}
			}
			else
			{
				VipPrintError(client, "?????? ????? ????? ???????!");
			}
		}
	}
	return 0;
}

public Action:TeleportTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		TeleportEntity(client, g_fTeamKill[client], NULL_VECTOR, NULL_VECTOR);
		VipPrint(client, "?? ??????????????? ?? ????? ??????.");
	}
	return Action:4;
}

public Menu_OnPluginStart()
{
	new Handle:hTopMenu;
	RegConsoleCmd("vip", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vip_menu", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vipmenu", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vip_settings", Display_MenuCmd, "VIP Menu", 0);
	new var1;
	if (LibraryExists("adminmenu") && (hTopMenu = GetAdminTopMenu()))
	{
		OnAdminMenuCreated(hTopMenu);
		OnAdminMenuReady(hTopMenu);
	}
	return 0;
}

public OnAdminMenuCreated(Handle:hTopMenu)
{
	if (!((obj_vipcmds = FindTopMenuCategory(hTopMenu, "vip_admin_menu"))))
	{
		obj_vipcmds = AddToTopMenu(hTopMenu, "vip_admin_menu", TopMenuObjectType:0, Handle_Commands, TopMenuObject:0, "VipCommandsOverride", 16384, "?????????? ???????? [VIP]");
	}
	return 0;
}

public Handle_Commands(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction:1)
	{
		if (object_id)
		{
			if (obj_vipcmds == object_id)
			{
				FormatEx(buffer, maxlength, "?????????? ????????: [Very Important Person]");
			}
		}
		else
		{
			FormatEx(buffer, maxlength, "%T:", "Admin Menu", client);
		}
	}
	else
	{
		if (!action)
		{
			if (obj_vipcmds == object_id)
			{
				FormatEx(buffer, maxlength, "?????????? ???????? [VIP]");
			}
		}
	}
	return 0;
}

public OnAdminMenuReady(Handle:hTopMenu)
{
	if (hTopMenu == g_hTopMenu)
	{
		return 0;
	}
	g_hTopMenu = hTopMenu;
	new TopMenuObject:MenuObject = FindTopMenuCategory(hTopMenu, "vip_admin_menu");
	if (MenuObject)
	{
		AddToTopMenu(g_hTopMenu, "vip_users_add", TopMenuObjectType:1, Handle_MenuEditAdd, MenuObject, "vip_users_add", 16384, "");
		AddToTopMenu(g_hTopMenu, "vip_users_list", TopMenuObjectType:1, Handle_MenuShowUsers, MenuObject, "vip_users_list", 16384, "");
	}
	return 0;
}

public Handle_MenuEditAdd(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	decl iBuffer;
	if (action)
	{
		if (action == TopMenuAction:2)
		{
			if (!g_bBetaTest)
			{
				VipPrintError(client, "?? ???? ?? ???????!? [\x040_0\x01] ? ??? ?? ???????? ??????????... ???????!");
				DisplayTopMenu(g_hTopMenu, client, TopMenuPosition:3);
				return 0;
			}
			if (GetTrieSize(g_hAdminsTrie[2]))
			{
				if (GetTrieValue(g_hAdminsTrie[2], g_sClientAuth[client][0], iBuffer))
				{
					Display_AddEdit(client);
				}
				else
				{
					VipPrintError(client, "? ??? ??? ???????!");
					DisplayTopMenu(g_hTopMenu, client, TopMenuPosition:3);
				}
			}
			Display_AddEdit(client);
		}
	}
	else
	{
		Format(buffer, maxlength, "????????/????????????? [VIP] ??????", client);
	}
	return 0;
}

public Handle_MenuShowUsers(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action)
	{
		if (action == TopMenuAction:2)
		{
			if (!g_bBetaTest)
			{
				ReplyToCommand(client, "\x04[\x01VIP\x04]\x01 ?? ???? ?? ???????!? [\x040_0\x01] ? ??? ?? ???????? ??????????... ???????!");
				DisplayTopMenu(g_hTopMenu, client, TopMenuPosition:3);
				return 0;
			}
			KvRewind(g_hKvUsers);
			if (KvGotoFirstSubKey(g_hKvUsers, false))
			{
				new String:sBuffer[4][128] = "";
				do {
					KvGetString(g_hKvUsers, "name", sBuffer[0][sBuffer], 128, "none");
					KvGetSectionName(g_hKvUsers, sBuffer[1], 128);
					KvGetString(g_hKvUsers, "group", sBuffer[2], 128, "none");
					if (StrEqual(sBuffer[2], "none", false))
					{
						KvGetString(g_hKvUsers, "flags", sBuffer[2], 128, "none");
						Format(sBuffer[2], 128, "Flags: [%s]", sBuffer[2]);
					}
					else
					{
						Format(sBuffer[2], 128, "Group: [%s]", sBuffer[2]);
					}
					KvGetString(g_hKvUsers, "expires", sBuffer[3], 128, "never");
					if (!StrEqual(sBuffer[3], "never", false))
					{
						FormatTime(sBuffer[3], 128, "%d.%m.%Y : %H.%M.%S", StringToInt(sBuffer[3], 10));
					}
					ReplyToCommand(client, "\x04[VIP]\x01 (%s) (%s) %s Expires: [%s]", sBuffer[0][sBuffer], sBuffer[1], sBuffer[2], sBuffer[3]);
				} while (KvGotoNextKey(g_hKvUsers, false));
			}
			else
			{
				VipPrintError(client, "???? ?????!");
			}
			DisplayTopMenu(g_hTopMenu, client, TopMenuPosition:3);
		}
	}
	else
	{
		Format(buffer, maxlength, "???????? [VIP] ???????", client);
	}
	return 0;
}

public Action:Display_MenuCmd(client, args)
{
	if (client)
	{
		if (IsClientVip(client))
		{
			if (g_hTopMenu)
			{
				Display_Menu(client);
			}
			else
			{
				VipPrintError(client, "????????! ???? ???????? ??????????!");
			}
		}
		else
		{
			VipPrintError(client, "? ??? ??? ???????!");
		}
	}
	else
	{
		ReplyToCommand(client, "[VIP] Available only to players!");
	}
	return Action:3;
}

public Display_Menu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_MenuSettings, MenuAction:28);
	decl String:sBuffer[100];
	if (StrEqual(g_sUsersExpires[client], "never", true))
	{
		Format(sBuffer, 100, "Me??: [Very Important Person] (%s)", "beta_0.0.5", client);
	}
	else
	{
		FormatTime(sBuffer, 100, "%d.%m.%Y : %H.%M.%S", StringToInt(g_sUsersExpires[client], 10));
		Format(sBuffer, 100, "Me??: [VIP] ?o [%s]", sBuffer, client);
	}
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "settings", "????????? [VIP]", 0);
	if (g_bSettingsChanged[client])
	{
		AddMenuItem(hMenu, "settings_save", "????????? ????????? [VIP]", 0);
	}
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_MenuSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_Menu(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (StrEqual(sInfo, "settings", false))
			{
				g_iUsersMenuPosition[client] = 0;
				Display_MenuSettings(client, 0);
			}
			else
			{
				if (StrEqual(sInfo, "settings_save", false))
				{
					UsersSettingsSave(client);
					Display_Menu(client);
				}
			}
		}
	}
	return 0;
}

public Display_AddEdit(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_VipMenuAddEdit, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "????????, ????????????? [VIP]:", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "vip_addserv", "???????? ? ???????", 0);
	AddMenuItem(hMenu, "vip_editbase", "????????????? ?? ????", 0);
	AddMenuItem(hMenu, "vip_del", "??????? ?? ????", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_VipMenuAddEdit(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				new var1;
				if (param == -6 && g_hTopMenu)
				{
					DisplayTopMenu(g_hTopMenu, client, TopMenuPosition:3);
				}
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (StrEqual(sInfo, "vip_addserv", false))
			{
				Display_UsersAdd(client, true);
			}
			else
			{
				if (StrEqual(sInfo, "vip_editbase", false))
				{
					Display_UsersEditBase(client);
				}
				if (StrEqual(sInfo, "vip_del", false))
				{
					Display_UsersDelete(client);
				}
			}
		}
	}
	return 0;
}

public Display_UsersEditBase(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_MenuEditBase, MenuAction:28);
	new String:sBuffer[2][128] = "\x08";
	Format(sBuffer[0][sBuffer], 128, "????????????? VIP ??????:", client);
	SetMenuTitle(hMenu, sBuffer[0][sBuffer]);
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		do {
			KvGetSectionName(g_hKvUsers, sBuffer[0][sBuffer], 128);
			KvGetString(g_hKvUsers, "name", sBuffer[1], 128, "none");
			if (!StrEqual(sBuffer[1], "none", false))
			{
				AddMenuItem(hMenu, sBuffer[0][sBuffer], sBuffer[1], 0);
			}
		} while (KvGotoNextKey(g_hKvUsers, false));
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		CloseHandle(hMenu);
		VipPrintError(client, "???? ?????!");
		Display_AddEdit(client);
	}
	return 0;
}

public MenuHandler_MenuEditBase(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_AddEdit(client);
			}
		}
		if (action == MenuAction:4)
		{
			GetMenuItem(hMenu, param, g_sVipFlags[client][3], 64, 0, "", 0);
			if (!isEditBaseTarget(client))
			{
				VipPrintError(client, "??????!");
				Display_UsersEditBase(client);
			}
		}
	}
	return 0;
}

public bool:isEditBaseTarget(client)
{
	decl iBuffer;
	decl String:sBuffer[128];
	if (GetTrieValue(g_hUsersTrie, g_sVipFlags[client][3], iBuffer))
	{
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], false))
		{
			KvGetString(g_hKvUsers, "name", g_sVipFlags[client][0], 64, "");
			KvGetString(g_hKvUsers, "group", sBuffer, 128, "");
			if (GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer))
			{
				KvRewind(g_hKvUsersGroups);
				if (KvJumpToKey(g_hKvUsersGroups, sBuffer, false))
				{
					KvGetString(g_hKvUsersGroups, "flags", g_sVipFlags[client][1], 64, "");
				}
			}
			else
			{
				KvGetString(g_hKvUsers, "flags", g_sVipFlags[client][1], 64, "");
			}
			strcopy(g_sVipFlags[client][2], 64, g_sVipFlags[client][1]);
			Display_EditBaseTarget(client);
			return true;
		}
	}
	return false;
}

public Display_EditBaseTarget(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_MenuEditBaseTarget, MenuAction:28);
	decl String:sBuffer[128];
	if (StrEqual(g_sVipFlags[client][1], g_sVipFlags[client][2], false))
	{
		Format(sBuffer, 128, "????? ???: %s", g_sVipFlags[client][0], client);
		AddMenuItem(hMenu, "groups", "?????????? ?????? [VIP]", 0);
		AddMenuItem(hMenu, "some", "?????????? ???????????? [VIP]", 0);
	}
	else
	{
		Format(sBuffer, 128, "????????? ????? ???: %s?", g_sVipFlags[client][0], client);
		AddMenuItem(hMenu, "save", "?????????", 0);
		AddMenuItem(hMenu, "nosave", "????????", 0);
	}
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_MenuEditBaseTarget(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_UsersEditBase(client);
			}
		}
		if (action == MenuAction:4)
		{
			new String:sBuffer[2][128] = "\x08";
			decl iBuffer[2];
			GetMenuItem(hMenu, param, sBuffer[0][sBuffer], 128, 0, "", 0);
			if (StrEqual(sBuffer[0][sBuffer], "groups", false))
			{
				Display_UsersEditBaseTargetGroups(client);
			}
			else
			{
				if (StrEqual(sBuffer[0][sBuffer], "some", false))
				{
					iBuffer[0] = 0;
					while (iBuffer[0] <= 18)
					{
						g_bPlayerVipEdit[client][iBuffer[0]] = false;
						iBuffer++;
					}
					iBuffer[0] = strlen(g_sVipFlags[client][1]);
					if (iBuffer[0])
					{
						new i;
						while (iBuffer[0] + -1 >= i)
						{
							Format(sBuffer[1], 128, "%c", g_sVipFlags[client][1][i]);
							if (GetTrieValue(g_hUsersFlagsTrie, sBuffer[1], iBuffer[1]))
							{
								g_bPlayerVipEdit[client][iBuffer[1]] = true;
							}
							i++;
						}
					}
					Display_UsersAddTargetSome(client, 0, false);
				}
				if (StrEqual(sBuffer[0][sBuffer], "save", false))
				{
					KvRewind(g_hKvUsers);
					if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], false))
					{
						KvGetString(g_hKvUsers, "group", sBuffer[0][sBuffer], 128, "none");
						if (!StrEqual(sBuffer[0][sBuffer], "none", false))
						{
							KvDeleteKey(g_hKvUsers, "group");
						}
						KvSetString(g_hKvUsers, "flags", g_sVipFlags[client][2]);
						KvRewind(g_hKvUsers);
						new var1 = g_sUsersPath;
						KeyValuesToFile(g_hKvUsers, var1[0][var1]);
						VipPrint(client, "????? ??? %s ???????????.", g_sVipFlags[client][0]);
						ResettingTheFlags(g_sVipFlags[client][3]);
						strcopy(g_sVipFlags[client][0], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][3], 64, NULL_STRING);
						iBuffer[0] = 0;
						while (iBuffer[0] <= 18)
						{
							g_bPlayerVipEdit[client][iBuffer[0]] = false;
							iBuffer++;
						}
						Display_UsersEditBase(client);
					}
				}
				if (StrEqual(sBuffer[0][sBuffer], "nosave", false))
				{
					iBuffer[0] = 0;
					while (iBuffer[0] <= 18)
					{
						g_bPlayerVipEdit[client][iBuffer[0]] = false;
						iBuffer++;
					}
					if (!isEditBaseTarget(client))
					{
						VipPrintError(client, "??????!");
						Display_UsersEditBase(client);
					}
				}
			}
		}
	}
	return 0;
}

public Display_UsersEditBaseTargetGroups(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersEditBaseTargetGroups, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "?????? VIP ???: %s", g_sVipFlags[client][0], client);
	SetMenuTitle(hMenu, sBuffer);
	KvRewind(g_hKvUsersGroups);
	if (KvGotoFirstSubKey(g_hKvUsersGroups, false))
	{
		do {
			KvGetSectionName(g_hKvUsersGroups, sBuffer, 100);
			AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		} while (KvGotoNextKey(g_hKvUsersGroups, false));
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersEditBaseTargetGroups(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_EditBaseTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			new String:sBuffer[2][128] = "\x08";
			GetMenuItem(hMenu, param, sBuffer[0][sBuffer], 128, 0, "", 0);
			KvRewind(g_hKvUsers);
			if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], false))
			{
				KvGetString(g_hKvUsers, "flags", sBuffer[1], 128, "none");
				if (!StrEqual(sBuffer[1], "none", false))
				{
					KvDeleteKey(g_hKvUsers, "flags");
				}
				KvSetString(g_hKvUsers, "group", sBuffer[0][sBuffer]);
				KvRewind(g_hKvUsers);
				new var1 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var1[0][var1]);
				VipPrint(client, "?????? %s ??? %s ???????????.", sBuffer[0][sBuffer], g_sVipFlags[client][0]);
				ResettingTheFlags(g_sVipFlags[client][3]);
				strcopy(g_sVipFlags[client][0], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][3], 64, NULL_STRING);
				Display_UsersEditBase(client);
			}
		}
	}
	return 0;
}

public Display_UsersDelete(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersDelete, MenuAction:28);
	new String:sBuffer[2][100] = "\x08";
	Format(sBuffer[0][sBuffer], 100, "??????? VIP ??????:", client);
	SetMenuTitle(hMenu, sBuffer[0][sBuffer]);
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		do {
			KvGetSectionName(g_hKvUsers, sBuffer[0][sBuffer], 100);
			KvGetString(g_hKvUsers, "name", sBuffer[1], 100, "none");
			if (!StrEqual(sBuffer[1], "none", false))
			{
				AddMenuItem(hMenu, sBuffer[1], sBuffer[1], 0);
				SetTrieString(g_hUsersDeleteTrie, sBuffer[1], sBuffer[0][sBuffer], true);
			}
		} while (KvGotoNextKey(g_hKvUsers, false));
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		VipPrintError(client, "???? ?????!");
		CloseHandle(hMenu);
		Display_AddEdit(client);
	}
	return 0;
}

public MenuHandler_UsersDelete(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_AddEdit(client);
			}
		}
		if (action == MenuAction:4)
		{
			new String:sBuffer[2][128] = "\x08";
			GetMenuItem(hMenu, param, sBuffer[0][sBuffer], 128, 0, "", 0);
			if (GetTrieString(g_hUsersDeleteTrie, sBuffer[0][sBuffer], sBuffer[1], 128, 0))
			{
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, sBuffer[1], false))
				{
					KvDeleteThis(g_hKvUsers);
					KvRewind(g_hKvUsers);
					new var1 = g_sUsersPath;
					KeyValuesToFile(g_hKvUsers, var1[0][var1]);
					ClearTrie(g_hUsersDeleteTrie);
					RemoveFromTrie(g_hUsersTrie, sBuffer[1]);
					DeleteUserSettings(sBuffer[1]);
					Vip_Log("????? %N (ID: %s | IP: %s) ??????? ?????? (%s | %s) ?? VIP ????.", client, g_sClientAuth[client][0], g_sClientAuth[client][1], sBuffer[0][sBuffer], sBuffer[1]);
					VipPrint(client, "%s ??????? ?????? ?? VIP ????.", sBuffer[0][sBuffer]);
					ResettingTheFlags(sBuffer[1]);
					Display_AddEdit(client);
				}
			}
		}
	}
	return 0;
}

public Display_MenuSettings(client, position)
{
	new Handle:hMenu = CreateMenu(MenuHandler_SettingsChanged, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "Hac?po???: [Very Important Person]", client);
	SetMenuTitle(hMenu, sBuffer);
	if (g_bPlayerVip[client][0])
	{
		if (g_iPlayerVip[client][0])
		{
			Format(sBuffer, 100, "[VIP] ?a?: [Hac?po??a]", client);
		}
		else
		{
			Format(sBuffer, 100, "[VIP] ?a?: [B?????e?o]", client);
		}
		AddMenuItem(hMenu, "chatvip", sBuffer, 0);
	}
	if (g_bPlayerVip[client][1])
	{
		new var1;
		if (g_bModels[0] || g_bModels[1])
		{
			if (g_iPlayerVip[client][1])
			{
				Format(sBuffer, 100, "[VIP] C???: [Hac?po??a]", client);
			}
			else
			{
				Format(sBuffer, 100, "[VIP] C???: [B?????e?]", client);
			}
			AddMenuItem(hMenu, "models", sBuffer, 0);
		}
		Format(sBuffer, 100, "[VIP] C???: [He?oc?y??o!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	if (g_bPlayerVip[client][2])
	{
		if (isUsersStatus(0))
		{
			if (g_iPlayerVip[client][2])
			{
				Format(sBuffer, 100, "[VIP] ??????: [?????????]", client);
			}
			else
			{
				Format(sBuffer, 100, "[VIP] ??????: [????????]", client);
			}
			AddMenuItem(hMenu, "uservip", sBuffer, 0);
		}
		if (g_iGame == GameType:2)
		{
			Format(sBuffer, 100, "[VIP] ??????: [He?oc?y??o!]", client);
			AddMenuItem(hMenu, "", sBuffer, 1);
		}
		if (g_iPlayerVip[client][2])
		{
			Format(sBuffer, 100, "[VIP] ??????: [?????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "[VIP] ??????: [????????]", client);
		}
		AddMenuItem(hMenu, "uservip", sBuffer, 0);
	}
	if (g_bPlayerVip[client][3])
	{
		if (g_iPlayerVip[client][3])
		{
			Format(sBuffer, 100, "?e???? ??? ?????e: [%i$]", g_iPlayerVip[client][3], client);
		}
		else
		{
			Format(sBuffer, 100, "?e???? ??? ?????e: [?????????]", client);
		}
		AddMenuItem(hMenu, "Cash_Settings", sBuffer, 0);
	}
	if (g_bPlayerVip[client][4])
	{
		if (g_bMapsNoGiveWeapons)
		{
			Format(sBuffer, 100, "????????? ??????: [He?oc?y??o!]", client);
			AddMenuItem(hMenu, "", sBuffer, 1);
		}
		if (g_iPlayerVip[client][4])
		{
			Format(sBuffer, 100, "????????? ??????: [?????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "????????? ??????: [?????????]", client);
		}
		AddMenuItem(hMenu, "installing_weapons", sBuffer, 0);
	}
	if (g_bPlayerVip[client][5])
	{
		if (g_iPlayerVip[client][5])
		{
			Format(sBuffer, 100, "????? ???????????: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "????? ???????????: [?????????]", client);
		}
		AddMenuItem(hMenu, "ShowHurt", sBuffer, 0);
	}
	if (g_bPlayerVip[client][6])
	{
		if (g_iPlayerVip[client][6])
		{
			Format(sBuffer, 100, "???????? ?? ???????: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "???????? ?? ???????: [?????????]", client);
		}
		AddMenuItem(hMenu, "NoTeamFlash", sBuffer, 0);
	}
	if (g_bPlayerVip[client][7])
	{
		new var2;
		if (g_bSDKHooksLoaded && g_bFriendLyFire)
		{
			if (g_iPlayerVip[client][7])
			{
				Format(sBuffer, 100, "?o?pe??e??? ?o ?o?a??e: [?????????]", client);
			}
			else
			{
				Format(sBuffer, 100, "?o?pe??e??? ?o ?o?a??e: [B????e??]", client);
			}
			AddMenuItem(hMenu, "nofriendlyfire", sBuffer, 0);
		}
		AddMenuItem(hMenu, "", "?o?pe??e??? ?o ?o?a??e: [He?oc?y??o!]", 1);
	}
	if (g_bPlayerVip[client][8])
	{
		if (g_iPlayerVip[client][8])
		{
			Format(sBuffer, 100, "?????? BunnyHop: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "?????? BunnyHop: [?????????]", client);
		}
		AddMenuItem(hMenu, "BunnyHop", sBuffer, 0);
	}
	if (g_bPlayerVip[client][9])
	{
		if (g_iPlayerVip[client][9])
		{
			Format(sBuffer, 100, "??????????? ? ?4: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "??????????? ? ?4: [?????????]", client);
		}
		AddMenuItem(hMenu, "Spawn_C4", sBuffer, 0);
	}
	if (g_bPlayerVip[client][10])
	{
		if (g_bSDKHooksLoaded)
		{
			if (g_iPlayerVip[client][10])
			{
				Format(sBuffer, 100, "???????? ?????: [????????]", client);
			}
			else
			{
				Format(sBuffer, 100, "???????? ?????: [?????????]", client);
			}
			AddMenuItem(hMenu, "IncreasesDamage", sBuffer, 0);
		}
		Format(sBuffer, 100, "???????? ?????: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	if (g_bPlayerVip[client][11])
	{
		if (g_iPlayerVip[client][11])
		{
			Format(sBuffer, 100, "??????????? HP: [?????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "??????????? HP: [?????????]", client);
		}
		AddMenuItem(hMenu, "Regeneration", sBuffer, 0);
	}
	if (g_bPlayerVip[client][12])
	{
		new var3;
		if (g_bSDKHooksLoaded && g_bFriendLyFire)
		{
			if (g_iPlayerVip[client][12])
			{
				Format(sBuffer, 100, "?e??? ?o ?o?a??e: [B????e?o]", client);
			}
			else
			{
				Format(sBuffer, 100, "?e??? ?o ?o?a??e: [B?????e?o]", client);
			}
			AddMenuItem(hMenu, "Medic", sBuffer, 0);
		}
		AddMenuItem(hMenu, "", "?e??? ?o ?o?a??e: [H??o?????o!]", 1);
	}
	if (g_bPlayerVip[client][13])
	{
		if (g_bSDKHooksLoaded)
		{
			if (g_iPlayerVip[client][13])
			{
				Format(sBuffer, 100, "?o?pe??e??? o? c?oe? ??a?a??: [B?????e?o]", client);
			}
			else
			{
				Format(sBuffer, 100, "?o?pe??e??? o? c?oe? ??a?a??: [B????e?o]", client);
			}
			AddMenuItem(hMenu, "NoDamageMyGrenades", sBuffer, 0);
		}
		Format(sBuffer, 100, "?o?pe??e??? o? c?oe? ??a?a??: [??????????!]", client);
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	if (g_bPlayerVip[client][14])
	{
		if (g_iPlayerVip[client][14] == 100)
		{
			Format(sBuffer, 100, "??????????? ? HP: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "??????????? ? HP: [%i]", g_iPlayerVip[client][14], client);
		}
		AddMenuItem(hMenu, "Health_Settings", sBuffer, 0);
	}
	if (g_bPlayerVip[client][15])
	{
		if (g_iPlayerVip[client][15] == 1)
		{
			Format(sBuffer, 100, "????????? c???????: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "????????? c???????: [x%i]", g_iPlayerVip[client][15], client);
		}
		AddMenuItem(hMenu, "Speed_Settings", sBuffer, 0);
	}
	if (g_bPlayerVip[client][16])
	{
		if (!g_iPlayerVip[client][16])
		{
			Format(sBuffer, 100, "????????? ??????????: [????????]", client);
		}
		else
		{
			switch (g_iPlayerVip[client][16])
			{
				case 1:
				{
					Format(sBuffer, 100, "O?e?? ??co?a?", client);
				}
				case 2:
				{
					Format(sBuffer, 100, "B?co?a?", client);
				}
				case 3:
				{
					Format(sBuffer, 100, "??????????", client);
				}
				case 4:
				{
					Format(sBuffer, 100, "??????????", client);
				}
				case 5:
				{
					Format(sBuffer, 100, "H???a?", client);
				}
				case 6:
				{
					Format(sBuffer, 100, "O?e?? H???a?", client);
				}
				default:
				{
				}
			}
			Format(sBuffer, 100, "????????? ??????????: [%s]", sBuffer, client);
		}
		AddMenuItem(hMenu, "gravity_settings", sBuffer, 0);
	}
	if (g_bPlayerVip[client][17])
	{
		if (g_iPlayerVip[client][17])
		{
			Format(sBuffer, 100, "???????: [????????]", client);
		}
		else
		{
			Format(sBuffer, 100, "???????: [?????????]", client);
		}
		AddMenuItem(hMenu, "effects", sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenuAtItem(hMenu, client, position, 0);
	return 0;
}

public MenuHandler_SettingsChanged(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_Menu(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[256];
			GetMenuItem(hMenu, param, sInfo, 256, 0, "", 0);
			g_iUsersMenuPosition[client] = GetMenuSelectionPosition();
			if (StrEqual(sInfo, "chatvip", false))
			{
				if (!g_iPlayerVip[client][0])
				{
					g_iPlayerVip[client][0] = 2;
					VipPrint(client, "???: [?????e?o]");
					g_bSettingsChanged[client] = 1;
				}
				Display_VipChat(client);
				return 0;
			}
			if (StrEqual(sInfo, "models", false))
			{
				if (g_iPlayerVip[client][1])
				{
					Display_UsersModels(client);
				}
				else
				{
					g_bUsersModels[client][0] = false;
					g_bUsersModels[client][1] = false;
					if (g_iCoutModels[0] != -1)
					{
						GetArrayString(g_hArrayModels[0], 0, sInfo, 256);
						Format(g_sUsersModels[client][0], 256, sInfo);
						g_bUsersModels[client][0] = true;
					}
					if (g_iCoutModels[1] != -1)
					{
						GetArrayString(g_hArrayModels[1], 0, sInfo, 256);
						Format(g_sUsersModels[client][1], 256, sInfo);
						g_bUsersModels[client][1] = true;
					}
					g_iPlayerVip[client][1] = 1;
					VipPrint(client, "????: [???????]");
					g_bSettingsChanged[client] = 1;
					Display_UsersModels(client);
				}
				return 0;
			}
			if (StrEqual(sInfo, "uservip", false))
			{
				if (!g_iPlayerVip[client][2])
				{
					g_iPlayerVip[client][2] = 1;
					new i;
					while (i <= 4)
					{
						g_bUsersStatus[client][i] = true;
						i++;
					}
					if (g_iGame != GameType:2)
					{
						new var1 = g_sUsersClanTag;
						CS_SetClientClanTag(client, var1[0][var1]);
					}
					g_bSettingsChanged[client] = 1;
					VipPrint(client, "??????: [???????]");
				}
				Display_VipStatusSettings(client);
				return 0;
			}
			if (StrEqual(sInfo, "Cash_Settings", false))
			{
				Display_SpawnCashSettings(client);
				return 0;
			}
			if (StrEqual(sInfo, "installing_weapons", false))
			{
				if (!g_iPlayerVip[client][4])
				{
					g_iPlayerVip[client][4] = 1;
					g_bSettingsChanged[client] = 1;
					VipPrint(client, "????????? ??????: [????????]");
				}
				Display_WeaponSettings(client, 0);
				return 0;
			}
			if (StrEqual(sInfo, "ShowHurt", false))
			{
				if (g_iPlayerVip[client][5])
				{
					g_iPlayerVip[client][5] = 0;
					VipPrint(client, "????? ???????????: [?????????]");
				}
				else
				{
					g_iPlayerVip[client][5] = 1;
					VipPrint(client, "????? ???????????: [????????]");
				}
			}
			else
			{
				if (StrEqual(sInfo, "NoTeamFlash", false))
				{
					if (g_iPlayerVip[client][6])
					{
						g_iPlayerVip[client][6] = 0;
						VipPrint(client, "???????? ?? ???????: [????????]");
					}
					else
					{
						g_iPlayerVip[client][6] = 1;
						VipPrint(client, "???????? ?? ???????: [???????]");
					}
				}
				if (StrEqual(sInfo, "nofriendlyfire", false))
				{
					if (!g_iPlayerVip[client][7])
					{
						g_iPlayerVip[client][7] = 2;
						g_bSettingsChanged[client] = 1;
						VipPrint(client, "??????????? ?? ???????: [?????????]");
					}
					Display_NoFriendLyFire(client);
					return 0;
				}
				if (StrEqual(sInfo, "BunnyHop", false))
				{
					if (g_iPlayerVip[client][8])
					{
						g_iPlayerVip[client][8] = 0;
						VipPrint(client, "BunnyHop: [????????]");
					}
					else
					{
						g_iPlayerVip[client][8] = 1;
						VipPrint(client, "BunnyHop: [???????]");
					}
				}
				if (StrEqual(sInfo, "Spawn_C4", false))
				{
					if (g_iPlayerVip[client][9])
					{
						g_iPlayerVip[client][9] = 0;
						VipPrint(client, "??????????? ? ?4: [?????????]");
					}
					else
					{
						g_iPlayerVip[client][9] = 1;
						VipPrint(client, "??????????? ? ?4: [????????]");
					}
				}
				if (StrEqual(sInfo, "IncreasesDamage", false))
				{
					if (g_iPlayerVip[client][10])
					{
						g_iPlayerVip[client][10] = 0;
						VipPrint(client, "???????? ?????: [?????????]");
					}
					else
					{
						g_iPlayerVip[client][10] = 1;
						VipPrint(client, "???????? ?????: [????????]");
					}
				}
				if (StrEqual(sInfo, "Regeneration", false))
				{
					if (!g_iPlayerVip[client][11])
					{
						g_iPlayerVip[client][11] = 2;
						VipPrint(client, "??????????? HP: [????????]");
						g_bSettingsChanged[client] = 1;
					}
					Display_Regeneration(client);
					return 0;
				}
				if (StrEqual(sInfo, "Medic", false))
				{
					if (g_iPlayerVip[client][12])
					{
						g_iPlayerVip[client][12] = 0;
						VipPrint(client, "????? ?? ???????: [????????]");
					}
					else
					{
						g_iPlayerVip[client][12] = 1;
						VipPrint(client, "????? ?? ???????: [???????]");
					}
				}
				if (StrEqual(sInfo, "NoDamageMyGrenades", false))
				{
					if (g_iPlayerVip[client][13])
					{
						g_iPlayerVip[client][13] = 0;
						VipPrint(client, "??????????? ?? ????? ???????: [????????]");
					}
					else
					{
						g_iPlayerVip[client][13] = 1;
						VipPrint(client, "??????????? ?? ????? ???????: [?????????]");
					}
				}
				if (StrEqual(sInfo, "Health_Settings", false))
				{
					Display_SpawnHeatlthSettings(client);
					return 0;
				}
				if (StrEqual(sInfo, "Speed_Settings", false))
				{
					Display_SpawnSpeedSettings(client);
					return 0;
				}
				if (StrEqual(sInfo, "gravity_settings", false))
				{
					Display_Gravity(client);
					return 0;
				}
				if (StrEqual(sInfo, "effects", false))
				{
					if (g_iPlayerVip[client][17])
					{
						g_iPlayerVip[client][17] = 0;
						VipPrint(client, "???????: [?????????]");
					}
					g_iPlayerVip[client][17] = 1;
					VipPrint(client, "???????: [????????]");
				}
			}
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			g_bSettingsChanged[client] = 1;
		}
	}
	return 0;
}

public Display_UsersAdd(client, bool:bMsgError)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersAdd, MenuAction:28);
	new String:sBuffer[2][128] = "\x08";
	decl bool:bAddMenuItem;
	Format(sBuffer[0][sBuffer], 128, "?????????? ?????? VIP ??????:", client);
	SetMenuTitle(hMenu, sBuffer[0][sBuffer]);
	bAddMenuItem = false;
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientVip(i) && GetClientName(i, sBuffer[1], 128))
		{
			IntToString(GetClientUserId(i), sBuffer[0][sBuffer], 128);
			AddMenuItem(hMenu, sBuffer[0][sBuffer], sBuffer[1], 0);
			if (!bAddMenuItem)
			{
				bAddMenuItem = true;
			}
		}
		i++;
	}
	if (bAddMenuItem)
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		CloseHandle(hMenu);
		if (bMsgError)
		{
			VipPrintError(client, "?????? ??? VIP ?? ???????.");
		}
		Display_AddEdit(client);
	}
	return 0;
}

public MenuHandler_UsersAdd(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_AddEdit(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[32];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 32, 0, "", 0);
			iBuffer = GetClientOfUserId(StringToInt(sBuffer, 10));
			if (iBuffer < 1)
			{
				VipPrintError(client, "%t", "Player no longer available");
			}
			else
			{
				if (!CanUserTarget(client, iBuffer))
				{
					VipPrintError(client, "%t", "Unable to target");
				}
				strcopy(g_sVipFlags[client][0], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
				strcopy(g_sVipFlags[client][3], 64, NULL_STRING);
				if (GetClientName(iBuffer, g_sVipFlags[client][0], 64))
				{
					g_iTarget[client] = iBuffer;
					DisplayTimeMenu(client);
					return 0;
				}
			}
			Display_UsersAdd(client, true);
		}
	}
	return 0;
}

public DisplayTimeMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_TimeList, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "[VIP]: ?? ????? ??? %s", g_sVipFlags[client][0], client);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	AddMenuItem(hMenu, "never", "??????????", 0);
	AddMenuItem(hMenu, "30", "30 ?????", 0);
	AddMenuItem(hMenu, "60", "1 ???", 0);
	AddMenuItem(hMenu, "120", "2 ????", 0);
	AddMenuItem(hMenu, "180", "3 ????", 0);
	AddMenuItem(hMenu, "240", "4 ????", 0);
	AddMenuItem(hMenu, "300", "5 ?????", 0);
	AddMenuItem(hMenu, "360", "6 ?????", 0);
	AddMenuItem(hMenu, "420", "7 ?????", 0);
	AddMenuItem(hMenu, "480", "8 ?????", 0);
	AddMenuItem(hMenu, "540", "9 ?????", 0);
	AddMenuItem(hMenu, "600", "10 ?????", 0);
	AddMenuItem(hMenu, "660", "11 ?????", 0);
	AddMenuItem(hMenu, "720", "12 ?????", 0);
	AddMenuItem(hMenu, "780", "13 ?????", 0);
	AddMenuItem(hMenu, "840", "14 ?????", 0);
	AddMenuItem(hMenu, "900", "15 ?????", 0);
	AddMenuItem(hMenu, "960", "16 ?????", 0);
	AddMenuItem(hMenu, "1020", "17 ?????", 0);
	AddMenuItem(hMenu, "1080", "18 ?????", 0);
	AddMenuItem(hMenu, "1140", "19 ?????", 0);
	AddMenuItem(hMenu, "1200", "20 ?????", 0);
	AddMenuItem(hMenu, "1260", "21 ???", 0);
	AddMenuItem(hMenu, "1320", "22 ????", 0);
	AddMenuItem(hMenu, "1380", "23 ????", 0);
	AddMenuItem(hMenu, "1440", "1 ????", 0);
	AddMenuItem(hMenu, "2880", "2 ???", 0);
	AddMenuItem(hMenu, "4320", "3 ???", 0);
	AddMenuItem(hMenu, "5760", "4 ???", 0);
	AddMenuItem(hMenu, "7200", "5 ????", 0);
	AddMenuItem(hMenu, "8640", "6 ????", 0);
	AddMenuItem(hMenu, "10080", "1 ??????", 0);
	AddMenuItem(hMenu, "20160", "2 ??????", 0);
	AddMenuItem(hMenu, "30240", "3 ??????", 0);
	AddMenuItem(hMenu, "43829", "1 ?????", 0);
	AddMenuItem(hMenu, "87658", "2 ??????", 0);
	AddMenuItem(hMenu, "131487", "3 ??????", 0);
	AddMenuItem(hMenu, "175316", "4 ??????", 0);
	AddMenuItem(hMenu, "219145", "5 ???????", 0);
	AddMenuItem(hMenu, "262974", "6 ???????", 0);
	AddMenuItem(hMenu, "306803", "7 ???????", 0);
	AddMenuItem(hMenu, "350632", "8 ???????", 0);
	AddMenuItem(hMenu, "394461", "9 ???????", 0);
	AddMenuItem(hMenu, "438290", "10 ???????", 0);
	AddMenuItem(hMenu, "482119", "11 ???????", 0);
	AddMenuItem(hMenu, "525948", "1 ???", 0);
	AddMenuItem(hMenu, "725760", "2 ????", 0);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_TimeList(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			Display_UsersAdd(client, true);
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[32];
			GetMenuItem(hMenu, param, sBuffer, 32, 0, "", 0);
			if (StrEqual(sBuffer, "never", false))
			{
				g_iTargetTime[client] = 0;
			}
			else
			{
				g_iTargetTime[client] = StringToInt(sBuffer, 10) * 60 + GetTime({0,0});
			}
			Display_UsersAddTargetAuth(client);
		}
	}
	return 0;
}

public Display_UsersAddTargetAuth(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersAddTargetAuth, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "??????????? ???: %s", g_sVipFlags[client][0], client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "0", "??????????? ??: SteamID", 0);
	AddMenuItem(hMenu, "1", "??????????? ??: IP", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersAddTargetAuth(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				DisplayTimeMenu(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[8];
			GetMenuItem(hMenu, param, sBuffer, 8, 0, "", 0);
			g_iClientAuth[g_iTarget[client]] = StringToInt(sBuffer, 10);
			Display_UsersAddTarget(client);
		}
	}
	return 0;
}

public Display_UsersAddTarget(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersAddTarget, MenuAction:28);
	decl String:sBuffer[128];
	if (StrEqual(g_sVipFlags[client][1], "", false))
	{
		Format(sBuffer, 128, "????? ???: %s", g_sVipFlags[client][0], client);
		AddMenuItem(hMenu, "groups", "?????????? ?????? [VIP]", 0);
		AddMenuItem(hMenu, "some", "?????????? ???????????? [VIP]", 0);
	}
	else
	{
		Format(sBuffer, 128, "????????? ????? ???: %s?", g_sVipFlags[client][0], client);
		AddMenuItem(hMenu, "save", "?????????", 0);
		AddMenuItem(hMenu, "nosave", "????????", 0);
	}
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersAddTarget(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_UsersAddTargetAuth(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (StrEqual(sBuffer, "groups", false))
			{
				Display_UsersAddTargetGroups(client);
			}
			else
			{
				if (StrEqual(sBuffer, "some", false))
				{
					new i;
					while (i <= 18)
					{
						g_bPlayerVipEdit[client][i] = false;
						i++;
					}
					Display_UsersAddTargetSome(client, 0, true);
				}
				if (StrEqual(sBuffer, "save", false))
				{
					KvRewind(g_hKvUsers);
					new var1;
					if (KvJumpToKey(g_hKvUsers, g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]], true) && IsClientInGame(g_iTarget[client]))
					{
						KvSetString(g_hKvUsers, "name", g_sVipFlags[client][0]);
						if (0 < g_iTargetTime[client])
						{
							Format(sBuffer, 128, "%i", g_iTargetTime[client]);
						}
						else
						{
							strcopy(sBuffer, 128, "never");
						}
						KvSetString(g_hKvUsers, "expires", sBuffer);
						KvGetString(g_hKvUsers, "group", sBuffer, 128, "none");
						if (!StrEqual(sBuffer, "none", false))
						{
							KvDeleteKey(g_hKvUsers, "group");
						}
						KvSetString(g_hKvUsers, "flags", g_sVipFlags[client][1]);
						KvRewind(g_hKvUsers);
						new var2 = g_sUsersPath;
						KeyValuesToFile(g_hKvUsers, var2[0][var2]);
						SetTrieValue(g_hUsersTrie, g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]], any:1, true);
						Vip_Log("????? %N (ID: %s | IP: %s) ??????? ?????? VIP ?????? (%s %s)", client, g_sClientAuth[client][0], g_sClientAuth[client][1], g_sVipFlags[client][0], g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]]);
						VipPrint(client, "????? ??? %s ???????????.", g_sVipFlags[client][0]);
						strcopy(g_sVipFlags[client][0], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
						strcopy(g_sVipFlags[client][3], 64, NULL_STRING);
						ResettingTheFlags(g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]]);
						new i;
						while (i <= 18)
						{
							g_bPlayerVipEdit[client][i] = false;
							i++;
						}
						Display_UsersAdd(client, false);
					}
					else
					{
						VipPrintError(client, "?????? ??????????!");
						Display_UsersAdd(client, true);
					}
					g_iTargetTime[client] = 0;
				}
				if (StrEqual(sBuffer, "nosave", false))
				{
					new i;
					while (i <= 18)
					{
						g_bPlayerVipEdit[client][i] = false;
						i++;
					}
					strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
					strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
					Display_UsersAddTarget(client);
				}
			}
		}
	}
	return 0;
}

public Display_UsersAddTargetGroups(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersAddTargetGroups, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "?????? VIP ???: %s", g_sVipFlags[client][0], client);
	SetMenuTitle(hMenu, sBuffer);
	KvRewind(g_hKvUsersGroups);
	if (KvGotoFirstSubKey(g_hKvUsersGroups, false))
	{
		do {
			KvGetSectionName(g_hKvUsersGroups, sBuffer, 100);
			AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		} while (KvGotoNextKey(g_hKvUsersGroups, false));
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		CloseHandle(hMenu);
		VipPrintError(client, "??????! ???? ????? ?????.");
		Display_UsersAddTarget(client);
	}
	return 0;
}

public MenuHandler_UsersAddTargetGroups(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_UsersAddTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			new String:sBuffer[2][128] = "\x08";
			GetMenuItem(hMenu, param, sBuffer[1], 128, 0, "", 0);
			KvRewind(g_hKvUsers);
			new var1;
			if (KvJumpToKey(g_hKvUsers, g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]], true) && IsClientInGame(g_iTarget[client]))
			{
				KvSetString(g_hKvUsers, "name", g_sVipFlags[client][0]);
				if (0 < g_iTargetTime[client])
				{
					Format(sBuffer[0][sBuffer], 128, "%i", g_iTargetTime[client]);
				}
				else
				{
					strcopy(sBuffer[0][sBuffer], 128, "never");
				}
				KvSetString(g_hKvUsers, "expires", sBuffer[0][sBuffer]);
				KvGetString(g_hKvUsers, "flags", sBuffer[0][sBuffer], 128, "none");
				if (!StrEqual(sBuffer[0][sBuffer], "none", false))
				{
					KvDeleteKey(g_hKvUsers, "flags");
				}
				KvSetString(g_hKvUsers, "group", sBuffer[1]);
				KvRewind(g_hKvUsers);
				new var2 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var2[0][var2]);
				SetTrieValue(g_hUsersTrie, g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]], any:1, true);
				ResettingTheFlags(g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]]);
				Vip_Log("????? %N (ID: %s | IP: %s) ??????? ?????? VIP ?????? %N (??? ???????????: %s)", client, g_sClientAuth[client][0], g_sClientAuth[client][1], g_iTarget[client], g_sClientAuth[g_iTarget[client]][g_iClientAuth[g_iTarget[client]]]);
				VipPrint(client, "?????? %s ??? %N ???????????.", sBuffer[1], g_iTarget[client]);
				Display_UsersAdd(client, false);
			}
			else
			{
				VipPrintError(client, "?????? ??????????!");
				Display_UsersAdd(client, true);
			}
			g_iTargetTime[client] = 0;
		}
	}
	return 0;
}

public Display_UsersAddTargetSome(client, position, bool:edit)
{
	new Handle:hMenu;
	new String:sBuffer[128];
	if (edit)
	{
		hMenu = CreateMenu(MenuHandler_UsersAddTargetSome, MenuAction:28);
	}
	else
	{
		hMenu = CreateMenu(MenuHandler_AddVipBaseTargetSomeMenu, MenuAction:28);
	}
	Format(sBuffer, 128, "????? VIP ???: %s", g_sVipFlags[client][0], client);
	SetMenuTitle(hMenu, sBuffer);
	if (g_bPlayerVipEdit[client][0])
	{
		Format(sBuffer, 128, "VIP Chat [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "VIP Chat [ ]", client);
	}
	AddMenuItem(hMenu, "a", sBuffer, 0);
	if (g_bPlayerVipEdit[client][1])
	{
		Format(sBuffer, 128, "VIP Models [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "VIP Models [ ]", client);
	}
	AddMenuItem(hMenu, "b", sBuffer, 0);
	if (g_bPlayerVipEdit[client][2])
	{
		Format(sBuffer, 128, "VIP Status [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "VIP Status [ ]", client);
	}
	AddMenuItem(hMenu, "c", sBuffer, 0);
	if (g_bPlayerVipEdit[client][3])
	{
		Format(sBuffer, 128, "Cash [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Cash [ ]", client);
	}
	AddMenuItem(hMenu, "d", sBuffer, 0);
	if (g_bPlayerVipEdit[client][4])
	{
		Format(sBuffer, 128, "Give Weapon [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Give Weapon [ ]", client);
	}
	AddMenuItem(hMenu, "e", sBuffer, 0);
	if (g_bPlayerVipEdit[client][5])
	{
		Format(sBuffer, 128, "Show Hurt [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Show Hurt [ ]", client);
	}
	AddMenuItem(hMenu, "f", sBuffer, 0);
	if (g_bPlayerVipEdit[client][6])
	{
		Format(sBuffer, 128, "No Team Flash [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "No Team Flash [ ]", client);
	}
	AddMenuItem(hMenu, "g", sBuffer, 0);
	if (g_bPlayerVipEdit[client][7])
	{
		Format(sBuffer, 128, "No Friendly Fire [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "No Friendly Fire [ ]", client);
	}
	AddMenuItem(hMenu, "h", sBuffer, 0);
	if (g_bPlayerVipEdit[client][8])
	{
		Format(sBuffer, 128, "BunnyHop [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "BunnyHop [ ]", client);
	}
	AddMenuItem(hMenu, "i", sBuffer, 0);
	if (g_bPlayerVipEdit[client][9])
	{
		Format(sBuffer, 128, "Spawn C4 [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Spawn C4 [ ]", client);
	}
	AddMenuItem(hMenu, "j", sBuffer, 0);
	if (g_bPlayerVipEdit[client][10])
	{
		Format(sBuffer, 128, "Increases Damage [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Increases Damage [ ]", client);
	}
	AddMenuItem(hMenu, "k", sBuffer, 0);
	if (g_bPlayerVipEdit[client][11])
	{
		Format(sBuffer, 128, "Regeneration [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Regeneration [ ]", client);
	}
	AddMenuItem(hMenu, "l", sBuffer, 0);
	if (g_bPlayerVipEdit[client][12])
	{
		Format(sBuffer, 128, "Medic [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Medic [ ]", client);
	}
	AddMenuItem(hMenu, "m", sBuffer, 0);
	if (g_bPlayerVipEdit[client][13])
	{
		Format(sBuffer, 128, "No Damage My Grenades [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "No Damage My Grenades [ ]", client);
	}
	AddMenuItem(hMenu, "n", sBuffer, 0);
	if (g_bPlayerVipEdit[client][14])
	{
		Format(sBuffer, 128, "Health [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Health [ ]", client);
	}
	AddMenuItem(hMenu, "o", sBuffer, 0);
	if (g_bPlayerVipEdit[client][15])
	{
		Format(sBuffer, 128, "Speed [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Speed [ ]", client);
	}
	AddMenuItem(hMenu, "p", sBuffer, 0);
	if (g_bPlayerVipEdit[client][16])
	{
		Format(sBuffer, 128, "Gravity [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Gravity [ ]", client);
	}
	AddMenuItem(hMenu, "q", sBuffer, 0);
	if (g_bPlayerVipEdit[client][17])
	{
		Format(sBuffer, 128, "Effects [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "Effects [ ]", client);
	}
	AddMenuItem(hMenu, "r", sBuffer, 0);
	if (g_bPlayerVipEdit[client][18])
	{
		Format(sBuffer, 128, "ResPawn [X]", client);
	}
	else
	{
		Format(sBuffer, 128, "ResPawn [ ]", client);
	}
	AddMenuItem(hMenu, "s", sBuffer, 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenuAtItem(hMenu, client, position, 0);
	return 0;
}

public MenuHandler_UsersAddTargetSome(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_UsersAddTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[4];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 4, 0, "", 0);
			if (GetTrieValue(g_hUsersFlagsTrie, sBuffer, iBuffer))
			{
				if (g_bPlayerVipEdit[client][iBuffer])
				{
					ReplaceString(g_sVipFlags[client][1], 64, sBuffer, "", true);
					g_bPlayerVipEdit[client][iBuffer] = false;
				}
				else
				{
					Format(g_sVipFlags[client][1], 64, "%s%s", g_sVipFlags[client][1], sBuffer);
					g_bPlayerVipEdit[client][iBuffer] = true;
				}
				Display_UsersAddTargetSome(client, GetMenuSelectionPosition(), true);
			}
		}
	}
	return 0;
}

public MenuHandler_AddVipBaseTargetSomeMenu(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				if (!strlen(g_sVipFlags[client][2]))
				{
					strcopy(g_sVipFlags[client][2], 64, g_sVipFlags[client][1]);
				}
				Display_EditBaseTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[4];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 4, 0, "", 0);
			if (GetTrieValue(g_hUsersFlagsTrie, sBuffer, iBuffer))
			{
				if (g_bPlayerVipEdit[client][iBuffer])
				{
					ReplaceString(g_sVipFlags[client][2], 64, sBuffer, "", true);
					g_bPlayerVipEdit[client][iBuffer] = false;
				}
				Format(g_sVipFlags[client][2], 64, "%s%s", g_sVipFlags[client][2], sBuffer);
				g_bPlayerVipEdit[client][iBuffer] = true;
			}
			Display_UsersAddTargetSome(client, GetMenuSelectionPosition(), false);
		}
	}
	return 0;
}

public Status_OnPluginStart()
{
	AddCommandListener(JoinTeam_Cmd, "jointeam");
	if (g_iGame != GameType:3)
	{
		AddCommandListener(JoinClass_Cmd, "joinclass");
	}
	RegConsoleCmd("viplist", UsersList_Cmd, "VIP List", 0);
	RegConsoleCmd("vip_list", UsersList_Cmd, "VIP List", 0);
	RegConsoleCmd("vips", UsersList_Cmd, "VIP List", 0);
	RegConsoleCmd("vipl", UsersList_Cmd, "VIP List", 0);
	return 0;
}

public Action:JoinTeam_Cmd(client, String:command[], args)
{
	new var1;
	if (client && args && g_bPlayerVip[client][2] && g_iPlayerVip[client][2])
	{
		decl String:sBuffer[4];
		decl iTeam;
		GetCmdArg(1, sBuffer, 4);
		iTeam = StringToInt(sBuffer, 10);
		new var2;
		if (iTeam != GetClientTeam(client) && iTeam <= 3 && iTeam > 0)
		{
			ChangeClientTeam(client, iTeam);
			return Action:3;
		}
	}
	return Action:0;
}

public Action:JoinClass_Cmd(client, String:command[], args)
{
	new var1;
	if (client && !g_bPlayerAlive[client])
	{
		decl String:sBuffer[4];
		decl iClass;
		GetCmdArg(1, sBuffer, 4);
		iClass = StringToInt(sBuffer, 10);
		new var2;
		if (g_bPlayerVip[client][2] && g_iPlayerVip[client][2] && iClass > 0 && 8 >= iClass && !GetTrieValue(g_hUsersJoinCache, g_sClientAuth[client][0], iClass) && SetTrieValue(g_hUsersJoinCache, g_sClientAuth[client][0], any:1, true))
		{
			CS_RespawnPlayer(client);
			g_bJoinClass = true;
			return Action:3;
		}
	}
	return Action:0;
}

public Action:UsersList_Cmd(client, args)
{
	decl String:sBuffer[128];
	if (client)
	{
		if (g_hTopMenu)
		{
			decl Handle:hMenu;
			decl bool:bVipInGame;
			hMenu = CreateMenu(MenuHandler_MenuSettings, MenuAction:28);
			Format(sBuffer, 128, "B ??pe: [Very Important Person]", client);
			SetMenuTitle(hMenu, sBuffer);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var2;
				if (IsClientInGame(i) && IsClientVip(i) && GetClientName(i, sBuffer, 128))
				{
					AddMenuItem(hMenu, "", sBuffer, 0);
					bVipInGame = true;
				}
				i++;
			}
			if (bVipInGame)
			{
				DisplayMenu(hMenu, client, 0);
				bVipInGame = false;
			}
			else
			{
				CloseHandle(hMenu);
			}
		}
		else
		{
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var1;
				if (IsClientInGame(i) && IsClientVip(i) && GetClientName(i, sBuffer, 128))
				{
					ReplyToCommand(client, "\x04[VIP]\x01 ????? \x04[\x01VIP\x04]\x01: %s!", sBuffer);
				}
				i++;
			}
		}
	}
	else
	{
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var3;
			if (IsClientInGame(i) && IsClientVip(i) && GetClientName(i, sBuffer, 128))
			{
				ReplyToCommand(client, "[VIP] Player [VIP]: %s!", sBuffer);
			}
			i++;
		}
	}
	return Action:3;
}

public Display_VipStatusSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_VipStatusSettings, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "[VIP] ??????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	new var1 = g_sUsersClanTag;
	Format(sBuffer, 100, "??????: [?????????]", var1[0][var1], client);
	AddMenuItem(hMenu, "disable", sBuffer, 0);
	if (g_iGame != GameType:2)
	{
		if (g_bUsersStatus[client][0])
		{
			new var2 = g_sUsersClanTag;
			Format(sBuffer, 100, "???? ??? ?????? ??: %s", var2[0][var2], client);
			AddMenuItem(hMenu, "clantag", sBuffer, 0);
		}
		Format(sBuffer, 100, "???? ???: [?? ??????]", client);
		AddMenuItem(hMenu, "clantag", sBuffer, 0);
	}
	new var3 = g_bUsersStatus;
	if (var3[0][var3][1])
	{
		if (g_bUsersStatus[client][1])
		{
			Format(sBuffer, 100, "??????????? ??????: [?????????]", client);
			AddMenuItem(hMenu, "weaponrestrict", sBuffer, 0);
		}
		Format(sBuffer, 100, "??????????? ??????: [????????]", client);
		AddMenuItem(hMenu, "weaponrestrict", sBuffer, 0);
	}
	new var4 = g_bUsersStatus;
	if (var4[0][var4][2])
	{
		if (g_bUsersStatus[client][2])
		{
			Format(sBuffer, 100, "????????? ?? PlayersVotes: [???????]", client);
			AddMenuItem(hMenu, "playersvotes", sBuffer, 0);
		}
		Format(sBuffer, 100, "????????? ?? PlayersVotes: [????????]", client);
		AddMenuItem(hMenu, "playersvotes", sBuffer, 0);
	}
	new var5 = g_bUsersStatus;
	if (var5[0][var5][3])
	{
		if (g_bUsersStatus[client][3])
		{
			Format(sBuffer, 100, "????????? ?? AntiCamp: [???????]", client);
			AddMenuItem(hMenu, "anticamp", sBuffer, 0);
		}
		Format(sBuffer, 100, "????????? ?? AntiCamp: [????????]", client);
		AddMenuItem(hMenu, "anticamp", sBuffer, 0);
	}
	new var6 = g_bUsersStatus;
	if (var6[0][var6][4])
	{
		if (g_bUsersStatus[client][4])
		{
			Format(sBuffer, 100, "????????? ?? AFK Manager: [???????]", client);
			AddMenuItem(hMenu, "afk_manager", sBuffer, 0);
		}
		Format(sBuffer, 100, "????????? ?? AFK Manager: [????????]", client);
		AddMenuItem(hMenu, "afk_manager", sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_VipStatusSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[32];
			GetMenuItem(hMenu, param, sBuffer, 32, 0, "", 0);
			if (StrEqual(sBuffer, "disable", false))
			{
				new var1;
				if (g_iGame == GameType:1 || g_iGame == GameType:3)
				{
					CS_GetClientClanTag(client, sBuffer, 32);
					if (!StrEqual(sBuffer, g_sUsersClanTag[client], false))
					{
						CS_SetClientClanTag(client, g_sUsersClanTag[client]);
					}
				}
				g_iPlayerVip[client][2] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, "??????: [????????]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				return 0;
			}
			if (StrEqual(sBuffer, "clantag", false))
			{
				if (g_bUsersStatus[client][0])
				{
					VipPrint(client, "???? ???: [?? ??????]", client);
					CS_SetClientClanTag(client, g_sUsersClanTag[client]);
					g_bUsersStatus[client][0] = false;
				}
				else
				{
					new var2 = g_sUsersClanTag;
					VipPrint(client, "???? ??? ?????? ??: %s", var2[0][var2], client);
					new var3 = g_sUsersClanTag;
					CS_SetClientClanTag(client, var3[0][var3]);
					g_bUsersStatus[client][0] = true;
				}
			}
			else
			{
				if (StrEqual(sBuffer, "weaponrestrict", false))
				{
					if (g_bUsersStatus[client][1])
					{
						VipPrint(client, "??????????? ??????: [????????]", client);
						g_bUsersStatus[client][1] = false;
					}
					else
					{
						VipPrint(client, "??????????? ??????: [?????????]", client);
						g_bUsersStatus[client][1] = true;
					}
				}
				if (StrEqual(sBuffer, "playersvotes", false))
				{
					if (g_bUsersStatus[client][2])
					{
						VipPrint(client, "????????? ?? PlayersVotes: [????????]", client);
						g_bUsersStatus[client][2] = false;
					}
					else
					{
						VipPrint(client, "????????? ?? PlayersVotes: [???????]", client);
						g_bUsersStatus[client][2] = true;
					}
				}
				if (StrEqual(sBuffer, "anticamp", false))
				{
					if (g_bUsersStatus[client][3])
					{
						VipPrint(client, "????????? ?? AntiCamp: [????????]", client);
						g_bUsersStatus[client][3] = false;
					}
					else
					{
						VipPrint(client, "????????? ?? AntiCamp: [???????]", client);
						g_bUsersStatus[client][3] = true;
					}
				}
				if (StrEqual(sBuffer, "afk_manager", false))
				{
					if (g_bUsersStatus[client][4])
					{
						VipPrint(client, "????????? ?? AFK Manager: [????????]", client);
						g_bUsersStatus[client][4] = false;
					}
					VipPrint(client, "????????? ?? AFK Manager: [???????]", client);
					g_bUsersStatus[client][4] = true;
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_VipStatusSettings(client);
		}
	}
	return 0;
}

public OnSocketUpdate()
{
	g_hArrayList = CreateArray(192, 0);
	g_hSocketTimer = CreateTimer(13.0, Load_SocketTimer, any:0, 0);
	return 0;
}

public Action:Load_SocketTimer(Handle:timer)
{
	g_hSocketTimer = MissingTAG:0;
	new Handle:hSocket;
	new Handle:hFile;
	Format(sSocketBuffer[1], 256, "vip_info_%i.txt", GetRandomInt(1, 100));
	new var1;
	if (FileExists(sSocketBuffer[1], false) && !DeleteFile(sSocketBuffer[1]))
	{
		g_bBetaTest = false;
		Vip_Log("Delete file '%s' Error!", sSocketBuffer[1]);
	}
	else
	{
		hFile = OpenFile(sSocketBuffer[1], "wb");
		hSocket = SocketCreate(SocketType:1, OnSocketError);
		ClearArray(g_hArrayList);
		SocketSetArg(hSocket, hFile);
		SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "update.sourcetm.com", 80);
	}
	return Action:4;
}

public OnSocketConnected(Handle:socket, any:hFile)
{
	if (EnumSocket)
	{
		if (EnumSocket == SocketStatus:1)
		{
			if (StrContains(sSocketBuffer[1], "Path_SM/", true) != -1)
			{
				new var3 = sSocketBuffer;
				strcopy(var3[0][var3], 256, sSocketBuffer[1]);
				new var4 = sSocketBuffer;
				ReplaceString(var4[0][var4], 256, "Path_SM/", "", true);
				new var5 = sSocketBuffer;
				new var6 = sSocketBuffer;
				BuildPath(PathType:0, var6[0][var6], 256, var5[0][var5]);
			}
			else
			{
				if (StrContains(sSocketBuffer[1], "Path_Mod/", true) != -1)
				{
					new var7 = sSocketBuffer;
					strcopy(var7[0][var7], 256, sSocketBuffer[1]);
					new var8 = sSocketBuffer;
					ReplaceString(var8[0][var8], 256, "Path_Mod/", "", true);
				}
			}
			new var9 = sSocketBuffer;
			new var1;
			if (FileExists(var9[0][var9], false) && !DeleteFile(var10[0][var10]))
			{
				g_bBetaTest = false;
				CloseHandle(socket);
				new var11 = sSocketBuffer;
				Vip_Log("Delete file '%s' Error", var11[0][var11]);
				return 0;
			}
			new var12 = sSocketBuffer;
			hFile = OpenFile(var12[0][var12], "wb");
			SocketSetArg(socket, hFile);
			new var13 = sSocketBuffer;
			Format(var13[0][var13], 256, "GET /update/sourcemod/vip/%s HTTP/1.0\r\nHost: update.sourcetm.com\r\nConnection: close\r\n\r\n", sSocketBuffer[1]);
		}
	}
	else
	{
		new var2 = sSocketBuffer;
		Format(var2[0][var2], 256, "GET /update/sourcemod/vip/info.txt HTTP/1.0\r\nHost: update.sourcetm.com\r\nConnection: close\r\n\r\n");
	}
	g_hSocketTimer = CreateTimer(720.0, Load_SocketTimer, any:0, 2);
	new var14 = sSocketBuffer;
	SocketSend(socket, var14[0][var14], -1);
	return 0;
}

public OnSocketReceive(Handle:socket, String:data[], size, any:hFile)
{
	new pos;
	if (!bReceive)
	{
		pos = StrContains(data, "\r\n\r\n", true) + 4;
		bReceive = true;
	}
	while (pos < size)
	{
		pos++;
		WriteFileCell(hFile, data[pos], 1);
	}
	return 0;
}

public OnSocketDisconnected(Handle:hBuffer, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(hBuffer);
	if (g_hSocketTimer)
	{
		KillTimer(g_hSocketTimer, false);
		g_hSocketTimer = MissingTAG:0;
	}
	bReceive = false;
	if (EnumSocket)
	{
		if (EnumSocket == SocketStatus:1)
		{
			if (g_iCountFile[1] == g_iCountFile[0])
			{
				new bool:bUpdate = 256;
				new var11 = sSocketBuffer;
				GetPluginFilename(GetMyHandle(), var11[0][var11], bUpdate);
				new var12 = sSocketBuffer;
				new var13 = sSocketBuffer;
				var12[0][var12][strlen(var13[0][var13]) + -4] = MissingTAG:0;
				new var14 = sSocketBuffer;
				InsertServerCommand("sm plugins reload %s", var14[0][var14]);
			}
			new bool:bUpdate = 256;
			new var15 = g_iCountFile;
			var15++;
			GetArrayString(g_hArrayList, var15[0], sSocketBuffer[1], bUpdate);
			new bool:bUpdate = 257;
			hBuffer = SocketCreate(SocketType:1, bUpdate);
			SocketSetArg(hBuffer, hFile);
			new bool:bUpdate = 80;
			SocketConnect(hBuffer, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "update.sourcetm.com", bUpdate);
		}
	}
	else
	{
		decl bool:bUpdate;
		hBuffer = CreateKeyValues("Information", "", "");
		new var1;
		if (FileToKeyValues(hBuffer, sSocketBuffer[1]) && KvJumpToKey(hBuffer, "Plugin", false))
		{
			new var5 = sSocketBuffer;
			KvGetString(hBuffer, "Version", var5[0][var5], 256, "Error");
			new var6 = sSocketBuffer;
			if (StrEqual(var6[0][var6], "beta_0.0.5", false))
			{
				bUpdate = false;
			}
			else
			{
				new var7 = sSocketBuffer;
				if (StrEqual(var7[0][var7], "Error", false))
				{
					g_bBetaTest = false;
					CloseHandle(hBuffer);
					Vip_Log("Error! File %s 'Socket_Info' key Version: 'Error'", sSocketBuffer[1]);
					return 0;
				}
				new var2;
				if (!(KvJumpToKey(hBuffer, "Files", false) && KvGotoFirstSubKey(hBuffer, false)))
				{
					bUpdate = false;
				}
				do {
					new var8 = sSocketBuffer;
					KvGetString(hBuffer, NULL_STRING, var8[0][var8], 256, "");
					new var9 = sSocketBuffer;
					PushArrayString(g_hArrayList, var9[0][var9]);
					new var10 = sSocketBuffer;
					ParsePathForLocal(var10[0][var10]);
				} while (KvGotoNextKey(hBuffer, false));
				g_iCountFile[0] = 0;
				g_iCountFile[1] = GetArraySize(g_hArrayList) + -1;
				bUpdate = true;
			}
			CloseHandle(hBuffer);
			new var3;
			if (FileExists(sSocketBuffer[1], false) && !DeleteFile(sSocketBuffer[1]))
			{
				g_bBetaTest = false;
				Vip_Log("Delete file '%s' Error!", sSocketBuffer[1]);
				ClearArray(g_hArrayList);
				return 0;
			}
			if (bUpdate)
			{
				new String:sTemp[2][256] = "\x08";
				BuildPath(PathType:0, sSocketBuffer[1], 256, "data/vip/old");
				if (!DirExists(sSocketBuffer[1]))
				{
					CreateDirectory(sSocketBuffer[1], 511);
				}
				BuildPath(PathType:0, sSocketBuffer[1], 256, "data/vip");
				hBuffer = OpenDirectory(sSocketBuffer[1]);
				while (ReadDirEntry(hBuffer, sTemp[0][sTemp], 256, 0))
				{
					new var4;
					if (!(StrContains(sTemp[0][sTemp], ".", true) == -1 || StrEqual(sTemp[0][sTemp], "..", false)))
					{
						if (strlen(sTemp[0][sTemp]) > 1)
						{
							Format(sTemp[1], 256, "%s/old/%s", sSocketBuffer[1], sTemp[0][sTemp]);
							Format(sTemp[0][sTemp], 256, "%s/%s", sSocketBuffer[1], sTemp[0][sTemp]);
							if (FileExists(sTemp[1], false))
							{
								DeleteFile(sTemp[1]);
							}
							RenameFile(sTemp[1], sTemp[0][sTemp]);
							DeleteFile(sTemp[0][sTemp]);
						}
					}
				}
				CloseHandle(hBuffer);
				GetArrayString(g_hArrayList, 0, sSocketBuffer[1], 256);
				EnumSocket = MissingTAG:1;
				hBuffer = SocketCreate(SocketType:1, OnSocketError);
				SocketSetArg(hBuffer, hFile);
				SocketConnect(hBuffer, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "update.sourcetm.com", 80);
			}
			else
			{
				EnumSocket = MissingTAG:0;
				g_hSocketTimer = CreateTimer(2500.0, Load_SocketTimer, any:0, 2);
				if (!g_bBetaTest)
				{
					g_bBetaTest = true;
					OnConfigsExecuted();
				}
			}
		}
		g_bBetaTest = false;
		CloseHandle(hBuffer);
		Vip_Log("Error! File %s 'Socket_Info'", sSocketBuffer[1]);
		return 0;
	}
	return 0;
}

public OnSocketError(Handle:socket, errorType, errorNum, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(socket);
	bReceive = false;
	if (g_hSocketTimer)
	{
		KillTimer(g_hSocketTimer, false);
		g_hSocketTimer = MissingTAG:0;
	}
	switch (errorType)
	{
		case 2:
		{
			LogError("Updater: Socket raised error: unknown host! (NO_HOST)");
		}
		case 3:
		{
			LogError("Updater: Socket raised error: connection error! (CONNECT_ERROR)");
		}
		case 4:
		{
			LogError("Updater: Socket raised error: send data error! (SEND_ERROR)");
		}
		case 5:
		{
			LogError("Updater: Socket raised error: bind to local port error! (BIND_ERROR)");
		}
		case 6:
		{
			LogError("Updater: Socket raised error: receive data error! (RECV_ERROR)");
		}
		default:
		{
		}
	}
	return 0;
}

public ParsePathForLocal(String:path[])
{
	decl count;
	new String:sDirs[16][64] = "@";
	count = ExplodeString(path, "/", sDirs, 16, 64, false) + -1;
	if (StrEqual(sDirs[0][sDirs], "Path_SM", false))
	{
		new var1 = sSocketBuffer;
		BuildPath(PathType:0, var1[0][var1], 256, "");
	}
	else
	{
		new var2 = sSocketBuffer;
		var2[0][var2] = MissingTAG:0;
	}
	new i = 1;
	while (i < count)
	{
		new var3 = sSocketBuffer;
		new var4 = sSocketBuffer;
		Format(var4[0][var4], 256, "%s%s/", var3[0][var3], sDirs[i]);
		new var5 = sSocketBuffer;
		if (!DirExists(var5[0][var5]))
		{
			new var6 = sSocketBuffer;
			CreateDirectory(var6[0][var6], 511);
		}
		i++;
	}
	return 0;
}

public UsersSettingsLoad()
{
	if (g_hKvUsersSettings)
	{
		CloseHandle(g_hKvUsersSettings);
	}
	g_hKvUsersSettings = CreateKeyValues("UsersSettings", "", "");
	FileToKeyValues(g_hKvUsersSettings, g_sUsersPath[2]);
	return 0;
}

public UsersLoadSettingsFlags(client)
{
	decl iTemp;
	decl String:sBuffer[256];
	KvRewind(g_hKvUsersSettings);
	if (KvJumpToKey(g_hKvUsersSettings, g_sClientAuth[client][g_iClientAuth[client]], false))
	{
		if (g_bPlayerVip[client][0])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "VipChat", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][0] = iTemp;
			}
		}
		if (g_bPlayerVip[client][1])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "VipModels", false))
			{
				iTemp = KvGetNum(g_hKvUsersSettings, "ModelsMod", -1);
				if (iTemp != -1)
				{
					g_iPlayerVip[client][1] = iTemp;
				}
				KvGetString(g_hKvUsersSettings, "Models=T", g_sUsersModels[client][0], 256, "none");
				if (StrEqual(g_sUsersModels[client][0], "none", false))
				{
					g_bUsersModels[client][0] = false;
				}
				else
				{
					if (GetTrieString(g_hModelsTrie[0], g_sUsersModels[client][0], sBuffer, 256, 0))
					{
						g_bUsersModels[client][0] = true;
					}
					if (g_iCoutModels[0] != -1)
					{
						GetArrayString(g_hArrayModels[0], 0, sBuffer, 256);
						Format(g_sUsersModels[client][0], 256, sBuffer);
						g_bUsersModels[client][0] = true;
					}
					g_bUsersModels[client][0] = false;
				}
				KvGetString(g_hKvUsersSettings, "Models=CT", g_sUsersModels[client][1], 256, "none");
				if (StrEqual(g_sUsersModels[client][1], "none", false))
				{
					g_bUsersModels[client][1] = false;
				}
				else
				{
					if (GetTrieString(g_hModelsTrie[1], g_sUsersModels[client][1], sBuffer, 256, 0))
					{
						g_bUsersModels[client][1] = true;
					}
					if (g_iCoutModels[1] != -1)
					{
						GetArrayString(g_hArrayModels[1], 0, sBuffer, 256);
						Format(g_sUsersModels[client][1], 256, sBuffer);
						g_bUsersModels[client][1] = true;
					}
					g_bUsersModels[client][1] = false;
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][2])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "StatusVIP", false))
			{
				iTemp = KvGetNum(g_hKvUsersSettings, "Status", -1);
				if (iTemp != -1)
				{
					g_iPlayerVip[client][2] = iTemp;
				}
				iTemp = KvGetNum(g_hKvUsersSettings, "ClanTag", -1);
				if (!iTemp)
				{
					g_bUsersStatus[client][0] = false;
				}
				iTemp = KvGetNum(g_hKvUsersSettings, "WeaponRestrict", -1);
				if (!iTemp)
				{
					g_bUsersStatus[client][1] = false;
				}
				iTemp = KvGetNum(g_hKvUsersSettings, "PlayersVotes", -1);
				if (!iTemp)
				{
					g_bUsersStatus[client][2] = false;
				}
				iTemp = KvGetNum(g_hKvUsersSettings, "AntiCamp", -1);
				if (!iTemp)
				{
					g_bUsersStatus[client][3] = false;
				}
				iTemp = KvGetNum(g_hKvUsersSettings, "AFKManager", -1);
				if (!iTemp)
				{
					g_bUsersStatus[client][4] = false;
				}
				KvGoBack(g_hKvUsersSettings);
			}
			if (g_iGame != GameType:2)
			{
				CreateTimer(3.0, Timer_ClanTag, client, 0);
			}
		}
		if (g_bPlayerVip[client][3])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "SpawnCash", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][3] = iTemp;
			}
		}
		if (g_bPlayerVip[client][4])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "GiveWeapon", false))
			{
				g_iPlayerVip[client][4] = KvGetNum(g_hKvUsersSettings, "WeaponMod", 0);
				KvGetString(g_hKvUsersSettings, "Rifle=T", g_sWeapon[client][0], 64, "ak47");
				KvGetString(g_hKvUsersSettings, "Rifle=CT", g_sWeapon[client][1], 64, "m4a1");
				KvGetString(g_hKvUsersSettings, "Pistol=T", g_sWeapon[client][2], 64, "deagle");
				KvGetString(g_hKvUsersSettings, "Pistol=CT", g_sWeapon[client][3], 64, "deagle");
				KvGetString(g_hKvUsersSettings, "Knife", g_sWeapon[client][4], 64, "setup");
				KvGetString(g_hKvUsersSettings, "Item=1", g_sWeapon[client][5], 64, "grenades");
				KvGetString(g_hKvUsersSettings, "Item=2", g_sWeapon[client][6], 64, "vesthelm");
				KvGetString(g_hKvUsersSettings, "Item=3", g_sWeapon[client][7], 64, "defuser");
				KvGetString(g_hKvUsersSettings, "Item=4", g_sWeapon[client][8], 64, "nvgs");
				KvGetString(g_hKvUsersSettings, "Silencer=m4a1", g_sWeapon[client][9], 64, "auto");
				KvGetString(g_hKvUsersSettings, "Silencer=usp", g_sWeapon[client][10], 64, "auto");
				KvGetString(g_hKvUsersSettings, "DropAllWeapons", g_sWeapon[client][11], 64, "drop");
				KvGetString(g_hKvUsersSettings, "ReloadAmmo", g_sWeapon[client][12], 64, "reload");
				new var1;
				if (g_bSDKHooksLoaded && g_iGame != GameType:3 && !g_bMapsNoGiveWeapons)
				{
					if (StrEqual(g_sWeapon[client][9], "auto", true))
					{
						SDKHook(client, SDKHookType:32, Users_WeaponEquipPost);
						g_bClientWeaponEquip[client] = 1;
					}
					if (StrEqual(g_sWeapon[client][10], "auto", true))
					{
						SDKHook(client, SDKHookType:32, Users_WeaponEquipPost);
						g_bClientWeaponEquip[client] = 1;
					}
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][5])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "ShowHurt", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][5] = iTemp;
			}
		}
		if (g_bPlayerVip[client][6])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "NoTeamFlash", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][6] = iTemp;
			}
		}
		if (g_bPlayerVip[client][7])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "NoFriendlyFire", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][7] = iTemp;
			}
		}
		if (g_bPlayerVip[client][8])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "BunnyHop", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][8] = iTemp;
			}
		}
		if (g_bPlayerVip[client][9])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "SpawnC4", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][9] = iTemp;
			}
		}
		if (g_bPlayerVip[client][10])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "IncreasesDamage", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][10] = iTemp;
			}
		}
		if (g_bPlayerVip[client][11])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "Regeneration", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][11] = iTemp;
			}
		}
		if (g_bPlayerVip[client][12])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "Medic", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][12] = iTemp;
			}
		}
		if (g_bPlayerVip[client][13])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "NoDamageMyGrenades", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][13] = iTemp;
			}
		}
		if (g_bPlayerVip[client][14])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "SpawnHealth", -1);
			if (iTemp != -1)
			{
				if (g_iMaxHealth >= iTemp)
				{
					g_iPlayerVip[client][14] = iTemp;
				}
				g_iPlayerVip[client][14] = g_iMaxHealth;
			}
		}
		if (g_bPlayerVip[client][15])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "SpawnSpeed", -1);
			if (iTemp != -1)
			{
				if (g_iMaxSpeed >= iTemp)
				{
					g_iPlayerVip[client][15] = iTemp;
				}
				g_iPlayerVip[client][15] = g_iMaxSpeed;
			}
		}
		if (g_bPlayerVip[client][16])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "Gravity", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][16] = iTemp;
				if (IsClientInGame(client))
				{
					switch (iTemp)
					{
						case 0:
						{
							if (1065353216 != GetPlayerGravity(client))
							{
								SetPlayerGravity(client, 1.0);
							}
						}
						case 1:
						{
							g_iPlayerVip[client][16] = 1;
							SetPlayerGravity(client, 4.0);
						}
						case 2:
						{
							g_iPlayerVip[client][16] = 2;
							SetPlayerGravity(client, 2.9);
						}
						case 3:
						{
							g_iPlayerVip[client][16] = 3;
							SetPlayerGravity(client, 1.8);
						}
						case 4:
						{
							g_iPlayerVip[client][16] = 4;
							SetPlayerGravity(client, 0.7);
						}
						case 5:
						{
							g_iPlayerVip[client][16] = 5;
							SetPlayerGravity(client, 0.4);
						}
						case 6:
						{
							g_iPlayerVip[client][16] = 6;
							SetPlayerGravity(client, 0.1);
						}
						default:
						{
						}
					}
				}
			}
		}
		if (g_bPlayerVip[client][17])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "Effects", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][17] = iTemp;
			}
		}
	}
	else
	{
		if (g_bPlayerVip[client][1])
		{
			if (g_iCoutModels[0] != -1)
			{
				GetArrayString(g_hArrayModels[0], 0, sBuffer, 256);
				Format(g_sUsersModels[client][0], 256, sBuffer);
				g_bUsersModels[client][0] = true;
			}
			if (g_iCoutModels[1] != -1)
			{
				GetArrayString(g_hArrayModels[1], 0, sBuffer, 256);
				Format(g_sUsersModels[client][1], 256, sBuffer);
				g_bUsersModels[client][1] = true;
			}
		}
		new var2;
		if (g_bPlayerVip[client][2] && g_iGame != GameType:2)
		{
			CreateTimer(3.0, Timer_ClanTag, client, 0);
		}
		if (g_bPlayerVip[client][4])
		{
			SDKHook(client, SDKHookType:32, Users_WeaponEquipPost);
			g_bClientWeaponEquip[client] = 1;
		}
	}
	return 0;
}

public UsersSettingsSave(client)
{
	KvRewind(g_hKvUsersSettings);
	if (KvJumpToKey(g_hKvUsersSettings, g_sClientAuth[client][g_iClientAuth[client]], true))
	{
		if (g_bPlayerVip[client][0])
		{
			KvSetNum(g_hKvUsersSettings, "VipChat", g_iPlayerVip[client][0]);
		}
		if (g_bPlayerVip[client][1])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "VipModels", true))
			{
				KvSetNum(g_hKvUsersSettings, "ModelsMod", g_iPlayerVip[client][1]);
				KvSetString(g_hKvUsersSettings, "Models=T", g_sUsersModels[client][0]);
				KvSetString(g_hKvUsersSettings, "Models=CT", g_sUsersModels[client][1]);
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][2])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "StatusVIP", true))
			{
				KvSetNum(g_hKvUsersSettings, "Status", g_iPlayerVip[client][2]);
				if (g_bUsersStatus[client][0])
				{
					KvSetNum(g_hKvUsersSettings, "ClanTag", 1);
				}
				else
				{
					KvSetNum(g_hKvUsersSettings, "ClanTag", 0);
				}
				if (g_bUsersStatus[client][1])
				{
					KvSetNum(g_hKvUsersSettings, "WeaponRestrict", 1);
				}
				else
				{
					KvSetNum(g_hKvUsersSettings, "WeaponRestrict", 0);
				}
				if (g_bUsersStatus[client][2])
				{
					KvSetNum(g_hKvUsersSettings, "PlayersVotes", 1);
				}
				else
				{
					KvSetNum(g_hKvUsersSettings, "PlayersVotes", 0);
				}
				if (g_bUsersStatus[client][3])
				{
					KvSetNum(g_hKvUsersSettings, "AntiCamp", 1);
				}
				else
				{
					KvSetNum(g_hKvUsersSettings, "AntiCamp", 0);
				}
				if (g_bUsersStatus[client][4])
				{
					KvSetNum(g_hKvUsersSettings, "AFKManager", 1);
				}
				else
				{
					KvSetNum(g_hKvUsersSettings, "AFKManager", 0);
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][3])
		{
			KvSetNum(g_hKvUsersSettings, "SpawnCash", g_iPlayerVip[client][3]);
		}
		if (g_bPlayerVip[client][4])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "GiveWeapon", true))
			{
				KvSetNum(g_hKvUsersSettings, "WeaponMod", g_iPlayerVip[client][4]);
				KvSetString(g_hKvUsersSettings, "Rifle=T", g_sWeapon[client][0]);
				KvSetString(g_hKvUsersSettings, "Rifle=CT", g_sWeapon[client][1]);
				KvSetString(g_hKvUsersSettings, "Pistol=T", g_sWeapon[client][2]);
				KvSetString(g_hKvUsersSettings, "Pistol=CT", g_sWeapon[client][3]);
				KvSetString(g_hKvUsersSettings, "Knife", g_sWeapon[client][4]);
				KvSetString(g_hKvUsersSettings, "Item=1", g_sWeapon[client][5]);
				KvSetString(g_hKvUsersSettings, "Item=2", g_sWeapon[client][6]);
				KvSetString(g_hKvUsersSettings, "Item=3", g_sWeapon[client][7]);
				KvSetString(g_hKvUsersSettings, "Item=4", g_sWeapon[client][8]);
				KvSetString(g_hKvUsersSettings, "Silencer=m4a1", g_sWeapon[client][9]);
				KvSetString(g_hKvUsersSettings, "Silencer=usp", g_sWeapon[client][10]);
				KvSetString(g_hKvUsersSettings, "DropAllWeapons", g_sWeapon[client][11]);
				KvSetString(g_hKvUsersSettings, "ReloadAmmo", g_sWeapon[client][12]);
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][5])
		{
			KvSetNum(g_hKvUsersSettings, "ShowHurt", g_iPlayerVip[client][5]);
		}
		if (g_bPlayerVip[client][6])
		{
			KvSetNum(g_hKvUsersSettings, "NoTeamFlash", g_iPlayerVip[client][6]);
		}
		if (g_bPlayerVip[client][7])
		{
			KvSetNum(g_hKvUsersSettings, "NoFriendlyFire", g_iPlayerVip[client][7]);
		}
		if (g_bPlayerVip[client][8])
		{
			KvSetNum(g_hKvUsersSettings, "BunnyHop", g_iPlayerVip[client][8]);
		}
		if (g_bPlayerVip[client][9])
		{
			KvSetNum(g_hKvUsersSettings, "SpawnC4", g_iPlayerVip[client][9]);
		}
		if (g_bPlayerVip[client][10])
		{
			KvSetNum(g_hKvUsersSettings, "IncreasesDamage", g_iPlayerVip[client][10]);
		}
		if (g_bPlayerVip[client][11])
		{
			KvSetNum(g_hKvUsersSettings, "Regeneration", g_iPlayerVip[client][11]);
		}
		if (g_bPlayerVip[client][12])
		{
			KvSetNum(g_hKvUsersSettings, "Medic", g_iPlayerVip[client][12]);
		}
		if (g_bPlayerVip[client][13])
		{
			KvSetNum(g_hKvUsersSettings, "NoDamageMyGrenades", g_iPlayerVip[client][13]);
		}
		if (g_bPlayerVip[client][14])
		{
			KvSetNum(g_hKvUsersSettings, "SpawnHealth", g_iPlayerVip[client][14]);
		}
		if (g_bPlayerVip[client][15])
		{
			KvSetNum(g_hKvUsersSettings, "SpawnSpeed", g_iPlayerVip[client][15]);
		}
		if (g_bPlayerVip[client][16])
		{
			KvSetNum(g_hKvUsersSettings, "Gravity", g_iPlayerVip[client][16]);
		}
		if (g_bPlayerVip[client][17])
		{
			KvSetNum(g_hKvUsersSettings, "Effects", g_iPlayerVip[client][17]);
		}
		KvRewind(g_hKvUsersSettings);
		KeyValuesToFile(g_hKvUsersSettings, g_sUsersPath[2]);
		UsersSettingsLoad();
		VipPrint(client, "??? ????????? ?????????.");
		g_bSettingsChanged[client] = 0;
	}
	else
	{
		VipPrintError(client, "??????! ?? ??????? ????????? ?????????!");
		Vip_Log("??????! ?? ??????? ????????? ????????? ?????? ??? %N ?????? ????? 'UsersSettings' [%s]", client, g_sUsersPath[2]);
	}
	return 0;
}

public DeleteUserSettings(String:sBuffer[])
{
	KvRewind(g_hKvUsersSettings);
	if (KvJumpToKey(g_hKvUsersSettings, sBuffer, false))
	{
		KvDeleteThis(g_hKvUsersSettings);
		KvRewind(g_hKvUsersSettings);
		KeyValuesToFile(g_hKvUsersSettings, g_sUsersPath[2]);
		UsersSettingsLoad();
	}
	return 0;
}

public Action:Timer_ClanTag(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (g_iClientTeam[client])
		{
			CS_GetClientClanTag(client, g_sUsersClanTag[client], 256);
			if (IsClientVipStatus(client, 0))
			{
				new var1 = g_sUsersClanTag;
				CS_SetClientClanTag(client, var1[0][var1]);
			}
		}
		CreateTimer(1.0, Timer_ClanTag, client, 0);
		return Action:0;
	}
	return Action:4;
}

public ResettingTheFlags(String:sBuffer[])
{
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (IsClientInGame(i) && StrEqual(sBuffer, g_sClientAuth[i][g_iClientAuth[i]], false))
		{
			OnClientDisconnect(i);
			OnClientPutInServer(i);
			g_iClientTeam[i] = GetClientTeam(i);
			g_bPlayerAlive[i] = IsPlayerAlive(i);
			return 0;
		}
		i++;
	}
	return 0;
}

public UsersModelsScan()
{
	new String:sBuffer[2][256] = "\x08";
	g_hKvUsersModels = CreateKeyValues("UsersModels", "", "");
	if (!FileToKeyValues(g_hKvUsersModels, g_sUsersModelsPath))
	{
		Vip_Log("File '%s' not found!", g_sUsersModelsPath);
	}
	ClearArray(g_hArrayModels[0]);
	ClearTrie(g_hModelsTrie[0]);
	ClearArray(g_hArrayModels[1]);
	ClearTrie(g_hModelsTrie[1]);
	KvRewind(g_hKvUsersModels);
	if (KvJumpToKey(g_hKvUsersModels, "ModelsT", false))
	{
		if (KvGotoFirstSubKey(g_hKvUsersModels, false))
		{
			do {
				KvGetSectionName(g_hKvUsersModels, sBuffer[0][sBuffer], 256);
				KvGetString(g_hKvUsersModels, "Model", sBuffer[1], 256, "none");
				new var1;
				if (StrEqual(sBuffer[1], "none", false) || StrEqual(sBuffer[1], "", false))
				{
					g_bModels[0] = 0;
				}
				else
				{
					if (FileExists(sBuffer[1], false))
					{
						PrecacheModel(sBuffer[1], false);
						if (IsModelPrecached(sBuffer[1]))
						{
							PushArrayString(g_hArrayModels[0], sBuffer[0][sBuffer]);
							SetTrieString(g_hModelsTrie[0], sBuffer[0][sBuffer], sBuffer[1], true);
							g_bModels[0] = 1;
						}
						else
						{
							SetFailState("File '%s' not Precached!", sBuffer[1]);
						}
					}
					Vip_Log("[%s] File '%s' not found!", sBuffer[0][sBuffer], sBuffer[1]);
				}
			} while (KvGotoNextKey(g_hKvUsersModels, false));
		}
		else
		{
			g_bModels[0] = 0;
		}
	}
	else
	{
		g_bModels[0] = 0;
	}
	KvRewind(g_hKvUsersModels);
	if (KvJumpToKey(g_hKvUsersModels, "ModelsCT", false))
	{
		if (KvGotoFirstSubKey(g_hKvUsersModels, false))
		{
			do {
				KvGetSectionName(g_hKvUsersModels, sBuffer[0][sBuffer], 256);
				KvGetString(g_hKvUsersModels, "Model", sBuffer[1], 256, "none");
				new var2;
				if (StrEqual(sBuffer[1], "none", false) || StrEqual(sBuffer[1], "", false))
				{
					g_bModels[1] = 0;
				}
				else
				{
					if (FileExists(sBuffer[1], false))
					{
						PrecacheModel(sBuffer[1], false);
						if (IsModelPrecached(sBuffer[1]))
						{
							PushArrayString(g_hArrayModels[1], sBuffer[0][sBuffer]);
							SetTrieString(g_hModelsTrie[1], sBuffer[0][sBuffer], sBuffer[1], true);
							g_bModels[1] = 1;
						}
						else
						{
							SetFailState("File '%s' not Precached!", sBuffer[1]);
						}
					}
					Vip_Log("[%s] File '%s' not found!", sBuffer[0][sBuffer], sBuffer[1]);
				}
			} while (KvGotoNextKey(g_hKvUsersModels, false));
		}
		else
		{
			g_bModels[1] = 0;
		}
	}
	else
	{
		g_bModels[1] = 0;
	}
	g_iCoutModels[0] = GetArraySize(g_hArrayModels[0]) + -1;
	g_iCoutModels[1] = GetArraySize(g_hArrayModels[1]) + -1;
	CloseHandle(g_hKvUsersModels);
	g_hKvUsersModels = MissingTAG:0;
	return 0;
}

public PlayerSpawn_Models(client)
{
	decl String:sBuffer[256];
	new var1;
	if (g_iClientTeam[client] == 2 && g_bModels[0] && g_bUsersModels[client][0])
	{
		if (GetTrieString(g_hModelsTrie[0], g_sUsersModels[client][0], sBuffer, 256, 0))
		{
			SetEntityModel(client, sBuffer);
			if (g_iGame == GameType:3)
			{
				SetEntDataString(client, g_iArmsModelOffset, sBuffer, 256, false);
			}
		}
	}
	else
	{
		new var2;
		if (g_iClientTeam[client] == 3 && g_bModels[1] && g_bUsersModels[client][1])
		{
			if (GetTrieString(g_hModelsTrie[1], g_sUsersModels[client][1], sBuffer, 256, 0))
			{
				SetEntityModel(client, sBuffer);
				if (g_iGame == GameType:3)
				{
					SetEntDataString(client, g_iArmsModelOffset, sBuffer, 256, false);
				}
			}
		}
	}
	return 0;
}

public Display_UsersModels(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModels, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "[VIP] ????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	new var1;
	if (!g_bUsersModels[client][0] && !g_bUsersModels[client][1])
	{
		g_iPlayerVip[client][1] = 0;
		g_bSettingsChanged[client] = 1;
		VipPrint(client, "????: [????????]");
		Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		CloseHandle(hMenu);
		return 0;
	}
	AddMenuItem(hMenu, "models_off", "C???: [?????????]", 0);
	if (g_bModels[0])
	{
		if (g_bUsersModels[client][0])
		{
			Format(sBuffer, 128, "????????? [%s]", g_sUsersModels[client][0], client);
			AddMenuItem(hMenu, "models_t", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hMenu, "models_t", "?????????: [????????]", 0);
		}
	}
	else
	{
		AddMenuItem(hMenu, "", "?????????: [H??o?????o!]", 1);
	}
	if (g_bModels[1])
	{
		if (g_bUsersModels[client][1])
		{
			Format(sBuffer, 128, "???????: [%s]", g_sUsersModels[client][1], client);
			AddMenuItem(hMenu, "models_ct", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hMenu, "models_ct", "???????: [????????]", 0);
		}
	}
	else
	{
		AddMenuItem(hMenu, "", "???????: [H??o?????o!]", 1);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersModels(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (StrEqual(sBuffer, "models_off", false))
			{
				g_iPlayerVip[client][1] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, "[VIP] ????: [????????]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
			else
			{
				if (StrEqual(sBuffer, "models_t", false))
				{
					Display_UsersModelsT(client);
				}
				if (StrEqual(sBuffer, "models_ct", false))
				{
					Display_UsersModelsCT(client);
				}
			}
		}
	}
	return 0;
}

public Display_UsersModelsT(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModelsSettings, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "[VIP] ???? ??????????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "modelt_off", "[VIP] ???? ??????????: [?????????]", 0);
	new i;
	while (g_iCoutModels[0] >= i)
	{
		GetArrayString(g_hArrayModels[0], i, sBuffer, 128);
		AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		i++;
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public Display_UsersModelsCT(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModelsSettings, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "[VIP] ???? ????????: [?????????]", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "modelct_off", "[VIP] ???? ????????: [?????????]", 0);
	new i;
	while (g_iCoutModels[1] >= i)
	{
		GetArrayString(g_hArrayModels[1], i, sBuffer, 128);
		AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		i++;
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersModelsSettings(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param == -6)
			{
				Display_UsersModels(client);
			}
		}
		if (action == MenuAction:4)
		{
			new String:sBuffer[2][256] = "\x08";
			GetMenuItem(hMenu, param, sBuffer[0][sBuffer], 256, 0, "", 0);
			if (StrEqual(sBuffer[0][sBuffer], "modelt_off", false))
			{
				g_bUsersModels[client][0] = false;
			}
			else
			{
				if (StrEqual(sBuffer[0][sBuffer], "modelct_off", false))
				{
					g_bUsersModels[client][1] = false;
				}
				if (GetTrieString(g_hModelsTrie[0], sBuffer[0][sBuffer], sBuffer[1], 256, 0))
				{
					Format(g_sUsersModels[client][0], 256, sBuffer[0][sBuffer]);
					new var1;
					if (g_bPlayerAlive[client] && g_iClientTeam[client] == 2)
					{
						SetEntityModel(client, sBuffer[1]);
					}
					g_bUsersModels[client][0] = true;
				}
				if (GetTrieString(g_hModelsTrie[1], sBuffer[0][sBuffer], sBuffer[1], 256, 0))
				{
					Format(g_sUsersModels[client][1], 256, sBuffer[0][sBuffer]);
					new var2;
					if (g_bPlayerAlive[client] && g_iClientTeam[client] == 3)
					{
						SetEntityModel(client, sBuffer[1]);
					}
					g_bUsersModels[client][1] = true;
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_UsersModels(client);
		}
	}
	return 0;
}

public Display_Gravity(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Gravity, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "????????? ??????????: ?????????", client);
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "??????????: [????????]", client);
	if (!g_iPlayerVip[client][16])
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "0", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [O?e?? ??co?a?]", client);
	if (g_iPlayerVip[client][16] == 1)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "1", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [B?co?a?]", client);
	if (g_iPlayerVip[client][16] == 2)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "2", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [??????????]", client);
	if (g_iPlayerVip[client][16] == 3)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "3", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [??????????]", client);
	if (g_iPlayerVip[client][16] == 4)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "4", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [H???a?]", client);
	if (g_iPlayerVip[client][16] == 5)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "5", sBuffer, 0);
	}
	Format(sBuffer, 100, "??????????: [O?e?? H???a?]", client);
	if (g_iPlayerVip[client][16] == 6)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "6", sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_Gravity(Handle:hMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(hMenu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[4];
			GetMenuItem(hMenu, param, sBuffer, 4, 0, "", 0);
			switch (StringToInt(sBuffer, 10))
			{
				case 0:
				{
					if (1065353216 != GetPlayerGravity(client))
					{
						SetPlayerGravity(client, 1.0);
					}
					g_iPlayerVip[client][16] = 0;
					VipPrint(client, "??????????: [????????]");
				}
				case 1:
				{
					g_iPlayerVip[client][16] = 1;
					SetPlayerGravity(client, 4.0);
					VipPrint(client, "??????????: [????? ???????]");
				}
				case 2:
				{
					g_iPlayerVip[client][16] = 2;
					SetPlayerGravity(client, 2.9);
					VipPrint(client, "??????????: [???????]");
				}
				case 3:
				{
					g_iPlayerVip[client][16] = 3;
					SetPlayerGravity(client, 1.8);
					VipPrint(client, "??????????: [??????? ???????]");
				}
				case 4:
				{
					g_iPlayerVip[client][16] = 4;
					SetPlayerGravity(client, 0.7);
					VipPrint(client, "??????????: [??????? ??????]");
				}
				case 5:
				{
					g_iPlayerVip[client][16] = 5;
					SetPlayerGravity(client, 0.4);
					VipPrint(client, "??????????: [??????]");
				}
				case 6:
				{
					g_iPlayerVip[client][16] = 6;
					SetPlayerGravity(client, 0.1);
					VipPrint(client, "??????????: [????? ??????]");
				}
				default:
				{
				}
			}
			g_bSettingsChanged[client] = 1;
			Display_Gravity(client);
		}
	}
	return 0;
}

public ResPawn_OnPluginStart()
{
	RegConsoleCmd("resp", ResPawn_Cmd, "ResPawn", 0);
	return 0;
}

public Action:ResPawn_Cmd(client, args)
{
	new var1;
	if (client && g_iClientTeam[client] > 1)
	{
		new var2;
		if (g_bPlayerVip[client][18] && g_iPlayerVip[client][18])
		{
			if (g_bPlayerAlive[client])
			{
				VipPrintError(client, "?????! ?? ?????? ??? ???! [0_o]");
			}
			else
			{
				new iFrags = GetPlayerFrags(client);
				if (iFrags >= 8)
				{
					iFrags += -8;
					SetPlayerFrags(client, iFrags);
					CS_RespawnPlayer(client);
					VipPrint(client, "? ??? ????? 8 ?????? :)");
				}
				else
				{
					VipPrintError(client, "?????, ???! ????? ???????????? ??? ???????, ? ???? ?????? ???? ?????? 8 ??????.");
				}
			}
		}
		else
		{
			VipPrintError(client, "??? ?????????? ??? ???????!");
		}
		return Action:3;
	}
	return Action:0;
}

public OnEntityCreated(entity, String:classname[])
{
	if (StrContains(classname, "_projectile", false) != -1)
	{
		CreateTimer(0.09, Timer_EntityGrenade, entity, 0);
	}
	return 0;
}

public Action:Timer_EntityGrenade(Handle:timer, any:entity)
{
	decl client;
	new var1;
	if (IsValidEntity(entity) && (client = GetEntDataEnt2(entity, g_iGrenadeThrowerOffset)) > 0 && client <= g_iMaxClients && g_bPlayerVip[client][17] && g_iPlayerVip[client][17])
	{
		TE_SetupBeamFollow(entity, g_iSetupBeam[0], 0, 0.5, 2.0, 2.0, 1, 194832);
		TE_SendToAll(0.0);
	}
	return Action:4;
}

public OnPluginStart()
{
	new Handle:hConVar;
	new String:sBuffer[128];
	GetGameDescription(sBuffer, 128, false);
	Vip_Log("????? ???????: [%s:rc2] ???: %s", "beta_0.0.5", sBuffer);
	if (g_iGame)
	{
		g_iAccountOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		g_iWeaponParentOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
		g_iSpeedOffset = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
		g_iFlashOffset[0] = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
		g_iFlashOffset[1] = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
		g_iHealthOffset = FindSendPropOffs("CCSPlayer", "m_iHealth");
		g_iWaterLevelOffset = FindSendPropOffs("CCSPlayer", "m_nWaterLevel");
		g_iNightVisionOffset = FindSendPropOffs("CCSPlayer", "m_bHasNightVision");
		g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
		g_iDefuserOffset = FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
		g_iSilencerOffset[0] = FindSendPropOffs("CWeaponM4A1", "m_bSilencerOn");
		g_iSilencerOffset[1] = FindSendPropOffs("CWeaponUSP", "m_bSilencerOn");
		if (g_iGame != GameType:2)
		{
			g_iSilencerOffset[2] = FindSendPropOffs("CWeaponM4A1", "m_weaponMode");
			g_iSilencerOffset[3] = FindSendPropOffs("CWeaponUSP", "m_weaponMode");
			if (g_iGame == GameType:3)
			{
				g_iArmsModelOffset = FindSendPropOffs("CCSPlayer", "m_szArmsModel");
			}
		}
		g_iActiveWeaponOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
		g_iClip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
		g_iGrenadeThrowerOffset = FindSendPropOffs("CBaseGrenade", "m_hThrower");
	}
	else
	{
		SetFailState("?????? ??? ?? ??????????????!");
	}
	Chat_OnPluginStart();
	Events_OnPluginStart();
	Health_OnPluginStart();
	Speed_OnPluginStart();
	Weapon_OnPluginStart();
	Cash_OnPluginStart();
	Menu_OnPluginStart();
	Status_OnPluginStart();
	Admins_OnPluginStart();
	ResPawn_OnPluginStart();
	new var1 = g_sUsersPath;
	BuildPath(PathType:0, var1[0][var1], 256, "data/vip/users.txt");
	BuildPath(PathType:0, g_sUsersPath[1], 256, "data/vip/users_groups.txt");
	BuildPath(PathType:0, g_sUsersPath[2], 256, "data/vip/users_settings.txt");
	BuildPath(PathType:0, g_sSettings, 256, "data/vip/settings.txt");
	new var2 = g_sAdminsPath;
	BuildPath(PathType:0, var2[0][var2], 256, "data/vip/admins.txt");
	BuildPath(PathType:0, g_sAdminsPath[1], 256, "data/vip/admins_groups.txt");
	BuildPath(PathType:0, g_sAdminsPath[2], 256, "data/vip/admins_access.txt");
	BuildPath(PathType:0, g_sUsersModelsPath, 256, "data/vip/users_models.txt");
	BuildPath(PathType:0, g_sTriggerChatPath, 256, "data/vip/trigger_chat.txt");
	BuildPath(PathType:0, g_sDownloadsPath, 256, "data/vip/downloads.txt");
	g_hChatTrie = CreateTrie();
	g_hUsersTrie = CreateTrie();
	g_hUsersJoinCache = CreateTrie();
	g_hUsersGroupsTrie = CreateTrie();
	g_hAdminsTrie[0] = CreateTrie();
	g_hAdminsTrie[1] = CreateTrie();
	g_hAdminsTrie[2] = CreateTrie();
	g_hUsersDeleteTrie = CreateTrie();
	g_hModelsTrie[0] = CreateTrie();
	g_hModelsTrie[1] = CreateTrie();
	g_hAdminFlagsTrie = CreateTrie();
	SetTrieValue(g_hAdminFlagsTrie, "a", any:0, true);
	SetTrieValue(g_hAdminFlagsTrie, "b", any:1, true);
	SetTrieValue(g_hAdminFlagsTrie, "c", any:2, true);
	SetTrieValue(g_hAdminFlagsTrie, "d", any:3, true);
	SetTrieValue(g_hAdminFlagsTrie, "e", any:4, true);
	SetTrieValue(g_hAdminFlagsTrie, "f", any:5, true);
	SetTrieValue(g_hAdminFlagsTrie, "g", any:6, true);
	SetTrieValue(g_hAdminFlagsTrie, "h", any:7, true);
	SetTrieValue(g_hAdminFlagsTrie, "i", any:8, true);
	SetTrieValue(g_hAdminFlagsTrie, "j", any:9, true);
	SetTrieValue(g_hAdminFlagsTrie, "k", any:10, true);
	SetTrieValue(g_hAdminFlagsTrie, "l", any:11, true);
	SetTrieValue(g_hAdminFlagsTrie, "m", any:12, true);
	SetTrieValue(g_hAdminFlagsTrie, "n", any:13, true);
	SetTrieValue(g_hAdminFlagsTrie, "z", any:14, true);
	SetTrieValue(g_hAdminFlagsTrie, "o", any:15, true);
	SetTrieValue(g_hAdminFlagsTrie, "p", any:16, true);
	SetTrieValue(g_hAdminFlagsTrie, "q", any:17, true);
	SetTrieValue(g_hAdminFlagsTrie, "r", any:18, true);
	SetTrieValue(g_hAdminFlagsTrie, "s", any:19, true);
	SetTrieValue(g_hAdminFlagsTrie, "t", any:20, true);
	g_hUsersFlagsTrie = CreateTrie();
	SetTrieValue(g_hUsersFlagsTrie, "a", any:0, true);
	SetTrieValue(g_hUsersFlagsTrie, "b", any:1, true);
	SetTrieValue(g_hUsersFlagsTrie, "c", any:2, true);
	SetTrieValue(g_hUsersFlagsTrie, "d", any:3, true);
	SetTrieValue(g_hUsersFlagsTrie, "e", any:4, true);
	SetTrieValue(g_hUsersFlagsTrie, "f", any:5, true);
	SetTrieValue(g_hUsersFlagsTrie, "g", any:6, true);
	SetTrieValue(g_hUsersFlagsTrie, "h", any:7, true);
	SetTrieValue(g_hUsersFlagsTrie, "i", any:8, true);
	SetTrieValue(g_hUsersFlagsTrie, "j", any:9, true);
	SetTrieValue(g_hUsersFlagsTrie, "k", any:10, true);
	SetTrieValue(g_hUsersFlagsTrie, "l", any:11, true);
	SetTrieValue(g_hUsersFlagsTrie, "m", any:12, true);
	SetTrieValue(g_hUsersFlagsTrie, "n", any:13, true);
	SetTrieValue(g_hUsersFlagsTrie, "o", any:14, true);
	SetTrieValue(g_hUsersFlagsTrie, "p", any:15, true);
	SetTrieValue(g_hUsersFlagsTrie, "q", any:16, true);
	SetTrieValue(g_hUsersFlagsTrie, "r", any:17, true);
	SetTrieValue(g_hUsersFlagsTrie, "s", any:18, true);
	g_hWeaponTrie = CreateTrie();
	SetTrieValue(g_hWeaponTrie, "galil", any:0, true);
	SetTrieValue(g_hWeaponTrie, "ak47", any:0, true);
	SetTrieValue(g_hWeaponTrie, "scout", any:0, true);
	SetTrieValue(g_hWeaponTrie, "sg552", any:0, true);
	SetTrieValue(g_hWeaponTrie, "awp", any:0, true);
	SetTrieValue(g_hWeaponTrie, "g3sg1", any:0, true);
	SetTrieValue(g_hWeaponTrie, "famas", any:0, true);
	SetTrieValue(g_hWeaponTrie, "m4a1", any:0, true);
	SetTrieValue(g_hWeaponTrie, "aug", any:0, true);
	SetTrieValue(g_hWeaponTrie, "sg550", any:0, true);
	SetTrieValue(g_hWeaponTrie, "m3", any:0, true);
	SetTrieValue(g_hWeaponTrie, "xm1014", any:0, true);
	SetTrieValue(g_hWeaponTrie, "mac10", any:0, true);
	SetTrieValue(g_hWeaponTrie, "tmp", any:0, true);
	SetTrieValue(g_hWeaponTrie, "mp5navy", any:0, true);
	SetTrieValue(g_hWeaponTrie, "ump45", any:0, true);
	SetTrieValue(g_hWeaponTrie, "p90", any:0, true);
	SetTrieValue(g_hWeaponTrie, "m249", any:0, true);
	SetTrieValue(g_hWeaponTrie, "glock", any:1, true);
	SetTrieValue(g_hWeaponTrie, "usp", any:1, true);
	SetTrieValue(g_hWeaponTrie, "p228", any:1, true);
	SetTrieValue(g_hWeaponTrie, "deagle", any:1, true);
	SetTrieValue(g_hWeaponTrie, "elite", any:1, true);
	SetTrieValue(g_hWeaponTrie, "fiveseven", any:1, true);
	SetTrieValue(g_hWeaponTrie, "knife", any:2, true);
	SetTrieValue(g_hWeaponTrie, "hegrenade", any:3, true);
	SetTrieValue(g_hWeaponTrie, "flashbang", any:3, true);
	SetTrieValue(g_hWeaponTrie, "smokegrenade", any:3, true);
	if (g_iGame == GameType:3)
	{
		SetTrieValue(g_hWeaponTrie, "taser", any:2, true);
		SetTrieValue(g_hWeaponTrie, "molotov", any:3, true);
		SetTrieValue(g_hWeaponTrie, "incgrenade", any:3, true);
		SetTrieValue(g_hWeaponTrie, "decoy", any:3, true);
	}
	SetTrieValue(g_hWeaponTrie, "c4", any:4, true);
	g_hWeaponAmmoTrie = CreateTrie();
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_galil", any:125, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_ak47", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_scout", any:100, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_sg552", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_awp", any:40, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_g3sg1", any:110, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_famas", any:115, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_m4a1", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_aug", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_sg550", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_m3", any:40, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_xm1014", any:39, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_mac10", any:130, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_tmp", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_mp5navy", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_ump45", any:125, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_p90", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_m249", any:300, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_glock", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_usp", any:112, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_p228", any:65, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_deagle", any:42, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_elite", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_fiveseven", any:120, true);
	hConVar = FindConVar("mp_friendlyfire");
	HookConVarChange(hConVar, OnSettingsChanged);
	hConVar = CreateConVar("vip_admins_cvar_password", "sv_logecho", "", 393216, false, 0.0, false, 0.0);
	OnSettingsChanged(hConVar, "", "");
	HookConVarChange(hConVar, OnSettingsChanged);
	hConVar = CreateConVar("vip_users_increase_damage", "1.35", "????????? ????? ??? VIP ??????? ? ?????? 'k'", 262144, true, 1.0, true, 100.0);
	OnSettingsChanged(hConVar, "", "");
	HookConVarChange(hConVar, OnSettingsChanged);
	hConVar = CreateConVar("vip_users_max_health", "115", "???????????? ?????????? HP ??? vip ???????.", 262144, true, 10.0, true, 500.0);
	OnSettingsChanged(hConVar, "", "");
	HookConVarChange(hConVar, OnSettingsChanged);
	hConVar = CreateConVar("vip_users_max_speed", "10", "???????????? ???????? ??????????? ??? vip ???????.", 262144, true, 2.0, true, 21.0);
	OnSettingsChanged(hConVar, "", "");
	HookConVarChange(hConVar, OnSettingsChanged);
	if (g_iGame != GameType:2)
	{
		hConVar = CreateConVar("vip_users_clantag", "[VIP]", "Clan Tag ??? vip ??????? ? ?????? 'c'.", 262144, false, 0.0, false, 0.0);
		OnSettingsChanged(hConVar, "", "");
		HookConVarChange(hConVar, OnSettingsChanged);
	}
	hConVar = CreateConVar("vip_users_reload_ammo", "1", "?????????????? ???????? ?????? ??? VIP ??????? ? ?????? 'e'", 262144, true, 0.0, true, 1.0);
	OnSettingsChanged(hConVar, "", "");
	HookConVarChange(hConVar, OnSettingsChanged);
	CreateConVar("vip_version", "beta_0.0.5", "Version of the plugin", 131328, false, 0.0, false, 0.0);
	g_hArrayModels[0] = CreateArray(32, 0);
	g_hArrayModels[1] = CreateArray(32, 0);
	g_hArrayUsersExpires = CreateArray(32, 0);
	LoadTranslations("common.phrases");
	return 0;
}

public OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	if (StrEqual(sBuffer, "mp_friendlyfire", false))
	{
		g_bFriendLyFire = GetConVarBool(convar);
		Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bFriendLyFire);
	}
	else
	{
		if (StrEqual(sBuffer, "vip_admins_cvar_password", false))
		{
			GetConVarString(convar, g_sAdminProtected, 128);
		}
		if (StrEqual(sBuffer, "vip_users_increase_damage", false))
		{
			g_fIncreaseDamage = GetConVarFloat(convar);
			Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, g_fIncreaseDamage);
		}
		if (StrEqual(sBuffer, "vip_users_max_health", false))
		{
			g_iMaxHealth = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iMaxHealth);
		}
		if (StrEqual(sBuffer, "vip_users_max_speed", false))
		{
			g_iMaxSpeed = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iMaxSpeed);
		}
		if (StrEqual(sBuffer, "vip_users_clantag", false))
		{
			new var1 = g_sUsersClanTag;
			GetConVarString(convar, var1[0][var1], 256);
			new var2 = g_sUsersClanTag;
			Vip_Log("ConVar : \"%s\" = \"%s\"", sBuffer, var2[0][var2]);
		}
		if (StrEqual(sBuffer, "vip_users_reload_ammo", false))
		{
			g_bReloadAmmo = GetConVarBool(convar);
			Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bReloadAmmo);
		}
	}
	return 0;
}

public OnLibraryAdded(String:name[])
{
	if (StrEqual(name, "sdkhooks", false))
	{
		g_bSDKHooksLoaded = true;
	}
	return 0;
}

public OnLibraryRemoved(String:name[])
{
	if (StrEqual(name, "sdkhooks", false))
	{
		g_bSDKHooksLoaded = false;
	}
	else
	{
		if (StrEqual(name, "adminmenu", false))
		{
			g_hTopMenu = MissingTAG:0;
		}
	}
	return 0;
}

public OnMapStart()
{
	g_bIsDeMap = false;
	if (FindEntityByClassname(-1, "func_bomb_target") != -1)
	{
		g_bIsDeMap = true;
	}
	GetCurrentMap(g_sMap, 64);
	if (FileExists(g_sDownloadsPath, false))
	{
		ParsFile(g_sDownloadsPath, Handle:0, 2);
	}
	if (FileExists(g_sTriggerChatPath, false))
	{
		ClearTrie(g_hChatTrie);
		ParsFile(g_sTriggerChatPath, g_hChatTrie, 1);
	}
	if (FileExists(g_sAdminsPath[2], false))
	{
		ClearTrie(g_hAdminsTrie[2]);
		ParsFile(g_sAdminsPath[2], g_hAdminsTrie[2], 1);
	}
	PluginSettings();
	UsersModelsScan();
	PrecacheSound("buttons/blip2.wav", false);
	PrecacheSound("ambient/explosions/explode_8.wav", false);
	PrecacheSound("buttons/button11.wav", false);
	PrecacheSound("ui/buttonclick.wav", false);
	g_iSetupBeam[0] = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	AddFileToDownloadsTable("materials/sprites/laserbeam.vmt");
	if (g_iGame == GameType:3)
	{
		g_iSetupBeam[1] = PrecacheModel("materials/sprites/glow01.vmt", false);
		AddFileToDownloadsTable("materials/sprites/glow01.vmt");
	}
	else
	{
		g_iSetupBeam[1] = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
		AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");
	}
	AddFileToDownloadsTable("sound/buttons/blip2.wav");
	AddFileToDownloadsTable("sound/ambient/explosions/explode_8.wav");
	AddFileToDownloadsTable("sound/buttons/button11.wav");
	AddFileToDownloadsTable("sound/ui/buttonclick.wav");
	return 0;
}

public OnMapEnd()
{
	UsersScan();
	AdminsScan();
	UsersSettingsLoad();
	ClearTrie(g_hUsersJoinCache);
	return 0;
}

public OnAllPluginsLoaded()
{
	decl String:sBuffer[64];
	UsersScan();
	AdminsScan();
	UsersSettingsLoad();
	OnSocketUpdate();
	Format(sBuffer, 64, "vip_%s", "beta_0.0.5");
	AutoExecConfig(true, sBuffer, "sourcemod");
	PrintToServer("Very Important Person [rc2] %s has been loaded successfully.", "beta_0.0.5");
	g_bSDKHooksLoaded = LibraryExists("sdkhooks");
	return 0;
}

public UsersScan()
{
	new String:sBuffer[256];
	if (g_hKvUsers)
	{
		CloseHandle(g_hKvUsers);
	}
	g_hKvUsers = CreateKeyValues("Users", "", "");
	new var1 = g_sUsersPath;
	if (FileToKeyValues(g_hKvUsers, var1[0][var1]))
	{
		if (g_hUsersTrie)
		{
			ClearTrie(g_hUsersTrie);
		}
		KvRewind(g_hKvUsers);
		if (KvGotoFirstSubKey(g_hKvUsers, false))
		{
			do {
				KvGetSectionName(g_hKvUsers, sBuffer, 256);
				SetTrieValue(g_hUsersTrie, sBuffer, any:1, true);
			} while (KvGotoNextKey(g_hKvUsers, false));
		}
		if (g_hKvUsersGroups)
		{
			CloseHandle(g_hKvUsersGroups);
		}
		g_hKvUsersGroups = CreateKeyValues("UsersGroups", "", "");
		if (FileToKeyValues(g_hKvUsersGroups, g_sUsersPath[1]))
		{
			if (g_hUsersGroupsTrie)
			{
				ClearTrie(g_hUsersGroupsTrie);
			}
			KvRewind(g_hKvUsersGroups);
			if (KvGotoFirstSubKey(g_hKvUsersGroups, false))
			{
				do {
					KvGetSectionName(g_hKvUsersGroups, sBuffer, 256);
					SetTrieValue(g_hUsersGroupsTrie, sBuffer, any:1, true);
				} while (KvGotoNextKey(g_hKvUsersGroups, false));
			}
		}
		else
		{
			g_bBetaTest = false;
			Vip_Log("File '%s' not found!", g_sUsersPath[1]);
			CloseHandle(g_hKvUsersGroups);
		}
		return 0;
	}
	g_bBetaTest = false;
	new var2 = g_sUsersPath;
	Vip_Log("File '%s' not found!", var2[0][var2]);
	CloseHandle(g_hKvUsers);
	return 0;
}

public PluginSettings()
{
	decl String:sBuffer[256];
	new String:sRandom[3][16] = "";
	g_hKvSettings = CreateKeyValues("Settings", "", "");
	if (FileToKeyValues(g_hKvSettings, g_sSettings))
	{
		KvRewind(g_hKvSettings);
		if (KvJumpToKey(g_hKvSettings, "Users", true))
		{
			if (KvJumpToKey(g_hKvSettings, "Regeneration", true))
			{
				g_fRegenTime[0] = KvGetFloat(g_hKvSettings, "TimerStart", 6.3);
				g_fRegenTime[1] = KvGetFloat(g_hKvSettings, "TimerRegen", 0.2);
				g_iRegenHP[0] = KvGetNum(g_hKvSettings, "RegenHP", 1);
				if (g_iRegenHP[0] < 1)
				{
					g_iRegenHP[0] = 1;
				}
				if (KvJumpToKey(g_hKvSettings, "HeartBeat", true))
				{
					g_iRegenHP[1] = KvGetNum(g_hKvSettings, "MinHP", 35);
					KvGetString(g_hKvSettings, "TimerRandom", sBuffer, 256, "2.0,3.2");
					if (ExplodeString(sBuffer, ",", sRandom, 3, 16, false) == 2)
					{
						ReplaceString(sRandom[0][sRandom], 16, " ", "", true);
						ReplaceString(sRandom[1], 16, " ", "", true);
						g_fRegenTime[2] = StringToFloat(sRandom[0][sRandom]);
						g_fRegenTime[3] = StringToFloat(sRandom[1]);
					}
					else
					{
						g_fRegenTime[2] = 1073741824;
						g_fRegenTime[3] = 1078774989;
					}
					KvGetString(g_hKvSettings, "Sound", g_sSoundHeartBeat, 256, "vip/heartbeat.mp3");
					Format(sBuffer, 256, "sound/%s", g_sSoundHeartBeat);
					if (FileExists(sBuffer, false))
					{
						PrecacheSound(g_sSoundHeartBeat, true);
						AddFileToDownloadsTable(sBuffer);
						g_bHeartBeat = true;
					}
					else
					{
						g_bHeartBeat = false;
						Vip_Log("File '%s' not found!", sBuffer);
					}
					KvGoBack(g_hKvSettings);
				}
				else
				{
					g_bHeartBeat = false;
				}
				KvGoBack(g_hKvSettings);
			}
			else
			{
				g_bHeartBeat = false;
			}
			g_bMapsNoGiveWeapons = false;
			if (KvJumpToKey(g_hKvSettings, "GiveWeapons", true))
			{
				KvGetString(g_hKvSettings, "NotGiveOnMapsList", sBuffer, 256, "none");
				new var1;
				if (!StrEqual(sBuffer, "none", false) && FileExists(sBuffer, false))
				{
					ParsFile(sBuffer, Handle:0, 3);
				}
			}
		}
	}
	else
	{
		g_bBetaTest = false;
		SetFailState("File '%s' not found!", g_sSettings);
	}
	CloseHandle(g_hKvSettings);
	return 0;
}

public OnClientPutInServer(client)
{
	new var1;
	if (g_bBetaTest && GetClientAuthString(client, g_sClientAuth[client][0], 32) && GetClientIP(client, g_sClientAuth[client][1], 32, true))
	{
		UsersLoadFlags(client);
		AdminAuth_Post(client);
		if (g_bSDKHooksLoaded)
		{
			SDKHook(client, SDKHookType:2, Users_OnTakeDamage);
		}
	}
	return 0;
}

public OnClientDisconnect(client)
{
	decl iBuffer;
	if (!g_bBetaTest)
	{
		return 0;
	}
	if (g_bIsAdmin[client])
	{
		RemoveAdmin(GetUserAdmin(client));
		g_bIsAdmin[client] = 0;
	}
	if (g_bSDKHooksLoaded)
	{
		SDKUnhook(client, SDKHookType:2, Users_OnTakeDamage);
		new var1;
		if (!g_bMapsNoGiveWeapons && g_iGame != GameType:3 && g_bClientWeaponEquip[client])
		{
			SDKUnhook(client, SDKHookType:32, Users_WeaponEquipPost);
			g_bClientWeaponEquip[client] = 0;
		}
	}
	new var2;
	if (g_bPlayerVip[client][2] && g_iPlayerVip[client][2] && g_bPlayerAlive[client])
	{
		SetTrieValue(g_hUsersJoinCache, g_sClientAuth[client][0], any:1, true);
		g_bJoinClass = true;
	}
	iBuffer = 0;
	while (iBuffer <= 18)
	{
		g_iPlayerVip[client][iBuffer] = 0;
		new var3 = false;
		g_bPlayerVipEdit[client][iBuffer] = var3;
		g_bPlayerVip[client][iBuffer] = var3;
		iBuffer++;
	}
	iBuffer = 0;
	while (iBuffer <= 12)
	{
		strcopy(g_sWeapon[client][iBuffer], 64, NULL_STRING);
		iBuffer++;
	}
	iBuffer = 0;
	while (iBuffer <= 4)
	{
		g_bUsersStatus[client][iBuffer] = false;
		iBuffer++;
	}
	strcopy(g_sClientAuth[client][0], 32, NULL_STRING);
	strcopy(g_sClientAuth[client][1], 32, NULL_STRING);
	strcopy(g_sUsersClanTag[client], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][0], 64, NULL_STRING);
	strcopy(g_sVipFlags[client][1], 64, NULL_STRING);
	strcopy(g_sVipFlags[client][2], 64, NULL_STRING);
	strcopy(g_sVipFlags[client][3], 64, NULL_STRING);
	g_bWelcome[client] = 0;
	g_bPlayerAlive[client] = 0;
	g_bSettingsChanged[client] = 0;
	g_iClientAuth[client] = 0;
	g_iClientTeam[client] = 0;
	return 0;
}

public OnConfigsExecuted()
{
	if (!g_bBetaTest)
	{
		return 0;
	}
	g_iMaxClients = MaxClients;
	new i = 1;
	while (i <= g_iMaxClients)
	{
		if (IsClientInGame(i))
		{
			g_iClientTeam[i] = GetClientTeam(i);
			g_bPlayerAlive[i] = IsPlayerAlive(i);
			OnClientPutInServer(i);
		}
		i++;
	}
	g_bFriendLyFire = GetConVarBool(FindConVar("mp_friendlyfire"));
	if (g_hUsersExpiresTimer)
	{
		KillTimer(g_hUsersExpiresTimer, false);
	}
	g_hUsersExpiresTimer = CreateTimer(300.0, Timer_UsersExpires, any:0, 1);
	return 0;
}

public bool:GetUsersTrie(client, String:buffer[], maxlen)
{
	decl temp;
	if (GetTrieValue(g_hUsersTrie, g_sClientAuth[client][0], temp))
	{
		strcopy(buffer, maxlen, g_sClientAuth[client][0]);
		g_iClientAuth[client] = 0;
		return true;
	}
	if (GetTrieValue(g_hUsersTrie, g_sClientAuth[client][1], temp))
	{
		strcopy(buffer, maxlen, g_sClientAuth[client][1]);
		g_iClientAuth[client] = 1;
		return true;
	}
	return false;
}

public UsersLoadFlags(client)
{
	decl String:sBuffer[128];
	decl iBuffer;
	if (GetUsersTrie(client, sBuffer, 128))
	{
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, sBuffer, false))
		{
			KvGetString(g_hKvUsers, "expires", g_sUsersExpires[client], 32, "never");
			new var1;
			if (!StrEqual(g_sUsersExpires[client], "never", false) && GetTime({0,0}) >= StringToInt(g_sUsersExpires[client], 10))
			{
				KvGetString(g_hKvUsers, "name", sBuffer, 128, "unnamed");
				KvDeleteThis(g_hKvUsers);
				KvRewind(g_hKvUsers);
				new var2 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var2[0][var2]);
				CloseHandle(g_hKvUsers);
				g_hKvUsers = CreateKeyValues("Users", "", "");
				new var3 = g_sUsersPath;
				FileToKeyValues(g_hKvUsers, var3[0][var3]);
				Vip_Log("???????? VIP ??????? ? %s (????: %s). ???????: (??????? ?????)", sBuffer, g_sClientAuth[client][g_iClientAuth[client]]);
			}
			KvGetString(g_hKvUsers, "group", sBuffer, 128, "");
			if (GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer))
			{
				KvRewind(g_hKvUsersGroups);
				if (KvJumpToKey(g_hKvUsersGroups, sBuffer, false))
				{
					UsersSetFlags(g_hKvUsersGroups, client);
				}
			}
			else
			{
				UsersSetFlags(g_hKvUsers, client);
			}
			if (!g_bWelcome[client])
			{
				CreateTimer(6.99, Timer_WelcomeMsg, GetClientUserId(client), 2);
			}
		}
	}
	return 0;
}

public UsersSetFlags(Handle:hKV, client)
{
	new String:sBuffer[2][128] = "\x08";
	decl iBuffer[2];
	KvGetString(hKV, "flags", sBuffer[0][sBuffer], 128, "");
	iBuffer[0] = strlen(sBuffer[0][sBuffer]);
	iBuffer--;
	if (iBuffer[0] > 0)
	{
		new i;
		while (iBuffer[0] >= i)
		{
			Format(sBuffer[1], 128, "%c", sBuffer[0][sBuffer][i]);
			if (GetTrieValue(g_hUsersFlagsTrie, sBuffer[1], iBuffer[1]))
			{
				g_bPlayerVip[client][iBuffer[1]] = true;
				switch (iBuffer[1])
				{
					case 0, 7, 11:
					{
						g_iPlayerVip[client][iBuffer[1]] = 2;
					}
					case 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 17, 18:
					{
						g_iPlayerVip[client][iBuffer[1]] = 1;
					}
					case 3:
					{
						g_iPlayerVip[client][iBuffer[1]] = 16000;
					}
					case 14:
					{
						g_iPlayerVip[client][iBuffer[1]] = 100;
					}
					case 16:
					{
						g_iPlayerVip[client][iBuffer[1]] = 0;
					}
					default:
					{
						i++;
					}
				}
			}
			i++;
		}
		if (g_bPlayerVip[client][2])
		{
			new i;
			while (i <= 4)
			{
				g_bUsersStatus[client][i] = true;
				i++;
			}
		}
		if (g_bPlayerVip[client][4])
		{
			strcopy(g_sWeapon[client][0], 64, "ak47");
			strcopy(g_sWeapon[client][1], 64, "m4a1");
			strcopy(g_sWeapon[client][2], 64, "deagle");
			strcopy(g_sWeapon[client][3], 64, "deagle");
			strcopy(g_sWeapon[client][4], 64, "setup");
			strcopy(g_sWeapon[client][5], 64, "grenades");
			strcopy(g_sWeapon[client][6], 64, "vesthelm");
			strcopy(g_sWeapon[client][7], 64, "defuser");
			strcopy(g_sWeapon[client][8], 64, "nvgs");
			strcopy(g_sWeapon[client][9], 64, "auto");
			strcopy(g_sWeapon[client][10], 64, "auto");
			strcopy(g_sWeapon[client][11], 64, "drop");
			strcopy(g_sWeapon[client][12], 64, "reload");
		}
		UsersLoadSettingsFlags(client);
	}
	return 0;
}

public Action:Timer_WelcomeMsg(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && !g_bWelcome[client] && IsClientInGame(client))
	{
		VipPrint(client, "????? ??????????, %N!", client);
		if (!StrEqual(g_sUsersExpires[client], "never", false))
		{
			decl String:sBuffer[256];
			FormatTime(sBuffer, 256, "???? VIP ?????????? ?????????????: [%d.%m.%Y : %H.%M.%S]", StringToInt(g_sUsersExpires[client], 10));
			VipPrint(client, sBuffer);
		}
		g_bWelcome[client] = 1;
	}
	return Action:4;
}

public Native_Log(Handle:plugin, numParams)
{
	decl String:sBuffer[256];
	FormatNativeString(0, 1, 2, 256, 0, sBuffer, "");
	LogToFileEx(g_sLogPath, "%s", sBuffer);
	return 0;
}

public Native_IsClientVip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (!client || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	new j;
	while (j <= 18)
	{
		if (g_bPlayerVip[client][j])
		{
			return 1;
		}
		j++;
	}
	return 0;
}

public Native_IsClientVipStatus(Handle:plugin, numParams)
{
	decl iBuffer[2];
	iBuffer[0] = GetNativeCell(1);
	iBuffer[1] = GetNativeCell(2);
	new var1;
	if (!iBuffer[0] || !IsClientConnected(iBuffer[0]))
	{
		ThrowNativeError(7, "Client index %i is invalid", iBuffer);
	}
	new var2;
	if (g_bPlayerVip[iBuffer[0]][2] && g_iPlayerVip[iBuffer[0]][2] && g_bUsersStatus[iBuffer[0]][iBuffer[1]])
	{
		return 1;
	}
	return 0;
}

public Native_StatusAddPlugin(Handle:plugin, numParams)
{
	new count = GetNativeCell(1);
	if (count > 4)
	{
		ThrowNativeError(7, "Plugin index %i is invalid", count);
	}
	if (0 < GetNativeCell(2))
	{
		new var1 = g_bUsersStatus;
		var1[0][var1][count] = true;
	}
	else
	{
		new var2 = g_bUsersStatus;
		var2[0][var2][count] = false;
	}
	return 0;
}

public bool:isUsersStatus(index)
{
	new j;
	while (j <= 4)
	{
		if (g_bUsersStatus[index][j])
		{
			return true;
		}
		j++;
	}
	return false;
}

public Native_VipPrint(Handle:plugin, numParams)
{
	decl client;
	decl String:sBuffer[256];
	client = GetNativeCell(1);
	new var1;
	if (!client || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	FormatNativeString(0, 2, 3, 256, 0, sBuffer, "");
	if (g_iGame == GameType:3)
	{
		PrintToChat(client, "\x01\x04[VIP]\x01 %s", sBuffer);
	}
	else
	{
		PrintToChat(client, "\x04[VIP]\x01 %s", sBuffer);
	}
	return 0;
}

public Native_VipPrintError(Handle:plugin, numParams)
{
	decl client;
	decl String:sBuffer[256];
	client = GetNativeCell(1);
	new var1;
	if (!client || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	FormatNativeString(0, 2, 3, 256, 0, sBuffer, "");
	if (g_iGame == GameType:3)
	{
		PrintToChat(client, "\x01\x04[VIP]\x01 %s", sBuffer);
	}
	else
	{
		PrintToChat(client, "\x04[VIP]\x01 %s", sBuffer);
	}
	EmitSoundToClient(client, "buttons/button11.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	return 0;
}

public Action:Timer_UsersExpires(Handle:timer)
{
	new String:sBuffer[2][256] = "\x08";
	decl iBuffer[2];
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		iBuffer[0] = 0;
		iBuffer[1] = GetTime({0,0});
		do {
			if (KvGetSectionName(g_hKvUsers, sBuffer[0][sBuffer], 256))
			{
				KvGetString(g_hKvUsers, "expires", sBuffer[1], 256, "never");
				new var1;
				if (!StrEqual(sBuffer[1], "never", false) && iBuffer[1] >= StringToInt(sBuffer[1], 10))
				{
					PushArrayString(g_hArrayUsersExpires, sBuffer[0][sBuffer]);
					iBuffer++;
				}
			}
		} while (KvGotoNextKey(g_hKvUsers, false));
		iBuffer--;
		if (0 < iBuffer[0])
		{
			new i;
			while (iBuffer[0] >= i)
			{
				KvRewind(g_hKvUsers);
				GetArrayString(g_hArrayUsersExpires, i, sBuffer[0][sBuffer], 256);
				if (KvJumpToKey(g_hKvUsers, sBuffer[0][sBuffer], false))
				{
					DeleteUserSettings(sBuffer[0][sBuffer]);
					ResettingTheFlags(sBuffer[0][sBuffer]);
					KvGetString(g_hKvUsers, "identity", sBuffer[1], 256, "none");
					KvDeleteThis(g_hKvUsers);
					RemoveFromTrie(g_hUsersTrie, sBuffer[0][sBuffer]);
					Vip_Log("???????? VIP ??????? ? %s (????: %s). ???????: (??????? ?????)", sBuffer[0][sBuffer], sBuffer[1]);
				}
				i++;
			}
			KvRewind(g_hKvUsers);
			new var2 = g_sUsersPath;
			KeyValuesToFile(g_hKvUsers, var2[0][var2]);
			CloseHandle(g_hKvUsers);
			g_hKvUsers = CreateKeyValues("Users", "", "");
			new var3 = g_sUsersPath;
			FileToKeyValues(g_hKvUsers, var3[0][var3]);
			ClearArray(g_hArrayUsersExpires);
		}
	}
	return Action:0;
}

public SetPlayerMoney(client, amount)
{
	SetEntData(client, g_iAccountOffset, amount, 4, true);
	return 0;
}

public GetPlayerMoney(client)
{
	return GetEntData(client, g_iAccountOffset, 4);
}

public SetPlayerHealth(client, health)
{
	SetEntData(client, g_iHealthOffset, health, 4, true);
	return 0;
}

public GetPlayerHealth(client)
{
	return GetEntData(client, g_iHealthOffset, 4);
}

public SetPlayerNightVision(client)
{
	SetEntData(client, g_iNightVisionOffset, any:1, 1, true);
	return 0;
}

public GetPlayerNightVision(client)
{
	return GetEntData(client, g_iNightVisionOffset, 1);
}

public SetPlayerArmor(client, armor)
{
	SetEntData(client, g_iArmorOffset, armor, 4, true);
	return 0;
}

public GetPlayerArmor(client)
{
	return GetEntData(client, g_iArmorOffset, 4);
}

public SetPlayerSpeed(client, Float:speed)
{
	SetEntDataFloat(client, g_iSpeedOffset, speed, true);
	return 0;
}

public Float:GetPlayerSpeed(client)
{
	return GetEntDataFloat(client, g_iSpeedOffset);
}

public SetPlayerAlphaBlind(client)
{
	SetEntDataFloat(client, g_iFlashOffset[0], 0.5, true);
	SetEntDataFloat(client, g_iFlashOffset[1], 0.0, true);
	ClientCommand(client, "dsp_player 0.0");
	return 0;
}

public SetPlayerDefuser(client)
{
	SetEntData(client, g_iDefuserOffset, any:1, 1, true);
	return 0;
}

public GetPlayerDefuser(client)
{
	return GetEntData(client, g_iDefuserOffset, 1);
}

public GetPlayerGrenade(client, cell)
{
	return GetEntProp(client, PropType:1, "m_iAmmo", 4, cell);
}

public SetPlayerGrenade(client, count, cell)
{
	SetEntProp(client, PropType:1, "m_iAmmo", count, 4, cell);
	return 0;
}

public SetPlayerGravity(client, Float:amount)
{
	SetEntPropFloat(client, PropType:1, "m_flGravity", amount, 0);
	return 0;
}

public Float:GetPlayerGravity(client)
{
	return GetEntPropFloat(client, PropType:1, "m_flGravity", 0);
}

public SetPlayerFrags(client, frags)
{
	SetEntProp(client, PropType:1, "m_iFrags", frags, 4, 0);
	return 0;
}

public GetPlayerFrags(client)
{
	return GetEntProp(client, PropType:1, "m_iFrags", 4, 0);
}

public PlayerReArmor(client, value)
{
	new iArmor = GetPlayerArmor(client);
	new var1;
	if (iArmor > 0 && value != iArmor)
	{
		SetPlayerArmor(client, value);
	}
	return 0;
}

public SetWeaponSilencer(client, slot)
{
	new iBuffer = GetPlayerWeaponSlot(client, slot);
	SetEntData(iBuffer, g_iSilencerOffset[slot], any:1, 1, false);
	if (g_iGame != GameType:2)
	{
		SetEntData(iBuffer, g_iSilencerOffset[slot + 2], any:1, 1, false);
	}
	return 0;
}

public GetWeaponSilencer(client, slot)
{
	return GetEntData(GetPlayerWeaponSlot(client, slot), g_iSilencerOffset[slot], 1);
}

public Action:KAC_OnCheatDetected(client, execution, bantime)
{
	decl temp;
	new var2;
	if (GetTrieValue(g_hUsersTrie, g_sClientAuth[client][0], temp) && (execution == 1 || execution == 2))
	{
		return Action:3;
	}
	return Action:0;
}

public Action:SMAC_OnCheatDetected(client, String:module[])
{
	decl temp;
	new var1;
	if (StrEqual(module, "smac_autotrigger.smx", false) && GetTrieValue(g_hUsersTrie, g_sClientAuth[client][0], temp))
	{
		return Action:3;
	}
	return Action:0;
}

public OnPluginEnd()
{
	new var1;
	if (g_bBetaTest && g_iGame != GameType:2)
	{
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var2;
			if (IsClientInGame(i) && IsClientVipStatus(i, 0))
			{
				CS_SetClientClanTag(i, g_sUsersClanTag[i]);
			}
			i++;
		}
	}
	return 0;
}

