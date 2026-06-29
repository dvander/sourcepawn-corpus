public PlVers:__version =
{
	version = 5,
	filevers = "1.8.0.5998",
	date = "08/30/2017",
	time = "22:30:40"
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
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "sdkhooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_cstrike =
{
	name = "cstrike",
	file = "games/game.cstrike.ext",
	autoload = 0,
	required = 1,
};
public Extension:__ext_cprefs =
{
	name = "Client Preferences",
	file = "clientprefs.ext",
	autoload = 1,
	required = 1,
};
new ArrayList:KnivesArray;
new String:path_knives[256];
new knives[50][65];
new knifeCount;
public Plugin:myinfo =
{
	name = "[CS:GO] Select Knife MENU PUBLIC.",
	description = "Knifes menu select on csgo",
	author = "Spy",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
};
new knife[66];
new Handle:c_knife;
public void:__ext_core_SetNTVOptional()
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
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
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
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return void:0;
}

public void:OnPluginStart()
{
	c_knife = RegClientCookie("hknife", "", CookieAccess:2);
	RegConsoleCmd("sm_knife", DID, "", 0);
	RegConsoleCmd("sm_faca", DID, "", 0);
	RegConsoleCmd("sm_facas", DID, "", 0);
	RegConsoleCmd("sm_knifes", DID, "", 0);
	RegConsoleCmd("sm_knive", DID, "", 0);
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
		i++;
	}
	KnivesArray = ArrayList.ArrayList(64, 0);
	loadKnives();
	return void:0;
}

public void:OnClientPutInServer(client)
{
	SDKHook(client, SDKHookType:16, OnPostWeaponEquip);
	return void:0;
}

public Action:OnPostWeaponEquip(client, iWeapon)
{
	new String:Classname[64];
	new var1;
	if (!GetEdictClassname(iWeapon, Classname, 64) || StrContains(Classname, "weapon_knife", false))
	{
		return Action:0;
	}
	if (0 < knife[client])
	{
		SetEntProp(iWeapon, PropType:0, "m_iItemDefinitionIndex", knife[client], 4, 0);
	}
	return Action:0;
}

public Action:DID(clientId, args)
{
	loadKnifeMenu(clientId, -1);
	return Action:3;
}

public void:loadKnifeMenu(clientId, menuPosition)
{
	new Menu:menu = CreateMenu(DIDMenuHandler_h, MenuAction:28);
	Menu.SetTitle(menu, "Knife Menu - PUBLIC VERSION");
	new String:item[4];
	new i = 1;
	while (i < knifeCount)
	{
		Format(item, 4, "%i", knives[i][64]);
		new var1;
		if (knives[i][64] == knife[clientId])
		{
			var1 = 1;
		}
		else
		{
			var1 = 0;
		}
		Menu.AddItem(menu, item, knives[i], var1);
		i++;
	}
	SetMenuExitButton(menu, true);
	if (menuPosition == -1)
	{
		Menu.Display(menu, clientId, 0);
	}
	else
	{
		Menu.DisplayAt(menu, clientId, menuPosition, 0);
	}
	return void:0;
}

public DIDMenuHandler_h(Menu:menu, MenuAction:action, client, itemNum)
{
	switch (action)
	{
		case 4:
		{
			new String:info[32];
			Menu.GetItem(menu, itemNum, info, 32, 0, "", 0);
			knife[client] = StringToInt(info, 10);
			new String:cookie[8];
			IntToString(knife[client], cookie, 8);
			SetClientCookie(client, c_knife, cookie);
			DarKnife(client);
			loadKnifeMenu(client, GetMenuSelectionPosition());
		}
		case 16:
		{
			CloseHandle(menu);
			menu = MissingTAG:0;
		}
		default:
		{
		}
	}
	return 0;
}

public void:OnClientCookiesCached(client)
{
	new String:value[16];
	GetClientCookie(client, c_knife, value, 16);
	if (0 < strlen(value))
	{
		knife[client] = StringToInt(value, 10);
	}
	else
	{
		knife[client] = 0;
	}
	return void:0;
}

public void:DarKnife(client)
{
	if (!IsPlayerAlive(client))
	{
		return void:0;
	}
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	if (iWeapon != -1)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill", -1, -1, 0);
		GivePlayerItem(client, "weapon_knife", 0);
	}
	return void:0;
}

public void:loadKnives()
{
	BuildPath(PathType:0, path_knives, 256, "configs/knives/facas.cfg");
	new KeyValues:kv = KeyValues.KeyValues("FACAS", "", "");
	knifeCount = 1;
	ClearArray(KnivesArray);
	KeyValues.ImportFromFile(kv, path_knives);
	if (!KeyValues.GotoFirstSubKey(kv, true))
	{
		SetFailState("As facas não foram encontradas. Re-instale o plugin.", path_knives);
		CloseHandle(kv);
		kv = MissingTAG:0;
	}
	do {
		KeyValues.GetSectionName(kv, knives[knifeCount], 64);
		knives[knifeCount][64] = KeyValues.GetNum(kv, "KnifeID", 0);
		PushArrayString(KnivesArray, knives[knifeCount]);
		knifeCount += 1;
	} while (KeyValues.GotoNextKey(kv, true));
	CloseHandle(kv);
	kv = MissingTAG:0;
	new i = knifeCount;
	while (i < 50)
	{
		knives[i][0] = 0;
		i++;
	}
	return void:0;
}

