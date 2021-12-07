#include <MemoryEx>

public Plugin myinfo =
{
    name = "[CPU] Get CPU name",
    author = "Rostu, CrazyHackGUT",
    version = "1.0",
    url = "Rostu#7917|vk.com/rostu13"
};

#define HKEY_LOCAL_MACHINE      0x80000002

static const char g_sFile[] = "file:///proc/cpuinfo";

public void OnPluginStart()
{
    CheckInitPEB();
}

public void MemoryEx_InitPEB()
{
    RegServerCmd("sm_cpu", Cmd_CPU);
}
public Action Cmd_CPU(int iArgs)
{
	if(GetServerOS() == OS_Windows)
	{
		char sResult[PLATFORM_MAX_PATH];
		GetProccessorName(sResult, sizeof sResult);

		PrintToServer("[SM] CPU name: %s", sResult);
	}
	else
	{
		if (!FileExists(g_sFile))
		{
			PrintToServer("[SM] your os == Linux...?");
			return Plugin_Handled;
		}

		File hFile = OpenFile(g_sFile, "rt");
		
		if (!hFile) 
		{
			PrintToServer("[SM] Couldn't open %s", g_sFile);
			return Plugin_Handled;
		}

		char sLine[512];

		while (!hFile.EndOfFile()) 
		{
			hFile.ReadLine(sLine, sizeof(sLine));

			if (ReplaceString(sLine, sizeof(sLine), "model name\t: ", "", false))
			{
				PrintToServer("[SM] CPU name: %s", sLine);
				break;
			}
		}

		delete hFile;
	}

	return Plugin_Continue;
}
void GetProccessorName(char[] sBuffer, int iMaxLength)
{
    int hKey;

    RegOpenKey(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", hKey);
    RegQueryValueEx(hKey, "ProcessorNameString", 0, 1, sBuffer, iMaxLength);
    WINAPI_CALL("advapi32", "RegCloseKey", WINAPI_FLAG_NEED_RETURN, WINAPI_ARGS_COUNT(1), hKey);
}
int RegOpenKey(int key, const char[] subKey, int &hKey)
{
    static Pointer pFunc;
    static Handle h;

    if(pFunc == Address_Null)
    {
        pFunc = g_hMem.GetProcAddress("advapi32", "RegOpenKeyA");

        if(pFunc != Address_Null)
        {
            StartPrepSDKCall(SDKCall_Static);
            PrepSDKCall_SetAddress(pFunc);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
            PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
            PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
            h = EndPrepSDKCall();
        }
    }

    return SDKCall(h, key, subKey, hKey);
}
int RegQueryValueEx(int hKey, const char[] sSubKey, int reserv, int type, char[] sResult, int iMaxLength)
{
    static Pointer pFunc;
    static Handle h;

    if(pFunc == Address_Null)
    {
        pFunc = g_hMem.GetProcAddress("advapi32", "RegQueryValueExA");

        if(pFunc != Address_Null)
        {
            StartPrepSDKCall(SDKCall_Static);
            PrepSDKCall_SetAddress(pFunc);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
            PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);

            PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
            h = EndPrepSDKCall();
        }
    }
    Pointer pStr = VirtualAlloc(iMaxLength);
    int iReturn = SDKCall(h, hKey, sSubKey, reserv, type, pStr, iMaxLength);
    ReadString(pStr, sResult, iMaxLength);
    FreeMemory(pStr);
    return iReturn;
}