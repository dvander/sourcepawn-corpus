#pragma semicolon 1
#include <sourcemod>

Handle gh_pack[100];

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	CreateNative("ClosePack", native_ClosePack);
		
	return APLRes_Success;
}

any native_ClosePack(Handle plugin, int numParams)
{
	for (int i = 1; i <= 20; i++)
	{
		if (!IsValidHandle(gh_pack[i]))
		{
			/*  similar result
			gh_pack[i] = GetNativeCellRef(1);
			*/
			
			gh_pack[i] = CloneHandle(GetNativeCellRef(1));
			SetNativeCellRef(1, INVALID_HANDLE);
			
			CreateTimer(0.1, RemovePack, i);
			
			return true;
		}
	}
	
	return false;
}

void RemovePack(Handle timer, int i)
{
	// Here I try to delete it, but it remains in the dump :(
	if (IsValidHandle(gh_pack[i]))
	{
		CloseHandle(gh_pack[i]);
		PrintToChatAll("RemovePack: close pack %d", i);
	}
}