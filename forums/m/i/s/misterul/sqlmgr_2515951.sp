#include <sourcemod>

Handle g_pDatabase = null;

public void OnPluginStart()
{

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (g_pDatabase == null)
	{
		char xerror[512];
		g_pDatabase = SQL_DefConnect(xerror, sizeof(xerror));
		
		if (strlen(xerror) > 0)
		{
			LogError("sqlmgr.sp(15) :: SQL_DefConnect :: %s", xerror);
			
			return APLRes_Failure;
		}
		
		CreateNative("SQL_GetDefaultDbHandle", Native_My_AddNumbers);
		CreateNative("GetDefaultDbHandle", Native_My_AddNumbers);
		
		CreateNative("SQL_GetMainDbHandle", Native_My_AddNumbers);
		CreateNative("GetMainDbHandle", Native_My_AddNumbers);
		
		RegPluginLibrary("sqlmgr");
	}

	return APLRes_Success;
}

public int Native_My_AddNumbers(Handle plugin, int numParams)
{
	return view_as<int>(g_pDatabase);
}
