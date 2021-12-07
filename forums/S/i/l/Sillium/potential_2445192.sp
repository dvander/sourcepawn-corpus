public PlVers:__version =
{
	version = 5,
	filevers = "1.7.3-dev+5301",
	date = "07/03/2016",
	time = "19:42:32"
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
public Extension:__ext_SteamWorks =
{
	name = "SteamWorks",
	file = "SteamWorks.ext",
	autoload = 1,
	required = 1,
};
public Plugin:myinfo =
{
	name = "Token Auto Updater",
	description = "",
	author = "Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.0.1",
	url = "http://zizt.ru/"
};
new String:log_file[48] = "addons/sourcemod/logs/token_auto_updater.log";
new String:tau_file[48] = "addons/sourcemod/configs/token_auto_updater.ini";
new String:token_buf_file[28] = "addons/sourcemod/data/tau";
new String:token[36];
new String:url_up[256];
new Handle:Timer_inf;
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
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

public void:OnPluginStart()
{
	if (!FileExists(tau_file, false, "GAME"))
	{
		LogToFile(log_file, "Файл token_auto_updater.ini не найден");
		SetFailState("[Token Auto Updater] Файл token_auto_updater.ini не найден");
	}
	new File:bdc = OpenFile(tau_file, "r", false, "GAME");
	File.ReadLine(bdc, url_up, 256);
	CloseHandle(bdc);
	bdc = MissingTAG:0;
	if (strlen(url_up) != 30)
	{
		LogToFile(log_file, "Неверный формат ключа доступа");
		SetFailState("[Token Auto Updater] Неверный формат ключа доступа");
	}
	if (FileExists(token_buf_file, false, "GAME"))
	{
		new File:token_buf = OpenFile(token_buf_file, "r", false, "GAME");
		File.ReadLine(token_buf, token, 33);
		CloseHandle(token_buf);
		token_buf = MissingTAG:0;
		DeleteFile(token_buf_file, false, "DEFAULT_WRITE_PATH");
		ServerCommand("sv_setsteamaccount %s", token);
	}
	else
	{
		LogToFile(log_file, "Получение токена");
	}
	return void:0;
}

public void:OnMapStart()
{
	if (Timer_inf)
	{
		KillTimer(Timer_inf, false);
		SteamWorks_SteamServersConnected();
	}
	Timer_inf = CreateTimer(600.0, UPD, any:0, 1);
	return void:0;
}

public SteamWorks_SteamServersConnected()
{
	static bool:frt;
	if (!frt)
	{
		new ipaddr[4];
		SteamWorks_GetPublicIP(ipaddr);
		new var1;
		if (ipaddr[0] && ipaddr[1] && ipaddr[2] && ipaddr[3])
		{
			return 0;
		}
		Format(url_up, 256, "http://token.zizt.ru/response.php?key=%s&ip=%d.%d.%d.%d:%d", url_up, ipaddr, ipaddr[1], ipaddr[2], ipaddr[3], ConVar.IntValue.get(FindConVar("hostport")));
		frt = true;
	}
	new Handle:zapros = SteamWorks_CreateHTTPRequest(EHTTPMethod:1, url_up);
	SteamWorks_SetHTTPCallbacks(zapros, SteamWorksHTTPRequestCompleted:3, SteamWorksHTTPHeadersReceived:-1, SteamWorksHTTPDataReceived:-1, Handle:0);
	SteamWorks_SendHTTPRequest(zapros);
	return 0;
}

public HTTPComplete(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode)
{
	if (bRequestSuccessful)
	{
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, SteamWorksHTTPBodyCallback:1, any:0, Handle:0);
	}
	CloseHandle(hRequest);
	hRequest = MissingTAG:0;
	return 0;
}

public GetResult(String:sData[])
{
	static bool:plt;
	if (plt)
	{
		return 0;
	}
	if (strlen(sData) != 32)
	{
		new ibuf = StringToInt(sData, 10);
		if (ibuf == -2)
		{
			LogToFile(log_file, "Неверный ключ доступа");
			SetFailState("[Token Auto Updater] Неверный ключ доступа");
		}
		else
		{
			if (ibuf == -1)
			{
				LogToFile(log_file, "У данного ключа пустой баланс для получения токена");
				SetFailState("[Token Auto Updater] У данного ключа пустой баланс для получения токена");
			}
		}
	}
	else
	{
		new File:token_buf = OpenFile(token_buf_file, "w", false, "GAME");
		File.WriteLine(token_buf, sData);
		CloseHandle(token_buf);
		token_buf = MissingTAG:0;
		if (token[0])
		{
			LogToFile(log_file, "Проверка токена");
			if (!StrEqual(token, sData, true))
			{
				KillTimer(Timer_inf, false);
				Timer_inf = MissingTAG:0;
				LogToFile(log_file, "Обнаружен бан токенов");
				CreateTimer(5.0, UPDR, any:1, 0);
			}
			else
			{
				strcopy(token, 33, sData);
			}
		}
		plt = true;
		LogToFile(log_file, "Токен получен");
		CreateTimer(5.0, UPDR, any:0, 0);
		return 0;
	}
	return 0;
}

public Action:UPD(Handle:timer)
{
	SteamWorks_SteamServersConnected();
	return Action:0;
}

public Action:UPDR(Handle:timer, bool:trd)
{
	if (trd)
	{
		new u = 1;
		while (u <= MaxClients)
		{
			if (IsClientInGame(u))
			{
				KickClient(u, "Рестарт сервера, перезайдите через минуту");
			}
			u++;
		}
		LogToFile(log_file, "Рестарт сервера для обновления токена");
	}
	ServerCommand("quit");
	return Action:0;
}

