public PlVers:__version =
{
	version = 5,
	filevers = "1.6.3",
	date = "12/07/2017",
	time = "22:46:03"
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
	name = "vip_interface005",
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
	name = "SDKHooks",
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
public SharedPlugin:__pl_restrict =
{
	name = "weaponrestrict",
	file = "weapon_restrict.smx",
	required = 0,
};
new Handle:hWeaponInfoTrie;
new String:weaponNames[55][0];
new WeaponType:weaponGroups[55] =
{
	11, 0, 0, 4, 5, 2, 9, 1, 3, 5, 0, 0, 1, 4, 3, 3, 0, 4, 1, 7, 2, 3, 1, 4, 5, 0, 3, 3, 8, 1, 10, 6, 6, 9, 3, 1, 2, 7, 2, 0, 12, 0, 1, 1, 2, 0, 3, 4, 3, 4, 8, 5, 5, 5, 9
};
new WeaponSlot:weaponSlots[55] =
{
	5, 1, 1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0, 5, -1, -1, -1, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 2, 3, 3, 3, -1
};
new BuyTeams[55] =
{
	-1, 0, 0, 0, 0, 0, 2, 2, 3, 0, 2, 3, 0, 3, 2, 3, 0, 0, 0, 0, 0, 3, 3, 2, 0, 0, 2, 2, 0, 0, -1, 0, 0, 0, 2, 0, 3, 0, 2, 2, 0, 0, 0, 3, 0, 0, -1, 3, 2, 0, 0, 2, 0, 3, 3
};
new bool:g_bBetaTest;
public Plugin:myinfo =
{
	name = "Very Important Person",
	description = "Very Important Person",
	author = "GoDtm666",
	version = "beta_0.0.5",
	url = "www.MyArena.ru"
};
new GameType:g_iGame;
new String:g_sUsersPath[3][256];
new String:g_sAdminsPath[256];
new bool:g_sUsersOnAttribute[66];
new bool:g_sUsersOnPlayerRunCmd[66];
new String:g_sUsersModelsPath[256];
new Handle:g_hArrayModelsT;
new Handle:g_hArrayModelsCT;
new Handle:g_hArrayModelsPathT;
new Handle:g_hArrayModelsPathCT;
new Handle:g_hArrayModelsArmsT;
new Handle:g_hArrayModelsArmsCT;
new Handle:g_hArrayModelsArmsPathT;
new Handle:g_hArrayModelsArmsPathCT;
new String:g_sUsersModelsArmsT[66][256];
new String:g_sUsersModelsArmsCT[66][256];
new g_iArrayModelsT = -1;
new g_iArrayModelsCT = -1;
new String:g_sUsersModelsT[66][256];
new String:g_sUsersModelsCT[66][256];
new g_iUsersModelsT[66];
new g_iUsersModelsCT[66];
new bool:g_bUsersModelsT[66];
new bool:g_bUsersModelsCT[66];
new String:g_sDownloadsPath[256];
new String:g_sVipFlags[66][6][256];
new bool:g_bAddBase[66];
new bool:g_bGiveWeapons = 1;
new Handle:g_hKvUsers;
new Handle:g_hKvUsersGroups;
new Handle:g_hKvUsersSettings;
new g_iArrayUsers = -1;
new Handle:g_hArrayUsers;
new Handle:g_hArrayUsersExpires;
new Handle:g_hUsersGroupsTrie;
new Handle:g_hArrayUsersPassword;
new Handle:g_hAdminsAccessTrie;
new Handle:g_hKeyAdminsAuth;
new String:g_sKeyAdminsAuth[36] = "_vipadmin";
new Handle:g_hUsersFlagsTrie;
new Handle:g_hConVarFlashLight;
new bool:g_bFlashLight = 1;
new Handle:g_hConVarChatTag;
new String:g_sChatTag[32] = "[VIP]";
new g_iUsersChatTagsArray = -1;
new String:g_sUsersChatTag[66][32];
new String:g_sChatIgnoreCmdsPath[256];
new Handle:g_hChatIgnoreCmdsArray;
new g_iChatIgnoreCmdsArray = -1;
new String:g_sChatTagsPath[256];
new Handle:g_hChatTagsArray;
new Handle:g_hWeaponTrie;
new Handle:g_hWeaponAmmoTrie;
new Handle:g_hWeaponLowAmmoTrie;
new bool:g_bLowAmmoSound;
new Float:g_fLowAmmoSoundSpam[66];
new Handle:g_hChangeTeamArray;
new bool:g_bChangeTeam;
new Float:g_fTimerChat[66];
new bool:g_bAdminChat[66];
new Handle:g_hConVarClanTag;
new String:g_sClanTag[32] = "[VIP]";
new String:g_sUsersClanTags[256];
new Handle:g_hUsersClanTagsArray;
new g_iUsersClanTags = -1;
new String:g_sUsersClanTag[66][32];
new String:g_sUsersOldClanTag[66][32];
new g_iUsersMenuPosition[66];
new bool:g_bUsersAdmin[66];
new bool:g_bUsersVip[66];
new bool:g_bUsersCmds[66];
new g_iTarget[66];
new g_iTargetUserId[66];
new g_iTargetTime[66];
new Handle:g_hTimerRegeneration[66];
new Handle:g_hTimerHeartBeat[66];
new Handle:g_hTimerMedic[66][2];
new bool:g_bMedicWarnSound;
new bool:g_bMedicSuccesSound;
new Handle:g_hTimerMedicSpam[66];
new g_iLightning;
new g_iLightningColor[4] =
{
	255, ...
};
new Float:g_fMedicProgresBarPos[66];
new Float:g_fMedicProgresBarMax[66];
new bool:g_bHudHintSound = 1;
new g_iMedic[66];
new Float:g_fMedic[66];
new Float:g_fRegenTime[2] =
{
	1086953882, 1045220557
};
new String:g_sSoundHeartBeat[256] = "vip/heartbeat.mp3";
new Handle:g_hConVarRegenerationTimerStart;
new Handle:g_hConVarRegenerationTimerRegen;
new g_iRegenHP = 1;
new String:g_sMap[64];
new bool:g_bPlayerVip[66][39];
new g_iPlayerVip[66][39];
new Handle:g_hUsersWeaponArrayPrimary;
new Handle:g_hUsersWeaponArrayPistols;
new g_iUsersWeaponArrayPistols;
new Handle:g_hUsersWeaponArrayRifles;
new g_iUsersWeaponArrayRifles;
new Handle:g_hUsersWeaponArraySniper;
new g_iUsersWeaponArraySniper;
new Handle:g_hUsersWeaponArraySemiGun;
new g_iUsersWeaponArraySemiGun;
new Handle:g_hUsersWeaponArrayMachineGun;
new g_iUsersWeaponArrayMachineGun;
new Handle:g_hUsersWeaponArrayShotGun;
new g_iUsersWeaponArrayShotGun;
new g_iUsersWeaponTeam[66];
new bool:g_bUsersWeaponPrimaryT[66];
new bool:g_bUsersWeaponPrimaryCT[66];
new String:g_sUsersWeaponPrimaryT[66][32];
new String:g_sUsersWeaponPrimaryCT[66][32];
new bool:g_bUsersWeaponSecondaryT[66];
new bool:g_bUsersWeaponSecondaryCT[66];
new String:g_sUsersWeaponSecondaryT[66][32];
new String:g_sUsersWeaponSecondaryCT[66][32];
new bool:g_bUsersWeaponKnife[66];
new bool:g_bUsersWeaponVestHelm[66];
new bool:g_bUsersWeaponDefuser[66];
new bool:g_bUsersWeaponNvgs[66];
new Handle:g_hUsersWeaponMaxHeGrenade;
new Handle:g_hUsersWeaponMaxFlashBang;
new Handle:g_hUsersWeaponMaxSmokeGrenade;
new g_iUsersWeaponMaxHeGrenade = 1;
new g_iUsersWeaponMaxFlashBang = 2;
new g_iUsersWeaponMaxSmokeGrenade = 1;
new bool:g_bUsersWeaponGrenades[66];
new g_iUsersWeaponHeGrenade[66];
new g_iUsersWeaponFlashBang[66];
new g_iUsersWeaponSmokeGrenade[66];
new bool:g_bUsersWeaponPrimaryPlayerDies[66];
new bool:g_bUsersWeaponSecondaryPlayerDies[66];
new bool:g_bUsersGiveWeaponsItemPickUp[66];
new Handle:g_hUsersWeaponTimerItem;
new Handle:g_hCvarRestartGame;
new Handle:g_hCvarIgnoreRoundWinConditions;
new bool:g_bIgnoreRoundWinConditions;
new Handle:g_hCvarFriendlyFire;
new Handle:g_hCvarVipFriendlyFire;
new Handle:g_hFriendlyFireActiv;
new bool:g_bFriendlyFireActiv = 1;
new Handle:g_hUsersCmdsFlagsTrie;
new bool:g_bPlayerCmds[66][6];
new bool:g_bPlayerCmdsEdit[66][6];
new g_iUsersReplayCommands[66];
new String:g_sClientAuth[66][32];
new bool:g_bPlayerVipEdit[66][39];
new bool:g_bIsDeMap;
new String:g_sLogPath[256];
new String:g_sErrorLogPath[256];
new bool:g_bHealthChoose[66];
new g_iUsersExpires[66];
new g_iMoveTypeOffset[66] =
{
	-1, ...
};
new g_iAccountOffset = -1;
new g_iOwnerEntityOffset = -1;
new g_iAmmoOffset = -1;
new g_iPrimaryAmmoTypeOffset = -1;
new g_iSpeedOffset = -1;
new g_iStaminaOffset = -1;
new g_iVelocityModifier = -1;
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
new g_iFragsOffset[66] =
{
	-1, ...
};
new g_iGravityOffset[66] =
{
	-1, ...
};
new g_iImpulseOffset[66] =
{
	-1, ...
};
new g_iObserverModeOffset = -1;
new g_iObserverTargetOffset = -1;
new g_iRagdollOffset = -1;
new g_iMaxClients;
new g_iClientTeam[66];
new bool:g_bPlayerAlive[66];
new bool:g_bWelcome[66];
new Handle:g_hConVarUsersMaxHealth;
new g_iMaxHealth = 115;
new Handle:g_hConVarUsersMaxSpeed;
new g_iMaxSpeed = 10;
new g_iSetupBeam[2];
new Handle:g_hConVarUsersActivateRounds;
new g_iUsersActivateRounds;
new g_iActivateRounds;
new bool:g_bUsersActivate = 1;
new Handle:g_hCvarVersion;
new bool:g_bSettingsChanged[66];
new bool:g_bSDKHooksLoaded;
new bool:g_bWeaponRestrictLoaded;
new SocketStatus:EnumSocket;
new Handle:g_hSocketTimer;
new String:sSocketBuffer[2][256];
new bool:bReceive;
new Handle:g_hArrayList;
new g_iCountFile[2];
new Handle:g_hConVarDamage;
new Handle:g_hConVarLowDamage;
new Handle:g_hConVarModelsForceTime;
new Float:g_fModelsForceTime;
new String:g_sModelsForce[66][256];
new String:g_sModelsForceArm[66][256];
new g_iModelsForceTeam[66];
new bool:g_bFriendLyFire;
new Float:g_fDamage = 1068289229;
new Float:g_fLowDamage = 1068289229;
new bool:g_bHeartBeat;
new bool:g_bUsersHeartShaking[66];
new Handle:g_hArrayKickReason;
new String:g_sKickReasonPath[256];
new g_iArrayKickReason = -1;
new g_iClientUserId[66];
new String:g_sNotGiveOnMapListPath[256];
new String:g_sAdvertVipAccessPath[256];
new Handle:g_hAdvertVipAccessArray;
new g_iAdvertVipAccessArray = -1;
new Handle:g_hOnUsersLoadFlags;
new Handle:g_hOnUsersLoadFlags_Post;
new g_iVipUsersChatSettings;
new Handle:g_hConVarCashMax;
new g_iCashMax = 16000;
new Handle:g_hConVarCashDivisor;
new g_iCashDivisor = 400;
new Handle:g_hConVarWeaponRestrictImmune;
new Handle:g_hConVarWeaponRestrictImmuneBanalce;
new bool:g_bWeaponRestrictImmune = 1;
new g_iWeaponRestrictImmuneBalance = 2;
new Float:g_fUsersTimeSetPassword[66];
new bool:g_bWeaponRestrict[55];
new String:g_sWeaponRestrictPath[256];
new WeaponID:g_nWeaponID;
new bool:g_bNoRestrictOnWarmup = 1;
new bool:g_bVipFriendLyFire = 1;
new bool:g_bProtobufMessage;
new Handle:g_hTimerUsersLossSpeed[66];
new Float:g_fUsersLossSpeed[66];
new Handle:g_hConVarUsersLossMiniSpeedTimer;
new Float:g_fUsersMaxSpeedTimer = 1058642330;
new Handle:g_hConVarUsersLossMiniSpeed;
new Float:g_fUsersLossMiniSpeed = 1044549468;
new String:g_sWeaponColorsPath[256];
new bool:g_bColorWeapons;
new Handle:g_hArrayWeaponColorsT;
new Handle:g_hArrayWeaponColorsNamesT;
new g_iWeaponColorsSizeT;
new bool:g_bUsersWeaponColorsT[66];
new g_iUsersWeaponColorsT[66][4];
new String:g_sUsersWeaponColorsNamesT[66][256];
new Handle:g_hArrayWeaponColorsCT;
new Handle:g_hArrayWeaponColorsNamesCT;
new bool:g_bUsersWeaponColorsCT[66];
new g_iWeaponColorsSizeCT;
new g_iUsersWeaponColorsCT[66][4];
new String:g_sUsersWeaponColorsNamesCT[66][256];
new String:g_sGrenadeModelsPath[256];
new bool:g_bGrenadeModels;
new Handle:g_hArrayGrenadeModelsT;
new Handle:g_hArrayGrenadeModelsNamesT;
new bool:g_bUsersGrenadeModelsT[66];
new String:g_sUsersGrenadeModelsNamesT[66][256];
new String:g_sUsersGrenadeModelsT[66][256];
new g_iGrenadeModelsSizeT;
new Handle:g_hArrayGrenadeModelsCT;
new Handle:g_hArrayGrenadeModelsNamesCT;
new bool:g_bUsersGrenadeModelsCT[66];
new String:g_sUsersGrenadeModelsNamesCT[66][256];
new String:g_sUsersGrenadeModelsCT[66][256];
new g_iGrenadeModelsSizeCT;
new String:g_sGrenadeProjectile[24];
new Float:g_fUsersFireGrenade[3];
new bool:g_bSourceComms_GetClientGagType;
new Handle:g_hKeyVipAuth;
new String:g_sKeyVipAuth[36] = "_vip";
new Float:g_fUsersKillEffect[66];
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

RoundFloat(Float:value)
{
	return RoundToNearest(value);
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:operator/(_:,Float:)(oper1, Float:oper2)
{
	return float(oper1) / oper2;
}

Float:operator+(Float:,_:)(Float:oper1, oper2)
{
	return oper1 + float(oper2);
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) == 0;
}

bool:operator==(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) == 0;
}

bool:operator!=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) != 0;
}

bool:operator!=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) != 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) > 0;
}

bool:operator>=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) >= 0;
}

bool:operator<(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) < 0;
}

bool:operator<(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) < 0;
}

bool:operator<=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) <= 0;
}

CharToLower(chr)
{
	if (IsCharUpper(chr))
	{
		return chr | 32;
	}
	return chr;
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

GetEntSendPropOffs(ent, String:prop[], bool:actual)
{
	decl String:cls[64];
	if (!GetEntityNetClass(ent, cls, 64))
	{
		return -1;
	}
	if (actual)
	{
		return FindSendPropInfo(cls, prop, 0, 0, 0);
	}
	return FindSendPropOffs(cls, prop);
}

bool:GetEntityClassname(entity, String:clsname[], maxlength)
{
	return !!GetEntPropString(entity, PropType:1, "m_iClassname", clsname, maxlength, 0);
}

RenderMode:GetEntityRenderMode(entity)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nRenderMode", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_nRenderMode");
		}
		gotconfig = true;
	}
	return GetEntProp(entity, PropType:0, prop, 1, 0);
}

SetEntityRenderMode(entity, RenderMode:mode)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nRenderMode", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_nRenderMode");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:0, prop, mode, 1, 0);
	return 0;
}

SetEntityRenderColor(entity, r, g, b, a)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_clrRender");
		}
		gotconfig = true;
	}
	new offset = GetEntSendPropOffs(entity, prop, false);
	if (0 >= offset)
	{
		ThrowError("SetEntityRenderColor not supported by this mod");
	}
	SetEntData(entity, offset, r, 1, true);
	SetEntData(entity, offset + 1, g, 1, true);
	SetEntData(entity, offset + 2, b, 1, true);
	SetEntData(entity, offset + 3, a, 1, true);
	return 0;
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

TE_SendToClient(client, Float:delay)
{
	new players[1];
	players[0] = client;
	return TE_Send(players, 1, delay);
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

public __ext_topmenus_SetNTVOptional()
{
	MarkNativeAsOptional("CreateTopMenu");
	MarkNativeAsOptional("LoadTopMenuConfig");
	MarkNativeAsOptional("AddToTopMenu");
	MarkNativeAsOptional("RemoveFromTopMenu");
	MarkNativeAsOptional("DisplayTopMenu");
	MarkNativeAsOptional("DisplayTopMenuCategory");
	MarkNativeAsOptional("FindTopMenuCategory");
	MarkNativeAsOptional("SetTopMenuTitleCaching");
	return 0;
}

public __pl_adminmenu_SetNTVOptional()
{
	MarkNativeAsOptional("GetAdminTopMenu");
	MarkNativeAsOptional("AddTargetsToMenu");
	MarkNativeAsOptional("AddTargetsToMenu2");
	return 0;
}

public __pl_restrict_SetNTVOptional()
{
	MarkNativeAsOptional("Restrict_RefundMoney");
	MarkNativeAsOptional("Restrict_RemoveRandom");
	MarkNativeAsOptional("Restrict_GetTeamWeaponCount");
	MarkNativeAsOptional("Restrict_GetRestrictValue");
	MarkNativeAsOptional("Restrict_GetWeaponIDExtended");
	MarkNativeAsOptional("Restrict_GetClientGrenadeCount");
	MarkNativeAsOptional("Restrict_GetWeaponIDFromSlot");
	MarkNativeAsOptional("Restrict_RemoveSpecialItem");
	MarkNativeAsOptional("Restrict_CanBuyWeapon");
	MarkNativeAsOptional("Restrict_CanPickupWeapon");
	MarkNativeAsOptional("Restrict_IsSpecialRound");
	MarkNativeAsOptional("Restrict_IsWarmupRound");
	MarkNativeAsOptional("Restrict_HasSpecialItem");
	MarkNativeAsOptional("Restrict_SetRestriction");
	MarkNativeAsOptional("Restrict_SetGroupRestriction");
	MarkNativeAsOptional("Restrict_GetRoundType");
	MarkNativeAsOptional("Restrict_CheckPlayerWeapons");
	MarkNativeAsOptional("Restrict_RemoveWeaponDrop");
	MarkNativeAsOptional("Restrict_ImmunityCheck");
	MarkNativeAsOptional("Restrict_AllowedForSpecialRound");
	MarkNativeAsOptional("Restrict_PlayRestrictSound");
	MarkNativeAsOptional("Restrict_AddToOverride");
	MarkNativeAsOptional("Restrict_RemoveFromOverride");
	MarkNativeAsOptional("Restrict_IsWeaponInOverride");
	MarkNativeAsOptional("Restrict_IsWarmupWeapon");
	return 0;
}

InitWeaponInfoTrie()
{
	hWeaponInfoTrie = CreateTrie();
	new info[4];
	new i;
	while (i < 55)
	{
		info[0] = i;
		info[1] = weaponSlots[i];
		info[2] = weaponGroups[i];
		new var1;
		if (i == 10 && GetEngineVersion() == 12)
		{
			info[3] = 0;
		}
		else
		{
			info[3] = BuyTeams[i];
		}
		SetTrieArray(hWeaponInfoTrie, weaponNames[i], info, 4, true);
		i++;
	}
	return 0;
}

WeaponID:GetWeaponID(String:weapon[])
{
	decl info[4];
	if (GetWeaponInfo(weapon, info))
	{
		return info[0];
	}
	return WeaponID:0;
}

bool:GetWeaponInfo(String:weapon[], info[4])
{
	if (!hWeaponInfoTrie)
	{
		InitWeaponInfoTrie();
	}
	decl String:CheckWeapon[64];
	strcopy(CheckWeapon, 64, weapon);
	new len = strlen(weapon);
	new i;
	while (i < len)
	{
		CheckWeapon[i] = CharToLower(weapon[i]);
		i++;
	}
	if (GetTrieArray(hWeaponInfoTrie, CheckWeapon, info, 4, 0))
	{
		return true;
	}
	new var1;
	if (ReplaceString(CheckWeapon, 64, "weapon_", "", false) == 1 || ReplaceString(CheckWeapon, 64, "item_", "", false) == 1)
	{
		if (GetTrieArray(hWeaponInfoTrie, CheckWeapon, info, 4, 0))
		{
			return true;
		}
	}
	return false;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new EngineVersion:iEngine = GetEngineVersion();
	BuildPath(PathType:0, g_sLogPath, 256, "logs/vip.log");
	BuildPath(PathType:0, g_sErrorLogPath, 256, "logs/vip_error.log");
	CreateNative("Vip_Log", Native_Log);
	CreateNative("Vip_ErrorLog", Native_ErrorLog);
	CreateNative("IsClientVip", Native_IsClientVip);
	CreateNative("IsClientVipCmds", Native_IsClientVipCmds);
	CreateNative("IsClientVipImmune", Native_IsClientVipImmune);
	CreateNative("SetVipUsersFlags", Native_SetVipUsersFlags);
	CreateNative("isVipUsersGroups", Native_isVipUsersGroups);
	CreateNative("SetVipUsersGroups", Native_SetVipUsersGroups);
	CreateNative("VipUsersDelete", Native_VipUsersDelete);
	CreateNative("VipUsersGetExpires", Native_VipUsersGetExpires);
	CreateNative("VipPrint", Native_VipPrint);
	CreateNative("VipUsersChatSettings", Native_VipUsersChatSettings);
	CreateNative("GetVipUsersChatSettings", Native_GetVipUsersChatSettings);
	CreateNative("GetVipUsersAttribute", Native_GetVipUsersAttribute);
	g_hOnUsersLoadFlags = CreateGlobalForward("Vip_OnUsersLoadFlags", ExecType:2, 2, 7);
	g_hOnUsersLoadFlags_Post = CreateGlobalForward("Vip_OnUsersLoadFlags_Post", ExecType:2, 2, 7, 2, 2, 2);
	if (iEngine == EngineVersion:2)
	{
		g_iGame = MissingTAG:2;
	}
	else
	{
		if (iEngine == EngineVersion:13)
		{
			g_iGame = MissingTAG:1;
		}
		if (iEngine == EngineVersion:12)
		{
			g_iGame = MissingTAG:3;
		}
		Format(error, err_max, "Данный мод не поддерживается!");
		return APLRes:1;
	}
	MarkNativeAsOptional("SourceComms_GetClientGagType");
	g_bSourceComms_GetClientGagType = GetFeatureStatus(FeatureType:0, "SourceComms_GetClientGagType") == 0;
	new var1;
	g_bProtobufMessage = GetFeatureStatus(FeatureType:0, "GetUserMessageType") && GetUserMessageType() == 1;
	RegPluginLibrary("vip_interface005");
	return APLRes:0;
}

public Admins_Init()
{
	BuildPath(PathType:0, g_sAdminsPath, 256, "data/vip/users_admins.ini");
	g_hAdminsAccessTrie = CreateTrie();
	RegConsoleCmd("vip_admin_pw", Admin_PasswordCommand, "Консольная команда авторизации админскии через пароль", 0);
	RegConsoleCmd("vip_admin_password", Admin_PasswordCommand, "Консольная команда авторизации админскии через пароль", 0);
	g_hKeyAdminsAuth = CreateConVar("vip_admin_key_auth", "_vipadmin", "Админский ключ авторизации пароля через setinfo. (Пример: setinfo _vipadmin \"Пароль\")", 262144, false, 0.0, false, 0.0);
	HookConVarChange(g_hKeyAdminsAuth, AdminsSettingsChanged);
	return 0;
}

public AdminsSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	GetConVarString(convar, g_sKeyAdminsAuth, 34);
	Vip_Log("ConVar : \"%s\" = \"%s\"", sBuffer, g_sKeyAdminsAuth);
	return 0;
}

public Action:Admin_PasswordCommand(client, args)
{
	if (client)
	{
		if (g_bUsersAdmin[client])
		{
			VipPrint(client, enSound:2, "Вы уже авторизованы!");
		}
		else
		{
			decl String:sBuffer[64];
			decl String:sPassword[64];
			decl String:sAuth[64];
			if (GetCmdArgString(sPassword, 64))
			{
				StripQuotes(sPassword);
				if (GetTrieString(g_hAdminsAccessTrie, g_sClientAuth[client], sBuffer, 64, 0))
				{
					new var1;
					if (strcmp(sBuffer, NULL_STRING, false) && strcmp(sBuffer, sPassword, false))
					{
					}
				}
				new var2;
				if (GetClientName(client, sAuth, 64) && GetTrieString(g_hAdminsAccessTrie, sAuth, sBuffer, 64, 0))
				{
					new var3;
					if (strcmp(sBuffer, NULL_STRING, false) && strcmp(sBuffer, sPassword, false))
					{
					}
				}
				if (GetClientIP(client, sAuth, 64, true))
				{
					Format(sAuth, 64, "!%s", sAuth);
					if (GetTrieString(g_hAdminsAccessTrie, sAuth, sBuffer, 64, 0))
					{
						new var4;
						if (strcmp(sBuffer, NULL_STRING, false) && strcmp(sBuffer, sPassword, false))
						{
						}
					}
				}
				if (g_bUsersAdmin[client])
				{
					VipPrint(client, enSound:1, "Авторизация успешно пройдена.");
					g_sUsersOnAttribute[client] = 1;
				}
				new var5;
				if (g_sUsersOnAttribute[client] && !g_bUsersCmds[client] && !g_bUsersVip[client])
				{
					g_sUsersOnAttribute[client] = 0;
				}
				VipPrint(client, enSound:2, "Ошибка авторизации!");
			}
		}
		return Action:3;
	}
	return Action:0;
}

public bool:LoadAdminString(String:buffer[])
{
	decl String:sBuffer[64];
	decl String:sPassword[64];
	new position = BreakString(buffer, sBuffer, 64);
	if (position == -1)
	{
		return SetTrieString(g_hAdminsAccessTrie, sBuffer, NULL_STRING, false);
	}
	strcopy(sPassword, 64, buffer[position]);
	StripQuotes(sPassword);
	return SetTrieString(g_hAdminsAccessTrie, sBuffer, sPassword, false);
}

public bool:isUsersAdmin(client)
{
	decl String:sBuffer[64];
	decl String:sPassword[64];
	if (GetTrieString(g_hAdminsAccessTrie, g_sClientAuth[client], sPassword, 64, 0))
	{
		new var2;
		return strcmp(sPassword, NULL_STRING, false) && (GetClientInfo(client, g_sKeyAdminsAuth, sBuffer, 64) && strcmp(sPassword, sBuffer, false));
	}
	new var3;
	if (GetClientName(client, sBuffer, 64) && GetTrieString(g_hAdminsAccessTrie, sBuffer, sPassword, 64, 0))
	{
		new var4;
		return GetClientInfo(client, g_sKeyAdminsAuth, sBuffer, 64) && strcmp(sPassword, sBuffer, false);
	}
	if (GetClientIP(client, sBuffer, 64, true))
	{
		Format(sBuffer, 64, "!%s", sBuffer);
		if (GetTrieString(g_hAdminsAccessTrie, sBuffer, sPassword, 64, 0))
		{
			new var6;
			return strcmp(sPassword, NULL_STRING, false) && (GetClientInfo(client, g_sKeyAdminsAuth, sBuffer, 64) && strcmp(sPassword, sBuffer, false));
		}
	}
	return false;
}

public Users_Init()
{
	g_hArrayUsers = CreateArray(64, 0);
	g_hArrayUsersExpires = CreateArray(64, 0);
	g_hArrayUsersPassword = CreateArray(64, 0);
	new var1 = g_sUsersPath;
	BuildPath(PathType:0, var1[0][var1], 256, "data/vip/users.ini");
	BuildPath(PathType:0, g_sUsersPath[1], 256, "data/vip/users_groups.ini");
	BuildPath(PathType:0, g_sUsersPath[2], 256, "data/vip/users_settings.ini");
	g_hUsersFlagsTrie = CreateTrie();
	SetTrieValue(g_hUsersFlagsTrie, "0a", any:0, false);
	SetTrieValue(g_hUsersFlagsTrie, "0b", any:1, false);
	SetTrieValue(g_hUsersFlagsTrie, "0c", any:2, false);
	SetTrieValue(g_hUsersFlagsTrie, "0d", any:3, false);
	SetTrieValue(g_hUsersFlagsTrie, "0e", any:4, false);
	SetTrieValue(g_hUsersFlagsTrie, "0f", any:5, false);
	SetTrieValue(g_hUsersFlagsTrie, "0g", any:6, false);
	SetTrieValue(g_hUsersFlagsTrie, "0h", any:8, false);
	SetTrieValue(g_hUsersFlagsTrie, "0i", any:9, false);
	SetTrieValue(g_hUsersFlagsTrie, "0j", any:10, false);
	SetTrieValue(g_hUsersFlagsTrie, "0k", any:11, false);
	SetTrieValue(g_hUsersFlagsTrie, "0l", any:12, false);
	SetTrieValue(g_hUsersFlagsTrie, "0m", any:13, false);
	SetTrieValue(g_hUsersFlagsTrie, "0n", any:14, false);
	SetTrieValue(g_hUsersFlagsTrie, "0o", any:15, false);
	SetTrieValue(g_hUsersFlagsTrie, "0p", any:16, false);
	SetTrieValue(g_hUsersFlagsTrie, "0q", any:17, false);
	SetTrieValue(g_hUsersFlagsTrie, "0r", any:18, false);
	SetTrieValue(g_hUsersFlagsTrie, "0s", any:19, false);
	SetTrieValue(g_hUsersFlagsTrie, "0t", any:20, false);
	SetTrieValue(g_hUsersFlagsTrie, "0u", any:21, false);
	SetTrieValue(g_hUsersFlagsTrie, "0v", any:22, false);
	SetTrieValue(g_hUsersFlagsTrie, "0w", any:23, false);
	SetTrieValue(g_hUsersFlagsTrie, "0y", any:25, false);
	if (g_iGame != GameType:2)
	{
		SetTrieValue(g_hUsersFlagsTrie, "0x", any:24, false);
	}
	SetTrieValue(g_hUsersFlagsTrie, "0z", any:26, false);
	SetTrieValue(g_hUsersFlagsTrie, "1a", any:27, false);
	SetTrieValue(g_hUsersFlagsTrie, "1b", any:28, false);
	SetTrieValue(g_hUsersFlagsTrie, "1c", any:29, false);
	SetTrieValue(g_hUsersFlagsTrie, "1d", any:30, false);
	SetTrieValue(g_hUsersFlagsTrie, "1e", any:7, false);
	SetTrieValue(g_hUsersFlagsTrie, "1f", any:31, false);
	SetTrieValue(g_hUsersFlagsTrie, "1g", any:32, false);
	SetTrieValue(g_hUsersFlagsTrie, "1h", any:33, false);
	SetTrieValue(g_hUsersFlagsTrie, "1i", any:34, false);
	SetTrieValue(g_hUsersFlagsTrie, "1j", any:35, false);
	SetTrieValue(g_hUsersFlagsTrie, "1k", any:36, false);
	SetTrieValue(g_hUsersFlagsTrie, "1l", any:37, false);
	SetTrieValue(g_hUsersFlagsTrie, "1m", any:38, false);
	g_hUsersCmdsFlagsTrie = CreateTrie();
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2a", any:0, false);
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2b", any:1, false);
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2c", any:2, false);
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2d", any:3, false);
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2e", any:4, false);
	SetTrieValue(g_hUsersCmdsFlagsTrie, "2f", any:5, false);
	RegAdminCmd("vip_users_add", Cmd_UsersAdd, 16384, "Добавить нового VIP игрока.", "", 0);
	RegAdminCmd("vip_users_groups", Cmd_UsersGroups, 16384, "Лист груп VIP.", "", 0);
	RegAdminCmd("vip_users_del", Cmd_UsersDelete, 16384, "Удалить VIP игрока.", "", 0);
	RegConsoleCmd("vip_set_password", Cmd_SetPassword, "Установка пароля VIP игрока.", 0);
	RegConsoleCmd("vip_password", Cmd_SetPassword, "Установка пароля VIP игрока.", 0);
	RegConsoleCmd("vip_pw", Cmd_SetPassword, "Установка пароля VIP игрока.", 0);
	g_hKeyVipAuth = CreateConVar("vip_vip_key_auth", "_vip", "VIP ключ авторизации пароля vip игрока через setinfo. (Пример: setinfo _vip \"Пароль\")", 262144, false, 0.0, false, 0.0);
	HookConVarChange(g_hKeyVipAuth, VipSettingsChanged);
	RegConsoleCmd("vip_users_password", Cmd_SetUsersPassword, "Установка пароля на SteamID VIP аккаунта.", 0);
	RegConsoleCmd("vip_users_pw", Cmd_SetUsersPassword, "Установка пароля на SteamID VIP аккаунта.", 0);
	return 0;
}

public VipSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	GetConVarString(convar, g_sKeyVipAuth, 34);
	Vip_Log("ConVar : \"%s\" = \"%s\"", sBuffer, g_sKeyVipAuth);
	return 0;
}

public UsersScan()
{
	decl String:sBuffer[256];
	if (g_hKvUsers)
	{
		CloseHandle(g_hKvUsers);
	}
	g_hKvUsers = CreateKeyValues("Users", "", "");
	new var1 = g_sUsersPath;
	if (FileToKeyValues(g_hKvUsers, var1[0][var1]))
	{
		if (g_iArrayUsers != -1)
		{
			ClearArray(g_hArrayUsers);
			ClearArray(g_hArrayUsersExpires);
			ClearArray(g_hArrayUsersPassword);
			g_iArrayUsers = -1;
		}
		KvRewind(g_hKvUsers);
		if (KvGotoFirstSubKey(g_hKvUsers, false))
		{
			do {
				KvGetSectionName(g_hKvUsers, sBuffer, 256);
				PushArrayString(g_hArrayUsers, sBuffer);
				PushArrayCell(g_hArrayUsersExpires, KvGetNum(g_hKvUsers, "expires", 0));
				KvGetString(g_hKvUsers, "password", sBuffer, 256, "#none");
				if (strlen(sBuffer))
				{
					PushArrayString(g_hArrayUsersPassword, sBuffer);
				}
				else
				{
					PushArrayString(g_hArrayUsersPassword, "");
				}
				g_iArrayUsers += 1;
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
			Vip_ErrorLog("Файл \"%s\" не найден!", g_sUsersPath[1]);
			CloseHandle(g_hKvUsersGroups);
		}
		return 0;
	}
	g_bBetaTest = false;
	new var2 = g_sUsersPath;
	Vip_ErrorLog("Файл \"%s\" не найден!", var2[0][var2]);
	CloseHandle(g_hKvUsers);
	return 0;
}

public bool:isUsersVipPassword(client, String:password[])
{
	decl String:sBuffer[64];
	new var1;
	return GetClientInfo(client, g_sKeyVipAuth, sBuffer, 64) && strcmp(sBuffer, password, false);
}

public bool:UsersLoadFlags(client)
{
	decl String:sBuffer[128];
	decl String:sName[128];
	new iBuffer = FindStringInArray(g_hArrayUsers, g_sClientAuth[client]);
	if (iBuffer != -1)
	{
		GetArrayString(g_hArrayUsersPassword, iBuffer, sBuffer, 128);
		new var1;
		if (strlen(sBuffer) && strcmp(sBuffer, "#none", false) && !isUsersVipPassword(client, sBuffer))
		{
			KickClient(client, "Неверный пароль VIP аккаунта");
			return false;
		}
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, g_sClientAuth[client], false))
		{
			g_iUsersExpires[client] = GetArrayCell(g_hArrayUsersExpires, iBuffer, 0, false);
			new var2;
			if (g_iUsersExpires[client] && GetTime(395996) >= g_iUsersExpires[client])
			{
				KvGetString(g_hKvUsers, "name", sBuffer, 128, "unnamed");
				KvDeleteThis(g_hKvUsers);
				KvRewind(g_hKvUsers);
				new var4 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var4[0][var4]);
				CloseHandle(g_hKvUsers);
				g_hKvUsers = CreateKeyValues("Users", "", "");
				new var5 = g_sUsersPath;
				FileToKeyValues(g_hKvUsers, var5[0][var5]);
				RemoveFromArray(g_hArrayUsers, iBuffer);
				RemoveFromArray(g_hArrayUsersExpires, iBuffer);
				RemoveFromArray(g_hArrayUsersPassword, iBuffer);
				g_iArrayUsers -= 1;
				VipPrint(client, enSound:2, "Ваш период использования VIP функций закончилось!");
				Vip_Log("Атрибуты VIP удалены у %s (ID: %s). Причина: Истекло время.", sBuffer, g_sClientAuth[client]);
			}
			KvGetString(g_hKvUsers, "name", sBuffer, 128, "");
			new var3;
			if (GetClientName(client, sName, 128) && strcmp(sBuffer, sName, false))
			{
				KvSetString(g_hKvUsers, "name", sName);
			}
			KvGetString(g_hKvUsers, "group", sBuffer, 128, "");
			if (GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer))
			{
				KvRewind(g_hKvUsersGroups);
				if (KvJumpToKey(g_hKvUsersGroups, sBuffer, false))
				{
					KvGetString(g_hKvUsersGroups, "flags", sBuffer, 128, "0a");
					g_sUsersOnAttribute[client] = UsersSetFlags(client, sBuffer);
					if (g_sUsersOnAttribute[client])
					{
						g_sUsersOnPlayerRunCmd[client] = GetOnPlayerRunCmd(client);
					}
				}
			}
			else
			{
				KvGetString(g_hKvUsers, "flags", sBuffer, 128, "0a");
				g_sUsersOnAttribute[client] = UsersSetFlags(client, sBuffer);
				if (g_sUsersOnAttribute[client])
				{
					g_sUsersOnPlayerRunCmd[client] = GetOnPlayerRunCmd(client);
				}
			}
			if (!g_bWelcome[client])
			{
				CreateTimer(7.01, Timer_WelcomeMsg, g_iClientUserId[client], 2);
			}
		}
	}
	UsersLoadFlags_Post(client, g_sClientAuth[client], g_bUsersVip[client], g_bUsersCmds[client], g_bUsersAdmin[client]);
	return true;
}


/* ERROR! null */
 function "UsersSetFlags" (number 47)
public Action:Cmd_UsersAdd(client, args)
{
	new var4;
	decl iTemp[2];
	new var1;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
		return Action:3;
	}
	new var2;
	if (!g_bBetaTest || args < 4)
	{
		if (client)
		{
			VipPrint(client, enSound:2, "Usage: vip_users_add \"NameUser\" \"SteamID\" \"Password\" \"Flags|Group\" \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
		}
		else
		{
			ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" \"SteamID\" \"Password\" \"Flags|Group\" \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
		}
		return Action:3;
	}
	GetCmdArg(1, var4 + var4, 128);
	new var5 = var4 + 4;
	GetCmdArg(2, var5 + var5, 128);
	new var6 = var4 + 8;
	GetCmdArg(3, var6 + var6, 128);
	new var7 = var4 + 12;
	GetCmdArg(4, var7 + var7, 128);
	new var8 = var4 + 16;
	GetCmdArg(5, var8 + var8, 128);
	new var9 = var4 + 20;
	GetCmdArg(6, var9 + var9, 128);
	if (strcmp(var4 + var4, "", false))
	{
		new var10 = var4 + 4;
		if (strlen(var10 + var10) <= 1)
		{
			ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" <SteamID> \"Password\" \"Flags|Group\" \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
			return Action:3;
		}
		new var11 = var4 + 12;
		if (strcmp(var11 + var11, "Flags", false))
		{
			new var12 = var4 + 12;
			if (strcmp(var12 + var12, "Group", false))
			{
				ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" \"SteamID\" \"Password\" <Flags|Group> \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
				return Action:3;
			}
			iTemp[0] = 2;
		}
		else
		{
			iTemp[0] = 1;
		}
		if (iTemp[0] == 2)
		{
			new var13 = var4 + 16;
			GetTrieValue(g_hUsersGroupsTrie, var13 + var13, iTemp[1]);
			if (iTemp[1] != 1)
			{
				new var14 = var4 + 16;
				ReplyToCommand(client, "Usage: vip_users_add \"NameUser\" \"SteamID\" \"Password\" \"Group\" <Группа \"%s\" не найдена!> \"TimeExpires (Unix Time)\"", var14 + var14);
				return Action:3;
			}
		}
		KvRewind(g_hKvUsers);
		new var15 = var4 + 4;
		if (KvJumpToKey(g_hKvUsers, var15 + var15, false))
		{
			ReplyToCommand(client, "Ошибка! Пользователь %s был добавлен в [VIP] базу раньше!", var4 + var4);
		}
		else
		{
			new var16 = var4 + 4;
			if (KvJumpToKey(g_hKvUsers, var16 + var16, true))
			{
				KvSetString(g_hKvUsers, "name", var4 + var4);
				new var17 = var4 + 20;
				new var3;
				if (strcmp(var17 + var17, "", false) && strcmp(var18 + var18, "0", false) && strcmp(var19 + var19, "never", false))
				{
					KvSetString(g_hKvUsers, "expires", "0");
				}
				else
				{
					new var20 = var4 + 20;
					KvSetString(g_hKvUsers, "expires", var20 + var20);
				}
				new var21 = var4 + 8;
				KvSetString(g_hKvUsers, "password", var21 + var21);
				if (iTemp[0] == 1)
				{
					new var22 = var4 + 16;
					KvSetString(g_hKvUsers, "flags", var22 + var22);
				}
				else
				{
					if (iTemp[0] == 2)
					{
						new var23 = var4 + 16;
						KvSetString(g_hKvUsers, "group", var23 + var23);
					}
				}
				KvRewind(g_hKvUsers);
				new var24 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var24[0][var24]);
				new var25 = var4 + 4;
				PushArrayString(g_hArrayUsers, var25 + var25);
				new var26 = var4 + 20;
				PushArrayCell(g_hArrayUsersExpires, StringToInt(var26 + var26, 10));
				new var27 = var4 + 8;
				PushArrayString(g_hArrayUsersPassword, var27 + var27);
				g_iArrayUsers += 1;
				new i = 1;
				while (i <= g_iMaxClients)
				{
					if (IsClientInGame(i))
					{
						new var28 = var4 + 4;
						if (!(strcmp(var28 + var28, g_sClientAuth[i], false)))
						{
							OnClientPutInServer(i);
						}
					}
					i++;
				}
			}
			ReplyToCommand(client, "Пользователь %s успешно добавлен в [VIP] базу.", var4 + var4);
			Vip_Log("Админ %N упешно добавил нового пользователя %s в [VIP] базу.", client, var4 + var4);
		}
		return Action:3;
	}
	ReplyToCommand(client, "Usage: vip_users_add <NameUser> \"SteamID\" \"Password\" \"Flags|Group\" \"CountFlags|GroupName\" \"TimeExpires (Unix Time)\"");
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
		VipPrint(client, enSound:2, "Usage: vip_users_del \"SteamID\"");
		return Action:3;
	}
	new var3;
	new var2;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
		return Action:3;
	}
	GetCmdArgString(var3 + var3, 128);
	StripQuotes(var3 + var3);
	new iBuffer = FindStringInArray(g_hArrayUsers, var3 + var3);
	if (iBuffer == -1)
	{
		ReplyToCommand(client, "Ошибка! %s не найден в [VIP] базе!", var3 + var3);
	}
	else
	{
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, var3 + var3, false))
		{
			KvDeleteThis(g_hKvUsers);
		}
		KvRewind(g_hKvUsers);
		new var4 = g_sUsersPath;
		KeyValuesToFile(g_hKvUsers, var4[0][var4]);
		RemoveFromArray(g_hArrayUsers, iBuffer);
		RemoveFromArray(g_hArrayUsersExpires, iBuffer);
		RemoveFromArray(g_hArrayUsersPassword, iBuffer);
		g_iArrayUsers -= 1;
		DeleteUserSettings(var3 + var3);
		ResettingTheFlags(var3 + var3);
		ReplyToCommand(client, "%s успешно удален из [VIP] базы.", var3 + var3);
		Vip_Log("Админ %N упешно удалил %s из [VIP] базы.", client, var3 + var3);
	}
	return Action:3;
}

public Action:Cmd_SetPassword(client, args)
{
	if (client)
	{
		if (g_sUsersOnAttribute[client])
		{
			if (GetCmdReplySource() == 1)
			{
				VipPrint(client, enSound:2, "В чате запрещено устанавливать пароль!");
			}
			else
			{
				new Float:fBuffer = GetGameTime();
				if (g_fUsersTimeSetPassword[client] > fBuffer)
				{
					VipPrint(client, enSound:2, "Изменение пароля будет доступно через %.0f сек.", g_fUsersTimeSetPassword[client] - fBuffer);
				}
				else
				{
					decl String:sBuffer[128];
					if (args == 1)
					{
						new iBuffer = FindStringInArray(g_hArrayUsers, g_sClientAuth[client]);
						if (iBuffer != -1)
						{
							GetArrayString(g_hArrayUsersPassword, iBuffer, sBuffer, 128);
							if (strlen(sBuffer))
							{
								GetCmdArgString(sBuffer, 128);
								StripQuotes(sBuffer);
								if (strlen(sBuffer))
								{
									g_fUsersTimeSetPassword[client] = fBuffer + 16.0;
									KvRewind(g_hKvUsers);
									new var1;
									if (iBuffer != -1 && KvJumpToKey(g_hKvUsers, g_sClientAuth[client], false))
									{
										SetArrayString(g_hArrayUsersPassword, iBuffer, sBuffer);
										KvSetString(g_hKvUsers, "password", sBuffer);
										KvRewind(g_hKvUsers);
										new var2 = g_sUsersPath;
										KeyValuesToFile(g_hKvUsers, var2[0][var2]);
										VipPrint(client, enSound:1, "Пароль \"\x04%s\x01\" успешно установлен.", sBuffer);
										VipPrint(client, enSound:0, "В консоли игры вводите: \x04setinfo %s \"%s\"", g_sKeyVipAuth, sBuffer);
									}
									else
									{
										VipPrint(client, enSound:2, "Ошибка установки пароля!");
									}
								}
								else
								{
									VipPrint(client, enSound:2, "Слишком короткий пароль.");
								}
							}
							else
							{
								VipPrint(client, enSound:2, "Вам запрещено устанавливать пароль.");
							}
						}
						else
						{
							VipPrint(client, enSound:2, "Не известная ошибка!");
						}
					}
					else
					{
						GetCmdArg(0, sBuffer, 128);
						VipPrint(client, enSound:2, "Usage: %s \"password\"", sBuffer);
					}
				}
			}
		}
		else
		{
			VipPrint(client, enSound:2, "У Вас нет доступа!");
		}
	}
	else
	{
		ReplyToCommand(client, "[VIP] Available only to players!");
	}
	return Action:3;
}

public Action:Cmd_SetUsersPassword(client, args)
{
	new var1;
	if (!client || g_bUsersAdmin[client])
	{
		decl String:sBuffer[128];
		if (args == 2)
		{
			GetCmdArg(1, sBuffer, 128);
			StripQuotes(sBuffer);
			new iBuffer = FindStringInArray(g_hArrayUsers, sBuffer);
			if (iBuffer == -1)
			{
				if (client)
				{
					VipPrint(client, enSound:2, "Игрок %s в vip базе не найден.", sBuffer);
				}
				else
				{
					ReplyToCommand(client, "Игрок %s в vip базе не найден.", sBuffer);
				}
			}
			else
			{
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, sBuffer, false))
				{
					GetCmdArg(2, sBuffer, 128);
					StripQuotes(sBuffer);
					SetArrayString(g_hArrayUsersPassword, iBuffer, sBuffer);
					KvSetString(g_hKvUsers, "password", sBuffer);
					KvRewind(g_hKvUsers);
					new var2 = g_sUsersPath;
					KeyValuesToFile(g_hKvUsers, var2[0][var2]);
					if (client)
					{
						VipPrint(client, enSound:1, "Пароль \"\x04%s\x01\" успешно установлен.", sBuffer);
					}
					else
					{
						ReplyToCommand(client, "Пароль \"%s\" успешно установлен.", sBuffer);
					}
				}
				if (client)
				{
					VipPrint(client, enSound:2, "Не известная ошибка!");
				}
				ReplyToCommand(client, "Не известная ошибка!");
			}
		}
		else
		{
			GetCmdArg(0, sBuffer, 128);
			if (client)
			{
				VipPrint(client, enSound:2, "Usage: %s \"SteamID\" \"password\"", sBuffer);
			}
			ReplyToCommand(client, "Usage: %s \"SteamID\" \"password\"", sBuffer);
		}
	}
	else
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
	}
	return Action:3;
}

public UsersChat_Init()
{
	g_hConVarChatTag = CreateConVar("vip_users_chat_tag", "[VIP]", "Стандартный чат тег для VIP игроков с флагом '0a'", 262144, false, 0.0, false, 0.0);
	HookConVarChange(g_hConVarChatTag, OnSettingsChanged);
	g_hChatTagsArray = CreateArray(32, 0);
	g_hChatIgnoreCmdsArray = CreateArray(32, 0);
	BuildPath(PathType:0, g_sChatTagsPath, 256, "data/vip/users_chat_tags.ini");
	BuildPath(PathType:0, g_sChatIgnoreCmdsPath, 256, "data/vip/users_chat_ignore_commands.ini");
	AddCommandListener(ClientChat_Command, "say");
	AddCommandListener(ClientChat_Command, "say_team");
	RegConsoleCmd("vip_chat_tag_add", Cmd_ChatTagAdd, "Добавить новый VIP тег.", 0);
	RegConsoleCmd("vip_chat_tag_list", Cmd_ChatTagList, "Лист VIP тег.", 0);
	RegConsoleCmd("vip_chat_tag_remove", Cmd_ChatTagRemove, "Удалить VIP тег.", 0);
	RegConsoleCmd("vip_chat_tag_del", Cmd_ChatTagRemove, "Удалить VIP тег.", 0);
	RegConsoleCmd("vip_chat_tag_reload", Cmd_ChatTagReload, "Перезагрузить VIP теги.", 0);
	RegConsoleCmd("vip_chat_tag", Cmd_SetChatTag, "Установка своего VIP тега.", 0);
	return 0;
}

public UsersChatTagsLoad()
{
	if (g_iUsersChatTagsArray != -1)
	{
		ClearArray(g_hChatTagsArray);
	}
	if (FileExists(g_sChatTagsPath, false))
	{
		ParsFile(g_sChatTagsPath, g_hChatTagsArray, 6);
		g_iUsersChatTagsArray = GetArraySize(g_hChatTagsArray) + -1;
	}
	else
	{
		g_iUsersChatTagsArray = -1;
	}
	return 0;
}

public Action:ClientChat_Command(client, String:command[], args)
{
	new var1;
	if (client > 0 && client <= g_iMaxClients)
	{
		decl bool:isVip;
		new var2;
		isVip = g_bPlayerVip[client][0] && g_iPlayerVip[client][0];
		new var3;
		if ((isVip || g_iVipUsersChatSettings) || (g_bSourceComms_GetClientGagType && SourceComms_GetClientGagType(client)))
		{
			return Action:0;
		}
		new Float:fBuffer = GetGameTime();
		if (fBuffer > g_fTimerChat[client])
		{
			decl String:sBuffer[256];
			new iBuffer;
			GetCmdArgString(sBuffer, 255);
			StripQuotes(sBuffer);
			g_fTimerChat[client] = fBuffer + 0.39;
			new var7;
			if (sBuffer[0] == '@' || (g_iChatIgnoreCmdsArray != -1 && FindStringInArray(g_hChatIgnoreCmdsArray, sBuffer) != -1))
			{
				return Action:0;
			}
			decl String:sName[32];
			decl String:sAlive[64];
			g_iClientTeam[client] = GetClientTeam(client);
			if (GetClientName(client, sName, 32))
			{
				new var8;
				if (isVip && sBuffer[0] == '!' && sBuffer[0] == '!' && strlen(sBuffer) > 2)
				{
					strcopy(sBuffer, 255, sBuffer[0]);
					if (g_bPlayerAlive[client])
					{
						Format(sAlive, 64, "\x04%s [ЧАТ]", g_sUsersChatTag[client]);
					}
					else
					{
						Format(sAlive, 64, "\x01*УБИТ* \x04%s [ЧАТ]", g_sUsersChatTag[client]);
					}
					iBuffer = 3;
				}
				else
				{
					if (strcmp(command, "say", false))
					{
						if (!(strcmp(command, "say_team", false)))
						{
							if (g_iClientTeam[client] == 2)
							{
								if (isVip)
								{
									if (g_bPlayerAlive[client])
									{
										Format(sAlive, 64, "\x04%s\x01 (Террорист)", g_sUsersChatTag[client]);
									}
									else
									{
										Format(sAlive, 64, "\x01*УБИТ* \x04%s\x01 (Террорист)", g_sUsersChatTag[client]);
									}
								}
								else
								{
									if (g_bPlayerAlive[client])
									{
										Format(sAlive, 64, "\x01(Террорист)");
									}
									Format(sAlive, 64, "\x01*УБИТ* (Террорист)");
								}
							}
							else
							{
								if (g_iClientTeam[client] == 3)
								{
									if (isVip)
									{
										if (g_bPlayerAlive[client])
										{
											Format(sAlive, 64, "\x04%s\x01 (Спецназовец)", g_sUsersChatTag[client]);
										}
										else
										{
											Format(sAlive, 64, "\x01*УБИТ* \x04%s\x01 (Спецназовец)", g_sUsersChatTag[client]);
										}
									}
									else
									{
										if (g_bPlayerAlive[client])
										{
											Format(sAlive, 64, "\x01(Спецназовец)");
										}
										Format(sAlive, 64, "\x01*УБИТ* (Спецназовец)");
									}
								}
								if (isVip)
								{
									Format(sAlive, 64, "\x04%s\x01 (Наблюдатель)", g_sUsersChatTag[client]);
								}
								Format(sAlive, 64, "\x01(Наблюдатель)");
							}
							iBuffer = 2;
						}
					}
					if (isVip)
					{
						new var9;
						if (!g_iClientTeam[client] || g_iClientTeam[client] == 1)
						{
							Format(sAlive, 64, "\x01*НАБЛЮДАТЕЛЬ* \x04%s", g_sUsersChatTag[client]);
						}
						else
						{
							if (g_bPlayerAlive[client])
							{
								Format(sAlive, 64, "\x04%s", g_sUsersChatTag[client]);
							}
							Format(sAlive, 64, "\x01*УБИТ* \x04%s", g_sUsersChatTag[client]);
						}
					}
					else
					{
						new var10;
						if (!g_iClientTeam[client] || g_iClientTeam[client] == 1)
						{
							Format(sAlive, 64, "\x01*НАБЛЮДАТЕЛЬ*");
						}
						if (g_bPlayerAlive[client])
						{
							Format(sAlive, 64, "\x01");
						}
						Format(sAlive, 64, "\x01*УБИТ*");
					}
					iBuffer = 1;
				}
				new i = 1;
				while (i <= g_iMaxClients)
				{
					new var11;
					if (IsClientConnected(i) && IsClientInGame(i))
					{
						if (iBuffer == 1)
						{
							if (g_iVipUsersChatSettings == 1)
							{
								Users_SayChat(i, client, sAlive, sName, sBuffer);
							}
							else
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
						if (iBuffer == 2)
						{
							g_iClientTeam[i] = GetClientTeam(i);
							if (g_iClientTeam[client] == g_iClientTeam[i])
							{
								if (g_iVipUsersChatSettings == 1)
								{
									Users_SayChat(i, client, sAlive, sName, sBuffer);
								}
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
						new var12;
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
				PrintToServer("%s %s", sName, sBuffer);
			}
		}
		return Action:3;
	}
	return Action:0;
}

public Users_SayChat(client, author, String:tag[], String:name[], String:text[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client, 132);
	decl String:sBuffer[256];
	if (g_bProtobufMessage)
	{
		if (tag[0])
		{
			Format(sBuffer, 255, " \x01%s \x03%s\x01 : %s", tag, name, text);
		}
		else
		{
			Format(sBuffer, 255, " \x01\x03%s\x01 : %s", name, text);
		}
		PbSetInt(hBuffer, "ent_idx", author, -1);
		PbSetBool(hBuffer, "chat", true, -1);
		PbSetString(hBuffer, "msg_name", sBuffer, -1);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		if (tag[0])
		{
			Format(sBuffer, 255, "%s \x03%s\x01 : %s", tag, name, text);
		}
		else
		{
			Format(sBuffer, 255, "\x03%s\x01 : %s", name, text);
		}
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, sBuffer);
	}
	EndMessage();
	return 0;
}

public Action:Cmd_ChatTagAdd(client, args)
{
	new var1;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
	}
	else
	{
		if (args)
		{
			if (FileExists(g_sChatTagsPath, false))
			{
				decl String:sBuffer[32];
				decl Handle:hFile;
				decl iBuffer;
				GetCmdArgString(sBuffer, 32);
				StripQuotes(sBuffer);
				iBuffer = strlen(sBuffer);
				if (iBuffer < 24)
				{
					hFile = OpenFile(g_sChatTagsPath, "at");
					if (hFile)
					{
						new var2;
						if (strcmp(sBuffer, g_sChatTag, false) && FindStringInArray(g_hChatTagsArray, sBuffer) > -1)
						{
							if (client)
							{
								VipPrint(client, enSound:2, "Тег \x04%s\x01 уже присутствует в базе!", sBuffer);
							}
							else
							{
								ReplyToCommand(client, "\x01Тег \x04%s\x01 уже присутствует в базе!", sBuffer);
							}
						}
						else
						{
							PushArrayString(g_hChatTagsArray, sBuffer);
							WriteFileLine(hFile, sBuffer);
							g_iUsersChatTagsArray = GetArraySize(g_hChatTagsArray) + -1;
							if (client)
							{
								VipPrint(client, enSound:0, "Тег \x04%s\x01 успешно добавлен в базу.", sBuffer);
							}
							ReplyToCommand(client, "\x01Тег \x04%s\x01 успешно добавлен в базу.", sBuffer);
						}
						CloseHandle(hFile);
					}
				}
				else
				{
					if (client)
					{
						VipPrint(client, enSound:2, "Максимальная длина VIP тега 23 символа! Тег: \x04%s\x01 длина тега = \x04%i", sBuffer, iBuffer);
					}
					ReplyToCommand(client, "Максимальная длина VIP тега 23 символа! Тег: %s длина тега = %i", sBuffer, iBuffer);
				}
			}
			else
			{
				if (client)
				{
					VipPrint(client, enSound:2, "Не найден файл \x04%s", g_sChatTagsPath);
				}
				ReplyToCommand(client, "\x01Не найден файл \x04%s", g_sChatTagsPath);
			}
		}
		if (client)
		{
			VipPrint(client, enSound:0, "Добавление нового тега vip_chat_tag_add \x04[new_tag]");
		}
		ReplyToCommand(client, "\x01Добавление нового тега vip_chat_tag_add \x04[new_tag]");
	}
	return Action:3;
}

public Action:Cmd_ChatTagList(client, args)
{
	new var1;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
	}
	else
	{
		if (g_iUsersChatTagsArray != -1)
		{
			decl String:sBuffer[32];
			ReplyToCommand(client, "База чат тег [%i]:", g_iUsersChatTagsArray);
			new i;
			while (i <= g_iUsersChatTagsArray)
			{
				GetArrayString(g_hChatTagsArray, i, sBuffer, 32);
				ReplyToCommand(client, sBuffer);
				i++;
			}
		}
		if (client)
		{
			VipPrint(client, enSound:2, "Чат тег база пуста!");
		}
		ReplyToCommand(client, "Чат тег база пуста!");
	}
	return Action:3;
}

public Action:Cmd_ChatTagRemove(client, args)
{
	new var1;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
	}
	else
	{
		if (g_iUsersChatTagsArray != -1)
		{
			if (args)
			{
				decl String:sBuffer[256];
				decl String:sTag[32];
				decl iBuffer;
				decl Handle:hBuffer;
				GetCmdArgString(sTag, 32);
				StripQuotes(sTag);
				iBuffer = FindStringInArray(g_hChatTagsArray, sTag);
				if (iBuffer == -1)
				{
					if (client)
					{
						VipPrint(client, enSound:2, "Тег \x04%s\x01 не найден в базе!", sTag);
					}
					else
					{
						ReplyToCommand(client, "Тег %s не найден в базе!", sTag);
					}
				}
				else
				{
					hBuffer = OpenFile(g_sChatTagsPath, "r");
					if (hBuffer)
					{
						Format(sBuffer, 256, "%s.dump", g_sChatTagsPath);
						new Handle:hTarget = OpenFile(sBuffer, "w");
						if (hTarget)
						{
							RemoveFromArray(g_hChatTagsArray, iBuffer);
							g_iUsersChatTagsArray = GetArraySize(g_hChatTagsArray) + -1;
							while (!IsEndOfFile(hBuffer))
							{
								new var2;
								if (!(!ReadFileLine(hBuffer, sBuffer, 256) || StrContains(sBuffer, sTag, true)))
								{
									WriteFileString(hTarget, sBuffer, false);
								}
							}
							CloseHandle(hTarget);
							CloseHandle(hBuffer);
							if (DeleteFile(g_sChatTagsPath))
							{
								Format(sBuffer, 256, "%s.dump", g_sChatTagsPath);
								if (RenameFile(g_sChatTagsPath, sBuffer))
								{
									if (client)
									{
										VipPrint(client, enSound:0, "Тег \x04%s\x01 успешно удалён.", sTag);
									}
									else
									{
										ReplyToCommand(client, "Тег %s успешно удалён.", sTag);
									}
								}
								else
								{
									Vip_ErrorLog("Не удалось переименовать файл %s на %s [Секция: Чат тег #3]", sBuffer, g_sChatTagsPath);
								}
							}
							Vip_ErrorLog("Не удалось удалить файл %s [Секция: Чат тег #1]", g_sChatTagsPath);
						}
						else
						{
							CloseHandle(hBuffer);
							if (client)
							{
								VipPrint(client, enSound:2, "Не удалось создать новый файл базы \x04%s\x01! [Секция: Чат тег #2]", sBuffer);
							}
							else
							{
								ReplyToCommand(client, "Не удалось создать новый файл базы %s! [Секция: Чат тег #2]", sBuffer);
							}
							Vip_ErrorLog("Не удалось создать новый файл базы %s! [Секция: Чат тег #2]", sBuffer);
						}
					}
					if (client)
					{
						VipPrint(client, enSound:2, "Ошибка чтения базы \x04%s\x01!", g_sChatTagsPath);
					}
					else
					{
						ReplyToCommand(client, "Ошибка чтения базы %s!", g_sChatTagsPath);
					}
				}
			}
			else
			{
				if (client)
				{
					VipPrint(client, enSound:0, "Удаление чат тега vip_chat_tag_remove \x04[old_tag]");
				}
				ReplyToCommand(client, "Удаление чат тега vip_chat_tag_remove [old_tag]");
			}
		}
		if (client)
		{
			VipPrint(client, enSound:2, "Чат тег база пуста!");
		}
		ReplyToCommand(client, "Чат тег база пуста!");
	}
	return Action:3;
}

public Action:Cmd_ChatTagReload(client, args)
{
	new var1;
	if (client && !g_bUsersAdmin[client])
	{
		VipPrint(client, enSound:2, "У Вас нет доступа!");
	}
	else
	{
		UsersChatTagsLoad();
		if (g_iUsersChatTagsArray != -1)
		{
			decl String:sTag[64];
			decl bool:bTag;
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var2;
				if (g_bPlayerVip[i][0] && IsClientConnected(i) && IsClientInGame(i))
				{
					bTag = false;
					new j;
					while (j <= g_iUsersChatTagsArray)
					{
						GetArrayString(g_hChatTagsArray, j, sTag, 64);
						if (!(strcmp(g_sUsersChatTag[i], sTag, false)))
						{
							bTag = true;
							if (!bTag)
							{
								strcopy(g_sUsersChatTag[i], 32, g_sChatTag);
							}
						}
						j++;
					}
					if (!bTag)
					{
						strcopy(g_sUsersChatTag[i], 32, g_sChatTag);
					}
				}
				i++;
			}
		}
		else
		{
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var3;
				if (g_bPlayerVip[i][0] && strcmp(g_sUsersChatTag[i], g_sChatTag, false) && IsClientConnected(i) && IsClientInGame(i))
				{
					strcopy(g_sUsersChatTag[i], 32, g_sChatTag);
					g_bSettingsChanged[i] = 1;
				}
				i++;
			}
		}
		if (client)
		{
			VipPrint(client, enSound:0, "База чат тег перезагружена.");
		}
		ReplyToCommand(client, "База чат тег перезагружена.");
	}
	return Action:3;
}

public Action:Cmd_SetChatTag(client, args)
{
	if (client)
	{
		new var1;
		if (g_bUsersAdmin[client] && g_bPlayerVip[client][0])
		{
			if (args)
			{
				decl String:sBuffer[32];
				decl iBuffer;
				GetCmdArgString(sBuffer, 32);
				StripQuotes(sBuffer);
				iBuffer = strlen(sBuffer);
				if (iBuffer > 23)
				{
					VipPrint(client, enSound:2, "Максимальная длина чат тега 23 символа! Тег: \x04%s\x01 длина тега = \x04%i", sBuffer, iBuffer);
				}
				else
				{
					new var2;
					if (strcmp(sBuffer, g_sChatTag, false) && strcmp(sBuffer, g_sUsersChatTag[client], false))
					{
						VipPrint(client, enSound:2, "Тег \x04%s\x01 существует в базе!", sBuffer);
					}
					strcopy(g_sUsersChatTag[client], 32, sBuffer);
					VipPrint(client, enSound:0, "Тег \x04%s\x01 успешно установлен.", sBuffer);
					g_bSettingsChanged[client] = 1;
				}
			}
			else
			{
				VipPrint(client, enSound:0, "Установка чат тега vip_chat_tag \x04[new_tag]");
			}
		}
		VipPrint(client, enSound:2, "Вам недоступна эта команда!");
	}
	return Action:3;
}

public Display_VipChat(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_VipChat, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Чат тeг: Настройка");
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "disable", "Чат: [Выключить]", 0);
	if (g_iUsersChatTagsArray != -1)
	{
		Format(sBuffer, 128, "Чaт тег: %s", g_sUsersChatTag[client]);
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 0);
	}
	new var1;
	if (g_iPlayerVip[client][0] == 2 || g_iPlayerVip[client][0] == 4)
	{
		Format(sBuffer, 128, "Звуки сообщений: [Включено]");
	}
	else
	{
		Format(sBuffer, 128, "Звуки сообщений: [Выключено]");
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
			if (param == -6)
			{
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[16];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, "", 0);
			if (strcmp(sBuffer, "disable", false))
			{
				if (strcmp(sBuffer, "sound", false))
				{
					Display_UsersChatTags(client);
				}
				if (g_iPlayerVip[client][0] == 2)
				{
					g_iPlayerVip[client][0] = 1;
					VipPrint(client, enSound:0, "Звуки сообщений: [Выключено]");
				}
				else
				{
					g_iPlayerVip[client][0] = 2;
					VipPrint(client, enSound:0, "Звуки сообщений: [Включено]");
				}
				g_bSettingsChanged[client] = 1;
				Display_VipChat(client);
			}
			else
			{
				g_iPlayerVip[client][0] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, enSound:0, "Чат: [Выключен]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
	}
	return 0;
}

public Display_UsersChatTags(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersChatTags, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Чат Теги: Настройка");
	SetMenuTitle(hMenu, sBuffer);
	if (strcmp(g_sUsersChatTag[client], g_sChatTag, false))
	{
		AddMenuItem(hMenu, g_sChatTag, g_sChatTag, 0);
	}
	else
	{
		AddMenuItem(hMenu, g_sChatTag, g_sChatTag, 1);
	}
	new i;
	while (i <= g_iUsersChatTagsArray)
	{
		GetArrayString(g_hChatTagsArray, i, sBuffer, 128);
		if (strcmp(g_sUsersChatTag[client], sBuffer, false))
		{
			AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		}
		else
		{
			AddMenuItem(hMenu, sBuffer, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersChatTags(Handle:hMenu, MenuAction:action, client, param)
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
				Display_VipChat(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[32];
			GetMenuItem(hMenu, param, sBuffer, 32, 0, "", 0);
			strcopy(g_sUsersChatTag[client], 32, sBuffer);
			VipPrint(client, enSound:0, "Чат тег изменён на: \x04%s", sBuffer);
			g_bSettingsChanged[client] = 1;
			Display_VipChat(client);
		}
	}
	return 0;
}

public ClanTag_Init()
{
	BuildPath(PathType:0, g_sUsersClanTags, 256, "data/vip/users_clan_tags.ini");
	g_hUsersClanTagsArray = CreateArray(32, 0);
	g_hConVarClanTag = CreateConVar("vip_users_clan_tag", "[VIP]", "Стандартный клан тег, для игроков с флагом '0x'", 262144, false, 0.0, false, 0.0);
	HookConVarChange(g_hConVarClanTag, OnSettingsChanged);
	RegConsoleCmd("vip_clan_tag", SetClanTag_Command, "Установка нового VIP клан тега.", 0);
	return 0;
}

public Action:SetClanTag_Command(client, args)
{
	if (client)
	{
		new var1;
		if (g_bUsersAdmin[client] && g_bPlayerVip[client][24])
		{
			if (args)
			{
				decl String:sBuffer[32];
				GetCmdArgString(sBuffer, 32);
				StripQuotes(sBuffer);
				new iBuffer = strlen(sBuffer);
				if (iBuffer > 23)
				{
					VipPrint(client, enSound:2, "Максимальная длина VIP клан тега 23 символа! Клан тег: \x04%s\x01 длина тега = \x04%i", sBuffer, iBuffer);
				}
				else
				{
					new var2;
					if (strcmp(sBuffer, g_sClanTag, true) && strcmp(sBuffer, g_sUsersClanTag[client], true))
					{
						VipPrint(client, enSound:2, "Клан тег \x04%s\x01 существует в базе!", sBuffer);
					}
					strcopy(g_sUsersClanTag[client], 32, sBuffer);
					CS_SetClientClanTag(client, sBuffer);
					VipPrint(client, enSound:0, "Клан тег \x04%s\x01 успешно установлен.", sBuffer);
					g_iPlayerVip[client][24] = 1;
					g_bSettingsChanged[client] = 1;
				}
			}
			else
			{
				VipPrint(client, enSound:0, "Установка VIP тега vip_clan_tag \x04[new_tag]");
			}
		}
		VipPrint(client, enSound:2, "Вам недоступна эта команда!");
	}
	return Action:3;
}

public Display_ClanTagSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_ClanTagSettings, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Kлaн тeг: Hacтpoйкa");
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "standard", "Kлaн тeг: [Стандартный]", 0);
	if (strcmp(g_sUsersClanTag[client], g_sClanTag, false))
	{
		AddMenuItem(hMenu, g_sClanTag, g_sClanTag, 0);
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, g_sClanTag, 1);
	}
	new i;
	while (i <= g_iUsersClanTags)
	{
		GetArrayString(g_hUsersClanTagsArray, i, sBuffer, 128);
		if (strcmp(g_sUsersClanTag[client], sBuffer, false))
		{
			AddMenuItem(hMenu, sBuffer, sBuffer, 0);
		}
		else
		{
			AddMenuItem(hMenu, sBuffer, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_ClanTagSettings(Handle:hMenu, MenuAction:action, client, param)
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
			g_bSettingsChanged[client] = 1;
			if (strcmp(sBuffer, "standard", false))
			{
				strcopy(g_sUsersClanTag[client], 32, sBuffer);
				CS_SetClientClanTag(client, sBuffer);
				VipPrint(client, enSound:0, "Клан тег \x04%s\x01 успешно установлен.", sBuffer);
				Display_ClanTagSettings(client);
			}
			else
			{
				g_iPlayerVip[client][24] = 0;
				CS_SetClientClanTag(client, g_sUsersOldClanTag[client]);
				VipPrint(client, enSound:0, "Установлен стандартный клан тег.", sBuffer);
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
	}
	return 0;
}

public Action:Timer_GetUsersClanTag(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && g_bPlayerVip[client][24] && IsClientInGame(client))
	{
		if (g_iClientTeam[client])
		{
			CS_GetClientClanTag(client, g_sUsersOldClanTag[client], 32);
			if (g_iPlayerVip[client][24])
			{
				CS_SetClientClanTag(client, g_sUsersClanTag[client]);
			}
		}
		CreateTimer(2.0, Timer_GetUsersClanTag, userid, 2);
		return Action:0;
	}
	return Action:4;
}

public DropWeapon_Init()
{
	AddCommandListener(DropWeapon_Command, "drop");
	return 0;
}

public Action:DropWeapon_Command(client, String:command[], args)
{
	new var1;
	if (client && isUsersDropWeapon(client))
	{
		new iUserDrop;
		new iBuffer;
		new bool:bClientObserver;
		if (g_bPlayerAlive[client])
		{
			new var2;
			if (g_bPlayerVip[client][29] && g_iPlayerVip[client][29])
			{
				iUserDrop = client;
			}
			return Action:0;
		}
		else
		{
			new var3;
			if (g_bUsersCmds[client] && g_bPlayerCmds[client][4] && IsClientObserver(client))
			{
				iBuffer = GetEntData(client, g_iObserverModeOffset, 4);
				if (g_iGame != GameType:2)
				{
					iBuffer += 1;
				}
				new var4;
				if (iBuffer == 3 || iBuffer == 4)
				{
					iBuffer = GetEntDataEnt2(client, g_iObserverTargetOffset);
					new var5;
					if (iBuffer > 0 && !g_bUsersAdmin[iBuffer] && g_bPlayerAlive[iBuffer] && IsClientInGame(iBuffer))
					{
						iUserDrop = iBuffer;
						bClientObserver = true;
					}
					return Action:0;
				}
				return Action:0;
			}
			return Action:0;
		}
		decl String:sBuffer[24];
		new iEntity = GetEntDataEnt2(iUserDrop, g_iActiveWeaponOffset);
		new var6;
		if (iEntity != -1 && IsValidEntity(iEntity) && GetEntDataEnt2(iEntity, g_iOwnerEntityOffset) == iUserDrop && GetEntityClassname(iEntity, sBuffer, 22))
		{
			if (strcmp(sBuffer, "weapon_knife", false))
			{
				if (strcmp(sBuffer, "weapon_hegrenade", false))
				{
					if (strcmp(sBuffer, "weapon_flashbang", false))
					{
						if (strcmp(sBuffer, "weapon_smokegrenade", false))
						{
							if (bClientObserver)
							{
								CS_DropWeapon(iUserDrop, iEntity, true, false);
								return Action:3;
							}
						}
						iBuffer = GetPlayerGrenade(iUserDrop, 13);
						CS_DropWeapon(iUserDrop, iEntity, true, false);
						if (iBuffer)
						{
							if (iBuffer == 2)
							{
								GivePlayerItem(iUserDrop, sBuffer, 0);
							}
							if (iBuffer > 2)
							{
								GivePlayerItem(iUserDrop, sBuffer, 0);
								iBuffer--;
								SetPlayerGrenade(iUserDrop, 13, iBuffer);
							}
						}
						return Action:3;
					}
					iBuffer = GetPlayerGrenade(iUserDrop, 12);
					CS_DropWeapon(iUserDrop, iEntity, true, false);
					if (iBuffer)
					{
						if (iBuffer == 2)
						{
							GivePlayerItem(iUserDrop, sBuffer, 0);
						}
						if (iBuffer > 2)
						{
							GivePlayerItem(iUserDrop, sBuffer, 0);
							iBuffer--;
							SetPlayerGrenade(iUserDrop, 12, iBuffer);
						}
					}
					return Action:3;
				}
				iBuffer = GetPlayerGrenade(iUserDrop, 11);
				CS_DropWeapon(iUserDrop, iEntity, true, false);
				if (iBuffer)
				{
					if (iBuffer == 2)
					{
						GivePlayerItem(iUserDrop, sBuffer, 0);
					}
					if (iBuffer > 2)
					{
						GivePlayerItem(iUserDrop, sBuffer, 0);
						iBuffer--;
						SetPlayerGrenade(iUserDrop, 11, iBuffer);
					}
				}
				return Action:3;
			}
			CS_DropWeapon(iUserDrop, iEntity, true, false);
			return Action:3;
		}
	}
	return Action:0;
}

public bool:isUsersDropWeapon(client)
{
	new var1;
	return g_bUsersVip[client] || g_bUsersCmds[client];
}

public Events_OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode:1);
	HookEvent("player_jump", Event_PlayerJump, EventHookMode:1);
	HookEvent("bomb_planted", Event_PlayerBomb, EventHookMode:1);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode:1);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode:1);
	if (g_iGame == GameType:2)
	{
		HookEvent("player_falldamage", Event_PlayerFallDamagePre, EventHookMode:0);
	}
	HookEvent("player_falldamage", Event_PlayerFallDamage, EventHookMode:1);
	if (g_iGame != GameType:3)
	{
		HookEvent("item_pickup", Event_PlayerItemPickUp, EventHookMode:1);
	}
	HookEvent("flashbang_detonate", Event_FlashBang, EventHookMode:1);
	HookEvent("weapon_reload", Event_WeaponReload, EventHookMode:1);
	HookEvent("weapon_fire_on_empty", Event_WeaponReload, EventHookMode:1);
	HookEvent("round_start", Event_RoundStart, EventHookMode:2);
	HookEvent("round_end", Event_RoundEnd, EventHookMode:2);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode:1);
	if (g_iGame != GameType:3)
	{
		HookEvent("weapon_fire", Event_WeaponFire, EventHookMode:1);
	}
	return 0;
}

public Event_WeaponFire(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sBuffer[32];
	new var1;
	if (client && g_bPlayerVip[client][38] && g_iPlayerVip[client][38] && IsClientInGame(client))
	{
		GetEventString(event, "weapon", sBuffer, 32);
		if (g_iGame != GameType:2)
		{
			WeaponFireSound(client, sBuffer[1]);
		}
		WeaponFireSound(client, sBuffer);
	}
	return 0;
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (client && IsClientInGame(client))
	{
		PlayerSpawn_Init(client);
	}
	return 0;
}

public PlayerSpawn_Init(client)
{
	g_iClientTeam[client] = GetClientTeam(client);
	if (g_iClientTeam[client])
	{
		g_bPlayerAlive[client] = IsPlayerAlive(client);
		new var1;
		if (g_bUsersActivate && g_bUsersVip[client] && g_bPlayerAlive[client])
		{
			new var2;
			if (g_bPlayerVip[client][1] && g_iPlayerVip[client][1])
			{
				PlayerSpawn_Models(client);
			}
			g_bUsersGiveWeaponsItemPickUp[client] = 1;
			new var3;
			if (g_bGiveWeapons && g_bNoRestrictOnWarmup && g_bPlayerVip[client][5] && g_iPlayerVip[client][5])
			{
				PlayerSpawn_Weapon(client, g_iClientTeam[client]);
			}
			new var4;
			if (g_bPlayerVip[client][4] && g_iPlayerVip[client][4])
			{
				PlayerSpawn_Cash(client);
			}
			if (g_bPlayerVip[client][17])
			{
				g_bHealthChoose[client] = 0;
				if (g_iPlayerVip[client][17] != 100)
				{
					PlayerSpawn_Health(client);
				}
			}
			new var5;
			if (g_bPlayerVip[client][18] && g_iPlayerVip[client][18] != 1)
			{
				PlayerSpawn_Speed(client);
			}
			new var6;
			if (g_bPlayerVip[client][19] && g_iGravityOffset[client] > -1)
			{
				PlayerSpawn_Gravity(client);
			}
			new var7;
			if (g_bIsDeMap && g_bPlayerVip[client][12] && g_iPlayerVip[client][12] && g_iClientTeam[client] == 2 && OnWeaponRestrictImmune(client, 2, WeaponID:6))
			{
				CreateTimer(0.29, Timer_SpawnBomb, g_iClientUserId[client], 0);
			}
			if (g_hTimerHeartBeat[client])
			{
				KillTimer(g_hTimerHeartBeat[client], false);
				g_hTimerHeartBeat[client] = 0;
			}
			if (g_hTimerMedic[client][0])
			{
				KillTimer(g_hTimerMedic[client][0], false);
				g_hTimerMedic[client][0] = MissingTAG:0;
			}
			new var8;
			if (!g_bUsersWeaponKnife[client] && g_bPlayerVip[client][32])
			{
				new iBuffer = GetPlayerWeaponSlot(client, 2);
				if (iBuffer > g_iMaxClients)
				{
					SetUsersWeaponColors(client, iBuffer);
				}
			}
		}
	}
	else
	{
		g_bPlayerAlive[client] = 0;
	}
	return 0;
}

public Event_PlayerJump(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (client && g_bPlayerVip[client][3] && g_iPlayerVip[client][3] && IsClientInGame(client))
	{
		SetEntDataFloat(client, g_iStaminaOffset, 0.0, true);
	}
	return 0;
}

public Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new var1;
	if (client && attacker)
	{
		if (g_bUsersVip[client])
		{
			new var2;
			if (g_bUsersActivate && g_bPlayerVip[client][14] && g_iPlayerVip[client][14])
			{
				Player_Regeneration(client);
			}
			new var3;
			if (g_bHeartBeat && g_bPlayerVip[client][25] && g_iPlayerVip[client][25])
			{
				Player_HeartBeat(client);
			}
		}
		if (attacker != client)
		{
			if (g_iClientTeam[attacker] != g_iClientTeam[client])
			{
				new total;
				new clients[66];
				new i = 1;
				while (i <= g_iMaxClients)
				{
					new var4;
					if (g_iClientTeam[i] == g_iClientTeam[client] && g_bPlayerAlive[i] && g_bPlayerVip[i][15] && g_iPlayerVip[i][15] && IsClientInGame(i))
					{
						total++;
						clients[total] = i;
					}
					i++;
				}
				if (total)
				{
					TE_Start("RadioIcon");
					TE_WriteNum("m_iAttachToClient", client);
					TE_Send(clients, total, 0.0);
				}
			}
			if (g_hTimerMedic[client][1])
			{
				KillTimer(g_hTimerMedic[client][1], false);
				g_hTimerMedic[client][1] = MissingTAG:0;
				new iMedic = GetClientOfUserId(g_iMedic[client]);
				new var5;
				if (iMedic && g_iMedic[iMedic] == GetEventInt(event, "userid") && g_hTimerMedic[iMedic][0])
				{
					KillTimer(g_hTimerMedic[iMedic][0], false);
					g_hTimerMedic[iMedic][0] = MissingTAG:0;
					g_fMedic[iMedic] = 0;
					g_fMedicProgresBarPos[iMedic] = 0;
					g_fMedicProgresBarMax[iMedic] = 0;
					new iFrag = GetPlayerFrags(iMedic);
					if (iFrag >= 1)
					{
						iFrag += -1;
						SetPlayerFrags(iMedic, iFrag);
					}
					else
					{
						iFrag = -1;
					}
					new var6;
					if (g_bPlayerAlive[iMedic] && IsClientInGame(iMedic) && IsClientInGame(client))
					{
						new iBuffer;
						new i = 1;
						while (i <= g_iMaxClients)
						{
							new var7;
							if (iMedic != i && IsClientInGame(i) && IsClientObserver(i))
							{
								iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
								if (g_iGame != GameType:2)
								{
									iBuffer += 1;
								}
								new var8;
								if (iBuffer == 3 || iBuffer == 4)
								{
									iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
									if (iMedic == iBuffer)
									{
										if (iFrag == -1)
										{
											VipPrint(i, enSound:0, "Потерян 1 фраг! %N получил повреждение. Заряд медика отменён!", client);
											PrintHintText(i, "Потерян 1 фраг! %N получил повреждение.\nЗаряд медика отменён!", client);
										}
										else
										{
											VipPrint(i, enSound:0, "%N получил повреждение. Заряд медика отменён!", client);
											PrintHintText(i, "%N получил повреждение.\nЗаряд медика отменён!", client);
										}
										EmitSoundToClient(i, "buttons/combine_button2.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
									}
								}
							}
							i++;
						}
						EmitSoundToClient(iMedic, "buttons/combine_button2.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
						if (iFrag == -1)
						{
							VipPrint(iMedic, enSound:0, "Потерян 1 фраг! %N получил повреждение. Заряд медика отменён!", client);
							PrintHintText(iMedic, "Потерян 1 фраг! %N получил повреждение.\nЗаряд медика отменён!", client);
						}
						else
						{
							VipPrint(iMedic, enSound:0, "%N получил повреждение. Заряд медика отменён!", client);
							PrintHintText(iMedic, "%N получил повреждение.\nЗаряд медика отменён!", client);
						}
					}
				}
				g_iMedic[client] = 0;
			}
		}
		new var9;
		if (g_bUsersVip[attacker] && g_bPlayerVip[attacker][6] && g_iPlayerVip[attacker][6] && attacker != client)
		{
			client = GetEventInt(event, "health");
			if (client)
			{
				PrintCenterText(attacker, "-%i : %i HP", GetEventInt(event, "dmg_health"), client);
			}
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
		if (g_bUsersVip[client])
		{
			new var1;
			if (g_bGiveWeapons && g_bPlayerVip[client][5])
			{
				g_bUsersWeaponPrimaryPlayerDies[client] = 1;
				g_bUsersWeaponSecondaryPlayerDies[client] = 1;
			}
			g_bUsersGiveWeaponsItemPickUp[client] = 0;
			new var2;
			if (g_bPlayerVip[client][18] && g_iPlayerVip[client][18] != 1)
			{
				PlayerDead_Speed(client);
			}
			if (g_bPlayerVip[client][23])
			{
				UsersChangeTeam(client);
			}
			if (g_hTimerHeartBeat[client])
			{
				KillTimer(g_hTimerHeartBeat[client], false);
				g_hTimerHeartBeat[client] = 0;
				StopSound(client, 0, g_sSoundHeartBeat);
			}
			new var3;
			if (g_bPlayerVip[client][30] && g_iPlayerVip[client][30])
			{
				Player_DissolveRagdoll(g_iClientUserId[client]);
			}
			if (g_hTimerMedic[client][0])
			{
				KillTimer(g_hTimerMedic[client][0], false);
				g_hTimerMedic[client][0] = MissingTAG:0;
			}
			g_fMedic[client] = 0;
			g_fMedicProgresBarPos[client] = 0;
			g_fMedicProgresBarMax[client] = 0;
		}
		new var4;
		if (attacker && g_bPlayerVip[attacker][33] && g_bPlayerAlive[attacker] && attacker != client && g_iPlayerVip[attacker][33])
		{
			if (GetEventBool(event, "headshot"))
			{
				new iBuffer;
				new i = 1;
				while (i <= g_iMaxClients)
				{
					new var5;
					if (attacker != i && client != i && IsClientInGame(i) && IsClientObserver(i))
					{
						iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
						if (g_iGame != GameType:2)
						{
							iBuffer += 1;
						}
						new var6;
						if (iBuffer == 3 || iBuffer == 4)
						{
							iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
							if (attacker == iBuffer)
							{
								UsersKillEffectFade(i, false);
							}
						}
					}
					i++;
				}
				UsersKillEffectFade(attacker, true);
			}
			decl String:sWeapon[64];
			GetEventString(event, "weapon", sWeapon, 64);
			new var7;
			if (strcmp(sWeapon, "knife", false) && strcmp(sWeapon[1], "knife", false) && strcmp(sWeapon, "hegrenade", false) && strcmp(sWeapon[1], "hegrenade", false) && strcmp(sWeapon, "molotov", false) && strcmp(sWeapon[1], "molotov", false) && strcmp(sWeapon, "decoy", false) && strcmp(sWeapon[1], "decoy", false))
			{
				new iBuffer;
				new i = 1;
				while (i <= g_iMaxClients)
				{
					new var8;
					if (attacker != i && client != i && IsClientInGame(i) && IsClientObserver(i))
					{
						iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
						if (g_iGame != GameType:2)
						{
							iBuffer += 1;
						}
						new var9;
						if (iBuffer == 3 || iBuffer == 4)
						{
							iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
							if (attacker == iBuffer)
							{
								UsersKillEffectFade(i, false);
							}
						}
					}
					i++;
				}
				UsersKillEffectFade(attacker, true);
			}
		}
		if (IsClientInGame(client))
		{
			new ent = GetEntPropEnt(client, PropType:1, "m_hEffectEntity", 0);
			new var10;
			if (ent > MaxClients && IsValidEdict(ent))
			{
				SetEntPropFloat(ent, PropType:1, "m_flLifetime", 0.0, 0);
			}
		}
		UsersDropBombDead();
		g_iMedic[client] = 0;
	}
	return 0;
}

public Action:Event_PlayerFallDamagePre(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (g_iPlayerVip[client][26] && GetEventFloat(event, "damage") >= float(GetPlayerHealth(client)))
	{
		SetEntProp(client, PropType:1, "m_takedamage", any:1, 4, 0);
	}
	return Action:0;
}

public Event_PlayerFallDamage(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (client && g_bUsersVip[client])
	{
		new var2;
		if (g_iGame == GameType:2 && g_iPlayerVip[client][26])
		{
			SetEntProp(client, PropType:1, "m_takedamage", any:2, 4, 0);
		}
		new var3;
		if (g_bUsersActivate && g_iPlayerVip[client][14])
		{
			Player_Regeneration(client);
		}
		new var4;
		if (g_bHeartBeat && g_iPlayerVip[client][25])
		{
			Player_HeartBeat(client);
		}
	}
	return 0;
}

public Event_PlayerItemPickUp(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (client && g_bUsersVip[client])
	{
		decl String:sWeapon[20];
		GetEventString(event, "item", sWeapon, 17);
		new var2;
		if (g_bUsersGiveWeaponsItemPickUp[client] && g_bPlayerVip[client][5])
		{
			decl String:sBuffer[20];
			Format(sBuffer, 17, "weapon_%s", sWeapon);
			if (g_iClientTeam[client] == 2)
			{
				new var3;
				if (g_bUsersWeaponSecondaryT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
				{
					g_bUsersWeaponSecondaryPlayerDies[client] = 0;
				}
				else
				{
					new var4;
					if (g_bUsersWeaponPrimaryT[client] && FindStringInArray(g_hUsersWeaponArrayPrimary, sBuffer) != -1)
					{
						g_bUsersWeaponPrimaryPlayerDies[client] = 0;
					}
				}
			}
			else
			{
				if (g_iClientTeam[client] == 3)
				{
					new var5;
					if (g_bUsersWeaponSecondaryCT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
					{
						g_bUsersWeaponSecondaryPlayerDies[client] = 0;
					}
					new var6;
					if (g_bUsersWeaponPrimaryCT[client] && FindStringInArray(g_hUsersWeaponArrayPrimary, sBuffer) != -1)
					{
						g_bUsersWeaponPrimaryPlayerDies[client] = 0;
					}
				}
			}
		}
		new var7;
		if (g_bPlayerVip[client][7] && g_iPlayerVip[client][7])
		{
			if (g_iPlayerVip[client][7] == 1)
			{
				new var8;
				if (strcmp(sWeapon, "m4a1", false) && !GetWeaponSilencer(client, 0))
				{
					SetWeaponSilencer(client, 0);
				}
				else
				{
					new var9;
					if (strcmp(sWeapon, "usp", false) && !GetWeaponSilencer(client, 1))
					{
						SetWeaponSilencer(client, 1);
					}
				}
			}
			if (g_iPlayerVip[client][7] == 2)
			{
				new var10;
				if (strcmp(sWeapon, "m4a1", false) && !GetWeaponSilencer(client, 0))
				{
					SetWeaponSilencer(client, 0);
				}
			}
			new var11;
			if (strcmp(sWeapon, "usp", false) && !GetWeaponSilencer(client, 1))
			{
				SetWeaponSilencer(client, 1);
			}
		}
	}
	return 0;
}

public Event_FlashBang(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		new var3;
		var3 + var3/* ERROR unknown load Binary */ = GetEventFloat(event, "x");
		var3 + var3 + 4/* ERROR unknown load Binary */ = GetEventFloat(event, "y");
		var3 + var3 + 8/* ERROR unknown load Binary */ = GetEventFloat(event, "z");
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var1;
			if (g_bPlayerVip[i][9] && g_iPlayerVip[i][9] && IsClientInGame(i))
			{
				new var4 = var3 + 4;
				GetClientEyePosition(i, var4 + var4);
				new var5 = var3 + 4;
				AntiFlash_VectorDistance(i, var3 + var3, var5 + var5);
			}
			else
			{
				new var2;
				if (g_bPlayerVip[i][8] && g_iPlayerVip[i][8] && g_iClientTeam[client] == g_iClientTeam[i] && i != client && IsClientInGame(i))
				{
					new var6 = var3 + 4;
					GetClientEyePosition(i, var6 + var6);
					new var7 = var3 + 4;
					AntiFlash_VectorDistance(i, var3 + var3, var7 + var7);
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
	if (client && g_bPlayerVip[client][28] && g_bPlayerAlive[client] && g_iPlayerVip[client][28])
	{
		Player_WeaponReload(client);
	}
	return 0;
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if (g_bChangeTeam)
	{
		ClearArray(g_hChangeTeamArray);
		g_bChangeTeam = false;
	}
	if (g_iWeaponRestrictImmuneBalance)
	{
		OnWeaponRestrictionBalance();
	}
	return 0;
}

public Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	new var1;
	if (!g_bUsersActivate && g_iActivateRounds > g_iUsersActivateRounds)
	{
		g_iActivateRounds = 0;
		g_bUsersActivate = true;
	}
	if (g_iArrayUsers != -1)
	{
		new iTime = GetTime(405144);
		new bool:bSave;
		new iBuffer;
		decl String:sBuffer[64];
		decl String:sName[32];
		new i;
		while (i <= g_iArrayUsers)
		{
			iBuffer = GetArrayCell(g_hArrayUsersExpires, i, 0, false);
			new var2;
			if (iBuffer && iTime >= iBuffer)
			{
				GetArrayString(g_hArrayUsers, i, sBuffer, 64);
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, sBuffer, false))
				{
					KvGetString(g_hKvUsers, "name", sName, 32, "none");
					KvDeleteThis(g_hKvUsers);
					Vip_Log("Атрибуты VIP удалены у %s (ID: %s). Причина: Истекло время.", sName, sBuffer);
					bSave = true;
				}
				RemoveFromArray(g_hArrayUsers, i);
				RemoveFromArray(g_hArrayUsersExpires, i);
				RemoveFromArray(g_hArrayUsersPassword, i);
				g_iArrayUsers -= 1;
				i--;
				DeleteUserSettings(sBuffer);
				ResettingTheFlags(sBuffer);
				iBuffer = 1;
				while (iBuffer <= g_iMaxClients)
				{
					new var3;
					if (strcmp(sBuffer, g_sClientAuth[iBuffer], false) && IsClientInGame(iBuffer))
					{
						VipPrint(iBuffer, enSound:2, "Ваш период использования VIP функций закончилось!");
					}
					iBuffer++;
				}
			}
			i++;
		}
		if (bSave)
		{
			KvRewind(g_hKvUsers);
			new var4 = g_sUsersPath;
			KeyValuesToFile(g_hKvUsers, var4[0][var4]);
		}
	}
	return 0;
}

public Event_PlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		if (g_bUsersVip[client])
		{
			new var1;
			if (g_bGiveWeapons && g_bPlayerVip[client][5])
			{
				g_bUsersWeaponPrimaryPlayerDies[client] = 1;
				g_bUsersWeaponSecondaryPlayerDies[client] = 1;
			}
			g_bUsersGiveWeaponsItemPickUp[client] = 0;
		}
	}
	return 0;
}

public Users_WeaponEquipPost(client, weapon)
{
	new var1;
	if (g_bPlayerAlive[client] && g_iClientTeam[client] && IsValidEntity(weapon) && IsClientInGame(client))
	{
		if (g_iGame == GameType:3)
		{
			decl String:sWeapon[32];
			new iBuffer = GetEntProp(weapon, PropType:0, "m_iItemDefinitionIndex", 4, 0);
			if (iBuffer == 60)
			{
				strcopy(sWeapon, 32, "weapon_m4a1_silencer");
			}
			else
			{
				if (iBuffer == 61)
				{
					strcopy(sWeapon, 32, "weapon_usp_silencer");
				}
				if (iBuffer == 63)
				{
					strcopy(sWeapon, 32, "weapon_cz75a");
				}
				GetEntityClassname(weapon, sWeapon, 32);
			}
			new var2;
			if (g_iPlayerVip[client][5] && g_bUsersGiveWeaponsItemPickUp[client])
			{
				if (g_iClientTeam[client] == 2)
				{
					new var3;
					if (g_bUsersWeaponSecondaryT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sWeapon) != -1)
					{
						g_bUsersWeaponSecondaryPlayerDies[client] = 0;
					}
					else
					{
						new var4;
						if (g_bUsersWeaponPrimaryT[client] && FindStringInArray(g_hUsersWeaponArrayPrimary, sWeapon) != -1)
						{
							g_bUsersWeaponPrimaryPlayerDies[client] = 0;
						}
					}
				}
				if (g_iClientTeam[client] == 3)
				{
					new var5;
					if (g_bUsersWeaponSecondaryCT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sWeapon) != -1)
					{
						g_bUsersWeaponSecondaryPlayerDies[client] = 0;
					}
					new var6;
					if (g_bUsersWeaponPrimaryCT[client] && FindStringInArray(g_hUsersWeaponArrayPrimary, sWeapon) != -1)
					{
						g_bUsersWeaponPrimaryPlayerDies[client] = 0;
					}
				}
			}
			if (g_iPlayerVip[client][7])
			{
				if (g_iPlayerVip[client][7] == 1)
				{
					new var7;
					if (strcmp(sWeapon[1], "m4a1_silencer", false) && !GetWeaponSilencer(client, 0))
					{
						SetWeaponSilencer(client, 0);
					}
					else
					{
						new var8;
						if (strcmp(sWeapon[1], "usp_silencer", false) && !GetWeaponSilencer(client, 1))
						{
							SetWeaponSilencer(client, 1);
						}
					}
				}
				if (g_iPlayerVip[client][7] == 2)
				{
					new var9;
					if (strcmp(sWeapon[1], "m4a1_silencer", false) && !GetWeaponSilencer(client, 0))
					{
						SetWeaponSilencer(client, 0);
					}
				}
				new var10;
				if (strcmp(sWeapon[1], "usp_silencer", false) && !GetWeaponSilencer(client, 1))
				{
					SetWeaponSilencer(client, 1);
				}
			}
		}
		SetUsersWeaponColors(client, weapon);
	}
	return 0;
}

public OnEntityCreated(entity, String:classname[])
{
	new var1;
	if (strncmp(classname, "hegrenade_projectile", 20, false) && strncmp(classname, "flashbang_projectile", 20, false) && strncmp(classname, "smokegrenade_projectile", 23, false) && strncmp(classname, "molotov_projectile", 18, false) && strncmp(classname, "decoy_projectile", 16, false))
	{
		CreateTimer(0.0, Timer_EntityGrenade, entity, 2);
	}
	return 0;
}

public GiveWeapons_Init()
{
	g_hWeaponTrie = CreateTrie();
	SetTrieValue(g_hWeaponTrie, "ak47", any:0, true);
	SetTrieValue(g_hWeaponTrie, "awp", any:0, true);
	SetTrieValue(g_hWeaponTrie, "g3sg1", any:0, true);
	SetTrieValue(g_hWeaponTrie, "famas", any:0, true);
	SetTrieValue(g_hWeaponTrie, "m4a1", any:0, true);
	SetTrieValue(g_hWeaponTrie, "aug", any:0, true);
	if (g_iGame == GameType:3)
	{
		SetTrieValue(g_hWeaponTrie, "galilar", any:0, true);
		SetTrieValue(g_hWeaponTrie, "nova", any:0, true);
		SetTrieValue(g_hWeaponTrie, "m4a1_silencer", any:0, true);
		SetTrieValue(g_hWeaponTrie, "bizon", any:0, true);
		SetTrieValue(g_hWeaponTrie, "mag7", any:0, true);
		SetTrieValue(g_hWeaponTrie, "negev", any:0, true);
		SetTrieValue(g_hWeaponTrie, "sawedoff", any:0, true);
		SetTrieValue(g_hWeaponTrie, "tec9", any:0, true);
		SetTrieValue(g_hWeaponTrie, "taser", any:2, true);
		SetTrieValue(g_hWeaponTrie, "hkp2000", any:1, true);
		SetTrieValue(g_hWeaponTrie, "mp7", any:0, true);
		SetTrieValue(g_hWeaponTrie, "mp9", any:0, true);
		SetTrieValue(g_hWeaponTrie, "p250", any:1, true);
		SetTrieValue(g_hWeaponTrie, "scar20", any:0, true);
		SetTrieValue(g_hWeaponTrie, "sg556", any:0, true);
		SetTrieValue(g_hWeaponTrie, "ssg08", any:0, true);
		SetTrieValue(g_hWeaponTrie, "molotov", any:3, true);
		SetTrieValue(g_hWeaponTrie, "decoy", any:3, true);
		SetTrieValue(g_hWeaponTrie, "usp_silencer", any:1, true);
		SetTrieValue(g_hWeaponTrie, "cz75a", any:1, true);
	}
	else
	{
		SetTrieValue(g_hWeaponTrie, "scout", any:0, true);
		SetTrieValue(g_hWeaponTrie, "sg552", any:0, true);
		SetTrieValue(g_hWeaponTrie, "sg550", any:0, true);
		SetTrieValue(g_hWeaponTrie, "tmp", any:0, true);
		SetTrieValue(g_hWeaponTrie, "mp5navy", any:0, true);
		SetTrieValue(g_hWeaponTrie, "p228", any:1, true);
		SetTrieValue(g_hWeaponTrie, "galil", any:0, true);
		SetTrieValue(g_hWeaponTrie, "m3", any:0, true);
		SetTrieValue(g_hWeaponTrie, "usp", any:1, true);
	}
	SetTrieValue(g_hWeaponTrie, "xm1014", any:0, true);
	SetTrieValue(g_hWeaponTrie, "mac10", any:0, true);
	SetTrieValue(g_hWeaponTrie, "ump45", any:0, true);
	SetTrieValue(g_hWeaponTrie, "p90", any:0, true);
	SetTrieValue(g_hWeaponTrie, "m249", any:0, true);
	SetTrieValue(g_hWeaponTrie, "glock", any:1, true);
	SetTrieValue(g_hWeaponTrie, "deagle", any:1, true);
	SetTrieValue(g_hWeaponTrie, "elite", any:1, true);
	SetTrieValue(g_hWeaponTrie, "fiveseven", any:1, true);
	SetTrieValue(g_hWeaponTrie, "knife", any:2, true);
	SetTrieValue(g_hWeaponTrie, "hegrenade", any:3, true);
	SetTrieValue(g_hWeaponTrie, "flashbang", any:3, true);
	SetTrieValue(g_hWeaponTrie, "smokegrenade", any:3, true);
	SetTrieValue(g_hWeaponTrie, "c4", any:4, true);
	RegConsoleCmd("vip_weapon", GiveWeapon_Command, "vip_weapon ak47", 0);
	RegConsoleCmd("vip_giveweapon", GiveWeapon_Command, "vip_giveweapon ak47", 0);
	RegConsoleCmd("vip_give", GiveWeapon_Command, "vip_give ak47", 0);
	return 0;
}

public Action:GiveWeapon_Command(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][27])
		{
			if (g_bGiveWeapons)
			{
				if (args)
				{
					if (g_iPlayerVip[client][27])
					{
						if (g_bUsersActivate)
						{
							new var4;
							decl iBuffer[2];
							g_iClientTeam[client] = GetClientTeam(client);
							GetCmdArgString(var4 + var4, 64);
							if (GetTrieValue(g_hWeaponTrie, var4 + var4, iBuffer))
							{
								g_bPlayerAlive[client] = IsPlayerAlive(client);
								new var1;
								if (OnWeaponRestrictImmune(client, 2, GetWeaponID(var4 + var4)) || OnWeaponRestrictImmune(client, 3, GetWeaponID(var4 + var4)))
								{
									Format(var4 + var4, 64, "weapon_%s", var4 + var4);
									if (g_bPlayerAlive[client])
									{
										switch (iBuffer[0])
										{
											case 3:
											{
												if (strcmp("weapon_hegrenade", var4 + var4, false))
												{
													if (strcmp("weapon_flashbang", var4 + var4, false))
													{
														if (!(strcmp("weapon_smokegrenade", var4 + var4, false)))
														{
															iBuffer[1] = GetPlayerGrenade(client, 13);
															if (iBuffer[1])
															{
																new var7 = iBuffer[1];
																var7++;
																SetPlayerGrenade(client, 13, var7);
															}
															GivePlayerItem(client, var4 + var4, 0);
														}
													}
													iBuffer[1] = GetPlayerGrenade(client, 12);
													if (iBuffer[1])
													{
														new var6 = iBuffer[1];
														var6++;
														SetPlayerGrenade(client, 12, var6);
													}
													else
													{
														GivePlayerItem(client, var4 + var4, 0);
													}
												}
												else
												{
													iBuffer[1] = GetPlayerGrenade(client, 11);
													if (iBuffer[1])
													{
														new var5 = iBuffer[1];
														var5++;
														SetPlayerGrenade(client, 11, var5);
													}
													else
													{
														GivePlayerItem(client, var4 + var4, 0);
													}
												}
											}
											case 4:
											{
												if (g_iClientTeam[client] == 2)
												{
													if (GetPlayerWeaponSlot(client, iBuffer[0]) < 1)
													{
														GivePlayerItem(client, var4 + var4, 0);
													}
												}
												else
												{
													VipPrint(client, enSound:2, "Вашей команде недоступно С4!");
												}
											}
											default:
											{
												iBuffer[1] = GetPlayerWeaponSlot(client, iBuffer[0]);
												if (iBuffer[1] > 1)
												{
													new var8 = var4 + 4;
													new var2;
													if (GetEdictClassname(iBuffer[1], var8 + var8, 64) && strcmp(var4 + var4, var9 + var9, false))
													{
														RemovePlayerItem(client, iBuffer[1]);
														RemoveEdict(iBuffer[1]);
														iBuffer[1] = GivePlayerItem(client, var4 + var4, 0);
													}
												}
												else
												{
													iBuffer[1] = GivePlayerItem(client, var4 + var4, 0);
												}
											}
										}
									}
									new var3;
									if (g_bPlayerVip[client][5] && g_iPlayerVip[client][5])
									{
										switch (iBuffer[0])
										{
											case 0:
											{
												if (g_iClientTeam[client] == 2)
												{
													strcopy(g_sUsersWeaponPrimaryT[client], 32, var4 + var4);
													g_bSettingsChanged[client] = 1;
												}
												else
												{
													if (g_iClientTeam[client] == 3)
													{
														strcopy(g_sUsersWeaponPrimaryCT[client], 32, var4 + var4);
														g_bSettingsChanged[client] = 1;
													}
												}
											}
											case 1:
											{
												if (g_iClientTeam[client] == 2)
												{
													strcopy(g_sUsersWeaponSecondaryT[client], 32, var4 + var4);
													g_bSettingsChanged[client] = 1;
												}
												else
												{
													if (g_iClientTeam[client] == 3)
													{
														strcopy(g_sUsersWeaponSecondaryCT[client], 32, var4 + var4);
														g_bSettingsChanged[client] = 1;
													}
												}
											}
											default:
											{
											}
										}
									}
								}
								else
								{
									VipPrint(client, enSound:2, "Оружие %s заблокировано!", var4 + var4);
								}
							}
							else
							{
								VipPrint(client, enSound:2, "Неизвестное оружие!");
							}
						}
						else
						{
							VipPrint(client, enSound:2, "Оружия будут доступны через %i рауда(ов).", g_iUsersActivateRounds - g_iActivateRounds + 2);
						}
					}
					else
					{
						VipPrint(client, enSound:2, "Чтобы получить оружие, опция должна быть включена!");
					}
				}
				else
				{
					VipPrint(client, enSound:0, "Пример: vip_give ak47");
				}
			}
			else
			{
				VipPrint(client, enSound:2, "На карте %s отключена установка оружия!", g_sMap);
			}
		}
		else
		{
			VipPrint(client, enSound:2, "Вам недоступна эта команда!");
		}
	}
	else
	{
		ReplyToCommand(client, "[VIP] Available only to players!");
	}
	return Action:3;
}

public Health_OnPluginStart()
{
	RegConsoleCmd("vip_health", SetHealth_Cmd, "vip_health 115", 0);
	RegConsoleCmd("vip_hp", SetHealth_Cmd, "vip_hp 115", 0);
	return 0;
}

public PlayerSpawn_Health(client)
{
	if (g_iPlayerVip[client][17] > g_iMaxHealth)
	{
		g_iPlayerVip[client][17] = g_iMaxHealth;
		g_bSettingsChanged[client] = 1;
	}
	SetPlayerHealth(client, g_iPlayerVip[client][17]);
	return 0;
}

public Action:SetHealth_Cmd(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][17])
		{
			if (args)
			{
				if (g_bUsersActivate)
				{
					decl String:sBuffer[8];
					GetCmdArgString(sBuffer, 5);
					new iBuffer = StringToInt(sBuffer, 10);
					new var1;
					if (iBuffer > 0 && g_iMaxHealth >= iBuffer)
					{
						new var2;
						if (g_bPlayerAlive[client] && GetPlayerHealth(client) != iBuffer)
						{
							if (g_bHealthChoose[client])
							{
								VipPrint(client, enSound:2, "Разрешено устанавливать HP 1 раз за раунд!");
							}
							if (iBuffer >= g_iMaxHealth)
							{
								SetPlayerHealth(client, g_iMaxHealth);
								new var3;
								if (g_bPlayerVip[client][27] && g_iPlayerVip[client][27])
								{
									SetPlayerArmor(client, g_iMaxHealth);
								}
							}
							else
							{
								SetPlayerHealth(client, iBuffer);
								new var4;
								if (g_bPlayerVip[client][27] && g_iPlayerVip[client][27])
								{
									SetPlayerArmor(client, iBuffer);
								}
							}
							g_bHealthChoose[client] = 1;
						}
						if (iBuffer != g_iPlayerVip[client][17])
						{
							g_iPlayerVip[client][17] = iBuffer;
							g_bSettingsChanged[client] = 1;
						}
					}
					else
					{
						ReplyToCommand(client, "\x04[VIP]\x01 Указанное число %s HP недопустимо!", sBuffer);
					}
				}
				else
				{
					VipPrint(client, enSound:2, "Установка HP будет доступна через %i рауда(ов).", g_iUsersActivateRounds - g_iActivateRounds + 2);
				}
			}
			else
			{
				ReplyToCommand(client, "\x04[VIP]\x01 Устанвока HP \"vip_health 115\" или \"vip_hp 115\"");
			}
		}
		VipPrint(client, enSound:2, "Вам недоступна эта команда!");
	}
	return Action:3;
}

public Display_SpawnHeatlthSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_SpawnHeatlthSettings, MenuAction:28);
	decl String:sBuffer[72];
	if (g_iPlayerVip[client][17] == 100)
	{
		Format(sBuffer, 72, "HP пpи cпaвнe: [Hacтpoйкa]");
	}
	else
	{
		Format(sBuffer, 72, "%i HP пpи cпaвнe: [Hacтpoйкa]", g_iPlayerVip[client][17]);
	}
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "100", "Не Устанавливать: [Стандарт]", 0);
	AddMenuItem(hMenu, "10", "Устанавливать: [10 HP]", 0);
	AddMenuItem(hMenu, "35", "Устанавливать: [35 HP]", 0);
	AddMenuItem(hMenu, "50", "Устанавливать: [50 HP]", 0);
	AddMenuItem(hMenu, "75", "Устанавливать: [75 HP]", 0);
	if (g_iMaxHealth >= 85)
	{
		AddMenuItem(hMenu, "85", "Устанавливать: [85 HP]", 0);
	}
	if (g_iMaxHealth >= 95)
	{
		AddMenuItem(hMenu, "95", "Устанавливать: [95 HP]", 0);
	}
	if (g_iMaxHealth >= 105)
	{
		AddMenuItem(hMenu, "105", "Устанавливать: [105 HP]", 0);
	}
	if (g_iMaxHealth >= 115)
	{
		AddMenuItem(hMenu, "115", "Устанавливать: [115 HP]", 0);
	}
	if (g_iMaxHealth >= 150)
	{
		AddMenuItem(hMenu, "150", "Устанавливать: [150 HP]", 0);
	}
	if (g_iMaxHealth >= 200)
	{
		AddMenuItem(hMenu, "200", "Устанавливать: [200 HP]", 0);
	}
	if (g_iMaxHealth >= 250)
	{
		AddMenuItem(hMenu, "250", "Устанавливать: [250 HP]", 0);
	}
	if (g_iMaxHealth >= 300)
	{
		AddMenuItem(hMenu, "300", "Устанавливать: [300 HP]", 0);
	}
	if (g_iMaxHealth >= 350)
	{
		AddMenuItem(hMenu, "350", "Устанавливать: [350 HP]", 0);
	}
	if (g_iMaxHealth >= 400)
	{
		AddMenuItem(hMenu, "400", "Устанавливать: [400 HP]", 0);
	}
	if (g_iMaxHealth >= 450)
	{
		AddMenuItem(hMenu, "450", "Устанавливать: [450 HP]", 0);
	}
	if (g_iMaxHealth >= 500)
	{
		AddMenuItem(hMenu, "500", "Устанавливать: [500 HP]", 0);
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
			decl String:sBuffer[8];
			GetMenuItem(hMenu, param, sBuffer, 5, 0, "", 0);
			g_iPlayerVip[client][17] = StringToInt(sBuffer, 10);
			g_bSettingsChanged[client] = 1;
			VipPrint(client, enSound:0, "Установлено возрождение с HP [%s]", sBuffer);
			Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		}
	}
	return 0;
}

public Player_HeartBeat(client)
{
	if (!g_hTimerHeartBeat[client])
	{
		g_hTimerHeartBeat[client] = CreateTimer(GetRandomFloat(0.99, 2.1), Timer_SoundHeartBeat, client, 0);
	}
	return 0;
}

public Action:Timer_SoundHeartBeat(Handle:timer, any:client)
{
	g_hTimerHeartBeat[client] = 0;
	if (IsClientInGame(client))
	{
		g_bPlayerAlive[client] = IsPlayerAlive(client);
		new var1;
		if (g_bPlayerAlive[client] && g_iPlayerVip[client][25] >= GetPlayerHealth(client))
		{
			decl clients[MaxClients];
			new total;
			new iBuffer;
			if (g_bUsersHeartShaking[client])
			{
				HeartBeatShake(client);
			}
			total++;
			clients[total] = client;
			HeartBeatFade(client);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var2;
				if (client != i && IsClientInGame(i) && IsClientObserver(i))
				{
					iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
					if (g_iGame != GameType:2)
					{
						iBuffer += 1;
					}
					new var3;
					if (iBuffer == 3 || iBuffer == 4)
					{
						iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
						if (client == iBuffer)
						{
							total++;
							clients[total] = i;
							HeartBeatFade(i);
						}
					}
				}
				i++;
			}
			EmitSound(clients, total, g_sSoundHeartBeat, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			g_hTimerHeartBeat[client] = CreateTimer(GetRandomFloat(2.5, 5.5), Timer_SoundHeartBeat, client, 0);
		}
	}
	return Action:4;
}

public HeartBeatShake(client)
{
	new Handle:hBuffer = StartMessageOne("Shake", client, 132);
	if (hBuffer)
	{
		if (g_bProtobufMessage)
		{
			PbSetInt(hBuffer, "command", 0, -1);
			PbSetFloat(hBuffer, "local_amplitude", 2.5, -1);
			PbSetFloat(hBuffer, "frequency", 1.0, -1);
			PbSetFloat(hBuffer, "duration", 0.4, -1);
		}
		else
		{
			BfWriteByte(hBuffer, 0);
			BfWriteFloat(hBuffer, 2.5);
			BfWriteFloat(hBuffer, 1.0);
			BfWriteFloat(hBuffer, 0.4);
		}
		EndMessage();
	}
	return 0;
}

public HeartBeatFade(client)
{
	new Handle:hBuffer = StartMessageOne("Fade", client, 132);
	if (g_bProtobufMessage)
	{
		PbSetInt(hBuffer, "duration", 130, -1);
		PbSetInt(hBuffer, "hold_time", 100, -1);
		PbSetInt(hBuffer, "flags", 1, -1);
		PbSetColor(hBuffer, "clr", 408056, -1);
	}
	else
	{
		BfWriteShort(hBuffer, 130);
		BfWriteShort(hBuffer, 100);
		BfWriteShort(hBuffer, 1);
		BfWriteByte(hBuffer, 235);
		BfWriteByte(hBuffer, 203);
		BfWriteByte(hBuffer, 203);
		BfWriteByte(hBuffer, 18);
	}
	EndMessage();
	return 0;
}

public Display_HeartBeatSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_HeartBeatSettings, MenuAction:514);
	decl String:sBuffer[128];
	SetMenuTitle(hMenu, "Звук сердцебиения: Настройка");
	AddMenuItem(hMenu, NULL_STRING, "Выключить опцию", 0);
	Format(sBuffer, 128, "При и меньше %i HP [+5]", g_iPlayerVip[client][25]);
	if (g_iPlayerVip[client][25] < 95)
	{
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 0);
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	Format(sBuffer, 128, "При и меньше %i HP [-5]", g_iPlayerVip[client][25]);
	if (g_iPlayerVip[client][25] < 10)
	{
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 0);
	}
	if (g_bUsersHeartShaking[client])
	{
		AddMenuItem(hMenu, NULL_STRING, "Тpяcкa пpи cepдцeбиeнии: [Bключено]", 0);
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, "Тpяcкa пpи cepдцeбиeнии: [Bыключено]", 0);
	}
	AddMenuItem(hMenu, NULL_STRING, "Прослушать звук сердцебиения", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_HeartBeatSettings(Handle:hMenu, MenuAction:action, client, param)
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
			if (param == 1)
			{
				g_iPlayerVip[client][25] += 5;
				Display_HeartBeatSettings(client);
				g_bSettingsChanged[client] = 1;
			}
			if (param == 2)
			{
				g_iPlayerVip[client][25] += -5;
				Display_HeartBeatSettings(client);
				g_bSettingsChanged[client] = 1;
			}
			if (param == 3)
			{
				g_bSettingsChanged[client] = 1;
				if (g_bUsersHeartShaking[client])
				{
					g_bUsersHeartShaking[client] = 0;
					VipPrint(client, enSound:0, "Тряска при сердцебиении: [Выключено]");
				}
				else
				{
					g_bUsersHeartShaking[client] = 1;
					VipPrint(client, enSound:0, "Тряска при сердцебиении: [Включено]");
				}
				Display_HeartBeatSettings(client);
			}
			if (param == 4)
			{
				VipPrint(client, enSound:0, "Воспроизведён звук сердцебиения.");
				EmitSoundToClient(client, g_sSoundHeartBeat, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				Display_HeartBeatSettings(client);
			}
			g_bSettingsChanged[client] = 1;
			g_iPlayerVip[client][25] = 0;
			VipPrint(client, enSound:0, "Звук сердцебиения: [Выключен]");
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
		if (g_bPlayerVip[client][18])
		{
			if (args)
			{
				if (g_bUsersActivate)
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
						g_iPlayerVip[client][18] = iSpeed;
						g_bSettingsChanged[client] = 1;
					}
					else
					{
						VipPrint(client, enSound:2, "Предел скорости %i!", g_iMaxSpeed);
					}
				}
				else
				{
					VipPrint(client, enSound:2, "Установка скорости будет доступна через %i рауда(ов).", g_iUsersActivateRounds - g_iActivateRounds + 2);
				}
			}
			else
			{
				ReplyToCommand(client, "\x04[VIP]\x01 Настройка скорости \"vip_speed 5\"");
			}
		}
		VipPrint(client, enSound:2, "Вам недоступна эта команда!");
	}
	return Action:3;
}

public PlayerSpawn_Speed(client)
{
	SetPlayerSpeed(client, g_iPlayerVip[client][18][1091567616] / 10);
	return 0;
}

public PlayerDead_Speed(client)
{
	SetPlayerSpeed(client, 1.0);
	return 0;
}

public Display_SpawnSpeedSettings(client)
{
	new var1;
	var1 = CreateMenu(MenuHandler_SpawnSpeedSettings, MenuAction:28);
	new var2;
	Format(var2 + var2, 128, "Скорость перемещения: [Настройка]", client);
	SetMenuTitle(var1, var2 + var2);
	if (g_iPlayerVip[client][18] == 1)
	{
		AddMenuItem(var1, "1", "Стандартная скорость [x1]", 1);
	}
	else
	{
		AddMenuItem(var1, "1", "Стандартная скорость [x1]", 0);
	}
	new s = 2;
	while (s <= g_iMaxSpeed)
	{
		Format(var2 + var2, 128, "%i", s);
		new var3 = var2 + 4;
		Format(var3 + var3, 128, "Скорость: [x%i]", s, client);
		if (s == g_iPlayerVip[client][18])
		{
			new var4 = var2 + 4;
			AddMenuItem(var1, var2 + var2, var4 + var4, 1);
		}
		else
		{
			new var5 = var2 + 4;
			AddMenuItem(var1, var2 + var2, var5 + var5, 0);
		}
		s++;
	}
	SetMenuExitBackButton(var1, true);
	DisplayMenu(var1, client, 0);
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
			g_iPlayerVip[client][18] = StringToInt(sInfo, 10);
			g_bPlayerAlive[client] = IsPlayerAlive(client);
			if (g_bPlayerAlive[client])
			{
				SetPlayerSpeed(client, g_iPlayerVip[client][18][1091567616] / 10);
			}
			g_bSettingsChanged[client] = 1;
			PlayerSpawn_Speed(client);
			VipPrint(client, enSound:0, "Установлена скорость [x%s]", sInfo);
			Display_SpawnSpeedSettings(client);
		}
	}
	return 0;
}

public Action:Timer_SpawnBomb(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && g_bPlayerAlive[client] && g_iClientTeam[client] == 2 && IsClientInGame(client) && GetPlayerWeaponSlot(client, 4) == -1)
	{
		GivePlayerItem(client, "weapon_c4", 0);
	}
	return Action:4;
}

public UsersDropBombDead()
{
	new iBuffer[2];
	decl String:sWeapon[64];
	new i = 1;
	while (i < g_iMaxClients)
	{
		if (IsClientInGame(i))
		{
			iBuffer[1] = GetPlayerWeaponSlot(i, 4);
			new var1;
			if (iBuffer[1] > g_iMaxClients && IsValidEdict(iBuffer[1]) && IsValidEntity(iBuffer[1]) && GetEdictClassname(iBuffer[1], sWeapon, 64) && strcmp(sWeapon, "weapon_c4", false))
			{
				iBuffer[0] = GetMaxEntities();
				new ent = g_iMaxClients;
				while (iBuffer[0] > ent)
				{
					new var2;
					if (IsValidEdict(ent) && IsValidEntity(ent) && GetEdictClassname(ent, sWeapon, 64) && strcmp(sWeapon, "weapon_c4", false) && GetEntDataEnt2(ent, g_iOwnerEntityOffset) == -1)
					{
						RemoveEdict(ent);
					}
					ent++;
				}
				return 0;
			}
		}
		i++;
	}
	return 0;
}

public OnSwitchEquipAndRemoveC4(client)
{
	new iBuffer[2];
	iBuffer[1] = GetPlayerWeaponSlot(client, 4);
	if (iBuffer[1] > 1)
	{
		if (GetEntDataEnt2(client, g_iActiveWeaponOffset) == iBuffer[1])
		{
			RemovePlayerItem(client, iBuffer[1]);
			RemoveEdict(iBuffer[1]);
			if ((iBuffer[0] = GetPlayerWeaponSlot(client, 0)) > 1)
			{
				EquipPlayerWeapon(client, iBuffer[0]);
			}
			else
			{
				if ((iBuffer[0] = GetPlayerWeaponSlot(client, 1)) > 1)
				{
					EquipPlayerWeapon(client, iBuffer[0]);
				}
				if ((iBuffer[0] = GetPlayerWeaponSlot(client, 2)) > 1)
				{
					EquipPlayerWeapon(client, iBuffer[0]);
				}
				if ((iBuffer[0] = GetPlayerWeaponSlot(client, 3)) > 1)
				{
					EquipPlayerWeapon(client, iBuffer[0]);
				}
			}
		}
		RemovePlayerItem(client, iBuffer[1]);
		RemoveEdict(iBuffer[1]);
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
		if (IsValidEdict(ent) && IsValidEntity(ent) && GetEntDataEnt2(ent, g_iOwnerEntityOffset) == -1 && GetEdictClassname(ent, sWeapon, 64) && strcmp(sWeapon, "weapon_c4", false))
		{
			RemoveEdict(ent);
		}
		ent++;
	}
	new i = 1;
	while (i <= g_iMaxClients)
	{
		if (IsClientInGame(i))
		{
			OnSwitchEquipAndRemoveC4(i);
		}
		i++;
	}
	return Action:4;
}

public FriendlyFire_Init()
{
	g_hCvarFriendlyFire = FindConVar("mp_friendlyfire");
	FriendlyFireSettingsChanged(g_hCvarFriendlyFire, "", "");
	HookConVarChange(g_hCvarFriendlyFire, FriendlyFireSettingsChanged);
	g_hCvarVipFriendlyFire = CreateConVar("vip_friendlyfire", "1", "Игpoки бeз VIP пpивeлeгий нe cмoгут paнить нaпapникa.", 262144, true, 0.0, true, 1.0);
	FriendlyFireSettingsChanged(g_hCvarVipFriendlyFire, "", "");
	HookConVarChange(g_hCvarVipFriendlyFire, FriendlyFireSettingsChanged);
	g_hFriendlyFireActiv = CreateConVar("vip_friendlyfire_activ", "1", "Активировать работу переменных mp_friendlyfire и vip_friendlyfire.", 262144, true, 0.0, true, 1.0);
	FriendlyFireSettingsChanged(g_hFriendlyFireActiv, "", "");
	HookConVarChange(g_hFriendlyFireActiv, FriendlyFireSettingsChanged);
	return 0;
}

public FriendlyFireSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	if (g_hCvarFriendlyFire == convar)
	{
		g_bFriendLyFire = GetConVarBool(convar);
		Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bFriendLyFire);
	}
	else
	{
		if (g_hFriendlyFireActiv == convar)
		{
			g_bFriendlyFireActiv = GetConVarBool(convar);
			if (g_bFriendlyFireActiv)
			{
				g_bFriendLyFire = GetConVarBool(g_hCvarFriendlyFire);
				g_bVipFriendLyFire = GetConVarBool(g_hCvarVipFriendlyFire);
			}
			else
			{
				g_bFriendLyFire = false;
				g_bVipFriendLyFire = false;
			}
			Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bFriendlyFireActiv);
		}
		if (g_hCvarVipFriendlyFire == convar)
		{
			g_bVipFriendLyFire = GetConVarBool(convar);
			Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bVipFriendLyFire);
		}
	}
	return 0;
}

public Regeneration_Init()
{
	g_hConVarRegenerationTimerStart = CreateConVar("vip_users_regeneration_timer_start", "6.3", "Через сколько секундах начнется регенерация. Формат: (секунда.миллисекунды)", 262144, true, 0.0, true, 20.0);
	HookConVarChange(g_hConVarRegenerationTimerStart, RegenerationSettingsChanged);
	g_hConVarRegenerationTimerRegen = CreateConVar("vip_users_regeneration_timer_regen", "0.2", "В секундах интервал регена +RegenHP. Формат: (секунда.миллисекунды)", 262144, true, 0.0, true, 20.0);
	HookConVarChange(g_hConVarRegenerationTimerRegen, RegenerationSettingsChanged);
	HookConVarChange(CreateConVar("vip_users_regeneration_regen_hp", "1", "+x HP регенарции.", 262144, true, 1.0, true, 50.0), RegenerationSettingsChanged);
	return 0;
}

public RegenerationSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	if (g_hConVarRegenerationTimerStart == convar)
	{
		g_fRegenTime[0] = GetConVarFloat(convar);
		Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, g_fRegenTime);
	}
	else
	{
		if (g_hConVarRegenerationTimerRegen == convar)
		{
			g_fRegenTime[1] = GetConVarFloat(convar);
			Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, 193096 + 4);
		}
		g_iRegenHP = GetConVarInt(convar);
		Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iRegenHP);
	}
	return 0;
}

public Player_Regeneration(client)
{
	if (g_hTimerRegeneration[client])
	{
		KillTimer(g_hTimerRegeneration[client], false);
		g_hTimerRegeneration[client] = 0;
	}
	g_hTimerRegeneration[client] = CreateTimer(g_fRegenTime[0], Timer_Regeneration, client, 0);
	return 0;
}

public Action:Timer_Regeneration(Handle:timer, any:client)
{
	g_hTimerRegeneration[client] = 0;
	new var1;
	if (g_bPlayerAlive[client] && IsClientInGame(client))
	{
		new iBuffer[2];
		new var2;
		if (g_bPlayerVip[client][17] && g_iPlayerVip[client][17])
		{
			iBuffer[1] = g_iPlayerVip[client][17];
		}
		else
		{
			iBuffer[1] = 100;
		}
		iBuffer[0] = GetPlayerHealth(client) + g_iRegenHP;
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
				g_hTimerRegeneration[client] = CreateTimer(g_fRegenTime[1], Timer_Regeneration, client, 0);
			}
		}
		else
		{
			if (iBuffer[1] < 100)
			{
				iBuffer[1] = 100;
			}
			SetPlayerHealth(client, iBuffer[1]);
			PlayerReArmor(client, iBuffer[1]);
		}
	}
	return Action:4;
}

public OnTakeDamage_Init()
{
	g_hConVarDamage = CreateConVar("vip_users_damage", "1.35", "Увеличить урон для VIP игроков с флагом '0m'", 262144, true, 1.0, true, 100.0);
	HookConVarChange(g_hConVarDamage, OnTakeDamageSettingsChanged);
	g_hConVarLowDamage = CreateConVar("vip_users_low_damage", "1.35", "Понизить урон противника для VIP игроков с флагом '0v'", 262144, true, 1.0, true, 100.0);
	HookConVarChange(g_hConVarLowDamage, OnTakeDamageSettingsChanged);
	if (g_iGame == GameType:1)
	{
		HookConVarChange(FindConVar("sv_hudhint_sound"), HudHintSoundSettingsChanged);
	}
	return 0;
}

public OnTakeDamageSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	if (g_hConVarDamage == convar)
	{
		g_fDamage = GetConVarFloat(convar);
		Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, g_fDamage);
	}
	else
	{
		if (g_hConVarLowDamage == convar)
		{
			g_fLowDamage = GetConVarFloat(convar);
			Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, g_fLowDamage);
		}
	}
	return 0;
}

public HudHintSoundSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	g_bHudHintSound = GetConVarBool(convar);
	Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bHudHintSound);
	return 0;
}

public Action:Users_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new var1;
	if (attacker > g_iMaxClients || !g_bFriendlyFireActiv)
	{
		return Action:0;
	}
	if (!attacker)
	{
		new var2;
		if (g_bPlayerVip[victim][26] && g_iPlayerVip[victim][26] && damagetype & 32)
		{
			return Action:3;
		}
		return Action:0;
	}
	new var3;
	if (g_bPlayerVip[attacker][36] && g_iPlayerVip[attacker][36] && damagetype == 64 && victim != attacker && g_iClientTeam[attacker] != g_iClientTeam[victim] && IsClientInGame(victim) && GetPlayerHealth(victim) > RoundToCeil(damage))
	{
		GetClientAbsOrigin(victim, g_fUsersFireGrenade);
		if (GetVectorDistance(damagePosition, g_fUsersFireGrenade, false) < 151)
		{
			IgniteEntity(victim, 5.0, false, 155.0, false);
		}
	}
	new var4;
	if (g_bPlayerVip[attacker][16] && g_iPlayerVip[attacker][16] && victim == attacker)
	{
		return Action:3;
	}
	if (g_bFriendLyFire)
	{
		new var5;
		if (g_bPlayerAlive[attacker] && attacker != victim && g_iClientTeam[attacker] == g_iClientTeam[victim])
		{
			new var6;
			if (g_bPlayerVip[attacker][15] && g_iPlayerVip[attacker][15])
			{
				new iBuffer[2];
				iBuffer[0] = GetPlayerHealth(victim);
				if (g_bPlayerVip[victim][17])
				{
					iBuffer[1] = g_iPlayerVip[victim][17];
				}
				else
				{
					iBuffer[1] = 100;
				}
				if (iBuffer[1] != iBuffer[0])
				{
					new var7;
					if (g_hTimerMedic[attacker][0] && g_hTimerMedic[victim][1])
					{
						TE_Start("RadioIcon");
						TE_WriteNum("m_iAttachToClient", victim);
						TE_SendToClient(attacker, 0.0);
						new i = 1;
						while (i <= g_iMaxClients)
						{
							new var8;
							if (attacker != i && victim != i && IsClientInGame(i) && IsClientObserver(i))
							{
								iBuffer[0] = GetEntData(i, g_iObserverModeOffset, 4);
								if (g_iGame != GameType:2)
								{
									iBuffer[0] = iBuffer[0] + 1;
								}
								new var9;
								if (iBuffer[0] == 3 || iBuffer[0] == 4)
								{
									iBuffer[0] = GetEntDataEnt2(i, g_iObserverTargetOffset);
									if (attacker == iBuffer[0])
									{
										UsersFadeMedic(i, 410416, 250);
									}
									if (victim == iBuffer[0])
									{
										UsersFadeMedic(i, 410432, 250);
									}
								}
							}
							i++;
						}
						UsersFadeMedic(attacker, 410448, 250);
						UsersFadeMedic(attacker, 410464, 250);
						g_fMedicProgresBarMax[attacker] = 5.0 - g_fMedic[attacker];
						g_fMedicProgresBarPos[attacker] = 0;
						g_iMedic[victim] = GetClientUserId(attacker);
						g_iMedic[attacker] = GetClientUserId(victim);
						g_hTimerMedic[attacker][0] = CreateTimer(0.09, Timer_Medic, attacker, 1);
						g_hTimerMedic[victim][1] = CreateTimer(0.009, Timer_ClientHealthRecovery, victim, 1);
					}
					else
					{
						if (IsClientInGame(attacker))
						{
							if (iBuffer[1] > iBuffer[0])
							{
								iBuffer[0] = iBuffer[0] + 5;
								if (iBuffer[1] < iBuffer[0])
								{
									iBuffer[0] = iBuffer[0] + -4;
								}
								SetPlayerHealth(victim, iBuffer[0]);
							}
							OnMedicWarn(attacker, g_hTimerMedic[victim][1] != 0);
						}
					}
				}
				else
				{
					new var10;
					if (g_hTimerMedic[attacker][0] && IsClientInGame(attacker))
					{
						OnMedicWarn(attacker, g_hTimerMedic[victim][1] != 0);
					}
				}
				return Action:3;
			}
			new var11;
			if (g_hTimerMedic[victim][1] && IsClientInGame(attacker))
			{
				OnMedicWarn(attacker, true);
				return Action:3;
			}
		}
		if (g_bPlayerVip[attacker][10])
		{
			new var12;
			if (g_bPlayerVip[victim][10] && g_iPlayerVip[victim][10] >= 1 && victim != attacker && g_iClientTeam[victim] == g_iClientTeam[attacker])
			{
				return Action:3;
			}
			new var13;
			if (g_iPlayerVip[attacker][10] == 2 && victim != attacker && g_iClientTeam[victim] == g_iClientTeam[attacker])
			{
				return Action:3;
			}
		}
		else
		{
			new var14;
			if (g_bPlayerVip[victim][10] && g_iPlayerVip[victim][10] >= 1 && attacker != victim && g_iClientTeam[attacker] == g_iClientTeam[victim])
			{
				return Action:3;
			}
		}
		new var16;
		if (g_bVipFriendLyFire && g_iClientTeam[attacker] == g_iClientTeam[victim] && (!g_iPlayerVip[attacker][10] || !g_iPlayerVip[attacker][15]))
		{
			return Action:3;
		}
	}
	new var17;
	if (g_bPlayerVip[victim][22] && g_iPlayerVip[victim][22])
	{
		new var18;
		if (g_bPlayerVip[attacker][13] && g_iPlayerVip[attacker][13])
		{
			if (g_fDamage != g_fLowDamage)
			{
				damage = damage / g_fLowDamage;
				return Action:1;
			}
		}
		damage = damage / g_fLowDamage;
		return Action:1;
	}
	else
	{
		new var19;
		if (g_bPlayerVip[attacker][13] && g_iPlayerVip[attacker][13])
		{
			damage = damage * g_fDamage;
			return Action:1;
		}
	}
	return Action:0;
}

public OnMedicWarn(client, bool:health)
{
	new iBuffer;
	if (health)
	{
		new iHealth = GetPlayerHealth(client);
		if (g_bPlayerVip[client][17])
		{
			iBuffer = g_iPlayerVip[client][17];
		}
		else
		{
			iBuffer = 100;
		}
		if (iHealth < iBuffer)
		{
			iHealth += 5;
			if (iHealth > iBuffer)
			{
				iHealth += -4;
			}
			SetPlayerHealth(client, iHealth);
		}
	}
	UsersFadeMedic(client, 410480, 75);
	if (g_bMedicWarnSound)
	{
		EmitSoundToClient(client, "ambient/weather/rain_drip4.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (client != i && IsClientInGame(i) && IsClientObserver(i))
		{
			iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
			if (g_iGame != GameType:2)
			{
				iBuffer += 1;
			}
			new var2;
			if (iBuffer == 3 || iBuffer == 4)
			{
				iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
				if (client == iBuffer)
				{
					UsersFadeMedic(i, 410528, 75);
					if (g_bMedicWarnSound)
					{
						EmitSoundToClient(i, "ambient/weather/rain_drip4.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
				}
			}
		}
		i++;
	}
	return 0;
}

public Action:Timer_Medic(Handle:timer, any:attacker)
{
	new var1;
	if (g_bPlayerAlive[attacker] && IsClientInGame(attacker))
	{
		new var5 = g_fMedicProgresBarPos[attacker];
		var5 = var5[0.12101];
		if (ShowBarDone(attacker, g_fMedicProgresBarPos[attacker], g_fMedicProgresBarMax[attacker]))
		{
			new iBuffer = GetPlayerHealth(attacker) + 15;
			new var2;
			if (g_bPlayerVip[attacker][17] && g_iPlayerVip[attacker][17])
			{
				if (g_iPlayerVip[attacker][17] <= iBuffer)
				{
					SetPlayerHealth(attacker, g_iPlayerVip[attacker][17]);
					PlayerReArmor(attacker, g_iPlayerVip[attacker][17]);
				}
				else
				{
					SetPlayerHealth(attacker, iBuffer);
					iBuffer = GetPlayerArmor(attacker) + 15;
					if (g_iPlayerVip[attacker][17] <= iBuffer)
					{
						PlayerReArmor(attacker, g_iPlayerVip[attacker][17]);
					}
					PlayerReArmor(attacker, iBuffer);
				}
			}
			else
			{
				if (iBuffer >= 100)
				{
					SetPlayerHealth(attacker, 100);
					PlayerReArmor(attacker, 100);
				}
				SetPlayerHealth(attacker, iBuffer);
				iBuffer = GetPlayerArmor(attacker) + 15;
				if (iBuffer >= 100)
				{
					PlayerReArmor(attacker, 100);
				}
				PlayerReArmor(attacker, iBuffer);
			}
			new i = 1;
			while (i <= g_iMaxClients)
			{
				new var3;
				if (attacker != i && IsClientInGame(i) && IsClientObserver(i))
				{
					iBuffer = GetEntData(i, g_iObserverModeOffset, 4);
					if (g_iGame != GameType:2)
					{
						iBuffer += 1;
					}
					new var4;
					if (iBuffer == 3 || iBuffer == 4)
					{
						iBuffer = GetEntDataEnt2(i, g_iObserverTargetOffset);
						if (attacker == iBuffer)
						{
							VipPrint(i, enSound:0, "Заряд медика готов к использованию!");
							PrintHintText(i, "Заряд медика готов к использованию!");
							if (g_bMedicSuccesSound)
							{
								EmitSoundToClient(i, "buttons/button9.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							}
						}
					}
				}
				i++;
			}
			VipPrint(attacker, enSound:0, "Заряд медика готов к использованию!");
			PrintHintText(attacker, "Заряд медика готов к использованию!");
			if (g_bMedicSuccesSound)
			{
				EmitSoundToClient(attacker, "buttons/button9.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			g_fMedicProgresBarPos[attacker] = 0;
			g_fMedicProgresBarMax[attacker] = 0;
		}
		return Action:0;
	}
	g_hTimerMedic[attacker][0] = MissingTAG:0;
	return Action:4;
}

public ShowBarDone(client, Float:energe, Float:max)
{
	new i;
	new iBuffer;
	new Float:fNum = energe / max * 100.0;
	decl String:sBuffer[32];
	if (fNum > 100.0)
	{
		fNum = 100.0;
	}
	if (fNum < 0.0)
	{
		fNum = 0.0;
	}
	iBuffer = RoundFloat(fNum * 0.25);
	i = 0;
	while (i < iBuffer)
	{
		sBuffer[i] = MissingTAG:35;
		i++;
	}
	while (i < 25)
	{
		sBuffer[i] = MissingTAG:61;
		i++;
	}
	iBuffer = RoundFloat(fNum);
	new j = 1;
	while (j <= g_iMaxClients)
	{
		new var1;
		if (client != j && IsClientInGame(j) && IsClientObserver(j))
		{
			i = GetEntData(j, g_iObserverModeOffset, 4);
			if (g_iGame != GameType:2)
			{
				i += 1;
			}
			new var2;
			if (i == 3 || i == 4)
			{
				i = GetEntDataEnt2(j, g_iObserverTargetOffset);
				if (client == i)
				{
					PrintHintText(j, "Заряд медика: %i%%\n[%s]", iBuffer, sBuffer);
					new var3;
					if (g_iGame == GameType:1 && g_bHudHintSound && IsSoundPrecached("ui/hint.wav"))
					{
						StopSound(j, 6, "ui/hint.wav");
					}
				}
			}
		}
		j++;
	}
	PrintHintText(client, "Заряд медика: %i%%\n[%s]", iBuffer, sBuffer);
	new var4;
	if (g_iGame == GameType:1 && g_bHudHintSound && IsSoundPrecached("ui/hint.wav"))
	{
		StopSound(client, 6, "ui/hint.wav");
	}
	strcopy(sBuffer, 31, NULL_STRING);
	return iBuffer == 100;
}

public Action:Timer_ClientHealthRecovery(Handle:timer, any:victim)
{
	new var1;
	if (g_bPlayerAlive[victim] && IsClientInGame(victim))
	{
		new iBuffer[2];
		iBuffer[0] = GetPlayerHealth(victim);
		if (g_bPlayerVip[victim][17])
		{
			iBuffer[1] = g_iPlayerVip[victim][17];
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
				iBuffer[1] = GetClientOfUserId(g_iMedic[victim]);
				g_iMedic[victim] = 0;
				new var2 = g_fMedic[iBuffer[1]];
				var2 = var2[0.5];
				if (g_fMedic[iBuffer[1]] > 4.5)
				{
					g_fMedic[iBuffer[1]] = 1083179008;
				}
			}
			SetPlayerHealth(victim, iBuffer[0]);
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
	Format(sBuffer, 100, "Повреждений по команде: [Настройки]");
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "Повреждения по команде: [Включить]");
	AddMenuItem(hMenu, "enable", sBuffer, 0);
	if (g_iPlayerVip[client][10] == 1)
	{
		Format(sBuffer, 100, "Блокировать повреждения от своих: [X]");
		AddMenuItem(hMenu, "fire", sBuffer, 1);
		Format(sBuffer, 100, "Блокировать все повреждения: [ ]");
		AddMenuItem(hMenu, "fire", sBuffer, 0);
	}
	else
	{
		if (g_iPlayerVip[client][10] == 2)
		{
			Format(sBuffer, 100, "Блокировать повреждения от своих: [ ]");
			AddMenuItem(hMenu, "fire", sBuffer, 0);
			Format(sBuffer, 100, "Блокировать все повреждения: [X]");
			AddMenuItem(hMenu, "fire", sBuffer, 1);
		}
		Format(sBuffer, 100, "Блокировать повреждения от своих: [Недоступно!]");
		AddMenuItem(hMenu, "", sBuffer, 1);
		Format(sBuffer, 100, "Блокировать все повреждения: [Недоступно!]");
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
			if (strcmp(sInfo, "enable", false))
			{
				if (!(strcmp(sInfo, "fire", false)))
				{
					if (g_iPlayerVip[client][10] == 2)
					{
						g_iPlayerVip[client][10] = 1;
						VipPrint(client, enSound:0, "Блокировать повреждения от своих: [Включено]");
					}
					else
					{
						g_iPlayerVip[client][10] = 2;
						VipPrint(client, enSound:0, "Блокировать все повреждения: [Включено]");
					}
					Display_NoFriendLyFire(client);
				}
			}
			else
			{
				g_iPlayerVip[client][10] = 0;
				VipPrint(client, enSound:0, "Повреждения по команде: [Включены]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
	}
	return 0;
}

public InfiniteAmmo_Init()
{
	g_hWeaponAmmoTrie = CreateTrie();
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_ak47", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_awp", any:40, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_g3sg1", any:110, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_famas", any:115, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_m4a1", any:120, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_aug", any:120, true);
	if (g_iGame == GameType:3)
	{
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_galilar", any:125, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_nova", any:40, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_m4a1_silencer", any:60, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_bizon", any:184, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_mag7", any:37, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_negev", any:350, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_sawedoff", any:39, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_tec9", any:152, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_hkp2000", any:65, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_mp7", any:150, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_mp9", any:150, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_p250", any:65, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_scar20", any:110, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_sg556", any:120, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_ssg08", any:100, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_usp_silencer", any:36, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_cz75a", any:24, true);
	}
	else
	{
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_scout", any:100, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_sg552", any:120, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_sg550", any:120, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_tmp", any:150, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_mp5navy", any:150, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_p228", any:65, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_galil", any:125, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_m3", any:40, true);
		SetTrieValue(g_hWeaponAmmoTrie, "weapon_usp", any:112, true);
	}
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_xm1014", any:39, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_mac10", any:130, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_ump45", any:125, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_p90", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_m249", any:300, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_glock", any:140, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_deagle", any:42, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_elite", any:150, true);
	SetTrieValue(g_hWeaponAmmoTrie, "weapon_fiveseven", any:120, true);
	return 0;
}

public Player_WeaponReload(client)
{
	decl String:sBuffer[32];
	new iBuffer[3];
	iBuffer[0] = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	if (IsValidEntity(iBuffer[0]))
	{
		if (g_iGame == GameType:3)
		{
			iBuffer[1] = GetEntProp(iBuffer[0], PropType:0, "m_iItemDefinitionIndex", 4, 0);
			if (iBuffer[1] == 60)
			{
				strcopy(sBuffer, 32, "weapon_m4a1_silencer");
			}
			else
			{
				if (iBuffer[1] == 61)
				{
					strcopy(sBuffer, 32, "weapon_usp_silencer");
				}
				if (iBuffer[1] == 63)
				{
					strcopy(sBuffer, 32, "weapon_cz75a");
				}
				GetEntityClassname(iBuffer[0], sBuffer, 32);
			}
		}
		else
		{
			GetEntityClassname(iBuffer[0], sBuffer, 32);
		}
		if (GetTrieValue(g_hWeaponAmmoTrie, sBuffer, iBuffer[1]))
		{
			iBuffer[2] = GetEntData(iBuffer[0], g_iClip1Offset, 4);
			if (0 < iBuffer[2])
			{
				iBuffer[1] -= iBuffer[2];
			}
			iBuffer[2] = GetEntData(iBuffer[0], g_iPrimaryAmmoTypeOffset, 4);
			SetEntData(client, iBuffer[2] * 4 + g_iAmmoOffset, iBuffer[1], 4, true);
		}
	}
	return 0;
}

public SpawnWeapon_Init()
{
	g_hUsersWeaponArrayPistols = CreateArray(32, 0);
	PushArrayString(g_hUsersWeaponArrayPistols, "weapon_glock");
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_hkp2000");
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_p250");
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_usp_silencer");
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_cz75a");
	}
	else
	{
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_usp");
		PushArrayString(g_hUsersWeaponArrayPistols, "weapon_p228");
	}
	PushArrayString(g_hUsersWeaponArrayPistols, "weapon_deagle");
	PushArrayString(g_hUsersWeaponArrayPistols, "weapon_elite");
	PushArrayString(g_hUsersWeaponArrayPistols, "weapon_fiveseven");
	g_iUsersWeaponArrayPistols = GetArraySize(g_hUsersWeaponArrayPistols);
	g_hUsersWeaponArrayPrimary = CreateArray(32, 0);
	g_hUsersWeaponArrayRifles = CreateArray(64, 0);
	PushArrayString(g_hUsersWeaponArrayRifles, "weapon_ak47");
	PushArrayString(g_hUsersWeaponArrayRifles, "weapon_m4a1");
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArrayRifles, "weapon_m4a1_silencer");
		PushArrayString(g_hUsersWeaponArrayRifles, "weapon_sg556");
		PushArrayString(g_hUsersWeaponArrayRifles, "weapon_galilar");
	}
	else
	{
		PushArrayString(g_hUsersWeaponArrayRifles, "weapon_sg552");
		PushArrayString(g_hUsersWeaponArrayRifles, "weapon_galil");
	}
	PushArrayString(g_hUsersWeaponArrayRifles, "weapon_aug");
	PushArrayString(g_hUsersWeaponArrayRifles, "weapon_famas");
	g_iUsersWeaponArrayRifles = GetArraySize(g_hUsersWeaponArrayRifles);
	SetUsersWeaponArrayPrimary_Item(g_hUsersWeaponArrayRifles, g_iUsersWeaponArrayRifles);
	g_hUsersWeaponArraySniper = CreateArray(32, 0);
	PushArrayString(g_hUsersWeaponArraySniper, "weapon_awp");
	PushArrayString(g_hUsersWeaponArraySniper, "weapon_g3sg1");
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArraySniper, "weapon_ssg08");
		PushArrayString(g_hUsersWeaponArraySniper, "weapon_scar20");
	}
	else
	{
		PushArrayString(g_hUsersWeaponArraySniper, "weapon_sg550");
		PushArrayString(g_hUsersWeaponArraySniper, "weapon_scout");
	}
	g_iUsersWeaponArraySniper = GetArraySize(g_hUsersWeaponArraySniper);
	SetUsersWeaponArrayPrimary_Item(g_hUsersWeaponArraySniper, g_iUsersWeaponArraySniper);
	g_hUsersWeaponArraySemiGun = CreateArray(64, 0);
	PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_mac10");
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_mp7");
		PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_bizon");
	}
	else
	{
		PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_mp5navy");
		PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_tmp");
	}
	PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_ump45");
	PushArrayString(g_hUsersWeaponArraySemiGun, "weapon_p90");
	g_iUsersWeaponArraySemiGun = GetArraySize(g_hUsersWeaponArraySemiGun);
	SetUsersWeaponArrayPrimary_Item(g_hUsersWeaponArraySemiGun, g_iUsersWeaponArraySemiGun);
	g_hUsersWeaponArrayMachineGun = CreateArray(32, 0);
	PushArrayString(g_hUsersWeaponArrayMachineGun, "weapon_m249");
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArrayMachineGun, "weapon_negev");
	}
	g_iUsersWeaponArrayMachineGun = GetArraySize(g_hUsersWeaponArrayMachineGun);
	SetUsersWeaponArrayPrimary_Item(g_hUsersWeaponArrayMachineGun, g_iUsersWeaponArrayMachineGun);
	g_hUsersWeaponArrayShotGun = CreateArray(64, 0);
	if (g_iGame == GameType:3)
	{
		PushArrayString(g_hUsersWeaponArrayShotGun, "weapon_nova");
		PushArrayString(g_hUsersWeaponArrayShotGun, "weapon_sawedoff");
	}
	else
	{
		PushArrayString(g_hUsersWeaponArrayShotGun, "weapon_m3");
	}
	PushArrayString(g_hUsersWeaponArrayShotGun, "weapon_xm1014");
	g_iUsersWeaponArrayShotGun = GetArraySize(g_hUsersWeaponArrayShotGun);
	SetUsersWeaponArrayPrimary_Item(g_hUsersWeaponArrayShotGun, g_iUsersWeaponArrayShotGun);
	g_hUsersWeaponMaxHeGrenade = CreateConVar("vip_users_max_hegrenade", "1", "Максимальная число гранат hegrenade.", 262144, true, 0.0, true, 100.0);
	HookConVarChange(g_hUsersWeaponMaxHeGrenade, OnSettingsChanged);
	g_hUsersWeaponMaxFlashBang = CreateConVar("vip_users_max_flashbang", "2", "Максимальная число гранат flashbang.", 262144, true, 0.0, true, 100.0);
	HookConVarChange(g_hUsersWeaponMaxFlashBang, OnSettingsChanged);
	g_hUsersWeaponMaxSmokeGrenade = CreateConVar("vip_users_max_smokegrenade", "1", "Максимальная число гранат smokegrenade.", 262144, true, 0.0, true, 100.0);
	HookConVarChange(g_hUsersWeaponMaxSmokeGrenade, OnSettingsChanged);
	return 0;
}

public SetUsersWeaponArrayPrimary_Item(Handle:buffer, items)
{
	decl String:sWeapon[20];
	new i;
	while (i < items)
	{
		GetArrayString(buffer, i, sWeapon, 17);
		PushArrayString(g_hUsersWeaponArrayPrimary, sWeapon);
		i++;
	}
	return 0;
}

public PlayerSpawn_Weapon(client, team)
{
	new iBuffer;
	if (team == 2)
	{
		if (g_bUsersWeaponPrimaryT[client])
		{
			GivePlayerItem_Weapon(client, 0, g_sUsersWeaponPrimaryT[client], team);
		}
		if (g_bUsersWeaponSecondaryT[client])
		{
			GivePlayerItem_Weapon(client, 1, g_sUsersWeaponSecondaryT[client], team);
		}
	}
	else
	{
		if (team == 3)
		{
			if (g_bUsersWeaponPrimaryCT[client])
			{
				GivePlayerItem_Weapon(client, 0, g_sUsersWeaponPrimaryCT[client], team);
			}
			if (g_bUsersWeaponSecondaryCT[client])
			{
				GivePlayerItem_Weapon(client, 1, g_sUsersWeaponSecondaryCT[client], team);
			}
			new var1;
			if (g_bIsDeMap && g_bUsersWeaponDefuser[client] && !GetPlayerDefuser(client))
			{
				SetPlayerDefuser(client);
			}
		}
	}
	if (g_bUsersWeaponKnife[client])
	{
		iBuffer = GetPlayerWeaponSlot(client, 2);
		new var2;
		if (iBuffer < g_iMaxClients && OnWeaponRestrictImmune(client, team, WeaponID:28))
		{
			iBuffer = GivePlayerItem(client, "weapon_knife", 0);
		}
		new var3;
		if (g_bPlayerVip[client][32] && iBuffer > g_iMaxClients)
		{
			SetUsersWeaponColors(client, iBuffer);
		}
	}
	new var4;
	if (g_bUsersWeaponVestHelm[client] && OnWeaponRestrictImmune(client, team, WeaponID:32))
	{
		iBuffer = GetPlayerArmor(client);
		if (iBuffer)
		{
			if (iBuffer != 100)
			{
				SetPlayerArmor(client, 100);
			}
		}
		GivePlayerItem(client, "item_assaultsuit", 0);
	}
	if (g_bUsersWeaponGrenades[client])
	{
		new var5;
		if (g_iUsersWeaponHeGrenade[client] && OnWeaponRestrictImmune(client, team, WeaponID:4))
		{
			iBuffer = GetPlayerGrenade(client, 11);
			if (iBuffer)
			{
				if (g_iUsersWeaponHeGrenade[client] != iBuffer)
				{
					SetPlayerGrenade(client, 11, g_iUsersWeaponHeGrenade[client]);
				}
			}
			GivePlayerItem(client, "weapon_hegrenade", 0);
			iBuffer = g_iUsersWeaponHeGrenade[client];
			if (iBuffer != 1)
			{
				SetPlayerGrenade(client, 11, iBuffer);
			}
		}
		new var6;
		if (g_iUsersWeaponFlashBang[client] && OnWeaponRestrictImmune(client, team, WeaponID:24))
		{
			iBuffer = GetPlayerGrenade(client, 12);
			if (iBuffer)
			{
				if (g_iUsersWeaponFlashBang[client] != iBuffer)
				{
					SetPlayerGrenade(client, 12, g_iUsersWeaponFlashBang[client]);
				}
			}
			GivePlayerItem(client, "weapon_flashbang", 0);
			iBuffer = g_iUsersWeaponFlashBang[client];
			if (iBuffer != 1)
			{
				SetPlayerGrenade(client, 12, iBuffer);
			}
		}
		new var7;
		if (g_iUsersWeaponSmokeGrenade[client] && OnWeaponRestrictImmune(client, team, WeaponID:9))
		{
			iBuffer = GetPlayerGrenade(client, 13);
			if (iBuffer)
			{
				if (g_iUsersWeaponSmokeGrenade[client] != iBuffer)
				{
					SetPlayerGrenade(client, 13, g_iUsersWeaponSmokeGrenade[client]);
				}
			}
			GivePlayerItem(client, "weapon_smokegrenade", 0);
			iBuffer = g_iUsersWeaponSmokeGrenade[client];
			if (iBuffer != 1)
			{
				SetPlayerGrenade(client, 13, iBuffer);
			}
		}
	}
	new var8;
	if (g_bUsersWeaponNvgs[client] && !GetPlayerNightVision(client) && OnWeaponRestrictImmune(client, team, WeaponID:33))
	{
		SetPlayerNightVision(client);
	}
	return 0;
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	new var1;
	if (g_bGiveWeapons && g_bUsersVip[client] && g_bPlayerVip[client][5] && g_bPlayerAlive[client])
	{
		decl String:sBuffer[20];
		if (GetEdictClassname(weaponIndex, sBuffer, 17))
		{
			if (g_iClientTeam[client] == 2)
			{
				new var2;
				if (g_bUsersWeaponSecondaryT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
				{
					g_bUsersWeaponSecondaryPlayerDies[client] = 1;
				}
				else
				{
					new var3;
					if (g_bUsersWeaponPrimaryT[client] && FindStringInArray(g_hUsersWeaponArrayPrimary, sBuffer) != -1)
					{
						g_bUsersWeaponPrimaryPlayerDies[client] = 1;
					}
				}
			}
			if (g_iClientTeam[client] == 3)
			{
				new var4;
				if (g_bUsersWeaponSecondaryCT[client] && FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
				{
					g_bUsersWeaponSecondaryPlayerDies[client] = 1;
				}
			}
		}
	}
	return Action:0;
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	new var1;
	if (g_bGiveWeapons && !g_bIgnoreRoundWinConditions)
	{
		if (g_hUsersWeaponTimerItem)
		{
			KillTimer(g_hUsersWeaponTimerItem, false);
			g_hUsersWeaponTimerItem = MissingTAG:0;
		}
		if (reason == 15)
		{
			new i = 1;
			while (i <= MaxClients)
			{
				g_bUsersWeaponPrimaryPlayerDies[i] = 1;
				g_bUsersWeaponSecondaryPlayerDies[i] = 1;
				g_bUsersGiveWeaponsItemPickUp[i] = 0;
				i++;
			}
		}
		new Float:fBuffer = delay - 0.09;
		if (fBuffer > 0.05)
		{
			g_hUsersWeaponTimerItem = CreateTimer(fBuffer, Timer_OnTerminateRound, any:0, 0);
		}
		else
		{
			ResetUsersGiveWeaponsItemPickUp();
		}
	}
	return Action:0;
}

public Action:Timer_OnTerminateRound(Handle:timer)
{
	g_hUsersWeaponTimerItem = MissingTAG:0;
	ResetUsersGiveWeaponsItemPickUp();
	return Action:4;
}

public ResetUsersGiveWeaponsItemPickUp()
{
	new i = 1;
	while (i <= g_iMaxClients)
	{
		g_bUsersGiveWeaponsItemPickUp[i] = 0;
		i++;
	}
	return 0;
}

public GivePlayerItem_Weapon(client, slot, String:buffer[], team)
{
	decl String:sBuffer[20];
	new iBuffer = GetPlayerWeaponSlot(client, slot);
	if (iBuffer == -1)
	{
		if (OnWeaponRestrictImmune(client, team, GetWeaponID(buffer)))
		{
			iBuffer = GivePlayerItem(client, buffer, 0);
		}
	}
	else
	{
		if (GetEdictClassname(iBuffer, sBuffer, 17))
		{
			if (slot)
			{
				if (slot == 1)
				{
					new var2;
					if (g_bUsersWeaponSecondaryPlayerDies[client] && strcmp(buffer, sBuffer, false))
					{
						if (OnWeaponRestrictImmune(client, team, GetWeaponID(buffer)))
						{
							if (RemovePlayerItem(client, iBuffer))
							{
								RemoveEdict(iBuffer);
								iBuffer = GivePlayerItem(client, buffer, 0);
							}
						}
						g_bUsersWeaponSecondaryPlayerDies[client] = 0;
					}
				}
			}
			new var1;
			if (g_bUsersWeaponPrimaryPlayerDies[client] && strcmp(buffer, sBuffer, false))
			{
				if (OnWeaponRestrictImmune(client, team, GetWeaponID(buffer)))
				{
					if (RemovePlayerItem(client, iBuffer))
					{
						RemoveEdict(iBuffer);
						iBuffer = GivePlayerItem(client, buffer, 0);
					}
				}
				g_bUsersWeaponPrimaryPlayerDies[client] = 0;
			}
		}
	}
	return 0;
}

public bool:OnWeaponRestrictImmune(client, team, WeaponID:id)
{
	if (g_bWeaponRestrictImmune)
	{
		new var2;
		return !g_bWeaponRestrict[id] || (g_bWeaponRestrictLoaded && Restrict_CanPickupWeapon(client, team, id, false));
	}
	return !g_bWeaponRestrict[id];
}

public Display_WeaponSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponSettings, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Aвтoмaтичecкaя ycтaнoвкa opужия: [Hacтpoйкa]");
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 128, "Bce установки: [Выключить]", client);
	AddMenuItem(hMenu, "disable", sBuffer, 0);
	if (g_bUsersWeaponSecondaryT[client])
	{
		Format(sBuffer, 128, "Пистолет T: [%s]", g_sUsersWeaponSecondaryT[client][1]);
		AddMenuItem(hMenu, "pt", sBuffer, 0);
	}
	else
	{
		AddMenuItem(hMenu, "pt", "Пистолет T: [Oтключён]", 0);
	}
	if (g_bUsersWeaponSecondaryCT[client])
	{
		Format(sBuffer, 128, "Пистолет CT: [%s]", g_sUsersWeaponSecondaryCT[client][1]);
		AddMenuItem(hMenu, "pct", sBuffer, 0);
	}
	else
	{
		AddMenuItem(hMenu, "pct", "Пистолет CT: [Oтключён]", 0);
	}
	if (g_bUsersWeaponPrimaryT[client])
	{
		Format(sBuffer, 128, "Aвтoмaты-Дpoбoвики T: [%s]", g_sUsersWeaponPrimaryT[client][1]);
		AddMenuItem(hMenu, "msgt", sBuffer, 0);
	}
	else
	{
		AddMenuItem(hMenu, "msgt", "Aвтoмaты-Дpoбoвики T: [Oтключёны]", 0);
	}
	if (g_bUsersWeaponPrimaryCT[client])
	{
		Format(sBuffer, 128, "Автоматы-Дробовики CT: [%s]", g_sUsersWeaponPrimaryCT[client][1]);
		AddMenuItem(hMenu, "msgct", sBuffer, 0);
	}
	else
	{
		AddMenuItem(hMenu, "msgct", "Aвтoмaты-Дpoбoвики CT: [Oтключёны]", 0);
	}
	new var1;
	if (OnWeaponRestrictImmune(client, 2, WeaponID:28) || OnWeaponRestrictImmune(client, 3, WeaponID:28))
	{
		if (g_bUsersWeaponKnife[client])
		{
			Format(sBuffer, 128, "Нoж: [Bceгдa]");
		}
		else
		{
			Format(sBuffer, 128, "Нoж: [Cтaндapт]");
		}
		AddMenuItem(hMenu, "knife", sBuffer, 0);
	}
	else
	{
		if (g_bUsersWeaponKnife[client])
		{
			Format(sBuffer, 128, "Нoж: [Bceгдa] [3aпpeщeнo]");
		}
		else
		{
			Format(sBuffer, 128, "Нoж: [Cтaндapт] [3aпpeщeнo]");
		}
		AddMenuItem(hMenu, "knife", sBuffer, 1);
	}
	AddMenuItem(hMenu, "equipment", "Cнapяжeния", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
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
			decl String:sBuffer[32];
			GetMenuItem(hMenu, param, sBuffer, 32, 0, "", 0);
			if (strcmp(sBuffer, "disable", false))
			{
				if (strcmp(sBuffer, "pt", false))
				{
					if (strcmp(sBuffer, "pct", false))
					{
						if (strcmp(sBuffer, "msgt", false))
						{
							if (strcmp(sBuffer, "msgct", false))
							{
								if (strcmp(sBuffer, "knife", false))
								{
									if (!(strcmp(sBuffer, "equipment", false)))
									{
										Display_WeaponEquipMentSettings(client);
									}
								}
								if (g_bUsersWeaponKnife[client])
								{
									g_bUsersWeaponKnife[client] = 0;
									VipPrint(client, enSound:0, "Автоматическая установка ножа: [Стандарт]");
								}
								else
								{
									g_bUsersWeaponKnife[client] = 1;
									VipPrint(client, enSound:0, "Автоматическая установка ножа: [Всегда]");
								}
								g_bSettingsChanged[client] = 1;
								Display_WeaponSettings(client);
							}
							g_iUsersWeaponTeam[client] = 3;
							Display_WeaponMachinesShotgunsSettings(client);
						}
						g_iUsersWeaponTeam[client] = 2;
						Display_WeaponMachinesShotgunsSettings(client);
					}
					g_iUsersWeaponTeam[client] = 3;
					Display_WeaponPistolsSettings(client);
				}
				g_iUsersWeaponTeam[client] = 2;
				Display_WeaponPistolsSettings(client);
			}
			else
			{
				g_iPlayerVip[client][5] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, enSound:0, "Автоматическая установка оружия: [Выключена]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
			}
		}
	}
	return 0;
}

public Display_WeaponPistolsSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponPistolsSettings, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sWeapon[32];
	if (g_iUsersWeaponTeam[client] == 2)
	{
		Format(sBuffer, 128, "Aвтoмaтичecкaя ycтaнoвкa opужия T: [Пиcтoлeты]");
		SetMenuTitle(hMenu, sBuffer);
		if (g_bUsersWeaponSecondaryT[client])
		{
			AddMenuItem(hMenu, "none", "Пиcтoлeт: [Oтключить]", 0);
		}
		else
		{
			AddMenuItem(hMenu, "skip", "< Назад: [Отмена]", 0);
		}
		new i;
		while (i < g_iUsersWeaponArrayPistols)
		{
			GetArrayString(g_hUsersWeaponArrayPistols, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponSecondaryT[client], false))
				{
					Format(sBuffer, 128, "Пистолет: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Пистолет: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponSecondaryT[client], false))
				{
					Format(sBuffer, 128, "Пистолет: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Пистолет: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
	}
	else
	{
		if (g_iUsersWeaponTeam[client] == 3)
		{
			Format(sBuffer, 128, "Aвтoмaтичecкaя ycтaнoвкa opужия CT: [Пиcтoлeты]");
			SetMenuTitle(hMenu, sBuffer);
			if (g_bUsersWeaponPrimaryCT[client])
			{
				AddMenuItem(hMenu, "none", "Пиcтoлeт: [Oтключить]", 0);
			}
			else
			{
				AddMenuItem(hMenu, "skip", "< Назад: [Отмена]", 0);
			}
			new i;
			while (i < g_iUsersWeaponArrayPistols)
			{
				GetArrayString(g_hUsersWeaponArrayPistols, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponSecondaryCT[client], false))
					{
						Format(sBuffer, 128, "Пистолет: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Пистолет: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponSecondaryCT[client], false))
					{
						Format(sBuffer, 128, "Пистолет: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Пистолет: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
		}
	}
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
				Display_WeaponSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (strcmp(sBuffer, "none", false))
			{
				if (strcmp(sBuffer, "skip", false))
				{
					if (g_iUsersWeaponTeam[client] == 2)
					{
						g_bUsersWeaponSecondaryT[client] = 1;
						strcopy(g_sUsersWeaponSecondaryT[client], 32, sBuffer);
						VipPrint(client, enSound:0, "Установлен пистолет \x04%s\x01 для команды 'Террорист'", sBuffer[1]);
					}
					else
					{
						if (g_iUsersWeaponTeam[client] == 3)
						{
							g_bUsersWeaponSecondaryCT[client] = 1;
							strcopy(g_sUsersWeaponSecondaryCT[client], 32, sBuffer);
							VipPrint(client, enSound:0, "Установлен пистолет \x04%s\x01 для команды 'Спецназ'", sBuffer[1]);
						}
					}
					g_bSettingsChanged[client] = 1;
				}
			}
			else
			{
				if (g_iUsersWeaponTeam[client] == 2)
				{
					strcopy(g_sUsersWeaponSecondaryT[client], 32, sBuffer);
					VipPrint(client, enSound:0, "Установка пистолета отключена для команды 'Террорист'");
					g_bUsersWeaponSecondaryT[client] = 0;
				}
				else
				{
					if (g_iUsersWeaponTeam[client] == 3)
					{
						strcopy(g_sUsersWeaponSecondaryCT[client], 32, sBuffer);
						VipPrint(client, enSound:0, "Установка пистолета отключена для команды 'Спецназ'");
						g_bUsersWeaponSecondaryCT[client] = 0;
					}
				}
				g_bSettingsChanged[client] = 1;
			}
			Display_WeaponSettings(client);
		}
	}
	return 0;
}

public Display_WeaponMachinesShotgunsSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponMachinesShotgunsSettings, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sWeapon[32];
	if (g_iUsersWeaponTeam[client] == 2)
	{
		Format(sBuffer, 128, "Aвтoмaтичecкaя ycтaнoвкa opужия T: [Aвтoмaты-Дpoбoвики]");
		SetMenuTitle(hMenu, sBuffer);
		if (g_bUsersWeaponPrimaryT[client])
		{
			AddMenuItem(hMenu, "none", "Aвтoмaты-Дpoбoвики: [Oтключить]", 0);
		}
		else
		{
			AddMenuItem(hMenu, "skip", "< Назад: [Отмена]", 0);
		}
		new i;
		while (i < g_iUsersWeaponArrayRifles)
		{
			GetArrayString(g_hUsersWeaponArrayRifles, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Винтовка: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Винтовка: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Винтовка: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Винтовка: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
		new i;
		while (i < g_iUsersWeaponArraySniper)
		{
			GetArrayString(g_hUsersWeaponArraySniper, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Снайперка: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Снайперка: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Снайперка: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Снайперка: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
		new i;
		while (i < g_iUsersWeaponArraySemiGun)
		{
			GetArrayString(g_hUsersWeaponArraySemiGun, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Полу-пистолет: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Полу-пистолет: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Полу-пистолет: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Полу-пистолет: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
		new i;
		while (i < g_iUsersWeaponArrayMachineGun)
		{
			GetArrayString(g_hUsersWeaponArrayMachineGun, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Пулемёт: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Пулемёт: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Пулемёт: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Пулемёт: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
		new i;
		while (i < g_iUsersWeaponArrayShotGun)
		{
			GetArrayString(g_hUsersWeaponArrayShotGun, i, sWeapon, 32);
			if (OnWeaponRestrictImmune(client, 2, GetWeaponID(sWeapon)))
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Дробовик: [%s]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 0);
				}
				else
				{
					Format(sBuffer, 128, "Дробовик: [%s] [X]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
			}
			else
			{
				if (strcmp(sWeapon, g_sUsersWeaponPrimaryT[client], false))
				{
					Format(sBuffer, 128, "Дробовик: [%s] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				Format(sBuffer, 128, "Дробовик: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
				AddMenuItem(hMenu, sWeapon, sBuffer, 1);
			}
			i++;
		}
	}
	else
	{
		if (g_iUsersWeaponTeam[client] == 3)
		{
			Format(sBuffer, 128, "Aвтoмaтичecкaя ycтaнoвкa opужия CT: [Aвтoмaты-Дpoбoвики]");
			SetMenuTitle(hMenu, sBuffer);
			if (g_bUsersWeaponPrimaryCT[client])
			{
				AddMenuItem(hMenu, "none", "Aвтoмaты-Дpoбoвики: [Oтключить]", 0);
			}
			else
			{
				AddMenuItem(hMenu, "skip", "< Назад: [Отмена]", 0);
			}
			new i;
			while (i < g_iUsersWeaponArrayRifles)
			{
				GetArrayString(g_hUsersWeaponArrayRifles, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Винтовка: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Винтовка: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Винтовка: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Винтовка: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
			new i;
			while (i < g_iUsersWeaponArraySniper)
			{
				GetArrayString(g_hUsersWeaponArraySniper, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Снайперка: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Снайперка: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Снайперка: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Снайперка: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
			new i;
			while (i < g_iUsersWeaponArraySemiGun)
			{
				GetArrayString(g_hUsersWeaponArraySemiGun, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Полу-пистолет: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Полу-пистолет: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Полу-пистолет: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Полу-пистолет: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
			new i;
			while (i < g_iUsersWeaponArrayMachineGun)
			{
				GetArrayString(g_hUsersWeaponArrayMachineGun, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Пулемёт: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Пулемёт: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Пулемёт: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Пулемёт: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
			new i;
			while (i < g_iUsersWeaponArrayShotGun)
			{
				GetArrayString(g_hUsersWeaponArrayShotGun, i, sWeapon, 32);
				if (OnWeaponRestrictImmune(client, 3, GetWeaponID(sWeapon)))
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Дробовик: [%s]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 0);
					}
					else
					{
						Format(sBuffer, 128, "Дробовик: [%s] [X]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
				}
				else
				{
					if (strcmp(sWeapon, g_sUsersWeaponPrimaryCT[client], false))
					{
						Format(sBuffer, 128, "Дробовик: [%s] [3aпpeщeнo]", sWeapon[1]);
						AddMenuItem(hMenu, sWeapon, sBuffer, 1);
					}
					Format(sBuffer, 128, "Дробовик: [%s] [X] [3aпpeщeнo]", sWeapon[1]);
					AddMenuItem(hMenu, sWeapon, sBuffer, 1);
				}
				i++;
			}
		}
	}
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
				Display_WeaponSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (strcmp(sBuffer, "none", false))
			{
				if (strcmp(sBuffer, "skip", false))
				{
					if (g_iUsersWeaponTeam[client] == 2)
					{
						g_bUsersWeaponPrimaryT[client] = 1;
						strcopy(g_sUsersWeaponPrimaryT[client], 32, sBuffer);
						VipPrint(client, enSound:0, "Установлено оружие \x04%s\x01 для команды 'Террорист'", sBuffer[1]);
					}
					else
					{
						if (g_iUsersWeaponTeam[client] == 3)
						{
							g_bUsersWeaponPrimaryCT[client] = 1;
							strcopy(g_sUsersWeaponPrimaryCT[client], 32, sBuffer);
							VipPrint(client, enSound:0, "Установлено оружие \x04%s\x01 для команды 'Спецназ'", sBuffer[1]);
						}
					}
					g_bSettingsChanged[client] = 1;
				}
			}
			else
			{
				if (g_iUsersWeaponTeam[client] == 2)
				{
					strcopy(g_sUsersWeaponPrimaryT[client], 32, sBuffer);
					VipPrint(client, enSound:0, "Установка Aвтoмaты-Дpoбoвики отключена для команды 'Террорист'");
					g_bUsersWeaponPrimaryT[client] = 0;
				}
				else
				{
					if (g_iUsersWeaponTeam[client] == 3)
					{
						strcopy(g_sUsersWeaponPrimaryCT[client], 32, sBuffer);
						VipPrint(client, enSound:0, "Установка Aвтoмaты-Дpoбoвики отключена для команды 'Спецназ'");
						g_bUsersWeaponPrimaryCT[client] = 0;
					}
				}
				g_bSettingsChanged[client] = 1;
			}
			Display_WeaponSettings(client);
		}
	}
	return 0;
}

public Display_WeaponEquipMentSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponEquipMentSettings, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Снаряжения: [Автоматическая Уcтaнoвкa]", client);
	SetMenuTitle(hMenu, sBuffer);
	if (g_bUsersWeaponGrenades[client])
	{
		Format(sBuffer, 128, "Гранаты: [Настройка]", client);
	}
	else
	{
		Format(sBuffer, 128, "Гранаты: [Выключены]", client);
	}
	AddMenuItem(hMenu, "grenades", sBuffer, 0);
	new var1;
	if (OnWeaponRestrictImmune(client, 2, WeaponID:32) || OnWeaponRestrictImmune(client, 3, WeaponID:32))
	{
		if (g_bUsersWeaponVestHelm[client])
		{
			Format(sBuffer, 128, "Бронижелет: [Включено]");
		}
		else
		{
			Format(sBuffer, 128, "Бронижелет: [Выключено]");
		}
		AddMenuItem(hMenu, "vesthelm", sBuffer, 0);
	}
	else
	{
		if (g_bUsersWeaponVestHelm[client])
		{
			Format(sBuffer, 128, "Бронижелет: [Включено] [3aпpeщeнo]");
		}
		else
		{
			Format(sBuffer, 128, "Бронижелет: [Выключено] [3aпpeщeнo]");
		}
		AddMenuItem(hMenu, "vesthelm", sBuffer, 1);
	}
	new var2;
	if (OnWeaponRestrictImmune(client, 2, WeaponID:54) || OnWeaponRestrictImmune(client, 3, WeaponID:54))
	{
		if (g_bUsersWeaponDefuser[client])
		{
			Format(sBuffer, 128, "Дефьюз КИТ: [Включено]");
		}
		else
		{
			Format(sBuffer, 128, "Дефьюз КИТ: [Выключено]");
		}
		AddMenuItem(hMenu, "defuser", sBuffer, 0);
	}
	else
	{
		if (g_bUsersWeaponDefuser[client])
		{
			Format(sBuffer, 128, "Дефьюз КИТ: [Включено] [3aпpeщeнo]");
		}
		else
		{
			Format(sBuffer, 128, "Дефьюз КИТ: [Выключено] [3aпpeщeнo]");
		}
		AddMenuItem(hMenu, "defuser", sBuffer, 1);
	}
	new var3;
	if (OnWeaponRestrictImmune(client, 2, WeaponID:33) || OnWeaponRestrictImmune(client, 3, WeaponID:33))
	{
		if (g_bUsersWeaponNvgs[client])
		{
			Format(sBuffer, 128, "Пpибop нoчнoгo видeния: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 128, "Пpибop нoчнoгo видeния: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "nvgs", sBuffer, 0);
	}
	else
	{
		if (g_bUsersWeaponNvgs[client])
		{
			Format(sBuffer, 128, "Пpибop нoчнoгo видeния: [Включено] [3aпpeщeнo]");
		}
		else
		{
			Format(sBuffer, 128, "Пpибop нoчнoгo видeния: [Выключено] [3aпpeщeнo]");
		}
		AddMenuItem(hMenu, "nvgs", sBuffer, 1);
	}
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
				Display_WeaponSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[100];
			GetMenuItem(hMenu, param, sBuffer, 100, 0, "", 0);
			if (strcmp(sBuffer, "grenades", false))
			{
				if (strcmp(sBuffer, "vesthelm", false))
				{
					if (strcmp(sBuffer, "defuser", false))
					{
						if (!(strcmp(sBuffer, "nvgs", false)))
						{
							if (g_bUsersWeaponNvgs[client])
							{
								g_bUsersWeaponNvgs[client] = 0;
								VipPrint(client, enSound:0, "Автоматическая установка прибора ночного видения: [Выключено]");
							}
							g_bUsersWeaponNvgs[client] = 1;
							VipPrint(client, enSound:0, "Автоматическая установка прибора ночного видения: [Включено]");
						}
					}
					if (g_bUsersWeaponDefuser[client])
					{
						g_bUsersWeaponDefuser[client] = 0;
						VipPrint(client, enSound:0, "Автоматическая установка щипчиков: [Выключено]");
					}
					else
					{
						g_bUsersWeaponDefuser[client] = 1;
						VipPrint(client, enSound:0, "Автоматическая установка щипчиков: [Включено]");
					}
				}
				else
				{
					if (g_bUsersWeaponVestHelm[client])
					{
						g_bUsersWeaponVestHelm[client] = 0;
						VipPrint(client, enSound:0, "Автоматическая установка Бронежилет: [Выключено]");
					}
					else
					{
						g_bUsersWeaponVestHelm[client] = 1;
						VipPrint(client, enSound:0, "Автоматическая установка Бронежилет: [Включено]");
					}
				}
				g_bSettingsChanged[client] = 1;
				Display_WeaponEquipMentSettings(client);
			}
			Display_WeaponGrenadesSettings(client);
			return 0;
		}
	}
	return 0;
}

public Display_WeaponGrenadesSettings(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_WeaponGrenadesSettings, MenuAction:514);
	decl String:sBuffer[128];
	if (g_bUsersWeaponGrenades[client])
	{
		Format(sBuffer, 128, "Гранаты: [Автоматическая Уcтaнoвкa]");
		SetMenuTitle(hMenu, sBuffer);
		AddMenuItem(hMenu, "disable", "Гранаты: [Oтключить]", 0);
	}
	else
	{
		Format(sBuffer, 128, "Гранаты: [Автоматическая Уcтaнoвкa] - [Oтключено]");
		SetMenuTitle(hMenu, sBuffer);
		AddMenuItem(hMenu, "enable", "Гранаты: [Включить]", 0);
	}
	if (g_iUsersWeaponMaxHeGrenade)
	{
		new var1;
		if (OnWeaponRestrictImmune(client, 2, WeaponID:4) || OnWeaponRestrictImmune(client, 3, WeaponID:4))
		{
			if (g_iUsersWeaponHeGrenade[client])
			{
				if (g_iUsersWeaponMaxHeGrenade == 1)
				{
					Format(sBuffer, 128, "Осколочная граната: [%i] >> [Отключить]", g_iUsersWeaponHeGrenade[client]);
				}
				else
				{
					if (g_iUsersWeaponHeGrenade[client] == g_iUsersWeaponMaxHeGrenade)
					{
						Format(sBuffer, 128, "Осколочная граната: [%i:%i] >> [Отключить]", g_iUsersWeaponHeGrenade[client], g_iUsersWeaponMaxHeGrenade);
					}
					Format(sBuffer, 128, "Осколочная граната: [%i:%i] >> [+1]", g_iUsersWeaponHeGrenade[client], g_iUsersWeaponMaxHeGrenade);
				}
			}
			else
			{
				Format(sBuffer, 128, "Осколочная граната: [Oтключeны]");
			}
			AddMenuItem(hMenu, "hg", sBuffer, 0);
		}
		else
		{
			if (g_iUsersWeaponHeGrenade[client])
			{
				if (g_iUsersWeaponMaxHeGrenade == 1)
				{
					Format(sBuffer, 128, "Осколочная граната: [%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponHeGrenade[client]);
				}
				else
				{
					if (g_iUsersWeaponHeGrenade[client] == g_iUsersWeaponMaxHeGrenade)
					{
						Format(sBuffer, 128, "Осколочная граната: [%i:%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponHeGrenade[client], g_iUsersWeaponMaxHeGrenade);
					}
					Format(sBuffer, 128, "Осколочная граната: [%i:%i] >> [+1] [3aпpeщeнo]", g_iUsersWeaponHeGrenade[client], g_iUsersWeaponMaxHeGrenade);
				}
			}
			else
			{
				Format(sBuffer, 128, "Осколочная граната: [Oтключeны] [3aпpeщeнo]");
			}
			AddMenuItem(hMenu, "hg", sBuffer, 1);
		}
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, "Осколочная граната: [Недоступно]", 1);
	}
	if (g_iUsersWeaponMaxFlashBang)
	{
		new var2;
		if (OnWeaponRestrictImmune(client, 2, WeaponID:24) || OnWeaponRestrictImmune(client, 3, WeaponID:24))
		{
			if (g_iUsersWeaponFlashBang[client])
			{
				if (g_iUsersWeaponMaxFlashBang == 1)
				{
					Format(sBuffer, 128, "Световая граната: [%i] >> [Отключить]", g_iUsersWeaponFlashBang[client]);
				}
				else
				{
					if (g_iUsersWeaponFlashBang[client] == g_iUsersWeaponMaxFlashBang)
					{
						Format(sBuffer, 128, "Световая граната: [%i:%i] >> [Отключить]", g_iUsersWeaponFlashBang[client], g_iUsersWeaponMaxFlashBang);
					}
					Format(sBuffer, 128, "Световая граната: [%i:%i] >> [+1]", g_iUsersWeaponFlashBang[client], g_iUsersWeaponMaxFlashBang);
				}
			}
			else
			{
				Format(sBuffer, 128, "Световая граната: [Oтключeны]");
			}
			AddMenuItem(hMenu, "fb", sBuffer, 0);
		}
		else
		{
			if (g_iUsersWeaponFlashBang[client])
			{
				if (g_iUsersWeaponMaxFlashBang == 1)
				{
					Format(sBuffer, 128, "Световая граната: [%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponFlashBang[client]);
				}
				else
				{
					if (g_iUsersWeaponFlashBang[client] == g_iUsersWeaponMaxFlashBang)
					{
						Format(sBuffer, 128, "Световая граната: [%i:%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponFlashBang[client], g_iUsersWeaponMaxFlashBang);
					}
					Format(sBuffer, 128, "Световая граната: [%i:%i] >> [+1] [3aпpeщeнo]", g_iUsersWeaponFlashBang[client], g_iUsersWeaponMaxFlashBang);
				}
			}
			else
			{
				Format(sBuffer, 128, "Световая граната: [Oтключeны] [3aпpeщeнo]");
			}
			AddMenuItem(hMenu, "fb", sBuffer, 1);
		}
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, "Световая граната: [Недоступно]", 1);
	}
	if (g_iUsersWeaponMaxSmokeGrenade)
	{
		new var3;
		if (OnWeaponRestrictImmune(client, 2, WeaponID:9) || OnWeaponRestrictImmune(client, 3, WeaponID:9))
		{
			if (g_iUsersWeaponSmokeGrenade[client])
			{
				if (g_iUsersWeaponMaxSmokeGrenade == 1)
				{
					Format(sBuffer, 128, "Дымовая граната: [%i] >> [Отключить]", g_iUsersWeaponSmokeGrenade[client]);
				}
				else
				{
					if (g_iUsersWeaponSmokeGrenade[client] == g_iUsersWeaponMaxSmokeGrenade)
					{
						Format(sBuffer, 128, "Дымовая граната: [%i:%i] >> [Отключить]", g_iUsersWeaponSmokeGrenade[client], g_iUsersWeaponMaxSmokeGrenade);
					}
					Format(sBuffer, 128, "Дымовая граната: [%i:%i] >> [+1]", g_iUsersWeaponSmokeGrenade[client], g_iUsersWeaponMaxSmokeGrenade);
				}
			}
			else
			{
				Format(sBuffer, 128, "Дымовая граната: [Oтключeны]");
			}
			AddMenuItem(hMenu, "sg", sBuffer, 0);
		}
		else
		{
			if (g_iUsersWeaponSmokeGrenade[client])
			{
				if (g_iUsersWeaponMaxSmokeGrenade == 1)
				{
					Format(sBuffer, 128, "Дымовая граната: [%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponSmokeGrenade[client]);
				}
				else
				{
					if (g_iUsersWeaponSmokeGrenade[client] == g_iUsersWeaponMaxSmokeGrenade)
					{
						Format(sBuffer, 128, "Дымовая граната: [%i:%i] >> [Отключить] [3aпpeщeнo]", g_iUsersWeaponSmokeGrenade[client], g_iUsersWeaponMaxSmokeGrenade);
					}
					Format(sBuffer, 128, "Дымовая граната: [%i:%i] >> [+1] [3aпpeщeнo]", g_iUsersWeaponSmokeGrenade[client], g_iUsersWeaponMaxSmokeGrenade);
				}
			}
			else
			{
				Format(sBuffer, 128, "Дымовая граната: [Oтключeны] [3aпpeщeнo]");
			}
			AddMenuItem(hMenu, "sg", sBuffer, 1);
		}
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, "Дымовая граната: [Недоступно]", 1);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_WeaponGrenadesSettings(Handle:hMenu, MenuAction:action, client, param)
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
				Display_WeaponEquipMentSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[8];
			GetMenuItem(hMenu, param, sBuffer, 8, 0, "", 0);
			if (strcmp(sBuffer, "hg", false))
			{
				if (strcmp(sBuffer, "fb", false))
				{
					if (strcmp(sBuffer, "sg", false))
					{
						if (strcmp(sBuffer, "disable", false))
						{
							if (strcmp(sBuffer, "enable", false))
							{
								Display_WeaponEquipMentSettings(client);
							}
							new var1;
							if (g_iUsersWeaponMaxHeGrenade && !g_iUsersWeaponHeGrenade[client])
							{
								g_iUsersWeaponHeGrenade[client] = 1;
							}
							new var2;
							if (g_iUsersWeaponMaxFlashBang && !g_iUsersWeaponFlashBang[client])
							{
								if (g_iUsersWeaponMaxFlashBang == 1)
								{
									g_iUsersWeaponFlashBang[client] = 1;
								}
								g_iUsersWeaponFlashBang[client] = 2;
							}
							new var3;
							if (g_iUsersWeaponMaxSmokeGrenade && !g_iUsersWeaponSmokeGrenade[client])
							{
								g_iUsersWeaponSmokeGrenade[client] = 1;
							}
							g_bUsersWeaponGrenades[client] = 1;
							VipPrint(client, enSound:0, "Автоматическая установка гранат: [Включено]");
							Display_WeaponGrenadesSettings(client);
						}
						g_bUsersWeaponGrenades[client] = 0;
						VipPrint(client, enSound:0, "Автоматическая установка гранат: [Выключено]");
						Display_WeaponGrenadesSettings(client);
					}
					if (g_iUsersWeaponMaxSmokeGrenade == g_iUsersWeaponSmokeGrenade[client])
					{
						g_iUsersWeaponSmokeGrenade[client] = 0;
					}
					else
					{
						g_iUsersWeaponSmokeGrenade[client]++;
					}
					UsersGrenadesIsOffMenu(client);
				}
				if (g_iUsersWeaponMaxFlashBang == g_iUsersWeaponFlashBang[client])
				{
					g_iUsersWeaponFlashBang[client] = 0;
				}
				else
				{
					g_iUsersWeaponFlashBang[client]++;
				}
				UsersGrenadesIsOffMenu(client);
			}
			else
			{
				if (g_iUsersWeaponMaxHeGrenade == g_iUsersWeaponHeGrenade[client])
				{
					g_iUsersWeaponHeGrenade[client] = 0;
				}
				else
				{
					g_iUsersWeaponHeGrenade[client]++;
				}
				UsersGrenadesIsOffMenu(client);
			}
		}
	}
	return 0;
}

public UsersGrenadesIsOffMenu(client)
{
	if (g_bUsersWeaponGrenades[client])
	{
		new var1;
		if (g_iUsersWeaponHeGrenade[client] && g_iUsersWeaponFlashBang[client] && g_iUsersWeaponSmokeGrenade[client])
		{
			g_bUsersWeaponGrenades[client] = 0;
			VipPrint(client, enSound:0, "Автоматическая установка гранат: [Выключено]");
		}
	}
	else
	{
		g_bUsersWeaponGrenades[client] = 1;
		VipPrint(client, enSound:0, "Автоматическая установка гранат: [Включено]");
	}
	Display_WeaponGrenadesSettings(client);
	g_bSettingsChanged[client] = 1;
	return 0;
}

public LossMiniSpeed_Init()
{
	g_hConVarUsersLossMiniSpeedTimer = CreateConVar("vip_users_loss_damage_mini_speed_timer", "0.6", "Ha cкoлькo ceкyнд ycтaнaвливaть cкopocть vip игpoкa пpи пoлучeнии ypoнa.", 262144, true, 0.1, true, 60.0);
	HookConVarChange(g_hConVarUsersLossMiniSpeedTimer, OnSettingsChanged);
	g_hConVarUsersLossMiniSpeed = CreateConVar("vip_users_loss_damage_mini_speed", "19", "Уcкopить cкopocть vip игpoкa пpи пoлучeнии ypoнa. (10%% дo 100%%)", 262144, true, 10.0, true, 100.0);
	HookConVarChange(g_hConVarUsersLossMiniSpeed, OnSettingsChanged);
	return 0;
}

public UsersLossDamageSpeed(client)
{
	if (g_hTimerUsersLossSpeed[client])
	{
		KillTimer(g_hTimerUsersLossSpeed[client], false);
		g_hTimerUsersLossSpeed[client] = 0;
		g_hTimerUsersLossSpeed[client] = CreateTimer(g_fUsersMaxSpeedTimer, Timer_UsersLossDamageSpeed, client, 0);
	}
	else
	{
		g_fUsersLossSpeed[client] = GetPlayerSpeed(client);
		new var1;
		if (g_fUsersLossSpeed[client] < g_fUsersLossSpeed[client][g_fUsersLossMiniSpeed] && g_fUsersLossSpeed[client][g_fUsersLossMiniSpeed] < 2.0)
		{
			g_hTimerUsersLossSpeed[client] = CreateTimer(g_fUsersMaxSpeedTimer, Timer_UsersLossDamageSpeed, client, 0);
			SetPlayerSpeed(client, g_fUsersLossSpeed[client][g_fUsersLossMiniSpeed]);
		}
	}
	return 0;
}

public Action:Timer_UsersLossDamageSpeed(Handle:timer, any:client)
{
	g_hTimerUsersLossSpeed[client] = 0;
	new var1;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		g_iClientTeam[client] = GetClientTeam(client);
		g_bPlayerAlive[client] = IsPlayerAlive(client);
		new var2;
		if (g_bPlayerAlive[client] && g_iClientTeam[client] > 1 && GetPlayerSpeed(client) == g_fUsersLossSpeed[client][g_fUsersLossMiniSpeed])
		{
			SetPlayerSpeed(client, g_fUsersLossSpeed[client]);
		}
	}
	g_fUsersLossSpeed[client] = 0;
	return Action:0;
}


/* ERROR! null */
 function "OnPlayerRunCmd" (number 156)
public bool:GetOnPlayerRunCmd(client)
{
	new var1;
	return g_bPlayerVip[client][11] || g_bPlayerVip[client][37] || g_bPlayerCmds[client][4] || g_bPlayerCmds[client][5];
}

public Action:Timer_MedicSpam(Handle:timer, any:client)
{
	g_hTimerMedicSpam[client] = 0;
	return Action:4;
}

public Cash_Init()
{
	g_hConVarCashMax = CreateConVar("vip_users_cash_max", "16000", "Максимальнео число денег для vip игроков с флагом '0e'.", 262144, true, 1.0, true, 16000.0);
	HookConVarChange(g_hConVarCashMax, OnSettingsChanged);
	g_hConVarCashDivisor = CreateConVar("vip_users_cash_divisor", "400", "Делитель денег для vip игроков с флагом '0e'.", 262144, true, 1.0, true, 8000.0);
	HookConVarChange(g_hConVarCashDivisor, OnSettingsChanged);
	RegConsoleCmd("vip_cash", SetCash_Command, "Установка денег: vip_cash 800", 0);
	return 0;
}

public Action:SetCash_Command(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][4])
		{
			if (g_bUsersActivate)
			{
				decl String:sBuffer[8];
				GetCmdArgString(sBuffer, 8);
				new iAmount = StringToInt(sBuffer, 10);
				new var1;
				if (args > 0 && iAmount > 0)
				{
					if (iAmount > g_iCashMax)
					{
						VipPrint(client, enSound:2, "Разрешено максиммум %i$", g_iCashMax);
					}
					else
					{
						if (iAmount != GetPlayerMoney(client))
						{
							if (iAmount > 16000)
							{
								SetPlayerMoney(client, 16000);
							}
							SetPlayerMoney(client, iAmount);
						}
						g_iPlayerVip[client][4] = iAmount;
						g_bSettingsChanged[client] = 1;
					}
				}
				else
				{
					ReplyToCommand(client, "\x04[VIP]\x01 Устанвока денег \"vip_cash %i\"", g_iCashMax);
				}
			}
			else
			{
				VipPrint(client, enSound:2, "Деньги будут доступны через %i рауда(ов).", g_iUsersActivateRounds - g_iActivateRounds + 2);
			}
		}
		VipPrint(client, enSound:2, "Вам недоступна эта команда!");
	}
	return Action:3;
}

public PlayerSpawn_Cash(client)
{
	new iMoney = GetPlayerMoney(client);
	if (g_iPlayerVip[client][4] > iMoney)
	{
		iMoney = g_iPlayerVip[client][4][iMoney];
		if (iMoney > 16000)
		{
			SetPlayerMoney(client, 16000);
		}
		SetPlayerMoney(client, iMoney);
	}
	return 0;
}

public Display_SpawnCashSettings(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnCashSettings, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Деньги при спавне: [Настройка]");
	SetMenuTitle(menu, sBuffer);
	AddMenuItem(menu, NULL_STRING, "При спавне: [Выключить]", 0);
	Format(sBuffer, 128, "При спавне: %i$ [+%i]", g_iPlayerVip[client][4], g_iCashDivisor);
	if (g_iPlayerVip[client][4] < g_iCashMax)
	{
		AddMenuItem(menu, NULL_STRING, sBuffer, 0);
	}
	else
	{
		AddMenuItem(menu, NULL_STRING, sBuffer, 1);
	}
	Format(sBuffer, 128, "При спавне: %i$ [-%i]", g_iPlayerVip[client][4], g_iCashDivisor);
	if (g_iPlayerVip[client][4] > g_iCashDivisor)
	{
		AddMenuItem(menu, NULL_STRING, sBuffer, 0);
	}
	else
	{
		AddMenuItem(menu, NULL_STRING, sBuffer, 1);
	}
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
			g_bSettingsChanged[client] = 1;
			if (!param)
			{
				g_iPlayerVip[client][4] = 0;
				VipPrint(client, enSound:0, "Деньги при спавне: [Выключено]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				return 0;
			}
			if (param == 1)
			{
				new var1 = g_iPlayerVip[client][4];
				var1 = var1[g_iCashDivisor];
			}
			else
			{
				if (param == 2)
				{
					g_iPlayerVip[client][4] -= g_iCashDivisor;
				}
			}
			Display_SpawnCashSettings(client);
		}
	}
	return 0;
}

public ChangeTeam_Init()
{
	g_hChangeTeamArray = CreateArray(32, 0);
	AddCommandListener(JoinTeam_Command, "jointeam");
	AddCommandListener(JoinClass_Command, "joinclass");
	return 0;
}

public Action:JoinTeam_Command(client, String:command[], args)
{
	new var1;
	if (client && g_bPlayerVip[client][23] && g_iPlayerVip[client][23] && args)
	{
		decl String:sBuffer[8];
		GetCmdArgString(sBuffer, 8);
		new iTeam = StringToInt(sBuffer, 10);
		g_iClientTeam[client] = GetClientTeam(client);
		new var2;
		if (iTeam > 0 && iTeam < 4 && iTeam != g_iClientTeam[client])
		{
			ChangeClientTeam(client, iTeam);
			return Action:3;
		}
	}
	return Action:0;
}

public Action:JoinClass_Command(client, String:command[], args)
{
	new var1;
	if (client && g_bPlayerVip[client][23] && g_iPlayerVip[client][23] && args)
	{
		g_bPlayerAlive[client] = IsPlayerAlive(client);
		if (!g_bPlayerAlive[client])
		{
			decl String:sBuffer[8];
			GetCmdArgString(sBuffer, 8);
			new iBuffer = StringToInt(sBuffer, 10);
			new var2;
			if (iBuffer > 0 && iBuffer < 9 && UsersChangeTeam(client))
			{
				CS_RespawnPlayer(client);
				return Action:3;
			}
		}
	}
	return Action:0;
}

public ParsFile(String:file[], Handle:hBuffer, option)
{
	new Handle:hFile = OpenFile(file, "r");
	if (hFile)
	{
		decl String:sLine[256];
		decl iBuffer;
		while (!IsEndOfFile(hFile))
		{
			if (ReadFileLine(hFile, sLine, 256))
			{
				iBuffer = StrContains(sLine, "//", true);
				if (iBuffer != -1)
				{
					sLine[iBuffer] = MissingTAG:0;
				}
				iBuffer = StrContains(sLine, "#", true);
				if (iBuffer != -1)
				{
					sLine[iBuffer] = MissingTAG:0;
				}
				iBuffer = StrContains(sLine, ";", true);
				if (iBuffer != -1)
				{
					sLine[iBuffer] = MissingTAG:0;
				}
				TrimString(sLine);
				new var2;
				if (!(sLine[0] && (sLine[0] == 'ï' && sLine[0] == '»' && sLine[0] == '¿')))
				{
					if (option == 1)
					{
						SetTrieValue(hBuffer, sLine, any:1, true);
					}
					else
					{
						if (option == 2)
						{
							if (isFileExists(sLine, false))
							{
								if (PrecacheFile(sLine, false))
								{
									AddFileToDownloadsTable(sLine);
								}
								else
								{
									Vip_ErrorLog("Файл \"%s\" не прошел кеширование", sLine);
								}
							}
							else
							{
								if (isDirExists(sLine))
								{
									new Handle:hDir = OpenDirectory(sLine);
									if (hDir)
									{
										decl String:sBuffer[256];
										decl FileType:type;
										while (ReadDirEntry(hDir, sBuffer, 256, type))
										{
											new var3;
											if (!(type == FileType:1 || strcmp(sBuffer[strlen(sBuffer) + -5], ".ztmp", false)))
											{
												Format(sBuffer, 256, "%s/%s", sLine, sBuffer);
												if (isFileExists(sBuffer, true))
												{
													if (PrecacheFile(sBuffer, false))
													{
														AddFileToDownloadsTable(sBuffer);
													}
													else
													{
														Vip_ErrorLog("Файл \"%s\" не прошел кеширование", sBuffer);
													}
												}
												else
												{
													Vip_ErrorLog("Не найден файл \"%s\"", sBuffer);
												}
											}
										}
										CloseHandle(hDir);
									}
									else
									{
										Vip_ErrorLog("Не удалось открыть папку \"%s\"", sLine);
									}
								}
								Vip_ErrorLog("Не удалось найти папку \"%s\"", sLine);
							}
						}
						new var4;
						if (option == 3 && strcmp(g_sMap, sLine, false))
						{
							g_bGiveWeapons = false;
							CloseHandle(hFile);
						}
						if (option == 4)
						{
							PushArrayString(hBuffer, sLine);
						}
						if (option == 5)
						{
							if (!LoadAdminString(sLine))
							{
								Vip_ErrorLog("[Секция: Администратор] Не удалось загрузить строку: %s", sLine);
							}
						}
						if (option == 6)
						{
							iBuffer = strlen(sLine);
							if (iBuffer > 23)
							{
								Vip_ErrorLog("[Секция: Чат чат] Максимальная длина тега 23 символа! Тег: %s длина тега = %i", sLine, iBuffer);
							}
							else
							{
								new var5;
								if (strcmp(sLine, g_sChatTag, false) && FindStringInArray(hBuffer, sLine) == -1)
								{
									Vip_ErrorLog("[Секция: Чат чат] тег %s уже присутствует в базе!", sLine);
								}
								PushArrayString(hBuffer, sLine);
							}
						}
						if (option == 7)
						{
							iBuffer = strlen(sLine);
							if (iBuffer > 23)
							{
								Vip_ErrorLog("[Секция: Клан тег] Максимальная длина тега 23 символа! Тег: %s длина тега = %i", sLine, iBuffer);
							}
							else
							{
								new var6;
								if (strcmp(sLine, g_sClanTag, false) && FindStringInArray(hBuffer, sLine) == -1)
								{
									Vip_ErrorLog("[Секция: Клан тег] тег %s уже присутствует в базе!", sLine);
								}
								PushArrayString(hBuffer, sLine);
							}
						}
						if (option == 8)
						{
							decl String:sBuffer[256];
							iBuffer = BreakString(sLine, sBuffer, 256);
							StripQuotes(sBuffer);
							g_nWeaponID = GetWeaponID(sBuffer);
							if (g_nWeaponID)
							{
								if (iBuffer == -1)
								{
									g_bWeaponRestrict[g_nWeaponID] = 1;
								}
								Format(sBuffer, 256, "/%s", sLine[iBuffer]);
								if (0 < StrContains(sBuffer, g_sMap, false))
								{
									g_bWeaponRestrict[g_nWeaponID] = 1;
								}
							}
						}
					}
				}
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		Vip_ErrorLog("Не возможно открывать файл \"%s\"!", file);
		SetFailState("Не возможно открывать файл \"%s\"!", file);
	}
	return 0;
}

public bool:PrecacheFile(String:file[], bool:preload)
{
	decl String:sBuffer[256];
	strcopy(sBuffer, 256, file[strlen(file) + -4]);
	new var1;
	if (strcmp(sBuffer, ".mdl", false) && strcmp(sBuffer, ".vmt", false))
	{
		if (!(PrecacheModel(file, preload)))
		{
			return false;
		}
	}
	else
	{
		new var2;
		if (strcmp(sBuffer, ".mp3", false) && strcmp(sBuffer, ".wav", false))
		{
			Format(sBuffer, 256, "%c%c%c%c%c%c", file, file[0], file[0], file[0], file[1], file[1]);
			new var3;
			if (strcmp(sBuffer, "sound/", false) && !PrecacheSound(file[1], preload))
			{
				return false;
			}
		}
	}
	return true;
}

public bool:isDirExists(String:dir[])
{
	if (DirExists(dir))
	{
		return true;
	}
	if (DirExists("custom"))
	{
		new Handle:hDir = OpenDirectory("custom");
		if (hDir)
		{
			decl String:sBuffer[256];
			decl FileType:type;
			while (ReadDirEntry(hDir, sBuffer, 256, type))
			{
				new var1;
				if (type == FileType:1 && strcmp(sBuffer, ".", false) && strcmp(sBuffer, "..", false))
				{
					Format(sBuffer, 256, "custom/%s/%s", sBuffer, dir);
					if (DirExists(sBuffer))
					{
						CloseHandle(hDir);
						return true;
					}
				}
			}
			CloseHandle(hDir);
		}
	}
	return false;
}

public bool:isFileExists(String:file[], bool:usevalue)
{
	if (FileExists(file, usevalue))
	{
		return true;
	}
	if (DirExists("custom"))
	{
		new Handle:hDir = OpenDirectory("custom");
		if (hDir)
		{
			decl String:sBuffer[256];
			decl FileType:type;
			while (ReadDirEntry(hDir, sBuffer, 256, type))
			{
				new var1;
				if (type == FileType:1 && strcmp(sBuffer, ".", false) && strcmp(sBuffer, "..", false))
				{
					Format(sBuffer, 256, "custom/%s/%s", sBuffer, file);
					if (FileExists(sBuffer, usevalue))
					{
						CloseHandle(hDir);
						return true;
					}
				}
			}
			CloseHandle(hDir);
		}
	}
	return false;
}

public Menu_OnPluginStart()
{
	RegConsoleCmd("vip", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vip_menu", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vipmenu", Display_MenuCmd, "VIP Menu", 0);
	RegConsoleCmd("vip_settings", Display_MenuCmd, "VIP Menu", 0);
	g_hAdvertVipAccessArray = CreateArray(32, 0);
	BuildPath(PathType:0, g_sAdvertVipAccessPath, 256, "data/vip/users_advert_vip_access.ini");
	return 0;
}

public Print_ShowUsers(client)
{
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		new var1;
		decl iBuffer;
		do {
			KvGetString(g_hKvUsers, "name", var1 + var1, 128, "none");
			new var2 = var1 + 4;
			KvGetSectionName(g_hKvUsers, var2 + var2, 128);
			new var3 = var1 + 8;
			KvGetString(g_hKvUsers, "group", var3 + var3, 128, "none");
			new var4 = var1 + 16;
			KvGetString(g_hKvUsers, "password", var4 + var4, 128, "none");
			new var5 = var1 + 8;
			if (strcmp(var5 + var5, "none", false))
			{
				new var9 = var1 + 8;
				new var10 = var1 + 8;
				Format(var10 + var10, 128, "Group: [%s]", var9 + var9);
			}
			else
			{
				new var6 = var1 + 8;
				KvGetString(g_hKvUsers, "flags", var6 + var6, 128, "none");
				new var7 = var1 + 8;
				new var8 = var1 + 8;
				Format(var8 + var8, 128, "Flags: [%s]", var7 + var7);
			}
			new var11 = var1 + 12;
			KvGetString(g_hKvUsers, "expires", var11 + var11, 128, "0");
			new var12 = var1 + 12;
			iBuffer = StringToInt(var12 + var12, 10);
			if (iBuffer)
			{
				new var13 = var1 + 12;
				FormatTime(var13 + var13, 128, "%d.%m.%Y : %H.%M.%S", iBuffer);
			}
			else
			{
				new var14 = var1 + 12;
				strcopy(var14 + var14, 128, "never");
			}
			new var15 = var1 + 12;
			new var16 = var1 + 8;
			new var17 = var1 + 16;
			new var18 = var1 + 4;
			ReplyToCommand(client, "\x04[VIP]\x01 (%s) (%s) password: [%s] %s Expires: [%s]", var1 + var1, var18 + var18, var17 + var17, var16 + var16, var15 + var15);
		} while (KvGotoNextKey(g_hKvUsers, false));
	}
	else
	{
		VipPrint(client, enSound:2, "База пуста!");
	}
	return 0;
}

public Action:Display_MenuCmd(client, args)
{
	new var1;
	if (client && IsClientInGame(client))
	{
		if (g_sUsersOnAttribute[client])
		{
			Display_Menu(client);
		}
		else
		{
			if (g_iAdvertVipAccessArray != -1)
			{
				decl String:sBuffer[128];
				new i;
				while (i <= g_iAdvertVipAccessArray)
				{
					GetArrayString(g_hAdvertVipAccessArray, i, sBuffer, 128);
					if (g_iAdvertVipAccessArray == i)
					{
						VipPrint(client, enSound:2, sBuffer);
					}
					else
					{
						VipPrint(client, enSound:0, sBuffer);
					}
					PrintToConsole(client, sBuffer);
					i++;
				}
			}
			VipPrint(client, enSound:2, "У Вас нет доступа!");
		}
	}
	else
	{
		ReplyToCommand(client, "[VIP] Available only to players!");
	}
	return Action:3;
}

public GetTimeVIPStamp(String:sBuffer[], maxlength, iTimeStamp)
{
	if (iTimeStamp > 31536000)
	{
		new years = iTimeStamp / 31536000;
		new days = iTimeStamp / 86400 % 365;
		if (0 < days)
		{
			FormatEx(sBuffer, maxlength, "%iг. %iд.", years, days);
		}
		else
		{
			FormatEx(sBuffer, maxlength, "%i%г.", years);
		}
		return 0;
	}
	if (iTimeStamp > 86400)
	{
		new days = iTimeStamp / 86400 % 365;
		new hours = iTimeStamp / 3600 % 24;
		if (0 < hours)
		{
			FormatEx(sBuffer, maxlength, "%iд. %iч.", days, hours);
		}
		else
		{
			FormatEx(sBuffer, maxlength, "%iд.", days);
		}
		return 0;
	}
	new Hours = iTimeStamp / 3600;
	new Mins = iTimeStamp / 60 % 60;
	new Secs = iTimeStamp % 60;
	if (0 < Hours)
	{
		FormatEx(sBuffer, maxlength, "%02iч:%02iм:%02iс", Hours, Mins, Secs);
	}
	else
	{
		FormatEx(sBuffer, maxlength, "%02iм:%02iс", Mins, Secs);
	}
	return 0;
}

public Display_Menu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_MenuSettings, MenuAction:514);
	decl String:sBuffer[256];
	new iBuffer = GetTime(424128);
	new var2;
	if (g_iUsersExpires[client] > iBuffer && (g_bUsersCmds[client] || g_bUsersVip[client]))
	{
		GetTimeVIPStamp(sBuffer, 256, g_iUsersExpires[client] - iBuffer);
		Format(sBuffer, 256, "Very Important Person (%s)\n - Иcтeкaeт через: %s", "beta_0.0.5", sBuffer, client);
	}
	else
	{
		Format(sBuffer, 256, "Very Important Person (%s)", "beta_0.0.5", client);
	}
	SetMenuTitle(hMenu, sBuffer);
	if (g_bUsersCmds[client])
	{
		AddMenuItem(hMenu, "playercommands", "Управление игроками", 0);
	}
	if (g_bUsersVip[client])
	{
		AddMenuItem(hMenu, "settings", "Настройки [VIP]", 0);
		if (g_bSettingsChanged[client])
		{
			AddMenuItem(hMenu, "settings_save", "Сохранить настройки [VIP]", 0);
		}
	}
	if (g_bUsersAdmin[client])
	{
		AddMenuItem(hMenu, "edit", "Управление системой [VIP]", 0);
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
			if (strcmp(sInfo, "playercommands", false))
			{
				if (strcmp(sInfo, "settings", false))
				{
					if (strcmp(sInfo, "settings_save", false))
					{
						if (!(strcmp(sInfo, "edit", false)))
						{
							if (!g_bBetaTest)
							{
								ReplyToCommand(client, "\x04[\x01VIP\x04]\x01 Да куда ты тыкаешь!? [\x040_0\x01] Я еще не проверил обновление... Подожди!");
								Display_Menu(client);
								return 0;
							}
							Display_AdminVipEdit(client);
						}
					}
					UsersSettingsSave(client);
					Display_Menu(client);
				}
				g_iUsersMenuPosition[client] = 0;
				Display_MenuSettings(client, 0);
			}
			else
			{
				Display_PlayerCommands(client);
			}
		}
	}
	return 0;
}

public Display_AdminVipEdit(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_AdminVipEdit, MenuAction:28);
	SetMenuTitle(hMenu, "Управление системой: [Very Important Person]");
	AddMenuItem(hMenu, NULL_STRING, "Добавить/Редактировать [VIP] игрока", 0);
	AddMenuItem(hMenu, NULL_STRING, "Показать [VIP] игроков", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_AdminVipEdit(Handle:hMenu, MenuAction:action, client, param)
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
			if (param)
			{
				if (param == 1)
				{
					Print_ShowUsers(client);
					Display_AdminVipEdit(client);
				}
			}
			Display_AddEdit(client);
		}
	}
	return 0;
}

public Display_AddEdit(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_VipMenuAddEdit, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "Добавить, Редактировать:", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "vip_addserv", "Добавить с сервера", 0);
	AddMenuItem(hMenu, "vip_editbase", "Редактировать из базы", 0);
	AddMenuItem(hMenu, "vip_del", "Удалить из базы", 0);
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
				if (param == -6)
				{
					Display_AdminVipEdit(client);
				}
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sInfo[32];
			GetMenuItem(hMenu, param, sInfo, 32, 0, "", 0);
			if (strcmp(sInfo, "vip_addserv", false))
			{
				if (strcmp(sInfo, "vip_editbase", false))
				{
					if (!(strcmp(sInfo, "vip_del", false)))
					{
						Display_UsersDelete(client);
					}
				}
				g_bAddBase[client] = 0;
				Display_UsersEditBase(client);
			}
			else
			{
				g_bAddBase[client] = 1;
				Display_UsersAdd(client, true);
			}
		}
	}
	return 0;
}

public Display_UsersEditBase(client)
{
	new var2;
	var2 = CreateMenu(MenuHandler_UsersEditBase, MenuAction:514);
	new var3;
	decl String:sTemp[64];
	Format(var3 + var3, 128, "Редактировать атрибуты у:", client);
	SetMenuTitle(var2, var3 + var3);
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		do {
			KvGetSectionName(g_hKvUsers, var3 + var3, 128);
			new var4 = var3 + 4;
			KvGetString(g_hKvUsers, "name", var4 + var4, 128, "none");
			new i = 1;
			while (i <= MaxClients)
			{
				new var1;
				if (!strcmp(g_sClientAuth[i], var3 + var3, false) && IsClientInGame(i) && !IsFakeClient(i) && GetClientName(i, sTemp, 64) && strcmp(var5 + var5, sTemp, false))
				{
					KvSetString(g_hKvUsers, "name", sTemp);
					new var6 = var3 + 4;
					KvGetString(g_hKvUsers, "name", var6 + var6, 128, "none");
					new var7 = var3 + 4;
					if (strcmp(var7 + var7, "none", false))
					{
						new var8 = var3 + 4;
						AddMenuItem(var2, var3 + var3, var8 + var8, 0);
					}
				}
				i++;
			}
			new var6 = var3 + 4;
			KvGetString(g_hKvUsers, "name", var6 + var6, 128, "none");
			new var7 = var3 + 4;
			if (strcmp(var7 + var7, "none", false))
			{
				new var8 = var3 + 4;
				AddMenuItem(var2, var3 + var3, var8 + var8, 0);
			}
		} while (KvGotoNextKey(g_hKvUsers, false));
		SetMenuExitBackButton(var2, true);
		DisplayMenu(var2, client, 0);
	}
	else
	{
		CloseHandle(var2);
		VipPrint(client, enSound:2, "База пуста!");
		Display_AddEdit(client);
	}
	return 0;
}

public MenuHandler_UsersEditBase(Handle:hMenu, MenuAction:action, client, param)
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
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, g_sVipFlags[client][3], 256, 0, g_sVipFlags[client][0], 256);
			new iBuffer = FindStringInArray(g_hArrayUsers, g_sVipFlags[client][3]);
			if (iBuffer != -1)
			{
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], false))
				{
					KvGetString(g_hKvUsers, "group", sBuffer, 128, "");
					if (GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer))
					{
						KvRewind(g_hKvUsersGroups);
						if (KvJumpToKey(g_hKvUsersGroups, sBuffer, false))
						{
							strcopy(g_sVipFlags[client][4], 256, sBuffer);
							KvGetString(g_hKvUsersGroups, "flags", g_sVipFlags[client][1], 256, "");
							g_iTargetTime[client] = KvGetNum(g_hKvUsers, "expires", 0);
							if (g_iTargetTime[client])
							{
								FormatTime(g_sVipFlags[client][5], 256, "%H:%M:%S %d:%m:%Y", g_iTargetTime[client]);
							}
							strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
						}
					}
					else
					{
						KvGetString(g_hKvUsers, "flags", g_sVipFlags[client][1], 256, "");
						g_iTargetTime[client] = KvGetNum(g_hKvUsers, "expires", 0);
						if (g_iTargetTime[client])
						{
							FormatTime(g_sVipFlags[client][5], 256, "%H:%M:%S %d:%m:%Y", g_iTargetTime[client]);
						}
						else
						{
							strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
						}
						strcopy(g_sVipFlags[client][4], 256, NULL_STRING);
					}
					strcopy(g_sVipFlags[client][2], 256, g_sVipFlags[client][1]);
					Display_UsersTarget(client);
					return 0;
				}
			}
			VipPrint(client, enSound:2, "Ошибка!");
			strcopy(g_sVipFlags[client][0], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][3], 256, NULL_STRING);
			Display_UsersEditBase(client);
		}
	}
	return 0;
}

public Display_UsersDelete(client)
{
	new var1;
	var1 = CreateMenu(MenuHandler_UsersDelete, MenuAction:514);
	new var2;
	Format(var2 + var2, 128, "Удалить VIP игрока:", client);
	SetMenuTitle(var1, var2 + var2);
	KvRewind(g_hKvUsers);
	if (KvGotoFirstSubKey(g_hKvUsers, false))
	{
		do {
			KvGetSectionName(g_hKvUsers, var2 + var2, 128);
			new var3 = var2 + 4;
			KvGetString(g_hKvUsers, "name", var3 + var3, 128, "unnamed");
			new var4 = var2 + 4;
			AddMenuItem(var1, var2 + var2, var4 + var4, 0);
		} while (KvGotoNextKey(g_hKvUsers, false));
		SetMenuExitBackButton(var1, true);
		DisplayMenu(var1, client, 0);
	}
	else
	{
		VipPrint(client, enSound:2, "База пуста!");
		CloseHandle(var1);
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
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var1 + var1, 128, 0, var2 + var2, 128);
			new iBuffer = FindStringInArray(g_hArrayUsers, var1 + var1);
			if (iBuffer != -1)
			{
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, var1 + var1, false))
				{
					KvDeleteThis(g_hKvUsers);
					KvRewind(g_hKvUsers);
					new var3 = g_sUsersPath;
					KeyValuesToFile(g_hKvUsers, var3[0][var3]);
					RemoveFromArray(g_hArrayUsers, iBuffer);
					RemoveFromArray(g_hArrayUsersExpires, iBuffer);
					RemoveFromArray(g_hArrayUsersPassword, iBuffer);
					g_iArrayUsers -= 1;
					DeleteUserSettings(var1 + var1);
					new var4 = var1 + 4;
					Vip_Log("Админ %N (ID: %s) успешно удалил %s (ID: %s) из VIP базы.", client, g_sClientAuth[client], var4 + var4, var1 + var1);
					new var5 = var1 + 4;
					VipPrint(client, enSound:0, "%s (ID: %s) успешно удалён из VIP базы.", var5 + var5, var1 + var1);
					ResettingTheFlags(var1 + var1);
				}
			}
			Display_AddEdit(client);
		}
	}
	return 0;
}

public Display_MenuSettings(client, position)
{
	new Handle:hMenu = CreateMenu(MenuHandler_SettingsChanged, MenuAction:514);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "Hacтpoйки: Very Important Person");
	SetMenuTitle(hMenu, sBuffer);
	if (g_bPlayerVip[client][0])
	{
		if (g_iPlayerVip[client][0])
		{
			Format(sBuffer, 100, "Чaт: [Hacтpoйкa]");
		}
		else
		{
			Format(sBuffer, 100, "Чaт: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "chat", sBuffer, 0);
	}
	if (g_bPlayerVip[client][1])
	{
		new var1;
		if (g_iArrayModelsT == -1 && g_iArrayModelsCT == -1)
		{
			Format(sBuffer, 100, "Cкин: [Heдocтyпнo!]");
			AddMenuItem(hMenu, "", sBuffer, 1);
		}
		if (g_iPlayerVip[client][1])
		{
			Format(sBuffer, 100, "Cкин: [Hacтpoйкa]");
		}
		else
		{
			Format(sBuffer, 100, "Cкин: [Bыключeн]");
		}
		AddMenuItem(hMenu, "models", sBuffer, 0);
	}
	if (g_bPlayerVip[client][2])
	{
		if (g_iPlayerVip[client][2])
		{
			Format(sBuffer, 100, "Иммунитeт: [Bключён]");
		}
		else
		{
			Format(sBuffer, 100, "Иммунитeт: [Bыключeн]");
		}
		AddMenuItem(hMenu, "immunity", sBuffer, 0);
	}
	if (g_bPlayerVip[client][31])
	{
		if (g_iPlayerVip[client][31])
		{
			Format(sBuffer, 100, "Иммунитeт oт зaпpeтa opужия: [Bключён]");
		}
		else
		{
			Format(sBuffer, 100, "Иммунитeт oт зaпpeтa opужия: [Bыключeн]");
		}
		AddMenuItem(hMenu, "weaponrestrict", sBuffer, 0);
	}
	if (g_bPlayerVip[client][3])
	{
		if (g_iPlayerVip[client][3])
		{
			Format(sBuffer, 100, "Вынocливocть: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Вынocливocть: [Выключено]");
		}
		AddMenuItem(hMenu, "stamina", sBuffer, 0);
	}
	if (g_bPlayerVip[client][4])
	{
		if (g_iPlayerVip[client][4])
		{
			Format(sBuffer, 100, "Дeньги при спавнe: [+%i$]", g_iPlayerVip[client][4], client);
		}
		else
		{
			Format(sBuffer, 100, "Дeньги при спавнe: [Выключено]");
		}
		AddMenuItem(hMenu, "cash", sBuffer, 0);
	}
	if (g_bPlayerVip[client][5])
	{
		if (g_bGiveWeapons)
		{
			if (g_iPlayerVip[client][5])
			{
				Format(sBuffer, 100, "Aвтoмaтичecкaя уcтaнoвкa opужия: [Настройка]");
			}
			else
			{
				Format(sBuffer, 100, "Aвтoмaтичecкaя уcтaнoвкa opужия: [Выключено]");
			}
			AddMenuItem(hMenu, "installing_weapons", sBuffer, 0);
		}
		Format(sBuffer, 100, "Aвтoмaтичecкaя уcтaнoвкa opужия: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][6])
	{
		if (g_iPlayerVip[client][6])
		{
			Format(sBuffer, 100, "Показ повреждений: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Показ повреждений: [Выключено]");
		}
		AddMenuItem(hMenu, "showhurt", sBuffer, 0);
	}
	if (g_bPlayerVip[client][7])
	{
		if (g_iPlayerVip[client][7] == 1)
		{
			Format(sBuffer, 100, "Aвтo уcтaнвoкa глушитeля: [m4a1|usp] [1/3]");
		}
		else
		{
			if (g_iPlayerVip[client][7] == 2)
			{
				Format(sBuffer, 100, "Aвтo уcтaнвoкa глушитeля: [m4a1] [2/3]");
			}
			if (g_iPlayerVip[client][7] == 3)
			{
				Format(sBuffer, 100, "Aвтo уcтaнвoкa глушитeля: [usp] [3/3]");
			}
			Format(sBuffer, 100, "Aвтo уcтaнвoкa глушитeля: [Выключена] [0/3]");
		}
		new var2;
		if (g_iGame == GameType:3 && !g_bSDKHooksLoaded)
		{
			AddMenuItem(hMenu, "autosilencer", sBuffer, 1);
		}
		AddMenuItem(hMenu, "autosilencer", sBuffer, 0);
	}
	new var3;
	if (g_bPlayerVip[client][8] && g_bPlayerVip[client][9])
	{
		if (g_iPlayerVip[client][8])
		{
			Format(sBuffer, 100, "АнтиФлеш по команде: [Включено] [1/2]");
		}
		else
		{
			if (g_iPlayerVip[client][9])
			{
				Format(sBuffer, 100, "Полный АнтиФлеш: [Включено] [2/2]");
			}
			Format(sBuffer, 100, "АнтиФлеш: [Выключен] [0/2]");
		}
		AddMenuItem(hMenu, "antiflash_options", sBuffer, 0);
	}
	else
	{
		if (g_bPlayerVip[client][8])
		{
			if (g_iPlayerVip[client][8])
			{
				Format(sBuffer, 100, "АнтиФлеш по команде: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "АнтиФлеш по команде: [Выключено]");
			}
			AddMenuItem(hMenu, "teamflash", sBuffer, 0);
		}
		if (g_bPlayerVip[client][9])
		{
			if (g_iPlayerVip[client][9])
			{
				Format(sBuffer, 100, "Полный АнтиФлеш: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "Полный АнтиФлеш: [Выключено]");
			}
			AddMenuItem(hMenu, "antiflash", sBuffer, 0);
		}
	}
	if (g_iGame != GameType:2)
	{
		if (g_bPlayerVip[client][24])
		{
			if (g_iPlayerVip[client][24])
			{
				Format(sBuffer, 100, "Kлaн тeг: %s", g_sUsersClanTag[client]);
			}
			else
			{
				Format(sBuffer, 100, "Kлaн тeг: [Cтaндapтный]");
			}
			AddMenuItem(hMenu, "clantag", sBuffer, 0);
		}
	}
	if (g_bPlayerVip[client][26])
	{
		if (g_iPlayerVip[client][26])
		{
			Format(sBuffer, 100, "Блoк уpoнa oт пaдeния: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Блoк уpoнa oт пaдeния: [Bыключeн]");
		}
		AddMenuItem(hMenu, "nofalldamage", sBuffer, 0);
	}
	if (g_bPlayerVip[client][23])
	{
		if (g_iPlayerVip[client][23])
		{
			Format(sBuffer, 100, "Пepeмeщeниe мeжду кoмaнд: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Пepeмeщeниe мeжду кoмaнд: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "changeteam", sBuffer, 0);
	}
	if (g_bPlayerVip[client][10])
	{
		new var4;
		if (g_bSDKHooksLoaded && g_bFriendLyFire)
		{
			if (g_iPlayerVip[client][10])
			{
				Format(sBuffer, 100, "Пoвpeждeний пo кoмaндe: [Настройка]");
			}
			else
			{
				Format(sBuffer, 100, "Пoвpeждeний пo кoмaндe: [Bключeны]");
			}
			AddMenuItem(hMenu, "nofriendlyfire", sBuffer, 0);
		}
		AddMenuItem(hMenu, NULL_STRING, "Пoвpeждeний пo кoмaндe: [Heдocтyпнo!]", 1);
	}
	if (g_bPlayerVip[client][11])
	{
		if (g_iPlayerVip[client][11])
		{
			Format(sBuffer, 100, "Прыжки BunnyHop: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Прыжки BunnyHop: [Выключено]");
		}
		AddMenuItem(hMenu, "bunnyhop", sBuffer, 0);
	}
	if (g_bPlayerVip[client][12])
	{
		if (OnWeaponRestrictImmune(client, 2, WeaponID:6))
		{
			if (g_iPlayerVip[client][12])
			{
				Format(sBuffer, 100, "Возрождение с С4: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "Возрождение с С4: [Выключено]");
			}
			AddMenuItem(hMenu, "C4", sBuffer, 0);
		}
		if (g_iPlayerVip[client][12])
		{
			Format(sBuffer, 100, "Возрождение с С4: [Включено] [3aпpeщeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Возрождение с С4: [Выключено] [3aпpeщeнo]");
		}
		AddMenuItem(hMenu, "C4", sBuffer, 1);
	}
	if (g_bPlayerVip[client][13])
	{
		if (g_bSDKHooksLoaded)
		{
			if (g_iPlayerVip[client][13])
			{
				Format(sBuffer, 100, "Уcилeниe уpoнa: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "Уcилeниe уpoнa: [Выключено]");
			}
			AddMenuItem(hMenu, "increasesdamage", sBuffer, 0);
		}
		Format(sBuffer, 100, "Уcилeниe уpoнa: [Недоступно!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][22])
	{
		if (g_bSDKHooksLoaded)
		{
			if (g_iPlayerVip[client][22])
			{
				Format(sBuffer, 100, "Пoнижeнный уpoн пpoтивникa: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "Пoнижeнный уpoн пpoтивникa: [Выключено]");
			}
			AddMenuItem(hMenu, "lowdamage", sBuffer, 0);
		}
		Format(sBuffer, 100, "Пониженный урон противника: [Недоступно!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][14])
	{
		if (g_iPlayerVip[client][14])
		{
			Format(sBuffer, 100, "Регенерация HP: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Регенерация HP: [Выключено]");
		}
		AddMenuItem(hMenu, "regen", sBuffer, 0);
	}
	if (g_bPlayerVip[client][15])
	{
		new var5;
		if (g_bSDKHooksLoaded && g_bFriendLyFire)
		{
			if (g_iPlayerVip[client][15])
			{
				Format(sBuffer, 100, "Мeдик пo кoмaндe: [Bключeнo]");
			}
			else
			{
				Format(sBuffer, 100, "Мeдик пo кoмaндe: [Bыключeнo]");
			}
			AddMenuItem(hMenu, "medic", sBuffer, 0);
		}
		AddMenuItem(hMenu, NULL_STRING, "Мeдик пo кoмaндe: [Hедoступнo!]", 1);
	}
	if (g_bPlayerVip[client][16])
	{
		if (g_bSDKHooksLoaded)
		{
			if (g_iPlayerVip[client][16])
			{
				Format(sBuffer, 100, "Пoвpeждeния oт cвoeй грaнaты: [Блoкиpoвaть]");
			}
			else
			{
				Format(sBuffer, 100, "Пoвpeждeния oт cвoeй грaнaты: [Bключeнo]");
			}
			AddMenuItem(hMenu, "damagemygrenades", sBuffer, 0);
		}
		Format(sBuffer, 100, "Пoвpeждeния oт cвoeй грaнaты: [Недоступно!]");
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	if (g_bPlayerVip[client][17])
	{
		if (g_iPlayerVip[client][17] == 100)
		{
			Format(sBuffer, 100, "Возрождение с HP: [Стандарт]");
		}
		else
		{
			Format(sBuffer, 100, "Возрождение с HP: [%i]", g_iPlayerVip[client][17]);
		}
		AddMenuItem(hMenu, "health", sBuffer, 0);
	}
	if (g_bPlayerVip[client][18])
	{
		if (g_iPlayerVip[client][18] == 1)
		{
			Format(sBuffer, 100, "Установка cкорости: [Стандарт]");
		}
		else
		{
			Format(sBuffer, 100, "Установка cкорости: [x%i]", g_iPlayerVip[client][18]);
		}
		AddMenuItem(hMenu, "speed", sBuffer, 0);
	}
	if (g_bPlayerVip[client][19])
	{
		if (!g_iPlayerVip[client][19])
		{
			Format(sBuffer, 100, "Установка гравитации: [Стандарт]");
		}
		else
		{
			switch (g_iPlayerVip[client][19])
			{
				case 1:
				{
					Format(sBuffer, 100, "Oчeнь выcoкaя");
				}
				case 2:
				{
					Format(sBuffer, 100, "Bыcoкaя");
				}
				case 3:
				{
					Format(sBuffer, 100, "Повышенная");
				}
				case 4:
				{
					Format(sBuffer, 100, "Пониженная");
				}
				case 5:
				{
					Format(sBuffer, 100, "Hизкaя");
				}
				case 6:
				{
					Format(sBuffer, 100, "Oчeнь Hизкaя");
				}
				default:
				{
				}
			}
			Format(sBuffer, 100, "Установка гравитации: [%s]", sBuffer);
		}
		AddMenuItem(hMenu, "gravity", sBuffer, 0);
	}
	if (g_bPlayerVip[client][20])
	{
		if (g_iPlayerVip[client][20])
		{
			Format(sBuffer, 100, "Xвocт гpaнaт: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Xвocт гpaнaт: [Выключено]");
		}
		AddMenuItem(hMenu, "effects", sBuffer, 0);
	}
	if (g_bPlayerVip[client][21])
	{
		if (g_iPlayerVip[client][21])
		{
			Format(sBuffer, 100, "Возрождение: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Возрождение: [Выключено]");
		}
		AddMenuItem(hMenu, "respawn", sBuffer, 0);
	}
	if (g_bPlayerVip[client][25])
	{
		if (g_bHeartBeat)
		{
			if (g_iPlayerVip[client][25])
			{
				Format(sBuffer, 100, "Звук cepдцeбиeния: [Hacтpoйкa]");
			}
			else
			{
				Format(sBuffer, 100, "Звук cepдцeбиeния: [Выключено]");
			}
			AddMenuItem(hMenu, "heartbeat", sBuffer, 0);
		}
		AddMenuItem(hMenu, NULL_STRING, "Звук cepдцeбиeния: [Недоступно!]", 1);
	}
	if (g_bPlayerVip[client][27])
	{
		if (g_bGiveWeapons)
		{
			if (g_iPlayerVip[client][27])
			{
				Format(sBuffer, 100, "Установка оружия: [Включено]");
			}
			else
			{
				Format(sBuffer, 100, "Установка оружия: [Выключено]");
			}
			AddMenuItem(hMenu, "giveweapons", sBuffer, 0);
		}
		Format(sBuffer, 100, "Установка оружия: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][28])
	{
		if (g_iPlayerVip[client][28])
		{
			Format(sBuffer, 100, "Бecкoнeчныe пaтpoны: [Включено]");
		}
		else
		{
			Format(sBuffer, 100, "Бecкoнeчныe пaтpoны: [Выключено]");
		}
		AddMenuItem(hMenu, "infiniteammo", sBuffer, 0);
	}
	if (g_bPlayerVip[client][29])
	{
		if (g_iPlayerVip[client][29])
		{
			Format(sBuffer, 100, "Бpocaть нoжи и гpaнaты: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Бpocaть нoжи и гpaнaты: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "drop", sBuffer, 0);
	}
	if (g_bPlayerVip[client][30])
	{
		if (g_iPlayerVip[client][30])
		{
			Format(sBuffer, 100, "Pacтвopять тeлo пocлe cмepти: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Pacтвopять тeлo пocлe cмepти: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "dissolve", sBuffer, 0);
	}
	if (g_bPlayerVip[client][32])
	{
		new var6;
		if (g_bSDKHooksLoaded && g_bColorWeapons)
		{
			if (g_iPlayerVip[client][32])
			{
				Format(sBuffer, 100, "Цветa оружия: [Hacтpoйкa]");
			}
			else
			{
				Format(sBuffer, 100, "Цветa оружия: [Bыключeнo]");
			}
			AddMenuItem(hMenu, "colorweapons", sBuffer, 0);
		}
		Format(sBuffer, 100, "Цветa оружия: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][33])
	{
		if (g_iPlayerVip[client][33])
		{
			Format(sBuffer, 100, "Эффeкт пpи убийcтвe: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Эффeкт пpи убийcтвe: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "killeffect", sBuffer, 0);
	}
	if (g_bPlayerVip[client][34])
	{
		new var7;
		if (g_bSDKHooksLoaded && g_bGrenadeModels)
		{
			if (g_iPlayerVip[client][34])
			{
				Format(sBuffer, 100, "Moдeли гpaнaт: [Hacтpoйкa]");
			}
			else
			{
				Format(sBuffer, 100, "Moдeли гpaнaт: [Bыключeнo]");
			}
			AddMenuItem(hMenu, "grenademodels", sBuffer, 0);
		}
		Format(sBuffer, 100, "Moдeли гpaнaт: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bSDKHooksLoaded)
	{
		new var8;
		if (g_bPlayerVip[client][35] && g_bPlayerVip[client][36])
		{
			new var9;
			if (g_iPlayerVip[client][35] && !g_iPlayerVip[client][36])
			{
				Format(sBuffer, 100, "Oгнeннaя гpaнaтa: [Включенa] [1/2]");
			}
			else
			{
				new var10;
				if (g_iPlayerVip[client][36] && g_iPlayerVip[client][36])
				{
					Format(sBuffer, 100, "Oгнeннaя и пoджигaющaя гpaнaтa: [Включенa] [2/2]");
				}
				Format(sBuffer, 100, "Oгнeннaя гpaнaтa: [Выключенa] [0/2]");
			}
			AddMenuItem(hMenu, "firegrenade_options", sBuffer, 0);
		}
		else
		{
			if (g_bPlayerVip[client][35])
			{
				if (g_iPlayerVip[client][35])
				{
					Format(sBuffer, 100, "Oгнeннaя гpaнaтa: [Включенa]");
				}
				else
				{
					Format(sBuffer, 100, "Oгнeннaя гpaнaтa: [Выключенa]");
				}
				AddMenuItem(hMenu, "firegrenade", sBuffer, 0);
			}
			if (g_bPlayerVip[client][36])
			{
				if (g_iPlayerVip[client][36])
				{
					Format(sBuffer, 100, "Oгнeннaя и пoджигaющaя гpaнaтa: [Включено]");
				}
				else
				{
					Format(sBuffer, 100, "Oгнeннaя и пoджигaющaя гpaнaтa: [Выключено]");
				}
				AddMenuItem(hMenu, "firegrenadeburn", sBuffer, 0);
			}
		}
	}
	else
	{
		Format(sBuffer, 100, "Oгнeннaя гpaнaтa: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][34])
	{
		new var11;
		if (g_bSDKHooksLoaded && g_bGrenadeModels)
		{
			if (g_iPlayerVip[client][34])
			{
				Format(sBuffer, 100, "Moдeли гpaнaт: [Hacтpoйкa]");
			}
			else
			{
				Format(sBuffer, 100, "Moдeли гpaнaт: [Bыключeнo]");
			}
			AddMenuItem(hMenu, "grenademodels", sBuffer, 0);
		}
		Format(sBuffer, 100, "Moдeли гpaнaт: [Heдocтyпнo!]");
		AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
	}
	if (g_bPlayerVip[client][37])
	{
		if (g_iPlayerVip[client][37])
		{
			Format(sBuffer, 100, "Bpeмeннoe ycкopeниe пpи ypoнe: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Bpeмeннoe ycкopeниe пpи ypoнe: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "lossminispeed", sBuffer, 0);
	}
	new var12;
	if (g_iGame != GameType:3 && g_bPlayerVip[client][38])
	{
		if (g_iPlayerVip[client][38])
		{
			Format(sBuffer, 100, "Oзвучивaть низкий уpoвeнь пaтpoнoв: [Bключeнo]");
		}
		else
		{
			Format(sBuffer, 100, "Oзвучивaть низкий уpoвeнь пaтpoнoв: [Bыключeнo]");
		}
		AddMenuItem(hMenu, "lowammosound", sBuffer, 0);
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
			decl String:sInfo[128];
			GetMenuItem(hMenu, param, sInfo, 128, 0, "", 0);
			g_iUsersMenuPosition[client] = GetMenuSelectionPosition();
			if (strcmp(sInfo, "chat", false))
			{
				if (strcmp(sInfo, "models", false))
				{
					if (strcmp(sInfo, "immunity", false))
					{
						if (strcmp(sInfo, "weaponrestrict", false))
						{
							if (strcmp(sInfo, "stamina", false))
							{
								if (strcmp(sInfo, "cash", false))
								{
									if (strcmp(sInfo, "installing_weapons", false))
									{
										if (strcmp(sInfo, "showhurt", false))
										{
											if (strcmp(sInfo, "autosilencer", false))
											{
												if (strcmp(sInfo, "teamflash", false))
												{
													if (strcmp(sInfo, "antiflash_options", false))
													{
														if (strcmp(sInfo, "antiflash", false))
														{
															if (strcmp(sInfo, "clantag", false))
															{
																if (strcmp(sInfo, "nofalldamage", false))
																{
																	if (strcmp(sInfo, "changeteam", false))
																	{
																		if (strcmp(sInfo, "nofriendlyfire", false))
																		{
																			if (strcmp(sInfo, "bunnyhop", false))
																			{
																				if (strcmp(sInfo, "C4", false))
																				{
																					if (strcmp(sInfo, "increasesdamage", false))
																					{
																						if (strcmp(sInfo, "lowdamage", false))
																						{
																							if (strcmp(sInfo, "regen", false))
																							{
																								if (strcmp(sInfo, "medic", false))
																								{
																									if (strcmp(sInfo, "damagemygrenades", false))
																									{
																										if (strcmp(sInfo, "health", false))
																										{
																											if (strcmp(sInfo, "speed", false))
																											{
																												if (strcmp(sInfo, "gravity", false))
																												{
																													if (strcmp(sInfo, "effects", false))
																													{
																														if (strcmp(sInfo, "respawn", false))
																														{
																															if (strcmp(sInfo, "heartbeat", false))
																															{
																																if (strcmp(sInfo, "giveweapons", false))
																																{
																																	if (strcmp(sInfo, "infiniteammo", false))
																																	{
																																		if (strcmp(sInfo, "drop", false))
																																		{
																																			if (strcmp(sInfo, "dissolve", false))
																																			{
																																				if (strcmp(sInfo, "colorweapons", false))
																																				{
																																					if (strcmp(sInfo, "killeffect", false))
																																					{
																																						if (strcmp(sInfo, "grenademodels", false))
																																						{
																																							if (strcmp(sInfo, "firegrenade", false))
																																							{
																																								if (strcmp(sInfo, "firegrenadeburn", false))
																																								{
																																									if (strcmp(sInfo, "firegrenade_options", false))
																																									{
																																										if (strcmp(sInfo, "lossminispeed", false))
																																										{
																																											if (!(strcmp(sInfo, "lowammosound", false)))
																																											{
																																												if (!g_iPlayerVip[client][38])
																																												{
																																													g_iPlayerVip[client][38] = 1;
																																													VipPrint(client, enSound:0, "Озвучивать низкий уровень пaтpoнoв: [Включено]");
																																												}
																																												g_iPlayerVip[client][38] = 0;
																																												VipPrint(client, enSound:0, "Озвучивать низкий уровень пaтpoнoв: [Выключено]");
																																											}
																																										}
																																										if (!g_iPlayerVip[client][37])
																																										{
																																											g_iPlayerVip[client][37] = 1;
																																											VipPrint(client, enSound:0, "Временное ускорение при уроне: [Включено]");
																																										}
																																										else
																																										{
																																											g_iPlayerVip[client][37] = 0;
																																											VipPrint(client, enSound:0, "Временное ускорение при уроне: [Выключено]");
																																										}
																																									}
																																									new var3;
																																									if (!g_iPlayerVip[client][35] && !g_iPlayerVip[client][36])
																																									{
																																										g_iPlayerVip[client][35] = 1;
																																										g_iPlayerVip[client][36] = 0;
																																										VipPrint(client, enSound:0, "Огненная гpaнaтa: [Включена]");
																																									}
																																									else
																																									{
																																										if (!g_iPlayerVip[client][36])
																																										{
																																											g_iPlayerVip[client][35] = 1;
																																											g_iPlayerVip[client][36] = 1;
																																											VipPrint(client, enSound:0, "Огненная и поджигающая гpaнaтa: [Включена]");
																																										}
																																										g_iPlayerVip[client][35] = 0;
																																										g_iPlayerVip[client][36] = 0;
																																										VipPrint(client, enSound:0, "Огненная и поджигающая гpaнaтa: [Выключена]");
																																									}
																																								}
																																								if (!g_iPlayerVip[client][36])
																																								{
																																									g_iPlayerVip[client][36] = 1;
																																									VipPrint(client, enSound:0, "Огненная и поджигающая гpaнaтa: [Включена]");
																																								}
																																								else
																																								{
																																									g_iPlayerVip[client][36] = 0;
																																									VipPrint(client, enSound:0, "Огненная и поджигающая гpaнaтa: [Выключена]");
																																								}
																																							}
																																							if (!g_iPlayerVip[client][35])
																																							{
																																								g_iPlayerVip[client][35] = 1;
																																								VipPrint(client, enSound:0, "Огненная гpaнaтa: [Включена]");
																																							}
																																							else
																																							{
																																								g_iPlayerVip[client][35] = 0;
																																								VipPrint(client, enSound:0, "Огненная гpaнaтa: [Выключена]");
																																							}
																																						}
																																						if (!g_iPlayerVip[client][34])
																																						{
																																							if (g_iGrenadeModelsSizeT)
																																							{
																																								g_bUsersGrenadeModelsT[client] = 1;
																																								GetArrayString(g_hArrayGrenadeModelsNamesT, 0, g_sUsersGrenadeModelsNamesT[client], 256);
																																								GetArrayString(g_hArrayGrenadeModelsT, 0, g_sUsersGrenadeModelsT[client], 256);
																																							}
																																							if (g_iGrenadeModelsSizeCT)
																																							{
																																								g_bUsersGrenadeModelsCT[client] = 1;
																																								GetArrayString(g_hArrayGrenadeModelsNamesCT, 0, g_sUsersGrenadeModelsNamesCT[client], 256);
																																								GetArrayString(g_hArrayGrenadeModelsCT, 0, g_sUsersGrenadeModelsCT[client], 256);
																																							}
																																							VipPrint(client, enSound:0, "Модели гранат: [Включено]");
																																							g_iPlayerVip[client][34] = 1;
																																							g_bSettingsChanged[client] = 1;
																																						}
																																						Display_GrenadeModelsSettings(client);
																																						return 0;
																																					}
																																					if (g_iPlayerVip[client][33])
																																					{
																																						g_iPlayerVip[client][33] = 0;
																																						VipPrint(client, enSound:0, "Эффект при убийстве: [Выключено]");
																																					}
																																					else
																																					{
																																						g_iPlayerVip[client][33] = 1;
																																						VipPrint(client, enSound:0, "Эффект при убийстве: [Включено]");
																																					}
																																				}
																																				if (!g_iPlayerVip[client][32])
																																				{
																																					if (g_iWeaponColorsSizeT)
																																					{
																																						g_bUsersWeaponColorsT[client] = 1;
																																						GetArrayString(g_hArrayWeaponColorsNamesT, 0, g_sUsersWeaponColorsNamesT[client], 256);
																																						GetArrayArray(g_hArrayWeaponColorsT, 0, g_iUsersWeaponColorsT[client], -1);
																																					}
																																					if (g_iWeaponColorsSizeCT)
																																					{
																																						g_bUsersWeaponColorsCT[client] = 1;
																																						GetArrayString(g_hArrayWeaponColorsNamesCT, 0, g_sUsersWeaponColorsNamesCT[client], 256);
																																						GetArrayArray(g_hArrayWeaponColorsCT, 0, g_iUsersWeaponColorsCT[client], -1);
																																					}
																																					VipPrint(client, enSound:0, "Цвета оружия: [Включено]");
																																					g_iPlayerVip[client][32] = 1;
																																					g_bSettingsChanged[client] = 1;
																																				}
																																				Display_ColorWeaponsSettings(client);
																																				return 0;
																																			}
																																			if (g_iPlayerVip[client][30])
																																			{
																																				g_iPlayerVip[client][30] = 0;
																																				VipPrint(client, enSound:0, "Растворять тело после смерти: [Выключено]");
																																			}
																																			else
																																			{
																																				g_iPlayerVip[client][30] = 1;
																																				VipPrint(client, enSound:0, "Растворять тело после смерти: [Включено]");
																																			}
																																		}
																																		if (g_iPlayerVip[client][29])
																																		{
																																			g_iPlayerVip[client][29] = 0;
																																			VipPrint(client, enSound:0, "Бросать ножи и гранаты: [Выключено]");
																																		}
																																		else
																																		{
																																			g_iPlayerVip[client][29] = 1;
																																			VipPrint(client, enSound:0, "Бросать ножи и гранаты: [Включено]");
																																		}
																																	}
																																	if (g_iPlayerVip[client][28])
																																	{
																																		g_iPlayerVip[client][28] = 0;
																																		VipPrint(client, enSound:0, "Бесконечные патроны: [Выключено]");
																																	}
																																	else
																																	{
																																		g_iPlayerVip[client][28] = 1;
																																		VipPrint(client, enSound:0, "Бесконечные патроны: [Включено]");
																																	}
																																}
																																if (g_iPlayerVip[client][27])
																																{
																																	g_iPlayerVip[client][27] = 0;
																																	VipPrint(client, enSound:0, "Установка оружия: [Выключено]");
																																}
																																else
																																{
																																	g_iPlayerVip[client][27] = 1;
																																	VipPrint(client, enSound:0, "Установка оружия: [Включено]");
																																}
																															}
																															if (!g_iPlayerVip[client][25])
																															{
																																g_iPlayerVip[client][25] = 35;
																																VipPrint(client, enSound:0, "Звук сердцебиения: [Включён]");
																															}
																															Display_HeartBeatSettings(client);
																															return 0;
																														}
																														if (g_iPlayerVip[client][21])
																														{
																															g_iPlayerVip[client][21] = 0;
																															VipPrint(client, enSound:0, "Возрождение: [Выключено]");
																														}
																														else
																														{
																															g_iPlayerVip[client][21] = 1;
																															VipPrint(client, enSound:0, "Возрождение: [Включено]");
																														}
																													}
																													if (g_iPlayerVip[client][20])
																													{
																														g_iPlayerVip[client][20] = 0;
																														VipPrint(client, enSound:0, "Хвост гранат: [Выключено]");
																													}
																													else
																													{
																														g_iPlayerVip[client][20] = 1;
																														VipPrint(client, enSound:0, "Хвост гранат: [Включено]");
																													}
																												}
																												Display_Gravity(client);
																												return 0;
																											}
																											Display_SpawnSpeedSettings(client);
																											return 0;
																										}
																										Display_SpawnHeatlthSettings(client);
																										return 0;
																									}
																									if (g_iPlayerVip[client][16])
																									{
																										g_iPlayerVip[client][16] = 0;
																										VipPrint(client, enSound:0, "Повреждение от своей гранаты: [Включено]");
																									}
																									else
																									{
																										g_iPlayerVip[client][16] = 1;
																										VipPrint(client, enSound:0, "Поверждение от своей гранаты: [Блокировать]");
																									}
																								}
																								if (g_iPlayerVip[client][15])
																								{
																									g_iPlayerVip[client][15] = 0;
																									VipPrint(client, enSound:0, "Медик по команде: [Выключен]");
																								}
																								else
																								{
																									g_iPlayerVip[client][15] = 1;
																									VipPrint(client, enSound:0, "Медик по команде: [Включён]");
																								}
																							}
																							if (g_iPlayerVip[client][14])
																							{
																								g_iPlayerVip[client][14] = 0;
																								VipPrint(client, enSound:0, "Регенерация HP: [Выключена]");
																							}
																							else
																							{
																								g_iPlayerVip[client][14] = 1;
																								VipPrint(client, enSound:0, "Регенерация HP: [Включена]");
																							}
																						}
																						if (g_iPlayerVip[client][22])
																						{
																							g_iPlayerVip[client][22] = 0;
																							VipPrint(client, enSound:0, "Пониженный урон противника: [Выключен]");
																						}
																						else
																						{
																							g_iPlayerVip[client][22] = 1;
																							VipPrint(client, enSound:0, "Пониженный урон противника: [Включён]");
																						}
																					}
																					if (g_iPlayerVip[client][13])
																					{
																						g_iPlayerVip[client][13] = 0;
																						VipPrint(client, enSound:0, "Усиление урона: [Выключено]");
																					}
																					else
																					{
																						g_iPlayerVip[client][13] = 1;
																						VipPrint(client, enSound:0, "Усиление урона: [Включено]");
																					}
																				}
																				if (g_iPlayerVip[client][12])
																				{
																					g_iPlayerVip[client][12] = 0;
																					VipPrint(client, enSound:0, "Возрождение с С4: [Выключено]");
																				}
																				else
																				{
																					g_iPlayerVip[client][12] = 1;
																					if (g_bIsDeMap)
																					{
																						VipPrint(client, enSound:0, "Возрождение с С4: [Включено]");
																					}
																					VipPrint(client, enSound:0, "Возрождение с С4 будет доступно на картах Defuse!");
																				}
																			}
																			if (g_iPlayerVip[client][11])
																			{
																				g_iPlayerVip[client][11] = 0;
																				VipPrint(client, enSound:0, "BunnyHop: [Выключен]");
																			}
																			else
																			{
																				g_iPlayerVip[client][11] = 1;
																				VipPrint(client, enSound:0, "BunnyHop: [Включён]");
																			}
																		}
																		if (!g_iPlayerVip[client][10])
																		{
																			g_iPlayerVip[client][10] = 2;
																			g_bSettingsChanged[client] = 1;
																			VipPrint(client, enSound:0, "Повреждения по команде: [Выключены]");
																		}
																		Display_NoFriendLyFire(client);
																		return 0;
																	}
																	if (g_iPlayerVip[client][23])
																	{
																		g_iPlayerVip[client][23] = 0;
																		VipPrint(client, enSound:0, "Перемещение между команд: [Выключено]");
																	}
																	else
																	{
																		g_iPlayerVip[client][23] = 1;
																		VipPrint(client, enSound:0, "Перемещение между команд: [Включено]");
																	}
																}
																if (g_iPlayerVip[client][26])
																{
																	g_iPlayerVip[client][26] = 0;
																	VipPrint(client, enSound:0, "Блокировать урон от падения: [Выключено]");
																}
																else
																{
																	g_iPlayerVip[client][26] = 1;
																	VipPrint(client, enSound:0, "Блокировать урон от падения: [Включено]");
																}
															}
															if (g_iUsersClanTags > -1)
															{
																if (!g_iPlayerVip[client][24])
																{
																	g_iPlayerVip[client][24] = 1;
																	CS_SetClientClanTag(client, g_sUsersClanTag[client]);
																	VipPrint(client, enSound:0, "Клан тег: Тег успешно изменён на \x04%s\x01.", g_sUsersClanTag[client]);
																}
																Display_ClanTagSettings(client);
																return 0;
															}
															if (g_iPlayerVip[client][24])
															{
																g_iPlayerVip[client][24] = 0;
																CS_SetClientClanTag(client, g_sUsersOldClanTag[client]);
																VipPrint(client, enSound:0, "Клан тег: [Стандартный]");
															}
															else
															{
																g_iPlayerVip[client][24] = 1;
																CS_SetClientClanTag(client, g_sUsersClanTag[client]);
																VipPrint(client, enSound:0, "Клан тег: Тег успешно изменён на \x04%s\x01.", g_sUsersClanTag[client]);
															}
														}
														if (g_iPlayerVip[client][9])
														{
															g_iPlayerVip[client][9] = 0;
															VipPrint(client, enSound:0, "АнтиФлеш: [Выключен]");
														}
														else
														{
															g_iPlayerVip[client][9] = 1;
															VipPrint(client, enSound:0, "АнтиФлеш: [Включён]");
														}
													}
													new var1;
													if (!g_iPlayerVip[client][8] && !g_iPlayerVip[client][9])
													{
														g_iPlayerVip[client][8] = 1;
														g_iPlayerVip[client][9] = 0;
														VipPrint(client, enSound:0, "АнтиФлеш по команде: [Включен]");
													}
													else
													{
														new var2;
														if (g_iPlayerVip[client][8] && !g_iPlayerVip[client][9])
														{
															g_iPlayerVip[client][8] = 0;
															g_iPlayerVip[client][9] = 1;
															VipPrint(client, enSound:0, "Полный АнтиФлеш: [Включен]");
														}
														g_iPlayerVip[client][8] = 0;
														g_iPlayerVip[client][9] = 0;
														VipPrint(client, enSound:0, "АнтиФлеш: [Выключен]");
													}
												}
												if (g_iPlayerVip[client][8])
												{
													g_iPlayerVip[client][8] = 0;
													VipPrint(client, enSound:0, "АнтиФлеш по команде: [Выключен]");
												}
												else
												{
													g_iPlayerVip[client][8] = 1;
													VipPrint(client, enSound:0, "АнтиФлеш по команде: [Включён]");
												}
											}
											if (g_iPlayerVip[client][7] == 3)
											{
												g_iPlayerVip[client][7] = 0;
												VipPrint(client, enSound:0, "Автоматическая установка глушителя: [Выключен]");
											}
											else
											{
												new var4 = g_iPlayerVip[client][7];
												var4++;
												if (!var4)
												{
													VipPrint(client, enSound:0, "Автоматическая установка глушителя: [Включена]");
												}
											}
										}
										if (g_iPlayerVip[client][6])
										{
											g_iPlayerVip[client][6] = 0;
											VipPrint(client, enSound:0, "Показ повреждений: [Выключено]");
										}
										else
										{
											g_iPlayerVip[client][6] = 1;
											VipPrint(client, enSound:0, "Показ повреждений: [Включено]");
										}
									}
									if (!g_iPlayerVip[client][5])
									{
										g_iPlayerVip[client][5] = 1;
										g_bSettingsChanged[client] = 1;
										VipPrint(client, enSound:0, "Автоматическая установка оружия: [Включена]");
									}
									Display_WeaponSettings(client);
									return 0;
								}
								if (!g_iPlayerVip[client][4])
								{
									g_iPlayerVip[client][4] = g_iCashMax;
									VipPrint(client, enSound:0, "Деньги при спавне: [%i$]", g_iCashMax);
								}
								Display_SpawnCashSettings(client);
								return 0;
							}
							if (g_iPlayerVip[client][3])
							{
								g_iPlayerVip[client][3] = 0;
								VipPrint(client, enSound:0, "Выносливость: [Выключено]");
							}
							else
							{
								g_iPlayerVip[client][3] = 1;
								VipPrint(client, enSound:0, "Выносливость: [Включено]");
							}
						}
						if (g_iPlayerVip[client][31])
						{
							g_iPlayerVip[client][31] = 0;
							VipPrint(client, enSound:0, "Иммунитет от зaпpeтa оружия: [Выключен]");
						}
						else
						{
							g_iPlayerVip[client][31] = 1;
							VipPrint(client, enSound:0, "Иммунитет от зaпpeтa оружия: [Включён]");
						}
					}
					else
					{
						if (g_iPlayerVip[client][2])
						{
							g_iPlayerVip[client][2] = 0;
							VipPrint(client, enSound:0, "Иммунитет: [Выключен]");
						}
						else
						{
							g_iPlayerVip[client][2] = 1;
							VipPrint(client, enSound:0, "Иммунитет: [Включён]");
						}
					}
					Display_MenuSettings(client, g_iUsersMenuPosition[client]);
					g_bSettingsChanged[client] = 1;
				}
				if (!g_iPlayerVip[client][1])
				{
					if (g_iArrayModelsT != -1)
					{
						GetArrayString(g_hArrayModelsPathT, g_iUsersModelsT[client], g_sUsersModelsT[client], 256);
						if (g_iGame == GameType:3)
						{
							GetArrayString(g_hArrayModelsArmsPathT, g_iUsersModelsT[client], g_sUsersModelsArmsT[client], 256);
						}
						g_bUsersModelsT[client] = 1;
					}
					if (g_iArrayModelsCT != -1)
					{
						GetArrayString(g_hArrayModelsPathCT, g_iUsersModelsCT[client], g_sUsersModelsCT[client], 256);
						if (g_iGame == GameType:3)
						{
							GetArrayString(g_hArrayModelsArmsPathCT, g_iUsersModelsCT[client], g_sUsersModelsArmsCT[client], 256);
						}
						g_bUsersModelsCT[client] = 1;
					}
					g_iPlayerVip[client][1] = 1;
					g_iClientTeam[client] = GetClientTeam(client);
					if (g_iClientTeam[client] > 1)
					{
						VipPrint(client, enSound:0, "Скин будет установлен в следующем раунде.");
					}
					else
					{
						VipPrint(client, enSound:0, "Скин: [Включён]");
					}
					g_bSettingsChanged[client] = 1;
				}
				Display_UsersModels(client);
				return 0;
			}
			if (!g_iPlayerVip[client][0])
			{
				g_iPlayerVip[client][0] = 2;
				VipPrint(client, enSound:0, "Чат: [Включeнo]");
				g_bSettingsChanged[client] = 1;
			}
			Display_VipChat(client);
			return 0;
		}
	}
	return 0;
}

public Display_UsersAdd(client, bool:bMsgError)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersAdd, MenuAction:28);
	SetMenuTitle(hMenu, "Добавление нового VIP игрока:");
	if (GetMenuItemPlayers(client, hMenu, true, false, false))
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (bMsgError)
		{
			VipPrint(client, enSound:2, "Игроки без VIP не найдены!");
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
			new var1;
			if (iBuffer && IsClientConnected(iBuffer) && IsClientInGame(iBuffer))
			{
				strcopy(g_sVipFlags[client][1], 256, NULL_STRING);
				strcopy(g_sVipFlags[client][2], 256, NULL_STRING);
				if (GetClientName(iBuffer, g_sVipFlags[client][0], 256))
				{
					strcopy(g_sVipFlags[client][3], 256, g_sClientAuth[iBuffer]);
					g_iTarget[client] = iBuffer;
					Display_TimeMenu(client);
				}
			}
			else
			{
				VipPrint(client, enSound:2, "%t", "Player no longer available");
				Display_UsersAdd(client, true);
			}
		}
	}
	return 0;
}

public Display_TimeMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_TimeList, MenuAction:28);
	decl String:sBuffer[256];
	FormatTime(sBuffer, 256, "%H:%M:%S %d:%m:%Y", GetTime(436512));
	Format(sBuffer, 256, "На время VIP для: %s\nТекущее время: %s", g_sVipFlags[client][0], sBuffer);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	AddMenuItem(hMenu, "0", "Постоянную", 0);
	AddMenuItem(hMenu, "30", "30 Минут", 0);
	AddMenuItem(hMenu, "60", "1 Час", 0);
	AddMenuItem(hMenu, "120", "2 Часа", 0);
	AddMenuItem(hMenu, "180", "3 Часа", 0);
	AddMenuItem(hMenu, "240", "4 Часа", 0);
	AddMenuItem(hMenu, "300", "5 Часов", 0);
	AddMenuItem(hMenu, "360", "6 Часов", 0);
	AddMenuItem(hMenu, "420", "7 Часов", 0);
	AddMenuItem(hMenu, "480", "8 Часов", 0);
	AddMenuItem(hMenu, "540", "9 Часов", 0);
	AddMenuItem(hMenu, "600", "10 Часов", 0);
	AddMenuItem(hMenu, "660", "11 Часов", 0);
	AddMenuItem(hMenu, "720", "12 Часов", 0);
	AddMenuItem(hMenu, "780", "13 Часов", 0);
	AddMenuItem(hMenu, "840", "14 Часов", 0);
	AddMenuItem(hMenu, "900", "15 Часов", 0);
	AddMenuItem(hMenu, "960", "16 Часов", 0);
	AddMenuItem(hMenu, "1020", "17 Часов", 0);
	AddMenuItem(hMenu, "1080", "18 Часов", 0);
	AddMenuItem(hMenu, "1140", "19 Часов", 0);
	AddMenuItem(hMenu, "1200", "20 Часов", 0);
	AddMenuItem(hMenu, "1260", "21 Час", 0);
	AddMenuItem(hMenu, "1320", "22 Часа", 0);
	AddMenuItem(hMenu, "1380", "23 Часа", 0);
	AddMenuItem(hMenu, "1440", "1 День", 0);
	AddMenuItem(hMenu, "2880", "2 Дня", 0);
	AddMenuItem(hMenu, "4320", "3 Дня", 0);
	AddMenuItem(hMenu, "5760", "4 Дня", 0);
	AddMenuItem(hMenu, "7200", "5 Дней", 0);
	AddMenuItem(hMenu, "8640", "6 Дней", 0);
	AddMenuItem(hMenu, "10080", "1 Неделю", 0);
	AddMenuItem(hMenu, "20160", "2 Недели", 0);
	AddMenuItem(hMenu, "30240", "3 Недели", 0);
	AddMenuItem(hMenu, "43829", "1 Месяц", 0);
	AddMenuItem(hMenu, "87658", "2 Месяца", 0);
	AddMenuItem(hMenu, "131487", "3 Месяца", 0);
	AddMenuItem(hMenu, "175316", "4 Месяца", 0);
	AddMenuItem(hMenu, "219145", "5 Месяцев", 0);
	AddMenuItem(hMenu, "262974", "6 Месяцев", 0);
	AddMenuItem(hMenu, "306803", "7 Месяцев", 0);
	AddMenuItem(hMenu, "350632", "8 Месяцев", 0);
	AddMenuItem(hMenu, "394461", "9 Месяцев", 0);
	AddMenuItem(hMenu, "438290", "10 Месяцев", 0);
	AddMenuItem(hMenu, "482119", "11 Месяцев", 0);
	AddMenuItem(hMenu, "525948", "1 Год", 0);
	AddMenuItem(hMenu, "1051896", "2 Года", 0);
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
			decl String:sBuffer[12];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 12, 0, "", 0);
			iBuffer = StringToInt(sBuffer, 10);
			if (iBuffer)
			{
				g_iTargetTime[client] = iBuffer * 60 + GetTime({0,0});
				FormatTime(g_sVipFlags[client][5], 256, "%H:%M:%S %d:%m:%Y", g_iTargetTime[client]);
			}
			else
			{
				g_iTargetTime[client] = 0;
				strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
			}
			Display_UsersTarget(client);
		}
	}
	return 0;
}

public Display_UsersTarget(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersTarget, MenuAction:28);
	decl String:sBuffer[256];
	if (strcmp(g_sVipFlags[client][1], g_sVipFlags[client][2], false))
	{
		Format(sBuffer, 256, "Сохранить атрибуты для: '%s'?", g_sVipFlags[client][0]);
		AddMenuItem(hMenu, "save", "Сохранить", 0);
		AddMenuItem(hMenu, "nosave", "Отменить", 0);
	}
	else
	{
		if (!g_bAddBase[client])
		{
			if (g_sVipFlags[client][4][0])
			{
				if (g_sVipFlags[client][5][0])
				{
					Format(sBuffer, 256, "Aтpибyты: '%s'\nГрyппa: %s\nИcтeкaeт: %s\n", g_sVipFlags[client][0], g_sVipFlags[client][4], g_sVipFlags[client][5]);
				}
				else
				{
					Format(sBuffer, 256, "Aтpибyты: '%s'\nГрyппa: %s\nИcтeкaeт: Hикoгдa\n", g_sVipFlags[client][0], g_sVipFlags[client][4]);
				}
			}
			else
			{
				if (g_sVipFlags[client][5][0])
				{
					Format(sBuffer, 256, "Aтpибyты: '%s'\nФлaги: %s\nИcтeкaeт: %s\n", g_sVipFlags[client][0], g_sVipFlags[client][1], g_sVipFlags[client][5]);
				}
				Format(sBuffer, 256, "Aтpибyты: '%s'\nФлaги: %s\nИcтeкaeт: Hикoгдa\n", g_sVipFlags[client][0], g_sVipFlags[client][1]);
			}
		}
		else
		{
			if (g_sVipFlags[client][5][0])
			{
				Format(sBuffer, 256, "Aтpибyты: '%s'\nИcтeкaeт: %s\n", g_sVipFlags[client][0], g_sVipFlags[client][5]);
			}
			Format(sBuffer, 256, "Aтpибyты: '%s'\nИcтeкaeт: Hикoгдa\n", g_sVipFlags[client][0]);
		}
		AddMenuItem(hMenu, "groups", "Установить группу", 0);
		AddMenuItem(hMenu, "some", "Установить определенные", 0);
	}
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersTarget(Handle:hMenu, MenuAction:action, client, param)
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
				if (g_bAddBase[client])
				{
					Display_UsersAdd(client, false);
				}
				Display_UsersEditBase(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			GetMenuItem(hMenu, param, sBuffer, 128, 0, "", 0);
			if (strcmp(sBuffer, "groups", false))
			{
				if (strcmp(sBuffer, "some", false))
				{
					if (strcmp(sBuffer, "save", false))
					{
						if (strcmp(sBuffer, "nosave", false))
						{
							if (!(strcmp(sBuffer, "extend", false)))
							{
								Display_UsersTargetExtend(client);
							}
						}
						new i;
						while (i <= 38)
						{
							g_bPlayerVipEdit[client][i] = false;
							i++;
						}
						new i;
						while (i <= 5)
						{
							g_bPlayerCmdsEdit[client][i] = false;
							i++;
						}
						strcopy(g_sVipFlags[client][1], 256, g_sVipFlags[client][2]);
						Display_UsersTarget(client);
					}
					KvRewind(g_hKvUsers);
					if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], g_bAddBase[client]))
					{
						if (g_bAddBase[client])
						{
							KvSetString(g_hKvUsers, "name", g_sVipFlags[client][0]);
							if (g_iTargetTime[client])
							{
								Format(sBuffer, 128, "%i", g_iTargetTime[client]);
							}
							else
							{
								strcopy(sBuffer, 128, "0");
							}
							KvSetString(g_hKvUsers, "expires", sBuffer);
							PushArrayCell(g_hArrayUsersExpires, StringToInt(sBuffer, 10));
							PushArrayString(g_hArrayUsersPassword, "");
							KvGetString(g_hKvUsers, "group", sBuffer, 128, "none");
							if (strcmp(sBuffer, "none", false))
							{
								KvDeleteKey(g_hKvUsers, "group");
							}
							KvSetString(g_hKvUsers, "flags", g_sVipFlags[client][1]);
							PushArrayString(g_hArrayUsers, g_sVipFlags[client][3]);
							g_iArrayUsers += 1;
							Vip_Log("Админ %N (ID: %s) добавил нового VIP игрока %s (ID: %s) Флаги: %s", client, g_sClientAuth[client], g_sVipFlags[client][0], g_sVipFlags[client][3], g_sVipFlags[client][1]);
							VipPrint(client, enSound:0, "Флаги для %s установлены.", g_sVipFlags[client][0]);
							ResettingTheFlags(g_sVipFlags[client][3]);
							Display_UsersAdd(client, false);
						}
						else
						{
							KvGetString(g_hKvUsers, "group", sBuffer, 128, "none");
							if (strcmp(sBuffer, "none", false))
							{
								KvDeleteKey(g_hKvUsers, "group");
							}
							KvSetString(g_hKvUsers, "flags", g_sVipFlags[client][1]);
							Vip_Log("Админ %N (ID: %s) изменил VIP флаги на %s у игрока %s (ID: %s)", client, g_sClientAuth[client], g_sVipFlags[client][1], g_sVipFlags[client][0], g_sVipFlags[client][3]);
							VipPrint(client, enSound:0, "Флаги для %s установлены.", g_sVipFlags[client][0]);
							ResettingTheFlags(g_sVipFlags[client][3]);
							Display_UsersEditBase(client);
						}
						KvRewind(g_hKvUsers);
						new var1 = g_sUsersPath;
						KeyValuesToFile(g_hKvUsers, var1[0][var1]);
						new i;
						while (i <= 38)
						{
							g_bPlayerVipEdit[client][i] = false;
							i++;
						}
						new i;
						while (i <= 5)
						{
							g_bPlayerCmdsEdit[client][i] = false;
							i++;
						}
						strcopy(g_sVipFlags[client][0], 256, NULL_STRING);
						strcopy(g_sVipFlags[client][1], 256, NULL_STRING);
						strcopy(g_sVipFlags[client][2], 256, NULL_STRING);
						strcopy(g_sVipFlags[client][3], 256, NULL_STRING);
					}
					else
					{
						VipPrint(client, enSound:2, "Ошибка добавления!");
						Display_UsersAdd(client, false);
					}
					g_iTargetTime[client] = 0;
				}
				new i;
				while (i <= 38)
				{
					g_bPlayerVipEdit[client][i] = false;
					i++;
				}
				new i;
				while (i <= 5)
				{
					g_bPlayerCmdsEdit[client][i] = false;
					i++;
				}
				if (!g_bAddBase[client])
				{
					decl iBuffer[2];
					iBuffer[0] = strlen(g_sVipFlags[client][1]);
					if (iBuffer[0])
					{
						new i;
						while (iBuffer[0] + -1 >= i)
						{
							i++;
							Format(sBuffer, 128, "%c%c", g_sVipFlags[client][1][i], g_sVipFlags[client][1][i + 1]);
							if (GetTrieValue(g_hUsersFlagsTrie, sBuffer, iBuffer[1]))
							{
								g_bPlayerVipEdit[client][iBuffer[1]] = true;
							}
							if (GetTrieValue(g_hUsersCmdsFlagsTrie, sBuffer, iBuffer[1]))
							{
								g_bPlayerCmdsEdit[client][iBuffer[1]] = true;
							}
							i++;
						}
					}
				}
				Display_UsersTargetSome(client);
			}
			else
			{
				Display_UsersTargetGroups(client);
			}
		}
	}
	return 0;
}

public Display_UsersTargetExtend(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersTargetExtend, MenuAction:28);
	decl String:sBuffer[256];
	FormatTime(sBuffer, 256, "%H:%M:%S %d:%m:%Y", GetTime(438672));
	Format(sBuffer, 256, "Продлить время VIP для: %s\nТекущее время: %s", g_sVipFlags[client][0], sBuffer);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "0", "Постоянную", 0);
	AddMenuItem(hMenu, "30", "30 Минут", 0);
	AddMenuItem(hMenu, "60", "1 Час", 0);
	AddMenuItem(hMenu, "120", "2 Часа", 0);
	AddMenuItem(hMenu, "180", "3 Часа", 0);
	AddMenuItem(hMenu, "240", "4 Часа", 0);
	AddMenuItem(hMenu, "300", "5 Часов", 0);
	AddMenuItem(hMenu, "360", "6 Часов", 0);
	AddMenuItem(hMenu, "420", "7 Часов", 0);
	AddMenuItem(hMenu, "480", "8 Часов", 0);
	AddMenuItem(hMenu, "540", "9 Часов", 0);
	AddMenuItem(hMenu, "600", "10 Часов", 0);
	AddMenuItem(hMenu, "660", "11 Часов", 0);
	AddMenuItem(hMenu, "720", "12 Часов", 0);
	AddMenuItem(hMenu, "780", "13 Часов", 0);
	AddMenuItem(hMenu, "840", "14 Часов", 0);
	AddMenuItem(hMenu, "900", "15 Часов", 0);
	AddMenuItem(hMenu, "960", "16 Часов", 0);
	AddMenuItem(hMenu, "1020", "17 Часов", 0);
	AddMenuItem(hMenu, "1080", "18 Часов", 0);
	AddMenuItem(hMenu, "1140", "19 Часов", 0);
	AddMenuItem(hMenu, "1200", "20 Часов", 0);
	AddMenuItem(hMenu, "1260", "21 Час", 0);
	AddMenuItem(hMenu, "1320", "22 Часа", 0);
	AddMenuItem(hMenu, "1380", "23 Часа", 0);
	AddMenuItem(hMenu, "1440", "1 День", 0);
	AddMenuItem(hMenu, "2880", "2 Дня", 0);
	AddMenuItem(hMenu, "4320", "3 Дня", 0);
	AddMenuItem(hMenu, "5760", "4 Дня", 0);
	AddMenuItem(hMenu, "7200", "5 Дней", 0);
	AddMenuItem(hMenu, "8640", "6 Дней", 0);
	AddMenuItem(hMenu, "10080", "1 Неделю", 0);
	AddMenuItem(hMenu, "20160", "2 Недели", 0);
	AddMenuItem(hMenu, "30240", "3 Недели", 0);
	AddMenuItem(hMenu, "43829", "1 Месяц", 0);
	AddMenuItem(hMenu, "87658", "2 Месяца", 0);
	AddMenuItem(hMenu, "131487", "3 Месяца", 0);
	AddMenuItem(hMenu, "175316", "4 Месяца", 0);
	AddMenuItem(hMenu, "219145", "5 Месяцев", 0);
	AddMenuItem(hMenu, "262974", "6 Месяцев", 0);
	AddMenuItem(hMenu, "306803", "7 Месяцев", 0);
	AddMenuItem(hMenu, "350632", "8 Месяцев", 0);
	AddMenuItem(hMenu, "394461", "9 Месяцев", 0);
	AddMenuItem(hMenu, "438290", "10 Месяцев", 0);
	AddMenuItem(hMenu, "482119", "11 Месяцев", 0);
	AddMenuItem(hMenu, "525948", "1 Год", 0);
	AddMenuItem(hMenu, "1051896", "2 Года", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersTargetExtend(Handle:hMenu, MenuAction:action, client, param)
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
				Display_UsersTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new iBuffer;
			new iIndex = FindStringInArray(g_hArrayUsers, g_sVipFlags[client][3]);
			if (iIndex != -1)
			{
				new var2 = var1 + 4;
				GetMenuItem(hMenu, param, var1 + var1, 256, 0, var2 + var2, 256);
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], false))
				{
					iBuffer = StringToInt(var1 + var1, 10);
					if (iBuffer)
					{
						if (!g_iTargetTime[client])
						{
							g_iTargetTime[client] = GetTime(439796);
						}
						new var3 = g_iTargetTime[client];
						var3 = var3[iBuffer * 60];
					}
					else
					{
						g_iTargetTime[client] = 0;
					}
					KvSetNum(g_hKvUsers, "expires", g_iTargetTime[client]);
					SetArrayCell(g_hArrayUsersExpires, iIndex, g_iTargetTime[client], 0, false);
					if (g_iTargetTime[client])
					{
						FormatTime(g_sVipFlags[client][5], 256, "%H:%M:%S %d:%m:%Y", g_iTargetTime[client]);
					}
					else
					{
						strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
					}
					new var4 = var1 + 4;
					Vip_Log("Админ %N (ID: %s) продлил время на (%s) для '%s' (ID: %s)", client, g_sClientAuth[client], var4 + var4, g_sVipFlags[client][0], g_sVipFlags[client][3]);
					new var5 = var1 + 4;
					VipPrint(client, enSound:0, "Продление на %s для '%s' установлено.", var5 + var5, g_sVipFlags[client][0]);
					KvRewind(g_hKvUsers);
					new var6 = g_sUsersPath;
					KeyValuesToFile(g_hKvUsers, var6[0][var6]);
					if (strcmp(g_sVipFlags[client][3], g_sClientAuth[client], false))
					{
						ResettingTheFlags(g_sVipFlags[client][3]);
					}
					else
					{
						g_iUsersExpires[client] = g_iTargetTime[client];
					}
				}
				else
				{
					VipPrint(client, enSound:2, "Ошибка продления!");
				}
			}
			else
			{
				VipPrint(client, enSound:2, "Ошибка продления! '%s' в базе не найден.", g_sVipFlags[client][0]);
			}
			Display_UsersTarget(client);
		}
	}
	return 0;
}

public Display_UsersTargetGroups(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersTargetGroups, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "Группа для: %s", g_sVipFlags[client][0], client);
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
		VipPrint(client, enSound:2, "Ошибка! База групп пуста.");
		Display_UsersTarget(client);
	}
	return 0;
}

public MenuHandler_UsersTargetGroups(Handle:hMenu, MenuAction:action, client, param)
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
				Display_UsersTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var2 + var2, 128, 0, "", 0);
			KvRewind(g_hKvUsers);
			if (KvJumpToKey(g_hKvUsers, g_sVipFlags[client][3], g_bAddBase[client]))
			{
				if (g_bAddBase[client])
				{
					KvSetString(g_hKvUsers, "name", g_sVipFlags[client][0]);
					if (g_iTargetTime[client])
					{
						Format(var1 + var1, 128, "%i", g_iTargetTime[client]);
					}
					else
					{
						strcopy(var1 + var1, 128, "0");
					}
					KvSetString(g_hKvUsers, "expires", var1 + var1);
					PushArrayString(g_hArrayUsers, g_sVipFlags[client][3]);
					PushArrayCell(g_hArrayUsersExpires, StringToInt(var1 + var1, 10));
					KvSetString(g_hKvUsers, "password", "");
					PushArrayString(g_hArrayUsersPassword, "");
					g_iArrayUsers += 1;
					KvGetString(g_hKvUsers, "flags", var1 + var1, 128, "none");
					if (strcmp(var1 + var1, "none", false))
					{
						KvDeleteKey(g_hKvUsers, "flags");
					}
					new var3 = var1 + 4;
					KvSetString(g_hKvUsers, "group", var3 + var3);
					new var4 = var1 + 4;
					Vip_Log("Админ %N (ID: %s) добавил нового VIP игрока %s (ID: %s) Группа: %s", client, g_sClientAuth[client], g_sVipFlags[client][0], g_sVipFlags[client][3], var4 + var4);
					new var5 = var1 + 4;
					VipPrint(client, enSound:0, "Группа %s для %s установлена.", var5 + var5, g_sVipFlags[client][0]);
					ResettingTheFlags(g_sVipFlags[client][3]);
					Display_UsersAdd(client, false);
				}
				else
				{
					KvGetString(g_hKvUsers, "flags", var1 + var1, 128, "none");
					if (strcmp(var1 + var1, "none", false))
					{
						KvDeleteKey(g_hKvUsers, "flags");
					}
					new var6 = var1 + 4;
					KvSetString(g_hKvUsers, "group", var6 + var6);
					new var7 = var1 + 4;
					Vip_Log("Админ %N (ID: %s) поменял VIP группу на %s у %s (ID: %s)", client, g_sClientAuth[client], var7 + var7, g_sVipFlags[client][0], g_sVipFlags[client][3]);
					new var8 = var1 + 4;
					VipPrint(client, enSound:0, "Группа %s для %s установлена.", var8 + var8, g_sVipFlags[client][0]);
					ResettingTheFlags(g_sVipFlags[client][3]);
					Display_UsersEditBase(client);
				}
				KvRewind(g_hKvUsers);
				new var9 = g_sUsersPath;
				KeyValuesToFile(g_hKvUsers, var9[0][var9]);
			}
			else
			{
				VipPrint(client, enSound:2, "Ошибка добавления!");
				if (g_bAddBase[client])
				{
					Display_UsersAdd(client, false);
				}
				Display_UsersEditBase(client);
			}
			strcopy(g_sVipFlags[client][0], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][1], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][2], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][3], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][4], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
			g_iTargetTime[client] = 0;
		}
	}
	return 0;
}

public Display_UsersTargetSome(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersTargetSome, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Атрибуты для: %s", g_sVipFlags[client][0]);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "", "Управление игроками", 0);
	AddMenuItem(hMenu, "", "VIP Артибуты", 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersTargetSome(Handle:hMenu, MenuAction:action, client, param)
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
				Display_UsersTarget(client);
			}
		}
		if (action == MenuAction:4)
		{
			if (!param)
			{
				Display_UsersPlayerCommands(client, 0);
			}
			if (param == 1)
			{
				Display_UsersVipAttributes(client, 0);
			}
		}
	}
	return 0;
}

public Display_UsersVipAttributes(client, position)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersVipAttributes, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "VIP Артибуты для: %s", g_sVipFlags[client][0]);
	SetMenuTitle(hMenu, sBuffer);
	if (g_bPlayerVipEdit[client][0])
	{
		Format(sBuffer, 128, "Чaт [X]");
	}
	else
	{
		Format(sBuffer, 128, "Чaт [ ]");
	}
	AddMenuItem(hMenu, "0a", sBuffer, 0);
	if (g_bPlayerVipEdit[client][1])
	{
		Format(sBuffer, 128, "Moдeли [X]");
	}
	else
	{
		Format(sBuffer, 128, "Moдeли [ ]");
	}
	AddMenuItem(hMenu, "0b", sBuffer, 0);
	if (g_bPlayerVipEdit[client][2])
	{
		Format(sBuffer, 128, "Иммунитeт [X]");
	}
	else
	{
		Format(sBuffer, 128, "Иммунитeт [ ]");
	}
	AddMenuItem(hMenu, "0c", sBuffer, 0);
	if (g_bPlayerVipEdit[client][31])
	{
		Format(sBuffer, 128, "Иммунитeт oт зaпpeтa opужия [X]");
	}
	else
	{
		Format(sBuffer, 128, "Иммунитeт oт зaпpeтa opужия [ ]");
	}
	AddMenuItem(hMenu, "1f", sBuffer, 0);
	if (g_bPlayerVipEdit[client][3])
	{
		Format(sBuffer, 128, "Вынocливocть [X]");
	}
	else
	{
		Format(sBuffer, 128, "Вынocливocть [ ]");
	}
	AddMenuItem(hMenu, "0d", sBuffer, 0);
	if (g_bPlayerVipEdit[client][4])
	{
		Format(sBuffer, 128, "Дeньги [X]");
	}
	else
	{
		Format(sBuffer, 128, "Дeньги [ ]");
	}
	AddMenuItem(hMenu, "0e", sBuffer, 0);
	if (g_bPlayerVipEdit[client][5])
	{
		Format(sBuffer, 128, "Aвтoмaтичecкaя уcтaнoвкa opужия [X]");
	}
	else
	{
		Format(sBuffer, 128, "Aвтoмaтичecкaя уcтaнoвкa opужия [ ]");
	}
	AddMenuItem(hMenu, "0f", sBuffer, 0);
	if (g_bPlayerVipEdit[client][6])
	{
		Format(sBuffer, 128, "Пoкaз уpoнa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пoкaз уpoнa [ ]");
	}
	AddMenuItem(hMenu, "0g", sBuffer, 0);
	if (g_bPlayerVipEdit[client][7])
	{
		Format(sBuffer, 128, "Aвтoглушитeль [X]");
	}
	else
	{
		Format(sBuffer, 128, "Aвтoглушитeль [ ]");
	}
	AddMenuItem(hMenu, "1e", sBuffer, 0);
	if (g_bPlayerVipEdit[client][8])
	{
		Format(sBuffer, 128, "Aнтифлeш пo кoмaндe [X]");
	}
	else
	{
		Format(sBuffer, 128, "Aнтифлeш пo кoмaндe [ ]");
	}
	AddMenuItem(hMenu, "0h", sBuffer, 0);
	if (g_bPlayerVipEdit[client][9])
	{
		Format(sBuffer, 128, "Пoлный Aнтифлeш [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пoлный Aнтифлeш [ ]");
	}
	AddMenuItem(hMenu, "0i", sBuffer, 0);
	if (g_iGame != GameType:2)
	{
		if (g_bPlayerVipEdit[client][24])
		{
			Format(sBuffer, 128, "Kлaн Тeг [X]");
		}
		else
		{
			Format(sBuffer, 128, "Kлaн Тeг [ ]");
		}
		AddMenuItem(hMenu, "0x", sBuffer, 0);
	}
	if (g_bPlayerVipEdit[client][26])
	{
		Format(sBuffer, 128, "Блoк уpoнa oт пaдeния [X]");
	}
	else
	{
		Format(sBuffer, 128, "Блoк уpoнa oт пaдeния [ ]");
	}
	AddMenuItem(hMenu, "0z", sBuffer, 0);
	if (g_bPlayerVipEdit[client][23])
	{
		Format(sBuffer, 128, "Пepeмeщeниe мeжду кoмaнд [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пepeмeщeниe мeжду кoмaнд [ ]");
	}
	AddMenuItem(hMenu, "0w", sBuffer, 0);
	if (g_bPlayerVipEdit[client][10])
	{
		Format(sBuffer, 128, "Пoвpeждeний пo кoмaндe [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пoвpeждeний пo кoмaндe [ ]");
	}
	AddMenuItem(hMenu, "0j", sBuffer, 0);
	if (g_bPlayerVipEdit[client][11])
	{
		Format(sBuffer, 128, "Прыжки BunnyHop [X]");
	}
	else
	{
		Format(sBuffer, 128, "Прыжки BunnyHop [ ]");
	}
	AddMenuItem(hMenu, "0k", sBuffer, 0);
	if (g_bPlayerVipEdit[client][12])
	{
		Format(sBuffer, 128, "Возрождение с С4 [X]");
	}
	else
	{
		Format(sBuffer, 128, "Возрождение с С4 [ ]");
	}
	AddMenuItem(hMenu, "0l", sBuffer, 0);
	if (g_bPlayerVipEdit[client][13])
	{
		Format(sBuffer, 128, "Уcилeниe уpoнa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Уcилeниe уpoнa [ ]");
	}
	AddMenuItem(hMenu, "0m", sBuffer, 0);
	if (g_bPlayerVipEdit[client][14])
	{
		Format(sBuffer, 128, "Регенерация HP [X]");
	}
	else
	{
		Format(sBuffer, 128, "Регенерация HP [ ]");
	}
	AddMenuItem(hMenu, "0n", sBuffer, 0);
	if (g_bPlayerVipEdit[client][15])
	{
		Format(sBuffer, 128, "Мeдик пo кoмaндe [X]");
	}
	else
	{
		Format(sBuffer, 128, "Мeдик пo кoмaндe [ ]");
	}
	AddMenuItem(hMenu, "0o", sBuffer, 0);
	if (g_bPlayerVipEdit[client][16])
	{
		Format(sBuffer, 128, "Пoвpeждeния oт cвoeй грaнaты [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пoвpeждeния oт cвoeй грaнaты [ ]");
	}
	AddMenuItem(hMenu, "0p", sBuffer, 0);
	if (g_bPlayerVipEdit[client][17])
	{
		Format(sBuffer, 128, "Возрождение с HP [X]");
	}
	else
	{
		Format(sBuffer, 128, "Возрождение с HP [ ]");
	}
	AddMenuItem(hMenu, "0q", sBuffer, 0);
	if (g_bPlayerVipEdit[client][18])
	{
		Format(sBuffer, 128, "Установка cкорости [X]");
	}
	else
	{
		Format(sBuffer, 128, "Установка cкорости [ ]");
	}
	AddMenuItem(hMenu, "0r", sBuffer, 0);
	if (g_bPlayerVipEdit[client][19])
	{
		Format(sBuffer, 128, "Установка гравитации [X]");
	}
	else
	{
		Format(sBuffer, 128, "Установка гравитации [ ]");
	}
	AddMenuItem(hMenu, "0s", sBuffer, 0);
	if (g_bPlayerVipEdit[client][20])
	{
		Format(sBuffer, 128, "Xвocт гpaнaт [X]");
	}
	else
	{
		Format(sBuffer, 128, "Xвocт гpaнaт [ ]");
	}
	AddMenuItem(hMenu, "0t", sBuffer, 0);
	if (g_bPlayerVipEdit[client][21])
	{
		Format(sBuffer, 128, "Возрождение [X]");
	}
	else
	{
		Format(sBuffer, 128, "Возрождение [ ]");
	}
	AddMenuItem(hMenu, "0u", sBuffer, 0);
	if (g_bPlayerVipEdit[client][22])
	{
		Format(sBuffer, 128, "Пoнижeнный уpoн пpoтивникa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Пoнижeнный уpoн пpoтивникa [ ]");
	}
	AddMenuItem(hMenu, "0v", sBuffer, 0);
	if (g_bPlayerVipEdit[client][25])
	{
		Format(sBuffer, 128, "Звук cepдцeбиeния [X]");
	}
	else
	{
		Format(sBuffer, 128, "Звук cepдцeбиeния [ ]");
	}
	AddMenuItem(hMenu, "0y", sBuffer, 0);
	if (g_bPlayerVipEdit[client][27])
	{
		Format(sBuffer, 128, "Уcтaнoвкa opужия [X]");
	}
	else
	{
		Format(sBuffer, 128, "Уcтaнoвкa opужия [ ]");
	}
	AddMenuItem(hMenu, "1a", sBuffer, 0);
	if (g_bPlayerVipEdit[client][28])
	{
		Format(sBuffer, 128, "Бecкoнeчныe пaтpoны [X]");
	}
	else
	{
		Format(sBuffer, 128, "Бecкoнeчныe пaтpoны [ ]");
	}
	AddMenuItem(hMenu, "1b", sBuffer, 0);
	if (g_bPlayerVipEdit[client][29])
	{
		Format(sBuffer, 128, "Бpocaть нoжи и гpaнaты [X]");
	}
	else
	{
		Format(sBuffer, 128, "Бpocaть нoжи и гpaнaты [ ]");
	}
	AddMenuItem(hMenu, "1c", sBuffer, 0);
	if (g_bPlayerVipEdit[client][30])
	{
		Format(sBuffer, 128, "Pacтвopять тeлo пocлe cмepти [X]");
	}
	else
	{
		Format(sBuffer, 128, "Pacтвopять тeлo пocлe cмepти [ ]");
	}
	AddMenuItem(hMenu, "1d", sBuffer, 0);
	if (g_bPlayerVipEdit[client][32])
	{
		Format(sBuffer, 128, "Цвeтa opужия [X]");
	}
	else
	{
		Format(sBuffer, 128, "Цвeтa opужия [ ]");
	}
	AddMenuItem(hMenu, "1g", sBuffer, 0);
	if (g_bPlayerVipEdit[client][33])
	{
		Format(sBuffer, 128, "Эффeкт пpи убийcтвe [X]");
	}
	else
	{
		Format(sBuffer, 128, "Эффeкт пpи убийcтвe [ ]");
	}
	AddMenuItem(hMenu, "1h", sBuffer, 0);
	if (g_bPlayerVipEdit[client][34])
	{
		Format(sBuffer, 128, "Moдeли гpaнaт [X]");
	}
	else
	{
		Format(sBuffer, 128, "Moдeли гpaнaт [ ]");
	}
	AddMenuItem(hMenu, "1i", sBuffer, 0);
	if (g_bPlayerVipEdit[client][35])
	{
		Format(sBuffer, 128, "Oгнeннaя гpaнaтa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Oгнeннaя гpaнaтa [ ]");
	}
	AddMenuItem(hMenu, "1j", sBuffer, 0);
	if (g_bPlayerVipEdit[client][36])
	{
		Format(sBuffer, 128, "Oгнeннaя и пoджигaющaя гpaнaтa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Oгнeннaя и пoджигaющaя гpaнaтa [ ]");
	}
	AddMenuItem(hMenu, "1k", sBuffer, 0);
	if (g_bPlayerVipEdit[client][37])
	{
		Format(sBuffer, 128, "Bpeмeннoe ycкopeниe пpи ypoнe [X]");
	}
	else
	{
		Format(sBuffer, 128, "Bpeмeннoe ycкopeниe пpи ypoнe [ ]");
	}
	AddMenuItem(hMenu, "1l", sBuffer, 0);
	if (g_iGame != GameType:3)
	{
		if (g_bPlayerVipEdit[client][38])
		{
			Format(sBuffer, 128, "Oзвучивaть низкий уpoвeнь пaтpoнoв [X]");
		}
		else
		{
			Format(sBuffer, 128, "Oзвучивaть низкий уpoвeнь пaтpoнoв [ ]");
		}
		AddMenuItem(hMenu, "1m", sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenuAtItem(hMenu, client, position, 0);
	return 0;
}

public MenuHandler_UsersVipAttributes(Handle:hMenu, MenuAction:action, client, param)
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
				Display_UsersTargetSome(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[8];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 8, 0, "", 0);
			if (GetTrieValue(g_hUsersFlagsTrie, sBuffer, iBuffer))
			{
				if (g_bPlayerVipEdit[client][iBuffer])
				{
					ReplaceString(g_sVipFlags[client][1], 256, sBuffer, "", true);
					g_bPlayerVipEdit[client][iBuffer] = false;
				}
				Format(g_sVipFlags[client][1], 256, "%s%s", g_sVipFlags[client][1], sBuffer);
				g_bPlayerVipEdit[client][iBuffer] = true;
			}
			Display_UsersVipAttributes(client, GetMenuSelectionPosition());
		}
	}
	return 0;
}

public Display_UsersPlayerCommands(client, position)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersPlayerCommands, MenuAction:28);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Управление игроками для: %s", g_sVipFlags[client][0]);
	SetMenuTitle(hMenu, sBuffer);
	if (g_bPlayerCmdsEdit[client][0])
	{
		Format(sBuffer, 128, "Kикнуть игpoкa [X]");
	}
	else
	{
		Format(sBuffer, 128, "Kикнуть игpoкa [ ]");
	}
	AddMenuItem(hMenu, "2a", sBuffer, 0);
	if (g_bPlayerCmdsEdit[client][1])
	{
		Format(sBuffer, 128, "3aбaнить игpoкa [X]");
	}
	else
	{
		Format(sBuffer, 128, "3aбaнить игpoкa [ ]");
	}
	AddMenuItem(hMenu, "2b", sBuffer, 0);
	if (g_bPlayerCmdsEdit[client][2])
	{
		Format(sBuffer, 128, "3aглушить игpoкa [X]");
	}
	else
	{
		Format(sBuffer, 128, "3aглушить игpoкa [ ]");
	}
	AddMenuItem(hMenu, "2c", sBuffer, 0);
	if (g_bPlayerCmdsEdit[client][3])
	{
		Format(sBuffer, 128, "Бpocaть opужия живых [X]");
	}
	else
	{
		Format(sBuffer, 128, "Бpocaть opужия живых [ ]");
	}
	AddMenuItem(hMenu, "2d", sBuffer, 0);
	if (g_bPlayerCmdsEdit[client][4])
	{
		Format(sBuffer, 128, "Упpaвлять фaнapикoм живых [X]");
	}
	else
	{
		Format(sBuffer, 128, "Упpaвлять фaнapикoм живых [ ]");
	}
	AddMenuItem(hMenu, "2e", sBuffer, 0);
	if (g_bPlayerCmdsEdit[client][5])
	{
		Format(sBuffer, 128, "Pиcoвaть cпpeями живых [X]");
	}
	else
	{
		Format(sBuffer, 128, "Pиcoвaть cпpeями живых [ ]");
	}
	AddMenuItem(hMenu, "2f", sBuffer, 0);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenuAtItem(hMenu, client, position, 0);
	return 0;
}

public MenuHandler_UsersPlayerCommands(Handle:hMenu, MenuAction:action, client, param)
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
				Display_UsersTargetSome(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[8];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 8, 0, "", 0);
			if (GetTrieValue(g_hUsersCmdsFlagsTrie, sBuffer, iBuffer))
			{
				if (g_bPlayerCmdsEdit[client][iBuffer])
				{
					ReplaceString(g_sVipFlags[client][1], 256, sBuffer, "", true);
					g_bPlayerCmdsEdit[client][iBuffer] = false;
				}
				Format(g_sVipFlags[client][1], 256, "%s%s", g_sVipFlags[client][1], sBuffer);
				g_bPlayerCmdsEdit[client][iBuffer] = true;
			}
			Display_UsersPlayerCommands(client, GetMenuSelectionPosition());
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
		Vip_ErrorLog("Delete file '%s' Error!", sSocketBuffer[1]);
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
				Vip_ErrorLog("Delete file '%s' Error", var11[0][var11]);
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
				new var16 = sSocketBuffer;
				GetPluginFilename(GetMyHandle(), var16[0][var16], 256);
				new var17 = sSocketBuffer;
				new var18 = sSocketBuffer;
				var17[0][var17][strlen(var18[0][var18]) + -4] = MissingTAG:0;
				new var19 = sSocketBuffer;
				InsertServerCommand("sm plugins reload %s", var19[0][var19]);
			}
			new var20 = g_iCountFile;
			var20++;
			GetArrayString(g_hArrayList, var20[0], sSocketBuffer[1], 256);
			hBuffer = SocketCreate(SocketType:1, OnSocketError);
			SocketSetArg(hBuffer, hFile);
			SocketConnect(hBuffer, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "update.sourcetm.com", 80);
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
			if (strcmp(var6[0][var6], "beta_0.0.5", false))
			{
				new var7 = sSocketBuffer;
				if (strcmp(var7[0][var7], "Error", false))
				{
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
				g_bBetaTest = false;
				CloseHandle(hBuffer);
				Vip_ErrorLog("Error! File %s 'Socket_Info' key Version: 'Error'", sSocketBuffer[1]);
				return 0;
			}
			else
			{
				bUpdate = false;
			}
			CloseHandle(hBuffer);
			new var3;
			if (FileExists(sSocketBuffer[1], false) && !DeleteFile(sSocketBuffer[1]))
			{
				g_bBetaTest = false;
				Vip_ErrorLog("Delete file '%s' Error!", sSocketBuffer[1]);
				ClearArray(g_hArrayList);
				return 0;
			}
			if (bUpdate)
			{
				new var11;
				BuildPath(PathType:0, sSocketBuffer[1], 256, "data/vip/old");
				if (!DirExists(sSocketBuffer[1]))
				{
					CreateDirectory(sSocketBuffer[1], 511);
				}
				BuildPath(PathType:0, sSocketBuffer[1], 256, "data/vip");
				hBuffer = OpenDirectory(sSocketBuffer[1]);
				while (ReadDirEntry(hBuffer, var11 + var11, 256, 0))
				{
					new var4;
					if (!(StrContains(var11 + var11, ".", true) == -1 || strcmp(var11 + var11, "..", false)))
					{
						if (strlen(var11 + var11) > 1)
						{
							new var12 = var11 + 4;
							Format(var12 + var12, 256, "%s/old/%s", sSocketBuffer[1], var11 + var11);
							Format(var11 + var11, 256, "%s/%s", sSocketBuffer[1], var11 + var11);
							new var13 = var11 + 4;
							if (FileExists(var13 + var13, false))
							{
								new var14 = var11 + 4;
								DeleteFile(var14 + var14);
							}
							new var15 = var11 + 4;
							RenameFile(var15 + var15, var11 + var11);
							DeleteFile(var11 + var11);
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
		CloseHandle(hBuffer);
		if (GetTime(444604) < 1520046183)
		{
			if (!g_bBetaTest)
			{
				g_bBetaTest = true;
				OnConfigsExecuted();
			}
			return 0;
		}
		g_bBetaTest = false;
		Vip_ErrorLog("Error! File %s 'Socket_Info'", sSocketBuffer[1]);
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
			if (GetTime(444916) < 1520046183)
			{
				g_bBetaTest = true;
				OnConfigsExecuted();
			}
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
	new var1;
	new var2;
	var1 = ExplodeString(path, "/", var2, 16, 64, false) + -1;
	if (strcmp(var2 + var2, "Path_SM", false))
	{
		new var4 = sSocketBuffer;
		var4[0][var4] = MissingTAG:0;
	}
	else
	{
		new var3 = sSocketBuffer;
		BuildPath(PathType:0, var3[0][var3], 256, "");
	}
	new i = 1;
	while (i < var1)
	{
		new var5 = sSocketBuffer;
		new var6 = sSocketBuffer;
		Format(var6[0][var6], 256, "%s%s/", var5[0][var5], var2[i]);
		new var7 = sSocketBuffer;
		if (!DirExists(var7[0][var7]))
		{
			new var8 = sSocketBuffer;
			CreateDirectory(var8[0][var8], 511);
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
	decl String:sBuffer[256];
	new iTemp;
	KvRewind(g_hKvUsersSettings);
	if (KvJumpToKey(g_hKvUsersSettings, g_sClientAuth[client], false))
	{
		new var1;
		if (g_bPlayerVip[client][0] && KvJumpToKey(g_hKvUsersSettings, "chat", false))
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "enable", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][0] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "tag", sBuffer, 256, "none");
			new var2;
			if (strlen(sBuffer) > 0 && strcmp(sBuffer, "none", false))
			{
				if (g_bUsersAdmin[client])
				{
					strcopy(g_sUsersChatTag[client], 32, sBuffer);
				}
				if (g_iUsersChatTagsArray != -1)
				{
					decl String:sTag[64];
					new i;
					while (i <= g_iUsersChatTagsArray)
					{
						GetArrayString(g_hChatTagsArray, i, sTag, 64);
						if (!(strcmp(sBuffer, sTag, false)))
						{
							strcopy(g_sUsersChatTag[client], 32, sBuffer);
						}
						i++;
					}
				}
			}
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][1])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "models", false))
			{
				iTemp = KvGetNum(g_hKvUsersSettings, "setup", -1);
				if (iTemp == -1)
				{
					if (g_iArrayModelsT != -1)
					{
						GetArrayString(g_hArrayModelsPathT, 0, g_sUsersModelsT[client], 256);
						if (g_iGame == GameType:3)
						{
							GetArrayString(g_hArrayModelsArmsPathT, 0, g_sUsersModelsArmsT[client], 256);
						}
						g_bUsersModelsT[client] = 1;
					}
					if (g_iArrayModelsCT != -1)
					{
						GetArrayString(g_hArrayModelsPathCT, 0, g_sUsersModelsCT[client], 256);
						if (g_iGame == GameType:3)
						{
							GetArrayString(g_hArrayModelsArmsPathCT, 0, g_sUsersModelsArmsCT[client], 256);
						}
						g_bUsersModelsCT[client] = 1;
					}
				}
				else
				{
					g_iPlayerVip[client][1] = iTemp;
					if (iTemp)
					{
						if (g_iArrayModelsT != -1)
						{
							if (g_iGame == GameType:3)
							{
								decl String:sArm[256];
								KvGetString(g_hKvUsersSettings, "modelt", sBuffer, 256, "none");
								KvGetString(g_hKvUsersSettings, "modelarmt", sArm, 256, "none");
								iTemp = FindStringInArray(g_hArrayModelsT, sBuffer);
								new var3;
								if (iTemp == -1 || FindStringInArray(g_hArrayModelsArmsT, sArm) == -1)
								{
									GetArrayString(g_hArrayModelsPathT, 0, g_sUsersModelsT[client], 256);
									GetArrayString(g_hArrayModelsArmsPathT, 0, g_sUsersModelsArmsT[client], 256);
								}
								else
								{
									g_iUsersModelsT[client] = iTemp;
									GetArrayString(g_hArrayModelsPathT, iTemp, g_sUsersModelsT[client], 256);
									GetArrayString(g_hArrayModelsArmsPathT, iTemp, g_sUsersModelsArmsT[client], 256);
								}
							}
							else
							{
								KvGetString(g_hKvUsersSettings, "modelt", sBuffer, 256, "none");
								iTemp = FindStringInArray(g_hArrayModelsT, sBuffer);
								if (iTemp == -1)
								{
									GetArrayString(g_hArrayModelsPathT, 0, g_sUsersModelsT[client], 256);
								}
								g_iUsersModelsT[client] = iTemp;
								GetArrayString(g_hArrayModelsPathT, iTemp, g_sUsersModelsT[client], 256);
							}
							g_bUsersModelsT[client] = 1;
						}
						if (g_iArrayModelsCT != -1)
						{
							if (g_iGame == GameType:3)
							{
								decl String:sArm[256];
								KvGetString(g_hKvUsersSettings, "modelct", sBuffer, 256, "none");
								KvGetString(g_hKvUsersSettings, "modelarmct", sArm, 256, "none");
								iTemp = FindStringInArray(g_hArrayModelsCT, sBuffer);
								new var4;
								if (iTemp == -1 || FindStringInArray(g_hArrayModelsArmsCT, sArm) == -1)
								{
									GetArrayString(g_hArrayModelsPathCT, 0, g_sUsersModelsCT[client], 256);
									GetArrayString(g_hArrayModelsArmsPathCT, 0, g_sUsersModelsArmsCT[client], 256);
								}
								else
								{
									g_iUsersModelsCT[client] = iTemp;
									GetArrayString(g_hArrayModelsPathCT, iTemp, g_sUsersModelsCT[client], 256);
									GetArrayString(g_hArrayModelsArmsPathCT, iTemp, g_sUsersModelsArmsCT[client], 256);
								}
							}
							else
							{
								KvGetString(g_hKvUsersSettings, "modelct", sBuffer, 256, "none");
								iTemp = FindStringInArray(g_hArrayModelsCT, sBuffer);
								if (iTemp == -1)
								{
									GetArrayString(g_hArrayModelsPathCT, 0, g_sUsersModelsCT[client], 256);
								}
								g_iUsersModelsCT[client] = iTemp;
								GetArrayString(g_hArrayModelsPathCT, iTemp, g_sUsersModelsCT[client], 256);
							}
							g_bUsersModelsCT[client] = 1;
						}
					}
				}
				KvGoBack(g_hKvUsersSettings);
			}
			if (g_iArrayModelsT != -1)
			{
				GetArrayString(g_hArrayModelsPathT, 0, g_sUsersModelsT[client], 256);
				if (g_iGame == GameType:3)
				{
					GetArrayString(g_hArrayModelsArmsPathT, 0, g_sUsersModelsArmsT[client], 256);
				}
				g_bUsersModelsT[client] = 1;
			}
			if (g_iArrayModelsCT != -1)
			{
				GetArrayString(g_hArrayModelsPathCT, 0, g_sUsersModelsCT[client], 256);
				if (g_iGame == GameType:3)
				{
					GetArrayString(g_hArrayModelsArmsPathCT, iTemp, g_sUsersModelsArmsCT[client], 256);
				}
				g_bUsersModelsCT[client] = 1;
			}
		}
		if (g_bPlayerVip[client][2])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "immunity", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][2] = iTemp;
			}
		}
		if (g_bPlayerVip[client][31])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "weaponrestrict", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][31] = iTemp;
			}
		}
		if (g_bPlayerVip[client][3])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "stamina", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][3] = iTemp;
			}
		}
		if (g_bPlayerVip[client][4])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "spawncash", -1);
			if (iTemp != -1)
			{
				if (iTemp > g_iCashMax)
				{
					g_iPlayerVip[client][4] = g_iCashMax;
				}
				g_iPlayerVip[client][4] = iTemp;
			}
		}
		new var5;
		if (g_bPlayerVip[client][5] && KvJumpToKey(g_hKvUsersSettings, "spawnweapon", false))
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "setup", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][5] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "weaponprimaryt", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponPrimaryT[client] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "weaponnameprimaryt", sBuffer, 256, "none");
			if (FindStringInArray(g_hUsersWeaponArrayPrimary, sBuffer) != -1)
			{
				strcopy(g_sUsersWeaponPrimaryT[client], 32, sBuffer);
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "weaponsecondaryt", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponSecondaryT[client] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "weaponnamesecondaryt", sBuffer, 256, "none");
			if (FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
			{
				strcopy(g_sUsersWeaponSecondaryT[client], 32, sBuffer);
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "weaponprimaryct", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponPrimaryCT[client] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "weaponnameprimaryct", sBuffer, 256, "none");
			if (FindStringInArray(g_hUsersWeaponArrayPrimary, sBuffer) != -1)
			{
				strcopy(g_sUsersWeaponPrimaryCT[client], 32, sBuffer);
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "weaponsecondaryct", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponSecondaryCT[client] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "weaponnamesecondaryct", sBuffer, 256, "none");
			if (FindStringInArray(g_hUsersWeaponArrayPistols, sBuffer) != -1)
			{
				strcopy(g_sUsersWeaponSecondaryCT[client], 32, sBuffer);
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "knife", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponKnife[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "assaultsuit", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponVestHelm[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "defuser", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponDefuser[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "nvgs", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponNvgs[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "grenades", -1);
			if (iTemp != -1)
			{
				g_bUsersWeaponGrenades[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "hegrenade", -1);
			new var6;
			if (iTemp != -1 && iTemp <= g_iUsersWeaponMaxHeGrenade)
			{
				g_iUsersWeaponHeGrenade[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "flashbang", -1);
			new var7;
			if (iTemp != -1 && iTemp <= g_iUsersWeaponMaxFlashBang)
			{
				g_iUsersWeaponFlashBang[client] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "smokegrenade", -1);
			new var8;
			if (iTemp != -1 && iTemp <= g_iUsersWeaponMaxSmokeGrenade)
			{
				g_iUsersWeaponSmokeGrenade[client] = iTemp;
			}
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][6])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "showhurt", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][6] = iTemp;
			}
		}
		if (g_bPlayerVip[client][7])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "autosilencer", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][7] = iTemp;
			}
		}
		if (g_bPlayerVip[client][8])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "noteamflash", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][8] = iTemp;
			}
		}
		if (g_bPlayerVip[client][9])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "antiflash", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][9] = iTemp;
			}
		}
		new var9;
		if (g_iGame != GameType:2 && g_bPlayerVip[client][24] && KvJumpToKey(g_hKvUsersSettings, "clantag", false))
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "setup", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][24] = iTemp;
			}
			KvGetString(g_hKvUsersSettings, "tag", sBuffer, 256, "none");
			new var10;
			if (strlen(sBuffer) > 0 && strcmp(sBuffer, "none", false))
			{
				if (g_bUsersAdmin[client])
				{
					strcopy(g_sUsersClanTag[client], 32, sBuffer);
				}
				if (g_iUsersClanTags > -1)
				{
					decl String:sTag[32];
					new i;
					while (i <= g_iUsersClanTags)
					{
						GetArrayString(g_hUsersClanTagsArray, i, sTag, 32);
						if (!(strcmp(sBuffer, sTag, false)))
						{
							strcopy(g_sUsersClanTag[client], 32, sBuffer);
						}
						i++;
					}
				}
			}
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][23])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "changeteam", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][23] = iTemp;
			}
		}
		if (g_bPlayerVip[client][10])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "nofriendlyfire", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][10] = iTemp;
			}
		}
		if (g_bPlayerVip[client][11])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "bunnyhop", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][11] = iTemp;
			}
		}
		if (g_bPlayerVip[client][12])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "spawnc4", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][12] = iTemp;
			}
		}
		if (g_bPlayerVip[client][13])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "increasesdamage", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][13] = iTemp;
			}
		}
		if (g_bPlayerVip[client][14])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "regeneration", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][14] = iTemp;
			}
		}
		if (g_bPlayerVip[client][15])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "medic", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][15] = iTemp;
			}
		}
		if (g_bPlayerVip[client][16])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "nodamagemygrenades", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][16] = iTemp;
			}
		}
		if (g_bPlayerVip[client][17])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "spawnhealth", -1);
			if (iTemp != -1)
			{
				if (g_iMaxHealth >= iTemp)
				{
					g_iPlayerVip[client][17] = iTemp;
				}
				g_iPlayerVip[client][17] = g_iMaxHealth;
			}
		}
		if (g_bPlayerVip[client][18])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "spawnspeed", -1);
			if (iTemp != -1)
			{
				if (g_iMaxSpeed >= iTemp)
				{
					g_iPlayerVip[client][18] = iTemp;
				}
				g_iPlayerVip[client][18] = g_iMaxSpeed;
			}
		}
		if (g_bPlayerVip[client][19])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "gravity", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][19] = iTemp;
				new var11;
				if (g_iGravityOffset[client] > -1 && IsClientConnected(client) && IsClientInGame(client))
				{
					g_iClientTeam[client] = GetClientTeam(client);
					g_bPlayerAlive[client] = IsPlayerAlive(client);
					new var12;
					if (g_iClientTeam[client] > 1 && g_bPlayerAlive[client])
					{
						switch (iTemp)
						{
							case 1:
							{
								g_iPlayerVip[client][19] = 1;
								SetPlayerGravity(client, 4.0);
							}
							case 2:
							{
								g_iPlayerVip[client][19] = 2;
								SetPlayerGravity(client, 2.9);
							}
							case 3:
							{
								g_iPlayerVip[client][19] = 3;
								SetPlayerGravity(client, 1.8);
							}
							case 4:
							{
								g_iPlayerVip[client][19] = 4;
								SetPlayerGravity(client, 0.8);
							}
							case 5:
							{
								g_iPlayerVip[client][19] = 5;
								SetPlayerGravity(client, 0.4);
							}
							case 6:
							{
								g_iPlayerVip[client][19] = 6;
								SetPlayerGravity(client, 0.1);
							}
							default:
							{
								if (1065353216 != GetPlayerGravity(client))
								{
									SetPlayerGravity(client, 1.0);
								}
							}
						}
					}
				}
			}
		}
		if (g_bPlayerVip[client][20])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "tailgrenades", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][20] = iTemp;
			}
		}
		if (g_bPlayerVip[client][21])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "respawn", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][21] = iTemp;
			}
		}
		if (g_bPlayerVip[client][22])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "lowdamage", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][22] = iTemp;
			}
		}
		new var13;
		if (g_bPlayerVip[client][25] && KvJumpToKey(g_hKvUsersSettings, "heartbeat", false))
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "health", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][25] = iTemp;
			}
			iTemp = KvGetNum(g_hKvUsersSettings, "shaking", -1);
			if (iTemp != -1)
			{
				g_bUsersHeartShaking[client] = iTemp;
			}
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][26])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "nofalldamage", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][26] = iTemp;
			}
		}
		if (g_bPlayerVip[client][27])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "giveweapons", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][27] = iTemp;
			}
		}
		if (g_bPlayerVip[client][28])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "infiniteammo", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][28] = iTemp;
			}
		}
		if (g_bPlayerVip[client][29])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "dropweapons", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][29] = iTemp;
			}
		}
		if (g_bPlayerVip[client][30])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "dissolve", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][30] = iTemp;
			}
		}
		new var15;
		if (g_bSDKHooksLoaded && g_bColorWeapons && g_bPlayerVip[client][32] && (g_iWeaponColorsSizeT || g_iWeaponColorsSizeCT))
		{
			if (KvJumpToKey(g_hKvUsersSettings, "colorweapons", false))
			{
				iTemp = KvGetNum(g_hKvUsersSettings, "enable", -1);
				if (iTemp != -1)
				{
					if (iTemp)
					{
						if (g_iWeaponColorsSizeT)
						{
							iTemp = KvGetNum(g_hKvUsersSettings, "weapons_t", -1);
							if (iTemp != -1)
							{
								if (iTemp)
								{
									KvGetString(g_hKvUsersSettings, "color_t", sBuffer, 256, "#none");
									new var16;
									if (strlen(sBuffer) && strcmp(sBuffer, "#none", false))
									{
										iTemp = FindStringInArray(g_hArrayWeaponColorsNamesT, sBuffer);
										if (iTemp != -1)
										{
											GetArrayArray(g_hArrayWeaponColorsT, iTemp, g_iUsersWeaponColorsT[client], -1);
											strcopy(g_sUsersWeaponColorsNamesT[client], 256, sBuffer);
											g_bUsersWeaponColorsT[client] = 1;
										}
									}
								}
								g_bUsersWeaponColorsT[client] = 0;
							}
						}
						if (g_iWeaponColorsSizeCT)
						{
							iTemp = KvGetNum(g_hKvUsersSettings, "weapons_ct", -1);
							if (iTemp != -1)
							{
								if (iTemp)
								{
									KvGetString(g_hKvUsersSettings, "color_ct", sBuffer, 256, "#none");
									new var17;
									if (strlen(sBuffer) && strcmp(sBuffer, "#none", false))
									{
										iTemp = FindStringInArray(g_hArrayWeaponColorsNamesCT, sBuffer);
										if (iTemp != -1)
										{
											GetArrayArray(g_hArrayWeaponColorsCT, iTemp, g_iUsersWeaponColorsCT[client], -1);
											strcopy(g_sUsersWeaponColorsNamesCT[client], 256, sBuffer);
											g_bUsersWeaponColorsCT[client] = 1;
										}
									}
								}
								g_bUsersWeaponColorsCT[client] = 0;
							}
						}
					}
					g_iPlayerVip[client][32] = 0;
					g_bUsersWeaponColorsT[client] = 0;
					g_bUsersWeaponColorsCT[client] = 0;
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][33])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "killeffect", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][33] = iTemp;
			}
		}
		new var19;
		if (g_bPlayerVip[client][34] && (g_iGrenadeModelsSizeT || g_iGrenadeModelsSizeCT))
		{
			if (KvJumpToKey(g_hKvUsersSettings, "grenademodels", false))
			{
				iTemp = KvGetNum(g_hKvUsersSettings, "enable", -1);
				if (iTemp != -1)
				{
					if (iTemp)
					{
						if (g_iGrenadeModelsSizeT)
						{
							iTemp = KvGetNum(g_hKvUsersSettings, "grenade_t", -1);
							if (iTemp != -1)
							{
								if (iTemp)
								{
									KvGetString(g_hKvUsersSettings, "model_t", sBuffer, 256, "#none");
									new var20;
									if (strlen(sBuffer) && strcmp(sBuffer, "#none", false))
									{
										iTemp = FindStringInArray(g_hArrayGrenadeModelsNamesT, sBuffer);
										if (iTemp != -1)
										{
											GetArrayString(g_hArrayGrenadeModelsT, iTemp, g_sUsersGrenadeModelsT[client], 256);
											strcopy(g_sUsersGrenadeModelsNamesT[client], 256, sBuffer);
											g_bUsersGrenadeModelsT[client] = 1;
										}
									}
								}
								g_bUsersGrenadeModelsT[client] = 0;
							}
						}
						if (g_iGrenadeModelsSizeCT)
						{
							iTemp = KvGetNum(g_hKvUsersSettings, "grenade_ct", -1);
							if (iTemp != -1)
							{
								if (iTemp)
								{
									KvGetString(g_hKvUsersSettings, "model_ct", sBuffer, 256, "#none");
									new var21;
									if (strlen(sBuffer) && strcmp(sBuffer, "#none", false))
									{
										iTemp = FindStringInArray(g_hArrayGrenadeModelsNamesCT, sBuffer);
										if (iTemp != -1)
										{
											GetArrayString(g_hArrayGrenadeModelsCT, iTemp, g_sUsersGrenadeModelsCT[client], 256);
											strcopy(g_sUsersGrenadeModelsNamesCT[client], 256, sBuffer);
											g_bUsersGrenadeModelsCT[client] = 1;
										}
									}
								}
								g_bUsersGrenadeModelsCT[client] = 0;
							}
						}
						new var22;
						if (g_bUsersGrenadeModelsT[client] || g_bUsersGrenadeModelsCT[client])
						{
							g_iPlayerVip[client][34] = 1;
						}
					}
					g_iPlayerVip[client][34] = 0;
					g_bUsersGrenadeModelsT[client] = 0;
					g_bUsersGrenadeModelsCT[client] = 0;
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][35])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "firegrenade", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][35] = iTemp;
			}
		}
		if (g_bPlayerVip[client][36])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "firegrenadeburn", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][36] = iTemp;
			}
		}
		if (g_bPlayerVip[client][37])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "lossminispeed", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][37] = iTemp;
			}
		}
		if (g_bPlayerVip[client][38])
		{
			iTemp = KvGetNum(g_hKvUsersSettings, "lowammosound", -1);
			if (iTemp != -1)
			{
				g_iPlayerVip[client][38] = iTemp;
			}
		}
	}
	else
	{
		if (g_bPlayerVip[client][1])
		{
			if (g_iArrayModelsT != -1)
			{
				GetArrayString(g_hArrayModelsPathT, 0, g_sUsersModelsT[client], 256);
				if (g_iGame == GameType:3)
				{
					GetArrayString(g_hArrayModelsArmsPathT, 0, g_sUsersModelsArmsT[client], 256);
				}
				g_bUsersModelsT[client] = 1;
			}
			if (g_iArrayModelsCT != -1)
			{
				GetArrayString(g_hArrayModelsPathCT, 0, g_sUsersModelsCT[client], 256);
				if (g_iGame == GameType:3)
				{
					GetArrayString(g_hArrayModelsArmsPathCT, 0, g_sUsersModelsArmsCT[client], 256);
				}
				g_bUsersModelsCT[client] = 1;
			}
		}
	}
	return 0;
}

public UsersSettingsSave(client)
{
	decl String:sBuffer[64];
	strcopy(sBuffer, 64, g_sClientAuth[client]);
	KvRewind(g_hKvUsersSettings);
	if (KvJumpToKey(g_hKvUsersSettings, sBuffer, false))
	{
		KvDeleteThis(g_hKvUsersSettings);
		KvRewind(g_hKvUsersSettings);
	}
	if (KvJumpToKey(g_hKvUsersSettings, sBuffer, true))
	{
		if (g_bPlayerVip[client][0])
		{
			if (KvJumpToKey(g_hKvUsersSettings, "chat", true))
			{
				KvSetNum(g_hKvUsersSettings, "enable", g_iPlayerVip[client][0]);
				if (g_bUsersAdmin[client])
				{
					KvSetString(g_hKvUsersSettings, "tag", g_sUsersChatTag[client]);
				}
				else
				{
					if (g_iUsersChatTagsArray != -1)
					{
						new i;
						while (i <= g_iUsersChatTagsArray)
						{
							GetArrayString(g_hChatTagsArray, i, sBuffer, 64);
							if (!(strcmp(g_sUsersChatTag[client], sBuffer, false)))
							{
								KvSetString(g_hKvUsersSettings, "tag", g_sUsersChatTag[client]);
							}
							i++;
						}
					}
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		new var1;
		if (g_bPlayerVip[client][1] && KvJumpToKey(g_hKvUsersSettings, "models", true))
		{
			KvSetNum(g_hKvUsersSettings, "setup", g_iPlayerVip[client][1]);
			if (g_iPlayerVip[client][1])
			{
				if (g_iArrayModelsT != -1)
				{
					GetArrayString(g_hArrayModelsT, g_iUsersModelsT[client], sBuffer, 64);
					KvSetString(g_hKvUsersSettings, "modelt", sBuffer);
					if (g_iGame == GameType:3)
					{
						GetArrayString(g_hArrayModelsArmsT, g_iUsersModelsT[client], sBuffer, 64);
						KvSetString(g_hKvUsersSettings, "modelarmt", sBuffer);
					}
				}
				if (g_iArrayModelsCT != -1)
				{
					GetArrayString(g_hArrayModelsCT, g_iUsersModelsCT[client], sBuffer, 64);
					KvSetString(g_hKvUsersSettings, "modelct", sBuffer);
					if (g_iGame == GameType:3)
					{
						GetArrayString(g_hArrayModelsArmsCT, g_iUsersModelsCT[client], sBuffer, 64);
						KvSetString(g_hKvUsersSettings, "modelarmct", sBuffer);
					}
				}
			}
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][2])
		{
			KvSetNum(g_hKvUsersSettings, "immunity", g_iPlayerVip[client][2]);
		}
		if (g_bPlayerVip[client][31])
		{
			KvSetNum(g_hKvUsersSettings, "weaponrestrict", g_iPlayerVip[client][31]);
		}
		if (g_bPlayerVip[client][3])
		{
			KvSetNum(g_hKvUsersSettings, "stamina", g_iPlayerVip[client][3]);
		}
		if (g_bPlayerVip[client][4])
		{
			KvSetNum(g_hKvUsersSettings, "spawncash", g_iPlayerVip[client][4]);
		}
		new var2;
		if (g_bPlayerVip[client][5] && KvJumpToKey(g_hKvUsersSettings, "spawnweapon", true))
		{
			KvSetNum(g_hKvUsersSettings, "setup", g_iPlayerVip[client][5]);
			KvSetNum(g_hKvUsersSettings, "weaponprimaryt", g_bUsersWeaponPrimaryT[client]);
			KvSetString(g_hKvUsersSettings, "weaponnameprimaryt", g_sUsersWeaponPrimaryT[client]);
			KvSetNum(g_hKvUsersSettings, "weaponsecondaryt", g_bUsersWeaponSecondaryT[client]);
			KvSetString(g_hKvUsersSettings, "weaponnamesecondaryt", g_sUsersWeaponSecondaryT[client]);
			KvSetNum(g_hKvUsersSettings, "weaponprimaryct", g_bUsersWeaponPrimaryCT[client]);
			KvSetString(g_hKvUsersSettings, "weaponnameprimaryct", g_sUsersWeaponPrimaryCT[client]);
			KvSetNum(g_hKvUsersSettings, "weaponsecondaryct", g_bUsersWeaponSecondaryCT[client]);
			KvSetString(g_hKvUsersSettings, "weaponnamesecondaryct", g_sUsersWeaponSecondaryCT[client]);
			KvSetNum(g_hKvUsersSettings, "knife", g_bUsersWeaponKnife[client]);
			KvSetNum(g_hKvUsersSettings, "assaultsuit", g_bUsersWeaponVestHelm[client]);
			KvSetNum(g_hKvUsersSettings, "defuser", g_bUsersWeaponDefuser[client]);
			KvSetNum(g_hKvUsersSettings, "nvgs", g_bUsersWeaponNvgs[client]);
			KvSetNum(g_hKvUsersSettings, "grenades", g_bUsersWeaponGrenades[client]);
			KvSetNum(g_hKvUsersSettings, "hegrenade", g_iUsersWeaponHeGrenade[client]);
			KvSetNum(g_hKvUsersSettings, "flashbang", g_iUsersWeaponFlashBang[client]);
			KvSetNum(g_hKvUsersSettings, "smokegrenade", g_iUsersWeaponSmokeGrenade[client]);
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][6])
		{
			KvSetNum(g_hKvUsersSettings, "showhurt", g_iPlayerVip[client][6]);
		}
		if (g_bPlayerVip[client][7])
		{
			KvSetNum(g_hKvUsersSettings, "autosilencer", g_iPlayerVip[client][7]);
		}
		if (g_bPlayerVip[client][8])
		{
			KvSetNum(g_hKvUsersSettings, "noteamflash", g_iPlayerVip[client][8]);
		}
		if (g_bPlayerVip[client][9])
		{
			KvSetNum(g_hKvUsersSettings, "antiflash", g_iPlayerVip[client][9]);
		}
		if (g_iGame != GameType:2)
		{
			new var3;
			if (g_bPlayerVip[client][24] && KvJumpToKey(g_hKvUsersSettings, "clantag", true))
			{
				KvSetNum(g_hKvUsersSettings, "setup", g_iPlayerVip[client][24]);
				if (strcmp(g_sUsersClanTag[client], g_sClanTag, false))
				{
					KvSetString(g_hKvUsersSettings, "tag", g_sUsersClanTag[client]);
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][26])
		{
			KvSetNum(g_hKvUsersSettings, "nofalldamage", g_iPlayerVip[client][26]);
		}
		if (g_bPlayerVip[client][23])
		{
			KvSetNum(g_hKvUsersSettings, "changeteam", g_iPlayerVip[client][23]);
		}
		if (g_bPlayerVip[client][10])
		{
			KvSetNum(g_hKvUsersSettings, "nofriendlyfire", g_iPlayerVip[client][10]);
		}
		if (g_bPlayerVip[client][11])
		{
			KvSetNum(g_hKvUsersSettings, "bunnyhop", g_iPlayerVip[client][11]);
		}
		if (g_bPlayerVip[client][12])
		{
			KvSetNum(g_hKvUsersSettings, "spawnc4", g_iPlayerVip[client][12]);
		}
		if (g_bPlayerVip[client][13])
		{
			KvSetNum(g_hKvUsersSettings, "increasesdamage", g_iPlayerVip[client][13]);
		}
		if (g_bPlayerVip[client][14])
		{
			KvSetNum(g_hKvUsersSettings, "regeneration", g_iPlayerVip[client][14]);
		}
		if (g_bPlayerVip[client][15])
		{
			KvSetNum(g_hKvUsersSettings, "medic", g_iPlayerVip[client][15]);
		}
		if (g_bPlayerVip[client][16])
		{
			KvSetNum(g_hKvUsersSettings, "nodamagemygrenades", g_iPlayerVip[client][16]);
		}
		if (g_bPlayerVip[client][17])
		{
			KvSetNum(g_hKvUsersSettings, "spawnhealth", g_iPlayerVip[client][17]);
		}
		if (g_bPlayerVip[client][18])
		{
			KvSetNum(g_hKvUsersSettings, "spawnspeed", g_iPlayerVip[client][18]);
		}
		if (g_bPlayerVip[client][19])
		{
			KvSetNum(g_hKvUsersSettings, "gravity", g_iPlayerVip[client][19]);
		}
		if (g_bPlayerVip[client][20])
		{
			KvSetNum(g_hKvUsersSettings, "tailgrenades", g_iPlayerVip[client][20]);
		}
		if (g_bPlayerVip[client][21])
		{
			KvSetNum(g_hKvUsersSettings, "respawn", g_iPlayerVip[client][21]);
		}
		if (g_bPlayerVip[client][22])
		{
			KvSetNum(g_hKvUsersSettings, "lowdamage", g_iPlayerVip[client][22]);
		}
		new var4;
		if (g_bPlayerVip[client][25] && KvJumpToKey(g_hKvUsersSettings, "heartbeat", true))
		{
			KvSetNum(g_hKvUsersSettings, "health", g_iPlayerVip[client][25]);
			KvSetNum(g_hKvUsersSettings, "shaking", g_bUsersHeartShaking[client]);
			KvGoBack(g_hKvUsersSettings);
		}
		if (g_bPlayerVip[client][27])
		{
			KvSetNum(g_hKvUsersSettings, "giveweapons", g_iPlayerVip[client][27]);
		}
		if (g_bPlayerVip[client][28])
		{
			KvSetNum(g_hKvUsersSettings, "infiniteammo", g_iPlayerVip[client][28]);
		}
		if (g_bPlayerVip[client][29])
		{
			KvSetNum(g_hKvUsersSettings, "dropweapons", g_iPlayerVip[client][29]);
		}
		if (g_bPlayerVip[client][30])
		{
			KvSetNum(g_hKvUsersSettings, "dissolve", g_iPlayerVip[client][30]);
		}
		new var6;
		if (g_bSDKHooksLoaded && g_bColorWeapons && g_bPlayerVip[client][32] && (g_iWeaponColorsSizeT || g_iWeaponColorsSizeCT))
		{
			if (KvJumpToKey(g_hKvUsersSettings, "colorweapons", true))
			{
				KvSetNum(g_hKvUsersSettings, "enable", g_iPlayerVip[client][32]);
				if (g_iPlayerVip[client][32])
				{
					if (g_bUsersWeaponColorsT[client])
					{
						KvSetNum(g_hKvUsersSettings, "weapons_t", 1);
						KvSetString(g_hKvUsersSettings, "color_t", g_sUsersWeaponColorsNamesT[client]);
					}
					else
					{
						KvSetNum(g_hKvUsersSettings, "weapons_t", 0);
					}
					if (g_bUsersWeaponColorsCT[client])
					{
						KvSetNum(g_hKvUsersSettings, "weapons_ct", 1);
						KvSetString(g_hKvUsersSettings, "color_ct", g_sUsersWeaponColorsNamesCT[client]);
					}
					KvSetNum(g_hKvUsersSettings, "weapons_ct", 0);
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][33])
		{
			KvSetNum(g_hKvUsersSettings, "killeffect", g_iPlayerVip[client][33]);
		}
		new var8;
		if (g_bSDKHooksLoaded && g_bGrenadeModels && g_bPlayerVip[client][34] && (g_iGrenadeModelsSizeT || g_iGrenadeModelsSizeCT))
		{
			if (KvJumpToKey(g_hKvUsersSettings, "grenademodels", true))
			{
				KvSetNum(g_hKvUsersSettings, "enable", g_iPlayerVip[client][34]);
				if (g_iPlayerVip[client][34])
				{
					if (g_bUsersGrenadeModelsT[client])
					{
						KvSetNum(g_hKvUsersSettings, "grenade_t", 1);
						KvSetString(g_hKvUsersSettings, "model_t", g_sUsersGrenadeModelsNamesT[client]);
					}
					else
					{
						KvSetNum(g_hKvUsersSettings, "grenade_t", 0);
					}
					if (g_bUsersGrenadeModelsCT[client])
					{
						KvSetNum(g_hKvUsersSettings, "grenade_ct", 1);
						KvSetString(g_hKvUsersSettings, "model_ct", g_sUsersGrenadeModelsNamesCT[client]);
					}
					KvSetNum(g_hKvUsersSettings, "grenade_ct", 0);
				}
				KvGoBack(g_hKvUsersSettings);
			}
		}
		if (g_bPlayerVip[client][35])
		{
			KvSetNum(g_hKvUsersSettings, "firegrenade", g_iPlayerVip[client][35]);
		}
		if (g_bPlayerVip[client][36])
		{
			KvSetNum(g_hKvUsersSettings, "firegrenadeburn", g_iPlayerVip[client][36]);
		}
		if (g_bPlayerVip[client][37])
		{
			KvSetNum(g_hKvUsersSettings, "lossminispeed", g_iPlayerVip[client][37]);
		}
		if (g_bPlayerVip[client][38])
		{
			KvSetNum(g_hKvUsersSettings, "lowammosound", g_iPlayerVip[client][38]);
		}
		KvRewind(g_hKvUsersSettings);
		KeyValuesToFile(g_hKvUsersSettings, g_sUsersPath[2]);
		UsersSettingsLoad();
		VipPrint(client, enSound:0, "Все изменения сохранены.");
		g_bSettingsChanged[client] = 0;
	}
	else
	{
		VipPrint(client, enSound:2, "Ошибка! Не удалось сохранить изменения!");
		Vip_ErrorLog("Ошибка! Не удаётся сохранить изменения флагов для %N (ID: %s) Секция ключа 'UsersSettings' [%s]", client, g_sClientAuth[client], g_sUsersPath[2]);
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

public ResettingTheFlags(String:auth[])
{
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (strcmp(auth, g_sClientAuth[i], false) && IsClientConnected(i) && IsClientInGame(i))
		{
			new var2;
			if (g_bPlayerVip[i][19] && g_iGravityOffset[i] > -1 && 1065353216 != GetPlayerGravity(i))
			{
				SetPlayerGravity(i, 1.0);
			}
			new var3;
			if (g_bPlayerVip[i][17] && g_iClientTeam[i] > 1 && g_bPlayerAlive[i] && GetPlayerHealth(i) > 100)
			{
				SetPlayerHealth(i, 100);
			}
			new var4;
			if (g_bPlayerVip[i][5] && g_iClientTeam[i] > 1 && g_bPlayerAlive[i] && GetPlayerArmor(i) > 100)
			{
				SetPlayerArmor(i, 100);
			}
			new var5;
			if (g_bPlayerVip[i][18] && 1065353216 != GetPlayerSpeed(i))
			{
				SetPlayerSpeed(i, 1.0);
			}
			OnClientDisconnect(i);
			OnClientPutInServer(i);
			g_iClientTeam[i] = GetClientTeam(i);
			g_bPlayerAlive[i] = IsPlayerAlive(i);
			new var6;
			if (g_bUsersVip[i] && g_iClientTeam[i] > 1 && g_bPlayerAlive[i])
			{
				PlayerSpawn_Init(i);
			}
			return 0;
		}
		i++;
	}
	return 0;
}

public Models_Init()
{
	g_hConVarModelsForceTime = CreateConVar("vip_users_models_force_time", "0.0", "Пepeпpoвepить уcтaнoвлeнный cкин пocлe cпaвнa, в x.x ceкунудax.", 262144, true, 0.0, true, 15.0);
	HookConVarChange(g_hConVarModelsForceTime, ModelsSettingsChanged);
	g_hArrayModelsT = CreateArray(64, 0);
	g_hArrayModelsCT = CreateArray(64, 0);
	g_hArrayModelsPathT = CreateArray(64, 0);
	g_hArrayModelsPathCT = CreateArray(64, 0);
	if (g_iGame == GameType:3)
	{
		g_hArrayModelsArmsT = CreateArray(64, 0);
		g_hArrayModelsArmsCT = CreateArray(64, 0);
		g_hArrayModelsArmsPathT = CreateArray(64, 0);
		g_hArrayModelsArmsPathCT = CreateArray(64, 0);
	}
	return 0;
}

public ModelsSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarName(convar, sBuffer, 32);
	g_fModelsForceTime = GetConVarFloat(convar);
	Vip_Log("ConVar : \"%s\" = \"%f\"", sBuffer, g_fDamage);
	return 0;
}

public UsersModelsScan()
{
	decl String:sBuffer[256];
	decl String:sSection[64];
	new Handle:hBuffer = CreateKeyValues("UsersModels", "", "");
	decl String:sArm[256];
	new iBuffer;
	if (FileToKeyValues(hBuffer, g_sUsersModelsPath))
	{
		KvRewind(hBuffer);
		if (KvJumpToKey(hBuffer, "ModelsT", false))
		{
			if (KvGotoFirstSubKey(hBuffer, false))
			{
				do {
					KvGetSectionName(hBuffer, sSection, 64);
					if (FindStringInArray(g_hArrayModelsT, sSection) == -1)
					{
						if (g_iGame == GameType:3)
						{
							KvGetString(hBuffer, "model_arms", sArm, 256, "none");
							iBuffer = strlen(sArm);
							new var1;
							if (!iBuffer || !strncmp(sArm, "none", 4, false))
							{
								iBuffer = strcopy(sArm, 256, "models/weapons/t_arms_leet.mdl");
							}
							if (iBuffer > 8)
							{
								new var2;
								if (isFileExists(sArm, false) || FileExists(sArm, true))
								{
									if (!(PrecacheModel(sArm, false)))
									{
										Vip_ErrorLog("Секция моделей: Ключ \"%s\" Ошибка кеширования arms модели \"%s\"", sSection, sArm);
									}
								}
								Vip_ErrorLog("Секция моделей: Ключ \"%s\" arms файл \"%s\" не найден!", sSection, sArm);
							}
						}
						KvGetString(hBuffer, "model", sBuffer, 256, "none");
						if (strlen(sBuffer) > 8)
						{
							new var3;
							if (isFileExists(sBuffer, false) || FileExists(sBuffer, true))
							{
								if (PrecacheModel(sBuffer, false))
								{
									PushArrayString(g_hArrayModelsT, sSection);
									PushArrayString(g_hArrayModelsPathT, sBuffer);
									g_iArrayModelsT += 1;
									if (g_iGame == GameType:3)
									{
										PushArrayString(g_hArrayModelsArmsT, sSection);
										PushArrayString(g_hArrayModelsArmsPathT, sArm);
									}
								}
								else
								{
									Vip_ErrorLog("Секция моделей: Ключ \"%s\" Ошибка кеширования модели \"%s\"", sSection, sBuffer);
								}
							}
							Vip_ErrorLog("Секция моделей: Ключ \"%s\" файл \"%s\" не найден!", sSection, sBuffer);
						}
					}
					else
					{
						Vip_ErrorLog("Секция моделей: Пропуск повторного ключа \"%s\"", sSection);
					}
				} while (KvGotoNextKey(hBuffer, false));
			}
		}
		KvRewind(hBuffer);
		if (KvJumpToKey(hBuffer, "ModelsCT", false))
		{
			if (KvGotoFirstSubKey(hBuffer, false))
			{
				do {
					KvGetSectionName(hBuffer, sSection, 64);
					if (FindStringInArray(g_hArrayModelsCT, sSection) == -1)
					{
						if (g_iGame == GameType:3)
						{
							KvGetString(hBuffer, "model_arms", sArm, 256, "none");
							iBuffer = strlen(sArm);
							new var4;
							if (!iBuffer || !strncmp(sArm, "none", 4, false))
							{
								iBuffer = strcopy(sArm, 256, "models/weapons/ct_arms_sas.mdl");
							}
							if (iBuffer > 8)
							{
								new var5;
								if (isFileExists(sArm, false) || FileExists(sArm, true))
								{
									if (!(PrecacheModel(sArm, false)))
									{
										Vip_ErrorLog("Секция моделей: Ключ \"%s\" Ошибка кеширования arms модели \"%s\"", sSection, sArm);
									}
								}
								Vip_ErrorLog("Секция моделей: Ключ \"%s\" arms файл \"%s\" не найден!", sSection, sArm);
							}
						}
						KvGetString(hBuffer, "model", sBuffer, 256, "none");
						if (strlen(sBuffer) > 8)
						{
							new var6;
							if (isFileExists(sBuffer, false) || FileExists(sBuffer, true))
							{
								if (PrecacheModel(sBuffer, false))
								{
									PushArrayString(g_hArrayModelsCT, sSection);
									PushArrayString(g_hArrayModelsPathCT, sBuffer);
									g_iArrayModelsCT += 1;
									if (g_iGame == GameType:3)
									{
										PushArrayString(g_hArrayModelsArmsCT, sSection);
										PushArrayString(g_hArrayModelsArmsPathCT, sArm);
									}
								}
								else
								{
									Vip_ErrorLog("Секция моделей: Ключ \"%s\" Ошибка кеширования модели \"%s\"", sSection, sBuffer);
								}
							}
							Vip_ErrorLog("Секция моделей: Ключ \"%s\" файл \"%s\" не найден!", sSection, sBuffer);
						}
					}
					else
					{
						Vip_ErrorLog("Секция моделей: Пропуск повторного ключа \"%s\"", sSection);
					}
				} while (KvGotoNextKey(hBuffer, false));
			}
		}
	}
	else
	{
		Vip_ErrorLog("Секция моделей: Файл моделей \"%s\" не найден! Cкины отключены.", g_sUsersModelsPath);
	}
	CloseHandle(hBuffer);
	return 0;
}

public PlayerSpawn_Models(client)
{
	new var1;
	if (g_iArrayModelsT != -1 && g_iClientTeam[client] == 2 && g_bUsersModelsT[client])
	{
		SetEntityModel(client, g_sUsersModelsT[client]);
		if (g_iGame == GameType:3)
		{
			SetEntPropString(client, PropType:0, "m_szArmsModel", g_sUsersModelsArmsT[client]);
			if (0.0 != g_fModelsForceTime)
			{
				strcopy(g_sModelsForce[client], 256, g_sUsersModelsT[client]);
				strcopy(g_sModelsForceArm[client], 256, g_sUsersModelsArmsT[client]);
				g_iModelsForceTeam[client] = 2;
				CreateTimer(g_fModelsForceTime, Timer_ModelsForceSkins, g_iClientUserId[client], 0);
			}
		}
		else
		{
			if (0.0 != g_fModelsForceTime)
			{
				strcopy(g_sModelsForce[client], 256, g_sUsersModelsT[client]);
				g_iModelsForceTeam[client] = 2;
				CreateTimer(g_fModelsForceTime, Timer_ModelsForceSkins, g_iClientUserId[client], 0);
			}
		}
	}
	else
	{
		new var2;
		if (g_iArrayModelsCT != -1 && g_iClientTeam[client] == 3 && g_bUsersModelsCT[client])
		{
			SetEntityModel(client, g_sUsersModelsCT[client]);
			if (g_iGame == GameType:3)
			{
				SetEntPropString(client, PropType:0, "m_szArmsModel", g_sUsersModelsArmsCT[client]);
				if (0.0 != g_fModelsForceTime)
				{
					strcopy(g_sModelsForce[client], 256, g_sUsersModelsCT[client]);
					strcopy(g_sModelsForceArm[client], 256, g_sUsersModelsArmsCT[client]);
					g_iModelsForceTeam[client] = 3;
					CreateTimer(g_fModelsForceTime, Timer_ModelsForceSkins, g_iClientUserId[client], 0);
				}
			}
			if (0.0 != g_fModelsForceTime)
			{
				strcopy(g_sModelsForce[client], 256, g_sUsersModelsCT[client]);
				g_iModelsForceTeam[client] = 3;
				CreateTimer(g_fModelsForceTime, Timer_ModelsForceSkins, g_iClientUserId[client], 0);
			}
		}
	}
	return 0;
}

public Display_UsersModels(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModels, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Скин: [Настройка]");
	SetMenuTitle(hMenu, sBuffer);
	new var1;
	if (!g_bUsersModelsT[client] && !g_bUsersModelsCT[client])
	{
		g_iPlayerVip[client][1] = 0;
		g_bSettingsChanged[client] = 1;
		VipPrint(client, enSound:0, "Скин: [Выключен]");
		Display_MenuSettings(client, g_iUsersMenuPosition[client]);
		CloseHandle(hMenu);
	}
	else
	{
		AddMenuItem(hMenu, "models_off", "Cкин: [Выключить]", 0);
		if (g_iArrayModelsT == -1)
		{
			AddMenuItem(hMenu, "", "Террорист: [Hедoступнo!]", 1);
		}
		else
		{
			if (g_bUsersModelsT[client])
			{
				GetArrayString(g_hArrayModelsT, g_iUsersModelsT[client], sBuffer, 128);
				Format(sBuffer, 128, "Террорист [%s]", sBuffer);
				AddMenuItem(hMenu, "models_t", sBuffer, 0);
			}
			AddMenuItem(hMenu, "models_t", "Террорист: [Отключён]", 0);
		}
		if (g_iArrayModelsCT == -1)
		{
			AddMenuItem(hMenu, "", "Спецназ: [Hедoступнo!]", 1);
		}
		else
		{
			if (g_bUsersModelsCT[client])
			{
				GetArrayString(g_hArrayModelsCT, g_iUsersModelsCT[client], sBuffer, 128);
				Format(sBuffer, 128, "Спецназ: [%s]", sBuffer);
				AddMenuItem(hMenu, "models_ct", sBuffer, 0);
			}
			AddMenuItem(hMenu, "models_ct", "Спецназ: [Отключён]", 0);
		}
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
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
			decl String:sBuffer[16];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, "", 0);
			if (strcmp(sBuffer, "models_off", false))
			{
				if (strcmp(sBuffer, "models_t", false))
				{
					if (!(strcmp(sBuffer, "models_ct", false)))
					{
						Display_UsersModelsCT(client);
					}
				}
				Display_UsersModelsT(client);
			}
			else
			{
				g_iPlayerVip[client][1] = 0;
				g_bSettingsChanged[client] = 1;
				VipPrint(client, enSound:0, "Скин: [Выключен]");
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				g_iClientTeam[client] = GetClientTeam(client);
				if (g_iClientTeam[client])
				{
					g_bPlayerAlive[client] = IsPlayerAlive(client);
					if (g_bPlayerAlive[client])
					{
						CS_UpdateClientModel(client);
					}
				}
			}
		}
	}
	return 0;
}

public Display_UsersModelsT(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModelsSettings, MenuAction:514);
	decl String:sBuffer[64];
	decl String:sIndex[4];
	Format(sBuffer, 64, "Скин Террориста: [Настройка]", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "modelt_off", "Скин Террориста: [Отключить]", 0);
	new i;
	while (i <= g_iArrayModelsT)
	{
		GetArrayString(g_hArrayModelsT, i, sBuffer, 64);
		if (g_iUsersModelsT[client] == i)
		{
			Format(sBuffer, 64, "%s [X]", sBuffer);
			AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
		}
		else
		{
			Format(sIndex, 4, "t_%i", i);
			AddMenuItem(hMenu, sIndex, sBuffer, 0);
		}
		i++;
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public Display_UsersModelsCT(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersModelsSettings, MenuAction:514);
	decl String:sBuffer[64];
	decl String:sIndex[8];
	Format(sBuffer, 64, "Скин Спецназа: [Настройка]", client);
	SetMenuTitle(hMenu, sBuffer);
	AddMenuItem(hMenu, "modelct_off", "Скин Спецназа: [Отключить]", 0);
	new i;
	while (i <= g_iArrayModelsCT)
	{
		GetArrayString(g_hArrayModelsCT, i, sBuffer, 64);
		if (g_iUsersModelsCT[client] == i)
		{
			Format(sBuffer, 64, "%s [X]", sBuffer);
			AddMenuItem(hMenu, NULL_STRING, sBuffer, 1);
		}
		else
		{
			Format(sIndex, 8, "ct_%i", i);
			AddMenuItem(hMenu, sIndex, sBuffer, 0);
		}
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
			decl String:sBuffer[16];
			decl String:sName[32];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, sName, 32);
			if (strcmp(sBuffer, "modelt_off", false))
			{
				if (strcmp(sBuffer, "modelct_off", false))
				{
					if (strncmp(sBuffer, "t_", 2, false))
					{
						if (!(strncmp(sBuffer, "ct_", 3, false)))
						{
							g_iUsersModelsCT[client] = StringToInt(sBuffer[0], 10);
							GetArrayString(g_hArrayModelsPathCT, g_iUsersModelsCT[client], g_sUsersModelsCT[client], 256);
							if (g_iGame == GameType:3)
							{
								GetArrayString(g_hArrayModelsArmsPathCT, g_iUsersModelsCT[client], g_sUsersModelsArmsCT[client], 256);
							}
							g_bUsersModelsCT[client] = 1;
							g_iClientTeam[client] = GetClientTeam(client);
							if (g_iClientTeam[client] == 3)
							{
								VipPrint(client, enSound:0, "Скин \x04%s\x01 будет установлен  в следующем раунде за команду спецназ.", sName);
							}
							VipPrint(client, enSound:0, "Скин \x04%s\x01 установлен за команду спецназ.", sName);
						}
					}
					g_iUsersModelsT[client] = StringToInt(sBuffer[0], 10);
					GetArrayString(g_hArrayModelsPathT, g_iUsersModelsT[client], g_sUsersModelsT[client], 256);
					if (g_iGame == GameType:3)
					{
						GetArrayString(g_hArrayModelsArmsPathT, g_iUsersModelsT[client], g_sUsersModelsArmsT[client], 256);
					}
					g_bUsersModelsT[client] = 1;
					g_iClientTeam[client] = GetClientTeam(client);
					if (g_iClientTeam[client] == 2)
					{
						VipPrint(client, enSound:0, "Скин \x04%s\x01 будет установлен в следующем раунде за команду террористов.", sName);
					}
					else
					{
						VipPrint(client, enSound:0, "Скин \x04%s\x01 установлен за команду террористов.", sName);
					}
				}
				g_bUsersModelsCT[client] = 0;
				g_iClientTeam[client] = GetClientTeam(client);
				if (g_iClientTeam[client])
				{
					g_bPlayerAlive[client] = IsPlayerAlive(client);
					if (g_bPlayerAlive[client])
					{
						CS_UpdateClientModel(client);
					}
				}
				VipPrint(client, enSound:0, "Скин за команду спецназ отключён.");
			}
			else
			{
				g_bUsersModelsT[client] = 0;
				g_iClientTeam[client] = GetClientTeam(client);
				if (g_iClientTeam[client])
				{
					g_bPlayerAlive[client] = IsPlayerAlive(client);
					if (g_bPlayerAlive[client])
					{
						CS_UpdateClientModel(client);
					}
				}
				VipPrint(client, enSound:0, "Скин за команду террористов отключён.");
			}
			g_bSettingsChanged[client] = 1;
			Display_UsersModels(client);
		}
	}
	return 0;
}

public Action:Timer_ModelsForceSkins(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && g_bPlayerAlive[client] && g_iModelsForceTeam[client] == g_iClientTeam[client] && IsClientInGame(client))
	{
		decl String:sBuffer[256];
		GetClientModel(client, sBuffer, 256);
		if (strcmp(sBuffer, g_sModelsForce[client], false))
		{
			SetEntityModel(client, g_sModelsForce[client]);
			if (g_iGame == GameType:3)
			{
				SetEntPropString(client, PropType:0, "m_szArmsModel", g_sModelsForceArm[client]);
			}
		}
	}
	return Action:4;
}

public Display_PlayerCommands(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_PlayerCommands, MenuAction:514);
	SetMenuTitle(hMenu, "Управление игроками:");
	if (g_bPlayerCmds[client][0])
	{
		AddMenuItem(hMenu, "1", "Кикнуть игрока", 0);
	}
	if (g_bPlayerCmds[client][1])
	{
		AddMenuItem(hMenu, "2", "Забанить игрока", 0);
	}
	if (g_bPlayerCmds[client][2])
	{
		AddMenuItem(hMenu, "3", "Заглушить игрока", 0);
	}
	if (g_bPlayerCmds[client][3])
	{
		AddMenuItem(hMenu, "4", "Бросить оружие", 0);
	}
	if (g_bPlayerCmds[client][4])
	{
		if (g_bFlashLight)
		{
			AddMenuItem(hMenu, "5", "Упpaвлeниe фoнapикoм", 0);
		}
		AddMenuItem(hMenu, NULL_STRING, "Упpaвлeниe фoнapикoм: [Heдocтyпнo!]", 1);
	}
	if (g_bPlayerCmds[client][5])
	{
		AddMenuItem(hMenu, "6", "Упpaвлeниe спреем", 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_PlayerCommands(Handle:hMenu, MenuAction:action, client, param)
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
			decl String:sBuffer[4];
			GetMenuItem(hMenu, param, sBuffer, 4, 0, "", 0);
			switch (StringToInt(sBuffer, 10))
			{
				case 1:
				{
					Display_KickPlayers(client, true);
				}
				case 2:
				{
					VipPrint(client, enSound:2, "Я эту опцию еще не начинал делать!");
					Display_PlayerCommands(client);
				}
				case 3:
				{
					VipPrint(client, enSound:2, "Я эту опцию еще не начинал делать!");
					Display_PlayerCommands(client);
				}
				case 4:
				{
					g_iUsersReplayCommands[client] = 4;
					Display_DropPlayers(client, true);
				}
				case 5:
				{
					g_iUsersReplayCommands[client] = 5;
					Display_FlashLightPlayers(client, true);
				}
				case 6:
				{
					g_iUsersReplayCommands[client] = 6;
					Display_SprayPlayers(client, true);
				}
				default:
				{
				}
			}
		}
	}
	return 0;
}

public Display_KickPlayers(client, bool:msgerror)
{
	new Handle:hMenu = CreateMenu(MenuHandler_KickPlayers, MenuAction:514);
	SetMenuTitle(hMenu, "Кикнуть игрока:");
	if (GetMenuItemPlayers(client, hMenu, false, true, false))
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (msgerror)
		{
			VipPrint(client, enSound:2, "Игроки не найдены!");
		}
		Display_PlayerCommands(client);
	}
	return 0;
}

public MenuHandler_KickPlayers(Handle:hMenu, MenuAction:action, client, param)
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
				Display_PlayerCommands(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[64];
			decl iBuffer;
			GetMenuItem(hMenu, param, sBuffer, 64, 0, "", 0);
			g_iTargetUserId[client] = StringToInt(sBuffer, 10);
			iBuffer = GetClientOfUserId(g_iTargetUserId[client]);
			new var1;
			if (!iBuffer || !IsClientConnected(iBuffer))
			{
				VipPrint(client, enSound:2, "%T", "Player no longer available", client);
				g_iTargetUserId[client] = 0;
			}
			else
			{
				if (GetClientName(iBuffer, g_sVipFlags[client][0], 256))
				{
					g_iTarget[client] = iBuffer;
					strcopy(g_sVipFlags[client][3], 256, g_sClientAuth[iBuffer]);
					Display_KickPlayersReason(client);
					return 0;
				}
			}
			Display_KickPlayers(client, false);
		}
	}
	return 0;
}

public Display_KickPlayersReason(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_KickPlayersReason, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Пpичина кика: %s", g_sVipFlags[client][0]);
	SetMenuTitle(hMenu, sBuffer);
	if (g_iArrayKickReason == -1)
	{
		AddMenuItem(hMenu, "Задолбал", "Задолбал", 0);
		AddMenuItem(hMenu, "Хватит матюгаться", "Хватит матюгаться", 0);
		AddMenuItem(hMenu, "Нубы не приветствуются", "Нубы не приветствуются", 0);
		AddMenuItem(hMenu, "Отдохни милок", "Отдохни милок", 0);
		AddMenuItem(hMenu, "Сходи погуляй", "Сходи погуляй", 0);
		AddMenuItem(hMenu, "Читер наверное", "Читер наверное", 0);
		AddMenuItem(hMenu, "Давай, до свидания", "Давай, до свидания", 0);
	}
	else
	{
		if (g_iArrayKickReason)
		{
			new i;
			while (i <= g_iArrayKickReason)
			{
				GetArrayString(g_hArrayKickReason, i, sBuffer, 128);
				AddMenuItem(hMenu, sBuffer, sBuffer, 0);
				i++;
			}
		}
		GetArrayString(g_hArrayKickReason, 0, sBuffer, 128);
		AddMenuItem(hMenu, sBuffer, sBuffer, 0);
	}
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_KickPlayersReason(Handle:hMenu, MenuAction:action, client, param)
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
				Display_KickPlayers(client, false);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[128];
			decl String:sReason[128];
			GetMenuItem(hMenu, param, sReason, 128, 0, "", 0);
			new target = GetClientOfUserId(g_iTargetUserId[client]);
			new var1;
			if (target && IsClientConnected(target) && IsClientInGame(target))
			{
				new var2;
				if (IsClientInKickQueue(target) || GetUserAdmin(target) == -1)
				{
					VipPrint(client, enSound:2, "Не Удалось выкинуть с сервера %s!", g_sVipFlags[client][0]);
				}
				else
				{
					KickClient(target, sReason);
					if (!GetClientName(client, sBuffer, 128))
					{
						Format(sBuffer, 128, "#%i (ID:%s)", g_iClientUserId[client], g_sClientAuth[client]);
					}
					new i = 1;
					while (i <= g_iMaxClients)
					{
						new var3;
						if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
						{
							if (g_bPlayerCmds[i][0])
							{
								if (i == client)
								{
									VipPrint(client, enSound:0, "Игрок %s кикнут с сервера.", g_sVipFlags[client][0]);
								}
								else
								{
									VipPrint(i, enSound:0, "%s кикнул с сервера %s", sBuffer, g_sVipFlags[client][0]);
								}
							}
							VipPrint(i, enSound:0, "Игрок %s кикнут с сервера.", g_sVipFlags[client][0]);
						}
						i++;
					}
					Vip_Log("%s (ID: %s) кикнул с сервера %s (ID: %s) Причина: %s", sBuffer, g_sClientAuth[client], g_sVipFlags[client][0], g_sVipFlags[client][3], sReason);
				}
			}
			else
			{
				VipPrint(client, enSound:2, "Игрок %s (ID: %s) успел свалить с сервера.", g_sVipFlags[client][0], g_sVipFlags[client][3]);
			}
			strcopy(g_sVipFlags[client][0], 256, NULL_STRING);
			strcopy(g_sVipFlags[client][3], 256, NULL_STRING);
			g_iTargetUserId[client] = 0;
			Display_KickPlayers(client, false);
		}
	}
	return 0;
}

public Display_DropPlayers(client, bool:msgerror)
{
	new Handle:hMenu = CreateMenu(MenuHandler_DropPlayers, MenuAction:514);
	SetMenuTitle(hMenu, "Бросить оружие у:");
	if (GetMenuItemPlayers(client, hMenu, false, true, true))
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (msgerror)
		{
			VipPrint(client, enSound:2, "Игроки не найдены!");
		}
		Display_PlayerCommands(client);
	}
	return 0;
}

public MenuHandler_DropPlayers(Handle:hMenu, MenuAction:action, client, param)
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
				Display_PlayerCommands(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[16];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, "", 0);
			g_iTargetUserId[client] = StringToInt(sBuffer, 10);
			new iBuffer = GetClientOfUserId(g_iTargetUserId[client]);
			new var1;
			if (!iBuffer || !IsClientInGame(iBuffer))
			{
				VipPrint(client, enSound:2, "%T", "Player no longer available", client);
				g_iTargetUserId[client] = 0;
			}
			else
			{
				if (GetClientName(iBuffer, g_sVipFlags[client][0], 256))
				{
					UsersDropWeapon(iBuffer);
					Display_UsersReplayCommands(client, true);
					return 0;
				}
			}
			Display_DropPlayers(client, false);
		}
	}
	return 0;
}

public Display_FlashLightPlayers(client, bool:msgerror)
{
	new Handle:hMenu = CreateMenu(MenuHandler_FlashLightPlayers, MenuAction:514);
	SetMenuTitle(hMenu, "Управление фонариком у:");
	if (GetMenuItemPlayers(client, hMenu, false, true, true))
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (msgerror)
		{
			VipPrint(client, enSound:2, "Игроки не найдены!");
		}
		Display_PlayerCommands(client);
	}
	return 0;
}

public MenuHandler_FlashLightPlayers(Handle:hMenu, MenuAction:action, client, param)
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
				Display_PlayerCommands(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[16];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, "", 0);
			g_iTargetUserId[client] = StringToInt(sBuffer, 10);
			new target = GetClientOfUserId(g_iTargetUserId[client]);
			new var1;
			if (!target || !IsClientInGame(target))
			{
				VipPrint(client, enSound:2, "%T", "Player no longer available", client);
				g_iTargetUserId[client] = 0;
			}
			else
			{
				if (GetClientName(target, g_sVipFlags[client][0], 256))
				{
					g_bPlayerAlive[target] = IsPlayerAlive(target);
					if (g_bPlayerAlive[target])
					{
						SetEntData(target, g_iImpulseOffset[target], any:100, 4, true);
					}
					Display_UsersReplayCommands(client, true);
					return 0;
				}
			}
			Display_FlashLightPlayers(client, false);
		}
	}
	return 0;
}

public Display_SprayPlayers(client, bool:msgerror)
{
	new Handle:hMenu = CreateMenu(MenuHandler_SprayPlayers, MenuAction:514);
	SetMenuTitle(hMenu, "Управление спреем у:");
	if (GetMenuItemPlayers(client, hMenu, false, true, true))
	{
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (msgerror)
		{
			VipPrint(client, enSound:2, "Игроки не найдены!");
		}
		Display_PlayerCommands(client);
	}
	return 0;
}

public MenuHandler_SprayPlayers(Handle:hMenu, MenuAction:action, client, param)
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
				Display_PlayerCommands(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[16];
			GetMenuItem(hMenu, param, sBuffer, 16, 0, "", 0);
			g_iTargetUserId[client] = StringToInt(sBuffer, 10);
			new target = GetClientOfUserId(g_iTargetUserId[client]);
			new var1;
			if (!target || !IsClientInGame(target))
			{
				VipPrint(client, enSound:2, "%T", "Player no longer available", client);
				g_iTargetUserId[client] = 0;
			}
			else
			{
				if (GetClientName(target, g_sVipFlags[client][0], 256))
				{
					g_bPlayerAlive[target] = IsPlayerAlive(target);
					if (g_bPlayerAlive[target])
					{
						SetEntData(target, g_iImpulseOffset[target], any:201, 4, true);
					}
					Display_UsersReplayCommands(client, true);
					return 0;
				}
			}
			Display_SprayPlayers(client, false);
		}
	}
	return 0;
}

public bool:GetMenuItemPlayers(client, Handle:hMenu, bool:clientequal, bool:isvip, bool:isalive)
{
	new var6;
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (!clientequal && i == client)
		{
		}
		else
		{
			new var2;
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && !IsClientInKickQueue(i))
			{
				if (isalive)
				{
					g_bPlayerAlive[i] = IsPlayerAlive(i);
					if (!g_bPlayerAlive[i])
					{
					}
				}
				new var7 = var6 + 4;
				if (!GetClientName(i, var7 + var7, 128))
				{
					new var8 = var6 + 4;
					Format(var8 + var8, 128, "Имя не распознано! [#%i] [%i]", g_iClientUserId[i], i);
				}
				g_iClientTeam[i] = GetClientTeam(i);
				IntToString(g_iClientUserId[i], var6 + var6, 128);
				if (g_iClientTeam[i] < 2)
				{
					new var3;
					if (g_bUsersVip[i] || g_bUsersCmds[i])
					{
						if (isvip)
						{
							new var9 = var6 + 4;
							new var10 = var6 + 4;
							Format(var10 + var10, 128, "[VIP] [SPEC] %s #%s", var9 + var9, var6 + var6);
						}
					}
					else
					{
						new var11 = var6 + 4;
						new var12 = var6 + 4;
						Format(var12 + var12, 128, "[SPEC] %s #%s", var11 + var11, var6 + var6);
					}
				}
				else
				{
					if (g_iClientTeam[i] == 2)
					{
						new var4;
						if (g_bUsersVip[i] || g_bUsersCmds[i])
						{
							if (isvip)
							{
								new var13 = var6 + 4;
								new var14 = var6 + 4;
								Format(var14 + var14, 128, "[VIP] [T] %s #%s", var13 + var13, var6 + var6);
							}
						}
						else
						{
							new var15 = var6 + 4;
							new var16 = var6 + 4;
							Format(var16 + var16, 128, "[T] %s #%s", var15 + var15, var6 + var6);
						}
					}
					new var5;
					if (g_bUsersVip[i] || g_bUsersCmds[i])
					{
						if (isvip)
						{
							new var17 = var6 + 4;
							new var18 = var6 + 4;
							Format(var18 + var18, 128, "[VIP] [CT] %s #%s", var17 + var17, var6 + var6);
						}
					}
					new var19 = var6 + 4;
					new var20 = var6 + 4;
					Format(var20 + var20, 128, "[CT] %s #%s", var19 + var19, var6 + var6);
				}
				new var21 = var6 + 4;
				AddMenuItem(hMenu, var6 + var6, var21 + var21, 0);
			}
		}
		i++;
	}
	if (GetMenuItemCount(hMenu))
	{
		return true;
	}
	CloseHandle(hMenu);
	return false;
}

public Display_UsersReplayCommands(client, bool:alivemsg)
{
	new Handle:hMenu = CreateMenu(MenuHandler_UsersReplayCommands, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Повторить операцию над: %s", g_sVipFlags[client][0]);
	SetMenuTitle(hMenu, sBuffer);
	new target = GetClientOfUserId(g_iTargetUserId[client]);
	new var1;
	if (target && IsClientInGame(target))
	{
		g_bPlayerAlive[target] = IsPlayerAlive(target);
		if (g_bPlayerAlive[target])
		{
			AddMenuItem(hMenu, NULL_STRING, "Повторить", 0);
		}
		else
		{
			AddMenuItem(hMenu, NULL_STRING, "Повторить", 1);
			AddMenuItem(hMenu, "2", "Обновить", 0);
			if (alivemsg)
			{
				VipPrint(client, enSound:2, "Игрок \x03%s\x01 должен быть живой!", g_sVipFlags[client][0]);
			}
		}
	}
	else
	{
		AddMenuItem(hMenu, NULL_STRING, "Повторить", 1);
		VipPrint(client, enSound:2, "Игрок \x03%s\x01 больше недоступен!", g_sVipFlags[client][0]);
	}
	AddMenuItem(hMenu, "1", "Назад", 0);
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, client, 0);
	return 0;
}

public MenuHandler_UsersReplayCommands(Handle:hMenu, MenuAction:action, client, param)
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
				if (g_iUsersReplayCommands[client] == 4)
				{
					Display_DropPlayers(client, false);
				}
				g_iUsersReplayCommands[client] = 0;
				g_iTargetUserId[client] = 0;
				Display_PlayerCommands(client);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:sBuffer[4];
			GetMenuItem(hMenu, param, sBuffer, 4, 0, "", 0);
			new iBuffer = StringToInt(sBuffer, 10);
			if (iBuffer == 1)
			{
				if (g_iUsersReplayCommands[client] == 4)
				{
					Display_DropPlayers(client, false);
				}
				else
				{
					if (g_iUsersReplayCommands[client] == 5)
					{
						Display_FlashLightPlayers(client, false);
					}
					if (g_iUsersReplayCommands[client] == 6)
					{
						Display_SprayPlayers(client, false);
					}
				}
			}
			else
			{
				if (iBuffer == 2)
				{
					Display_UsersReplayCommands(client, false);
				}
				if (g_iUsersReplayCommands[client] == 4)
				{
					iBuffer = GetClientOfUserId(g_iTargetUserId[client]);
					new var1;
					if (iBuffer && IsClientInGame(iBuffer))
					{
						g_bPlayerAlive[iBuffer] = IsPlayerAlive(iBuffer);
						if (g_bPlayerAlive[iBuffer])
						{
							if (!UsersDropWeapon(iBuffer))
							{
								VipPrint(client, enSound:2, "У игрока \x03%s\x01 не найдено оружия!", g_sVipFlags[client][0]);
							}
						}
						VipPrint(client, enSound:2, "Игрок \x03%s\x01 должен быть живой!", g_sVipFlags[client][0]);
					}
					Display_UsersReplayCommands(client, false);
				}
				if (g_iUsersReplayCommands[client] == 5)
				{
					iBuffer = GetClientOfUserId(g_iTargetUserId[client]);
					new var2;
					if (iBuffer && IsClientInGame(iBuffer))
					{
						g_bPlayerAlive[iBuffer] = IsPlayerAlive(iBuffer);
						if (g_bPlayerAlive[iBuffer])
						{
							SetEntData(iBuffer, g_iImpulseOffset[iBuffer], any:100, 4, true);
						}
						VipPrint(client, enSound:2, "Игрок \x03%s\x01 должен быть живой!", g_sVipFlags[client][0]);
					}
					Display_UsersReplayCommands(client, false);
				}
				if (g_iUsersReplayCommands[client] == 6)
				{
					iBuffer = GetClientOfUserId(g_iTargetUserId[client]);
					new var3;
					if (iBuffer && IsClientInGame(iBuffer))
					{
						g_bPlayerAlive[iBuffer] = IsPlayerAlive(iBuffer);
						if (g_bPlayerAlive[iBuffer])
						{
							SetEntData(iBuffer, g_iImpulseOffset[iBuffer], any:201, 4, true);
						}
						VipPrint(client, enSound:2, "Игрок \x03%s\x01 должен быть живой!", g_sVipFlags[client][0]);
					}
					Display_UsersReplayCommands(client, false);
				}
			}
		}
	}
	return 0;
}

public Player_DissolveRagdoll(userid)
{
	CreateTimer(1.23, Timer_PlayerDissolveRagdoll, userid, 0);
	return 0;
}

public Action:Timer_PlayerDissolveRagdoll(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && IsClientInGame(client) && !g_bPlayerAlive[client])
	{
		decl String:sBuffer[16];
		new ragdoll = GetEntDataEnt2(client, g_iRagdollOffset);
		if (ragdoll != -1)
		{
			Format(sBuffer, 16, "dis_%i", userid);
			new entity = CreateEntityByName("env_entity_dissolver", -1);
			if (entity != -1)
			{
				DispatchKeyValue(ragdoll, "targetname", sBuffer);
				DispatchKeyValue(entity, "dissolvetype", "1");
				DispatchKeyValue(entity, "target", sBuffer);
				AcceptEntityInput(entity, "Dissolve", -1, -1, 0);
				AcceptEntityInput(entity, "kill", -1, -1, 0);
			}
		}
	}
	return Action:4;
}

public PlayerSpawn_Gravity(client)
{
	switch (g_iPlayerVip[client][19])
	{
		case 1:
		{
			g_iPlayerVip[client][19] = 1;
			SetPlayerGravity(client, 4.0);
		}
		case 2:
		{
			g_iPlayerVip[client][19] = 2;
			SetPlayerGravity(client, 2.9);
		}
		case 3:
		{
			g_iPlayerVip[client][19] = 3;
			SetPlayerGravity(client, 1.8);
		}
		case 4:
		{
			g_iPlayerVip[client][19] = 4;
			SetPlayerGravity(client, 0.8);
		}
		case 5:
		{
			g_iPlayerVip[client][19] = 5;
			SetPlayerGravity(client, 0.4);
		}
		case 6:
		{
			g_iPlayerVip[client][19] = 6;
			SetPlayerGravity(client, 0.1);
		}
		default:
		{
			if (1065353216 != GetPlayerGravity(client))
			{
				SetPlayerGravity(client, 1.0);
			}
		}
	}
	return 0;
}

public Display_Gravity(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Gravity, MenuAction:28);
	decl String:sBuffer[100];
	Format(sBuffer, 100, "Установка гравитации: Настройка", client);
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, 100, "Гравитация: [Стандарт]", client);
	if (!g_iPlayerVip[client][19])
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "0", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Oчeнь выcoкaя]", client);
	if (g_iPlayerVip[client][19] == 1)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "1", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Bыcoкaя]", client);
	if (g_iPlayerVip[client][19] == 2)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "2", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Повышенная]", client);
	if (g_iPlayerVip[client][19] == 3)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "3", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Пониженная]", client);
	if (g_iPlayerVip[client][19] == 4)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "4", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Hизкaя]", client);
	if (g_iPlayerVip[client][19] == 5)
	{
		AddMenuItem(hMenu, "", sBuffer, 1);
	}
	else
	{
		AddMenuItem(hMenu, "5", sBuffer, 0);
	}
	Format(sBuffer, 100, "Гравитация: [Oчeнь Hизкaя]", client);
	if (g_iPlayerVip[client][19] == 6)
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
					g_iPlayerVip[client][19] = 0;
					VipPrint(client, enSound:0, "Гравитация: [Стандарт]");
				}
				case 1:
				{
					g_iPlayerVip[client][19] = 1;
					SetPlayerGravity(client, 4.0);
					VipPrint(client, enSound:0, "Гравитация: [Очень высокая]");
				}
				case 2:
				{
					g_iPlayerVip[client][19] = 2;
					SetPlayerGravity(client, 2.9);
					VipPrint(client, enSound:0, "Гравитация: [Высокая]");
				}
				case 3:
				{
					g_iPlayerVip[client][19] = 3;
					SetPlayerGravity(client, 1.8);
					VipPrint(client, enSound:0, "Гравитация: [Немного высокая]");
				}
				case 4:
				{
					g_iPlayerVip[client][19] = 4;
					SetPlayerGravity(client, 0.7);
					VipPrint(client, enSound:0, "Гравитация: [Немного низкая]");
				}
				case 5:
				{
					g_iPlayerVip[client][19] = 5;
					SetPlayerGravity(client, 0.4);
					VipPrint(client, enSound:0, "Гравитация: [Низкая]");
				}
				case 6:
				{
					g_iPlayerVip[client][19] = 6;
					SetPlayerGravity(client, 0.1);
					VipPrint(client, enSound:0, "Гравитация: [Очень низкая]");
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
	RegConsoleCmd("resp", ResPawn_Command, "ResPawn", 0);
	RegConsoleCmd("respawn", ResPawn_Command, "ResPawn", 0);
	RegConsoleCmd("vip_respawn", ResPawn_Command, "ResPawn", 0);
	return 0;
}

public Action:ResPawn_Command(client, args)
{
	if (client)
	{
		if (g_bPlayerVip[client][21])
		{
			if (g_iClientTeam[client] > 1)
			{
				if (g_bPlayerAlive[client])
				{
					VipPrint(client, enSound:2, "Чувак! Ты здоров как БЫК! [0_o]");
				}
				new iFrags = GetPlayerFrags(client);
				if (iFrags >= 4)
				{
					iFrags += -4;
					SetPlayerFrags(client, iFrags);
					CS_RespawnPlayer(client);
					VipPrint(client, enSound:0, "С вас снято 4 фрага :)");
				}
				else
				{
					VipPrint(client, enSound:2, "Сорри, бро! Чтобы использовать эту функцию, у тебя должно быть миниум 4 фрага.");
				}
			}
		}
		else
		{
			VipPrint(client, enSound:2, "Вам недоступна эта команда!");
		}
		return Action:3;
	}
	return Action:0;
}

public WeaponRestrictImmune_Init()
{
	g_hConVarWeaponRestrictImmune = CreateConVar("vip_users_weapon_restrict", "1", "Блoкиpoвaть opужия через: 1 конфиг users_weapon_restrict.ini и чepeз плaгин weapon_restrict, 0 тoлькo из кoнфигa users_weapon_restrict.ini", 262144, true, 0.0, true, 1.0);
	WeaponRestrictImmuneOnSettingsChanged(g_hConVarWeaponRestrictImmune, NULL_STRING, NULL_STRING);
	HookConVarChange(g_hConVarWeaponRestrictImmune, WeaponRestrictImmuneOnSettingsChanged);
	g_hConVarWeaponRestrictImmuneBanalce = CreateConVar("vip_users_weapon_restrict_balance", "2", "Бaлaнc VIP игpoкoв c иммунитeтoм oт зaпpeтa opужия флaгa '1f'. Бaлaнc: 0 Oтк, 1 VIP, 2 Кpoмe aдминoв, 3 Bce игpoки и кpoмe aдминoв.", 262144, true, 0.0, true, 3.0);
	WeaponRestrictImmuneOnSettingsChanged(g_hConVarWeaponRestrictImmuneBanalce, NULL_STRING, NULL_STRING);
	HookConVarChange(g_hConVarWeaponRestrictImmuneBanalce, WeaponRestrictImmuneOnSettingsChanged);
	return 0;
}

public OnWeaponRestrictionBalance()
{
	new iTeamT;
	new iTeamCT;
	new iTeamTVIP;
	new iTeamCTVIP;
	new iTeamIDT[66];
	new iTeamIDCT[66];
	new iTeamIDTVIP[66];
	new iTeamIDCTVIP[66];
	new client;
	new iTemp;
	new iNoVIP;
	new iTeamTAdmin;
	new iTeamCTAdmin;
	new iPrintToID[66];
	new iPrintToIDSize;
	new i = 1;
	while (i <= g_iMaxClients)
	{
		if (IsClientInGame(i))
		{
			g_iClientTeam[i] = GetClientTeam(i);
			if (g_iClientTeam[i] == 2)
			{
				new var1;
				if (g_bUsersAdmin[i] && g_iWeaponRestrictImmuneBalance > 1)
				{
					iTeamTAdmin++;
				}
				else
				{
					iTemp = GetClientUserId(i);
					new var2;
					if (g_bPlayerVip[i][31] && g_iPlayerVip[i][31])
					{
						iTeamTVIP++;
						iTeamIDTVIP[iTeamTVIP] = iTemp;
					}
					iTeamT++;
					iTeamIDT[iTeamT] = iTemp;
				}
			}
			if (g_iClientTeam[i] == 3)
			{
				new var3;
				if (g_bUsersAdmin[i] && g_iWeaponRestrictImmuneBalance > 1)
				{
					iTeamCTAdmin++;
				}
				iTemp = GetClientUserId(i);
				new var4;
				if (g_bPlayerVip[i][31] && g_iPlayerVip[i][31])
				{
					iTeamCTVIP++;
					iTeamIDCTVIP[iTeamCTVIP] = iTemp;
				}
				iTeamCT++;
				iTeamIDCT[iTeamCT] = iTemp;
			}
		}
		i++;
	}
	if (iNoVIP != iTeamT)
	{
		SortIntegers(iTeamIDT, iTeamT, SortOrder:1);
	}
	if (iNoVIP != iTeamCT)
	{
		SortIntegers(iTeamIDCT, iTeamCT, SortOrder:1);
	}
	iTemp = iTeamTVIP - iTeamCTVIP;
	if (iTemp > 1)
	{
		SortIntegers(iTeamIDTVIP, iTeamTVIP, SortOrder:1);
		iTemp = RoundToFloor(iTemp / 1073741824);
		new i;
		while (i < iTemp)
		{
			client = GetClientOfUserId(iTeamIDTVIP[i]);
			CS_SwitchTeam(client, 3);
			CS_UpdateClientModel(client);
			CS_RespawnPlayer(client);
			iPrintToIDSize++;
			iPrintToID[iPrintToIDSize] = iTeamIDTVIP[i];
			if (g_bIsDeMap)
			{
				OnSwitchEquipAndRemoveC4(client);
			}
			if (iTeamCT != iNoVIP)
			{
				client = GetClientOfUserId(iTeamIDCT[iNoVIP]);
				iNoVIP++;
				iTeamIDCT[iNoVIP] = -1;
				CS_SwitchTeam(client, 2);
				CS_UpdateClientModel(client);
				CS_RespawnPlayer(client);
				iPrintToIDSize++;
				iPrintToID[iPrintToIDSize] = iTeamIDCT[i];
				new var5;
				if (g_bIsDeMap && GetPlayerDefuser(client))
				{
					RemovePlayerDefuser(client);
				}
			}
			i++;
		}
	}
	else
	{
		iTemp = iTeamCTVIP - iTeamTVIP;
		if (iTemp > 1)
		{
			SortIntegers(iTeamIDCTVIP, iTeamCTVIP, SortOrder:1);
			iTemp = RoundToFloor(iTemp / 1073741824);
			new i;
			while (i < iTemp)
			{
				client = GetClientOfUserId(iTeamIDCTVIP[i]);
				CS_SwitchTeam(client, 2);
				CS_UpdateClientModel(client);
				CS_RespawnPlayer(client);
				iPrintToIDSize++;
				iPrintToID[iPrintToIDSize] = iTeamIDCTVIP[i];
				new var6;
				if (g_bIsDeMap && GetPlayerDefuser(client))
				{
					RemovePlayerDefuser(client);
				}
				if (iNoVIP != iTeamT)
				{
					client = GetClientOfUserId(iTeamIDT[iNoVIP]);
					iNoVIP++;
					iTeamIDT[iNoVIP] = -1;
					CS_SwitchTeam(client, 3);
					CS_UpdateClientModel(client);
					CS_RespawnPlayer(client);
					iPrintToIDSize++;
					iPrintToID[iPrintToIDSize] = iTeamIDT[i];
					if (g_bIsDeMap)
					{
						OnSwitchEquipAndRemoveC4(client);
					}
				}
				i++;
			}
		}
	}
	if (g_iWeaponRestrictImmuneBalance > 2)
	{
		iTemp = iTeamT - iTeamCT;
		if (iTemp > 1)
		{
			iTemp = RoundToFloor(iTemp / 1073741824);
			new i;
			while (i < iTemp)
			{
				if (iTeamIDT[i] != -1)
				{
					client = GetClientOfUserId(iTeamIDT[i]);
					CS_SwitchTeam(client, 3);
					CS_UpdateClientModel(client);
					CS_RespawnPlayer(client);
					iPrintToIDSize++;
					iPrintToID[iPrintToIDSize] = iTeamIDT[i];
					if (g_bIsDeMap)
					{
						OnSwitchEquipAndRemoveC4(client);
					}
					if (GetTeamClientCount(3) - iTeamCTAdmin == GetTeamClientCount(2) - iTeamTAdmin)
					{
					}
				}
				i++;
			}
		}
		iTemp = iTeamCT - iTeamT;
		iTemp = RoundToFloor(iTemp / 1073741824);
		if (iTemp > 1)
		{
			new i;
			while (i < iTemp)
			{
				if (iTeamIDCT[i] != -1)
				{
					client = GetClientOfUserId(iTeamIDCT[i]);
					CS_SwitchTeam(client, 2);
					CS_UpdateClientModel(client);
					CS_RespawnPlayer(client);
					iPrintToIDSize++;
					iPrintToID[iPrintToIDSize] = iTeamIDCT[i];
					new var7;
					if (g_bIsDeMap && GetPlayerDefuser(client))
					{
						RemovePlayerDefuser(client);
					}
					if (GetTeamClientCount(3) - iTeamCTAdmin == GetTeamClientCount(2) - iTeamTAdmin)
					{
					}
				}
				i++;
			}
		}
	}
	if (iPrintToIDSize)
	{
		new i = 1;
		while (i <= g_iMaxClients)
		{
			new var8;
			if (g_iClientTeam[i] > 0 && IsClientInGame(i))
			{
				iTemp = GetClientUserId(i);
				client = 0;
				new q;
				while (q < iPrintToIDSize)
				{
					if (iPrintToID[q] == iTemp)
					{
						client = i;
						if (client)
						{
							PrintCenterText(client, "#Cstrike_TitlesTXT_Player_Balanced");
						}
						PrintCenterText(i, "#Cstrike_TitlesTXT_Teams_Balanced");
					}
					q++;
				}
				if (client)
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Player_Balanced");
				}
				PrintCenterText(i, "#Cstrike_TitlesTXT_Teams_Balanced");
			}
			i++;
		}
	}
	return 0;
}

public WeaponRestrictImmuneOnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[64];
	GetConVarName(convar, sBuffer, 64);
	new iBuffer = GetConVarInt(convar);
	if (g_hConVarWeaponRestrictImmune == convar)
	{
		g_bWeaponRestrictImmune = iBuffer != 0;
	}
	else
	{
		if (g_hConVarWeaponRestrictImmuneBanalce == convar)
		{
			g_iWeaponRestrictImmuneBalance = iBuffer;
		}
	}
	Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, iBuffer);
	return 0;
}

public bool:Restrict_OnRemoveRandom(client, WeaponID:id)
{
	new var1;
	if (g_bPlayerVip[client][31] && g_bNoRestrictOnWarmup && g_iPlayerVip[client][31] && !g_bWeaponRestrict[id] && !Restrict_IsSpecialRound())
	{
		return false;
	}
	return true;
}

public Action:Restrict_OnCanBuyWeapon(client, team, WeaponID:id, &CanBuyResult:result)
{
	new var1;
	if (g_bPlayerVip[client][31] && g_bNoRestrictOnWarmup && g_iPlayerVip[client][31] && result != 2 && !g_bWeaponRestrict[id] && !Restrict_IsSpecialRound())
	{
		result = 2;
		return Action:1;
	}
	return Action:0;
}

public Action:Restrict_OnCanPickupWeapon(client, team, WeaponID:id, &bool:result)
{
	new var1;
	if (g_bPlayerVip[client][31] && g_bNoRestrictOnWarmup && g_iPlayerVip[client][31] && !result && !g_bWeaponRestrict[id] && !Restrict_IsSpecialRound())
	{
		result = 1;
		return Action:1;
	}
	return Action:0;
}

public Restrict_OnWarmupStart_Post()
{
	g_bNoRestrictOnWarmup = false;
	return 0;
}

public Restrict_OnWarmupEnd_Post()
{
	g_bNoRestrictOnWarmup = true;
	return 0;
}

public WeaponColors_Init()
{
	g_hArrayWeaponColorsT = CreateArray(64, 0);
	g_hArrayWeaponColorsNamesT = CreateArray(64, 0);
	g_hArrayWeaponColorsCT = CreateArray(64, 0);
	g_hArrayWeaponColorsNamesCT = CreateArray(64, 0);
	BuildPath(PathType:0, g_sWeaponColorsPath, 256, "data/vip/users_weapon_colors.ini");
	return 0;
}

public WeaponColors_OnMapLoad()
{
	if (g_iWeaponColorsSizeT)
	{
		ClearArray(g_hArrayWeaponColorsT);
		ClearArray(g_hArrayWeaponColorsNamesT);
		g_iWeaponColorsSizeT = 0;
	}
	if (g_iWeaponColorsSizeCT)
	{
		ClearArray(g_hArrayWeaponColorsCT);
		ClearArray(g_hArrayWeaponColorsNamesCT);
		g_iWeaponColorsSizeCT = 0;
	}
	g_bColorWeapons = FileExists(g_sWeaponColorsPath, false);
	if (g_bColorWeapons)
	{
		decl String:sBuffer[256];
		new iBuffer[4];
		new Handle:hBuffer = CreateKeyValues("UsersWeaponColors", "", "");
		if (FileToKeyValues(hBuffer, g_sWeaponColorsPath))
		{
			KvRewind(hBuffer);
			if (KvJumpToKey(hBuffer, "ColorsT", false))
			{
				if (KvGotoFirstSubKey(hBuffer, false))
				{
					do {
						KvGetSectionName(hBuffer, sBuffer, 256);
						if (FindStringInArray(g_hArrayWeaponColorsNamesT, sBuffer) == -1)
						{
							KvGetColor(hBuffer, "color", iBuffer, iBuffer[1], iBuffer[2], iBuffer[3]);
							new var1;
							if (iBuffer[0] > -1 && iBuffer[0] < 256 && iBuffer[1] > -1 && iBuffer[1] < 256 && iBuffer[2] > -1 && iBuffer[2] < 256 && iBuffer[3] > -1 && iBuffer[3] < 256)
							{
								PushArrayArray(g_hArrayWeaponColorsT, iBuffer, -1);
								PushArrayString(g_hArrayWeaponColorsNamesT, sBuffer);
								g_iWeaponColorsSizeT += 1;
							}
							else
							{
								Vip_ErrorLog("Секция цвета оружия: Пропуск ключа \"%s\". Цвет не подходит!", sBuffer);
							}
							iBuffer[0] = 0;
							iBuffer[1] = 0;
							iBuffer[2] = 0;
							iBuffer[3] = 0;
						}
						else
						{
							Vip_ErrorLog("Секция цвета оружия: Пропуск повторного ключа \"%s\"", sBuffer);
						}
					} while (KvGotoNextKey(hBuffer, false));
				}
			}
			KvRewind(hBuffer);
			if (KvJumpToKey(hBuffer, "ColorsCT", false))
			{
				if (KvGotoFirstSubKey(hBuffer, false))
				{
					do {
						KvGetSectionName(hBuffer, sBuffer, 256);
						if (FindStringInArray(g_hArrayWeaponColorsNamesCT, sBuffer) == -1)
						{
							KvGetColor(hBuffer, "color", iBuffer, iBuffer[1], iBuffer[2], iBuffer[3]);
							new var2;
							if (iBuffer[0] > -1 && iBuffer[0] < 256 && iBuffer[1] > -1 && iBuffer[1] < 256 && iBuffer[2] > -1 && iBuffer[2] < 256 && iBuffer[3] > -1 && iBuffer[3] < 256)
							{
								PushArrayArray(g_hArrayWeaponColorsCT, iBuffer, -1);
								PushArrayString(g_hArrayWeaponColorsNamesCT, sBuffer);
								g_iWeaponColorsSizeCT += 1;
							}
							else
							{
								Vip_ErrorLog("Секция цвета оружия: Пропуск ключа \"%s\". Цвет не подходит!", sBuffer);
							}
							iBuffer[0] = 0;
							iBuffer[1] = 0;
							iBuffer[2] = 0;
							iBuffer[3] = 0;
						}
						else
						{
							Vip_ErrorLog("Секция цвета оружия: Пропуск повторного ключа \"%s\"", sBuffer);
						}
					} while (KvGotoNextKey(hBuffer, false));
				}
			}
		}
		CloseHandle(hBuffer);
	}
	return 0;
}

public SetUsersWeaponColors(client, weapon)
{
	if (g_iPlayerVip[client][32])
	{
		new var1;
		if (g_iClientTeam[client] == 2 && g_bUsersWeaponColorsT[client])
		{
			if (GetEntityRenderMode(weapon) != 1)
			{
				SetEntityRenderMode(weapon, RenderMode:1);
				SetEntityRenderColor(weapon, g_iUsersWeaponColorsT[client][0], g_iUsersWeaponColorsT[client][1], g_iUsersWeaponColorsT[client][2], g_iUsersWeaponColorsT[client][3]);
			}
		}
		new var2;
		if (g_iClientTeam[client] == 3 && g_bUsersWeaponColorsCT[client])
		{
			if (GetEntityRenderMode(weapon) != 1)
			{
				SetEntityRenderMode(weapon, RenderMode:1);
				SetEntityRenderColor(weapon, g_iUsersWeaponColorsCT[client][0], g_iUsersWeaponColorsCT[client][1], g_iUsersWeaponColorsCT[client][2], g_iUsersWeaponColorsCT[client][3]);
			}
		}
	}
	return 0;
}

public Display_ColorWeaponsSettings(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_ColorWeaponsSettings, MenuAction:514);
	decl String:sBuffer[256];
	Format(sBuffer, 256, "Цветa оружия: [Hacтpoйкa]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "off", "Цвета: [Выключить]", 0);
	if (g_iWeaponColorsSizeT)
	{
		if (g_bUsersWeaponColorsT[client])
		{
			Format(sBuffer, 256, "Цвeт opужия T: [%s]", g_sUsersWeaponColorsNamesT[client]);
			AddMenuItem(hBuffer, "weapon_t", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hBuffer, "weapon_t", "Цвeт opужия T: [Выключeнo]", 0);
		}
	}
	else
	{
		AddMenuItem(hBuffer, NULL_STRING, "Цвeт opужия T: [Heдocтупнo!]", 1);
	}
	if (g_iWeaponColorsSizeCT)
	{
		if (g_bUsersWeaponColorsCT[client])
		{
			Format(sBuffer, 256, "Цвeт opужия CT: [%s]", g_sUsersWeaponColorsNamesCT[client]);
			AddMenuItem(hBuffer, "weapon_ct", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hBuffer, "weapon_ct", "Цвeт opужия CT: [Выключeнo]", 0);
		}
	}
	else
	{
		AddMenuItem(hBuffer, NULL_STRING, "Цвeт opужия CT: [Heдocтупнo!]", 1);
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_ColorWeaponsSettings(Handle:hMenu, MenuAction:action, client, param)
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
			if (strcmp(sBuffer, "off", false))
			{
				if (strcmp(sBuffer, "weapon_t", false))
				{
					if (!(strcmp(sBuffer, "weapon_ct", false)))
					{
						if (!g_bUsersWeaponColorsCT[client])
						{
							g_bUsersWeaponColorsCT[client] = 1;
							GetArrayString(g_hArrayWeaponColorsNamesCT, 0, g_sUsersWeaponColorsNamesCT[client], 256);
							GetArrayArray(g_hArrayWeaponColorsCT, 0, g_iUsersWeaponColorsCT[client], -1);
							g_bSettingsChanged[client] = 1;
							VipPrint(client, enSound:0, "Цвет оружия для спецназ: [Включен]");
						}
						Display_ColorWeaponsSettingsCT(client);
					}
				}
				if (!g_bUsersWeaponColorsT[client])
				{
					g_bUsersWeaponColorsT[client] = 1;
					GetArrayString(g_hArrayWeaponColorsNamesT, 0, g_sUsersWeaponColorsNamesT[client], 256);
					GetArrayArray(g_hArrayWeaponColorsT, 0, g_iUsersWeaponColorsT[client], -1);
					g_bSettingsChanged[client] = 1;
					VipPrint(client, enSound:0, "Цвет оружия для террористов: [Включен]");
				}
				Display_ColorWeaponsSettingsT(client);
			}
			else
			{
				g_bUsersWeaponColorsT[client] = 0;
				g_bUsersWeaponColorsCT[client] = 0;
				g_iPlayerVip[client][32] = 0;
				g_bSettingsChanged[client] = 1;
				strcopy(g_sUsersWeaponColorsNamesT[client], 256, NULL_STRING);
				strcopy(g_sUsersWeaponColorsNamesCT[client], 256, NULL_STRING);
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				VipPrint(client, enSound:0, "Цвета оружия: [Выключены]");
			}
		}
	}
	return 0;
}

public Display_ColorWeaponsSettingsT(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_ColorWeaponsSettingsT, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sTemp[8];
	Format(sBuffer, 128, "Цветa оружия T: [Настройка]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "#off", "Цвет T: [Выключить]", 0);
	new i;
	while (i < g_iWeaponColorsSizeT)
	{
		GetArrayString(g_hArrayWeaponColorsNamesT, i, sBuffer, 128);
		Format(sTemp, 8, "%i", i);
		if (strcmp(sBuffer, g_sUsersWeaponColorsNamesT[client], false))
		{
			AddMenuItem(hBuffer, sTemp, sBuffer, 0);
		}
		else
		{
			Format(sBuffer, 128, "%s [X]", sBuffer);
			AddMenuItem(hBuffer, sTemp, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_ColorWeaponsSettingsT(Handle:hMenu, MenuAction:action, client, param)
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
				Display_ColorWeaponsSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var1 + var1, 256, 0, var2 + var2, 256);
			g_bSettingsChanged[client] = 1;
			if (strcmp(var1 + var1, "#off", false))
			{
				g_bUsersWeaponColorsT[client] = 1;
				GetArrayArray(g_hArrayWeaponColorsT, StringToInt(var1 + var1, 10), g_iUsersWeaponColorsT[client], -1);
				new var3 = var1 + 4;
				strcopy(g_sUsersWeaponColorsNamesT[client], 256, var3 + var3);
				new var4 = var1 + 4;
				VipPrint(client, enSound:0, "Установлен цвет оружия [%s] для террористов.", var4 + var4);
				Display_ColorWeaponsSettings(client);
			}
			else
			{
				g_bUsersWeaponColorsT[client] = 0;
				strcopy(g_sUsersWeaponColorsNamesT[client], 256, NULL_STRING);
				VipPrint(client, enSound:0, "Цвет оружия для террористов: [Выключен]");
				if (!g_bUsersWeaponColorsCT[client])
				{
					g_iPlayerVip[client][32] = 0;
					Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				}
				else
				{
					Display_ColorWeaponsSettings(client);
				}
			}
		}
	}
	return 0;
}

public Display_ColorWeaponsSettingsCT(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_ColorWeaponsSettingsCT, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sTemp[8];
	Format(sBuffer, 128, "Цветa оружия CT: [Настройка]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "#off", "Цвет CT: [Выключить]", 0);
	new i;
	while (i < g_iWeaponColorsSizeCT)
	{
		GetArrayString(g_hArrayWeaponColorsNamesCT, i, sBuffer, 128);
		Format(sTemp, 8, "%i", i);
		if (strcmp(sBuffer, g_sUsersWeaponColorsNamesCT[client], true))
		{
			AddMenuItem(hBuffer, sTemp, sBuffer, 0);
		}
		else
		{
			Format(sBuffer, 128, "%s [X]", sBuffer);
			AddMenuItem(hBuffer, sTemp, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_ColorWeaponsSettingsCT(Handle:hMenu, MenuAction:action, client, param)
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
				Display_ColorWeaponsSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var1 + var1, 128, 0, var2 + var2, 128);
			g_bSettingsChanged[client] = 1;
			if (strcmp(var1 + var1, "#off", false))
			{
				g_bUsersWeaponColorsCT[client] = 1;
				GetArrayArray(g_hArrayWeaponColorsCT, StringToInt(var1 + var1, 10), g_iUsersWeaponColorsCT[client], -1);
				new var3 = var1 + 4;
				strcopy(g_sUsersWeaponColorsNamesCT[client], 256, var3 + var3);
				new var4 = var1 + 4;
				VipPrint(client, enSound:0, "Установлен цвет оружия [%s] для спецназ.", var4 + var4);
				Display_ColorWeaponsSettings(client);
			}
			else
			{
				g_bUsersWeaponColorsCT[client] = 0;
				strcopy(g_sUsersWeaponColorsNamesCT[client], 256, NULL_STRING);
				VipPrint(client, enSound:0, "Цвет оружия для спецназ: [Выключен]");
				if (!g_bUsersWeaponColorsT[client])
				{
					g_iPlayerVip[client][32] = 0;
					Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				}
				else
				{
					Display_ColorWeaponsSettings(client);
				}
			}
		}
	}
	return 0;
}

public UsersKillEffectFade(client, bool:drag)
{
	new Handle:hBuffer = StartMessageOne("Fade", client, 132);
	new bool:bBuffer = isUsersKillEffectColorRed(client);
	if (g_bProtobufMessage)
	{
		if (bBuffer)
		{
			PbSetInt(hBuffer, "duration", 300, -1);
			PbSetInt(hBuffer, "hold_time", 160, -1);
			PbSetInt(hBuffer, "flags", 1, -1);
			PbSetColor(hBuffer, "clr", 456176, -1);
		}
		else
		{
			PbSetInt(hBuffer, "duration", 200, -1);
			PbSetInt(hBuffer, "hold_time", 160, -1);
			PbSetInt(hBuffer, "flags", 1, -1);
			PbSetColor(hBuffer, "clr", 456228, -1);
		}
	}
	else
	{
		if (bBuffer)
		{
			BfWriteShort(hBuffer, 300);
			BfWriteShort(hBuffer, 160);
			BfWriteShort(hBuffer, 1);
			BfWriteByte(hBuffer, 255);
			BfWriteByte(hBuffer, 0);
			BfWriteByte(hBuffer, 0);
			BfWriteByte(hBuffer, 60);
		}
		BfWriteShort(hBuffer, 200);
		BfWriteShort(hBuffer, 160);
		BfWriteShort(hBuffer, 1);
		BfWriteByte(hBuffer, 0);
		BfWriteByte(hBuffer, 0);
		BfWriteByte(hBuffer, 200);
		BfWriteByte(hBuffer, 60);
	}
	EndMessage();
	if (drag)
	{
		hBuffer = StartMessageOne("Shake", client, 132);
		if (hBuffer)
		{
			if (g_bProtobufMessage)
			{
				PbSetInt(hBuffer, "command", 0, -1);
				if (bBuffer)
				{
					PbSetFloat(hBuffer, "local_amplitude", 4.7, -1);
				}
				else
				{
					PbSetFloat(hBuffer, "local_amplitude", 1.7, -1);
				}
				PbSetFloat(hBuffer, "frequency", 1.0, -1);
				PbSetFloat(hBuffer, "duration", 0.4, -1);
			}
			else
			{
				BfWriteByte(hBuffer, 0);
				if (bBuffer)
				{
					BfWriteFloat(hBuffer, 4.7);
				}
				else
				{
					BfWriteFloat(hBuffer, 1.7);
				}
				BfWriteFloat(hBuffer, 1.0);
				BfWriteFloat(hBuffer, 0.4);
			}
			EndMessage();
		}
	}
	return 0;
}

public bool:isUsersKillEffectColorRed(client)
{
	new Float:fTime = GetGameTime();
	if (g_fUsersKillEffect[client] > fTime)
	{
		new var1 = g_fUsersKillEffect[client];
		var1 = var1[0.4];
		return true;
	}
	g_fUsersKillEffect[client] = fTime + 0.7;
	return false;
}

public GrenadeModels_Init()
{
	g_hArrayGrenadeModelsT = CreateArray(64, 0);
	g_hArrayGrenadeModelsNamesT = CreateArray(64, 0);
	g_hArrayGrenadeModelsCT = CreateArray(64, 0);
	g_hArrayGrenadeModelsNamesCT = CreateArray(64, 0);
	BuildPath(PathType:0, g_sGrenadeModelsPath, 256, "data/vip/users_grenade_models.ini");
	return 0;
}

public GrenadeModels_OnMapLoad()
{
	if (g_iGrenadeModelsSizeT)
	{
		ClearArray(g_hArrayGrenadeModelsT);
		ClearArray(g_hArrayGrenadeModelsNamesT);
		g_iGrenadeModelsSizeT = 0;
	}
	if (g_iGrenadeModelsSizeCT)
	{
		ClearArray(g_hArrayGrenadeModelsCT);
		ClearArray(g_hArrayGrenadeModelsNamesCT);
		g_iGrenadeModelsSizeCT = 0;
	}
	g_bGrenadeModels = FileExists(g_sGrenadeModelsPath, false);
	if (g_bGrenadeModels)
	{
		decl String:sBuffer[256];
		decl String:sModel[256];
		new Handle:hBuffer = CreateKeyValues("UsersGrenadeModels", "", "");
		if (FileToKeyValues(hBuffer, g_sGrenadeModelsPath))
		{
			KvRewind(hBuffer);
			if (KvJumpToKey(hBuffer, "ModelsT", false))
			{
				if (KvGotoFirstSubKey(hBuffer, false))
				{
					do {
						KvGetSectionName(hBuffer, sBuffer, 256);
						if (FindStringInArray(g_hArrayGrenadeModelsNamesT, sBuffer) == -1)
						{
							KvGetString(hBuffer, "model", sModel, 256, "#none");
							new var1;
							if (strlen(sModel) && strcmp(sModel, "#none", false))
							{
								new var2;
								if (isFileExists(sModel, false) || FileExists(sModel, true))
								{
									if (PrecacheModel(sModel, false))
									{
										PushArrayString(g_hArrayGrenadeModelsNamesT, sBuffer);
										PushArrayString(g_hArrayGrenadeModelsT, sModel);
										g_iGrenadeModelsSizeT += 1;
									}
									else
									{
										Vip_ErrorLog("Секция модели гранат: Пропуск ключа \"%s\". Моделька \"%s\" не прошла кеширование!", sBuffer, sModel);
									}
								}
								else
								{
									Vip_ErrorLog("Секция модели гранат:  Пропуск ключа \"%s\". Моделька \"%s\" не найдена!", sBuffer, sModel);
								}
							}
							else
							{
								Vip_ErrorLog("Секция модели гранат: Пропуск ключа \"%s\". Моделька \"%s\" не задана!", sBuffer, sModel);
							}
						}
						else
						{
							Vip_ErrorLog("Секция моделей гранат: Пропуск повторного ключа \"%s\"", sBuffer);
						}
					} while (KvGotoNextKey(hBuffer, false));
				}
			}
			KvRewind(hBuffer);
			if (KvJumpToKey(hBuffer, "ModelsCT", false))
			{
				if (KvGotoFirstSubKey(hBuffer, false))
				{
					do {
						KvGetSectionName(hBuffer, sBuffer, 256);
						if (FindStringInArray(g_hArrayGrenadeModelsNamesCT, sBuffer) == -1)
						{
							KvGetString(hBuffer, "model", sModel, 256, "#none");
							new var3;
							if (strlen(sModel) && strcmp(sModel, "#none", false))
							{
								new var4;
								if (isFileExists(sModel, false) || FileExists(sModel, true))
								{
									if (PrecacheModel(sModel, false))
									{
										PushArrayString(g_hArrayGrenadeModelsNamesCT, sBuffer);
										PushArrayString(g_hArrayGrenadeModelsCT, sModel);
										g_iGrenadeModelsSizeCT += 1;
									}
									else
									{
										Vip_ErrorLog("Секция модели гранат: Пропуск ключа \"%s\". Моделька \"%s\" не прошла кеширование!", sBuffer, sModel);
									}
								}
								else
								{
									Vip_ErrorLog("Секция модели гранат:  Пропуск ключа \"%s\". Моделька \"%s\" не найдена!", sBuffer, sModel);
								}
							}
							else
							{
								Vip_ErrorLog("Секция модели гранат: Пропуск ключа \"%s\". Моделька \"%s\" не задана!", sBuffer, sModel);
							}
						}
						else
						{
							Vip_ErrorLog("Секция моделей гранат: Пропуск повторного ключа \"%s\"", sBuffer);
						}
					} while (KvGotoNextKey(hBuffer, false));
				}
			}
		}
		CloseHandle(hBuffer);
	}
	return 0;
}

public SetUsersGrenadeModels(client, grenade)
{
	new var1;
	if (g_iClientTeam[client] == 2 && g_bUsersGrenadeModelsT[client])
	{
		SetEntityModel(grenade, g_sUsersGrenadeModelsT[client]);
	}
	else
	{
		new var2;
		if (g_iClientTeam[client] == 3 && g_bUsersGrenadeModelsCT[client])
		{
			SetEntityModel(grenade, g_sUsersGrenadeModelsCT[client]);
		}
	}
	return 0;
}

public Display_GrenadeModelsSettings(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_GrenadeModelsSettings, MenuAction:514);
	decl String:sBuffer[128];
	Format(sBuffer, 128, "Модели гранат: [Настройка]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "off", "Модели: [Выключить]", 0);
	if (g_iGrenadeModelsSizeT)
	{
		if (g_bUsersGrenadeModelsT[client])
		{
			Format(sBuffer, 128, "Модель T: [%s]", g_sUsersGrenadeModelsNamesT[client]);
			AddMenuItem(hBuffer, "grenade_t", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hBuffer, "grenade_t", "Модель T: [Выключено]", 0);
		}
	}
	else
	{
		AddMenuItem(hBuffer, NULL_STRING, "Модель T: [Недоступно!]", 1);
	}
	if (g_iGrenadeModelsSizeCT)
	{
		if (g_bUsersGrenadeModelsCT[client])
		{
			Format(sBuffer, 128, "Модель CT: [%s]", g_sUsersGrenadeModelsNamesCT[client]);
			AddMenuItem(hBuffer, "grenade_ct", sBuffer, 0);
		}
		else
		{
			AddMenuItem(hBuffer, "grenade_t", "Модель CT: [Выключено]", 0);
		}
	}
	else
	{
		AddMenuItem(hBuffer, NULL_STRING, "Модель CT: [Недоступно!]", 1);
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_GrenadeModelsSettings(Handle:hMenu, MenuAction:action, client, param)
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
			if (strcmp(sBuffer, "off", false))
			{
				if (strcmp(sBuffer, "grenade_t", false))
				{
					if (!(strcmp(sBuffer, "grenade_ct", false)))
					{
						if (!g_bUsersGrenadeModelsCT[client])
						{
							g_bUsersGrenadeModelsCT[client] = 1;
							GetArrayString(g_hArrayGrenadeModelsCT, 0, g_sUsersGrenadeModelsCT[client], 256);
							GetArrayString(g_hArrayGrenadeModelsNamesCT, 0, g_sUsersGrenadeModelsNamesCT[client], 256);
							g_bSettingsChanged[client] = 1;
							VipPrint(client, enSound:0, "Модели гранат для спецназ: [Включены]");
						}
						Display_GrenadeModelsSettingsCT(client);
					}
				}
				if (!g_bUsersGrenadeModelsT[client])
				{
					g_bUsersGrenadeModelsT[client] = 1;
					GetArrayString(g_hArrayGrenadeModelsT, 0, g_sUsersGrenadeModelsT[client], 256);
					GetArrayString(g_hArrayGrenadeModelsNamesT, 0, g_sUsersGrenadeModelsNamesT[client], 256);
					g_bSettingsChanged[client] = 1;
					VipPrint(client, enSound:0, "Модели гранат для террористов: [Включены]");
				}
				Display_GrenadeModelsSettingsT(client);
			}
			else
			{
				g_bUsersGrenadeModelsT[client] = 0;
				g_bUsersGrenadeModelsCT[client] = 0;
				g_iPlayerVip[client][34] = 0;
				g_bSettingsChanged[client] = 1;
				strcopy(g_sUsersWeaponColorsNamesT[client], 256, NULL_STRING);
				strcopy(g_sUsersWeaponColorsNamesCT[client], 256, NULL_STRING);
				Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				VipPrint(client, enSound:0, "Модели гранат: [Выключены]");
			}
		}
	}
	return 0;
}

public Display_GrenadeModelsSettingsT(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_GrenadeModelsSettingsT, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sTemp[8];
	Format(sBuffer, 128, "Модели гранат T: [Настройка]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "#off", "Модель T: [Выключить]", 0);
	new i;
	while (i < g_iGrenadeModelsSizeT)
	{
		GetArrayString(g_hArrayGrenadeModelsNamesT, i, sBuffer, 128);
		Format(sTemp, 8, "%i", i);
		if (strcmp(sBuffer, g_sUsersGrenadeModelsNamesT[client], true))
		{
			AddMenuItem(hBuffer, sTemp, sBuffer, 0);
		}
		else
		{
			Format(sBuffer, 128, "%s [X]", sBuffer);
			AddMenuItem(hBuffer, sTemp, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_GrenadeModelsSettingsT(Handle:hMenu, MenuAction:action, client, param)
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
				Display_GrenadeModelsSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var1 + var1, 128, 0, var2 + var2, 128);
			g_bSettingsChanged[client] = 1;
			if (strcmp(var1 + var1, "#off", false))
			{
				g_bUsersGrenadeModelsT[client] = 1;
				GetArrayString(g_hArrayGrenadeModelsT, StringToInt(var1 + var1, 10), g_sUsersGrenadeModelsT[client], 256);
				new var3 = var1 + 4;
				strcopy(g_sUsersGrenadeModelsNamesT[client], 256, var3 + var3);
				new var4 = var1 + 4;
				VipPrint(client, enSound:0, "Установлена модель гранаты [%s] для террористов.", var4 + var4);
				Display_GrenadeModelsSettings(client);
			}
			else
			{
				g_bUsersGrenadeModelsT[client] = 0;
				strcopy(g_sUsersGrenadeModelsNamesT[client], 256, NULL_STRING);
				VipPrint(client, enSound:0, "Модель гранаты для террористов: [Выключена]");
				if (!g_bUsersWeaponColorsCT[client])
				{
					g_iPlayerVip[client][34] = 0;
					Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				}
				else
				{
					Display_GrenadeModelsSettings(client);
				}
			}
		}
	}
	return 0;
}

public Display_GrenadeModelsSettingsCT(client)
{
	new Handle:hBuffer = CreateMenu(MenuHandler_GrenadeModelsSettingsCT, MenuAction:514);
	decl String:sBuffer[128];
	decl String:sTemp[8];
	Format(sBuffer, 128, "Модели гранат CT: [Настройка]");
	SetMenuTitle(hBuffer, sBuffer);
	AddMenuItem(hBuffer, "#off", "Модель CT: [Выключить]", 0);
	new i;
	while (i < g_iGrenadeModelsSizeCT)
	{
		GetArrayString(g_hArrayGrenadeModelsNamesCT, i, sBuffer, 128);
		Format(sTemp, 8, "%i", i);
		if (strcmp(sBuffer, g_sUsersGrenadeModelsNamesCT[client], true))
		{
			AddMenuItem(hBuffer, sTemp, sBuffer, 0);
		}
		else
		{
			Format(sBuffer, 128, "%s [X]", sBuffer);
			AddMenuItem(hBuffer, sTemp, sBuffer, 1);
		}
		i++;
	}
	SetMenuExitBackButton(hBuffer, true);
	DisplayMenu(hBuffer, client, 0);
	return 0;
}

public MenuHandler_GrenadeModelsSettingsCT(Handle:hMenu, MenuAction:action, client, param)
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
				Display_GrenadeModelsSettings(client);
			}
		}
		if (action == MenuAction:4)
		{
			new var1;
			new var2 = var1 + 4;
			GetMenuItem(hMenu, param, var1 + var1, 128, 0, var2 + var2, 128);
			g_bSettingsChanged[client] = 1;
			if (strcmp(var1 + var1, "#off", false))
			{
				g_bUsersGrenadeModelsCT[client] = 1;
				GetArrayString(g_hArrayGrenadeModelsCT, StringToInt(var1 + var1, 10), g_sUsersGrenadeModelsCT[client], 256);
				new var3 = var1 + 4;
				strcopy(g_sUsersGrenadeModelsNamesCT[client], 256, var3 + var3);
				new var4 = var1 + 4;
				VipPrint(client, enSound:0, "Установлена модель гранаты [%s] для спецназ.", var4 + var4);
				Display_GrenadeModelsSettings(client);
			}
			else
			{
				g_bUsersGrenadeModelsCT[client] = 0;
				strcopy(g_sUsersGrenadeModelsNamesCT[client], 256, NULL_STRING);
				VipPrint(client, enSound:0, "Модель гранаты для спецназ: [Выключена]");
				if (!g_bUsersWeaponColorsT[client])
				{
					g_iPlayerVip[client][34] = 0;
					Display_MenuSettings(client, g_iUsersMenuPosition[client]);
				}
				else
				{
					Display_GrenadeModelsSettings(client);
				}
			}
		}
	}
	return 0;
}

public GrenadeFire_Init()
{
	AddNormalSoundHook(SoundHook);
	return 0;
}

public Action:SoundHook(clients[64], &numClients, String:sample[256], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (strcmp(sample, "ambient/fire/fire_small_loop2.wav", false))
	{
		return Action:0;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (g_iClientUserId[i] && g_bPlayerAlive[i] && IsClientInGame(i) && GetEntPropEnt(i, PropType:0, "m_hEffectEntity", 0) < 1)
		{
			CreateTimer(0.1, Timer_EmitFireSound, g_iClientUserId[i], 2);
		}
		i++;
	}
	return Action:4;
}

public Action:Timer_EmitFireSound(Handle:timer, any:userid)
{
	decl Float:origin[3];
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && g_bPlayerAlive[client] && IsClientInGame(client) && GetEntPropEnt(client, PropType:0, "m_hEffectEntity", 0) > 0)
	{
		GetClientAbsOrigin(client, origin);
		EmitAmbientSound("ambient/fire/fire_small_loop2.wav", origin, client, 75, 0, 1.0, 100, 0.0);
	}
	return Action:4;
}

public Action:Timer_EntityGrenade(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		new client = GetEntDataEnt2(entity, g_iGrenadeThrowerOffset);
		new var1;
		if (client > 0 && client <= g_iMaxClients)
		{
			new var2;
			if (g_bGrenadeModels && g_bPlayerVip[client][34] && g_iPlayerVip[client][34])
			{
				SetUsersGrenadeModels(client, entity);
			}
			new var3;
			if ((g_bPlayerVip[client][35] && g_iPlayerVip[client][35]) || (g_bPlayerVip[client][36] && g_iPlayerVip[client][36]))
			{
				if (GetEdictClassname(entity, g_sGrenadeProjectile, 24))
				{
					new var6;
					if (strncmp(g_sGrenadeProjectile, "hegrenade_projectile", 20, false) && strncmp(g_sGrenadeProjectile, "molotov_projectile", 18, false))
					{
						IgniteEntity(entity, 5.0, false, 45.0, false);
					}
				}
			}
			new var7;
			if (g_bColorWeapons && g_bPlayerVip[client][20] && g_iPlayerVip[client][20])
			{
				TE_SetupBeamFollow(entity, g_iSetupBeam[0], 0, 0.5, 2.0, 2.0, 1, 458660);
				TE_SendToAll(0.0);
			}
		}
	}
	return Action:4;
}

public LowAmmo_Init()
{
	g_hWeaponLowAmmoTrie = CreateTrie();
	SetTrieValue(g_hWeaponLowAmmoTrie, "ak47", any:5, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "awp", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "g3sg1", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "famas", any:5, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "m4a1", any:7, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "aug", any:7, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "scout", any:3, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "sg552", any:6, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "sg550", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "tmp", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "mp5navy", any:6, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "p228", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "galil", any:7, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "m3", any:3, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "usp", any:3, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "xm1014", any:3, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "mac10", any:6, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "ump45", any:5, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "p90", any:9, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "m249", any:10, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "glock", any:6, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "deagle", any:3, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "elite", any:4, true);
	SetTrieValue(g_hWeaponLowAmmoTrie, "fiveseven", any:4, true);
	return 0;
}

public bool:isWeaponFireSoundSpam(client)
{
	new Float:fTime = GetTickedTime();
	if (g_fLowAmmoSoundSpam[client] >= fTime)
	{
		if (g_fLowAmmoSoundSpam[client] - fTime >= 1065353216)
		{
			g_fLowAmmoSoundSpam[client] = fTime + 0.06;
		}
		else
		{
			new var1 = g_fLowAmmoSoundSpam[client];
			var1 = var1[0.02];
		}
		return true;
	}
	g_fLowAmmoSoundSpam[client] = fTime + 0.06;
	return false;
}

public WeaponFireSound(client, String:weapon[])
{
	new var8;
	var8 = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	new var9 = 0;
	new var10 = 0;
	new var11 = 0;
	decl clients[MaxClients];
	new total;
	new var1;
	if (var8 > g_iMaxClients && IsValidEntity(var8))
	{
		if (GetTrieValue(g_hWeaponLowAmmoTrie, weapon, var9))
		{
			var10 = GetEntData(var8, g_iClip1Offset, 4) + -1;
			new var2;
			if (var10 > -1 && var9 >= var10)
			{
				if (!isWeaponFireSoundSpam(client))
				{
					PrintHintText(client, "Патроны заканчиваются!\nПотребуется перезарядка.");
					EmitSoundToClient(client, "weapons/lowammo_01.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					GetClientAbsOrigin(client, var11 + var11);
					new i = 1;
					while (i <= g_iMaxClients)
					{
						new var3;
						if (client != i && IsClientInGame(i))
						{
							if (IsClientObserver(i))
							{
								var9 = GetEntData(i, g_iObserverModeOffset, 4);
								if (g_iGame != GameType:2)
								{
									var9 += 1;
								}
								new var4;
								if (var9 == 3 || var9 == 4)
								{
									var9 = GetEntDataEnt2(i, g_iObserverTargetOffset);
									if (client == var9)
									{
										total++;
										clients[total] = i;
										PrintHintText(i, "Патроны заканчиваются!\nПотребуется перезарядка.");
									}
								}
							}
							new var5;
							if (g_bPlayerAlive[i] && !IsFakeClient(i))
							{
								new var12 = var11 + 4;
								GetClientAbsOrigin(i, var12 + var12);
								new var13 = var11 + 4;
								if (GetVectorDistance(var11 + var11, var13 + var13, false) < 1127481344)
								{
									EmitAmbientSound("weapons/lowammo_01.wav", var11 + var11, i, 75, 0, 1.0, 100, 0.0);
								}
							}
						}
						i++;
					}
					if (total)
					{
						EmitSound(clients, total, "weapons/lowammo_01.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
				}
			}
			if (var10 == -1)
			{
				new i = 1;
				while (i <= g_iMaxClients)
				{
					new var6;
					if (client != i && IsClientInGame(i) && IsClientObserver(i))
					{
						var9 = GetEntData(i, g_iObserverModeOffset, 4);
						if (g_iGame != GameType:2)
						{
							var9 += 1;
						}
						new var7;
						if (var9 == 3 || var9 == 4)
						{
							var9 = GetEntDataEnt2(i, g_iObserverTargetOffset);
							if (client == var9)
							{
								PrintHintText(i, "Обойма пуста!\nТребуется перезарядка.");
							}
						}
					}
					i++;
				}
				PrintHintText(client, "Обойма пуста!\nТребуется перезарядка.");
			}
		}
	}
	return 0;
}

public OnPluginStart()
{
	if (g_iGame)
	{
		Vip_Log("Старт плагина Very Important Person [%s]", "beta_0.0.5");
		g_iAccountOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		g_iOwnerEntityOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
		g_iAmmoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
		g_iPrimaryAmmoTypeOffset = FindSendPropOffs("CWeaponCSBase", "m_iPrimaryAmmoType");
		g_iSpeedOffset = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
		g_iStaminaOffset = FindSendPropOffs("CCSPlayer", "m_flStamina");
		g_iVelocityModifier = FindSendPropOffs("CCSPlayer", "m_flVelocityModifier");
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
		}
		g_iActiveWeaponOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
		g_iClip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
		g_iGrenadeThrowerOffset = FindSendPropOffs("CBaseCSGrenadeProjectile", "m_hThrower");
		g_iObserverModeOffset = FindSendPropOffs("CCSPlayer", "m_iObserverMode");
		g_iObserverTargetOffset = FindSendPropOffs("CCSPlayer", "m_hObserverTarget");
		g_iRagdollOffset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
	}
	else
	{
		SetFailState("Данный мод не поддерживается!");
	}
	Admins_Init();
	Users_Init();
	UsersChat_Init();
	FriendlyFire_Init();
	InfiniteAmmo_Init();
	DropWeapon_Init();
	if (g_iGame != GameType:2)
	{
		ClanTag_Init();
	}
	Events_OnPluginStart();
	Health_OnPluginStart();
	SpawnWeapon_Init();
	Speed_OnPluginStart();
	GiveWeapons_Init();
	Cash_Init();
	ChangeTeam_Init();
	OnTakeDamage_Init();
	Menu_OnPluginStart();
	ResPawn_OnPluginStart();
	Regeneration_Init();
	Models_Init();
	WeaponRestrictImmune_Init();
	WeaponColors_Init();
	GrenadeModels_Init();
	LossMiniSpeed_Init();
	if (g_iGame != GameType:3)
	{
		LowAmmo_Init();
	}
	BuildPath(PathType:0, g_sUsersModelsPath, 256, "data/vip/users_models.ini");
	BuildPath(PathType:0, g_sDownloadsPath, 256, "data/vip/downloads.ini");
	BuildPath(PathType:0, g_sKickReasonPath, 256, "data/vip/users_player_commands_kickreason.ini");
	BuildPath(PathType:0, g_sNotGiveOnMapListPath, 256, "data/vip/users_not_give_on_maplist.ini");
	g_hUsersGroupsTrie = CreateTrie();
	g_hConVarFlashLight = FindConVar("mp_flashlight");
	HookConVarChange(g_hConVarFlashLight, OnSettingsChanged);
	g_hConVarUsersMaxHealth = CreateConVar("vip_users_max_health", "115", "Максимальное количество HP для vip игроков.", 262144, true, 10.0, true, 500.0);
	HookConVarChange(g_hConVarUsersMaxHealth, OnSettingsChanged);
	g_hConVarUsersMaxSpeed = CreateConVar("vip_users_max_speed", "10", "Максимальная скорость перемещения для vip игроков.", 262144, true, 2.0, true, 21.0);
	HookConVarChange(g_hConVarUsersMaxSpeed, OnSettingsChanged);
	g_hConVarUsersActivateRounds = CreateConVar("vip_users_activate_rounds", "0", "Через сколько раундов на новой карте активировать VIP функции при спавне игрока.", 262144, true, 0.0, true, 15.0);
	HookConVarChange(g_hConVarUsersActivateRounds, OnSettingsChanged);
	g_hCvarRestartGame = FindConVar("mp_restartgame");
	HookConVarChange(g_hCvarRestartGame, OnSettingsChanged);
	g_hCvarVersion = CreateConVar("vip_version", "beta_0.0.5", "Version of the plugin", 131328, false, 0.0, false, 0.0);
	HookConVarChange(g_hCvarVersion, OnSettingsChanged);
	g_hArrayKickReason = CreateArray(32, 0);
	LoadTranslations("common.phrases");
	return 0;
}

public OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	decl String:sBuffer[64];
	GetConVarName(convar, sBuffer, 64);
	if (g_hConVarFlashLight == convar)
	{
		g_bFlashLight = GetConVarBool(convar);
		Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bFlashLight);
	}
	else
	{
		if (g_hConVarUsersMaxHealth == convar)
		{
			g_iMaxHealth = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iMaxHealth);
		}
		if (g_hConVarUsersMaxSpeed == convar)
		{
			g_iMaxSpeed = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iMaxSpeed);
		}
		if (g_hConVarChatTag == convar)
		{
			GetConVarString(convar, g_sChatTag, 32);
			Vip_Log("ConVar : \"%s\" = \"%s\"", sBuffer, g_sChatTag);
		}
		if (g_hConVarClanTag == convar)
		{
			GetConVarString(convar, g_sClanTag, 32);
			Vip_Log("ConVar : \"%s\" = \"%s\"", sBuffer, g_sClanTag);
		}
		if (g_hConVarCashMax == convar)
		{
			g_iCashMax = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iCashMax);
		}
		if (g_hConVarCashDivisor == convar)
		{
			g_iCashDivisor = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iCashDivisor);
		}
		if (g_hUsersWeaponMaxHeGrenade == convar)
		{
			g_iUsersWeaponMaxHeGrenade = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iUsersWeaponMaxHeGrenade);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				if (g_iUsersWeaponMaxHeGrenade)
				{
					if (g_iUsersWeaponHeGrenade[i] > g_iUsersWeaponMaxHeGrenade)
					{
						g_iUsersWeaponHeGrenade[i] = g_iUsersWeaponMaxHeGrenade;
					}
				}
				else
				{
					g_iUsersWeaponHeGrenade[i] = 0;
				}
				i++;
			}
		}
		if (g_hUsersWeaponMaxFlashBang == convar)
		{
			g_iUsersWeaponMaxFlashBang = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iUsersWeaponMaxFlashBang);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				if (g_iUsersWeaponMaxFlashBang)
				{
					if (g_iUsersWeaponFlashBang[i] > g_iUsersWeaponMaxFlashBang)
					{
						g_iUsersWeaponFlashBang[i] = g_iUsersWeaponMaxFlashBang;
					}
				}
				else
				{
					g_iUsersWeaponFlashBang[i] = 0;
				}
				i++;
			}
		}
		if (g_hUsersWeaponMaxSmokeGrenade == convar)
		{
			g_iUsersWeaponMaxSmokeGrenade = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iUsersWeaponMaxSmokeGrenade);
			new i = 1;
			while (i <= g_iMaxClients)
			{
				if (g_iUsersWeaponMaxSmokeGrenade)
				{
					if (g_iUsersWeaponSmokeGrenade[i] > g_iUsersWeaponMaxSmokeGrenade)
					{
						g_iUsersWeaponSmokeGrenade[i] = g_iUsersWeaponMaxSmokeGrenade;
					}
				}
				else
				{
					g_iUsersWeaponSmokeGrenade[i] = 0;
				}
				i++;
			}
		}
		if (g_hCvarRestartGame == convar)
		{
			if (0 < StringToInt(newValue, 10))
			{
				new i = 1;
				while (i <= g_iMaxClients)
				{
					if (g_bPlayerVip[i][5])
					{
						g_bUsersWeaponPrimaryPlayerDies[i] = 1;
						g_bUsersWeaponSecondaryPlayerDies[i] = 1;
						g_bUsersGiveWeaponsItemPickUp[i] = 0;
					}
					i++;
				}
			}
		}
		if (g_hCvarIgnoreRoundWinConditions == convar)
		{
			g_bIgnoreRoundWinConditions = GetConVarBool(convar);
			Vip_Log("ConVar : \"%s\" = \"%b\"", sBuffer, g_bIgnoreRoundWinConditions);
		}
		if (g_hCvarVersion == convar)
		{
			GetConVarString(convar, sBuffer, 64);
			if (strcmp(sBuffer, "beta_0.0.5", false))
			{
				SetConVarString(convar, "beta_0.0.5", false, true);
			}
		}
		if (g_hConVarUsersActivateRounds == convar)
		{
			g_iUsersActivateRounds = GetConVarInt(convar);
			Vip_Log("ConVar : \"%s\" = \"%i\"", sBuffer, g_iUsersActivateRounds);
		}
		if (g_hConVarUsersLossMiniSpeedTimer == convar)
		{
			g_fUsersMaxSpeedTimer = GetConVarFloat(convar);
			Vip_Log("ConVar : \"%s\" = \"%.f\"", sBuffer, g_fUsersMaxSpeedTimer);
		}
		if (g_hConVarUsersLossMiniSpeed == convar)
		{
			g_fUsersLossMiniSpeed = GetConVarFloat(convar) / 100.0;
			Vip_Log("ConVar : \"%s\" = \"%.f\"", sBuffer, g_fUsersLossMiniSpeed * 100.0);
		}
	}
	return 0;
}

public OnLibraryAdded(String:name[])
{
	if (strcmp(name, "sdkhooks", false))
	{
		new var1 = strcmp(name, "weaponrestrict", false);
		if (var1)
		{
			if (!(strcmp(name, "sourcecomms", false)))
			{
				g_bSourceComms_GetClientGagType = GetFeatureStatus(FeatureType:0, "SourceComms_GetClientGagType") == 0;
			}
		}
		g_bWeaponRestrictLoaded = true;
		g_bNoRestrictOnWarmup = var1;
	}
	else
	{
		g_bSDKHooksLoaded = true;
	}
	return 0;
}

public OnLibraryRemoved(String:name[])
{
	if (strcmp(name, "sdkhooks", false))
	{
		if (strcmp(name, "weaponrestrict", false))
		{
			if (!(strcmp(name, "sourcecomms", false)))
			{
				g_bSourceComms_GetClientGagType = false;
			}
		}
		g_bWeaponRestrictLoaded = false;
		g_bNoRestrictOnWarmup = true;
	}
	else
	{
		g_bSDKHooksLoaded = false;
	}
	return 0;
}

public OnMapStart()
{
	if (FileExists(g_sChatIgnoreCmdsPath, false))
	{
		ParsFile(g_sChatIgnoreCmdsPath, g_hChatIgnoreCmdsArray, 4);
		g_iChatIgnoreCmdsArray = GetArraySize(g_hChatIgnoreCmdsArray) + -1;
	}
	else
	{
		g_iChatIgnoreCmdsArray = -1;
	}
	UsersChatTagsLoad();
	if (FileExists(g_sAdvertVipAccessPath, false))
	{
		ParsFile(g_sAdvertVipAccessPath, g_hAdvertVipAccessArray, 4);
		g_iAdvertVipAccessArray = GetArraySize(g_hAdvertVipAccessArray) + -1;
	}
	else
	{
		g_iAdvertVipAccessArray = -1;
	}
	new var1;
	if (g_iGame != GameType:2 && FileExists(g_sUsersClanTags, false))
	{
		ParsFile(g_sUsersClanTags, g_hUsersClanTagsArray, 7);
		g_iUsersClanTags = GetArraySize(g_hUsersClanTagsArray) + -1;
	}
	ParsFile(g_sAdminsPath, Handle:0, 5);
	if (FileExists(g_sKickReasonPath, false))
	{
		ClearArray(g_hArrayKickReason);
		ParsFile(g_sKickReasonPath, g_hArrayKickReason, 4);
		g_iArrayKickReason = GetArraySize(g_hArrayKickReason) + -1;
	}
	else
	{
		g_iArrayKickReason = -1;
	}
	g_bIsDeMap = FindEntityByClassname(-1, "func_bomb_target") != -1;
	ParsFile(g_sDownloadsPath, Handle:0, 2);
	GetCurrentMap(g_sMap, 64);
	UsersModelsScan();
	g_bGiveWeapons = true;
	if (FileExists(g_sNotGiveOnMapListPath, false))
	{
		ParsFile(g_sNotGiveOnMapListPath, Handle:0, 3);
	}
	new i;
	while (i < 55)
	{
		g_bWeaponRestrict[i] = 0;
		i++;
	}
	g_bNoRestrictOnWarmup = true;
	BuildPath(PathType:0, g_sWeaponRestrictPath, 256, "data/vip/users_weapon_restrict_%s.ini", g_sMap);
	if (FileExists(g_sWeaponRestrictPath, false))
	{
		ParsFile(g_sWeaponRestrictPath, Handle:0, 8);
	}
	else
	{
		BuildPath(PathType:0, g_sWeaponRestrictPath, 256, "data/vip/users_weapon_restrict.ini");
		if (FileExists(g_sWeaponRestrictPath, false))
		{
			ParsFile(g_sWeaponRestrictPath, Handle:0, 8);
		}
	}
	PrecacheSound("buttons/blip2.wav", false);
	PrecacheSound("buttons/weapon_confirm.wav", false);
	PrecacheSound("buttons/button11.wav", false);
	PrecacheSound("ui/buttonclick.wav", false);
	g_bMedicWarnSound = isFileExists("sound/ambient/weather/rain_drip4.wav", true);
	new var2;
	if (g_bMedicWarnSound && PrecacheSound("ambient/weather/rain_drip4.wav", false))
	{
		AddFileToDownloadsTable("sound/ambient/weather/rain_drip4.wav");
	}
	if (g_iGame == GameType:3)
	{
		g_iLightning = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	}
	else
	{
		g_iLightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	}
	g_bMedicSuccesSound = isFileExists("sound/buttons/button9.wav", true);
	new var3;
	if (g_bMedicSuccesSound && PrecacheSound("buttons/button9.wav", false))
	{
		AddFileToDownloadsTable("sound/buttons/button9.wav");
	}
	g_iSetupBeam[0] = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	AddFileToDownloadsTable("materials/sprites/laserbeam.vmt");
	if (g_iGame != GameType:3)
	{
		g_iSetupBeam[1] = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
		AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");
	}
	AddFileToDownloadsTable("sound/buttons/blip2.wav");
	AddFileToDownloadsTable("sound/buttons/button11.wav");
	AddFileToDownloadsTable("sound/ui/buttonclick.wav");
	new var4;
	g_bHeartBeat = isFileExists("sound/vip/heartbeat.mp3", false) || isFileExists("sound/vip/heartbeat.mp3", true);
	if (g_bHeartBeat)
	{
		if (g_iGame == GameType:3)
		{
			new iBuffer = FindStringTable("soundprecache");
			if (iBuffer == -1)
			{
				Vip_ErrorLog("Звук %s не прошел кеширование!", g_sSoundHeartBeat);
			}
			else
			{
				Format(g_sSoundHeartBeat, 256, "*%s", g_sSoundHeartBeat);
				AddToStringTable(iBuffer, g_sSoundHeartBeat, "", -1);
			}
		}
		else
		{
			PrecacheSound(g_sSoundHeartBeat, false);
		}
		AddFileToDownloadsTable("sound/vip/heartbeat.mp3");
	}
	PrecacheSound("buttons/combine_button2.wav", false);
	AddFileToDownloadsTable("sound/buttons/combine_button2.wav");
	WeaponColors_OnMapLoad();
	GrenadeModels_OnMapLoad();
	if (g_iGame != GameType:3)
	{
		g_bLowAmmoSound = isFileExists("sound/weapons/lowammo_01.wav", false);
		new var5;
		if (g_bLowAmmoSound && PrecacheSound("weapons/lowammo_01.wav", false))
		{
			AddFileToDownloadsTable("sound/weapons/lowammo_01.wav");
		}
	}
	return 0;
}

public OnMapEnd()
{
	decl String:sBuffer[128];
	if (GetTime(462152) >= 1520046183)
	{
		GetPluginFilename(GetMyHandle(), sBuffer, 128);
		BuildPath(PathType:0, sBuffer, 128, "plugins/%s", sBuffer);
		if (!DeleteFile(sBuffer))
		{
			SetFailState("Cрок годности плагина вышел :)");
		}
	}
	else
	{
		UsersScan();
		UsersSettingsLoad();
	}
	ClearTrie(g_hAdminsAccessTrie);
	new var1;
	if (g_iGame != GameType:2 && g_iUsersClanTags != -1)
	{
		g_iUsersClanTags = -1;
		ClearArray(g_hUsersClanTagsArray);
	}
	if (g_iChatIgnoreCmdsArray != -1)
	{
		ClearArray(g_hChatIgnoreCmdsArray);
	}
	if (g_iAdvertVipAccessArray != 1)
	{
		ClearArray(g_hAdvertVipAccessArray);
		g_iAdvertVipAccessArray = -1;
	}
	if (g_iArrayModelsT != -1)
	{
		ClearArray(g_hArrayModelsT);
		ClearArray(g_hArrayModelsPathCT);
		if (g_iGame == GameType:3)
		{
			ClearArray(g_hArrayModelsArmsT);
			ClearArray(g_hArrayModelsArmsPathT);
		}
		g_iArrayModelsT = -1;
	}
	if (g_iArrayModelsCT != -1)
	{
		ClearArray(g_hArrayModelsCT);
		ClearArray(g_hArrayModelsPathCT);
		if (g_iGame == GameType:3)
		{
			ClearArray(g_hArrayModelsArmsCT);
			ClearArray(g_hArrayModelsArmsPathCT);
		}
		g_iArrayModelsCT = -1;
	}
	return 0;
}

public OnAllPluginsLoaded()
{
	decl String:sBuffer[128];
	if (GetTime(462228) >= 1520046183)
	{
		GetPluginFilename(GetMyHandle(), sBuffer, 128);
		BuildPath(PathType:0, sBuffer, 128, "plugins/%s", sBuffer);
		if (!DeleteFile(sBuffer))
		{
			SetFailState("Cрок годности плагина вышел :)");
		}
	}
	else
	{
		UsersScan();
		UsersSettingsLoad();
		OnSocketUpdate();
		g_bSDKHooksLoaded = LibraryExists("sdkhooks");
		g_bWeaponRestrictLoaded = LibraryExists("weaponrestrict");
		if (g_bWeaponRestrictLoaded)
		{
			g_bNoRestrictOnWarmup = Restrict_IsWarmupRound();
		}
		g_hCvarIgnoreRoundWinConditions = FindConVar("mp_ignore_round_win_conditions");
		if (g_hCvarIgnoreRoundWinConditions)
		{
			HookConVarChange(g_hCvarIgnoreRoundWinConditions, OnSettingsChanged);
		}
		Format(sBuffer, 128, "vip_%s", "beta_0.0.5");
		AutoExecConfig(true, sBuffer, "sourcemod");
		PrintToServer("Very Important Person %s has been loaded successfully.", "beta_0.0.5");
	}
	return 0;
}

public OnClientPutInServer(client)
{
	new var1;
	if (IsClientConnected(client) && GetClientAuthString(client, g_sClientAuth[client], 32, true) && g_bBetaTest)
	{
		g_iClientUserId[client] = GetClientUserId(client);
		new var3 = isUsersAdmin(client);
		g_bUsersAdmin[client] = var3;
		g_sUsersOnAttribute[client] = var3;
		new var2;
		if (UsersLoadFlagsAdmission(client, g_sClientAuth[client]) && UsersLoadFlags(client))
		{
			g_iImpulseOffset[client] = FindDataMapOffs(client, "m_nImpulse", 0, 0);
			if (g_bSDKHooksLoaded)
			{
				SDKHook(client, SDKHookType:2, Users_OnTakeDamage);
			}
		}
	}
	return 0;
}

public OnClientDisconnect(client)
{
	new iBuffer;
	if (!g_bBetaTest)
	{
		return 0;
	}
	if (g_bSDKHooksLoaded)
	{
		SDKUnhook(client, SDKHookType:2, Users_OnTakeDamage);
		new var2;
		if ((g_bPlayerVip[client][32] && (g_iWeaponColorsSizeT || g_iWeaponColorsSizeCT)) || (g_iGame == GameType:3 && (g_bPlayerVip[client][7] || g_bPlayerVip[client][5])))
		{
			SDKUnhook(client, SDKHookType:32, Users_WeaponEquipPost);
		}
	}
	new var6;
	if (g_bPlayerVip[client][23] && g_bPlayerAlive[client])
	{
		UsersChangeTeam(client);
	}
	if (g_hTimerHeartBeat[client])
	{
		KillTimer(g_hTimerHeartBeat[client], false);
		g_hTimerHeartBeat[client] = 0;
	}
	if (g_hTimerMedic[client][0])
	{
		KillTimer(g_hTimerMedic[client][0], false);
		g_hTimerMedic[client][0] = MissingTAG:0;
	}
	if (g_hTimerMedic[client][1])
	{
		KillTimer(g_hTimerMedic[client][1], false);
		g_hTimerMedic[client][1] = MissingTAG:0;
	}
	if (g_hTimerUsersLossSpeed[client])
	{
		KillTimer(g_hTimerUsersLossSpeed[client], false);
		g_hTimerUsersLossSpeed[client] = 0;
	}
	if (g_hTimerMedicSpam[client])
	{
		KillTimer(g_hTimerMedicSpam[client], false);
		g_hTimerMedicSpam[client] = 0;
	}
	iBuffer = 0;
	while (iBuffer <= 38)
	{
		g_iPlayerVip[client][iBuffer] = 0;
		new var7 = false;
		g_bPlayerVipEdit[client][iBuffer] = var7;
		g_bPlayerVip[client][iBuffer] = var7;
		iBuffer++;
	}
	iBuffer = 0;
	while (iBuffer <= 5)
	{
		new var8 = false;
		g_bPlayerCmdsEdit[client][iBuffer] = var8;
		g_bPlayerCmds[client][iBuffer] = var8;
		iBuffer++;
	}
	strcopy(g_sClientAuth[client], 32, NULL_STRING);
	strcopy(g_sUsersClanTag[client], 32, NULL_STRING);
	strcopy(g_sUsersOldClanTag[client], 32, NULL_STRING);
	strcopy(g_sVipFlags[client][0], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][1], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][2], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][3], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][4], 256, NULL_STRING);
	strcopy(g_sVipFlags[client][5], 256, NULL_STRING);
	strcopy(g_sUsersChatTag[client], 32, NULL_STRING);
	strcopy(g_sUsersModelsT[client], 256, NULL_STRING);
	strcopy(g_sUsersModelsCT[client], 256, NULL_STRING);
	strcopy(g_sUsersModelsArmsT[client], 256, NULL_STRING);
	strcopy(g_sUsersModelsArmsCT[client], 256, NULL_STRING);
	strcopy(g_sModelsForce[client], 256, NULL_STRING);
	strcopy(g_sModelsForceArm[client], 256, NULL_STRING);
	strcopy(g_sUsersWeaponColorsNamesT[client], 256, NULL_STRING);
	strcopy(g_sUsersWeaponColorsNamesCT[client], 256, NULL_STRING);
	g_bUsersWeaponColorsT[client] = 0;
	g_iUsersWeaponColorsT[client][0] = 0;
	g_iUsersWeaponColorsT[client][1] = 0;
	g_iUsersWeaponColorsT[client][2] = 0;
	g_iUsersWeaponColorsT[client][3] = 0;
	g_bUsersWeaponColorsCT[client] = 0;
	g_iUsersWeaponColorsCT[client][0] = 0;
	g_iUsersWeaponColorsCT[client][1] = 0;
	g_iUsersWeaponColorsCT[client][2] = 0;
	g_iUsersWeaponColorsCT[client][3] = 0;
	strcopy(g_sUsersGrenadeModelsNamesT[client], 256, NULL_STRING);
	strcopy(g_sUsersGrenadeModelsNamesCT[client], 256, NULL_STRING);
	g_bUsersGrenadeModelsT[client] = 0;
	g_bUsersGrenadeModelsCT[client] = 0;
	strcopy(g_sUsersGrenadeModelsT[client], 256, NULL_STRING);
	strcopy(g_sUsersGrenadeModelsCT[client], 256, NULL_STRING);
	g_bUsersWeaponGrenades[client] = 0;
	g_iUsersWeaponHeGrenade[client] = 0;
	g_iUsersWeaponFlashBang[client] = 0;
	g_iUsersWeaponSmokeGrenade[client] = 0;
	g_bUsersWeaponPrimaryPlayerDies[client] = 0;
	g_bUsersWeaponSecondaryPlayerDies[client] = 0;
	g_bUsersGiveWeaponsItemPickUp[client] = 0;
	g_iUsersWeaponTeam[client] = 0;
	g_bUsersWeaponPrimaryT[client] = 0;
	g_bUsersWeaponPrimaryCT[client] = 0;
	strcopy(g_sUsersWeaponPrimaryT[client], 32, NULL_STRING);
	strcopy(g_sUsersWeaponPrimaryCT[client], 32, NULL_STRING);
	g_bUsersWeaponSecondaryT[client] = 0;
	g_bUsersWeaponSecondaryCT[client] = 0;
	strcopy(g_sUsersWeaponSecondaryT[client], 32, NULL_STRING);
	strcopy(g_sUsersWeaponSecondaryCT[client], 32, NULL_STRING);
	g_bUsersWeaponKnife[client] = 0;
	g_bUsersWeaponVestHelm[client] = 0;
	g_bUsersWeaponDefuser[client] = 0;
	g_bUsersWeaponNvgs[client] = 0;
	g_bUsersHeartShaking[client] = 0;
	g_bUsersModelsCT[client] = 0;
	g_bUsersModelsT[client] = 0;
	g_bHealthChoose[client] = 0;
	g_bUsersCmds[client] = 0;
	g_bUsersVip[client] = 0;
	g_bWelcome[client] = 0;
	g_bPlayerAlive[client] = 0;
	g_bSettingsChanged[client] = 0;
	g_bAdminChat[client] = 0;
	g_bUsersAdmin[client] = 0;
	g_sUsersOnAttribute[client] = 0;
	g_sUsersOnPlayerRunCmd[client] = 0;
	g_iMedic[client] = 0;
	g_iModelsForceTeam[client] = 0;
	g_iUsersModelsCT[client] = 0;
	g_iUsersModelsT[client] = 0;
	g_iClientTeam[client] = 0;
	g_iClientUserId[client] = 0;
	g_fTimerChat[client] = 0;
	g_fMedic[client] = 0;
	g_fMedicProgresBarPos[client] = 0;
	g_fMedicProgresBarMax[client] = 0;
	g_fUsersTimeSetPassword[client] = 0;
	g_fUsersKillEffect[client] = 0;
	g_fUsersLossSpeed[client] = 0;
	g_fLowAmmoSoundSpam[client] = 0;
	return 0;
}

public OnConfigsExecuted()
{
	g_iMaxClients = GetMaxClients();
	if (!g_bBetaTest)
	{
		return 0;
	}
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			g_iClientTeam[i] = GetClientTeam(i);
			g_bPlayerAlive[i] = IsPlayerAlive(i);
			OnClientPutInServer(i);
		}
		i++;
	}
	g_bFriendLyFire = GetConVarBool(g_hCvarFriendlyFire);
	g_bUsersActivate = g_iUsersActivateRounds == 0;
	if (!g_bUsersActivate)
	{
		g_iActivateRounds = 1;
	}
	return 0;
}

public Action:Timer_WelcomeMsg(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new var1;
	if (client && !g_bWelcome[client] && IsClientInGame(client))
	{
		VipPrint(client, enSound:0, "Добро пожаловать, %N!", client);
		if (g_iUsersExpires[client])
		{
			decl String:sBuffer[256];
			FormatTime(sBuffer, 256, "Ваши VIP привилегии заканчиваются: [%H:%M:%S %d:%m:%Y]", g_iUsersExpires[client]);
			VipPrint(client, enSound:0, sBuffer);
		}
		g_bWelcome[client] = 1;
	}
	if (g_iGame == GameType:3)
	{
		InsertServerCommand("ammo_grenade_limit_total 4");
		InsertServerCommand("ammo_grenade_limit_flashbang 2");
	}
	return Action:4;
}

public Native_Log(Handle:plugin, numParams)
{
	decl String:sFilename[64];
	decl String:sBuffer[256];
	GetPluginFilename(plugin, sFilename, 64);
	FormatNativeString(0, 1, 2, 256, 0, sBuffer, "");
	LogToFileEx(g_sLogPath, "[%s] %s", sFilename, sBuffer);
	return 0;
}

public Native_ErrorLog(Handle:plugin, numParams)
{
	decl String:sFilename[64];
	decl String:sBuffer[256];
	GetPluginFilename(plugin, sFilename, 64);
	FormatNativeString(0, 1, 2, 256, 0, sBuffer, "");
	LogToFileEx(g_sErrorLogPath, "[%s] %s", sFilename, sBuffer);
	return 0;
}

public Native_IsClientVip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (client < 1 || client > g_iMaxClients)
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	return g_bUsersVip[client];
}

public Native_IsClientVipCmds(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (client < 1 || client > g_iMaxClients)
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	return g_bUsersCmds[client];
}

public Native_IsClientVipImmune(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (client < 1 || client > g_iMaxClients)
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	new var2;
	return g_bPlayerVip[client][2] && g_iPlayerVip[client][2];
}

public Native_SetVipUsersFlags(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (client < 1 || client > g_iMaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	else
	{
		new var3;
		GetNativeString(2, var3 + var3, 128, 0);
		new var4 = var3 + 4;
		GetNativeString(4, var4 + var4, 128, 0);
		if (UsersSetFlags(client, var3 + var3))
		{
			new iBuffer = GetNativeCell(3);
			PushArrayString(g_hArrayUsers, g_sClientAuth[client]);
			if (0 > iBuffer)
			{
				iBuffer = 0;
			}
			else
			{
				if (iBuffer)
				{
					iBuffer = iBuffer * 60 + GetTime(462800);
				}
			}
			PushArrayCell(g_hArrayUsersExpires, iBuffer);
			new var5 = var3 + 4;
			PushArrayString(g_hArrayUsersPassword, var5 + var5);
			g_iArrayUsers += 1;
			g_iUsersExpires[client] = iBuffer;
			if (GetNativeCell(5))
			{
				decl String:sName[32];
				KvRewind(g_hKvUsers);
				if (KvJumpToKey(g_hKvUsers, g_sClientAuth[client], true))
				{
					if (!GetClientName(client, sName, 32))
					{
						strcopy(sName, 32, "Unknown");
					}
					KvSetString(g_hKvUsers, "name", sName);
					KvSetNum(g_hKvUsers, "expires", iBuffer);
					KvSetString(g_hKvUsers, "flags", var3 + var3);
					new var6 = var3 + 4;
					KvSetString(g_hKvUsers, "password", var6 + var6);
					KvRewind(g_hKvUsers);
					new var7 = g_sUsersPath;
					KeyValuesToFile(g_hKvUsers, var7[0][var7]);
				}
			}
			CreateTimer(7.01, Timer_WelcomeMsg, g_iClientUserId[client], 2);
			if (IsClientInGame(client))
			{
				g_iClientTeam[client] = GetClientTeam(client);
				g_bPlayerAlive[client] = IsPlayerAlive(client);
				new var2;
				if (g_iClientTeam[client] > 1 && g_bPlayerAlive[client])
				{
					PlayerSpawn_Init(client);
				}
				g_sUsersOnAttribute[client] = 1;
				g_sUsersOnPlayerRunCmd[client] = GetOnPlayerRunCmd(client);
			}
			return 1;
		}
	}
	return 0;
}

public Native_isVipUsersGroups(Handle:plugin, numParams)
{
	decl String:sBuffer[256];
	decl iBuffer;
	GetNativeString(1, sBuffer, 256, 0);
	return GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer);
}

public Native_SetVipUsersGroups(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new var1;
	if (client < 1 || client > g_iMaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	else
	{
		new var3;
		new var4;
		GetNativeString(2, var3, 128, 0);
		new var5 = var4 + 4;
		GetNativeString(4, var5 + var5, 128, 0);
		KvRewind(g_hKvUsersGroups);
		if (KvJumpToKey(g_hKvUsersGroups, var3, false))
		{
			KvGetString(g_hKvUsersGroups, "flags", var4 + var4, 128, "0a");
			if (UsersSetFlags(client, var4 + var4))
			{
				new iBuffer = GetNativeCell(3);
				PushArrayString(g_hArrayUsers, g_sClientAuth[client]);
				if (0 > iBuffer)
				{
					iBuffer = 0;
				}
				else
				{
					if (iBuffer)
					{
						iBuffer = iBuffer * 60 + GetTime(462900);
					}
				}
				if (GetNativeCell(5))
				{
					KvRewind(g_hKvUsers);
					if (KvJumpToKey(g_hKvUsers, g_sClientAuth[client], true))
					{
						if (!GetClientName(client, var4 + var4, 128))
						{
							strcopy(var4 + var4, 128, "Unknown");
						}
						KvSetString(g_hKvUsers, "name", var4 + var4);
						KvSetNum(g_hKvUsers, "expires", iBuffer);
						new var6 = var4 + 4;
						KvSetString(g_hKvUsers, "password", var6 + var6);
						KvSetString(g_hKvUsers, "group", var3);
						KvRewind(g_hKvUsers);
						new var7 = g_sUsersPath;
						KeyValuesToFile(g_hKvUsers, var7[0][var7]);
					}
				}
				PushArrayCell(g_hArrayUsersExpires, iBuffer);
				new var8 = var4 + 4;
				PushArrayString(g_hArrayUsersPassword, var8 + var8);
				g_iArrayUsers += 1;
				g_iUsersExpires[client] = iBuffer;
				CreateTimer(7.01, Timer_WelcomeMsg, g_iClientUserId[client], 2);
				if (IsClientInGame(client))
				{
					g_iClientTeam[client] = GetClientTeam(client);
					g_bPlayerAlive[client] = IsPlayerAlive(client);
					new var2;
					if (g_iClientTeam[client] > 1 && g_bPlayerAlive[client])
					{
						PlayerSpawn_Init(client);
					}
					g_sUsersOnAttribute[client] = 1;
					g_sUsersOnPlayerRunCmd[client] = GetOnPlayerRunCmd(client);
				}
				return 1;
			}
		}
		else
		{
			ThrowNativeError(25, "Группа %s не найдена", var4);
		}
	}
	return 0;
}

public Native_VipUsersDelete(Handle:plugin, numParams)
{
	decl String:sBuffer[32];
	GetNativeString(1, sBuffer, 32, 0);
	if (strlen(sBuffer))
	{
		new iBuffer = FindStringInArray(g_hArrayUsers, sBuffer);
		if (iBuffer != -1)
		{
			KvRewind(g_hKvUsers);
			if (KvJumpToKey(g_hKvUsers, sBuffer, false))
			{
				decl String:sName[64];
				KvGetString(g_hKvUsers, "name", sName, 64, "unnamed");
				KvDeleteThis(g_hKvUsers);
				KvRewind(g_hKvUsers);
				new var1 = g_sUsersPath;
				if (KeyValuesToFile(g_hKvUsers, var1[0][var1]))
				{
					RemoveFromArray(g_hArrayUsers, iBuffer);
					RemoveFromArray(g_hArrayUsersExpires, iBuffer);
					RemoveFromArray(g_hArrayUsersPassword, iBuffer);
					Vip_Log("Атрибуты VIP удалены у %s (ID: %s).", sName, sBuffer);
					return 1;
				}
			}
		}
		else
		{
			Vip_Log("Не удалось удалить VIP (ID: %s), возможно, что VIP игрока нет в базе.", sBuffer);
		}
	}
	else
	{
		ThrowNativeError(25, "Неверный формат строки steamid = '%s'", sBuffer);
	}
	return 0;
}

public Native_VipUsersGetExpires(Handle:plugin, numParams)
{
	decl String:sBuffer[256];
	GetNativeString(1, sBuffer, 256, 0);
	if (strlen(sBuffer))
	{
		new iBuffer = FindStringInArray(g_hArrayUsers, sBuffer);
		if (iBuffer != -1)
		{
			return GetArrayCell(g_hArrayUsersExpires, iBuffer, 0, false);
		}
	}
	return -1;
}

public Native_VipPrint(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new enSound:iSound = GetNativeCell(2);
	decl String:sBuffer[256];
	new var1;
	if (!client || !IsClientConnected(client))
	{
		ThrowNativeError(7, "Client index %i is invalid", client);
	}
	FormatNativeString(0, 3, 4, 256, 0, sBuffer, "");
	if (g_iGame == GameType:3)
	{
		PrintToChat(client, " \x01\x04[VIP]\x01 %s", sBuffer);
	}
	else
	{
		PrintToChat(client, "\x01\x04[VIP]\x01 %s", sBuffer);
	}
	if (iSound == enSound:1)
	{
		EmitSoundToClient(client, "buttons/weapon_confirm.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else
	{
		if (iSound == enSound:2)
		{
			EmitSoundToClient(client, "buttons/button11.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	return 0;
}

public Native_VipUsersChatSettings(Handle:plugin, numParams)
{
	new iBuffer = GetNativeCell(1);
	new var1;
	if (iBuffer >= 0 && iBuffer < 2)
	{
		g_iVipUsersChatSettings = iBuffer;
	}
	else
	{
		ThrowNativeError(7, "Неверный индекс %i настройки чата", iBuffer);
	}
	return 0;
}

public Native_GetVipUsersChatSettings(Handle:plugin, numParams)
{
	return g_iVipUsersChatSettings;
}

public Native_GetVipUsersAttribute(Handle:plugin, numParams)
{
	decl String:sBuffer[256];
	new iBuffer;
	GetNativeString(1, sBuffer, 256, 0);
	if (strlen(sBuffer))
	{
		KvRewind(g_hKvUsers);
		if (KvJumpToKey(g_hKvUsers, sBuffer, false))
		{
			KvGetString(g_hKvUsers, "group", sBuffer, 256, "");
			if (!GetTrieValue(g_hUsersGroupsTrie, sBuffer, iBuffer))
			{
				KvGetString(g_hKvUsers, "flags", sBuffer, 256, "0a");
			}
			KvRewind(g_hKvUsers);
			iBuffer = GetNativeCell(3);
			new var1;
			if (strlen(sBuffer) && iBuffer > 0)
			{
				SetNativeString(2, sBuffer, iBuffer, true, 0);
				return 1;
			}
		}
	}
	else
	{
		ThrowNativeError(25, "Длина строки SteamID равна 0");
	}
	return 0;
}

public MoveType:GetClientMoveType(client)
{
	return GetEntData(client, g_iMoveTypeOffset[client], 4);
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

public bool:GetPlayerNightVision(client)
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

public AntiFlash_VectorDistance(client, Float:point[3], Float:origin[3])
{
	if (GetVectorDistance(point, origin, false) <= 1153138688)
	{
		SetEntDataFloat(client, g_iFlashOffset[0], 0.5, true);
		SetEntDataFloat(client, g_iFlashOffset[1], 0.0, true);
		if (g_iGame != GameType:3)
		{
			ClientCommand(client, "dsp_player 0.0");
		}
	}
	return 0;
}

public SetPlayerDefuser(client)
{
	SetEntData(client, g_iDefuserOffset, any:1, 1, true);
	return 0;
}

public RemovePlayerDefuser(client)
{
	SetEntData(client, g_iDefuserOffset, any:1, 0, true);
	return 0;
}

public bool:GetPlayerDefuser(client)
{
	return GetEntData(client, g_iDefuserOffset, 1);
}

public SetPlayerGrenade(client, cell, count)
{
	if (g_iGame == GameType:3)
	{
		SetEntData(client, cell + 3 * 4 + g_iAmmoOffset, count, 4, true);
	}
	else
	{
		SetEntData(client, cell * 4 + g_iAmmoOffset, count, 4, true);
	}
	return 0;
}

public GetPlayerGrenade(client, cell)
{
	if (g_iGame == GameType:3)
	{
		return GetEntData(client, cell + 3 * 4 + g_iAmmoOffset, 4);
	}
	return GetEntData(client, cell * 4 + g_iAmmoOffset, 4);
}

public SetPlayerGravity(client, Float:amount)
{
	SetEntDataFloat(client, g_iGravityOffset[client], amount, true);
	return 0;
}

public Float:GetPlayerGravity(client)
{
	return GetEntDataFloat(client, g_iGravityOffset[client]);
}

public SetPlayerFrags(client, frags)
{
	SetEntData(client, g_iFragsOffset[client], frags, 4, true);
	return 0;
}

public GetPlayerFrags(client)
{
	return GetEntData(client, g_iFragsOffset[client], 4);
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
	if (iBuffer != -1)
	{
		SetEntData(iBuffer, g_iSilencerOffset[slot], any:1, 1, false);
		if (g_iGame != GameType:2)
		{
			SetEntData(iBuffer, g_iSilencerOffset[slot + 2], any:1, 1, false);
		}
	}
	return 0;
}

public bool:GetWeaponSilencer(client, slot)
{
	new iBuffer = GetPlayerWeaponSlot(client, slot);
	if (iBuffer != -1)
	{
		return GetEntData(iBuffer, g_iSilencerOffset[slot], 1);
	}
	return false;
}

public bool:UsersChangeTeam(client)
{
	if (FindStringInArray(g_hChangeTeamArray, g_sClientAuth[client]) == -1)
	{
		PushArrayString(g_hChangeTeamArray, g_sClientAuth[client]);
		g_bChangeTeam = true;
		return true;
	}
	return false;
}

public SetUsersObImpulse(client, impulse)
{
	new iBuffer = GetEntData(client, g_iObserverModeOffset, 4);
	if (g_iGame != GameType:2)
	{
		iBuffer += 1;
	}
	new var1;
	if (iBuffer == 3 || iBuffer == 4)
	{
		iBuffer = GetEntDataEnt2(client, g_iObserverTargetOffset);
		new var2;
		if (iBuffer > 0 && !g_bUsersAdmin[iBuffer] && g_bPlayerAlive[iBuffer] && IsClientInGame(iBuffer))
		{
			SetEntData(iBuffer, g_iImpulseOffset[iBuffer], impulse, 4, true);
		}
	}
	return 0;
}

public UsersFadeMedic(client, color[4], duration)
{
	new Handle:hBuffer = StartMessageOne("Fade", client, 132);
	if (g_bProtobufMessage)
	{
		PbSetInt(hBuffer, "duration", duration, -1);
		PbSetInt(hBuffer, "hold_time", 0, -1);
		PbSetInt(hBuffer, "flags", 1, -1);
		PbSetColor(hBuffer, "clr", color, -1);
	}
	else
	{
		BfWriteShort(hBuffer, duration);
		BfWriteShort(hBuffer, 0);
		BfWriteShort(hBuffer, 1);
		BfWriteByte(hBuffer, color[0]);
		BfWriteByte(hBuffer, color[1]);
		BfWriteByte(hBuffer, color[2]);
		BfWriteByte(hBuffer, color[3]);
	}
	EndMessage();
	return 0;
}

public bool:UsersDropWeapon(client)
{
	new var1;
	if (!g_bUsersAdmin[client] && g_bPlayerAlive[client] && IsClientInGame(client))
	{
		new iEntity = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		new var2;
		if (iEntity != -1 && IsValidEntity(iEntity) && GetEntDataEnt2(iEntity, g_iOwnerEntityOffset) == client)
		{
			CS_DropWeapon(client, iEntity, true, false);
			return true;
		}
	}
	return false;
}

public bool:UsersLoadFlagsAdmission(client, String:authid[])
{
	new bool:result = 1;
	Call_StartForward(g_hOnUsersLoadFlags);
	Call_PushCell(client);
	Call_PushString(authid);
	Call_Finish(result);
	return result;
}

public UsersLoadFlags_Post(client, String:authid[], bool:usersvip, bool:userscmds, bool:usersadmin)
{
	Call_StartForward(g_hOnUsersLoadFlags_Post);
	Call_PushCell(client);
	Call_PushString(authid);
	Call_PushCell(usersvip);
	Call_PushCell(userscmds);
	Call_PushCell(usersadmin);
	Call_Finish(0);
	return 0;
}

public Action:KAC_OnCheatDetected(client, execution, bantime)
{
	new var1;
	if (g_bPlayerVip[client][11] && g_iPlayerVip[client][11])
	{
		return Action:3;
	}
	return Action:0;
}

public Action:SMAC_OnCheatDetected(client, String:module[])
{
	new var1;
	if (strcmp(module, "smac_autotrigger.smx", false) && g_bPlayerVip[client][11] && g_iPlayerVip[client][11])
	{
		return Action:3;
	}
	return Action:0;
}

public OnPluginEnd()
{
	if (!g_bBetaTest)
	{
		return 0;
	}
	new i = 1;
	while (i <= g_iMaxClients)
	{
		new var1;
		if (g_bUsersVip[i] && IsClientInGame(i))
		{
			new var2;
			if (g_iGame != GameType:2 && g_bPlayerVip[i][24] && g_iPlayerVip[i][24])
			{
				CS_SetClientClanTag(i, g_sUsersOldClanTag[i]);
			}
			new var3;
			if (g_bPlayerVip[i][1] && g_iPlayerVip[i][1] && GetClientTeam(i) > 1 && IsPlayerAlive(i))
			{
				CS_UpdateClientModel(i);
			}
		}
		i++;
	}
	return 0;
}

