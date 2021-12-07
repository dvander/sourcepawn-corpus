#include sourcemod

#include <SteamWorks>
#include <UTF-8-string>
#include <cstrike>
#include <sdktools_functions>
#include <Regex>

#define INSERT_PlInfo

#define	PlugAuth "wAries"
#define	PlugUrl  "whyAries.ru"
#define	PlugName "[C] Username Filter"
#define	PlugVer  "2.0a"
#define	PlugDesc "Username filter"

#include <std>

Regex
	hRegex;

ArrayList
	aDomenList;
int
	ArrSize;

char 
	cRegex[] = "([-a-zA-Z0-9]{2,}[.][a-zA-Z]{2,5})", 
	cKick[PMP], 
	cFile[PMP],
	cWhiteDomens[PMP],
	cNewDomen[PMP];

int 
	iMode;

bool
	bTag;

float
	fTick;

enum eType
{
	eName = 0,
	eTag
};

static char aMsg[2][PMP];

public void OnPluginStart()
{

	aDomenList = new ArrayList(PLATFORM_MAX_PATH, 0);
	eGame = GetEngineVersion();

	BuildPath(Path_SM, SZF(cFile), "configs/nnp/censure.txt")

	char error[PMP];
	hRegex = new Regex(cRegex, _, SZF(error));
	if(!hRegex || error[0])
		SetFailState("Invalid regex expression: %s", error);
}

public void OnMapStart()
{
	ReadConfig();
	ReadDomens();

	CreateTimer(fTick, OnPeriodTick, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action OnPeriodTick 
(Handle hTimer, any data)
{
	//////LogMessage("Timer tick");
	if(!hTimer)
		return Plugin_Handled;

	//////LogMessage("Valid timer");

	char szName[PMP];

	FORITER(i, 1, MaxClients)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if(bTag)
		{
			CS_GetClientClanTag(i, SZF(szName));
			TrimString(szName);
			//////LogMessage("Tag:%s", szName);
			
			if(szName[0])
				SharingLocal(i, eTag, SZF(szName));
		}
		
		if(iMode && !IsClientInGame(i))
			continue;

		GetClientName(i, SZF(szName));
		TrimString(szName);
		//LogMessage("Name:%s", szName);

		if(!szName[0])
			SetClientInfo(i, "name", "unnamed");
		else if(!UTF8StrEqual(szName, "unnamed"))
			SharingLocal(i, eName, SZF(szName));
	}

	return Plugin_Continue;
}

void SharingLocal(int client, eType eNow, char[] szBuffer, int iLen)
{
	char szUrl[MAX_NAME_LENGTH], cBuffer[MAX_NAME_LENGTH];
	int iCount;

	//LogMessage("Local");
	strcopy(SZF(cBuffer), szBuffer);

	FORITER(i, 0, ArrSize)
	{
		aDomenList.GetString(i, SZF(szUrl));
		//LogMessage("Buffer %s contain %s?", cBuffer, szUrl);

		if(UTF8StrContains(cBuffer, szUrl) == -1)
			continue;
		
		////LogMessage("Yes");
		iCount++;
		ReplaceString(SZF(cBuffer), szUrl, "", false);
	}

	TrimString(cBuffer);
	if(!cBuffer[0] && eNow != eTag)
		cBuffer = "unnamed";

	//LogMessage("Now buffer: %s", cBuffer);
	strcopy(szBuffer, iLen, cBuffer);

	//LogMessage("Copyed");
	SharingWeb(client, iCount, eNow, szBuffer, iLen);
}

void SharingWeb(int client, int iCount, eType eNow, char[] szBuffer, int iLen)
{
	//////LogMessage("SharingWeb: %s", szBuffer);

	int iMatchCount = hRegex.MatchAll(szBuffer);
	//////LogMessage("iMatchCount: %i", iMatchCount);
	if(iMatchCount < 1)
	{
		if(iCount)
			RestrictPlayer(client, eNow, szBuffer, iLen);
			
		return;
	}
	
	char cBuffer[MAX_NAME_LENGTH], cUrl[MAX_NAME_LENGTH];

	Handle nHttp;
	FORITER(i, 0, iMatchCount)
	{
		if(!hRegex.GetSubString(0, SZF(cBuffer), i) || UTF8StrContains(cWhiteDomens, cBuffer, false) != -1)
			continue;
		
		FormatEx(SZF(cUrl), "https://%s/", cBuffer);

		//////LogMessage("Send for: %s", cUrl);

		nHttp = SteamWorks_CreateHTTPRequest(k_EHTTPMethodHEAD, cUrl);
		SteamWorks_SetHTTPRequestHeaderValue(nHttp, "User-Agent", "Test");

		DataPack dp = new DataPack();
		dp.WriteString(cBuffer);
		dp.WriteString(szBuffer);
		dp.WriteCell(GetClientUserId(client));
		dp.WriteCell(eNow);

		SteamWorks_SetHTTPRequestContextValue(nHttp, dp);

		SteamWorks_SetHTTPCallbacks(nHttp, OnRequestCB);
		SteamWorks_SendHTTPRequest(nHttp);
	}
}

public void OnRequestCB(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data1)
{
	DataPack hDp = data1;

	if(!bFailure && bRequestSuccessful && eStatusCode && eStatusCode < k_EHTTPStatusCode500InternalServerError)
	{
		char cURL[PMP], cName[PMP];

		hDp.Reset();
		hDp.ReadString(SZF(cURL));
		hDp.ReadString(SZF(cName));
		ReplaceString(SZF(cName), cURL, "", false);

		int iClient = GetClientOfUserId(hDp.ReadCell());
		if(iClient)
			RestrictPlayer(iClient, view_as<eType>(hDp.ReadCell()), SZF(cName));
			
		
		WriteDomen(iClient, cURL);
	}

	hDp.Close();
}

void RestrictPlayer(int iClient, eType eNow, char[] szNewName, int iLen)
{
	if(iMode)
	{
		KickClient(iClient, cKick);
		return;
	}
	
	switch(eNow)
	{
		case eTag: CS_SetClientClanTag(iClient, szNewName);
		case eName:	SetClientInfo(iClient, "name", szNewName);
	}

	SendColorMsg(iClient, aMsg[eNow]);
}

void WriteDomen(int iClient, const char[] cURL)
{
	////LogMessage("Write : %s?", cURL);
	if(IsUrlArray(cURL))
		return;

	////LogMessage("Yes");
	if(iClient)
		SendColorMsg(iClient, cNewDomen, cURL);

	static File hFile;

	hFile = OpenFile(cFile, "a");
	if(!hFile)
		SetFailState("Invalid file path: %s", cFile);
	
	hFile.WriteLine(cURL);
	delete hFile;

	aDomenList.PushString(cURL);
	ArrSize = aDomenList.Length;
}

void ReadDomens()
{
	aDomenList.Clear();

	static File hFile;

	hFile = OpenFile(cFile, "r");
	if(!hFile)
		SetFailState("Invalid file path: %s", cFile);
	
	char szLine[PMP];
	while (!hFile.EndOfFile() && hFile.ReadLine(SZF(szLine)))
	{
		TrimString(szLine);
		////LogMessage(szLine);
		aDomenList.PushString(szLine);
	}

	delete hFile;

	ArrSize = aDomenList.Length;
}

void ReadConfig()
{
	static char szFolder[PMP];

	if(!szFolder[0])
		BuildPath(Path_SM, SZF(szFolder), "configs/nnp/settings.ini");

	KeyValues hKV = new KeyValues("UsernameFilter");
	
	if(!hKV.ImportFromFile(szFolder))
		SetFailState("Failed import from: %s", szFolder);

	hKV.GetString("nnp_kickmsg", SZF(cKick));
	hKV.GetString("nnp_renamemsg", aMsg[eName], PMP);
	hKV.GetString("nnp_retagmsg", aMsg[eTag], PMP);
	hKV.GetString("nnp_whitedomen", SZF(cWhiteDomens));
	hKV.GetString("nnp_thxmsgfornewdomen", SZF(cNewDomen));
	fTick = hKV.GetFloat("nnp_period", 60.0);
	iMode = hKV.GetNum("nnp_mode", 0);
	bTag = view_as<bool>(hKV.GetNum("nnp_checktag", 0));

	hKV.Close();

	if(iMode > 1 || iMode < 0)
		SetFailState("Undefined mode: nnp_mode");	
}

bool IsUrlArray(const char[] cURL)
{
	////LogMessage("IsUrlArray: %s", cURL);
	char szBuffer[PMP];
	FORITER(i, 0, ArrSize)
	{
		aDomenList.GetString(i, SZF(szBuffer));
		////LogMessage("%s = %s ?", szBuffer, cURL);
		if(UTF8StrEqual(szBuffer, cURL, false))
			return true;
		
		////LogMessage("false");
	}

	return false;
}
