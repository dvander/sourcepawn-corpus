#include <sourcemod>
new Handle:g_hKv = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Timed reserved slot",
	author = "Nightbox",
	description = "Add a timed reserved slot",
	version = "0.0 unsupported",
	url = "http://forums.alliedmods.net/showthread.php?t=96355"
}

public OnPluginStart()
{
	RegAdminCmd("sm_addtimedreserved", cAddTimedReserved, ADMFLAG_CHEATS, "Add timed reserved slot to player (sm_addtimedreserved <userid> <time>)");
	if(g_hKv!=INVALID_HANDLE)
		CloseHandle(g_hKv);
	g_hKv = CreateKeyValues("Admins");
	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "configs/admins.cfg");
	if(FileExists(path)) {
		FileToKeyValues(g_hKv, path);
		if(KvGotoFirstSubKey(g_hKv)) {
			new expires;
			do {
				expires = KvGetNum(g_hKv, "expires");
				if(expires!=0 && expires<GetTime())
					KvDeleteThis(g_hKv);
			} while(KvGotoNextKey(g_hKv));
			KvRewind(g_hKv);
			KeyValuesToFile(g_hKv, path);
		}
	} else {
		SetFailState("Can't find admins.cfg");
	}
}

public Action:cAddTimedReserved(client, args)
{
	new String:sTarget[32], String:sAmount[32];
	new iTarget, iAmount;
	
	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		PrintToChat(client, "Usage: sm_addtimedreserved userid time");
		return Plugin_Handled;
	}
	
	if (!GetCmdArg(2, sAmount, sizeof(sAmount)))
	{
		PrintToChat(client, "Usage: sm_addtimedreserved userid time");
		return Plugin_Handled;
	}
	
	iTarget = GetClientOfUserId(StringToInt(sTarget));
	iAmount = StringToInt(sAmount);
	
	if (!FullCheckClient(iTarget))
	{
		PrintToChat(client, "No such user (%s)", sTarget);
		return Plugin_Handled;
	}
	
	AddReservedSlotTime(iTarget, iAmount);
	
	return Plugin_Handled;
}

public bool:FullCheckClient(client)
{
	if (client < 1)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}


AddReservedSlotTime(client, time) {
	decl String:steamid[32], String:key[128];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(key, sizeof(key), "%s_loyal", steamid);
	KvJumpToKey(g_hKv, key, true);
	new expires = KvGetNum(g_hKv, "expires");
	if(expires==0 || expires<GetTime()) {
		KvSetString(g_hKv, "auth", "steam");
		KvSetString(g_hKv, "identity", steamid);
		KvSetString(g_hKv, "flags", "a");
		expires = GetTime()+time;
		KvSetNum(g_hKv, "expires", expires);
	} else {
		expires += time;
		KvSetNum(g_hKv, "expires", expires);
	}
	KvRewind(g_hKv);
	decl String:path[256], String:duration[32];
	BuildPath(Path_SM, path, sizeof(path), "configs/admins.cfg");
	KeyValuesToFile(g_hKv, path);
	expires = (expires-GetTime())/60;
	if(expires<60) {
		Format(duration, sizeof(duration), "%i min%s", expires, expires==1?"":"s");
	} else {
		new hours = expires/60;
		expires = expires%60;
		if(hours<24) {
			Format(duration, sizeof(duration), "%i hr%s %i min%s", hours, hours==1?"":"s", expires, expires==1?"":"s");
		} else {
			new days = hours/24;
			hours = hours%24;
			Format(duration, sizeof(duration), "%i day%s %i hr%s %i min%s", days, days==1?"":"s", hours, hours==1?"":"s", expires, expires==1?"":"s");
		}
	}
	//PrintToChat(client, "\x01You have \x04%s\x01 remaining on your reserved slot.", duration);
}