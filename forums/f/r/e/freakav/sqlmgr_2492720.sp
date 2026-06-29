#include <sourcemod>

native ArrayList Creat3Array(int blocksize=1, int startsize=0);

native Database S3L_Connect(char[] szTuple, bool bPersistent, char[] szError, int iMaxSize);

native void S3L_TConnect(SQLTCallback pCB, char[] szName = "default", any _Data = 0);
native void S3L_TQuery(Handle pDb, SQLTCallback pCB, char[] szQuery, any _Data = 0, DBPriority pPrio = DBPrio_Low);

Handle g_pDb = INVALID_HANDLE, g_pTDb = INVALID_HANDLE, g_pQry = INVALID_HANDLE;
char g_szBuff[PLATFORM_MAX_PATH] = "", g_szErr[PLATFORM_MAX_PATH] = "", g_szQry[PLATFORM_MAX_PATH * 16] = "";

public APLRes AskPluginLoad2(Handle pSelf, bool bLateLoaded, char[] szError, int iMaxSize)
{
	g_pQry = Creat3Array(MAX_NAME_LENGTH);
	g_pDb = S3L_Connect("main_db", true, g_szErr, sizeof(g_szErr));

	CreateNative("GetMainDbHandle", __GetMainDbHandle);

	CreateNative("SQL_Connect", __Connect);
	CreateNative("SQL_TConnect", __TConnect);
	CreateNative("SQL_TQuery", __TQuery);

	RegPluginLibrary("sqlmgr");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateTimer(0.1, Timer_ExecQry, _, TIMER_REPEAT);
}

public int __GetMainDbHandle(Handle pPlug, int iParams)
{
	return view_as<int>(g_pDb);
}

public int __Connect(Handle pPlug, int iParams)
{
	static Handle pSQL = INVALID_HANDLE;

	GetNativeString(1, g_szBuff, sizeof(g_szBuff));

	if (StrContains(g_szBuff, "Token", false) == -1 && \
			StrContains(g_szBuff, "Stash", false) == -1 && \
				StrContains(g_szBuff, "Auto", false) == -1 && \
					StrContains(g_szBuff, "Update", false) == -1)
	{
		return view_as<int>(g_pDb);
	}

	pSQL = S3L_Connect(g_szBuff, true, g_szErr, sizeof(g_szErr));

	if (StrContains(g_szBuff, "Token", false) != -1 || \
			StrContains(g_szBuff, "Stash", false) != -1)
	{
		g_pTDb = pSQL;
	}

	return view_as<int>(pSQL);
}

public int __TConnect(Handle pPlug, int iParams)
{
	static Function pFn = INVALID_FUNCTION;

	pFn = GetNativeFunction(1);

	Call_StartFunction(pPlug, pFn);
	Call_PushCell(view_as<int>(INVALID_HANDLE));
	Call_PushCell(view_as<int>(g_pDb));
	Call_PushString("");
	Call_PushCell(0);
	Call_Finish();
	
	return 0;
}

public int __TQuery(Handle pPlug, int iParams)
{
	static Handle pPack = INVALID_HANDLE;
	static Function pFn = INVALID_FUNCTION;
	static int iData = 0;

	if ((pPack = CreateDataPack()) == INVALID_HANDLE)
		return 1;

	pFn = GetNativeFunction(2);
	GetNativeString(3, g_szQry, sizeof(g_szQry));
	iData = GetNativeCell(4);

	ReplaceString(g_szQry, sizeof(g_szQry), "INSERT INTO", "INSERT IGNORE INTO", false);

	WritePackCell(pPack, pPlug);
	WritePackFunction(pPack, pFn);
	WritePackString(pPack, g_szQry);
	WritePackCell(pPack, iData);

	PushArrayCell(g_pQry, view_as<Handle>(pPack));
	return 0;
}

public Action Timer_ExecQry(Handle pTimer, any _Data)
{
	static int iData = 0;
	static Handle pPack = INVALID_HANDLE, pPlug = INVALID_HANDLE;
	static Function pFn = INVALID_FUNCTION;

	if (g_pDb != INVALID_HANDLE && GetArraySize(g_pQry) > 0)
	{
		pPack = view_as<Handle>(GetArrayCell(g_pQry, 0));

		ResetPack(pPack);

		pPlug = ReadPackCell(pPack);
		pFn = ReadPackFunction(pPack);
		ReadPackString(pPack, g_szQry, sizeof(g_szQry));
		iData = ReadPackCell(pPack);

		if (StrContains(g_szQry, "SELECT GSLT_GETSERVERTOKEN", false) == -1)
			S3L_TQuery(g_pDb, TQuery_Handler, g_szQry, pPack, DBPrio_Low);

		else
			S3L_TQuery(g_pTDb, TQuery_Handler, g_szQry, pPack, DBPrio_Low);

		RemoveFromArray(g_pQry, 0);
	}
}

public void TQuery_Handler(Handle pOwner, Handle pChild, const char[] szError, any _Data)
{
	static Function pFn = INVALID_FUNCTION;
	static int iData = 0;
	static Handle pPlug = INVALID_HANDLE;

	ResetPack(_Data);

	pPlug = ReadPackCell(_Data);
	pFn = ReadPackFunction(_Data);
	ReadPackString(_Data, g_szQry, sizeof(g_szQry));
	iData = ReadPackCell(_Data);

	CloseHandle(_Data);
	_Data = INVALID_HANDLE;

	Call_StartFunction(pPlug, pFn);
	Call_PushCell(view_as<int>(pOwner));
	Call_PushCell(view_as<int>(pChild));
	Call_PushString("");
	Call_PushCell(iData);
	Call_Finish();

	CloseHandle(pChild);
	pChild = INVALID_HANDLE;
}
